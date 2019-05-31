---
title: 从服务管理来看 systemd 架构之结构与语义性缺陷（下）
tagline: 技术性论文
author: Chen Jie
layout: post
group: translation
permalink: /structural-and-semantic-deficiencies-in-the-systemd-architecture-for-real-world-service-management-part2/
tags:
  - unit
  - job
  - init
  - Service
  - 服务
  - dbus
  - kdbus
  - journald
  - cgroup
categories:
  - Systemd
---

> 原文：[Structural and semantic deficiencies in the systemd architecture for real-world service management, a technical treatise][1]
> 作者：V.R.
> 译者：Chen Jie

<p style="color:#a6aaa9">有一句话，耳熟能详，叫做一个函数只做一件事，并做好一件事。推而广之，一个程序也应有其专注。本文给译者的启发，即一个 init + 服务管理器该是怎样的呢？</p>
<ul style="color:#a6aaa9">
<li>简单，恪守底层组件角色，勿有复杂抽象。</li>
<li>避免类 D-Bus 高级 IPC，因会牵扯入复杂的内建对象系统。</li>

<li>视需求，集合“一组关联服务”，手写代码调度集合的启动：
<ul>
	<li>比如，开机首启 “最小系统服务集合”</li>
	<li>“最小系统服务集合” 之启动，如「<a href="/tinylab-weekly-11-4th-2015/">泰晓资讯·11月 / 第四期 / 2015</a>」“秒启 Linux” 所介绍的那样，手写代码调度初始化工作</li>
	<li>集合实是一个状态，状态迁移</li>
</ul>
</li>

<li>其他散落服务，采取按需启动方式。比如监听资源，并结合动态追踪（dynamic tracing）插入代码，与服务管理器进行通信。</li>
</ul>

「__[从服务管理来看 systemd 架构之结构与语义性缺陷（上）][2]__」列举了主要问题，它们是由 systemd 之执行引擎 所引入的层层封装导致（或 虽与之无关，但层层封装加大了调试难度）。另外，默认打印、或是如 systemd-analyze(1) 之类的工具，要么信息太粗糙，要么把依赖信息一股脑儿列出，很难解读。没有一颗“福尔摩斯”的大脑，莫能调试。简陋的 snapshot units，
缺失通用机制来“导出依赖图到磁盘以便稍后回滚”，这就没法复现问题，或是恢复到已知状态。所以说，systemd 的依赖图 是一个机器资源，每次都计算，仅存内存，用户理应不关心。但现有实现不够健壮，没法做到让用户放心。对比过去和现在用的类似系统，都将计算后的依赖图存在某处，更稳妥些，例如 serel 和 s6-rc。

## Bus APIs, 连接及 对象接口 的冗余

