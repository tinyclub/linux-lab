---
title: '嵌入式 Linux 启动时间优化'
author: Wu Zhangjin
layout: post
album: '嵌入式 Linux 知识库'
group: translation
permalink: /elinux-org-boot-time-optimization/
tags:
  - Boot Time
  - bootloader
  - eLinux.org
  - Ftrace
  - Grabserial
  - Kexec
  - Linux
  - Oprofile
  - Perf
  - Splash
  - XIP
  - 启动时间
categories:
  - Boot Time
  - Linux
---

> 书籍：[嵌入式 Linux 知识库][1]
> 原文：[eLinux.org][2]
> 翻译：[@lzufalcon][3]
> 校订：[@ibrother][4]

## 简介

本章包含的话题有启动时间的测量、分析、人因工程（human factors）、初始化技术和优化技巧等。

产品花在启动方面的时间直接影响终端用户对该产品的第一印象。

一个消费电子设备不管如何引人注目或者设计得怎么好，设备从关机状态到可交互的使用状态所需的时间对于获得正面的用户体验尤为关键。案例 &#35;1 就是在关机状态从头启动一个设备的例子。

启动一个设备涉及到许多步骤和一系列的事件。为了使用前后一致的术语，消费电子 Linux 论坛（CE Linux Forum）的[启动时间优化工作组][5]起草了一个术语词汇表，该表包括了相关术语在该领域内通用的定义。该词汇表如下：

  * [启动时间相关的词汇表][6]

## 技术/项目主页

下面主要介绍与减少 Linux 启动时间有关的各种技术。

有一部分描述了 eLinux.org 上可以下载的本地补丁，而其余部分则介绍了在其他地方维护的项目或者补丁。

