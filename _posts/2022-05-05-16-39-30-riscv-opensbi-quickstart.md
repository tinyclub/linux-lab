---
layout: post
author: 'Wu Zhangjin'
title: "RISC-V OpenSBI 快速上手"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /riscv-opensbi-quickstart/
description: "本文介绍了 RISC-V OpenSBI 的基础用法以及 Linux 内核调用 OpenSBI 服务的方式。"
category:
  - 开源项目
  - Risc-V
  - Bootloaders
tags:
  - Linux
  - RISC-V
  - SBI
  - Supervisor Mode
  - Machine Mode
  - OpenSBI
  - ecall
---

> Author:  Wu Zhangjin <falcon@tinylab.org>
> Date:    2022/05/05
> Project: [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux)

## 简介

如果要支持 Linux 等现代操作系统，RISC-V 必须提供三种工作模式，即 Machine Mode, Supervisor Mode 和 User Mode。Supervisor 和 User 分别用于运行我们常见的 Linux 与用户态应用程序。而 Machine Mode 则用于运行 Bootloader 并装载和执行 OS。

在 RISC-V 上，Machine Mode 还为 Supervisor Mode 提供一些特定的服务，这些服务由 SBI (Supervisor Binary Interface) 规范定义，在运行完 Bootloader 以后，这些服务还驻留在内存，在 Supervisor Mode 可以通过 `ecall` 调用这些处于 Machine Mode 的服务。

OpenSBI 是 RISC-V SBI 规范的一种 C 语言参考实现，由西数开发，本文带领大家来上个手。

