---
title: 从服务管理来看 systemd 架构之结构与语义性缺陷（上）
tagline: 技术性论文
author: Chen Jie
layout: post
group: translation
permalink: /structural-and-semantic-deficiencies-in-the-systemd-architecture-for-real-world-service-management-part1/
tags:
  - systemd
  - unit
  - job
  - init
categories:
  - 服务管理
---

> 原文：[Structural and semantic deficiencies in the systemd architecture for real-world service management, a technical treatise][1]
> 作者：V.R.
> 译者：Chen Jie

<p style="color:#a6aaa9"> 就像那些年钻过的牛角尖，在一个局部里面 兼收并蓄，最终代码疲于调和。systemd 是否也钻到了牛角尖？本文作者给出了有趣的观点。</p>

## 万物皆单元（Unit）（然并没有什么卵用）

systemd 通常被认为是一个服务管理器（service manager）或是一个 init。在这些问题域中，systemd 常被传颂。其亮点之一、进程监管工具（process supervision toolkit）的重要组成部分 - journald - 一个可靠的日志系统。其它辅助组件，如 logind 和 nspawn，也备受赞誉，但它们只是跑在服务管理器之上的服务和工具，故很少单独提及。

然，上述这个观点是错的！简单地将 systemd 看作“init”，或“服务管理器”，或“GNU/Linux 操作系统的核心管理、配置的软件合集”，甚至是一个“用户空间底层的中间件” 都不合适。

事实是，所有这些都基于 systemd 之根本：一个用于封装 OS 资源的对象系统 以及事务性作业调度（transactional job scheduling）引擎，试图在 GNU/Linux 上提供统一接口：

- 控制/切分（partitioning） CPU 时间单元
- 静态名和实体

