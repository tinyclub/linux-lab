---
layout: post
author: 'Wu Zhangjin'
title: "bugfix: Qemu 运行 ARM Linux 5.0 必现启动死机"
draft: true
album: 'Linux Bug 解析'
license: "cc-by-sa-4.0"
permalink: /debugging-qemu-arm-linux-5.0-boot-hang/
description: " 文章摘要 "
category:
  - 调试技巧
tags:
  - qemu
  - arm
  - linux 5.0
  - boot hang
  - 死机
  - earlycon
---

> By Falcon of [TinyLab.org][1]
> May 14, 2019

注：泰晓科技新增 “Linux Bug 解析” 专辑，全面连载各类 Bug 实例解析过程。本文是该专辑的第一篇，欢迎持续关注。通过该专辑，您可以学习到分析和解决实际问题的方式、方法、工具和技巧。

## 背景介绍

前段时间为 Linux Lab 新增了 5.0.10 for ARM64/virt board，期间遇到了启动死机问题，本文对该问题进行详解。

在继续阅读之前，建议准备好 [Linux Lab](/linux-lab)，方便同时做实验。为复现该问题，请先注释掉 `boards/virt/Makefile` 中的 QEMU 所在行，或者键入如下命令确保使用旧版本的 qemu。

    $ export QEMU=

## 问题现象

编译完 Linux 5.0.10 并通过 Linux Lab 运行时：

    $ make BOARD=virt
    $ make boot V=1