对 D-Bus 的批评超过了本文讨论范畴，但不管怎说，对于处于用户空间底层的组件，用 D-Bus 这样量级的通信机制，不得不卷入“服务发现”、“对象系统”和“认证 API”，还不如使用更简单轻量的 IPC。另外，对每个 systemd 实例，在 /run 下各有各的 socket（译者：即私有总线），来进行 D-Bus 协议通信 及 序列化/反序列化 Unit 结构 到/从
文件。于是，[常](https://bugzilla.redhat.com/show_bug.cgi?id=1010572)[见](https://unix.stackexchange.com/questions/220940/how-to-get-systemd-running-correctly)[不能连上私有总线](https://github.com/systemd/systemd/issues/589)而导致的 “Failed to get D-Bus connection”，在网上一搜一大把，还跟着 /run/systemd/private 字样。sd-bus - _事实上_ kdbus 客户端的参考实现库（无内核 kdbus 支持时切换到 dbus1）、由 systemd 使用并主导 - 尚不能给潜在使用者以足够信心。

<p style="color:#a6aaa9">译者：感觉此处耍流氓，若前后逻辑是承接的，那么作者似乎是借着“Failed to get D-Bus connection”来说明 sd-bus 不可靠。然支持多总线是 D-Bus 规范使然，多总线必然需指定连哪个总线，指定错了当然连不上啦，与 sd-bus 实现无关。就代码质量而言，根据译者体验，sd-bus 比 D-Bus 库要清晰许多。不过，放大范畴，kdbus 本身确还面临挑战，有兴趣的同学可以关注下 <a href="https://github.com/bus1/bus1">kdbus 的重构工作 bus1</a> 以及本站「<a
href="/kdbus-kernel-is-implemented-as-a-driver-its-really-okay/">KDBUS
实现为一个内核驱动，真地好吗？</a>」一文。</p>

在 [PID1 的 D-Bus APIs 文档](https://wiki.freedesktop.org/www/Software/systemd/dbus/)中，“Manager 对象的接口”无疑非常惹眼。实际上，systemctl 内部实现为它的一个客户端。它还是唯一向总线上的订阅者，发送信号的接口。但发送的信号相当有限，如 （任意分类的）units 加载到内存、从内存卸载时；jobs 也是；启动完成时；磁盘上的 unit 文件被启用/掩盖（masked）；以及重新读取某个 service 时。这些所谓“信号”的事件通知，只是 systemd
全部事件中的很小一部分。剩下总线上 APIs，其中大部分仅是简单地返回属性（properties） － 常见为 unit 配置信息，可用其它通信机制来发出，没必要借助 D-Bus。

最讽刺的是，为了运行命令或是查询数据（数据须被反串行化到 _另一_ 对象系统），必须和对象系统（D-Bus）通信。但这个真实存在的对象系统，却试图对用户隐藏，显得突兀且晦涩。另外，通信中存在代理对象系统（D-Bus），不可避免增加了开销 和 失败情形。

## 写 cgroup

<p>
systemd 使用 cgroup 来 “可靠地追踪进程”，但 cgroup 本职工作是“资源控制和分区”，似有些许失谐。更合适的做法是监听 Netlink proc connector（cn_proc）上的事件，来追踪进程<span style="color:#a6aaa9">（译者：对 cn_proc 感兴趣的同学可参考<a href="https://github.com/cee1/plymouth/commit/5be1bb7751b547fe5c125a42c3f2fe607568fa0f#diff-af57a80c2ea80c9775806fbf20594a89">这个例子</a>）</span>。
</p>

另外，systemd 处理 “Type=forking” 这类 services，并非像大家所知的那样，做的比 传统的服务管理器 更好。这类服务的天生缺陷：将自己变作守护进程，而非让 服务管理进程 守护。systemd 对此有俩手段，来找到服务主进程：“PIDFile=” 配置项直接指定 和  “GuessMainPID” 启发式推断。前者有 “检查和使用时差”的竞态问题，后者在 cgroup 中存在多个守护进程时失效。

内部实现上，Manager 和 Unit 模块都直接访问 cgroup 对象接口。后者封装了对 cgroupfs 文件系统的原始操作。不管咋说，当前的设计，难以分离出一个通信接口明晰、专一的 cgroup 写服务。开发者对这种消除冗余代码的提议，无甚兴趣，虽然他们声称要消除冗余。对比统一的、 “cgroup 层次结构”的单个写者方案，_目前_ 的官方实现有些随意，对象接口存在内部耦合，长久渐成问题。systemd 有两类 units，专用于新建（并命名） cgroup 组，并将进程划分入组 ： slice（与 target 一样，slices 是伪 units，仅用来分组，甚至不能用来同步）和 scope（将 未在 Unit 框架中直接配置的、任意的系统进程分入组）。systemd 对外暴露的 cgroup API 也很简单，主要用于创建 暂存的 units。 

## 在关键路径上进行解析

引自 djb 的 “[The qmail security guarantee](http://cr.yp.to/qmail/guarantee.html)”：

> Don’t parse.
>
> I have discovered that there are two types of command interfaces in the world of computing: good interfaces and user interfaces.
>
> The essence of user interfaces is parsing: converting an unstructured sequence of commands, in a format usually determined more by psychology than by solid engineering, into structured data.
>
> When another programmer wants to talk to a user interface, he has to quote: convert his structured data into an unstructured sequence of commands that the parser will, he hopes, convert back into the original structured data.
>
> This situation is a recipe for disaster. The parser often has bugs: it fails to handle some inputs according to the documented interface. The quoter often has bugs: it produces outputs that do not have the right meaning. Only on rare joyous occasions does it happen that the parser and the quoter both misinterpret the interface in the same way.
>
> When the original data is controlled by a malicious user, many of these bugs translate into security holes. Some examples: the Linux login -froot security hole; the classic find \| xargs rm security hole; the Majordomo injection security hole. Even a simple parser like getopt is complicated enough for people to screw up the quoting.
>
> In qmail, all the internal file structures are incredibly simple: text0 lines beginning with single-character commands. (text0 format means that lines are separated by a 0 byte instead of line feed.) The program-level interfaces don’t take options.
>
> All the complexity of parsing RFC 822 address lists and rewriting headers is in the qmail-inject program, which runs without privileges and is essentially part of the UA.

<p style="color:#a6aaa9">译者：Daniel J. Bernstein 这句 “there are two types of command interfaces in the world of computing: good interfaces and user interfaces”，及后面一句 —— UI 的本质是<span style="font-weight:bold">解析</span>，将一系列非结构化的、更倾向人类心理认知（所谓“更友好”）的命令 转成 结构化数据；然后将结构化数据，转回非结构化的系列命令 —— 颇有意思。进一步延伸下，不同代 UI
技术，解析器（Parser）是重要的组成部分？虽然形式上各不相同，比如命令行的
getopt，GUI 图形交互输入事件（键 鼠 触摸等）的 Parser，再到自然语言的语音语义识别 ...</p>

launchd，启发了 systemd 诞生，是在 PID1 之外解析 plists 的。

最近的一个研究组，聚焦“语言的理论安全（[LANGSEC](http://langsec.org/)）”，与 djb 一样，对“解析”的风险，举了详细一例。因此，systemd 在关键进程中解析 unit 文件的配置信息（这里面还涉及模糊匹配），相当业余。

## 非通用的 fd 持有和 socket “激活前（preopening）”逻辑

所谓的“socket 激活”特性（如 Laurent Bercot 所指出的那样，这个名字有[明显误导](https://forums.gentoo.org/viewtopic-t-994548-postdays-0-postorder-asc-start-25.html#7581522)），是 systemd 著名特性之一。有趣的是，“socket units” 作为懒惰的装载点，其命名有偏颇 —— socket units 其实还支持 FIFOs，POSIX 消息队列 以及 “特殊文件”（即，字符设备之类的用 ioctl(2) 的东东）。

在“[Systemd for Administrators, Part XI](http://0pointer.de/blog/projects/inetd.html)”，Lennart Poettering 声称：

> Socket activation of any kind requires support in the services themselves.

<p>
这可不对。这种技术近 20 年前就有了，当时叫做 UCSPI（UNIX Client-Server Programming Interface），JdeBP 写过一篇<a href="http://homepage.ntlworld.com./jonathan.deboynepollard/FGA/UCSPI.html">简介</a>。“类守护工具”的服务管理器，可通过运行脚本（runscripts）中的链式装载工具，来显式构建执行状态。而 systemd 对象模型非常自封闭，不能轻易加入许多扩展。<span style="color:#a6aaa9">（译者：猜测此处逻辑为：前者无需改服务代码，就支持延迟执行特性；而 systemd 扩展有限，需要改服务代码适配）</span>
</p>

使用 systemd 的“socket 激活”，除了如 Bercot 所说的、模糊了不同语义，还需链接 libsystemd 的 sd_listen_fds(3) 。最近引入的 “fd 持有” 特性 sd_notify_pid_with_fds(3)，也一样。

这里提一下，动态追踪（dynamic tracing）是另一种潜在的方式，来延迟执行直至资源上线。

## unit 文件的配置能力较弱

unit 文件易用的配置格式，也是 systemd 主要卖点之一。另一更显著优点在于，systemd 保证每个服务都始于一个干净的进程状态，这与传统脚本大杂烩的 init 不同，后者天生地没法保证 服务启动时状态干净。

实际上，这是误解。干净的（或者说明确的）进程状态，是指从明确定义了的清单，能构建出执行环境。基于脚本解释器也能做到。例如，通过链式装载工具，在 exec(2) 中执行己的镜像和下一步的命令参数，从而构造出任意复杂执行环境。这其实与函数构建执行环境是相同的，只不过这里的 “函数” 粒度更高层些 —— 操作系统进程。systemd 中，可执行状态的构建并非自链式装载，而是将 unit 文件选项导入到一个盖在 Unit 对象上的、为 service unit
类型所设置、私有的 ExecContext 结构体。

本文上篇提到的 DefaultDependencies= 是一个隐含状态，会偶尔导致 排序循环，并进一步导致循环依赖。另一方面，如 Restart= ，其选项值定义要么太细，要么太简，例如 “on-abnormal” 以及 “on-abort”，但老实说，借助 RestartPreventExitStatus= 可以搞定。由此大概可见，systemd 未提供一套通用的东东 给 “负责重启的组件”。对于服务 “想调用自己的重启器，配合着服务管理器” 来重启，甚至都没有诸如 “ExecRestart=”
的选项。有些变通方法，例如通过启动脚本检查后置条件，但粒度太糙。其它新生代的同类系统如 Solaris SMF 没这个问题。一种潜在的、更好的做法是，使用 systemd APIs 来写 “负责重启的组件”，从而与对象框架有更好整合（但已有的 D-Bus 对象框架还不够好）。

执行环境的修改选项，例如 PrivateTmp=，PrivateDevices=，PrivateNetwork=，ProtectSystem= 和 ProtectHome= 并非一些小修改，而是为实施 预定义策略 而引入的大例程。事实上，作为一个对象系统，这算是 “委托（delegation）” 或 “再绑定和扩展能力” 的缺失。这点上，systemd 与类似系统不同，如早先的 pinit，initng 和 eINIT、及后来的 finit，不支持插件或扩展，尽管它层面较高，也有自定义选项的需求。

本节所述问题并非理论上存在，实际中常有误用 systemd unit 选项，其中一些极端的例子（全部与 Java 应用有关，看起来皆因 没法指定重启器）[罗列于此](http://homepage.ntlworld.com./jonathan.deboynepollard/FGA/systemd-house-of-horror/)。

## 失衡：处事之道，倾向儒乎？道乎？

systemd 的依赖系统看起来极其复杂，这也许是在资源管理上，它到底是“勤劳、做在前头”的主动儒家做派？还是“懒惰，按需而动”的随缘道家做派？

在实践中，相比由依赖图推导显式排序、依赖关系，再由 Manager 对象分配 units、调度 jobs、排入事务中 —— 延迟加载用很少。

而在 systemd 设计之重要参考，launchd，则完全是一副 “道家做派的”：通过 IPC 来满足任何潜在的资源依赖。systemd 则兼修 “儒”（基于依赖网络的对象模型）与 “道”（延迟加载），但未能做好平衡。

通常的儒派服务管理器，秉承 “不怕出错，出错重试” 精神，有模块分离（或通过工具，例如守护工具及其衍生，或是 RPC 通信服务，如 SystemXVI）、通过链式加载来合成执行状态、仅限于排序的依赖（或其他人类可以理解、一览无余的图）。而道派服务管理器，通常没有 依赖信息 的概念，而是集中于监听服务导出的资源，然后视条件异步、动态地启动服务。认为 “按需响应方式” 要好于
“纯追求吞吐量的并行启动”。但在 systemd，一面要忍受 激进并行化启动 带来的不确定性、据依赖信息生成的对象网络 及附带的事务和 job 概念；另一方面，将 延迟加载 的特性局限于内部的 Manager，不像 UCSPI 那样灵活。

对象系统本身，并未带来诸如 “稍后绑定（late binding）”（仅有 vtables 的方法动态分发）、“内省（introspection）”（仅通过 D-Bus 间接获得，但有限）、Unit 语义之 “猴子补丁（monkey patching）”（例如，可用来重载选项），也没让 Unit 真正成为一个统一的基础抽象。故对象系统是个笑话，充其量就是装了个逼。一层层抽象并无明显收益，却把执行模型弄复杂了。

## 同步用 Targets 而非 milestones

Targets 是一个伪的 units，除了有依赖以外，本身无任何含义。其用来作为同步点，来命名系统状态 或说是检查点，同时相对 targets，可对 units 进行启动顺序的排序。相当于类似系统中的运行级（runlevels），合集（profiles）以及里程碑（milestones）。

值得一提的是，仅将 target 作为图的一部分来处理，必丢失一些信息。例如，在 Solaris SMF，里程碑（milestones） 有其完整的清单，来便于诸如设置个别服务属性，或全局的系统属性。故在此例中，不仅仅是个同步点，而是个实际存在的、可转入的、特定的系统状态。进一步说，因其配置项 仍受服务管理器 限制，故它既有近乎 “inittab(5) 中，对应 runlevel 的脚本” 那样的灵活性，又有健全环境、可进行恰当的一致性检查。另一个好处是，里程碑里有哪些服务，是 _明确_ 的。作为对比，target 通过依赖来隐含关联进服务。

具体例子参见 [SmartOS milestones](https://github.com/illumos/illumos-gate/tree/master/usr/src/cmd/svc/milestone)。

## （系统相关的）就绪通知问题

在 Unix 进程模型中，没有 “服务就绪” 的通知方式。“服务就绪” 是指初始化工作已完成，进入了主循环来处理请求。

该问题真实存在，却鲜被觉察。通常而言，儒派的服务管理器，会在限制次数内，自动重启依赖的服务，直到条件满足。取决于工作负载，这种做法可能导致 “过度抖动” 而备受批评。

有两种 _常见_ 的方法，来避免这种徒劳的重试：懒惰（通常借助 preopening sockets，不过这样会延迟加载资源）和 服务管理器 提供的就绪通知机制。

systemd 中，“Type=notify” 的 service unit，采取第二种方法。其背后的 sd_notify 函数，通过一个简单的、基于 socket 通道来实现。由此可见，需要服务链接 libsystemd 来调用 sd_notify 等导出的函数。

监管器要求 服务程序的作者 来调整代码，这样做不是特别合适。其实还有另一个方法，鲜有讨论。该方法能加快启动速度（但不是并行启动）。“检查点 / 稍后回滚检查点”法：将进程就绪时刻的镜像，生成检查点。再次启动时，叠加检查点。用工具 DMTCP 或 CRIU 就可以做到。

## 全局系统 和 服务 的状态纠缠在一起

systemd 架构中，各个组件环环相扣。init、进程管理器、进程监管器、cgroup 写者、一些本地服务工具、Unit 结构体（做成一个协议也许更好些）、定时器（timer）、挂载点（mounts）、自动挂载点（automounts）以及 交换分区挂载点（swaps），所有这些都在同一个模块，其间的边界定义是病态的。

这带来了一系列问题：实时升级有较大风险；许多本该可扩展的接口（例如，用自定义实现，替代已有模块）被做成了内部细节，从而丢失了一些潜在的有用特性。例如，将跑在系统模式 下的 systemd Manager，剥离掉启动和关机功能；或是跑在用户模式下，作为会话管理器，可执行代码不含 “系统管理器 和 init” 功能。作为参考， [uselessd](http://uselessd.darknedgy.net/PidNone/) 展示了上述建议的可行性（ 基于 “systemd-208  ＋ 若干 backport 补丁” ，稍加改动，初步可运作，但没测试过，故还不适于正常使用）。虽说最新 systemd 功能更复杂了，但开发者若有意采纳这些建议，完全可以做到。

各组件环环相扣，要么全要，要么全不要，从而阻止了组件的灵活组合。

## journald，集中的 I/O 瓶颈

<p>此处暂不讨<span style="color:#a6aaa9">（tǔ）</span>论<span style="color:#a6aaa9">（cáo）</span>journald 日志记录为二进制格式。</p>

没错，传统的 syslogd 确实有问题。然而，systemd 的替代方案，journald, 似乎更容易产生 集中的 I/O 瓶颈。journald 将启动早期日志、内核日志，服务日志和其他日志（比如 coredumps）全部并到一处，并进行索引、应用一些隐含的后期处理规则。

与之形成鲜明对比的是，早先的一些方案，如 [multilog](http://cr.yp.to/daemontools/multilog.html)，[s6-log](http://skarnet.org/software/s6/s6-log.html)，其日志的收集、轮换存档、以及处理 这三步骤，是有明确分离的。它们也没有去“嗅探”全局的各种日志，相反，每进程有专用的日志服务，日志分开存起来。日志处理方面，或通过 POSIX regexps 来简单过滤，或用脚本做复杂过滤。这意味着过滤规则是明确的，并可针对单个进程来调整。依据配置的阀值，日志按简明的命名风格，自动轮换存挡。

具体实施方法如下：

> 任何程序，无一例外，将它的日志（出错信息，警告信息或任何其他信息）输出到 “标准出错的文件描述符”，即 fd 2，它就是来干这活的。
> 
> 当 1 号进程启动时，日志链的“头”是本机控制台：1 号进程发往 stderr 的，应该毫无修改地呈现在本机控制台。无论何时，本机控制台都应是日志输出的最后一处。
>
> 那些不处理自己日志的服务，其日志转给 一号进程配置和监管的 日志处理机制（a catch-all logging mechanism）。catch-all 日志机制 自身的错误消息，呈现在本机控制台上。
>
> 1 号进程自己的错误消息，可以呈现在本机控制台，或耍些心机走 catch-all 日志机制。
>
> 1 号进程启动的服务，应有自己的日志服务；用 s6-svscan 的监管机制（supervision mechanism) 可以很容易做到。日志服务自身的错误信息，应当走到 catch-all 日志机制。
>
> 对于用户登录服务如 getty，xdm 或是 sshd，作为服务，在启动时已备好各自的日志服务。当然，当用户使用 终端 和 脚本解释器，解释器的 stderr 应被重定向到 终端：交互视程序打破了自动日志链，转由用户来处理。
>
> 某个 “类 syslogd 服务” 可接收老式程序通过 syslog() 发来的日志。但它是个普通的服务，其接收的日志并非 日志链 中一部分。向 “类 syslogd 服务” 提供 日志服务，多有重复；syslogd 自身的错误消息，默认到 catch-all 日志机制。s6 软件包，含有 ucspilogd 程序，再结合 s6-networking 软件包，足以方便地实现一个完整的 syslogd 系统，替代 syslogd。

索引各个日志的工作，与收集工作完全不相干，从而更加灵活。同时，和外部服务的互操作更简单了，并且托管工作也简化了，不需要 journald.conf(5) 中那些缓和日志破碎设的限制。

## 总结

通常对 systemd 的解读，缺乏完整性，概念上小视了 systemd。本文建议将 systemd 视作一个更高级的模型，来阐述和讨论 systemd 架构的一些观察。

尽管做了包容万象的抽象，在语义上却不统一；围绕依赖式、网络化的对象系统，引入了事务、启发式的 job 排序调度，带来了不易调试的失败情形 —— 若少一些抽象层可避免这些情形。通过 D-Bus 总线与服务管理器通信，增加复杂度和对象模型冗余，却收益甚少。

还有，unit 文件的选项，常带有隐含状态，要么提供的功能有限。在特性上， 到底是更倾向 “勤劳、做在前头”，还是 “懒惰，按需而动”？没有把握好，导致不得不加入非通用的、Manager 相关的代码，来处理两者的某些边界情形。日志机制 和 环环相扣的架构，相比已有成功实践，反而有所倒退。



 [1]: http://blog.darknedgy.net/technology/2015/10/11/0/
 [2]: /structural-and-semantic-deficiencies-in-the-systemd-architecture-for-real-world-service-management-part1/