值得一提的是，systemd 开发者在一篇名为 “[The New Control Group Interface](https://wiki.freedesktop.org/www/Software/systemd/ControlGroupInterface/)” wiki 文章写到（下段引用中， cgroups 被称为对象 (objects)）：

> Well, as mentioned above, a dependency network between objects, usable for propagation, combined with a powerful execution engine is basically what systemd is.

这和上面说的差不多，除了提到了执行引擎（execution engine） —— 大体上是 job 队列 和 unit 队列的上下文，由 Manager 对象所驱动 —— 其知名度相对小些，但却是定义 一个“systemd 实例（跑在系统层面，或者每个会话跑一个）” 高层逻辑的主要结构体。systemd 另一充满争议的话题，即前述“依赖网络（dependency network）”是点睛妙笔吗？就 systemd 对象系统而言，依赖网络真的至关重要？或不过是处理 job 冲突、实现基本的 unit 调度语义而强加入的？更让人看不明白的是，几乎所有用户都认为 systemd 是一副“勤劳的、做在前头”的处事风格，而作者却鼓励按照“懒惰处事”的思维去用之。这实际暗含“设计上对并行启动有多照顾”？“并行启动” 不符合 “懒惰处事”风格，而显是“勤劳、做在前头”的做派 - 这便需借助“依赖信息”（dependency  information）来进行同步，让每个有向图（directed graph）中的 services 序列化启动，从而避免并行启动天然的不确定性和竞态问题。

让我们竖起中指。

有许多系统的设计中，有一个“基本抽象”，然后“重载”方法。在 Plan 9 中，这个“基本抽象”，就是“文件”，这里的“文件”不是磁盘上一个文件，而是存于 “字节流协议 9P”所定义的上下文中 - 任意数据结构可表述为一颗“文件之树”。对于 systemd，这个 “基本抽象” 就是 Unit。

Unit（通常和 unit 文件搞混，后者是 Unit 序列化后存在磁盘的文件）也是对象，故面对对象贯穿于 systemd 的设计。每个 Unit 关联一个 Manager 对象，该对象驱动着系统层面、或每用户会话跑的 systemd 实例。注意区分“抽象 Unit”，“Unit 的一个实例”，以及 “Unit 的一个引用”。“Unit 实例”关联一个 vtable，vtable 是一个“虚函数派发到函数实现”的机制，包括常见的进程管理（启动、停止进程，杀进程），资源回收操作如资源释放，以及 Unit 运行时刻状态相关的域（标志、描述、依赖集、布尔型域等 静态数据成员除外）。不同的 unit 类型，vtable 中虚函数指到其相应实现。Unit 还可以包含或者说是入列一个 job（每个 Unit 只能有一个 job），到 Manager 对象私有的 运转队列（run queue）中，等待被分派和执行。Manager 对象还有一个 加载队列（load queue），用于加载 unit 文件，或者程序生成。还有 清理队列（cleanup queue）用于清除“过期的 units”（不持有 jobs，且是 inactive+failed），以及 GC 队列容纳即将进入 清理队列 的 Units（一个简单的 “标记，随后清理”的垃圾收集方法）。

这些就是 systemd 架构之实质。其提供统一 _内部_ 接口很可能是有用的，但通常而言，不会从面对对象中捞到太多的好处，远不如一个统一的 _外部_ 接口来的老练。

例如，units 还有许多分类（不是 systemd.unit(5) 所说的类型（types），每个分类有重大语义差别），如下：

### 长存的 units

“长存的 units” 并非官方术语，是指从磁盘的 unit 文件加载来的、最为人所熟知的那种。

该分类下的 units，依据 type 不同，有许多选项。并有“安装”的概念（[Install] 指令）

### 临时（可执行）的 units

临时的 units 不由 unit 文件指定，而是程序生成。此分类下的 units 管理着可执行数据，或是一个工作单元。scope 是 _完全_ 临时的、可执行 unit，用于逻辑绑定一组（无父子关系的）进程，实现资源管理。与 svchost 相似，只是采用不同的机制（采用 cgroup）。另一方面，systemd-run(1) 工具能生成/运行临时的 timer（用来触发其他的 units）和 services。

少数临时的 units 有磁盘上对应的 unit 文件，但它们是不指定 units 的配置。

该分类的存在，显而易见，能让任意进程跑在 systemd 框架中，适用于如 一次性任务，进行测试或应用于脚本，同时可动态调整其执行环境。

那么问题来了，systemd 在“执行环境的动态修改”（此处动态性，例如纯替换运行时环境，或是从 `某个检查点 + 与目标执行环境的差异' 再次执行），并不牢靠。__unit drop-ins__ 支持额外的 unit 文件片段（INI 格式），改写对应的、厂商提供的默认 unit 文件，但这是静态的、装载时的机制，且不能调整依赖关系（准确而言，只可以加依赖关系）。

对了，systemctl(1) 命令有个 __set-property__ 选项，确能在运行时刻来修改执行环境，但基本只能改 systemd.resource-control(5) 所列举的选项，即 cgroup controllers 相关的选项。

### 临时（不可执行）的 units

同上，它们由程序生成。该分类下有 device unit 和 snapshot unit。前者有磁盘对应 unit 文件（没有配置选项，当然），后者没有。

Snapshot unit 比较特殊，虽然它仅存于内存，却可用文件名来引用之。它由 __systemctl snapshot__ 命令来创建，并持有当下全部启用的、活跃 units 之引用。粒度较粗，仅能保有“什么正在跑、什么已经停了”的信息。

Snapshot unit 仅存于内存，极大地削弱了其用场，例如，没法创建一个依赖图的检查点，以便稍后将系统状态恢复到这个已知健康的检查点。

Device unit 虽有磁盘对应 unit 文件，但仅用于排序。udev 规则中，打上 “systemd” 标记的设备会创建 device units。device unit 没有选项，主要是为了实现“对应设备插入，执行相应服务”（通过 udev 规则中的“SYSTEMD_WANTS=”）。由此可见，device unit 是用来封装 管理特定设备节点 之公开 APIs，故其语义是明确的。

### 长存的、基于任务的 units，与 jobs 无关联

标题很绕口，但概述了此分类的 units。如前所述，systemd 通过 job（也是一个内部的 unit 类型）来执行 unit，jobs 本身由其他 units 来排。然而，也有例外，最具代表性的就是 mount 和 swap unit。

既然叫做长存的 units，其配置源自 unit 文件。Mount unit，作用类似 job 或者 oneshot service，甚至伪装成 jobs 打印 工作状态日志。Mount unit 内部也是基于“泛化的 Unit 接口”，最终是使用 `util-linux 的 mount(8) 命令`工作。Swap unit 类似，使用 `swapon(8)/swapoff(8)` 命令，另还用了 libudev 接口来注册设备节点，实际貌似还有排 jobs。这些从某种程度而言，在隐藏差别之上，Mount unit 和 swap unit 存在重复重叠的部分，

Automount unit 是进阶的变种，它借助 autofs，且直接排 jobs。实践中用来推迟挂载（直到真正访问时才挂载）。

## 排 jobs

Jobs 是一种内部存在的 unit 类型，且和其他分类的 units 相关联（一个 job 只关联一个 unit），通常而言，提供通用的、控制任意 unit 执行时间的内部接口。Jobs 作为事务的一部分被调度，其语义取决于被 _赋予的类型_ - JOB_START，JOB_STOP，JOB_VERIFY_ACTIVE，JOB_NOP，等等。Job 类型仅在内部可见，而 _Job 的 7 种模式_ ，可由 systemctl(1) 来设定。模式用来指定，相对其他 jobs 如何排 job，即某个 job 存在如何影响着 对失败的应对动作、对依赖信息的遵循、以及其他 jobs 的最终结果。job 的最终结果包括 JOB_TIMEOUT，JOB_DONE，JOB_CANCELED, JOB_ASSERT（service “前提条件”中的断言失败，如需要，可触发“hard job failures”），等等。Jobs 被排到 Manager 之私有的运转队列中（run queue），通常随后加到事务中来检查一致性（按上“引用过标记” 和 “世代计数（generation count）”来跟踪）。

Job 的类型可能会“塌缩降级”（be collapsed），即根据 Unit 活跃状态的变化（active，reloading, inactive, failed...），调整 Job 的类型。Jobs 自有其私有的依赖关系，与外部可见的 Unit 依赖关系相区别。当多个 Jobs 符合某些启发式属性，且不冲突时，可并入一个事务中。其策略在源码中注释如下：

    /* Merging is commutative, so imagine the matrix as symmetric. We store only its lower triangle to avoid duplication. We don't store the main diagonal, because A merged with A is simply A.
    
     * If the resulting type is collapsed immediately afterwards (to get rid of
     * the JOB_RELOAD_OR_START, which lies outside the lookup function's domain), 
     * the following properties hold:
    
        - Merging is associative! A merged with B, and then merged with C is the same as A merged with the result of B merged with C.
        - Mergeability is transitive! If A can be merged with B and B with C then A also with C.
        - Also, if A merged with B cannot be merged with C, then either A or B cannot be merged with C either.

<p style="color:#a6aaa9">（合并操作满足交换律，若查表得到的结果为随后立即“塌缩”，则进一步满足结合律和传递律）</p>

（对正在运行的 jobs 也能进行 合并操作，除了 JOB_RELOAD 类型，这是为了避免进入竞态，而可能错过一些配置文件的更新。）

上述情形，有点像是个“露出内部一角”的抽象（或者说，在面对对象的情景下，未能有效封装内部信息）：job 作为内在的 unit 类型，用户还能 __部分地__ 感知到它 —— 通过 systemctl(1) 列出 jobs，以及 job 的模式；开机时输出的 job 启动信息 —— 大部分情况下，并不期望去使用或关心这些信息。另外，如上所述，即便在 job 有用的情形中，其用法也并不一致。

## 事务管理器

Manager 通常不会“裸调度” jobs，而是在事务中调度，其中加入许多启发式的东东。

事务用哈希表来索引其下的 jobs，事务还有一布尔标志指示其不可取消，以及一个指向“锚 job”的指针（“锚 job”就是一开始排入的 job，之后发生“合并”，“塌缩” 以及其他调整）。当事务中的 jobs 不依赖其他 jobs 时，它们就被回收（从哈希表中移除）。

单个 job 加到事务中，使之成为“含单个 job”的事务：要么从哈希表中取出一个已存在的 job，要么分配一个新的 —— 设置“引用过标记”和“世代计数”，插入事务链表头部。

向事务中加入带着 unit 依赖的 job，牵扯更多。首先，检查 unit 的配置是否已加载、处于“活跃运行”状态、未被屏蔽（masked） 以及正加入的 job 类型，是否匹配 unit 的属性。接着所有的一般依赖、正依赖、强依赖和负依赖（下一节展开说）被递归地加上。若 job 类型为 JOB_RELOAD，另加上 “PropagatesReloadTo= 与 PropagatesReloadFrom= 关系”。JOB_RESTART 类型常被转成 JOB_TRY_RESTART，防止强行启动未存在的依赖。

事务管理器的记账任务，例如有 丢掉冗余 jobs（即，job 类型 与 对应 unit 活跃状态存在重叠、空操作的 job），丢弃不可合并的 job 来解决冲突（它们不直接关乎“锚 job”），（通过丢弃 jobs）打破循环依赖（依据 非 NULL 的“引用过标记”，以及“世代计数” 等于最近一次 遍历图 时的值）。

## 被依赖才存在

基于依赖的 init 比嘴上说的更脆弱。在进程管理器的语境中，术语“依赖”常指 拓扑上排序的有向图（a topologically sorted direct graph）中的一个节点。此外，该语境中，其目标问题是排序 —— 确保顺序不会出错。这同例如函数库的依赖不尽相同，后者需要被依赖的函数库（shared object）导出同名公开符号，来满足依赖。诚然，在 init 系统中，没人关心服务，而是关心服务导出的资源。所谓服务的依赖关系，算是件合理的外衣，但又天然带有额外代价（这其中包括一个严格的“勤劳、做在前头”的规定，除非像 systemd 或 nosh+UCSPI 那样，再混搭“懒惰处事”风）。

如此，几乎所有的依赖问题可简化为排序问题。那么问题又来了，为啥一个依赖系统要搞的有点小复杂？或者，一个依赖系统就是一个简单的、扫描配置指令的预处理器，其输出的排序结果也可人来写从而替代之？依赖信息主要作用，是为了计算并行启动中的可靠顺序。不保证顺序性，进程间很容易出现同步问题，以及所依赖资源未准备好。再说说并行启动，主要为加快启动速度。另一种加快启动速度的方法，就是“预先设置检查点 / 后续启动恢复到检查点”，如 DMTCP 或 CRIU，盖上完成初始化的服务进程镜像（马上就进入事件循环时的镜像）。故基于依赖的 init，其实现，不能太松散以至于成了个花瓶，也不能太复杂，引入过繁的处理开销 和 过多的输入路径，以至于没法人为预估其执行过程。

依赖，不尽等同 _关系_（relationships），后者更加细致且存于 服务与其他服务广泛的交互语境，而非仅是启动中遵循的顺序。systemd 把这些统称“依赖”，不过做了些具体分类：

正依赖，被正依赖，负依赖，顺序依赖，重载传播依赖（reload propagators）。另外，OnFailure= 与 JoinsNamespaceOf= 自成一类，如 systemd 源代码中 UnitDependency 所枚举的那样。最后，还有些内部分类，比如触发器和引用（后者用于垃圾收集队列）。

正依赖包括：Requires=，Wants= 和 PartOf=。

被正依赖包括：RequiredBy= 和 WantedBy=（unit 文件安装时用到）。

负依赖是 Conflicts=。

顺序依赖是 Before= 和 After=。

重载传播依赖有 PropagatesReloadTo= 和 ReloadPropagatedFrom=。

上述分类中的一个显著特点在于，systemd 区分正依赖（如 Requires=）和顺序依赖。前者不影响后者，不指定顺序依赖的话，服务 将与 其正依赖的服务 同时启动。Requires= 是一种强的正依赖 - 若其依赖的服务失败，将致其也失败。相对的，Wants= 语义就要弱些。

这里着重指出，比较他基于依赖的 init 和 rc 系统，如 BSP init+rc.d 以及 OpenRC，systemd 对待顺序依赖做法是不同的！它将之视为 建议，而非须照办的命令。job 的处理管线和事务调度器可按照 每个启发规则 来自由安排，故最后生成的图，与配置相比，可能大相径庭。这些启发规则，常表现为 要么太松散，或是太严格（松散规则允许的，综合严格规则，往往出现相反的失败情形）。

除了这种高度晦涩以及 依赖图 作为机器资源 而外部不可见，依赖选项之间还有重复，甚至是打架。用户不知道这些潜规则，容易不经意间就配错关系（还有 ReloadPropagatedFrom= 这货，让人想起臭名昭著的 COMEFROM 陈述方式）。对了，所有的 units 默认设置 DefaultDependencies=true，即至少依赖 basic.target，shutdown.target，sysinit.target 以及 umount.target 作为隐含的启动等待点。

下一章节讨论 “勤劳的、做在前头” vs “懒惰处事”，以及与 服务关系（service relationships）之联系。

## 任何问题靠间接层搞定

许多用户大概觉得长长的处理流程，能更可靠，更正确，实则不然。例如，jobs、事务、unit 语义、systemd 风格的依赖，这些没有一个对应 Unix 的进程模型，其只是因为 systemd 被弄成 将资源和进程封装成对象的 系统（与一个定义清晰的进程监管器正好相反），同时为了激进地并行启动，而不得不引入的复杂度。难于衡量这种做法到底有多少收益，但一些初级的工具，如那些 守护工具（daemontools），数年来大量部署使用，似乎为这种过分复杂的做法之反例，待进一步观察。不管咋样，其设置中有些相对独有的失败情形：

### 启动顺序循环（Ordering cycles）

又有叫做 转圈的事务（cyclic transactions），因依赖图有环而产生的一个典型症状。对此，systemd 通常会丢弃某些 节点/jobs，丢的不巧会导致启动卡住。尤其会导致依赖循环（dependency loops）。

启动顺序循环 已知[很难调试](https://unix.stackexchange.com/questions/193714/generic-methodology-to-debug-ordering-cycles-in-systemd)，没啥通用方法可参照，因为最终的依赖信息仅存在内存。有时是因为 DefaultDependencies= 这个隐藏的默认依赖导致。

### 依赖循环（Dependency loops）

遇到启动顺序循环，systemd 丢弃某个 job，但随后又因依赖被排入，于是不断丢弃，不断排入，通常会让系统启动卡住。此处有多个发行版上的卡在 [NFS 和 rpbind](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=763315)，还有 [Zol](http://changelog.complete.org/archives/9237-first-impressions-of-systemd)，还有 [Xen](http://lists.opensuse.org/opensuse-factory/2015-05/msg01380.html)。许多其他情形，可能都简单报告成了启动顺序循环问题。

### 破坏型事务（Destructive transactions）

破坏型事务是指，关于某 job（不是 JOB_NOP 类型）的事务，该事务中排入了一个不可取消的 job，且该 job 不是 JOB_NOP 类型，且不适用每条合并规则故而不可合并。通常这意味着对 已存在的 job 进行的操作，将破坏其完整性。[该](https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1441253) [问](https://bbs.archlinux.org/viewtopic.php?id=182603) [题](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=776171) 已知影响重启和关机操作。

### 被卡住的 jobs（Stuck jobs）

一个或多个启动中的 jobs，花了[极](https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1440098) [长](https://bbs.archlinux.org/viewtopic.php?id=189369) 的时间（比如 30s，>1m）来等待同步完成，才继续下一步。借助 systemd-analyze(1) 也看不出内部调度行为的细节，故常简单粗暴地禁用肇事者。

### 不确定的启动顺序（Non-deterministic boot order）

如 bootup(7) 所述：

> The boot-up process is highly parallelized so that the order in which specific target units are reached is not deterministic, but still adheres to a limited amount of ordering structure.

就像并行化概念一样，操作顺序没必要是确定的，但最后的 _结果_ 必须是。但...解决依赖中，每次结果或多或少有差异。在 [QEMU 环境](https://askubuntu.com/questions/618105/systemd-non-determinism-early-on-in-boot-from-squashfs) 中报告过 systemd 对依赖信息的解释，每次启动都不一样。这是一例 作者明确所说的“不确定性”，更多的情形很可能被忽略了，因为用户在出现问题时往往再重启一下来解决。



 [1]: http://blog.darknedgy.net/technology/2015/10/11/0/