直接卡死了，只看到 Qemu 的输出日志，没有看到任何内核日志输出 ;-(

## 分析过程

### 理清问题基本信息

首先需要承认，面对这种不按套路出牌的 Linux 启动状况（不确定性），这个时候谁都可能“惶恐不安”。接着告诉自己，问题必须解决，冷静！

有两个信息先捋一下：

- 之前的 Linux v4.5.5 ok，启动完美
- 网上已经有同学完美启动了 5.0 for ARM64

所以，问题可能原因：

- Linux v5.0.10 相比 v4.5.5 有变更引入了衰退
- Linux Lab 所使用的环境跟网上其他同学的环境有差异，可能差异在编译器和 Qemu。

接下来有两个思路：

- 用二分法找出引入问题的变更，即从 v4.5.5 到 v5.0.10 之间找出第一个启动不了的内核版本
- 升级 Linux Lab 中的编译器和 Qemu 到最新版本

可是，虽然这两个工作都可行，但还都蛮耗费时间（第2个相对而言没那么耗时），所以，不能逃避，正面扛着看看！

### 定下分析方式

ok，先保持内核版本不变、环境不变，正面分析到底 Linux 内核卡死在哪里？！

#### 打开 early Logging 机制

竟然内核什么都没有输出，那么先想办法输出点东西。

死得这么早，可能是普通串口初始化之前就挂了，要在这之前就打印东西，能想到是 early printk：

    $ make boot V=1 XKCLI="earlycon"

`earlycon` 是内核最新的 early printk 逻辑，说明文档在 linux-stable/Documentation/admin-guide/kernel-parameters.txt：

    earlycon=  [KNL] Output early console device and options.

    [ARM64] The early console is determined by the stdout-path property in device tree's chosen node, or determined by the ACPI SPCR table.

    [X86] When used with no options the early console is determined by the ACPI SPCR table.

加上以后，很幸运，有东西咕噜咕噜滚出来了：

    $ make boot V=1 XKCLI=earlycon
    make  _boot
    make[1]: Entering directory `/labs/linux-lab'
    sudo qemu-system-aarch64  -M virt -m 128M -net nic,model=virtio -net tap -device virtio-net-device,netdev=net0,mac=c0:2f:fd:e8:dc:ce -netdev tap,id=net0 -smp 2 -cpu cortex-a57 -kernel /labs/linux-lab/output/aarch64/linux-v5.0.10-virt/arch/arm64/boot/Image -no-reboot  -initrd /labs/linux-lab/prebuilt/root/aarch64/cortex-a57/rootfs.cpio.gz -append 'route=172.17.0.5 root=/dev/ram0 earlycon console=ttyAMA0' -nographic
    ...
    Booting Linux on physical CPU 0x0000000000 [0x411fd070]
    Linux version 5.0.10-dirty (ubuntu@5016aaa36868) (gcc version 4.9.3 20150413 (prerelease) (Linaro GCC 4.9-2015.05)) #6 SMP Sun May 5 06:42:26 UTC 2019
    Machine model: linux,dummy-virt
    earlycon: pl11 at MMIO 0x0000000009000000 (options '')
    printk: bootconsole [pl11] enabled
    ...
    ------------[ cut here ]------------
    kernel BUG at /labs/linux-lab/linux-stable/arch/arm64/kernel/traps.c:425!
    Internal error: Oops - BUG: 0 [#1] SMP
    Modules linked in:
    Process swapper (pid: 0, stack limit = 0x(____ptrval____))
    CPU: 0 PID: 0 Comm: swapper Not tainted 5.0.10-dirty #37
    Hardware name: linux,dummy-virt (DT)
    pstate: 00000085 (nzcv daIf -PAN -UAO)
    pc : do_undefinstr+0x280/0x2c0
    lr : do_undefinstr+0x168/0x2c0
    ...
    Call trace:
     do_undefinstr+0x280/0x2c0
     el1_undef+0x10/0x78
     __cpuinfo_store_cpu+0x80/0x1d0
     cpuinfo_store_boot_cpu+0x28/0x54
     smp_prepare_boot_cpu+0x38/0x40
     start_kernel+0x170/0x450
    Code: 2a154035 17ffffb5 a9025bb5 f9001bb7 (d4210000)
    ---[ end trace 16cff5c8dd5a6423 ]---
    Kernel panic - not syncing: Attempted to kill the idle task!
    ---[ end Kernel panic - not syncing: Attempted to kill the idle task! ]---

#### 出错 Log 分析

出错日志有非常关键的 Calltrace 信息，初一看，发现是 undefinstr 异常，并且有触发异常的具体位置：

    __cpuinfo_store_cpu+0x80/0x1e4

通过如下命令找到代码所在文件：

    $ cd linux-stable
    $ grep __cpuinfo_store_cpu -nur arch/arm64/
    arch/arm64/kernel/cpuinfo.c:328:static void __cpuinfo_store_cpu(struct cpuinfo_arm64 *info)
    arch/arm64/kernel/cpuinfo.c:386:	__cpuinfo_store_cpu(info);
    arch/arm64/kernel/cpuinfo.c:393:	__cpuinfo_store_cpu(info);

打开代码初步查看如下：

    $ vim arch/arm64/kernel/cpuinfo.c +328
    info->reg_cntfrq = arch_timer_get_cntfrq();
    ...
    info->reg_id_aa64mmfr0 = read_cpuid(ID_AA64MMFR0_EL1);
    info->reg_id_aa64mmfr1 = read_cpuid(ID_AA64MMFR1_EL1);
    info->reg_id_aa64mmfr2 = read_cpuid(ID_AA64MMFR2_EL1);
    info->reg_id_aa64pfr0 = read_cpuid(ID_AA64PFR0_EL1);
    info->reg_id_aa64pfr1 = read_cpuid(ID_AA64PFR1_EL1);
    info->reg_id_aa64zfr0 = read_cpuid(ID_AA64ZFR0_EL1);

初步猜测，可能是部分寄存器访问出错，但是具体哪一个错了还需要进一步确认。

#### 定位代码出错位置

接下来需要通过 Backtrace 中的 `__cpuinfo_store_cpu+0x80` 找到准确的出错位置，也就是代码行。

这个寻找过程我们很早有专门的文章介绍，可以查阅：[如何快速定位 Linux Panic 出错的代码行](http://tinylab.org/find-out-the-code-line-of-kernel-panic-address/)。

方法有几种，但是实际发现用 objdump 最为准确，gdb 在这个例子里有一行的偏差。

在这之前，必须确保 vmlinux 是带符号的，否则这些工具没法帮我们定位出错文件和代码行。要让 vmlinux 带符号，必须在 boards/virt/linux_v5.0.10_defconfig 中开启如下配置后重新编译内核：

    CONFIG_DEBUG_KERNEL=y
    CONFIG_DEBUG_INFO=y
    CONFIG_KALLSYMS=y

重新配置和编译内核：

    $ make kernel-defconfig
    $ make kernel

接下来，回到 Linux Lab 主目录，开始定位问题所在的代码行。先得请 nm 帮找出 `__cpuinfo_store_cpu` 的地址：

    $ aarch64-linux-gnu-nm output/aarch64/linux-v5.0.10-virt/vmlinux | grep __cpuinfo_store_cpu
    ffffff80100919c0 t __cpuinfo_store_cpu

同时根据异常日志中的 “__cpuinfo_store_cpu+0x80/0x1d0” 计算出 start-address 和 stop-address，0x80 为出错位置，0x1d0 为函数 size，我们找出这个范围。

    $ echo "obase=16;ibase=10;$((0x80100919c0+0x80))" | bc -l
    8010091A40
    $ echo "obase=16;ibase=10;$((0x80100919c0+0x1d0))" | bc -l
    8010091B90

接着，请出 objdump 这尊大神，start-address 设置为函数入口，stop-address 设置为

    $ aarch64-linux-gnu-objdump -dS output/aarch64/linux-v5.0.10-virt/vmlinux --start-address=0xffffff80100919c0 --stop-address=0xffffff8010091b90
    ...
   	info->reg_id_aa64mmfr1 = read_cpuid(ID_AA64MMFR1_EL1);
    ffffff8010091a3c:	f901ba60 	str	x0, [x19, #880]
    ffffff8010091a40:	d5380740 	mrs	x0, id_aa64mmfr2_el1
	info->reg_id_aa64mmfr2 = read_cpuid(ID_AA64MMFR2_EL1);
    ffffff8010091a44:	f901be60 	str	x0, [x19, #888]
    ffffff8010091a48:	d5380400 	mrs	x0, id_aa64pfr0_el1
	info->reg_id_aa64pfr0 = read_cpuid(ID_AA64PFR0_EL1);
    ...

找到 "ffffff8010091a40" 所在行：

    ffffff8010091a40:	d5380740 	mrs	x0, id_aa64mmfr2_el1
	info->reg_id_aa64mmfr2 = read_cpuid(ID_AA64MMFR2_EL1);

#### 分析出错原因

看上去像是该寄存器访问异常。用 vim 打开注释掉该行并重新编译，重新启动，发现继续出错：

    Call trace:
     do_undefinstr+0x280/0x2c0
     el1_undef+0x10/0x78
     __cpuinfo_store_cpu+0x90/0x1c8
     cpuinfo_store_boot_cpu+0x28/0x54
     smp_prepare_boot_cpu+0x38/0x40
     start_kernel+0x170/0x450

代码偏移为 0x90，出错位置为：0xffffff8010091b50，同样计算 start-address：0xffffff80100919c0 和 stop-address：0xffffff8010091b88，用 objdump 找到如下位置：

    $ aarch64-linux-gnu-objdump -dS output/aarch64/linux-v5.0.10-virt/vmlinux --start-address=0xffffff80100919c0 --stop-address=0xffffff8010091b88
    ...
    ffffff8010091a48:	d5380422 	mrs	x2, id_aa64pfr1_el1
    	info->reg_id_aa64pfr1 = read_cpuid(ID_AA64PFR1_EL1);
    ffffff8010091a4c:	f901c662 	str	x2, [x19, #904]
    ffffff8010091a50:	d5380482 	mrs	x2, id_aa64zfr0_el1
    	info->reg_id_aa64zfr0 = read_cpuid(ID_AA64ZFR0_EL1);
    ffffff8010091a54:	f901ca62 	str	x2, [x19, #912]

出错位置的代码如下：

    ffffff8010091a50:	d5380482 	mrs	x2, id_aa64zfr0_el1
    	info->reg_id_aa64zfr0 = read_cpuid(ID_AA64ZFR0_EL1);

#### 验证解决方法可行性

同样注释掉这部分，重新编译之后就可以正常启动了。需做修改如下：

    $ cd linux-stable
    $ git diff
    -	info->reg_id_aa64mmfr2 = read_cpuid(ID_AA64MMFR2_EL1);
    +	//info->reg_id_aa64mmfr2 = read_cpuid(ID_AA64MMFR2_EL1);
    ...
    -	info->reg_id_aa64zfr0 = read_cpuid(ID_AA64ZFR0_EL1);
    +	//info->reg_id_aa64zfr0 = read_cpuid(ID_AA64ZFR0_EL1);


启动日志如下：

    ..
    Welcome to Linux Lab
    linux-lab login: root
    #
    # uname -a
    Linux linux-lab 5.0.10-dirty #39 SMP Sun May 5 13:00:38 UTC 2019 aarch64 GNU/Linux

至此，临时解决方案 ok。已经把上面两笔内核的修改制作成了 patch，并放到了boards/virt/patch/linux/v5.0/ 下，另外，在 boards/virt/Makefile 中配置了 “KP=1”，后续配置时会据此自动打 patch，打上后再编译就可启动了。

### 问题复盘

正面分析发现是 Linux 内核代码中有相关寄存器的操作引起了 undefinstr，这部分寄存器官方内核是支持的，说明真实硬件没有问题，所以需要继续看看运行环境部分，也就是这里的 Qemu 模拟器，很大可能是 Qemu 版本问题。

之前 Linux Lab 自带版本是 2.5：

    $ qemu-system-aarch64 --version
    QEMU emulator version 2.5.0 (Debian 1:2.5+dfsg-5ubuntu4), Copyright (c) 2003-2008 Fabrice Bellard

所以接下来要升级 Qemu 版本，由于未能找到编译好的 Qemu 版本，我们自行编译，并且给 Linux Lab 添加了 Qemu 编译支持，这里不做介绍。

编译完一个新的 v2.12.0 以后测试发现，可以直接正常启动不做改动的 Linux 5.0.10，所以证实了我们的猜测。

    $ prebuilt/qemu/aarch64/v2.12.0/bin/qemu-system-aarch64 --version
    QEMU emulator version 2.12.0
    Copyright (c) 2003-2017 Fabrice Bellard and the QEMU Project developers


## 小结

本文详细介绍了一个典型的 Linux 内核死机问题。在实际产品研发过程中，死机问题会千奇百怪，死机路径可能随机变化，死机概率也因使用环境有高有低，所以，一方面要不断积累解决问题的技术经验，另外一方面尤其重要的是，沉着冷静，在面对类似难题时，坚定解决问题的信心。

欢迎添加作者微信 lzufalcon，进一步交流探讨！

[1]: http://tinylab.org