为了方便起见，本文统一使用 [Linux Lab Disk](https://tinylab.org/linux-lab-disk) 或 [Linux Lab](https://tinylab.org/linux-lab) 开发环境，含交叉编译器、模拟器等，可极速开展 RISC-V 开发。

另外，本文基于 OpenSBI v1.0 和 Linux v5.17。

## 基本用法

### 下载

OpenSBI 发布在 Github 上，其地址为: <https://github.com/riscv-software-src/opensbi>

为了加快下载速度，我们在社区仓库做了镜像：<https://gitee.com/tinylab/qemu-opensbi.git>

接下来，下载到 Linux Lab 的 `src/examples` 目录下：

    $ cd src/examples
    $ git clone https://gitee.com/tinylab/qemu-opensbi.git
    $ cd qemu-opensbi/

### 编译

可以分别编译出 32 位和 64 位的版本：

    $ make all PLATFORM=generic LLVM=1 PLATFORM_RISCV_XLEN=32
    or
    $ make all PLATFORM=generic LLVM=1 PLATFORM_RISCV_XLEN=64

下面简单说明一下编译设定：

* `PLATFORM` 我们选择了支持 qemu 的 generic platform，关于 platform 的选择，大家可以参考 `docs/platform/platform.md`。
* `LLVM` 则用于启用 llvm 编译器。
* `PLATFORM_RISCV_XLEN` 用于指定 RV32 或 RV64。

编译结果保存在：

    $ tree build/platform/generic/firmware/
    build/platform/generic/firmware/
    ├── fw_dynamic.bin
    ├── fw_dynamic.dep
    ├── fw_dynamic.elf
    ├── fw_dynamic.elf.ld
    ├── fw_dynamic.o
    ├── fw_jump.bin
    ├── fw_jump.dep
    ├── fw_jump.elf
    ├── fw_jump.elf.ld
    ├── fw_jump.o
    ├── fw_payload.bin
    ├── fw_payload.dep
    ├── fw_payload.elf
    ├── fw_payload.elf.ld
    ├── fw_payload.o
    └── payloads
        ├── test.bin
        ├── test.dep
        ├── test.elf
        ├── test.elf.ld
        ├── test_head.dep
        ├── test_head.o
        ├── test_main.dep
        ├── test_main.o
        └── test.o

编译后生成了多种不同类型的 firmware 文件，还有一个 payloads 目录。下面单独拿出一个小节来做介绍。

### Firmware 说明

为了兼容不同的运行需求，OpenSBI 支持三种类型的 Firmware，分别为：

* dynamic：从上一级 Boot Stage 获取下一级 Boot Stage 的入口信息，以 `struct fw_dynamic_info` 结构体通过 `a2` 寄存器传递。
* jump：假设下一级 Boot Stage Entry 为固定地址，直接跳转过去运行。
* payload：在 jump 的基础上，直接打包进来下一级 Boot Stage 的 Binary。

下一级通常是 Bootloader 或 OS，比如 U-Boot，Linux。

Firmware 相关的源码在 OpenSBI 的 `firmware/` 目录下。

### 运行

OpenSBI 提供了直接运行的 make 入口：

    $ make run PLATFORM=generic
    qemu-system-riscv64 -M virt -m 256M -nographic -bios /labs/linux-lab/src/examples/opensbi/build/platform/generic/firmware/fw_payload.elf

    OpenSBI v1.0-38-g794986f
       ____                    _____ ____ _____
      / __ \                  / ____|  _ \_   _|
     | |  | |_ __   ___ _ __ | (___ | |_) || |
     | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
     | |__| | |_) |  __/ | | |____) | |_) || |_
      \____/| .__/ \___|_| |_|_____/|____/_____|
            | |
            |_|

    Platform Name             : riscv-virtio,qemu
    Platform Features         : medeleg
    Platform HART Count       : 1
    Platform IPI Device       : aclint-mswi
    Platform Timer Device     : aclint-mtimer @ 10000000Hz
    Platform Console Device   : uart8250
    Platform HSM Device       : ---
    Platform Reboot Device    : sifive_test
    Platform Shutdown Device  : sifive_test
    Firmware Base             : 0x80000000
    Firmware Size             : 284 KB
    Runtime SBI Version       : 0.3

    Domain0 Name              : root
    Domain0 Boot HART         : 0
    Domain0 HARTs             : 0*
    Domain0 Region00          : 0x0000000002000000-0x000000000200ffff (I)
    Domain0 Region01          : 0x0000000080000000-0x000000008007ffff ()
    Domain0 Region02          : 0x0000000000000000-0xffffffffffffffff (R,W,X)
    Domain0 Next Address      : 0x0000000080200000
    Domain0 Next Arg1         : 0x0000000082200000
    Domain0 Next Mode         : S-mode
    Domain0 SysReset          : yes

    Boot HART ID              : 0
    Boot HART Domain          : root
    Boot HART ISA             : rv64imafdcsu
    Boot HART Features        : scounteren,mcounteren
    Boot HART PMP Count       : 16
    Boot HART PMP Granularity : 4
    Boot HART PMP Address Bits: 54
    Boot HART MHPM Count      : 0
    Boot HART MIDELEG         : 0x0000000000000222
    Boot HART MEDELEG         : 0x000000000000b109

    Test payload running

`fw_payload.elf` 默认打包进去了 `build/platform/generic/firmware/payloads/test.bin`。如果需要打包 U-boot 或 Linux，可以参考 `docs/firmware/fw_payload.md` 传递 `FW_PAYLOAD_PATH` 参数指定需要打包 image 的路径，更详细用法可分别参考：

* docs/firmware/payload_linux.md
* docs/firmware/payload_uboot.md

`firmware/payloads/` 下的 test payload 是一个很好的 Next Boot Stage 的例子：

* `test_head.S` - 做了一些执行 C 程序前的准备并跳转到 C 程序
* `test.elf.ldS` - 链接脚本，涉及到 Payload 的内存装载位置， 由 `FW_TEXT_START + FW_PAYLOAD_OFFSET` 确定
* `test_main.c` - C 程序，主要是通过 `ecall` 调用 OpenSBI 的字符串打印接口写了一行字符串

### 调试

如果要进一步深入分析 OpenSBI：

* 一方面可以结合 cscope 等工具摸清各个函数之间的调用关系，进而理解 OpenSBI 的代码结构。
* 另外一方面可以用 gdb + Qemu 研究 OpenSBI 的整个执行流程

`docs/platform/qemu_virt.md` 的最后有描述如何开展 OpenSBI 的调试，这里不做重述。

## 在 Linux Lab 下使用 OpenSBI

### 更新 Linux Lab 中的 OpenSBI 固件

