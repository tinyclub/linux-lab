---
title: Linux 片面报告：从 4.0 到 4.2
author: Chen Jie
layout: post
group: news
permalink: /linux-one-sided-reports-from-4-0-to-4-2/
tags:
  - BPF
  - DAX
  - F2FS
  - KASan
  - KDBUS
  - kernel C
  - Live patching
  - Linux
categories:
  - 技术动态
---

<!-- title: Linux 片面报告：从 4.0 到 4.2 -->

<!-- %s/!\[image\](/&#038;\/wp-content\/uploads\/2015\/06\// -->

> by Chen Jie of [TinyLab.org][1]
> 2015/6/28


## 前言

Linux 4.1 刚刚发布。近期的 Linux 4.0，4.1 和（开发中的）4.2，似与 TinyLab 诸文有些缘分。且让我们从这角度，带着“偏见”来看看。

## 4.0

『[Linux 技术报告：从 3.10 到 4.0][2]』 从电源管理、性能、稳定性和安全性几个方面回顾了此间版本，其中 4.0 版本亮点：

### Live patching

无需重启给内核代码打补丁，大量用到了 ftrace 技术，且是独立的代码 － 无需更改其他子系统。泰晓尚未有文章细细道来，@TinyLab，不来一篇吗？

### DAX

我们都知道文件访问先读到内存，然后再访问。某些情况下，例如欲来的 **持续性非易失内存**（persistent non-volatile memory，断电内容不丢失）作磁盘用时，还要拷贝到内存再去读，就属脱裤子放屁 —— 多此一举了。于是有了 DAX —— Direct Access, the X is for eXciting。

『[Clear Containers 介绍][3]』了 Intel 轻量级虚拟机的实现 —— 如此“轻量”，以至于开销可比拟容器（同时有着硬件隔离更安全）：

  * 更少的启动开销。分别优化启动过程中的三阶段： Hypervisor、Kernel 和 Userspace。
  * 更少的内存开销。其中 DAX 便是内存开销减少的第一功臣，其次为 KSM。

### KASan 内存访问检查工具

利用编译器特性，动态地检查内核地址错误：

  * 访问已释放的内存地址
  * 访问越界

特点是比 kmemcheck 快一大截。

Linux 内核作为最成功的开源项目之一，坐拥许多先进特性，这些特性能否共享给用户空间呢？

比如我们在做 [memcpy 优化][4]时，发现加入少数宏开关，就能将内核 memcpy 实现移到用户空间来。

想像一下，若内核的 C 库、C Utils（比如 [User-space RCU][5]） 以及 KASan 为代表的基础设施，共享给用户空间？不仅代码复用降低了维护工作量，更能将社区最优秀的成果推广开来，进而使得代码、APIs 风格统一，使 Linux 呈现更好的整体性。

甚至 [Linux 内核通过 VDSO 机制，将内核例程映射给用户态][6]？这样两者没准还能共享例程代码所在物理内存页，从而进一步减少内存占用！（也许不能？此处仅 YY）

### 新挂载项 &#8220;lazytime&#8221; 与 overlayfs 增强

如果留意下手机的挂载信息，例如 `adb shell；cat /proc/self/mountinfo`，大概能看到其中 “relatime” 样字出没。“relatime” 有益性能却不符合 POSIX 规范所约定的行为。有了 “lazytime”，就能既符合规范又不损性能。

overlayfs 能将多个文件系统内容合并、层叠起来，是实现[桌面应用容器化][7]的核心技术。

## 4.1

### 最热闹的论战 &#8211; KDBUS 终未合并

KDBus 是用户态 DBus 服务（高级别的 IPC 服务）在内核中的实现。由 systemd、Tizen 以及 Linux 车载系统等社区推动。然而引起了剧烈论战，『[KDBUS 合入 Linux Kernel：激烈论战，目前暂歇][8]』 一文回顾了期间来来往往的邮枪邮战。

最新消息：

  * Linus 表示 Greg 是个好同志，相信他的判断，在合适的时候进行合并。
  * KDBUS 作者 Greg Kroah-Hartman（似乎已是 Linux 内核社区的二号人物？），表示将进行更多调整和测试，期望在 4.3 时候进行合并。

### 改动汇总

  * 调度器：重新实现了 CPU 的负载计算方法，计算出的负载与当前 CPU 速度无关。其改善了 CPU 变频情形下的负载均衡，并更好地支持 big.LITTLE。
  * perf：能在 KProbe 上附加 BPF 程序；新增支持 Intel （即将到来） cache QoS 状态监视；新增支持处理器硬件 Tracer 功能（貌似是可编程的）。

    BPF 是种伪汇编，由用户态提供给内核，内核检查后 JIT 执行。用户程序从而能够向内核安全地注入代码，用于包过滤、内核性能剖析、调试等等。啧啧，又是个大杀器。

  * zram：可以压缩块数据了。

  * 多用户模式成为可选。对于“小”的嵌入式设备非常有用。『[Linux 在谋求安全与统一][9]』提到了物联网应用中，“小”的硬件对 Linux 内核带来的挑战。
  * KVM：支持 MIPS 的浮点单元和 SIMD 模式；支持 ARM 的中断注入（irqfd()）。
  * 新增“简单持续性内存”驱动：改善内核对“大型非易失性内存设备”的支持。
  * ext4 文件系统：现在支持文件和文件夹加密了。
  * DRM：支持虚拟的 GEM，用作虚拟显卡的内存管理。
  * MIPS：支持 XPA 寻址模式，32 位系统上访问 40 位内存地址。
  * ARM64：支持 ACPI 接口啦。
  * 新增 tracefs：从 debugfs 中独立出来。现在可以只进行性能剖析，而不用同时暴露内核调试接口。
  * aio\_read/write 被移走，由 read\_iter/write_iter 所替代。

### MIPS：csum 优化补丁并入

对于超标量的 MIPS 处理器而言，IP 校验和性能将翻一倍。通过证明校验算法的结合律，并用结合律破了指令硬相关，从而提升指令并发度。其中细节详见『[IP 校验和计算优化：四两拨千斤][10]』。

该优化本质上是对算法优化，故可以推广到其他体系架构上，同时也适于 C 的参考实现版本。

## 4.2

4.2 尚在代码合并期间，以下特性也许不会体现在最终版本上：

  * Libnvdimm 子系统引入。又是非易失内存设备，目测要火了～
  * IO 调度器 CFQ 针对 SSD 优化。IO 调度器 CFQ 启发自 CPU 调度器 CFS，其公平性体现在时间占用公平。优化后公平性体现在 IOPS（Input/Output Operations Per Second）数公平。约有 12% 性能提升。顺便说一句，NCQ TRIM 也有改善，4.2 的 SSD IO 性能改善，值得期待。
  * F2FS 支持加密单个文件。F2FS（Flash-Friendly File-System）是目前 SSD 介质上性能最好的文件系统。
  * Crypto 子系统：新的公钥加/解密 API 引入，同时支持支持硬件和软件实现的公钥加/解密。
  * Crypto 子系统：新的 Jitter Entropy 随机数生成器引入。以 CPU 执行时间的抖动，作为随机源。生成的随机数，可作为其他随机数生成器的种子。

    本站『[/dev/urandom 不得不说的故事][11]』 讲述了内核随机数的故事。其中提到由于启动早期熵缺乏，而需要注入存于磁盘的种子文件，来确保启动时刻随机数的质量。到了 4.2，可以从“Jitter Entropy RNG” 得到种子，无需用户态代码来加载种子了。

  * KVM：x86 上支持写合并、SMM（System Management Mode）

  * 排队自旋锁合并。非竞态下轻微提升，重度竞态（4 槽以上的 NUMA 系统）下明显提升。

    本站『[实用同步原语伸缩技术：如何设计高性能的锁定原语][12]』系统介绍了这些年来，Linux 在多核多线程、各种竞态下锁的改进。顺便说个小花絮，该文中特别鸣谢了惠普的 Linux 性能工作组。而本次补丁也由惠普所提交。可见惠普在此领域的积攒，由此对 The Machine 项目期待值++。





 [1]: http://tinylab.org
 [2]: /linux-technical-report-from-3-10-to-4-0
 [3]: /clear-containers-introduction
 [4]: /assembly-practice-loongson-processor-memcpy-optimization
 [5]: https://lwn.net/Articles/573424/
 [6]: https://lwn.net/Articles/417647/
 [7]: https://blogs.gnome.org/uraeus/2014/07/10/desktop-containers-the-way-forward/
 [8]: /kdbus-in-linux-kernel-the-debate-the-current-respite
 [9]: /linux-seeks-security-and-unity-cn
 [10]: /ip-checksum-calculation-optimization-four-two-ounces
 [11]: /myths-about-urandom
 [12]: /practical-synchronization-primitives-retractable-technologies-how-to-design-a-high-performance-locking-primitives