### 测量启动时间

  * [Printk Times][7] &#8211; 用于显示每个 printk 的执行时间
  * [内核函数跟踪（Ftrace）][8] &#8211; 用于报告内核中每个函数的调用时间
  * [Linux 跟踪工具箱（LTT）][9] &#8211; 用于报告确切的内核和进程事件的时间数据
  * [Oprofile（译注：最新替代品是 perf）][10] &#8211; 通用的 Linux 分析器（Profile）
  * [Bootchart][11] &#8211; 用于 Linux 启动过程的性能分析和数据展示。收集启动过程中的用户空间部分的资源使用情况和进程信息，然后渲染成 PNG、SVG 或者 EPS 格式的图表。
  * [Bootprobe][12] &#8211; 一组用于分析系统启动过程的 [System Tap][13] 脚本
  * 当然，别忘了 `cat /proc/uptime` （译注：统计系统已经运行的时间）
  * [grabserial][14] &#8211; Tim Bird （译注：CE Linux Forum 主席）写的一个非常赞的工具用于记录控制台输出并打上时间戳
  * [进程跟踪][15] &#8211; 同样是 Tim Bird 写的一个简单补丁，用于记录 exec、fork 和 exit 系统调用。
  * [ptx&#95;ts][16] &#8211; Pengutronix 的时间戳记录器（TimeStamper）：一个简单的过滤器，可前置时间戳到标准输出（STDOUT）上，有点像 grabserial 但是不限于串口。
  * [Initcall（内核初始化函数）调试][17] &#8211; 一个用于显示 initcalls 所花时间的内核命令行选项
  * 也可以看下: [Kernel 检测工具][18]，里头列举了一些已知的内核检测工具，这些对于测量内核启动时间来说可能会有帮助。

### 减少启动时间的技术和技巧

#### 引导程序（Bootloader）加速

  * [就地执行（XIP）内核][19] &#8211; 允许内核在 ROM 或者 FLASH 上就地执行（XIP）
  * [在启动时通过 DMA 拷贝内核镜像][20]
      * 使用 DMA 从闪存（Flash）拷贝内核镜像文件到内存中
  * [采用未压缩的内核][21] &#8211; 一个未压缩的内核或许可以更快启动
  * [快速内核解压][22]

#### 内核加速

  * [关闭控制台][23] &#8211; 避免启动过程中的控制台输出开销（译注：尤其是串口控制台，会严重拖慢系统启动，甚至带来各种实时问题）
  * 关闭调试接口 和 `printk` &#8211; 避免调试接口和`printk`带来的开销，缺点是将丢失大量（对于调试可能有用）的信息
  * [不同步 RTC][24] &#8211; 避免在启动时延迟用 RTC 时钟边沿同步系统时间（可能带来时钟漂移）
  * [更短的 IDE 延迟时间][25] &#8211; 减少 IDE 启动延迟的持续时间（有效但是可能危险）
  * [硬编码内核模块信息][26] &#8211; 通过硬编码用于加载重定位信息的内容来减少加载模块的开销
  * [不侦测 IDE][27] &#8211; 强制内核使用 `ide<x>=noprobe` 命令行选项，从而绕过 IDE 侦测
  * [预设 LPJ][28] &#8211; 允许使用一个预设的 `loops_per_jiffy`（同样可以通过内核命令行选项设置）
  * [异步函数调用][29] &#8211; 允许侦测（Probe）函数或者其他函数并行处理，从而让耗时的启动活动并行起来
      * [设备侦测函数线程化][30] &#8211; 允许驱动并行地侦测设备（译注：没有提交到主线，不过内核有其他类似优化，比如异步函数调用，见 `kernel/async.c`）
  * [重排驱动初始化过程][31]
      * 允许驱动总线侦测尽可能快地启动（译注：总线 Probe 完以后，挂在上面的设备就可以相应地尽快完成 Probe）
  * [延迟 Initcalls][32] &#8211; 延迟不重要的模块初始化函数到主要启动过程之后
  * NAND ECC（Error Correcting Code）技术改进 &#8211; 2.6.28 之前的 `nand_ecc.c` 有改进的空间，可以从 [mtd git 仓库][33] 找到这样一个改善的版本，相应文档在[这里][34]。这个当且仅当系统使用软 ECC 校验时才有效
  * 检查内核正在使用哪个内存分配器，Slob 或者 Slub 可能比 Slab 更好，早期内核默认使用 Slab，可根据需要切换为 Slob 或者 Slub
  * 如果系统不需要，可以从内核中去掉 SYSFS 甚至 PROCFS 支持。一项测试表明删掉 SYSFS 可以节省 20 ms
  * 仔细调研所有的内核配置选项，看看它们是否有用。即使选上的选项最终没有用到，它也可能增加内核尺寸因而会增加内核加载时间（假设没有使用就地执行 XIP 功能）。通常，这个需要一些试验和测试！例如，选上 `CONFIG_CC_OPTIMIZE_FOR_SIZE`（在内核的 `General Setup` 配置菜单下面）在一个案例中能够产生 20ms 的启动优化。虽然不是很显著，但是对于启动时间优化来说，积少成多就能看到效果（Not dramatic, but when reducing boot time every penny counts!）。

  * 迁移到一个不同的编译器版本可能会产生更短和更快的代码。通常，新的编译器能够产生更优的代码。你也可以玩转一下各种编译器选项看看哪些表现最好。

  * 如果在内核中用上 initramfs 和压缩了的内核，那么最好是不要再压缩 initramfs。这个主要是为了避免重复两次解压数据。一个针对该问题的补丁被提交到了 LKML（译注：Linux 内核邮件列表）：<http://lkml.org/lkml/2008/11/22/112>

##### 文件系统方面的问题

对于同样的数据集，不同的文件系统拥有不同的初始化（即挂载，mounting）时间，这取决于元数据（meta-data）是否必须从存储器读到内存并且在挂载过程中使用哪种算法。

  * [文件系统信息][35] &#8211; 介绍了各种文件系统启动时间相关的信息
  * [文件系统][36] &#8211; 嵌入式系统关注的各类文件系统，也包括一些优化建议
  * [避免使用 Initramfs][37] &#8211; 解释了如果想极小化启动时间的话为什么不能使用 initramfs
  * 拆分分区。如果挂载一个文件系统耗费太久，那么可以考虑把一个文件系统拆分成两部分，一部分带有在启动时或者启动后立即需要的信息，而另外一部分可以（延迟到）后面挂载
  * [Ramdisks 用法澄清][38] &#8211; 解释为什么使用 Ramdisk 通常会引起更长的启动时间而不是更短

#### 用户空间和应用程序加速

  * [优化 RC 脚本][39] &#8211; 减少执行 RC 脚本的开销
  * [并行执行 RC 脚本][40] &#8211; 以并行而不是串行方式执行 RC 脚本
  * [就地执行应用程序][41] &#8211; 允许程序和库能够在 ROM 和 FLASH 中就地执行
  * [预链接][42] &#8211; 避免在首次加载程序时进行运行时链接
  * 静态链接应用程序。这样可以避免运行时链接。如果应用程序少的话会有用，这样也可以减少镜像文件的大小，因为不再需要动态库。
  * `GNU_HASH`: 在动态链接时有大约 50% 左右的速度改善
      * 可以看[这里][43]
  * [应用程序初始化优化][44] &#8211; 通过如下方法优化程序加载和初始化时间：
      * 使用 mmap vs. read
      * 采用页映射的特性
  * [把模块编译到内核镜像中][45]
      * 通过把模块加到内核镜像中可以避免模块加载的额外开销
  * 加速模块加载 &#8211; 使用 Alessio Igor Bogani 的内核补丁来改善模块加载时间：[加速符号定位进程][46]。
  * 避免使用 `udev`，因为它花费相当一部分时间来构建 `/dev` 目录。在嵌入式系统中，通常会事先知道需要哪些设备，在哪些情况下用哪些驱动，所以我们知道在 `/dev` 下，哪些设备入口需要创建，这些应该静态而不是动态创建。所以，在这里，`mknod` 是友，`udev` 是敌。
  * 如果你还是喜欢 `udev` 而且也喜欢快速启动，也可以尝试这种方法：在系统启动时开启 `udev` 并备份它创建的设备节点。接着，修改系统的初始化脚本成这样：不再运行 `udev`，而是把刚备份的设备节点拷贝到 `/dev` 目录中，之后再像往常一样安装热插拔守护进程（即 `udev`）。这个戏法避免了启动时的设备节点创建但是还是可以让系统在之后（按需动态）创建设备节点。
  * 如果设备有连接网络，最好使用静态 IP 地址。通过 DHCP 获取地址会增加时间并产生相应的额外开销。
  * 迁移到不同的编译器版本可以产生更短和更快的代码。通常新编译器产生更优的代码。你也可以玩转各个选项看看哪个最佳。
  * 如果可能，从 glibc 转到 uClibc。这个会产生更小的可执行文件因此会有更快的加载时间。
  * 库优化工具：<http://libraryopt.sourceforge.net/>

    该工具允许创建优化的库。不需要的函数会被移除因此而获得更好性能。正常情况下，有些库所占用的内存页面包含不会用到的代码（临近用到的代码），经过优化后，这种情况不会再发生，所以可以花更少的内存页面因此会有更少的内存加载，结果一些时间就会省掉。

  * [函数重排][47]

    这是一种技术，用于重排可执行文件中的函数，确保它们根据需要依次出现。它可以改善应用程序加载的时间，因为所有的初始化代码被打包成一组页面，而不是离散成多个不同的页面。

#### 系统休眠相关的改进

另外一个改善启动时间的途径是利用休眠相关的机制。已知的两种方案是：

  * 使用标准的休眠/唤醒方案。这个已经由来自三星的 Chan Ju, Park 演示过。看表格 23 以及之后的内容：[PPT][48] 以及这篇[论文][49] 的第 2.7 节。

    该方法的一个问题是闪存写比闪存读慢很多，所以实际上创建一个休眠镜像可能消耗相当长的一段时间。

  * 实现快照启动。这个由 Sony 的 Hiroki Kaminaga 完成并且描述在 [ARM 快照启动][50] 和 [Snapshot-boot-final.pdf][51]

    这个类似上述休眠/唤醒方案。但是休眠文件被保留并且在每次启动时使用。缺点是在制作快照时不可以挂载可写分区，否则当分区被修改，而休眠文件中的应用在映像中有未修改分区有关的信息时，就会产生不一致性。

#### 杂项

[关于压缩][52] 一文讨论了压缩技术在启动时间优化方面的效果。这个能够影响内核与用户空间两者的启动时间。

#### 一些未经验证的想法

该节只是对没来得及实现但可能利于启动优化的一些想法做一个记录。

  * **预填充的缓冲区高速缓存** &#8211; 因为 initramfs 执行了额外的数据拷贝，所以想法是可以有一个预填充的缓冲区高速缓存。一种简单的场景是当启动完成并且应用初始化完了以后，就允许把缓冲区高速缓存转存出来。然后这个数据可以在后续的启动中用于初始化缓冲区高速缓存（当然不需要拷贝了）。一种可能的方法是把这些数据直接打包到内核镜像中并直接使用，当然也可以选择分开加载。不幸地是，我现在具有的这块知识不足以做一个简单的实现。注意事项：

      * 是否可能把缓冲区高速缓存拆分成两个不同的部分，一个静态分配，另外一个动态分配？
      * 预填充的缓冲区高速缓存的内存页可能不能丢弃，所以他们需要被固定保护起来。
      * 除了缓冲区高速缓存数据外，一些其他的变量也可能需要保存
      * 类似的方法对于文件数据缓存也可能有效

  * **专用文件系统** &#8211; 当前的文件系统中有大量的抽象，这些抽象方便了新文件系统的添加并且为所有文件系统创建了统一视图。无疑这个设计很漂亮整洁，但是这些抽象层也引入了一些开销。一种解决方案或许是创建一个专有的文件系统，只支持 1 到 2 种文件系统，从而可以消除抽象层带来的开销。这或许会有用，不过合并到主线的几率为 0 。

## 文章和演讲稿

  * [嵌入式 Linux 启动时间优化研讨会材料][53]

      * 由 Free Electrons 提供
      * 一则关于启动时间优化技术的演讲稿 &#8211; Atmel SAMA5 硬件上的实际实验情况

  * &#8220;启动时间优化&#8221; &#8211; （[幻灯][54]

      * Alexandre Belloni 于 2012 年 11 月 6 日 在 ELC Europe 上做的报告
      * [Free-Electrons 上的入口][55]

  * &#8220;减少启动时间的正确途径&#8221; &#8211; （[幻灯][56]

      * Andrew Murray 于 2010 年 10 月 28 日 在 ELC Europe 上做的报告
      * 这个包含一个 1 秒钟启动的针对 SH7724 的 QT Linux 冷启案例研究，也有用户空间函数重排的信息
      * 类似的幻灯片，关于 1 秒钟启动的针对 OMAP3530EVM 的案例研究，可以从[这里][57] 找到。
  * &#8220;1 秒钟的 Linux 启动演示（新版）&#8221; ([Youtube 视频（来自MontaVista）][58])
  * &#8220;用于减少启动时间的工具和技巧&#8221; &#8211; （[幻灯][59], [ODP][60], [PDF][61]

      * Tim Bird 于 2008 年 11 月 7 日 在 ELC Europe 报告，展示了他当时收集的一些减少启动时间的技巧
      * [Tims 开发的快速启动工具][62] 提供了一些关于该报告的在线材料

  * [Christopher Hallinan][63] 于 2008 年在 MontaVista 视讯会议上做了一个关于如何减少启动时间的报告，幻灯在[这里][64]

  * [优化链接器加载时间][65]

      * 介绍各类启动时间优化、预链接等

  * [X86 上的启动延迟基准测试][66]

      * 由 Gilad Ben-Yossef 于 2008 年 7 月完成
      * 该教程关于如何使用 TSC 寄存器和内核的 `PRINTK_TIMES` 特性来测量 x86 系统启动时间，包括 BIOS、引导程序、内核以及第一个用户程序。

  * [嵌入式 Linux 的快速启动][67]

      * 来自韩国 ETRI 的 HoJoon Park 于 2008 年 7 月 在 CELF [3rd Korean Technical Jamboree][68] 做的报告。
      * 解释了用于减少不同阶段启动时间的不同技术

  * Tim Bird 做的关于启动时间优化技术的调查：

      * [用于优化 Linux 启动时间的方法][69]
          * 为 2004 年 Ottawa Linux 专题研讨会准备的论文
      * [减少嵌入式 Linux 系统的启动时间][70]
          * 2003 年 11 月的报告，描述了一些存在的启动时间优化技术和策略

  * 在消费电子设备上并行化 Linux 启动 &#8211; （[PDF][71]

  * [通过应用并行来获得更快的 Linux 启动速度][72]

      * 由来自 IBM Developer Works 的 M. Tim Jones 撰写
      * 该文展示了一些用于提高 Linux 启动速度的选项，包括两个用于并行初始化过程的方法，也展示了如何用图形可视化启动过程的性能数据。

  * [Android 启动时间优化][73]

      * 由来自 0xlab 的 Kan-Ru Chen 撰写
      * 该报告涵盖了 Android 启动时间测量、分析、以及提出的一些优化方法、基于休眠的优化技术以及一些潜在的 Andriod 用户空间优化技术。

  * TI 嵌入式处理器的维基也提供了一些信息，描述了 Linux/Android 启动时间的优化过程

      * [Linux 启动时间优化][74]
      * [Android 启动时间优化][75]

  * [实现 Android 的检查点技术（Checkpointing）][76]

      * 由 0xlab 的 Kito Cheng 和 Jim Huang 撰写
      * 实现 Android 检查点技术（Checkpointing）的原因
          * 恢复到事先存储的状态可以获得更快的 Android 启动时间
          * 基于定期检查点技术可以获得更好的产品试用体验

### 案例研究

  * [在用 NAND 的 ARM 机器上做到从引导程序启动到 Shell 只花 300 ms][77]
  * 三星的关于数码照相机的可行性（Proof-Of-Acceptability）研究，看这里：[启动时间优化 PPT][48] 和 [论文][49]
  * [1 秒内把 Linux 从关机状态启动到用户空间][78]
      * 在该文中，Robin Getz 描述了用于加速 blackfin 开发板的技术
  * [在 3.2 秒内启动 Linux dm365 网络照相机][79]
  * [在 0.5 秒内启动内核和 Shell (不包括 U-boot 和解压)][80]
  * [Warp2, Lineo Solutions, 2008年，2.97 秒启动, ARM11, 400MHz][81]

## 其他的项目/邮件列表/资源

### SysV &#8216;init&#8217; 的替代品

启动 Linux 系统的传统方法是用 `/sbin/init`，它是一个初始化程序，负责解析 `/etc/inittab`，并能够针对不同的运行级别和系统事件（各类按键组合和电源事件）产生一系列动作。

可查看 [init(8) 手册页][82] 和 [inittab(5) 首页页][83] 获取更多信息。

#### busybox init

[BusyBox][84] 通常包含一个 `init` 小程序。

截止 2000 年，Busybox init 和全功能的 init 之间，`inittab` 支持的特性稍微有些差异。但是不知道到 2010 以后（译注：现在都 2015 年了，看来这个文章真地有点老了，后面有时间很多材料得好好整理下），情况是否依旧。可以从[这里][85]看到一些细节。

Denys Vlasenko, Busybox 的维护人员之一，曾经建议用名叫 `runsv` 的工具替换掉传统的 `init`，可以看下[这里][86]。

#### upstart

`upstart` 是一个新的 Linux 桌面工具，它提供了 `/sbin/init`，但是实现了不同的操作语义：

  * 首页：<http://upstart.ubuntu.com/>
  * 维基百科地址：<http://en.wikipedia.org/wiki/Upstart>

#### Android init

Android `init` 是专门为启动 Andriod 系统而定制的程序，看[这里][87]。

#### systemd

systemd 是一个新的项目 (就当时 2010 年 5 月而言)，用于在 Linux 桌面系统中启动守护进程和服务，可以看看[这里][88]。

### Kexec

  * Kexec 允许系统不经 BIOS 重启（注：与通常的重启不同）。也就是说，一个 Linux 内核可以无需进入引导程序就能直接启动另外一个 Linux 内核，白皮书在[kexec.pdf][89]。
      * 这里是另外一篇文章：[使用 kexec 快速重启 Linux][90]

### 启动画面（Splash Screen）项目

  * [Splashy][91] &#8211; 一种在启动过程的早期阶段放置启动画面的技术，这个是用户空间代码。
      * 这个貌似是最新的启动画面技术，为主流发行版所用。为了支持该技术，需要在内核中添加一个 Framebuffer 驱动。
  * [Gentoo Splashscreen][92] &#8211; 一种在启动过程早期放置启动画面的新技术
  * [PSplash][93] &#8211; PSplash 是一种用户空间的图形化引导启动画面，主要针对嵌入式 Linux 设备，支持 16bpp 或者 32bpp 的帧缓冲。

### 其他

  * [基于休眠快照启动][94] &#8211; 一种用软件唤醒来快速启动系统的技术

## 正在从事快速启动的公司、个人或者项目

  * Intel &#8211; Arjan van de Ven &#8211; see <http://lwn.net/Articles/299483/>
  * fastboot Git 仓库 &#8211; see <http://lwn.net/Articles/299591/>
  * Free Electrons - <http://free-electrons.com/services/boot-time/>

## 启动时间检查清单

可以从 2009 年 8 月的一个关于 ARM 设备上启动时间的讨论中找到一些事关启动时间优化的提示和建议。

虽然可能会重复本文中已经介绍的内容，但是咱们还是从上述讨论中提取了一个检查清单（译注：可以方便启动优化时做检查）：

  * CPU 时钟频率切到最大了吗？如果内核、引导程序或者硬件负责设置 CPU 功率和速度，那么我们得确保各 CPU 用最大速度而不是最低速度启动。

  * SOC 上的内存接口硬件（寄存器）的定时配置（例如 RAM 和 NOR/NAND 定时）优化过吗？许多供应商卖硬件时采用保守的设置：“好吧，工作了，以后再优化”。我们想要的配置是：“尽可能地快，但是还得稳定且可靠”。这部分可能需要一些硬件知识并且必须为不同内存设备做不同配置（译注：不同内存设备特性不一样，比如说工作频率会有差异）。

  * 我们的引导程序用了指令和数据缓存吗？例如 U-Boot 在 ARM 设备上默认没有使能数据缓存，因为要使能数据缓存，需要额外定制 MMU 表。

  * 内核从存储设备（例如 NOR 或者 NAND）拷贝到内存中使用了优化过的方法吗？比如 DMA 或者是 ARM 上至少得用上 `load/store multiple` 命令（ldm/stm）？

  * 如果用 U-boot 的 uImage，在启动参数中设置 `verify=no` 可以避免校验码验证。

  * 优化内核的尺寸

      * 可以尝试一些针对嵌入式系统的内核配置选项，例如，消除所有的 printk 字符串，减少数据结构或者消除不需要的功能。

  * 拷贝了几次内核镜像数据？第一次由引导程序从存储设备拷到内存，然后内核的解压程序负责解压到最终的位置？如果使用压缩了的内核和 NOR 闪存，可以考虑在 NOR 闪存中就地执行（XIP）解压器。

  * 如果使用了压缩内核，检查下压缩算法。zlib 在解压方面较慢，而 lzo 则更快。所以如果采用 lzo 压缩，我们也可以加速一些东西（可以从 LKML 查看这些）。如果没有任何压缩也可能是一件好事（看下一个话题）。

  * 检查是否使用了未压缩的内核（根据系统配置）。在闪存系统上使用未压缩的内核可以优化启动时间。原因是当存储设备的速率低于解压速率时，压缩过的内核才有优势（译注：拷贝时间 v.s. 解压时间）。在支持 DMA 的典型嵌入式系统上，其读取到内存的速率胜过基于 CPU 的解压速率。当然，这取决于很多方面，比如闪存控制器的性能、内核存储文件系统性能、DMA 控制器性能、缓存架构等。所以，每个系统会有个体差异。举例来说：使用未解压的内核（约 2.8MB）解压（在 NOR 闪存中就地执行解压程序）比从闪存拷贝 2.8MB 内核到内存中多花费了约 0.5 秒。

  * 使用提前计算好的 `loops-per-jiffy`，（译注：然后通过内核命令行参数传给内核，可避免执行重新计算的代码）

  * 使能内核 `quiet` 选项（译注：可关闭控制台输出）

  * 如果使用 UBI 文件系统：UBI 用到 MTD 设备上相当缓慢。细节在 MTD 的 [UBI 伸缩性][95] 一文中有解释。如果不用 UBI2，我们基本啥也优化不了，UBIFS 将没啥用（UBIFS would stay intact），有一些关于这个的讨论，并且貌似要做 UBI2 相当困难：（[一些想法][96]）。

      * 紧跟着的邮件里头，Sascha Hauer 写到：

    > &#8220;非常有趣的是，内核 NAND 驱动比 U-boot 中的慢很多，看完发现结果是内核驱动用了中断来判断控制器是否准备好，换成轮询以后 NAND 的性能提升了一倍。UBI 挂载更快并且这个为启动过程又省掉了几秒钟 :-) “

  * 启动时使用静态设备节点，之后再设置 Busybox mdev 来做动态热插拔

  * 如果使能了网络，那么在网络代码路径中可能会有很长的超时设定，具体取决于是否指定了静态地址。可以看下 `net/ipv4/ipconfig.c` 文件中的定义：`CONF_PRE_OPEN` 和 `CON_POST_OPEN` 以及[IP 延迟配置补丁][97].

  * 并行化启动过程

  * 关闭该选项：&#8221;Set system time from RTC on startup and resume&#8221;，可避免减慢内核启动。（要实现 RTC 同步），我们可以在 init 末尾使用 `hwclock -s` 命令。

[分类][98]:

  * [启动时间][99]
  * [引导程序][100]
  * [消费电子 Linux 工作组][101]





 [1]: http://tinylab.gitbooks.io/elinux
 [2]: http://eLinux.org/Boot_Time "http://eLinux.org/Boot_Time"
 [3]: https://github.com/lzufalcon
 [4]: https://github.com/ibrother
 [5]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Bootup_Time_Working_Group/Bootup_Time_Working_Group.html "Bootup Time Working Group"
 [6]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Boot-up_Time_Definition_Of_Terms/Boot-up_Time_Definition_Of_Terms.html "Boot-up Time Definition Of Terms"
 [7]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Printk_Times/Printk_Times.html "Printk Times"
 [8]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Kernel_Function_Trace/Kernel_Function_Trace.html "Kernel Function Trace"
 [9]: http://tinylab.gitbooks.io/elinux/content/zh/dbg_portal/kernel_trace_and_profile/Linux_Trace_Toolkit/Linux_Trace_Toolkit.html "Linux Trace Toolkit"
 [10]: http://oprofile.sourceforge.net/news/
 [11]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Bootchart/Bootchart.html "Bootchart"
 [12]: http://people.redhat.com/berrange/systemtap/bootprobe/
 [13]: http://tinylab.gitbooks.io/elinux/content/zh/dbg_portal/kernel_trace_and_profile/System_Tap/System_Tap.html "System Tap"
 [14]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Tims_Fastboot_Tools/Tims_Fastboot_Tools.html#grabserial "Tims Fastboot Tools"
 [15]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Tims_Fastboot_Tools/Tims_Fastboot_Tools.html#Tim.27s_quick_and_dirty_process_trace "Tims Fastboot Tools"
 [16]: http://pengutronix.de/software/ptx_ts/index_en.html
 [17]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Initcall_Debug/Initcall_Debug.html "Initcall Debug"
 [18]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Kernel_Instrumentation/Kernel_Instrumentation.html "Kernel Instrumentation"
 [19]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Kernel_XIP/Kernel_XIP.html "Kernel XIP"
 [20]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/DMA_Copy_Of_Kernel_On_Startup/DMA_Copy_Of_Kernel_On_Startup.html "DMA Copy Of Kernel On Startup"
 [21]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Uncompressed_kernel/Uncompressed_kernel.html "Uncompressed kernel"
 [22]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Fast_Kernel_Decompression/Fast_Kernel_Decompression.html "Fast Kernel Decompression"
 [23]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Disable_Console/Disable_Console.html "Disable Console"
 [24]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/RTC_No_Sync/RTC_No_Sync.html "RTC No Sync"
 [25]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Short_IDE_Delays/Short_IDE_Delays.html "Short IDE Delays"
 [26]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Hardcode_kernel_module_info/Hardcode_kernel_module_info.html "Hardcode kernel module info"
 [27]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/IDE_No_Probe/IDE_No_Probe.html "IDE No Probe"
 [28]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Preset_LPJ/Preset_LPJ.html "Preset LPJ"
 [29]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Asynchronous_function_calls/Asynchronous_function_calls.html "Asynchronous function calls"
 [30]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Threaded_Device_Probing/Threaded_Device_Probing.html "Threaded Device Probing"
 [31]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Reordering_of_driver_initialization/Reordering_of_driver_initialization.html "Reordering of driver initialization"
 [32]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Deferred_Initcalls/Deferred_Initcalls.html "Deferred Initcalls"
 [33]: http://git.infradead.org/mtd-2.6.git?a=blob_plain;f=drivers/mtd/nand/nand_ecc.c;hb=HEAD
 [34]: http://git.infradead.org/mtd-2.6.git?a=blob_plain;f=Documentation/mtd/nand_ecc.txt;hb=HEAD
 [35]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Filesystem_Information/Filesystem_Information.html "Filesystem Information"
 [36]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/File_Systems/File_Systems.html "File Systems"
 [37]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Avoid_Initramfs/Avoid_Initramfs.html "Avoid Initramfs"
 [38]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Ramdisks_demasked/Ramdisks_demasked.md "Ramdisks demasked"
 [39]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Optimize_RC_Scripts/Optimize_RC_Scripts.html "Optimize RC Scripts"
 [40]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Parallel_RC_Scripts/Parallel_RC_Scripts.html "Parallel RC Scripts"
 [41]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Application_XIP/Application_XIP.html "Application XIP"
 [42]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Pre_Linking/Pre_Linking.html "Pre Linking"
 [43]: http://sourceware.org/ml/binutils/2006-06/msg00418.html
 [44]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Application_Init_Optimizations/Application_Init_Optimizations.html "Application Init Optimizations"
 [45]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Include_modules_in_kernel_image/Include_modules_in_kernel_image.html "Include modules in kernel image"
 [46]: http://comments.gmane.org/gmane.linux.kernel.embedded/3508
 [47]: http://www.celinux.org/elc08_presentations/DDLink%20FunctionReorder%2008%2004.pdf
 [48]: http://eLinux.org/images/9/98/LinuxBootupTimeReduction4DSC.ppt "LinuxBootupTimeReduction4DSC.ppt"
 [49]: http://www.kernel.org/doc/ols/2006/ols2006v2-pages-239-248.pdf
 [50]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Suspend_To_Disk_For_ARM/Suspend_To_Disk_For_ARM.html "Suspend To Disk For ARM"
 [51]: http://elinux.org/images/3/37/Snapshot-boot-final.pdf
 [52]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/About_Compression/About_Compression.html "About Compression"
 [53]: http://free-electrons.com/doc/training/boot-time/
 [54]: http://elinux.org/images/d/d1/Alexandre_Belloni_boottime_optimizations.pdf
 [55]: http://free-electrons.com/blog/elce-2012-videos/
 [56]: http://elinux.org/images/f/f7/RightApproachMinimalBootTimes.pdf
 [57]: http://www.slideshare.net/andrewmurraympc/t-iswift-boot
 [58]: http://www.youtube.com/watch?v=-l_DSZe8_F8
 [59]: http://eLinux.org/images/9/98/Tools-and-technique-for-reducing-bootup-time.ppt "Tools-and-technique-for-reducing-bootup-time.ppt"
 [60]: http://eLinux.org/images/4/40/Tools-and-technique-for-reducing-bootup-time.odp "Tools-and-technique-for-reducing-bootup-time.odp"
 [61]: http://eLinux.org/images/d/d2/Tools-and-technique-for-reducing-bootup-time.pdf "Tools-and-technique-for-reducing-bootup-time.pdf"
 [62]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Tims_Fastboot_Tools/Tims_Fastboot_Tools.html "Tims Fastboot Tools"
 [63]: http://www.mvista.com/download/author.php?a=37
 [64]: http://www.mvista.com/download/power/Reducing-boot-time-techniques-for-fast-booting.pdf
 [65]: http://lwn.net/Articles/192082/
 [66]: http://benyossef.com/benchmarking-boot-latency-on-x86/
 [67]: http://tree.celinuxforum.org/CelfPubWiki/KoreaTechJamboree3?action=AttachFile&do=get&target=The_Fast_Booting_of_Embedded_Linux.pdf
 [68]: http://tree.celinuxforum.org/CelfPubWiki/KoreaTechJamboree3
 [69]: http://kernel.org/doc/ols/2004/ols2004v1-pages-79-88.pdf
 [70]: http://eLinux.org/images/7/78/ReducingStartupTime_v0.8.pdf "ReducingStartupTime v0.8.pdf"
 [71]: http://tree.celinuxforum.org/CelfPubWiki/ELCEurope2007Presentations?action=AttachFile&do=view&target=par.pdf
 [72]: http://www.ibm.com/developerworks/cn/linux/l-boot-faster/
 [73]: http://www.slideshare.net/kanru/android-boot-time-optimization
 [74]: http://processors.wiki.ti.com/index.php/Optimize_Linux_Boot_Time
 [75]: http://processors.wiki.ti.com/index.php/Android_Boot_Time_Optimization
 [76]: http://www.slideshare.net/jserv/implement-checkpointing-for-android-elce2012
 [77]: http://www.makelinux.com/emb/fastboot/omap
 [78]: https://docs.blackfin.uclinux.org/doku.php?id=fast_boot_example
 [79]: http://e2e.ti.com/support/embedded/f/354/t/51158.aspx
 [80]: http://e2e.ti.com/support/dsp/davinci_digital_media_processors/f/100/p/7616/30088.aspx
 [81]: http://www.theinquirer.net/inquirer/news/1049451/linux-boots
 [82]: http://linux.die.net/man/8/init
 [83]: http://linux.die.net/man/5/inittab
 [84]: http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/BusyBox/BusyBox.html "BusyBox"
 [85]: http://spblinux.de/2.0/doc/init.html
 [86]: http://busybox.net/~vda/init_vs_runsv.html
 [87]: http://eLinux.org/Android_Booting#.27init.27 "Android Booting"
 [88]: http://0pointer.de/blog/projects/systemd.html
 [89]: http://elinux.org/images/2/2f/ELC-2010-Damm-Kexec.pdf
 [90]: http://www.ibm.com/developerworks/cn/linux/l-kexec/index.html
 [91]: https://wiki.archlinux.org/index.php/Splashy_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
 [92]: https://wiki.gentoo.org/wiki/Fbsplash
 [93]: http://git.yoctoproject.org/cgit/cgit.cgi/psplash
 [94]: http://tree.celinuxforum.org/CelfPubWiki/
 [95]: http://www.linux-mtd.infradead.org/doc/ubi.html#L_scalability
 [96]: http://www.linux-mtd.infradead.org/faq/ubi.html#L_attach_faster
 [97]: http://patchwork.kernel.org/patch/31678/
 [98]: http://eLinux.org/Special:Categories "Special:Categories"
 [99]: http://eLinux.org/Category:Boot_Time "Category:Boot Time"
 [100]: http://eLinux.org/Category:Bootloader "Category:Bootloader"
 [101]: http://eLinux.org/Category:CE_Linux_Working_Groups "Category:CE Linux Working Groups"