作为一套完善的内核实验框架，Linux Lab 为 RISC-V 提供了完整的 Linux 实验支持，提供了 2 套虚拟开发板：`riscv32/virt` 和 `riscv64/virt`。

其中，有用到 OpenSBI 作为 Bootloader。

    $ cd /labs/linux-lab
    $ grep BIOS -ur boards/riscv64/virt/Makefile
    BIOS    ?= $(BSP_BIOS)/opensbi/generic/fw_jump.elf

其完整路径为：

    $ ls boards/riscv64/virt/bsp/bios/opensbi/generic/fw_jump.elf
    boards/riscv64/virt/bsp/bios/opensbi/generic/fw_jump.elf

在客制化 OpenSBI 以后，可以复制 OpenSBI build 目录中的 `fw_jump.elf` 到 Linux Lab 中的上述路径下进行使用。

    $ cd /labs/linux-lab
    $ cp src/examples/build/platform/generic/firmware/fw_jump.elf boards/riscv64/virt/bsp/bios/opensbi/generic/fw_jump.elf

复制完以后就可以通过 `make boot` 引导 OpenSBI 和内核：

    $ make BOARD=riscv64/virt
    $ make boot
    ...
    OpenSBI v1.0-38-g794986f
       ____                    _____ ____ _____
      / __ \                  / ____|  _ \_   _|
     | |  | |_ __   ___ _ __ | (___ | |_) || |
     | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
     | |__| | |_) |  __/ | | |____) | |_) || |_
      \____/| .__/ \___|_| |_|_____/|____/_____|
            | |
            |_|

    Platform Name             : riscv-virtio,qemu
    Platform Features         : medeleg
    Platform HART Count       : 4
    Platform IPI Device       : aclint-mswi
    Platform Timer Device     : aclint-mtimer @ 10000000Hz
    Platform Console Device   : uart8250
    Platform HSM Device       : ---
    Platform Reboot Device    : sifive_test
    Platform Shutdown Device  : sifive_test
    Firmware Base             : 0x80000000
    Firmware Size             : 308 KB
    Runtime SBI Version       : 0.3

    Domain0 Name              : root
    Domain0 Boot HART         : 0
    Domain0 HARTs             : 0*,1*,2*,3*
    Domain0 Region00          : 0x0000000002000000-0x000000000200ffff (I)
    Domain0 Region01          : 0x0000000080000000-0x000000008007ffff ()
    Domain0 Region02          : 0x0000000000000000-0xffffffffffffffff (R,W,X)
    Domain0 Next Address      : 0x0000000080200000
    Domain0 Next Arg1         : 0x0000000082200000
    Domain0 Next Mode         : S-mode
    Domain0 SysReset          : yes

    Boot HART ID              : 0
    Boot HART Domain          : root
    Boot HART ISA             : rv64imafdcsu
    Boot HART Features        : scounteren,mcounteren,time
    Boot HART PMP Count       : 16
    Boot HART PMP Granularity : 4
    Boot HART PMP Address Bits: 54
    Boot HART MHPM Count      : 0
    Boot HART MIDELEG         : 0x0000000000000222
    Boot HART MEDELEG         : 0x000000000000b109
    Linux version 5.17.0-dirty (ubuntu@linux-lab) (riscv64-linux-gnu-gcc (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0, GNU ld (GNU Binutils for Ubuntu) 2.34) #8 SMP Wed Mar 23 17:22:04 CST 2022
    OF: fdt: Ignoring memory range 0x80000000 - 0x80200000
    Machine model: riscv-virtio,qemu
    efi: UEFI not found.
    Zone ranges:
      DMA32    [mem 0x0000000080200000-0x0000000087ffffff]
      Normal   empty
    Movable zone start for each node
    Early memory node ranges
      node   0: [mem 0x0000000080200000-0x0000000087ffffff]
    Initmem setup node 0 [mem 0x0000000080200000-0x0000000087ffffff]
    SBI specification v0.3 detected
    SBI implementation ID=0x1 Version=0x10000
    SBI TIME extension detected
    SBI IPI extension detected
    SBI RFENCE extension detected
    SBI SRST extension detected
    SBI HSM extension detected
    riscv: ISA extensions acdfimsu
    riscv: ELF capabilities acdfim
    percpu: Embedded 16 pages/cpu s24792 r8192 d32552 u65536
    Built 1 zonelists, mobility grouping on.  Total pages: 31815
    Kernel command line: route=172.20.169.140 iface=eth0 rw fsck.repair=yes rootwait root=/dev/vda console=ttyS0
    Unknown kernel command line parameters "route=172.20.169.140 iface=eth0", will be passed to user space.
    ...
    devtmpfs: mounted
    Freeing unused kernel image (initmem) memory: 2140K
    Hello, RISC-V Linux: https://gitee.com/tinylab/riscv-linux
    Happy Hacking .................
    Run /sbin/init as init process
    EXT4-fs (vda): re-mounted. Quota mode: disabled.
    Starting syslogd: OK
    Starting klogd: OK
    Initializing random number generator... random: dd: uninitialized urandom read (512 bytes read)
    done.

    Welcome to Linux Lab
    linux-lab login: root
    #
    # uname -a
    Linux linux-lab 5.17.0-dirty #8 SMP Wed Mar 23 17:22:04 CST 2022 riscv64 GNU/Linux
    # poweroff
    ...
    The system is going down NOW!
    Sent SIGTERM to all processes
    Sent SIGKILL to all processes
    Requesting system poweroff
    reboot: Power down

### 分析 Linux 内核中对 OpenSBI 的调用

类似上面的 test payload，在 Linux 内核中，也有通过 `ecall` 调用 OpenSBI 的服务。

    $ cd src/linux-stable
    $ find arch/riscv/ -name "*sbi*"
    arch/riscv/include/asm/cpu_ops_sbi.h
    arch/riscv/include/asm/kvm_vcpu_sbi.h
    arch/riscv/include/asm/sbi.h
    arch/riscv/kernel/cpu_ops_sbi.c
    arch/riscv/kernel/sbi.c
    arch/riscv/kvm/vcpu_sbi.c
    arch/riscv/kvm/vcpu_sbi_base.c
    arch/riscv/kvm/vcpu_sbi_hsm.c
    arch/riscv/kvm/vcpu_sbi_replace.c
    arch/riscv/kvm/vcpu_sbi_v01.c

其中，核心的实现在 sbi.c：

    // arch/riscv/kernel/sbi.c: 25

    struct sbiret sbi_ecall(int ext, int fid, unsigned long arg0,
                            unsigned long arg1, unsigned long arg2,
                            unsigned long arg3, unsigned long arg4,
                            unsigned long arg5)
    {
            struct sbiret ret;

            register uintptr_t a0 asm ("a0") = (uintptr_t)(arg0);
            register uintptr_t a1 asm ("a1") = (uintptr_t)(arg1);
            register uintptr_t a2 asm ("a2") = (uintptr_t)(arg2);
            register uintptr_t a3 asm ("a3") = (uintptr_t)(arg3);
            register uintptr_t a4 asm ("a4") = (uintptr_t)(arg4);
            register uintptr_t a5 asm ("a5") = (uintptr_t)(arg5);
            register uintptr_t a6 asm ("a6") = (uintptr_t)(fid);
            register uintptr_t a7 asm ("a7") = (uintptr_t)(ext);
            asm volatile ("ecall"
                          : "+r" (a0), "+r" (a1)
                          : "r" (a2), "r" (a3), "r" (a4), "r" (a5), "r" (a6), "r" (a7)
                          : "memory");
            ret.error = a0;
            ret.value = a1;

            return ret;
    }
    EXPORT_SYMBOL(sbi_ecall);

其中，`a0-a5` 作为参数，而 `ext` 和 `fid` 一起决定 OpenSBI 服务的 id，而返回的错误信息和返回值通过 `a0-a1` 取回。

关于服务的定义，可参考：

    // arch/riscv/include/asm/sbi.h: 13

    #ifdef CONFIG_RISCV_SBI
    enum sbi_ext_id {
    #ifdef CONFIG_RISCV_SBI_V01
            SBI_EXT_0_1_SET_TIMER = 0x0,
            SBI_EXT_0_1_CONSOLE_PUTCHAR = 0x1,
            SBI_EXT_0_1_CONSOLE_GETCHAR = 0x2,
            SBI_EXT_0_1_CLEAR_IPI = 0x3,
            SBI_EXT_0_1_SEND_IPI = 0x4,
            SBI_EXT_0_1_REMOTE_FENCE_I = 0x5,
            SBI_EXT_0_1_REMOTE_SFENCE_VMA = 0x6,
            SBI_EXT_0_1_REMOTE_SFENCE_VMA_ASID = 0x7,
            SBI_EXT_0_1_SHUTDOWN = 0x8,
    #endif
            SBI_EXT_BASE = 0x10,
            SBI_EXT_TIME = 0x54494D45,
            SBI_EXT_IPI = 0x735049,
            SBI_EXT_RFENCE = 0x52464E43,
            SBI_EXT_HSM = 0x48534D,
            SBI_EXT_SRST = 0x53525354,

            /* Experimentals extensions must lie within this range */
            SBI_EXT_EXPERIMENTAL_START = 0x08000000,
            SBI_EXT_EXPERIMENTAL_END = 0x08FFFFFF,

            /* Vendor extensions must lie within this range */
            SBI_EXT_VENDOR_START = 0x09000000,
            SBI_EXT_VENDOR_END = 0x09FFFFFF,
    };

    enum sbi_ext_base_fid {
            SBI_EXT_BASE_GET_SPEC_VERSION = 0,
            SBI_EXT_BASE_GET_IMP_ID,
            SBI_EXT_BASE_GET_IMP_VERSION,
            SBI_EXT_BASE_PROBE_EXT,
            SBI_EXT_BASE_GET_MVENDORID,
            SBI_EXT_BASE_GET_MARCHID,
            SBI_EXT_BASE_GET_MIMPID,
    };

    enum sbi_ext_time_fid {
            SBI_EXT_TIME_SET_TIMER = 0,
    };

    enum sbi_ext_ipi_fid {
            SBI_EXT_IPI_SEND_IPI = 0,
    };

其中，可以很容易看出 `ext` 和 `fid` 之间的关系，例如，在 base extension 下有 7 个 fid，而 time extension 下只有 1 个 fid，两者一起指定具体的服务函数，有点像 2 级映射。

具体地，timer 的 SBI 调用被封装成了：

    // arch/riscv/kernel/sbi.c: 240

    static void __sbi_set_timer_v02(uint64_t stime_value)
    {
    #if __riscv_xlen == 32
            sbi_ecall(SBI_EXT_TIME, SBI_EXT_TIME_SET_TIMER, stime_value,
                      stime_value >> 32, 0, 0, 0, 0);
    #else
            sbi_ecall(SBI_EXT_TIME, SBI_EXT_TIME_SET_TIMER, stime_value, 0,
                      0, 0, 0, 0);
    #endif
    }

需要注意地是，SBI 规范是不断演进的，可以看到内核代码中其实还有一个老的 `__sbi_set_timer_v01`，内核是通过 `sbi_probe_extension` 来探测 SBI 是否支持某个具体的 Extension：

    // arch/riscv/kernel/sbi.c: 580

    /**
     * sbi_probe_extension() - Check if an SBI extension ID is supported or not.
     * @extid: The extension ID to be probed.
     *
     * Return: Extension specific nonzero value f yes, -ENOTSUPP otherwise.
     */
    int sbi_probe_extension(int extid)
    {
            struct sbiret ret;

            ret = sbi_ecall(SBI_EXT_BASE, SBI_EXT_BASE_PROBE_EXT, extid,
                            0, 0, 0, 0, 0);
            if (!ret.error)
                    if (ret.value)
                            return ret.value;

            return -ENOTSUPP;
    }
    EXPORT_SYMBOL(sbi_probe_extension);

### OpenSBI 中如何提供服务

OpenSBI 通过 `lib/sbi` 注册了相关的 ecall 服务，全部加到了链表 `ecall_exts_list` 中：

    // lib/sbi/sbi_ecall.c: 144

    int sbi_ecall_init(void)
    {
            int ret;

            /* The order of below registrations is performance optimized */
            ret = sbi_ecall_register_extension(&ecall_time);
            if (ret)
                    return ret;
            ret = sbi_ecall_register_extension(&ecall_rfence);
            if (ret)
                    return ret;
            ret = sbi_ecall_register_extension(&ecall_ipi);
            if (ret)
                    return ret;
            ret = sbi_ecall_register_extension(&ecall_base);
            if (ret)
                    return ret;
            ret = sbi_ecall_register_extension(&ecall_hsm);
            if (ret)
                    return ret;
            ret = sbi_ecall_register_extension(&ecall_srst);
            if (ret)
                    return ret;
            ret = sbi_ecall_register_extension(&ecall_pmu);
            if (ret)
                    return ret;
            ret = sbi_ecall_register_extension(&ecall_legacy);
            if (ret)
                    return ret;
            ret = sbi_ecall_register_extension(&ecall_vendor);
            if (ret)
                    return ret;

            return 0;
    }

服务和 id 的映射由 `ecall_xxx` 对应的结构体 `struct sbi_ecall_extension` 中的 `extid_xxx` 和 `handle` 进行处理：

    // include/sbi/sbi_ecall.h: 23

    struct sbi_ecall_extension {
            struct sbi_dlist head;
            unsigned long extid_start;
            unsigned long extid_end;
            int (* probe)(unsigned long extid, unsigned long *out_val);
            int (* handle)(unsigned long extid, unsigned long funcid,
                           const struct sbi_trap_regs *regs,
                           unsigned long *out_val,
                           struct sbi_trap_info *out_trap);
    };

    // lib/sbi/sbi_ecall_replace.c: 22
    static int sbi_ecall_time_handler(unsigned long extid, unsigned long funcid,
                                      const struct sbi_trap_regs *regs,
                                      unsigned long *out_val,
                                      struct sbi_trap_info *out_trap)
    {
            int ret = 0;

            if (funcid == SBI_EXT_TIME_SET_TIMER) {
    #if __riscv_xlen == 32
                    sbi_timer_event_start((((u64)regs->a1 << 32) | (u64)regs->a0));
    #else
                    sbi_timer_event_start((u64)regs->a0);
    #endif
            } else
                    ret = SBI_ENOTSUPP;

            return ret;
    }

    struct sbi_ecall_extension ecall_time = {
            .extid_start = SBI_EXT_TIME,
            .extid_end = SBI_EXT_TIME,
            .handle = sbi_ecall_time_handler,
    };

而具体的服务定义在特定的文件中，比如 `lib/sbi/sbi_timer.c` 中定义 timer 相关的 SBI 服务。

### ecall 服务调用过程

当发起 Linux 的 `ecall` 调用后，这些 OpenSBI 中的服务具体是怎么触发的呢？这就涉及到如下过程：

* 在 `firmware/fw_base.S` 中注册了 Machine Mode 的 trap handler，即 `sbi_trap_handler`
* 在 `lib/sbi/sbi_trap.c` 中定义了 `sbi_trap_handler`，处理各种 mcause，比如 Illegal Instructions，Misaligned Load & Store, Supervisor & Machine Ecall 等。
* 在 `lib/sbi/sbi_ecall.c` 中定义了处理 ecall mcause 的 `sbi_ecall_handler`，它遍历上面 `ecall_exts_list` 中注册的各种 ecall 服务。
* `sbi_ecall_handler` 根据 Linux 内核传递的 ext (extension id) 找到链表中对应的 ecall 服务，执行其中的 `handle` 函数，该函数根据 fid 执行具体的服务内容。

代码细节这里不做展开，大家打开相应源码，检索对应的关键字即可轻松找到。

## 小结

本文带领大家开展了基本的 OpenSBI 下载、编译、运行和调试实验，并进一步介绍了 Linux 内核如何调用 OpenSBI 的服务。

在这个基础上，大家就可以进一步探索更具体的服务实现甚至定制一些自己的服务啦。比如说，通过修改 `sbi_illegal_insn_handler` 在 OpenSBI 模拟处理器未实现的指令。

## 参考资料

* OpenSBI: docs/firmware/
* OpenSBI: docs/platform/{generic.md,qemu_virt.md}
