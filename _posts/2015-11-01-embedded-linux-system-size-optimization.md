---
layout: post
author: 'Wen Pingbo'
title: "嵌入式 Linux 系统裁剪"
album: "嵌入式 Linux 知识库"
group: translation
permalink: /embedded-linux-system-size-optimization/
description: "介绍了 Linux 系统裁剪相关的信息"
category:
  - 系统裁剪
tags:
  - Linux
  - System Size
---

> 书籍：[嵌入式 Linux 知识库](https://tinylab.gitbooks.io/elinux)
> 原文：[eLinux.org](http://eLinux.org/System_Size "http://eLinux.org/System_Size")
> 翻译：[@wengpingbo](https://github.com/wengpingbo)
> 校订：[@lzufalcon](https://github.com/lzufalcon)

## 介绍

本文介绍一些与 Linux 系统尺寸优化相关的信息和项目。

## 减少系统尺寸的技术


### 内核尺寸缩减

另一个 WIKI，[https://tiny.wiki.kernel.org/](https://tiny.wiki.kernel.org/)，在内核尺寸优化方面，有一些新的信息和工作（截止到 2014.08）。


#### 配置选项

-   [内核尺寸优化指北](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/System_Size/Kernel_Size_Tuning_Guide/Kernel_Size_Tuning_Guide.html "Kernel Size Tuning Guide") -
    关于计算内核尺寸，配置内核来达到最小尺寸的文档


#### Linux-tiny 补丁集

-   [Linux Tiny](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/System_Size/Linux_Tiny/Linux_Tiny.html "Linux Tiny") 是能够使 Linux 内核占用更小空间的补丁集。Linux-tiny 的长期目标是把这些补丁合入主线内核中。在过去的几年里，有几个补丁已经合入到主线内核，而且相关工作还在持续。


#### "dietnet"

Andi Kleen 在 2014.05，提交了一系列补丁，用来减少 Linux 内核网络协议栈的大小。相关的提交记录在这里：
[https://lkml.org/lkml/2014/5/5/686](https://lkml.org/lkml/2014/5/5/686)

Andi 指出这些补丁支持 3 个使用场景：

-	全功能网络协议栈（默认是 Linux 网络协议栈）
-	只有客户端堆栈 - 功能有缩减，但仍然兼容正常的用户空间程序，对一些使用场景是合适的
-	只包含最小的子集，这可能需要一些特殊的用户态软件来配合

为了获得全面的尺寸缩减，在使用这些补丁的时候，最好同时使用 LTO。这样，网络协议栈只需 170K 就能跑起来（默认的协议栈需要 400K）


#### 减少内核尺寸相关的编译选项

这里有一篇 LWN 文章讨论了用于裁剪内核的 3 个 GCC 选项。

[使用 GCC 缩减内核](http://lwn.net/Articles/67175/)

第一个选项是 `-Os`，这早就在 tiny kernel 补丁里。

在 3.4 版本之后，GCC 提供一个 `-funit-at-a-time` 选项。这让 GCC 能够更好的移除内联和无用的代码，减少 text 和 data 段的大小。这个选项依赖另一个补丁。根据 GCC 手册，这个选项不再起作用。

`-fwhole-program` 和 `--combine` 选项的组合，其效果上等于把所有的源文件分组，且把所有的变量静态化。GCC 依旧支持这些选项，但在 BusyBox 的配置选项里已经不提供了。这发生了什么？

另外一个选项，`-mregparm=3`，看上去是 X86 特有的，它告诉编译器对于函数的前 3 个参数，用寄存器存储。（by John Rigby）

访问 [[1]](http://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html) 查阅所有可用的优化选项，访问 [编译器优化](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/System_Size/Compiler_Optimization/Compiler_Optimization.html "Compiler Optimization") 查阅更多关于优化选项效果的细节。


#### 垃圾回收补丁集

这些 [补丁](http://busybox.net/~vda/k-sections/) ，通过在链接阶段提高无用代码 / 数据的剔除效果，可以缩减大约 10% 的内核大小。它们正在往内核主线提交。由于一个链接器的 [BUG](https://bugzilla.redhat.com/show_bug.cgi?id=621742)，这些补丁的接受依赖于一个新版本链接器（在 binutils-2.21 将会提供）。好消息是这个 BUG 只是影响一些特定的架构（parisc），所以这些补丁在旧的链接器上还是可以使用的。


#### 运行时内核大小

通常，内核内存大小的缩减主要关注内核静态编译的镜像大小。但是，内核在运行时也要动态分配内存。在加载时，内核会创建多个表，给网络，文件系统等模块使用。

以下表格展示了，在 2.6 版本内核里，不同的哈希表所占用的内存大小。（表格来自 [data_structures](http://logfs.org/~joern/data_structures.pdf) 第 25 页）

<table border="1" cellspacing="0" cellpadding="5" align="center">
<tr>
<th>Hash Table         </th>
<th>memory &lt; 512MiB RAM </th>
<th> memory &gt;=512MiB RAM
</th></tr>
<tr>
<th>                   </th>
<th>32b/64b       </th>
<th>32b/64b
</th></tr>
<tr>
<td>TCP established    </td>
<td>96k/192k      </td>
<td>384k/768k
</td></tr>
<tr>
<td>TCP bind           </td>
<td> 64k/128k     </td>
<td> 256k/512k
</td></tr>
<tr>
<td>IP route cache     </td>
<td> 128k/256k    </td>
<td>   512k/1M
</td></tr>
<tr>
<td>Inode-cache        </td>
<td>  64k/128k    </td>
<td>   64k/128k
</td></tr>
<tr>
<td>Dentry cache       </td>
<td>   32k/64k    </td>
<td>    32k/64k
</td></tr>
<tr>
<td>Total             </td>
<td>  384k/768k   </td>
<td> 1248k/2496k
</td></tr></table>



##### 内核栈大小

内核有一个配置选项，用来减少每一个进程的内核栈大小到 4K。内核栈大小默认是 8K（截止到 2011）。如果你有很多进程，使用 4K 的栈能够减少内核栈的使用。

更多关于内核栈大小的信息： [小型内核栈](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/System_Size/Kernel_Small_Stacks/Kernel_Small_Stacks.html "Kernel Small Stacks")


#### 自动裁剪

在 2012 年，Tim Bird 研究了几种关于自动尺寸缩减和整体系统优化的技术。特别是他研究的如下几项：

-	内核链接时优化
-	系统调用消除
-	全局限制
-	内核栈大小缩减

Tim 同时也在链接时重写和静态代码压缩技术方面发现了一些非常有趣的学术研究。（**注**：部分研究见 [Tiny Linux Kernel](http://elinux.org/Work_on_Tiny_Linux_Kernel)）Tim 在 2013 年 5 月在日本举行的 LinuxCon 会议上展示了他的工作。

这次展示的一些提纲和完整的幻灯片可以这里找到 [系统尺寸自动缩减](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/System_Size/System_Size_Auto-Reduction/System_Size_Auto-Reduction.html "System Size Auto-Reduction")


#### PRINTK 消息压缩

在 2014 年，一个开放项目提议，[压缩的 printk 消息](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/System_Size/Compressed_printk_messages/Compressed_printk_messages.md "Compressed printk messages")，评估过这个技术。这个项目的结果可以在 [压缩的 printk 消息 - 结果](../.././dev_portals/System_Size/Compressed_printk_messages/Compressed_printk_messages.html_-_Results "Compressed printk messages - Results") 找到。


#### 裁剪的一些想法和近期的工作

一群开发者正持续致力于 Linux 内核大小裁剪的工作上（截止到 2014）。为方便后续内核裁剪工作，已经建立了一篇文章来分类近期工作和想法。该文章在：[内核大小裁剪工作](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/System_Size/Kernel_Size_Reduction_Work/Kernel_Size_Reduction_Work.html "Kernel Size Reduction Work")。


### 文件系统压缩

对于只读数据来说，一个压缩的文件系统是很有的。以下文件系统在嵌入式系统里用得非常多：

-	Cramfs，SquashFS，用于块存储
-	JFFS2 和 它的姊妹 UBIFS，用于 Flash（MTD）存储

要注意的是由于 Cramfs 和 Squashfs 只写一次（write-only-once）的天然特性，也能够用于 MTD 存储。

访问 [文件系统](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/File_Systems/File_Systems.html "File Systems") 获取更多信息。


### 应用裁剪


#### 程序大小相关编译选项

你可以使用 `gcc -Os` 来优化大小。


#### 缩减你的程序

你可以使用 'strip' 命令来剔除你应用中无用的符号。`strip` 命令包含在你的工具链里，且和当前的架构有关。（例如，你需要加上一个工具链前缀，像 `arm-linux-strip`）。

要注意的是这会让你的应用更加难调试，因为调试符号不再存在。

默认情况下，`strip` 只移除调试符号。但是在动态链接时，我们可以移除除了基本符号之外的所有其他符号。若想获取最高程度的移除效果，可以使用 `strip --strip-unneeded <app>`。

这可以节省很多空间，特别是在调试符号被包含在构建里时。

    $ gcc -g hello.c -o hello
    $ ls -l hello
    -rwxrwxr-x 1 tbird tbird 6143 2009-02-10 09:43 hello
    $ strip hello
    $ ls -l hello
    -rwxrwxr-x 1 tbird tbird 3228 2009-02-10 09:43 hello
    $ strip --strip-unneeded hello
    $ ls -l hello
    -rwxrwxr-x 1 tbird tbird 3228 2009-02-10 09:43 hello

现在，编译时不带调试符号：

    $ gcc hello.c -o hello
    $ ls -l hello
    -rwxrwxr-x 1 tbird tbird 4903 2009-02-10 09:45 hello
    $ strip hello
    $ ls -l hello
    -rwxrwxr-x 1 tbird tbird 3228 2009-02-10 09:45 hello

我们可以 strip 可执行文件和共享库。

有一个 "super-strip" 工具，会移除 ELF 可执行程序里额外信息（通常 'strip' 忽略的）。可以在这里找到：[http://muppetlabs.com/\~breadbox/software/elfkickers.html](http://muppetlabs.com/~breadbox/software/elfkickers.html)。*这个程序现在好像被废弃了，我不能在 Fedora 8 上编译它。*

[这里](http://reverse.lostrealm.com/protect/strip.html) 有一些关于如何手动剔除单独节区（Sections）的信息，它介绍了如何使用 `-R` 命令。


#### 手动优化程序大小

如果你非常想要创建小尺寸二进制文件，你可以使用一些技术来手动创建最小的 Linux 可执行文件。

看 [一个快速创建紧凑的 Linux ELF 可执行文件的教程](http://muppetlabs.com/~breadbox/software/tiny/teensy.html)


### 库尺寸裁剪技术


#### 使用更小的 libc

Glibc 是 Linux 系统下默认的 C 库。Glibc 大概有 2MB 大小。Linux 上同样可以找到其他 C 库，他们提供不同程度上的兼容和尺寸节约。通常，对于那些比较关注系统尺寸来说，uClibc 是一个非常好的 Glibc 替代品。

-   [uClibc](http://uclibc.org/) - 占用空间少，支持 C 库的全部功能
-   [dietlibc](http://www.fefe.de/dietlibc/) - 另外一个可以生成非常小的可执行文件的库
-   [klibc](http://www.kernel.org/pub/linux/libs/klibc/) - 非常小的库，用在 init 内存文件系统
-   [eglibc](http://www.eglibc.org/home) - glibc 嵌入式系统版。缩减尺寸是其设计目标之一
-   [musl libc](http://www.musl-libc.org/) - 一个轻型，快速，简单，和标准兼容的 C 库
-   [olibc](http://olibc.github.com/) - 另一个优化过大小和性能的 C 库，起源于 Android bionic libc
-   Libc 规格子集 - CELF 考虑过创建一个 Libc 规格子集的可能性。一些公司也同样考虑过把 Glibc 模块化，这样部分 Glibc 就变得可配置。预研显示这项工作是非常困难的，因为 Glibc 有着非常复杂的内部函数依赖


#### 静态链接

如果你的应用非常小，那么使用静态链接比使用共享库更合理一些。共享库默认包含所有特性的符号（函数和数据结构）。但是，当你把一个库静态链接到一个程序时，只有那些实际被引用的部分才会被包含到程序里来。


#### 库裁剪

通过剔除无用的符号，减少共享库的大小是可能的。

MontaVista 释放过一个工具，用来优化库。这个工具扫描整个文件系统，然后会重新构建系统上的共享库，只包含真正被当前文件系统上的应用引用过的符号。

使用这个方法需要当心，因为这会让那些程序的插件，或者部分升级过程变得非常困难（因为新软件引用的符号可能没有包含在当前已经被优化过的库里）。但是对于那些功能固定的设备来说，这会显著的减少库的大小。

看 [http://libraryopt.sourceforge.net/](http://libraryopt.sourceforge.net/)


#### 延时加载库

对于一个产品，通过延迟加载共享库，和分割库的依赖，来减少运行时 RAM 的占用空间是可能的。Panasonic 做了一些研究，在一个进程里延迟库的加载，在 ELC 2007 展示过这个研究。

看 [动态延时加载（pdf）](http://eLinux.org/images/1/19/DeferredDynamicLoading_20070417.pdf "DeferredDynamicLoading 20070417.pdf") 演示。


### 就地执行（XIP）

我们可以通过直接使用来自 Flash 的一些 `text` 和 `data` 来节省内存开销。


#### 内核 XIP

通过在 FLASH 里执行内核，这有可能节省内存。

-   看 [内核 XIP](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Kernel_XIP/Kernel_XIP.html "Kernel XIP")


#### 应用 XIP

通过在 FLASH 里执行应用程序，这有可能节省内存。

-   看 [应用 XIP](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Application_XIP/Application_XIP.html "Application XIP")


#### 原地数据读取 (DRIP)

这有一个技术，用来在 FLASH 里保持数据，直到该数据需要更新，才复制到内存里来。

-   看 [Data Read In Place](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/System_Size/Data_Read_In_Place/Data_Read_In_Place.html "Data Read In Place")


## 尺寸测量的技术和相关工具


### 内核尺寸测量数据

-   [Bloatwatch](http://www.selenic.com/bloatwatch/) - 一个内核回归分析工具
	-	Bloatwatch 提供很多细节，并且能在不同的时间里比较内核版本的大小


### 怎样计算内核镜像的大小

-	查看内核主要部分的大小（代码和数据）：

`size vmlinux */built-in.o`

    [tbird@crest ebony]$ size vmlinux */built-in.o
       text    data     bss     dec     hex filename
    2921377  369712  132996 3424085  343f55 vmlinux
     764472   35692   22768  822932   c8e94 drivers/built-in.o
     918344   22364   36824  977532   eea7c fs/built-in.o
      18260    1868    1604   21732    54e4 init/built-in.o
      39960     864     224   41048    a058 ipc/built-in.o
     257292   14656   34516  306464   4ad20 kernel/built-in.o
      34728     156    2280   37164    912c lib/built-in.o
     182312    2704     736  185752   2d598 mm/built-in.o
     620864   20820   26676  668360   a32c8 net/built-in.o
       1912       0       0    1912     778 security/built-in.o
        133       0       0     133      85 usr/built-in.o

-	查看最大的内核符号：
    -   `nm --size -r vmlinux`

<!-- -->

    [tbird@crest ebony]$ nm --size -r vmlinux | head -10
    00008000 b read_buffers
    00004000 b __log_buf
    00003100 B ide_hwifs
    000024f8 T jffs2_garbage_collect_pass
    00002418 T journal_commit_transaction
    00002400 b futex_queues
    000021a8 t jedec_probe_chip
    00002000 b write_buf
    00002000 D init_thread_union
    00001e6c t tcp_ack


### 怎样动态计算内存使用情况

测量 Linux 下运行时内存使用情况，访问 [动态内存测量](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Memory_Management/Runtime_Memory_Measurement/Runtime_Memory_Measurement.html "Runtime Memory Measurement")

同时，要得到更精准的内存使用情况和相关补丁，请访问 [精准内存测量](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Memory_Management/Accurate_Memory_Measurement/Accurate_Memory_Measurement.html "Accurate Memory Measurement")


### Linux 内核 从 2.4 到 2.6 的尺寸增加

Linux 内核从 2.4 到 2.6 版本之间，大小增加了 10% ~ 30%。论坛成员非常关注这种尺寸增长。

访问 [Szwg Linux
26Data](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/System_Size/Szwg_Linux_26Data/Szwg_Linux_26Data.html "Szwg Linux 26Data") 相关数据支持。

-   [尺寸调整](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/System_Size/Size_Tunables/Size_Tunables.html "Size Tunables")


### GCC 代码大小基准测试

CSiBE 是 GCC 编译器的代码大小基准测试工具。CSiBE 的主要目标是监控 GCC 生成的代码大小。另外，编译时间和代码优化测量也包括在内。

[CSiBE](http://www.inf.u-szeged.hu/csibe/)


## 案例研究

"Motorola 在 2.4 的 Linux 内核上做的系统大小缩减（大概给移动设备使用）"

-   MotSizeReduction.ppt - 幻灯片占用符，太大了，无法上传到 WIKI （为什么不在这？）


### uClinux

-	一篇在 cortex-m3s 上跑 uClinux 库的文章。里面使用的内核有很多好资料。
    -   [http://electronicdesign.com/embedded/practical-advice-running-uclinux-cortex-m3m4](http://electronicdesign.com/embedded/practical-advice-running-uclinux-cortex-m3m4)


### 微型处理器上的 Linux (这里是在 M3 上)

-	在 2014 年的 ELC 上，Vitaly Wool 展示了在 STM32F4XX 上运行 2.6.33 的 Linux 内核
    -   Vitaly 的幻灯片： [Spreading the disease: Linux on
        microcontrollers](http://elinux.org/images/c/ca/Spreading.pdf)
    -	设备有 256K 内存和 2M 的存储
    -	内核和应用使用了 XIP 技术


## 发行版本的尺寸缩减相关尝试

这有一些专注于小尺寸系统的项目：

-   micro-Yocto (2014)
    -   Tom Zanussi has lead an effort in the Yocto Project to produce a
        minimal kernel for very small embedded systems
    -	Tom Zanussi 在 Yocto 项目上做了很多关于为微型嵌入式系统生成小型内核的工作
    -	Tom 在 ELC 2014 展示的幻灯片：[microYocto and the Internet of Tiny](http://elinux.org/images/5/54/Tom.zanussi-elc2014.pdf)
    -   获取更多相关信息，查看 [https://github.com/tzanussi/meta-galileo/raw/daisy/meta-galileo/README](https://github.com/tzanussi/meta-galileo/raw/daisy/meta-galileo/README)
-   [http://cgit.openembedded.org/meta-micro/](http://cgit.openembedded.org/meta-micro/)
    -   由 Phil Blundell 维护。这个项目在保持系统功能全面的前提下减少大小方面，做得很成功。它使用了 uClibc 库
    -   [Meta-tiny git
        repository](http://git.infradead.org/users/dvhart/meta-tiny.git)
-   这有一个叫 Poky-tiny 的项目，基于 Yocto 做一个极度缩减的嵌入式发型版本。
    -   查看 [https://wiki.yoctoproject.org/wiki/Poky-Tiny](https://wiki.yoctoproject.org/wiki/Poky-Tiny)
    -   Poky-tiny 是尝试基于 Yocto 做一个很小的系统，Darren Hart 说

<!-- -->

	meta-tiny 是我的一个实验项目，用来验证我们可以用现有的代码和架构构建什么东西。
	我发现我们可以在不裁剪任何功能的前提下，节约大概 10% 的核心镜像空间。
	我们可以在保持 IPV4 可用的前提下，节省 20% 空间。

-   -   幻灯片 [Tuning Linux For Embedded Systems: When Less Is
        More](http://elinux.org/images/2/2b/Elce11_hart.pdf)


## 杂项


### 内核内存溢出检测

ARM 公司的 Catalin Marinas 最近贡献了一个内存溢出检测工具给 Linux 内核（在 2.6.17 版本？）。将来可能会合入主线仓库。相关 LKML 讨论记录：[http://lkml.org/lkml/2006/6/11/39](http://lkml.org/lkml/2006/6/11/39)


### 系统的大小是怎样影响性能的

已经有理论证明减少系统大小可以提高性能，因为这减少了缓存匹配失败的几率。在 Linux 下好像没有实际数据来支持这个理论，但是在内核邮件列表里已经讨论过。

查看 [this post by Linus
Torvalds](http://groups.google.com/group/linux.kernel/msg/e1f9f579a946333e?hl=en&)


### 缩减桌面发行版本的文件系统

这有一个很好的文档，是关于怎样从一个桌面发行版本里裁剪不需要的文件。实例的版本是 LFS，但是在其他发行版本上也是可以工作的。

[http://www.linuxfromscratch.org/hints/downloads/files/OLD/stripped-down.txt](http://www.linuxfromscratch.org/hints/downloads/files/OLD/stripped-down.txt)


### 极小系统

该节罗列了各种各样的，关于生成绝对小型系统的尝试。

-	Vitaly Wool 描述了在一个 2MB 存储和 256K 内存的 ST MCU 上，运行 2.6.33 内核 
    -   [Linux for Microcontrollers: Spreading the Disease
        (PDF)](http://eLinux.org/images/c/ca/Spreading.pdf "Spreading.pdf") (在 2014.4 ELC 上展示过)
-	有人在一个只有 128K 内存的处理器上，跑着老版本的 BSD。（你没看错，是 128K）
    -   [http://olimex.wordpress.com/2012/04/04/unix-on-pic32-meet-retrobsd-for-duinomite/](http://olimex.wordpress.com/2012/04/04/unix-on-pic32-meet-retrobsd-for-duinomite/)


[分类](http://eLinux.org/Special:Categories "Special:Categories"):

-   [系统裁剪](http://eLinux.org/Category:System_Size "Category:System Size")

