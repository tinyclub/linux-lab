---
layout: post
author: 'Dong Liyuan'
title: "嵌入式 Linux 设备树"
album: "嵌入式 Linux 知识库"
group: translation
permalink: /embedded-linux-device-tree/
description: "本文介绍了 Linux 上的一种设备集描述方式：设备树，基于该机制，同一个内核可以结合不同的设备树支持不同的开发板。"
category:
  - 设备树
tags:
  - Open Firmware
  - DTS
  - DTB
  - DTC
  - Linux
  - FDT
  - UEFI
  - ACPI
  - 扁平设备树
---

> 书籍：[嵌入式 Linux 知识库](http://tinylab.gitbooks.io/elinux)
> 原文：[eLinux.org](http://elinux.org/Boot_Time.md)
> 翻译：[@sdfd](https://github.com/sdfd)
> 校订：[@lzufalcon](https://github.com/lzufalcon)

## 前言

设备树数据可以表示成几种不同的格式。它是由 [Open FirmWare](http://www.firmworks.com/www/ofw.htm)[^Open_FirmWare]封装平台信息的设备树格式发展而来，被移植到 Linux 操作系统中。使用 `.dts` 源文件和 `.dtsi` 头文件创建和维护一个典型的设备树。Linux 编译器会对其进行预处理。

设备树源码被编译成一个 `.dtb` 的二进制文件。`.dtb` 二进制文件的数据格式通常参考扁平设备树（FDT）。Linux 操作系统通过设备树数据去寻找并在系统中注册设备。FDT 在启动时的很早时刻存取，但是为了在启动后期和系统完全启动后更有效率的存取，它被扩展进内核内部的数据结构中。

目前，Linux 内核可以支持 ARM，x86，Microblaze，PowerPC 和 Sparc 架构读取设备树信息。拓展设备树对其他平台的支持，通过内核架构统一处理平台描述是我们所关注的。

### 扁平设备树是

扁平设备树（FDT）仅仅是一个数据结构。

它描述了一个机器设备的硬件配置。它是从 Open FirmWare 设备树格式中发展而来。其格式可以体现和描述大多数板级硬件设计，包括：

- CPU 的数量和类型
- RAM 的基地址和大小
- 总线和桥
- 外设连接
- 中断控制和 IRQ 线的连接

像 initrd 镜像一样，FDT 也可以被静态的链接进内核或者在 boot 启动时传递给内核。

### 扁平设备树不是

- 不是解决所有板级接口问题
	- 不可能包含所有板子定制的特殊驱动和复杂的板子。
- 不是一个固件接口
	- 它可能是通用固件接口的一部分，但就设备树而言它只是一个数据结构。
	- 不能代替 ATAGS，但是 FDT 可以通过 ATAG 传递。
	- 参考下面的“竞品的解决方案”一节。
- 它不打算去做一个通用的接口。
	- 它对解决一些问题来说是一个有用的数据结构，但是用不用它还是由开发者决定。
- 不是一个侵略性的改变
	- 使用 FDT 不是必需的
	- 设备树被要求支持 ARM 架构的新板子
	- 不要求去改变已有的板子端口
	- 不要求修改已有的固件

### 历史

- [设备树如何进入 Linux 及其发展](http://elinux.org/Device_tree_history)

### 未来

- [设备树有什么变化及其前进方向](http://elinux.org/Device_tree_future)

## 优势

### 对于内核发行

- 可能需要安装镜像的内核会更少（如： ARM 上网本）。
	- 通过一个 FDT 镜像表示每台机器（小于 4K/每台）和一些附属的架构镜像代替一个内核镜像表示（约 1-2MB/每台）（如：ARM11，CortexA8，CortexA9 等）。
	- 使当前的安装镜像去引导具有相同芯片集的未来的硬件平台成为可能。
	- 备注：FDT 只是解决此问题的一部分。一些启动软件仍然需要正确选择和传递 FDT 镜像。

### 对于片上系统（SoC）供应商

- 减少或努力淘汰需要编写的机器支持代码（如 `arch/arm/mach-*`），而把精力放在设备驱动开发上。

### 对于主板设计者

- 努力减少所需的端口
	- SoC 供应商提供参考设计的二进制代码也可能在自制的机器上启动。
- 不需要对每个新的主板变体分配一个新的全球性 ARM 机器 ID。
	- 使用设备树中的 <vendor>，<boardname> 命名空间代替。
- 大多数主板特性相关的代码的改变被限制在设备树文件和设备驱动中。
- 例如：Xilinx FPGA 工具链中有一个工具可以从 FPGA 的设计文件中生成设备树源文件。
	- 既然硬件描述被限制在设备树源文件中，FPGA 工程师可以测试设计的改变而不需要将其添加到内核代码中。
	- 内核代码不需要手动地从 FPGA 设计文件中提取设计改变。

### 对于嵌入式 Linux 生态系统

- 需要合入的板级支持代码更少
- 板子有更大的可能得到对此不感兴趣的供应商的主要支持
- 通过修复或者替换损坏的 FDT 镜像可以有更大的能力去提供有问题的板子的支持

### 对于固件或 bootloader 开发者

- 减少板子描述错误的影响（FDT 作为一个单独镜像存储而不是静态的链接进固件中）。如果初始的发布版的板子描述错误，它可以很容易的升级而不需要危险的重新刷固件
- 对板子变体的表示方式不需要分配新的机器号或新的 ATAGs
- 备注：FDT 不是要替代 ATAGs，而是对其补充

### 其他的优势

- 设备树源代码和 FDTs 可以很容易的由机器生成和修改。
	- Xilinx FPGA 工具可以生成设备树源码
	- U-Boot 固件在启动前可以检查和修改 FDT 镜像

## 竞品的解决方案

### 板子相关特性的数据结构

一些平台板子相关的特性使用 C 数据结构从 bootloader 向内核传递数据。著名的有嵌入式 PowerPC 在 FDT 数据结构之前支持的标准。

PowerPC 示范的经验提示我们使用自定义的 C 数据结构对于少量的数据确实是有利的解决方案。但是它引起了长期的可维护问题，而且总体上来说它没有尝试去解决描述板级配置的问题。随着这种特有情况的发展，没有办法决定什么版本的数据结构合金内核代码中。PowerPC 的板级信息结构用 `#ifdef` 搞得一团糟，修改的很丑陋，它还仅仅是传递一小点像内存大小和网卡 MAC 地址这样的数据。

ATAGs 以优雅的方式--通过定义友好的命名空间传递个体的数据项（内存区域，初始化地址等），操作系统能可靠的解析这些参数。然而，只有一打或者只有 ATAG 被定义是不能足够的表达对板子设计的描述。使用 ATAGs 本质上需要一个分离的机器号去配置每一个板子变体，即使他们给予相同的设计。

尽管如此，ATAG 仍是一个理想的向内核传递 FDT 镜像的方法，其同时被用来传递启动地址。
### ACPI（高级配置与电源接口）

固件由差异化系统描述表（DSDT）提供高级配置与电源接口硬件描述的配置文件。ACPI 应用于 x86 兼容机系统，其由经典 IBM PC BIOS 发展而来。

### UEFI（统一的可扩展固件接口）

[可扩展固件接口](http://en.wikipedia.org/wiki/Extensible_Firmware_Interface) 是一个从平台固件到操作系统传递控制命令的规范接口。它由英特尔设计，被用来代替 PC 的 BIOS 接口。

ARM 控制着 UEFI 社区的[成员](http://www.uefi.org/join/list)。这就不难想象 UEFI 由 ARM 实现。

### Open FirmWare

[Open FirmWare](http://en.wikipedia.org/wiki/Open_Firmware) 是 Sun 公司在 20 世纪 80 年代后期设计的一个固件接口规范，移植到了很多架构中。它指定一个运行时操作系统的客户端接口，交叉平台的设备接口，用户接口和描述机器布局的设备树。

FDT 之于 Open FirmWare 就像 DSDT 之于 ACPI。FDT 重用了 Open FirmWare 已经确定了的设备树布局。事实上，Linux PowerPC 支持使用相同的代码库同时支持 Open FirmWare 和 FDT 平台。

## 关于竞品的解决方案的一些注解

大多数竞品的解决方案像上面列出的包括机器描述和运行时服务的功能丰富的固件接口。相反的，FDT 只是一个数据结构，并不指定任何固件接口细节。使用 FDT 端口的板子的典型的启动过程是由类似 U-Boot 这样的简单的固件实现的，其不提供任何形式的运行时服务。

功能丰富的接口的共同的设计目标是提供一个抽象的启动接口，其只受不同硬件平台的差异的影响，其至少要能初始化操作系统自己本地的设备驱动。一个想法是在新的硬件上启动老的操作系统镜像，像 Linux 的 LiveCD 镜像不需要明确知道硬件配置那样，但是需要依赖固件给其提供信息。

典型的嵌入式固件设计目标是：a）尽可能快的启动系统 b）升级系统镜像 c）可能还需要在初始化板子时提供一些低等级的 debug 调试支持。关注点倾向于系统一旦从内核直接驱动硬件启动后就远离固件(不需要依赖固件运行时服务)。事实上，不建议进行固件升级，因为固件升级可能带来板子无法启动的风险。嵌入式系统中的 ACPI，UEFI 和 Open FirmWare 解决方法通常启动的并不快，虽然可能更好一点，比需要的更复杂一点。就这一点而言，FDT 的方法因其简单而更有优势。如：FDT 提供类似的表示方法去描述硬件，但是它可以工作在现存的固件上，也可以升级而不需要刷新固件。

## 资源

### Wiki 和内核中的参考资料
[设备树主要的wiki在：](http://www.devicetree.org/Main_Page)
http://www.devicetree.org/Main_Page 对设备树的概念进行了很好的介绍，并用源码来更形象的表述这些概念。（但是在于其他的资源比较的时候请检查页面底部最新的修改日期（当前是 2010.10.23））
在 Linux 内核文档目录可以找到设备树的参考资料：`Documentation/devicetree`。请参考https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/Documentation/devicetree

一些很有用的文件：
- ABI.txt:稳定和一般绑定规则的注释
- resource-names.txt: `-name` 属性 包含一个名字对应其他性质的一个命令列表
- usage-model.txt: 不同原理的绑定的信息
- vendor-prefixes.txt: 供应商前缀注册
- bindings 目录有在 dts 中每个设备类型描述原理和语法以及被用于内核框架和驱动的细节。
- bindings/submitting-patches.txt: 重要的说明：
	- patch 提交者
	- kernel 维护者

### FAQ,小贴士和最佳范例
请看 [Linux 设备树指南](http://elinux.org/Linux_Drivers_Device_Tree_Guide)

### 演示文稿，论文和文章

- [解决设备树问题](http://elinux.org/Device_Tree_frowand) LinuxCon Japan 2015 by Frank Rowand
- 设备树作为作为稳定的 ABI：是一个神话？，ELC 2015 by Thomas Petazzoni
	- http://elinux.org/images/0/0a/The_Device_Tree_as_a_Stable_ABI-_A_Fairy_Tale%3F.pdf
- 设备树的作用和路线图 可重构硬件工作的发展
	- [PDF](http://elinux.org/images/1/19/Dynamic-dt-keynote-v3.pdf)
	- [YouTube video](http://www.youtube.com/watch?v=3Ag7ZBC_Nts)
- 设备树入门 ELC 2014 by Thomas Petazzoni
	- [PDF](http://elinux.org/images/f/f9/Petazzoni-device-tree-dummies_0.pdf)
	- [YouTube video](https://www.youtube.com/watch?v=uzBwHFjJ0vU)
- [设备树I：现在我们快乐了吗？](https://lwn.net/Articles/572692/) Neil Brown, LWN.net November 2013
- [设备树II：更难的部分](https://lwn.net/Articles/573409/) Neil Brown, LWN.net November 2013
- 设备树入门 ELC Europe 2013 by Thomas Petazzoni
	- [PDF](http://elinux.org/images/a/a3/Elce2013-petazzoni-devicetree-for-dummies.pdf)
	- [YouTube video](https://www.youtube.com/watch?v=m_NyYEBxfn8)
- 设备树的作用和路线图可重构硬件工作的发展 ELC Europe 2014 by Pantelis Antoniou
	- [Media:Antoniou--transactional_device_tree_and_overlays.pdf](http://elinux.org/images/8/82/Antoniou--transactional_device_tree_and_overlays.pdf)
- 设备树：内核组件和实际的排错 ELC Europe 2014 by Frank Rowand
	- [Media:Rowand--devicetree_kernel_internals.pdf](http://elinux.org/images/0/0c/Rowand--devicetree_kernel_internals.pdf)
- 设备树，当前的灾难 ELC Europe 2013 by Mark Rutland
	- [Media:Rutland-presentation_3.pdf](http://elinux.org/images/8/8e/Rutland-presentation_3.pdf)
	- [YouTube video](https://www.youtube.com/watch?v=xamjHjjyeBI)
- 对设备树的长期支持和安全性的最佳实践 ELC Europe 2013 by Alison Chaiken
	- [Media:Chaiken-DT_ELCE_2013.pdf](http://elinux.org/images/d/d1/Chaiken-DT_ELCE_2013.pdf)
- 板子文件迁移到设备树 ELC Europe 2013 by Pantelis Antoniou
	- [Media:ELCE2013_-_DT_War.pdf](http://elinux.org/images/5/5c/ELCE2013_-_DT_War.pdf)
- Linux内核中对ARM的支持 Presented at FOSDEM 2013 by Thomas Petazzoni
	- https://archive.fosdem.org/2013/schedule/event/arm_in_the_linux_kernel/attachments/slides/273/export/events/attachments/arm_in_the_linux_kernel/slides/273/arm_support_kernel.pdf	
	- 关于设备树如何成为整个 ARM 架构重构的一部分的一些好材料及如何使用它的一些细节。
- Linux 内核：合并 ARM 架构的支持 Libre Software Meeting, 2013 by Thomas Petazzoni
	- http://free-electrons.com/pub/conferences/2012/lsm/arm-kernel-consolidation/arm-kernel-consolidation.pdf
- 使用设备树支持开发基于 ARM SOC 的经验 Thomas P. Abraham, ELC 2012
	- [Media:Experiences_With_Device_Tree_Support_Development_For_ARM-Based_SOC's.pdf](http://elinux.org/images/4/48/Experiences_With_Device_Tree_Support_Development_For_ARM-Based_SOC%27s.pdf)
	- ELC（Embedded Linux Conferences（嵌入式Linux会议））2012的幻灯片和视频：http://free-electrons.com/blog/elc-2012-videos/
- 设备树地位的报告 Grant Likely, ELC Europe 2011
	- ELC Europe 2011的幻灯片和视频：http://free-electrons.com/blog/elce-2011-videos/

##### 各种子系统的设备树描述的笔记

- 引脚控制子系统-增加接地引脚和 GPIO Presented at Linaro Connect, 2013 by Linus Walleij
	- http://www.df.lth.se/~triad/papers/pincontrol.pdf

#### 较老的材料

在 Linux 源码树种描述设备树支持的文档（2006年的信息）：[Documentation/powerpc/booting-without-of.txt](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/plain/Documentation/powerpc/booting-without-of.txt?id=HEAD)

- 使用设备树描述嵌入式硬件 Grant Likely, Embedded Linux Conference, 2008
	- http://www.celinux.org/elc08_presentations/glikely--device-tree.pdf
- 交响乐的味道：使用设备树描述嵌入式硬件 Grant Likely and Josh Boyer - paper for OLS 2008
	- http://ols.fedoraproject.org/OLS/Reprints-2008/likely2-reprint.pdf
- 2008 年在 OLS 的设备树特性会议笔记：
	- http://lists.ozlabs.org/pipermail/devicetree-discuss/2008-July/000004.html
- 联系相关的 Open FirmWare，设备树的绑定和推荐做法也可应用于 FDT:
	- http://www.openfirmware.info/Bindings
- 来自外部的 FreeBSD ARM 通讯的观点
	- http://wiki.freebsd.org/FreeBSDArmBoards

### 工具

- 设备树编译器（dtc）-在人类可编辑的设备树源码“dts”格式和用于内核或者汇编源码的紧凑的设备树二进制“dtb”之间转换。Dtc 也是 dtb 的逆编译器。
	- dtc 在 Linux 版本下主要在内核源码目录的 `scripts/dtc/` 中维护
	- 上层工程主要维护在：
		- https://git.kernel.org/cgit/utils/dtc/dtc.git
		- `git clone git://git.kernel.org/pub/scm/utils/dtc/dtc.git`
- Xilinx EDK 设备树生成器-从 Xilinx FPGA 的设计文件中生成 FDT
	- http://xilinx.wikidot.com/device-tree-generator

	设备树生成器是一个 Xilinx EDK 工具，拥有 BSP 自动生成的特性

### 调试

你可以设置 `CONFIG_PROC_DEVICETREE` 使你可以在系统启动后从 /proc 中看到设备树信息。当此项被设置成“Y”后重新编译内核，然后启动内核，输入命令`cd /proc/device-tree`

对于新的不存在 `CONFIG_PROC_DEVICETREE` 选项的内核，当 `CONFIG_PROC_FS` 被设置成”Y”时会创建 `/proc/device-tree`。你也可以尝试 `CONFIG_DEBUG_DRIVER=Y`。

另外，通常你可以在一个独立的 c 文件中设置`#define DEBUG 1`，在此文件中添加日常活动的调试语句。这将激活源码中任何 `pr_debug()`语句。

或者，你可以增加以下语句到 `drivers/of/Makefile` 中：

	CFLAGS_base.o := -DDEBUG
	CFLAGS_device.o := -DDEBUG
	CFLAGS_platform.o := -DDEBUG
	CFLAGS_fdt.o := -DDEBUG

### 设备树 irc (互联网中继聊天)

设备树 irc 通道是在 freenode.net 上的 #devicetree。

### 设备树邮件列表

2013年7月更新

	http://vger.kernel.org/vger-lists.html#devicetree
	存档：http://www.spinics.net/lists/devicetree/

2013年7月之前

	https://lists.ozlabs.org/listinfo/devicetree-discuss
	存档： http://news.gmane.org/gmane.linux.drivers.devicetree


[^Open_FirmWare]:译者注：第一个无版权的引导固件，它可兼容不同的处理器和总线，是 PowerPC 和 CHRP（共用硬件参考平台）所必需的，其由 IEEE 1275-1994 标准定义。
