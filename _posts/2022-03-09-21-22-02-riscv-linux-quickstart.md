---
layout: post
author: 'Wu Zhangjin'
title: "如何分析 Linux 内核 RISC-V 架构相关代码"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /riscv-linux-quickstart/
description: "RISC-V Linux 内核兴趣小组于近日建立，将首要聚焦 Linux 内核 RISC-V 架构部分的剖析，本文介绍如何分析 Linux 内核 RISC-V 架构相关源码，并介绍了相关工具，是参与人员必读篇。"
category:
  - 开源项目
  - Risc-V
tags:
  - cscope
  - tree
  - RISC-V
  - Linux
  - git
---

> By Falcon of [TinyLab.org][1]
> Mar 09, 2022

## 背景简介

本次 **RISC-V Linux 内核剖析** 活动的主要目标是分析 Linux 内核对 RISC-V 架构的相关支持，因此，重点是分析 Linux 内核的 `arch/riscv` 目录。

有两个方向可以去分析，一个是直接分析 `arch/riscv` 的目录结构，另外一个是分析 `arch/riscv` 相关的历史改动。

但是通常可以把两者结合起来，如果把现有的 `arch/riscv` 目录结构比作一栋建好的房子，那 `arch/riscv` 历史改动能呈现房子的建设过程，地基怎么打，骨架怎么放，一砖一瓦如何添加进去，都有完整的记录和描述。

本次活动的目标内核版本是 Linux v5.17，由于 v5.17 还未发布，本文先以 v5.16 为例，待 v5.17 正式版本发布以后，后续输出以 v5.17 为基准。另外，本次活动以 riscv64 为主。

## 准备好 Linux 内核代码仓库

由于 Linux 内核代码很大，特别是本次活动需要用到 git 仓库，下载体验无法保障，不建议自行去下载。

可以考虑用本次活动推荐的 [Linux Lab](https://gitee.com/tinylab/linux-lab) 实验环境，已经对下载做了透明加速，直接用 `make kernel-download` 直接下载。

也可以直接在某宝选购免安装即插即用的 Linux Lab Disk 智能随身系统盘，已经预先帮忙下载好了较新的内核源码（v5.16, v5.17-rcX），仅需通过 `git fetch --all` 更新到后续的 v5.17 正式版。

Linux Lab 或 Linux Lab Disk 还提供了本活动后续要用到的 RISC-V Linux 内核编译和运行环境。

在 Linux Lab Disk 下，可以用桌面的 `Linux Lab Shell` 登陆，登陆后默认就在 `/labs/linux-lab` 工作目录。对于自行安装的情况，请参考使用手册用 `tools/docker/bash` 登陆。

接下来，需要切换到 `riscv64/virt` 虚拟开发板并克隆出一套 v5.16 配置。

    $ make BOARD=riscv64/virt
    $ make kernel-clone LINUX_NEW=v5.16

**说明**：`riscv64/virt` 虚拟开发板仅向活动参与者开放，其他用户可在选购 Linux Lab Disk 后申请内置。

Linux Lab 默认把 Linux 内核源码放置在 `src/linux-stable` 目录：

    $ make kernel-download
    $ cd src/linux-stable

为了聚焦本次活动，基础环境的搭建部分将不再过多介绍，请参考 [相关手册](https://gitee.com/link?target=https%3A%2F%2Ftinylab.org%2Fpdfs%2Flinux-lab-v0.9-manual-zh.pdf)、[连载文章](https://www.zhihu.com/column/tinylab) 和 [演示视频](https://www.cctalk.com/m/group/88948325)。

## arch/riscv 目录结构

这里用 `tree` 工具展示一下整体的结构，大概了解一下框架和位置就行：

    $ tree arch/riscv/
    ├── boot
    │   ├── dts                      # device tree support
    │   │   ├── canaan
    │   │   │   ├── canaan_kd233.dts
    │   │   │   ├── k210.dtsi
    │   │   │   ├── k210_generic.dts
    │   │   │   ├── Makefile
    │   │   │   ├── sipeed_maix_bit.dts
    │   │   │   ├── sipeed_maix_dock.dts
    │   │   │   ├── sipeed_maixduino.dts
    │   │   │   └── sipeed_maix_go.dts
    │   │   ├── Makefile
    │   │   ├── microchip
    │   │   │   ├── Makefile
    │   │   │   ├── microchip-mpfs.dtsi
    │   │   │   └── microchip-mpfs-icicle-kit.dts
    │   │   └── sifive
    │   │       ├── fu540-c000.dtsi
    │   │       ├── fu740-c000.dtsi
    │   │       ├── hifive-unleashed-a00.dts
    │   │       ├── hifive-unmatched-a00.dts
    │   │       └── Makefile
    │   ├── install.sh
    │   ├── loader.lds.S
    │   ├── loader.S
    │   └── Makefile
    ├── configs                      # default configuration
    │   ├── defconfig
    │   ├── nommu_k210_defconfig
    │   ├── nommu_k210_sdcard_defconfig
    │   ├── nommu_virt_defconfig
    │   └── rv32_defconfig
    ├── errata                       # errata (cpu bug fixup)
    │   ├── alternative.c
    │   ├── Makefile
    │   └── sifive
    │       ├── errata.c
    │       ├── errata_cip_453.S
    │       └── Makefile
    ├── include                      # headers
    │   ├── asm
    │   │   ├── alternative.h
    │   │   ├── alternative-macros.h
    │   │   ├── asm.h
    │   │   ├── asm-offsets.h
    │   │   ├── asm-prototypes.h
    │   │   ├── atomic.h
    │   │   ├── barrier.h
    │   │   ├── bitops.h
    │   │   ├── bug.h
    │   │   ├── cacheflush.h
    │   │   ├── cache.h
    │   │   ├── cacheinfo.h
    │   │   ├── clint.h
    │   │   ├── clocksource.h
    │   │   ├── cmpxchg.h
    │   │   ├── cpu_ops.h
    │   │   ├── csr.h
    │   │   ├── current.h
    │   │   ├── delay.h
    │   │   ├── efi.h
    │   │   ├── elf.h
    │   │   ├── errata_list.h
    │   │   ├── fence.h
    │   │   ├── fixmap.h
    │   │   ├── ftrace.h
    │   │   ├── futex.h
    │   │   ├── gdb_xml.h
    │   │   ├── hugetlb.h
    │   │   ├── hwcap.h
    │   │   ├── image.h
    │   │   ├── io.h
    │   │   ├── irqflags.h
    │   │   ├── irq.h
    │   │   ├── irq_work.h
    │   │   ├── jump_label.h
    │   │   ├── kasan.h
    │   │   ├── Kbuild
    │   │   ├── kdebug.h
    │   │   ├── kexec.h
    │   │   ├── kgdb.h
    │   │   ├── kprobes.h
    │   │   ├── linkage.h
    │   │   ├── mmio.h
    │   │   ├── mmiowb.h
    │   │   ├── mmu_context.h
    │   │   ├── mmu.h
    │   │   ├── mmzone.h
    │   │   ├── module.h
    │   │   ├── module.lds.h
    │   │   ├── numa.h
    │   │   ├── page.h
    │   │   ├── parse_asm.h
    │   │   ├── patch.h
    │   │   ├── pci.h
    │   │   ├── perf_event.h
    │   │   ├── pgalloc.h
    │   │   ├── pgtable-32.h
    │   │   ├── pgtable-64.h
    │   │   ├── pgtable-bits.h
    │   │   ├── pgtable.h
    │   │   ├── probes.h
    │   │   ├── processor.h
    │   │   ├── ptdump.h
    │   │   ├── ptrace.h
    │   │   ├── sbi.h
    │   │   ├── seccomp.h
    │   │   ├── sections.h
    │   │   ├── set_memory.h
    │   │   ├── smp.h
    │   │   ├── soc.h
    │   │   ├── sparsemem.h
    │   │   ├── spinlock.h
    │   │   ├── spinlock_types.h
    │   │   ├── stackprotector.h
    │   │   ├── stacktrace.h
    │   │   ├── string.h
    │   │   ├── switch_to.h
    │   │   ├── syscall.h
    │   │   ├── thread_info.h
    │   │   ├── timex.h
    │   │   ├── tlbflush.h
    │   │   ├── tlb.h
    │   │   ├── uaccess.h
    │   │   ├── unistd.h
    │   │   ├── uprobes.h
    │   │   ├── vdso
    │   │   │   ├── clocksource.h
    │   │   │   ├── gettimeofday.h
    │   │   │   ├── processor.h
    │   │   │   └── vsyscall.h
    │   │   ├── vdso.h
    │   │   ├── vendorid_list.h
    │   │   ├── vermagic.h
    │   │   ├── vmalloc.h
    │   │   └── word-at-a-time.h
    │   └── uapi
    │       └── asm
    │           ├── auxvec.h
    │           ├── bitsperlong.h
    │           ├── bpf_perf_event.h
    │           ├── byteorder.h
    │           ├── elf.h
    │           ├── hwcap.h
    │           ├── Kbuild
    │           ├── perf_regs.h
    │           ├── ptrace.h
    │           ├── sigcontext.h
    │           ├── ucontext.h
    │           └── unistd.h
    ├── Kbuild                       # Build support with configurations enabled in Kconfig
    ├── Kconfig                      # Configuration support for defconfig, menuconfig ...
    ├── Kconfig.debug
    ├── Kconfig.erratas
    ├── Kconfig.socs
    ├── kernel
    │   ├── asm-offsets.c            # tasks support, required to generate asm-offsets.h, see Documentation/kbuild/makefiles.rst and Kbuild
    │   ├── cacheinfo.c              # cache support
    │   ├── cpu.c                    # /proc/cpuinfo
    │   ├── cpufeature.c             # hwcap
    │   ├── cpu-hotplug.c            # cpu hotplug
    │   ├── cpu_ops.c
    │   ├── cpu_ops_sbi.c
    │   ├── cpu_ops_spinwait.c
    │   ├── crash_dump.c             # crash support
    │   ├── crash_save_regs.S
    │   ├── efi.c                    # UEFI boot support
    │   ├── efi-header.S
    │   ├── entry.S                  # entries for exceptions and interrupts
    │   ├── fpu.S                    # fpu
    │   ├── ftrace.c                 # ftrace
    │   ├── head.h
    │   ├── head.S                   # boot code
    │   ├── image-vars.h
    │   ├── irq.c                    # irqs
    │   ├── jump_label.c             # [jump_label](https://lwn.net/Articles/412072/), required by tracepoint
    │   ├── kexec_relocate.S         # kexec
    │   ├── kgdb.c                   # kgdb
    │   ├── machine_kexec.c          # kexec
    │   ├── Makefile
    │   ├── mcount-dyn.S             # ftrace
    │   ├── mcount.S
    │   ├── module.c                 # module support
    │   ├── module-sections.c
    │   ├── patch.c
    │   ├── perf_callchain.c         # perf
    │   ├── perf_event.c
    │   ├── perf_regs.c
    │   ├── probes                   # kprobes & uprobes
    │   │   ├── decode-insn.c
    │   │   ├── decode-insn.h
    │   │   ├── ftrace.c
    │   │   ├── kprobes.c
    │   │   ├── kprobes_trampoline.S
    │   │   ├── Makefile
    │   │   ├── simulate-insn.c
    │   │   ├── simulate-insn.h
    │   │   └── uprobes.c
    │   ├── process.c                # scheduling
    │   ├── ptrace.c                 # ptrace
    │   ├── reset.c                  # reboot
    │   ├── riscv_ksyms.c
    │   ├── sbi.c                    # sbi
    │   ├── setup.c                  # setup_arch (dtb parse, ioremap setup, jump label init, efi init, paging init, mem init, res init, sbi init, kasan init, setup smp)
    │   ├── signal.c                 # signal
    │   ├── smpboot.c                # smp
    │   ├── smp.c
    │   ├── soc.c                    # soc init
    │   ├── stacktrace.c             # stacktrace
    │   ├── syscall_table.c          # syscall
    │   ├── sys_riscv.c
    │   ├── time.c                   # time
    │   ├── traps.c                  # traps
    │   ├── traps_misaligned.c
    │   ├── vdso                     # vdso
    │   │   ├── flush_icache.S
    │   │   ├── getcpu.S
    │   │   ├── Makefile
    │   │   ├── note.S
    │   │   ├── rt_sigreturn.S
    │   │   ├── so2s.sh
    │   │   ├── vdso.lds.S
    │   │   ├── vdso.S
    │   │   └── vgettimeofday.c
    │   ├── vdso.c
    │   ├── vmlinux.lds.S            # vmlinux linker script
    │   └── vmlinux-xip.lds.S        # xip support
    ├── lib                          # libs
    │   ├── delay.c
    │   ├── error-inject.c
    │   ├── Makefile
    │   ├── memcpy.S
    │   ├── memmove.S
    │   ├── memset.S
    │   ├── tishift.S
    │   └── uaccess.S
    ├── Makefile
    ├── mm                           # memory management
    │   ├── cacheflush.c
    │   ├── context.c
    │   ├── extable.c                # extable
    │   ├── fault.c
    │   ├── hugetlbpage.c            # hugetlb
    │   ├── init.c
    │   ├── kasan_init.c             # kasan
    │   ├── Makefile
    │   ├── pageattr.c
    │   ├── physaddr.c
    │   ├── ptdump.c
    │   └── tlbflush.c
    └── net
        ├── bpf_jit_comp32.c         # eBPF
        ├── bpf_jit_comp64.c
        ├── bpf_jit_core.c
        ├── bpf_jit.h
        └── Makefile

    19 directories, 237 files

涉及到具体代码文件和代码行改动的时候，可以用 `git log` 和 `git blame` 辅助查看。

    $ git log arch/riscv/kernel/mcount.S
    $ git blame -L 103,103 arch/riscv/kernel/mcount.S

涉及到代码函数定义的查找部分可以参考本文后续章节介绍的 cscope 用法。

## arch/riscv 历史改动

可以直接通过 `git log arch/riscv` 查看 `arch/riscv` 目录的所有改动。

首先找出来 `arch/riscv` 的第一笔改动：

    $ git log --oneline arch/riscv
    ...
    fab957c11efe RISC-V: Atomic and Locking Code
    76d2a0493a17 RISC-V: Init and Halt Code

因为内容比较多，下面的指令只列出每个 Commit 的标题（`--oneline`），并按照逆序的方式排列（`--reverse`），也过滤掉了部分非核心的代码（`egrep`），从而方便从头开始一笔一笔分析。

    $ git rev-list --oneline 76d2a0493a17^..v5.16 --reverse arch/riscv \
        | egrep -v " Merge | Backmerge | dts| kbuild| asm-generic| firmware| include| Documentation| Revert| drivers | config | Rename"

    76d2a0493a17 RISC-V: Init and Halt Code
    fab957c11efe RISC-V: Atomic and Locking Code
    5d8544e2d007 RISC-V: Generic library routines and assembly
    2129a235c098 RISC-V: ELF and module implementation
    7db91e57a0ac RISC-V: Task implementation
    6d60b6ee0c97 RISC-V: Device, timer, IRQs, and the SBI
    07037db5d479 RISC-V: Paging and MMU
    e2c0cdfba7f6 RISC-V: User-facing API
    fbe934d69eb7 RISC-V: Build Infrastructure
    b7e5a591502b RISC-V: Remove __vdso_cmpxchg{32,64} symbol versions
    28dfbe6ed483 RISC-V: Add VDSO entries for clock_get/gettimeofday/getcpu
    4650d02ad2d9 RISC-V: Remove unused arguments from ATOMIC_OP
    8286d51a6c24 RISC-V: Comment on why {,cmp}xchg is ordered how it is
    61a60d35b7d1 RISC-V: Remove __smp_bp__{before,after}_atomic
    3343eb6806f3 RISC-V: Remove smb_mb__{before,after}_spinlock()
    9347ce54cd69 RISC-V: __test_and_op_bit_ord should be strongly ordered
    21db403660d1 RISC-V: Add READ_ONCE in arch_spin_is_locked()
    c901e45a999a RISC-V: `sfence.vma` orderes the instruction cache
    bf7305527343 RISC-V: remove spin_unlock_wait()
    5ddf755e4439 RISC-V: use generic serial.h
    5e6f82b0fe7b RISC-V: use RISCV_{INT,SHORT} instead of {INT,SHORT} for asm macros
    fe2726af9fdc RISC-V: io.h: type fixes for warnings
    83e7b8769a08 RISC-V: move empty_zero_page definition to C and export it
    24948b7ec0f3 RISC-V: Export some expected symbols for modules
    4bde63286a6c RISC-V: Provide stub of setup_profiling_timer()
    4a41d5dbb0bb RISC-V: Use define for get_cycles like other architectures
    08f051eda33b RISC-V: Flush I$ when making a dirty page executable
    921ebd8f2c08 RISC-V: Allow userspace to flush the instruction cache
    da894ff100be RISC-V: __io_writes should respect the length argument
    07f8ba7439f9 RISC-V: User-Visible Changes
    7382fbdeae0d RISC-V: __io_writes should respect the length argument
    3b62de26cf5e RISC-V: Fixes for clean allmodconfig build
    5e454b5457b5 riscv: use linux/uaccess.h, not asm/uaccess.h...
    c895f6f703ad bpf: correct broken uapi for BPF_PROG_TYPE_PERF_EVENT program type
    86ad5c97ce5c RISC-V: Logical vs Bitwise typo
    3cfa5008081d RISC-V: Resurrect smp_mb__after_spinlock()
    27b017452532 RISC-V: Remove unused CONFIG_HVC_RISCV_SBI code
    33c57c0d3c67 RISC-V: Add a basic defconfig
    9e49a4ed072a RISC-V: Make __NR_riscv_flush_icache visible to userspace
    c163fb38ca34 riscv: remove CONFIG_MMU ifdefs
    1125203c13b9 riscv: rename SR_* constants to match the spec
    b8ee205af46c riscv: remove the unused dma_capable helper
    0500871f21b2 Construct init thread stack in the linker script rather than by union
    c5cd037d1c80 dma-mapping: provide a generic asm/dma-mapping.h
    002e67454f61 dma-direct: rename dma_noop to dma_direct
    3e076a7e0492 RISC-V: Remove duplicate command-line parsing logic
    5d44bf2065e1 RISC-V: Remove mem_end command line processing
    10626c32e382 riscv/ftrace: Add basic support
    0b5030c8c052 riscv: remove unused __ARCH_HAVE_MMU define
    509009ccfa53 riscv: remove redundant unlikely()
    fe9b842f7292 riscv: disable SUM in the exception handler
    f1b65f20fb05 RISC-V: Limit the scope of TLB shootdowns
    5ec9c4ff0430 riscv: add ZONE_DMA32
    0ca7a0b7c13e riscv: remove the unused current_pgdir function
    372def1f9341 riscv: don't read back satp in paging_init
    7549cdf59d9f riscv: rename sptbr to satp
    4889dec6c87d riscv: inline set_pgdir into its only caller
    ab0dc41b7324 riscv: Remove ARCH_WANT_OPTIONAL_GPIOLIB select
    2aaa2dc31bee riscv: kconfig: Remove RISCV_IRQ_INTC select
    89a4b4441206 riscv: Remove ARCH_HAS_ATOMIC64_DEC_IF_POSITIVE select
    bcae803a2131 RISC-V: Enable IRQ during exception handling
    ab4af6053410 riscv/barrier: Define __smp_{mb,rmb,wmb}
    cc6c98485f8e RISC-V: Move to the new GENERIC_IRQ_MULTI_HANDLER handler
    a90f590a1bee mm: add ksys_mmap_pgoff() helper; remove in-kernel calls to sys_mmap_pgoff()
    a1d2a6b4cee8 riscv/ftrace: Add RECORD_MCOUNT support
    c15ac4fd60d5 riscv/ftrace: Add dynamic function tracer support
    bc1a4c3a8425 riscv/ftrace: Add dynamic function graph tracer support
    71e736a7d655 riscv/ftrace: Add ARCH_SUPPORTS_FTRACE_OPS support
    aea4c671fb98 riscv/ftrace: Add DYNAMIC_FTRACE_WITH_REGS support
    b785ec129bd9 riscv/ftrace: Add HAVE_FUNCTION_GRAPH_RET_ADDR_PTR support
    8d235b174af5 riscv/barrier: Define __smp_{store_release,load_acquire}
    0123f4d76ca6 riscv/spinlock: Strengthen implementations with fences
    5ce6c1f3535f riscv/atomic: Strengthen implementations with fences
    ab1ef68e5401 RISC-V: Add sections of PLT and GOT for kernel module
    b8bde0ef12bd RISC-V: Add section of GOT.PLT for kernel module
    da975dd4818c RISC-V: Support GOT_HI20/CALL_PLT relocation type in kernel module
    e1910c72bdc4 RISC-V: Support CALL relocation type in kernel module
    e7456e696bff RISC-V: Support HI20/LO12_I/LO12_S relocation type in kernel module
    56ea45ae2392 RISC-V: Support RVC_BRANCH/JUMP relocation type in kernel modulewq
    29e405cd88c3 RISC-V: Support ALIGN relocation type in kernel module
    8e691b16769d RISC-V: Support ADD32 relocation type in kernel module
    4aad074c9c1d RISC-V: Support SUB32 relocation type in kernel module
    4a632cec8884 RISC-V: Enable module support in defconfig
    e21d54219c7a RISC-V: Add definition of relocation types
    2c9046b71bb6 RISC-V: Assorted memory model fixes
    7a8e7da42250 RISC-V: Fixes to module loading
    86e11757d8b2 riscv: select DMA_DIRECT_OPS instead of redefining it
    5b7252a26870 riscv: there is no <asm/handle_irq.h>
    85602bea297f RISC-V: build vdso-dummy.o with -no-pie
    3eb0f5193b49 signal: Ensure every siginfo we send has all bits initialized
    4d6a20b13558 signal/riscv: Use force_sig_fault where appropriate
    7ff3a7621dda signal/riscv: Replace do_trap_siginfo with force_sig_fault
    325ef1857fff PCI: remove PCI_DMA_BUS_IS_PHYS
    6e88628d03dd dma-debug: remove CONFIG_HAVE_DMA_API_DEBUG
    2ff075c7dfd4 drivers: base: cacheinfo: setup DT cache properties early
    c3e4ed012ba7 riscv: simplify Kconfig magic for 32-bit vs 64-bit kernels
    f1306f0423ec riscv: only enable ZONE_DMA32 for 64-bit
    10314e09d044 riscv: add swiotlb support
    ebcbd75e3962 riscv: Fix the bug in memory access fixup code
    178e9fc47aae perf: riscv: preliminary RISC-V support
    32c81bced356 RISC-V: Preliminary Perf Support
    2861ae302f6b riscv: use NULL instead of a plain 0
    9bf97390b303 riscv: no __user for probe_kernel_address()
    3010a5ea665a mm: introduce ARCH_HAS_PTE_SPECIAL
    86406d51d360 riscv: split the declaration of __copy_user
    889d746edd02 riscv: add riscv-specific predefines to CHECKFLAGS
    1dd985229d5f riscv/ftrace: Export _mcount when DYNAMIC_FTRACE isn't set
    77aa85de16ae RISC-V: Handle R_RISCV_32 in modules
    e0e0c87c022b RISC-V: Make our port sparse-clean
    24a130ccfe58 RISC-V: Add CONFIG_HVC_RISCV_SBI=y to defconfig
    8b47038e6d34 atomics/treewide: Remove redundant atomic_inc_not_zero() definitions
    bef828204a1b atomics/treewide: Make atomic64_inc_not_zero() optional
    eccc2da8c03f atomics/treewide: Make atomic_fetch_add_unless() optional
    2b523f170e39 atomics/riscv: Define atomic64_fetch_add_unless()
    18cc1814d4e7 atomics/treewide: Make test ops optional
    9837559d8eb0 atomics/treewide: Make unconditional inc/dec ops optional
    d5fad48cfb4b RISC-V: Add conditional macro for zone of DMA32
    8f79125d285d RISC-V: Select GENERIC_UCMPDI2 on RV32I
    c480d8911fda RISC-V: Add definiion of extract symbol's index and type for 32-bit
    7df85002178e RISC-V: Change variable type for 32-bit compatible
    781c8fe2da3d RISC-V: fix R_RISCV_ADD32/R_RISCV_SUB32 relocations
    f67f10b8a6c9 riscv: remove unnecessary of_platform_populate call
    1db9b80980d2 RISC-V: Fix PTRACE_SETREGSET bug.
    9a6a51154f8b RISC-V: Fix the rv32i kernel build
    fd2efaa4eb53 locking/atomics: Rework ordering barriers
    06ec64b84c35 Kconfig: consolidate the "Kernel hacking" menu
    4938c79bd0f5 RISC-V: Use KBUILD_CFLAGS instead of KCFLAGS when building the vDSO
    a89757daf25c RISC-V: implement __lshrti3.
    758914fea278 RISC-V: Don't increment sepc after breakpoint.
    5b5c2a2c44d7 RISC-V: Add early printk support via the SBI console
    b9490350f751 RISC-V: remove timer leftovers
    b9d5535746e3 RISC-V: simplify software interrupt / IPI code
    4b40e9ddc892 RISC-V: remove INTERRUPT_CAUSE_* defines from asm/irq.h
    bec2e6ac353d RISC-V: add a definition for the SIE SEIE bit
    6ea0f26a7913 RISC-V: implement low-level interrupt handling
    62b019436814 clocksource: new RISC-V SBI timer driver
    94f592f0e5b9 RISC-V: Add the directive for alignment of stvec's value
    8237f8bc4f6e irqchip: add a SiFive PLIC driver
    4c42ae4f6ab7 RISC-V: Fix !CONFIG_SMP compilation error
    50a7ca3c6fc8 mm: convert return type of handle_mm_fault() caller to vm_fault_t
    7847e7052fc3 RISC-V: Define sys_riscv_flush_icache when SMP=n
    66eb957df4c7 riscv: Delete asm/compat.h
    7a3b1bf70b37 RISC-V: Fix sys_riscv_flush_icache
    0ce5671c4450 riscv: tlb: Provide definition of tlb_flush() before including tlb.h
    47d80a68f10d RISC-V: Use a less ugly workaround for unused variable warnings
    e866d3e84eb7 riscv: Do not overwrite initrd_start and initrd_end
    67314ec7b025 RISC-V: Request newstat syscalls
    ef1f2258748b RISCV: Fix end PFN for low memory
    f28380185193 signal: Remove the need for __ARCH_SI_PREABLE_SIZE and SI_PAD_SIZE
    e68ad867f77e Extract FPU context operations from entry.S
    007f5c358957 Refactor FPU code in signal setup/return procedures
    e8be53023302 Cleanup ISA string setting
    9671f7061433 Allow to disable FPU support
    9411ec60c23d Auto-detect whether a FPU exists
    7f47c73b355f RISC-V: Build tishift only on 64-bit
    51858aaf9bea RISC-V: Use swiotlb on RV64 only
    757331db9214 RISC-V: Select GENERIC_LIB_UMODDI3 on RV32
    827a438156e4 RISC-V: Avoid corrupting the upper 32-bit of phys_addr_t in ioremap
    1ed4237ab616 RISC-V: No need to pass scause as arg to do_IRQ()
    566d6c428ead RISC-V: Don't set cacheinfo.{physical_line_partition,attributes}
    19ccf29bb18f RISC-V: Filter ISA and MMU values in cpuinfo
    b18d6f05252d RISC-V: Comment on the TLB flush in smp_callin()
    6db170ff4c08 RISC-V: Disable preemption before enabling interrupts
    9639a44394b9 RISC-V: Provide a cleaner raw_smp_processor_id()
    46373cb442c5 RISC-V: Use mmgrab()
    a37d56fc4011 RISC-V: Use WRITE_ONCE instead of direct access
    6825c7a80f18 RISC-V: Add logical CPU indexing for RISC-V
    f99fb607fb2b RISC-V: Use Linux logical CPU number instead of hartid
    4b26d22fdff1 RISC-V: Show CPU ID and Hart ID separately in /proc/cpuinfo
    8b20d2db0a6d RISC-V: Show IPI stats
    1760debb51f7 RISC-V: Don't set cacheinfo.{physical_line_partition,attributes}
    86e581e31078 RISC-V: Mask out the F extension on systems without D
    b8c8a9590e4f RISC-V: Add FP register ptrace support for gdb.
    b90edb33010b RISC-V: Add futex support.
    f31b8de98853 RISC-V: remove the unused return_to_handler export
    ee5928843a93 riscv: move GCC version check for ARCH_SUPPORTS_INT128 to Kconfig
    aef53f97b505 RISC-V: Cosmetic menuconfig changes
    4e4101cfefd3 riscv: Add support to no-FPU systems
    a6de21baf637 RISC-V: Fix some RV32 bugs and build failures
    d26c4bbf9924 RISC-V: SMP cleanup and new features
    de0d22e50cd3 treewide: remove current_text_addr
    b4a991ec584b mm: remove CONFIG_NO_BOOTMEM
    aca52c398389 mm: remove CONFIG_HAVE_MEMBLOCK
    c6ffc5ca8fb3 memblock: rename free_all_bootmem to memblock_free_all
    732e8e4130ff RISC-V: properly determine hardware caps
    9b4789eacb65 Move EM_RISCV into elf-em.h
    ef70696a63c7 lib: Remove umoddi3 and udivmoddi4
    ba1f0d955769 RISC-V: refresh defconfig
    4ab49461d9d9 RISC-V: defconfig: Enable printk timestamps
    10febb3ecace riscv: fix spacing in struct pt_regs
    f157d411a9eb riscv: add missing vdso_install target
    85d90b91807b RISC-V: lib: Fix build error for 64-bit
    ef3a61406618 RISC-V: Silence some module warnings on 32-bit
    21f70d4abf9e RISC-V: Fix raw_copy_{to,from}_user()
    c0fbcd991860 RISC-V: Build flat and compressed kernel images
    0138ebb90c63 riscv: fix warning in arch/riscv/include/asm/module.h
    27f8899d6002 riscv: add asm/unistd.h UAPI header
    5d8f81ba1da5 RISC-V: recognize S/U mode bits in print_isa
    e949b6db51dc riscv/function_graph: Simplify with function_graph_enter()
    3731c3d4774e dma-mapping: always build the direct mapping code
    55897af63091 dma-direct: merge swiotlb_dma_ops into the dma_direct code
    2b3f786408c5 RISC-V: defconfig: Enable RISC-V SBI earlycon support
    7ba12bb676c2 RISC-V: Remove EARLY_PRINTK support
    8636a1f9677d treewide: surround Kconfig file paths with double quotes
    8b699616f399 riscv, atomic: Add #define's for the atomic_{cmp,}xchg_*() variants
    94f9bf118f1e RISC-V: Fix of_node_* refcount
    cd378dbb3daf RISC-V: add of_node_put()
    397182e0db56 riscv: remove unused variable in ftrace
    3aed8c43267e RISC-V: Update Kconfig to better handle CMDLINE
    358f3fff5271 RISC-V: Move from EARLY_PRINTK to SBI earlycon
    a266cdba17b3 RISC-V: lib: minor asm cleanup
    9b9afe4a0ef1 RISC-V: Select GENERIC_SCHED_CLOCK for clocksource drivers
    96d4f267e40f Remove 'type' argument from access_ok() function
    4cf58924951e mm: treewide: remove unused address argument from pte_alloc functions
    8c4fa8b8d483 riscv: remove redundant kernel-space generic-y
    d4ce5458ea1b arch: remove stale comments "UAPI Header export list"
    d6e4b3e326d8 arch: remove redundant UAPI generic-y defines
    22e6a2e14cb8 RISC-V: Make BSS section as the last section in vmlinux.lds.S
    8fd6e05c7463 arch: riscv: support kernel command line forcing when no DTB passed
    37a107ff6dcd riscv: don't stop itself in smp_send_stop
    2cffc9569050 RISC-V: Support MODULE_SECTIONS mechanism on RV32
    efe75c494f57 riscv: add audit support
    0aea89430a4c riscv: audit: add audit hook in do_syscall_trace_enter/exit()
    45ef1aa8a0e3 riscv: define NR_syscalls in unistd.h
    008e901b7028 riscv: define CREATE_TRACE_POINTS in ptrace.c
    775800b0f1d7 riscv: fix trace_sys_exit hook
    5aeb1b36cedd riscv: add HAVE_SYSCALL_TRACEPOINTS to Kconfig
    801009424e05 Fix a handful of audit-related issue
    99fd6e875d0c RISC-V: Add _TIF_NEED_RESCHED check for kernel thread when CONFIG_PREEMPT=y
    2bb10639f12c RISC-V: fix bad use of of_node_put
    8581f38742cf RISC-V: asm/page.h: fix spelling mistake "CONFIG_64BITS" -> "CONFIG_64BIT"
    86cca81a31cd RISC-V: Kconfig: fix spelling mistake "traget" -> "target"
    a37ead8f2efb RISC-V: defconfig: Move CONFIG_PCI{,E_XILINX}
    e4cf9e47ab24 RISC-V: defconfig: Enable Generic PCIE by default
    2a200fb9fb12 RISC-V: defconfig: Add CRYPTO_DEV_VIRTIO=y
    28198c4639b3 riscv: fixup max_low_pfn with PFN_DOWN.
    ae662eec8a51 riscv: Adjust mmap base address at a third of task size
    2353ecc6f91f bpf, riscv: add BPF JIT for RV64G
    e3613bb8afc2 riscv: Add pte bit to distinguish swap from invalid
    7265d103902c riscv: add missing newlines to printk messages
    e1b1381b3179 riscv: use pr_info and friends
    149820c6cf3c riscv: fix riscv_of_processor_hartid() comment
    e3d794d555cd riscv: treat cpu devicetree nodes without status as enabled
    dd81c8ab819d riscv: use for_each_of_cpu_node iterator
    79a47bad61bb riscv: remove the HAVE_KPROBES option
    ff4c25f26a71 dma-mapping: improve selection of dma_declare_coherent availability
    680f9b8e6c56 RISC-V: Setup init_mm before parse_early_param()
    0651c263c8e3 RISC-V: Move setup_bootmem() to mm/init.c
    6f1e9e946f0b RISC-V: Move setup_vm() to mm/init.c
    f2c17aabc917 RISC-V: Implement compile-time fixed mappings
    823900cd0130 RISC-V: Free-up initrd in free_initrd_mem()
    d4c08b9776b3 riscv: Use latest system call ABI
    ce246c444a08 riscv: io: Update __io_[p]ar() macros to take an argument
    e15c6e37066e RISC-V: Do not wait indefinitely in __cpu_up
    78d1daa36489 RISC-V: Move cpuid to hartid mapping to SMP.
    ba15c86185e9 RISC-V: Remove NR_CPUs check during hartid search from DT
    dd641e268673 RISC-V: Allow hartid-to-cpuid function to fail.
    291debb38dbb RISC-V: Compare cpuid with NR_CPUS before mapping.
    fbdc6193dc70 RISC-V: Assign hwcap as per comman capabilities.
    736706bee329 get rid of legacy 'get_ds()' function
    f7ccc35aa3bd arch: riscv: fix logic error in parse_dtb
    13fd5de06514 RISC-V: Fixmap support and MM cleanups
    795c230604cb riscv/vdso: don't clear PG_reserved
    16add411645c syscall_get_arch: add "struct task_struct *" argument
    dbee9c9c4584 riscv: fix accessing 8-byte variable from RV32
    387181dcdb6c RISC-V: Always compile mm/init.c with cmodel=medany and notrace
    ff0e2a7bd13f RISC-V: Fix FIXMAP_TOP to avoid overlap with VMALLOC area
    da4ed3787391 RISC-V: Use IS_ENABLED(CONFIG_CMODEL_MEDLOW)
    390a0c62c23c locking/rwsem: Remove rwsem-spinlock.c & use rwsem-xadd.c for all archs
    10a16997db3d riscv: Fix syscall_get_arguments() and syscall_set_arguments()
    b35f549df1d7 syscalls: Remove start and number from syscall_get_arguments() args
    32d92586629a syscalls: Remove start and number from syscall_set_arguments() args
    1b937e8faa87 RISC-V: Add separate defconfig for 32bit systems
    f05badde4e20 RISC-V: Fix Maximum Physical Memory 2GiB option for 64bit systems
    fa9833992d5f riscv/stacktrace: Remove the pointless ULONG_MAX marker
    7a64f3f1cffd riscv/signal: Fixup additional syscall restarting
    5cfade5fdcc9 riscv: turn mm_segment_t into a struct
    e28dcc77e8e8 riscv: remove unreachable big endian code
    09afac77b6e8 riscv: remove CONFIG_RISCV_ISA_A
    df16c40cbfb4 riscv: clear all pending interrupts when booting
    c637b911e066 riscv: simplify the stack pointer setup in head.S
    ba9c0141941c riscv: cleanup the parse_dtb calling conventions
    877425424d6c riscv: remove unreachable !HAVE_FUNCTION_GRAPH_RET_ADDR_PTR code
    6ab77af4b0ee riscv: remove duplicate macros from ptrace.h
    bed137870663 riscv: print the unexpected interrupt cause
    bf0102a0fdd9 riscv: call pm_power_off from machine_halt / machine_power_off
    fd7f744caed8 riscv: vdso: drop unnecessary cc-ldoption
    70114560b285 RISC-V: Add RISC-V specific arch_match_cpu_phys_id
    ab3d26500547 RISC-V: Implement nosmp commandline option.
    0d7b4a607d8f riscv: switch over to generic free_initmem()
    8b4302a442af RISC-V: Support nr_cpus command line option.
    f1f47c6ca34b RISC-V: Fix minor checkpatch issues.
    196a14d45161 RISC-V: Use tabs to align macro values in asm/csr.h
    6dcaf00487ca RISC-V: Add interrupt related SCAUSE defines in asm/csr.h
    a3182c91ef4e RISC-V: Access CSRs using CSR numbers
    58de77545e53 riscv: move flush_icache_{all,mm} to cacheflush.c
    f6635f873a60 riscv: move switch_mm to its own file
    a21344dfc6ad riscv: fix sbi_remote_sfence_vma{,_asid}.
    d18ebc274ca7 riscv: support trap-based WARN()
    ee72e0e70cf7 riscv: Add the support for c.ebreak check in is_valid_bugaddr()
    9a6e7af02f7f riscv: Support BUG() in kernel module
    4c3aeb82a0f4 RISC-V: Avoid using invalid intermediate translations
    a967a289f169 RISC-V: sifive_l2_cache: Add L2 cache controller driver for SiFive SoCs
    8fef9900d43f riscv: fix locking violation in page fault handler
    ec8f24b7faaf treewide: Add SPDX license identifier - Makefile/Kconfig
    fe121ee531d1 bpf, riscv: clear target register high 32-bits for and/or/xor on ALU32
    b4d0d230ccfb treewide: Replace GPLv2 boilerplate/reference with SPDX - rule 36
    588cb88cedd5 treewide: Replace GPLv2 boilerplate/reference with SPDX - rule 120
    66d0d5a854a6 riscv: bpf: eliminate zero extension code-gen
    3cf5d076fb4d signal: Remove task parameter from force_sig
    6f25a967646a signal/riscv: Remove tsk parameter from do_trap
    351b6825b3a9 signal: Explicitly call force_sig_fault on current
    2e1661d26736 signal: Remove the task parameter from force_sig_fault
    2874c5fd2842 treewide: Replace GPLv2 boilerplate/reference with SPDX - rule 152
    c942fddf8793 treewide: Replace GPLv2 boilerplate/reference with SPDX - rule 157
    1802d0beecaf treewide: Replace GPLv2 boilerplate/reference with SPDX - rule 174
    96ac6d435100 treewide: Add SPDX license identifier - Kbuild
    1e692f09e091 bpf, riscv: clear high 32 bits for ALU32 add/sub/neg/lsh/rsh/arsh
    33e42ef57197 locking/atomic, riscv: Fix atomic64_sub_if_positive() offset argument
    0754211847d7 locking/atomic, riscv: Use s64 for atomic64
    50acfb2b76e1 treewide: Replace GPLv2 boilerplate/reference with SPDX - rule 286
    bd305f259cd3 kconfig: make arch/*/configs/defconfig the default of KBUILD_DEFCONFIG
    3b025f2bc989 RISC-V: defconfig: enable clocks, serial console
    405945588fee riscv: export pm_power_off again
    d0e1f2110a5e riscv: Fix udelay in RV32.
    8d4e048d60bd arch: riscv: add support for building DTB files from DT source data
    bf587caae305 riscv: mm: synchronize MMU after pte change
    259931fd3b96 riscv: remove unused barrier defines
    caab277b1de0 treewide: Replace GPLv2 boilerplate/reference with SPDX - rule 234
    d2912cb15bdd treewide: Replace GPLv2 boilerplate/reference with SPDX - rule 500
    91abaeaaff35 EDAC/sifive: Add EDAC platform driver for SiFive SoCs
    ad97f9df0fee riscv: add binfmt_flat support
    ff8391e1b7d2 RISC-V: defconfig: enable MMC & SPI for RISC-V
    0db7f5cd4aeb riscv: mm: Fix code comment
    6dd91e0eacff RISC-V: defconfig: Enable NO_HZ_IDLE and HIGH_RES_TIMERS
    556024d41f39 riscv: Remove gate area stubs
    bbc5dc5155aa riscv: defconfig: enable SOC_SIFIVE
    d90d45d7dcb7 RISC-V: Fix memory reservation in setup_bootmem()
    9e953cda5cdf riscv: Introduce huge page support for 32/64bit kernel
    df7e9059cf6b riscv: ccache: Remove unused variable
    2ebca1cbb4a5 riscv: remove free_initrd_mem
    46dd3d7d287b bpf, riscv: Enable zext optimization for more RV64G ALU ops
    671f9a3e2e24 RISC-V: Setup initial page tables in two stages
    0f327f2aaad6 RISC-V: Add an Image header that boot loader can parse.
    d1b46fe50c8b riscv: switch to generic version of pte allocation
    b74c0cad3d5f riscv: drop unneeded -Wall addition
    2d69fbf3d01a riscv: fix build break after macro-to-function conversion in generic cacheflush.h
    56ac5e213933 riscv: enable sys_clone3 syscall for rv64
    03f11f03dbfe RISC-V: Parse cpu topology during boot.
    d9c525229521 treewide: add "WITH Linux-syscall-note" to SPDX tag of uapi headers
    b399abe7c21e riscv: Fix perf record without libelf support
    b7edabfe8438 riscv: defconfig: align RV64 defconfig to the output of "make savedefconfig"
    66cc016ab7c7 riscv: delay: use do_div() instead of __udivdi3()
    81a48ee41738 RISC-V: Remove udivdi3
    eb93685847a9 riscv: fix flush_tlb_range() end address for flush_tlb_page()
    500bc2c1f48a riscv: rv32_defconfig: Update the defconfig
    d568cb3f9351 riscv: defconfig: Update the defconfig
    8ac71d7e46b9 riscv: Correct the initialized flow of FP register
    69703eb9a8ae riscv: Make __fstate_clean() work correctly.
    a256f2e329df RISC-V: Fix FIXMAP area corruption on RV32 systems
    4f3f90084673 riscv: Using CSR numbers to access CSRs
    d95f1a542c3d RISC-V: Implement sparsemem
    909548d6c578 riscv: add arch/riscv/Kbuild
    dbeb90b0c1eb riscv: Add perf callchain support
    98a93b0b561c riscv: Add support for perf registers sampling
    7e0e50895fdf riscv: refactor the IPI code
    1db7a7ca5ac5 riscv: cleanup send_ipi_mask
    e11ea2a02b93 riscv: optimize send_ipi_single
    f5bf645d10f2 riscv: cleanup riscv_cpuid_to_hartid_mask
    2f12dbf190d9 riscv: don't use the rdtime(h) pseudo-instructions
    95594cb40c6e riscv: move the TLB flush logic out of line
    474efecb65dc riscv: modify the Image header to improve compatibility with the ARM64 header
    b6f2b2e600a2 RISC-V: Fix building error when CONFIG_SPARSEMEM_MANUAL=y
    b47613da3b71 arch/riscv: disable excess harts before picking main boot hart
    d3d7a0ce020e RISC-V: Export kernel symbols for kvm
    c82dd6d078a2 riscv: Avoid interrupts being erroneously enabled in handle_exception()
    13224794cb08 mm: remove quicklist page table caches
    782de70c4293 mm: consolidate pgtable_cache_init() and pgd_cache_init()
    54c95a11cc1b riscv: make mmap allocation top-down by default
    b4ed71f557e4 mm: treewide: clarify pgtable_page_{ctor,dtor}() naming
    18856604b3e7 RISC-V: Clear load reservations while restoring hart contexts
    922b0375fc93 riscv: Fix memblock reservation for device tree blob
    8b04825ed205 riscv: avoid kernel hangs when trapped in BUG()
    e0c0fc18f10d riscv: avoid sending a SIGTRAP to a user thread trapped in WARN()
    8bb0daef64e5 riscv: Correct the handling of unexpected ebreak in do_trap_break()
    cd9e72b80090 RISC-V: entry: Remove unneeded need_resched() loop
    2f01b7864188 riscv: remove the switch statement in do_trap_break()
    4c8eb19cf9dc riscv: tlbflush: remove confusing comment on local_flush_tlb_all()
    5bf4e52ff031 RISC-V: fix virtual address overlapped in FIXADDR_START and VMEMMAP_START
    04ce8d3f40cd riscv: Use pr_warn instead of pr_warning
    90db7b220c9a riscv: fix fs/proc/kcore.c compilation with sparsemem enabled
    62103ece5236 riscv: Fix implicit declaration of 'page_to_section'
    9fe57d8c575d riscv: Fix undefined reference to vmemmap_populate_basepages
    a6d9e2672609 riscv: cleanup <asm/bug.h>
    e8f44c50dfe7 riscv: cleanup do_trap_break
    ffaee2728f9b riscv: add prototypes for assembly language functions from head.S
    6a527b6785ba riscv: init: merge split string literals in preprocessor directive
    bf6df5dd25b7 riscv: mark some code and data as file-static
    a48dac448d85 riscv: fp: add missing __user pointer annotations
    f307307992bf riscv: for C functions called only from assembly, mark with __visible
    00a5bf3a8ca3 RISC-V: Add PCIe I/O BAR memory mapping
    1edd28b7e85d RISC-V: Remove unsupported isa string info print
    5340627e3fe0 riscv: add support for SECCOMP and SECCOMP_FILTER
    6384423f49c8 RISC-V: Do not invoke SBI call if cpumask is empty
    31738ede9b33 RISC-V: Issue a local tlbflush if possible.
    6efb16b1d551 RISC-V: Issue a tlb page flush if possible
    eaf937075c9a vmlinux.lds.h: Move NOTES into RO_DATA
    93240b327929 vmlinux.lds.h: Replace RO_DATA_SECTION with RO_DATA
    c9174047b48d vmlinux.lds.h: Replace RW_DATA_SECTION with RW_DATA
    86fe639a1c16 riscv: enter WFI in default_power_off() if SBI does not shutdown
    0c3ac28931d5 riscv: separate MMIO functions into their own header file
    a4c3733d32a7 riscv: abstract out CSR names for supervisor vs machine mode
    38af57825313 riscv: use the generic ioremap code
    0fdc636cd95c riscv: Use PMD_SIZE to replace PTE_PARENT_SIZE
    6b57ba8ed48a riscv: clean up the macro format in each header file
    8083c629dc31 RISC-V: Add multiple compression image format.
    3b03ac6bbd6e riscv: poison SBI calls for M-mode
    3320648ecc38 riscv: cleanup the default power off implementation
    8bf90f320d9a riscv: implement remote sfence.i using IPIs
    4f9bbcefa142 riscv: add support for MMIO access to the timer registers
    c12d3362a74b int128: move __uint128_t compiler test to Kconfig
    fcdc65375186 riscv: provide native clint access for M-mode
    accb9dbc4aff riscv: read the hart ID from mhartid on boot
    9e80635619b5 riscv: clear the instruction cache and all registers when booting
    6bd33e1ece52 riscv: add nommu support
    405fe7aa0dba riscv: provide a flat image loader
    de29fe308de7 riscv: Fix Kconfig indentation
    f2c5fd9e4c05 riscv: defconfigs: enable debugfs
    2e06b2717535 riscv: defconfigs: enable more debugging options
    2cc6c4a0da4a RISC-V: Add address map dumper
    29ff64929e6c sched/rt, riscv: Use CONFIG_PREEMPTION
    0e72a2f9c1a3 riscv: Fix build dependency for loader
    bc3e8f5d42d5 riscv: only select serial sifive if TTY is enabled
    1f059dfdf5d1 mm/vmalloc: Add empty <asm/vmalloc.h> headers and use them from <linux/vmalloc.h>
    96bc4432f5ad bpf, riscv: Limit to 33 tail calls
    f1003b787c00 riscv, bpf: Fix broken BPF tail calls
    7d1ef13fea2b riscv, bpf: Add support for far branching
    29d92edd9ee8 riscv, bpf: Add support for far branching when emitting tail call
    33203c02f2f8 riscv, bpf: Add support for far jumps and exits
    fe8322b866d5 riscv, bpf: Optimize BPF tail calls
    7f3631e88ee6 riscv, bpf: Provide RISC-V specific JIT image alloc/free
    e368b64f8b0c riscv, bpf: Optimize calls
    eb9928bed003 riscv, bpf: Add missing uapi header for BPF_PROG_TYPE_PERF_EVENT programs
    34bfc10a6e7e riscv, perf: Add arch specific perf_arch_bpf_user_pt_regs
    1d5c17e47028 RISC-V: Typo fixes in image header and documentation.
    d411cf02ed02 riscv: fix scratch register clearing in M-mode.
    01f52e16b868 riscv: define vmemmap before pfn_to_page calls
    9209fb51896f riscv: move sifive_l2_cache.c to drivers/soc
    4d47ce158efb riscv: fix compile failure with EXPORT_SYMBOL() & !MMU
    556f47ac6083 riscv: reject invalid syscalls below -1
    1833e327a5ea riscv: export flush_icache_all to modules
    ac51e005fe14 riscv: mm: use __pa_symbol for kernel symbols
    0da310e82d3a riscv: gcov: enable gcov for RISC-V
    1d8f65798240 riscv: ftrace: correct the condition logic in function graph tracer
    2f3035da4019 riscv: prefix IRQ_ macro names with an RV_ namespace
    20bda4ed62f5 riscv: Implement copy_thread_tls
    dc6fcba72f04 riscv: Fixup obvious bug for fp-regs reset
    2680e04c1874 arch/riscv/setup: Drop dummy_con initialization
    20d2292754e7 riscv: make sure the cores stay looping in .Lsecondary_park
    95f4d9cced96 riscv: delete temporary files
    fc585d4a5cf6 riscv: Less inefficient gcc tishift helpers (and export their symbols)
    8ad8b72721d0 riscv: Add KASAN support
    fc76324fa27f riscv: keep 32-bit kernel to 32-bit phys_addr_t
    6435f773d81f riscv: mm: add support for CONFIG_DEBUG_VIRTUAL
    af6513ead046 riscv: mm: add p?d_leaf() definitions
    c68a9032299e riscv: set pmp configuration if kernel is running in M-mode
    6a1ce99dc4bd RISC-V: Don't enable all interrupts in trap_init()
    e7167043ee50 riscv: Fix gitignore
    a0a31fd84f8f riscv: allocate a complete page size for each page table
    8458ca147c20 riscv: adjust the indent
    0cff8bff7af8 riscv: avoid the PIC offset of static percpu data in module beyond 2G limits
    aad15bc85c18 riscv: Change code model of module to medany to improve data accessing
    ab70a73aa45b riscv: Use flush_icache_mm for flush_icache_user_range
    2fab7a15604c riscv: Delete CONFIG_SYSFS_SYSCALL from defconfigs
    aff7783392e0 riscv: force hart_lottery to put in .sdata section
    064223b947a8 RISC-V: Stop putting .sbss in .sdata
    52e7c52d2ded RISC-V: Stop relying on GCC's register allocator's hueristics
    fdff9911f266 RISC-V: Inline the assembly register save/restore macros
    abc71bf0a703 RISC-V: Stop using LOCAL for the uaccess fixups
    aa2734202acc riscv: Force flat memory model with no-mmu
    a160eed4b783 riscv: Fix range looking for kernel image memblock
    ca6cb5447cec riscv, bpf: Factor common RISC-V JIT code
    5f316b65e99f riscv, bpf: Add RV32G eBPF JIT
    759bdc168181 RISC-V: Add kconfig option for QEMU virt machine
    a4485398b6b8 RISC-V: Enable QEMU virt machine support in defconfigs
    81e2d3c52c0e RISC-V: Select SYSCON Reboot and Poweroff for QEMU virt machine
    d2047aba2e68 RISC-V: Select Goldfish RTC driver for QEMU virt machine
    3133287b53ee riscv: Use p*d_leaf macros to define p*d_huge
    af33d2433b03 riscv: fix seccomp reject syscall code path
    9f40b6e77d2f RISC-V: Move all address space definition macros to one place
    ccbe80bad571 irqchip/sifive-plic: Enable/Disable external interrupts upon cpu online/offline
    adccfb1a805e riscv: uaccess should be used in nommu mode
    3384b043ea15 riscv: fix the IPI missing issue in nommu mode
    d198b34f3855 .gitignore: add SPDX License Identifier
    d3ab332a5021 riscv: add ARCH_HAS_SET_MEMORY support
    395a21ff859c riscv: add ARCH_HAS_SET_DIRECT_MAP support
    5fde3db5eb02 riscv: add ARCH_SUPPORTS_DEBUG_PAGEALLOC support
    bd3d914d16aa riscv: move exception table immediately after RO_DATA
    00cb41d5ad31 riscv: add alignment for text, rodata and data sections
    d27c3c90817e riscv: add STRICT_KERNEL_RWX support
    b42d763a2d41 riscv: add macro to get instruction length
    043cb41a85de riscv: introduce interfaces to patch kernel code
    8fdddb2eae73 riscv: patch code by fixmap mapping
    59c4da8640cc riscv: Add support to dump the kernel page tables
    88d110382555 riscv: Use macro definition instead of magic number
    2191b4f298fa RISC-V: Move all address space definition macros to one place
    a08971e9488d futex: arch_futex_atomic_op_inuser() calling conventions change
    8446923ae4d7 RISC-V: Mark existing SBI as 0.1 SBI.
    b9dcd9e41587 RISC-V: Add basic support for SBI v0.2
    ecbacc2a3efd RISC-V: Add SBI v0.2 extension definitions
    1ef46c231df4 RISC-V: Implement new SBI v0.2 extensions
    e011995e826f RISC-V: Move relocate and few other functions out of __init
    2875fe056156 RISC-V: Add cpu_ops and modify default booting method
    f90b43ce176c RISC-V: Export SBI error to linux error mapping function
    db5a79460315 RISC-V: Add SBI HSM extension definitions
    cfafe2601374 RISC-V: Add supported for ordered booting method using HSM
    f1e58583b9c7 RISC-V: Support cpu hotplug
    4ef873226ceb mm: introduce fault_signal_pending()
    dde160724832 mm: introduce FAULT_FLAG_DEFAULT
    4064b9827063 mm: allow VM_FAULT_RETRY for multiple times
    93bbb2555b65 riscv, bpf: Remove BPF JIT for nommu builds
    956d705dd279 riscv: Unaligned load/store handling for M_MODE
    335b139057ef riscv: Add SOC early init support
    c48c4a4c7ead riscv: Add Kendryte K210 SoC support
    5ba568f57f0a riscv: Add Kendryte K210 device tree
    aa10eb6bb8a9 riscv: Kendryte K210 default config
    37809df4b1c8 riscv: create a loader.bin boot image for Kendryte SoC
    489553dd13a8 riscv, bpf: Fix offset range checking for auipc+jalr on RV64
    c62da0c35d58 mm/vma: define a default value for VM_DATA_DEFAULT_FLAGS
    af2bdf828f79 RISC-V: stacktrace: Declare sp_in_global outside ifdef
    3c1918c8f541 riscv: fix vdso build with lld
    72df61d9d66e riscv: sbi: Correct sbi_shutdown() and sbi_clear_ipi() export
    7d0ce3b2b483 riscv: sbi: Fix undefined reference to sbi_shutdown
    62d0fd591db1 arch: split MODULE_ARCH_VERMAGIC definitions out to <asm/vermagic.h>
    a5fe13c7b494 riscv: select ARCH_HAS_STRICT_KERNEL_RWX only if MMU
    745abfaa9eaf bpf, riscv: Fix tail call count off by one in RV32 BPF JIT
    91f658587a96 bpf, riscv: Fix stack layout of JITed code on RV32
    7391efa48d88 RISC-V: Export riscv_cpuid_to_hartid_mask() API
    6bcff51539cc RISC-V: Add bitmap reprensenting ISA features common across CPUs
    a2da5b181f88 RISC-V: Remove N-extension related defines
    c749bb2d5548 riscv: set max_pfn to the PFN of the last page
    0a9f2a6161dc riscv: add Linux note to vdso
    d6d5161280b3 riscv: force __cpu_up_ variables to put in data section
    73cb8e2a5863 RISC-V: Remove unused code from STRICT_KERNEL_RWX
    0224b2acea0f bpf, riscv: Enable missing verifier_zext optimizations on RV64
    21a099abb765 bpf, riscv: Optimize FROM_LE using verifier_zext on RV64
    ca349a6a104e bpf, riscv: Optimize BPF_JMP BPF_K when imm == 0 on RV64
    073ca6a0369e bpf, riscv: Optimize BPF_JSET BPF_K using andi on RV64
    e7b146a8bfba riscv: perf_event: Make some funciton static
    48084c3595cb riscv: perf: RISCV_BASE_PMU should be independent
    ab7fbad0c7d7 riscv: Fix unmet direct dependencies built based on SOC_VIRT
    0502bee37cde riscv: stacktrace: Fix undefined reference to `walk_stackframe'
    fa8174aa225f riscv: Add pgprot_writecombine/device and PAGE_SHARED defination if NOMMU
    21e2414083e2 riscv: Disable ARCH_HAS_DEBUG_VIRTUAL if NOMMU
    69868418e148 riscv: Make SYS_SUPPORTS_HUGETLBFS depends on MMU
    9a6630aef933 riscv: pgtable: Fix __kernel_map_pages build error if NOMMU
    ed1ed4c0da54 riscv: mmiowb: Fix implicit declaration of function 'smp_processor_id'
    2d2682512f0f riscv: Allow device trees to be built into the kernel
    8bb661742776 riscv: K210: Add a built-in device tree
    045c654220e5 riscv: K210: Update defconfig
    eb077c9c387f RISC-V: Skip setting up PMPs on traps
    fe89bd2be866 riscv: Add KGDB support
    d96575709cc7 riscv: Use the XML target descriptions to report 3 system registers
    edde5584c7ab riscv: Add SW single-step support for KDB
    b80b3d582ebd riscv: Remove the 'riscv_' prefix of function name
    5303df244cbf riscv: Use NOKPROBE_SYMBOL() instead of __krpobes annotation
    0ff7c3b33127 riscv: Use text_mutex instead of patch_lock
    087958a17658 riscv: cacheinfo: Implement cache_get_priv_group with a generic ops structure
    8fa3cdff05f0 riscv: Fix print_vm_layout build error if NOMMU
    8356c379cfba RISC-V: gp_in_global needs register keyword
    99395ee3f7b4 mm: ptdump: expand type of 'val' in note_page()
    c3f896dcf1e4 mm: switch the test_vmalloc module to use __vmalloc_node
    3f08a302f533 mm: remove CONFIG_HAVE_MEMBLOCK_NODE_MAP option
    9691a071aa26 mm: use free_area_init() instead of free_area_init_nodes()
    ae94da898133 hugetlbfs: add arch_hugetlb_valid_size
    359f25443a8d hugetlbfs: move hugepagesz= parsing to arch independent code
    38237830882b hugetlbfs: remove hugetlb_add_hstate() warning for existing hstate
    b0eae98c66fe mm/hugetlb: define a generic fallback for is_hugepage_only_range()
    5be993432821 mm/hugetlb: define a generic fallback for arch_clear_hugepage_flags()
    b422d28b2177 riscv: support DEBUG_WX
    885f7f8e3046 mm: rename flush_icache_user_range to flush_icache_user_page
    2062a4e8ae9f kallsyms/printk: add loglvl to print_ip_sym()
    0b3d43657489 riscv: add show_stack_loglvl()
    9cb8f069deee kernel: rename show_stack_loglvl() => show_stack()
    974b9b2c68f3 mm: consolidate pte_index() and pte_offset_*() definitions
    d8ed45c5dcd4 mmap locking API: use coccinelle to convert mmap_sem rwsem call sites
    89154dd5313f mmap locking API: convert mmap_sem call sites missed by coccinelle
    3e4e28c5a8f0 mmap locking API: convert mmap_sem API comments
    c1e8d7c6a7a6 mmap locking API: convert mmap_sem comments
    e8c7ef7d5819 RISC-V: Sort select statements alphanumerically
    5cf998ba8c7b RISC-V: self-contained IPI handling routine
    6b7ce8927b5a irqchip: RISC-V per-HART local interrupt controller driver
    033a65de7ece clocksource/drivers/timer-riscv: Use per-CPU timer interrupt
    24dc17005ca1 RISC-V: Remove do_IRQ() function
    e71ee06e3ca3 RISC-V: Force select RISCV_INTC for CONFIG_RISCV
    4e0f9e3a6104 RISC-V: Don't mark init section as non-executable
    05589dde649c riscv: fix build warning of missing prototypes
    ad5d1122b82f riscv: use vDSO common flow to reduce the latency of the time-related functions
    01f76386b0ac riscv: set the permission of vdso_data to read-only
    6c58f25e6938 riscv/atomic: Fix sign extension for RV64I
    fe557319aa06 maccess: rename probe_kernel_{read,write} to copy_{from,to}_kernel_nofault
    25f12ae45fc1 maccess: rename probe_kernel_address to get_kernel_nofault
    e0d17c842c0f RISC-V: Don't allow write+exec only page mapping request in mmap
    0e2c09011d4d RISC-V: Acquire mmap lock before invoking walk_page_range
    a0fc3b32893b riscv: Add -fPIC option to CFLAGS_vgettimeofday.o
    e93b327dbf3d riscv: Add extern declarations for vDSO time-related functions
    e05d57dcb8c7 riscv: Fixup __vdso_gettimeofday broke dynamic ftrace
    234e9d7a6200 riscv: Select ARCH_SUPPORTS_ATOMIC_RMW by default
    a2693fe254e7 RISC-V: Use a local variable instead of smp_processor_id()
    140c8180eb7c arch: remove HAVE_COPY_THREAD_TLS
    714acdbd1c94 arch: rename copy_thread_tls() back to copy_thread()
    526fbaed33e8 riscv: Register System RAM as iomem resources
    fc0c769ffd92 riscv: enable the Kconfig prompt of STRICT_KERNEL_RWX
    f7fc752815f8 riscv: Fix "no previous prototype" compile warning in kgdb.c file
    def0aa218e6d kgdb: Move the extern declaration kgdb_has_hit_break() to generic kgdb.h
    70ee5731a40b riscv: Avoid kgdb.h including gdb_xml.h to solve unused-const-variable warning
    0cac21b02ba5 riscv: use 16KB kernel stack on 64-bit
    38b7c2a3ffb1 RISC-V: Upgrade smp_mb__after_spinlock() to iorw,iorw
    4cb699d0447b riscv: kasan: use local_tlb_flush_all() to avoid uninitialized __sbi_rfence
    002dff36acfb asm/rwonce: Don't pull <asm/barrier.h> into 'asm-generic/rwonce.h'
    bfabff3cb0fe bpf, riscv: Modify JIT ctx to support compressed instructions
    804ec72c68c8 bpf, riscv: Add encodings for compressed instructions
    18a4d8c97b84 bpf, riscv: Use compressed instructions in the rv64 JIT
    d0d8aae64566 RISC-V: Set maximum number of mapped pages correctly
    4400231c8acc RISC-V: Do not rely on initrd_start/end computed during early dt parsing
    fa5a19835905 riscv: Parse all memory blocks to remove unusable memory
    2cb6cd495d17 riscv: switch to ->regset_get()
    7ca8cf5347f7 locking/atomic: Move ATOMIC_INIT into linux/types.h
    6184358da000 riscv: Fixup static_obj() fail
    c15959921f8d riscv: Fixup lockdep_assert_held with wrong param cpu_running
    3c4697982982 riscv: Enable LOCKDEP_SUPPORT & fixup TRACE_IRQFLAGS_SUPPORT
    298447928bb1 riscv: Support irq_work via self IPIs
    ed48b297fe21 riscv: Enable context tracking
    20d38f7c45a4 riscv: Allow building with kcov coverage
    cbb3d91d3bcf riscv: Add kmemleak support
    08b5985e7be5 riscv: Fix typo in asm/hwcap.h uapi header
    f2c9699f6555 riscv: Add STACKPROTECTOR supported
    8e0c02f27253 Replace HTTP links with HTTPS ones: RISC-V
    11a54f422b0d riscv: Support R_RISCV_ADD64 and R_RISCV_SUB64 relocs
    ebc00dde8a97 riscv: Add jump-label implementation
    3e7b669c6c53 riscv: Cleanup unnecessary define in asm-offset.c
    89b03cc1dff0 riscv: Use generic pgprot_* macros from <linux/pgtable.h>
    925ac7b6636b riscv: Select ARCH_HAS_DEBUG_VM_PGTABLE
    79b1feba5455 RISC-V: Setup exception vector early
    e3ef4d69456e riscv: Fix build warning for mm/init
    3843aca0521d riscv: fix build warning of mm/pageattr
    635093e306a3 RISC-V: Fix build warning for smpboot.c
    40284a072c42 riscv: disable stack-protector for vDSO
    4c5a116ada95 vdso/treewide: Add vdso_data pointer argument to __arch_get_hw_counter()
    1d9cfee7535c mm/sparsemem: enable vmem_altmap support in vmemmap_populate_basepages()
    c89ab04febf9 mm/sparse: cleanup the code surrounding memory_present()
    428e2976a5bf uaccess: remove segment_eq
    bce617edecad mm: do page fault accounting in handle_mm_fault
    5ac365a45890 mm/riscv: use general page fault accounting
    76d4467a97bd riscv: Setup exception vector for nommu platform
    cc7f3f72dc2a RISC-V: Add mechanism to provide custom IPI operations
    2bc3fc877aa9 RISC-V: Remove CLINT related code from timer and arch
    df561f6688fe treewide: Use fallthrough pseudo-keyword
    c604abc3f6e3 vmlinux.lds.h: Split ELF_DETAILS from STABS_DEBUG
    5e6e9852d6f7 uaccess: add infrastructure for kernel builds with set_fs()
    66d18dbda846 RISC-V: Take text_mutex in ftrace_init_nop()
    4363287178a8 riscv/mm: Simplify retry logic in do_page_fault()
    cac4d1dc85be riscv/mm/fault: Move no context handling to no_context()
    a51271d99cdd riscv/mm/fault: Move bad area handling to bad_area()
    ac416a724f11 riscv/mm/fault: Move vmalloc fault handling to vmalloc_fault()
    bda281d5bfb7 riscv/mm/fault: Simplify fault error handling
    6c11ffbfd849 riscv/mm/fault: Move fault error handling to mm_fault_error()
    7a75f3d47a0b riscv/mm/fault: Simplify mm_fault_error()
    6747430197ed riscv/mm/fault: Move FAULT_FLAG_WRITE handling in do_page_fault()
    afb8c6fee8ce riscv/mm/fault: Move access error check to function
    baf7cbd94b56 riscv: Set more data to cacheinfo
    b5fca7c55f9f riscv: Define AT_VECTOR_SIZE_ARCH for ARCH_DLINFO
    38f5bd23deae riscv: Add cache information in AUX vector
    2baa6d9506f2 riscv/mm/fault: Fix inline placement in vmalloc_fault() declaration
    a960c1323749 riscv/mm/fault: Set FAULT_FLAG_INSTRUCTION flag in do_page_fault()
    21190b74bcf3 riscv: Add sfence.vma after early page table changes
    f025d9d9934b riscv: Fix Kendryte K210 device tree
    d5be89a8d118 RISC-V: Resurrect the MMIO timer implementation for M-mode systems
    aa9887608e77 RISC-V: Check clint_time_val before use
    8f3a2b4a96dc RISC-V: Move DT mapping outof fixmap
    6262f661ff5d RISC-V: Add early ioremap support
    e8dcb61f2ade RISC-V: Implement late mapping page table allocation functions
    cb7d2dd5612a RISC-V: Add PE/COFF header for EFI stub
    d7071743db31 RISC-V: Add EFI stub support.
    b91540d52a08 RISC-V: Add EFI runtime services
    de22d2107ced RISC-V: Add page table dump support for uefi
    11129e8ed4d9 riscv: use memcpy based uaccess for nommu again
    f289a34811d8 riscv: refactor __get_user and __put_user
    d464118cdc41 riscv: implement __get_kernel_nofault and __put_user_nofault
    e8d444d3e98c riscv: remove address space overrides using set_fs()
    a78c6f5956a9 RISC-V: Make sure memblock reserves the memory containing DT
    84814460eef9 riscv: Fixup bootup failure with HARDENED_USERCOPY
    c8e470184a06 riscv: drop unneeded node initialization
    b10d6bca8720 arch, drivers: replace for_each_membock() with for_each_mem_range()
    cc6de1680538 memblock: use separate iterators for memory and reserved regions
    3c532798ec96 tracehook: clear TIF_NOTIFY_RESUME in tracehook_notify_resume()
    33def8498fdd treewide: Convert macro and uses of __section(foo) to __section("foo")
    0774a6ed294b timekeeping: default GENERIC_CLOCKEVENTS to enabled
    9d750c75bd2c risc-v: kernel: ftrace: Fixes improper SPDX comment style
    1bd14a66ee52 RISC-V: Remove any memblock representing unusable memory area
    79605f139426 riscv: Set text_offset correctly for M-Mode
    bcacf5f6f239 riscv: fix pfn_to_virt err in do_page_fault().
    635e3f3e47f2 riscv: uaccess: fix __put_kernel_nofault()
    1074dd44c5ba RISC-V: Use non-PGD mappings for early DTB access
    c2c81bb2f691 RISC-V: Fix the VDSO symbol generaton for binutils-2.35+
    76a4efa80900 perf/arch: Remove perf_sample_data::regs_user_copy
    00ab027a3b82 RISC-V: Add kernel image sections to the resource tree
    c18d7c17c005 riscv: Fix compressed Image formats build
    2c42bcbb95ec riscv: Clean up boot dir
    ae386e9d809c riscv: Ignore Image.* and loader.bin
    cef397038167 arch: pgtable: define MAX_POSSIBLE_PHYSMEM_BITS where needed
    673a11a7e415 riscv: Enable seccomp architecture tracking
    da815582cf45 riscv: Enable CMA support
    31564b8b6dba riscv: Add HAVE_IRQ_TIME_ACCOUNTING
    99c168fccbfe riscv: Cleanup stacktrace
    9dd97064e21f riscv: Make stack walk callback consistent with generic code
    58c644ba512c sched/idle: Fix arch_cpu_idle() vs tracing
    e553fdc8105a riscv: Explicitly specify the build id style in vDSO Makefile again
    6134b110f971 RISC-V: Add missing jump label initialization
    30aca1bacb39 RISC-V: fix barrier() use in <vdso/processor.h>
    5cb0080f1bfd riscv: Enable ARCH_STACKWALK
    62149f3564c5 RISC-V: Initialize SBI early
    b6566dc1acca RISC-V: Align the .init.text section
    19a00869028f RISC-V: Protect all kernel sections including init early
    b5b11a8ac4b5 RISC-V: Move dynamic relocation section under __init
    54649911f31b efi: stub: get rid of efi_get_max_fdt_addr()
    04091d6c0535 riscv: provide memmove implementation
    ccbbfd1cbf36 RISC-V: Define get_cycles64() regardless of M-mode
    772e1b7c4267 riscv: kernel: Drop unused clean rule
    3ae9c3cde51a riscv: Fixed kernel test robot warning
    78ed473c7619 RISC-V: Use the new generic devmem_is_allowed()
    7d95a88f9254 Add and use a generic version of devmem_is_allowed()
    24a31b81e383 riscv: add support for TIF_NOTIFY_SIGNAL
    5d6ad668f316 arch, mm: restore dependency of __kernel_map_pages() on DEBUG_PAGEALLOC
    32a0de886eb3 arch, mm: make kernel_page_present() always available
    28108fc8a056 clk: sifive: Use common name for prci configuration
    de043da0b9e7 RISC-V: Fix usage of memblock_enforce_memory_limit
    87dbc209ea04 local64.h: make <asm/local64.h> mandatory
    641e8cd2cbf0 riscv: Cleanup sbi function stubs when RISCV_SBI disabled
    21733cb51847 riscv/mm: Introduce a die_kernel_fault() helper function
    21855cac82d3 riscv/mm: Prevent kernel module to access user memory without uaccess routines
    cf7b2ae4d704 riscv: return -ENOSYS for syscall -1
    11f4c2e940e2 riscv: Fix kernel time_init()
    643437b996ba riscv: Enable interrupts during syscalls with M-Mode
    d5805af9fe9f riscv: Fix builtin DTB handling
    0ea02c737752 riscv: Drop a duplicated PAGE_KERNEL_EXEC
    7cd1af107a92 riscv: Trace irq on only interrupt is enabled
    80709af7325d riscv: cacheinfo: Fix using smp_processor_id() in preemptible
    0aa2ec8a475f riscv: Fixup CONFIG_GENERIC_TIME_VSYSCALL
    c25a053e1577 riscv: Fix KASAN memory mapping.
    0983834a8393 riscv: defconfig: enable gpio support for HiFive Unleashed
    08734e0581a5 riscv: Use vendor name for K210 SoC support
    93c2ce1ee77e riscv: Fix Canaan Kendryte K210 device tree
    5a2308da9f60 riscv: Add Canaan Kendryte K210 reset controller
    cbd34f4bb37d riscv: Separate memory init from paging init
    3e5b0bdb2a4d riscv: Add support pte_protnone and pmd_protnone if CONFIG_NUMA_BALANCING
    4f0e8eef772e riscv: Add numa support for riscv64 platform
    46ad48e8a28d riscv: Add machine name to kernel boot log and stack dump output
    dcdc7a53a890 RISC-V: Implement ptrace regs and stack API
    edfcf91fe4f8 riscv: Fixup compile error BUILD_BUG_ON failed
    67d945778099 riscv: Fixup wrong ftrace remove cflag
    5ad84adf5456 riscv: Fixup patch_text panic in ftrace
    afc76b8b8011 riscv: Using PATCHABLE_FUNCTION_ENTRY instead of MCOUNT
    c22b0bcb1dd0 riscv: Add kprobes supported
    829adda597fe riscv: Add KPROBES_ON_FTRACE supported
    74784081aac8 riscv: Add uprobes supported
    ee55ff803b38 riscv: Add support for function error injection
    fea2fed201ee riscv: Enable per-task stack canaries
    091b9450858e riscv: Add dump stack in show_regs
    da401e894532 riscv: Improve __show_regs
    f766f77a74f5 riscv/stacktrace: Fix stack output without ra on the stack top
    dec822771b01 riscv: stacktrace: Move register keyword to beginning of declaration
    797f0375dd2e RISC-V: Do not allocate memblock while iterating reserved memblocks
    abb8e86b2696 RISC-V: Set current memblock limit
    e557793799c5 RISC-V: Fix maximum allowed phsyical memory for RV32
    336e8eb2a3cf riscv: Fixup pfn_valid error with wrong max_mapnr
    2ab543823322 riscv: virt_addr_valid must check the address belongs to linear mapping
    f105ea9890f4 RISC-V: Fix .init section permission update
    eefb5f3ab2e8 riscv: Align on L1_CACHE_BYTES when STRICT_KERNEL_RWX
    de5f4b8f634b RISC-V: Define MAXPHYSMEM_1GB only for RV32
    f105aa940e78 riscv: add BUILTIN_DTB support for MMU-enabled targets
    aec33b54af55 riscv: Covert to reserve_initrd_mem()
    e178d670f251 riscv/kasan: add KASAN_VMALLOC support
    5da9cbd2b200 arch/riscv:fix typo in a comment in arch/riscv/kernel/image-vars.h
    d4c34d09ab03 pinctrl: Add RISC-V Canaan Kendryte K210 FPIOA driver
    5dd671333171 RISC-V: probes: Treat the instruction stream as host-endian
    3449831d92fe RISC-V: remove unneeded semicolon
    65d4b9c53017 RISC-V: Implement ASID allocator
    4727dc20e042 arch: setup PF_IO_WORKER threads like PF_KTHREAD
    4bb875632ad0 RISC-V: Add a non-void return for sbi v02 functions
    67d96729a9e7 riscv: Update Canaan Kendryte K210 device tree
    97c279bcf813 riscv: Add SiPeed MAIX BiT board device tree
    a40f920964c4 riscv: Add SiPeed MAIX DOCK board device tree
    8194f08bda18 riscv: Add SiPeed MAIX GO board device tree
    8f5b0e79f3e5 riscv: Add SiPeed MAIXDUINO board device tree
    62363a8e2f56 riscv: Add Kendryte KD233 board device tree
    aec3a94d951f riscv: Update Canaan Kendryte K210 defconfig
    7e09fd3994c5 riscv: Add Canaan Kendryte K210 SD card defconfig
    cc937cad14fb riscv: Remove unnecessary declaration
    f3d60f2a25e4 riscv: Disable KSAN_SANITIZE for vDSO
    0f02de4481da riscv: Get rid of MAX_EARLY_MAPPING_SIZE
    7899ed260c34 riscv: Improve kasan definitions
    9484e2aef45b riscv: Use KASAN_SHADOW_INIT define for kasan memory initialization
    d127c19c7bea riscv: Improve kasan population function
    d7fbcf40df86 riscv: Improve kasan population by using hugepages when possible
    f01e631cccab RISC-V: Make NUMA depend on SMP
    b122c7a32593 RISC-V: Enable CPU Hotplug in defconfigs
    dd2d082b5760 riscv: Cleanup setup_bootmem()
    f6e5aedf470b riscv: Add support for memtest
    9530141455c9 riscv: Add ARCH_HAS_FORTIFY_SOURCE
    6dd4879f59b0 RISC-V: correct enum sbi_ext_rfence_fid
    030f1dfa8550 riscv: traps: Fix no prototype warnings
    004570c3796b riscv: irq: Fix no prototype warning
    56a6c37f6e39 riscv: sbi: Fix comment of __sbi_set_timer_v01
    e06f4ce1d4c6 riscv: ptrace: Fix no prototype warnings
    db2a8f9256e9 riscv: time: Fix no prototype for time_init
    a6a58ecf98c3 riscv: syscall_table: Reduce W=1 compilation warnings noise
    86b276c1dded riscv: process: Fix no prototype for show_regs
    288f6775a089 riscv: ftrace: Use ftrace_get_regs helper
    0d7588ab9ef9 riscv: process: Fix no prototype for arch_dup_task_struct
    6e9070dc2e84 riscv: fix bugon.cocci warnings
    2f100585d045 riscv: Enable generic clockevent broadcast
    bab1770a2ce0 ftrace: Fix spelling mistake "disabed" -> "disabled"
    fa59030bf855 riscv: Fix compilation error with Canaan SoC
    ce989f1472ae RISC-V: Fix out-of-bounds accesses in init_resources()
    f3773dd031de riscv: Ensure page table writes are flushed when initializing KASAN vmalloc
    78947bdfd752 RISC-V: kasan: Declare kasan_shallow_populate() static
    a5406a7ff56e riscv: Correct SPARSEMEM configuration
    a0d8d552783b whack-a-mole: kill strlen_user() (again)
    f35bb4b8d10a RISC-V: Don't print SBI version for all detected extensions
    2da073c19641 riscv: Cleanup KASAN_VMALLOC support
    23c1075ae83a riscv: Drop const annotation for sp
    285a76bb2cf5 riscv: evaluate put_user() arg before enabling user access
    ac8d0b901f00 riscv,entry: fix misaligned base for excp_vect_table
    9d8c7d92015e riscv: remove unneeded semicolon
    1adbc2941eee riscv: Make NUMA depend on MMU
    199fc6b8dee7 riscv: Fix spelling mistake "SPARSEMEM" to "SPARSMEM"
    2349a3b26e29 riscv: add do_page_fault and do_trap_break into the kprobes blacklist
    e31be8d343e6 riscv: kprobes/ftrace: Add recursion protection to the ftrace callback
    7ae11635ec90 riscv: keep interrupts disabled for BREAKPOINT exception
    09accc3a05f7 riscv: Disable data start offset in flat binaries
    183787c6fcc2 riscv: Add 3 SBI wrapper functions to get cpu manufacturer information
    6f4eea90465a riscv: Introduce alternative mechanism to apply errata solution
    1a0e5dbd3723 riscv: sifive: Add SiFive alternative ports
    800149a77c2c riscv: sifive: Apply errata "cip-453" patch
    bff3ff525460 riscv: sifive: Apply errata "cip-1200" patch
    7f3d349065d0 riscv: Use $(LD) instead of $(CC) to link vDSO
    7ce047715030 riscv: Workaround mcount name prior to clang-13
    adebc8817b5c riscv: Select HAVE_DYNAMIC_FTRACE when -fpatchable-function-entry is available
    2bfc6cd81bd1 riscv: Move kernel mapping outside of linear mapping
    0df68ce4c26a riscv: Prepare ptdump for vm layout dynamic addresses
    1987501b1130 riscv: add __init section marker to some functions
    de31ea4a1181 riscv: Mark some global variables __ro_after_init
    e6a302248cec riscv: Constify sys_call_table
    300f62c37d46 riscv: Constify sbi_ipi_ops
    cdd1b2bd358f riscv: kprobes: Implement alloc_insn_page()
    1d27d854425f riscv: bpf: Move bpf_jit_alloc_exec() and bpf_jit_free_exec() to core
    fc8504765ec5 riscv: bpf: Avoid breaking W^X
    5387054b986e riscv: module: Create module allocations without exec permissions
    a9451b8e1971 riscv: Set ARCH_HAS_STRICT_MODULE_RWX if MMU
    b1ebaa0e1318 riscv/kprobe: fix kernel panic when invoking sys_read traced by kprobe
    e75e6bf47a47 riscv/mm: Use BUG_ON instead of if condition followed by BUG.
    772d7891e8b3 riscv: vdso: fix and clean-up Makefile
    fba8a8674f68 RISC-V: Add kexec support
    ffe0e5261268 RISC-V: Improve init_resources()
    e53d28180d4d RISC-V: Add kdump support
    5640975003d0 RISC-V: Add crash kernel support
    44c922572952 RISC-V: enable XIP
    99b3e3d41a03 RISC-V: Add Microchip PolarFire SoC kconfig option
    0fa6107eca41 RISC-V: Initial DTS for Microchip ICICLE board
    2951162094e6 RISC-V: Enable Microchip PolarFire ICICLE SoC
    1f9d03c5e999 mm: move mem_init_print_info() into mm_init()
    533b4f3a789d RISC-V: Fix error code returned by riscv_hartid_to_cpuid()
    883fcb8ecaaf riscv: Fix 32b kernel build with CONFIG_DEBUG_VIRTUAL=y
    28252e08649f riscv: Remove 32b kernel mapping from page table dump
    f54c7b5898d3 RISC-V: Always define XIP_FIXUP
    855f9a8e87fe mm: generalize SYS_SUPPORTS_HUGETLBFS (rename as ARCH_SUPPORTS_HUGETLBFS)
    8db6f937f4e7 riscv: Only extend kernel reservation if mapped read-only
    0e0d4992517f riscv: enable SiFive errata CIP-453 and CIP-1200 Kconfig only if CONFIG_64BIT=y
    8d91b0973358 riscv: Consistify protect_kernel_linear_mapping_text_rodata() use
    beaf5ae15a13 riscv: remove unused handle_exception symbol
    f1a0a376ca0c sched/core: Initialize the idle task with preemption disabled
    f5397c3ee0a3 riscv: mm: add _PAGE_LEAF macro
    141682f5b9d6 riscv: mm: make pmd_bad() check leaf condition
    c3b2d67046d2 riscv: mm: add param stride for __sbi_tlb_flush_range
    e88b333142e4 riscv: mm: add THP support on 64-bit
    eac2f3059e02 riscv: stacktrace: fix the riscv stacktrace when CONFIG_FRAME_POINTER enabled
    97a031082320 riscv: Select ARCH_USE_MEMTEST
    02ccdeed1817 riscv: kprobes: Fix build error when MMU=n
    bab0d47c0ebb riscv: kexec: Fix W=1 build warnings
    3332f4190674 riscv: mremap speedup - enable HAVE_MOVE_PUD and HAVE_MOVE_PMD
    8f3e136ff378 riscv: mm: Remove setup_zero_page()
    db756746807b riscv: enable generic PCI resource mapping
    f842f5ff6aaf riscv: Move setup_bootmem into paging_init
    50bae95e17c6 riscv: mm: Drop redundant _sdata and _edata declaration
    8237c5243a61 riscv: Optimize switch_mm by passing "cpu" to flush_icache_deferred()
    37a7a2a10ec5 riscv: Turn has_fpu into a static key if FPU=y
    9efbb3558310 locking/atomic: riscv: move to ARCH_ATOMIC
    3c1885187bc1 locking/atomic: delete !ARCH_ATOMIC remnants
    8c9f4940c27d riscv: kprobes: Remove redundant kprobe_step_ctx
    ec3a5cb61146 riscv: Use -mno-relax when using lld linker
    3df952ae2ac8 riscv: Add __init section marker to some functions again
    010623568222 riscv: mm: init: Consolidate vars, functions
    7fa865f5640a riscv: TRANSPARENT_HUGEPAGE: depends on MMU
    cba43c31f14b riscv: Use global mappings for kernel pages
    ec6aba3d2be1 kprobes: Remove kprobe::fault_handler
    8a4102a0cf07 riscv: mm: Fix W+X mappings at boot
    b75db25c416b riscv: skip errata_cip_453.o if CONFIG_ERRATA_SIFIVE_CIP_453 is disabled
    da2d48808fbd RISC-V: Fix memblock_free() usages in init_resources()
    2e38eb04c95e kprobes: Do not increment probe miss count in the fault handler
    ff76e3d7c3c9 riscv: fix build error when CONFIG_SMP is disabled
    5def4429aefe riscv: mm: Use better bitmap_zalloc()
    efcec32fe84a riscv: Cleanup unused functions
    ae3d69bcc455 riscv: fix typo in init.c
    5e63215c2f64 riscv: xip: support runtime trap patching
    42e0e0b453bc riscv: code patching only works on !XIP_KERNEL
    858cf860494f riscv: alternative: fix typo in macro name
    ce3aca0465e3 riscv: Only initialize swiotlb when necessary
    9b79878ced8f riscv: Remove CONFIG_PHYS_RAM_BASE_FIXED
    7094e6acaf7a riscv: Simplify xip and !xip kernel address conversion macros
    0ddd7eaffa64 riscv: Fix BUILTIN_DTB for sifive and microchip soc
    5d2388dbf84a riscv32: Use medany C model for modules
    01f5315dd732 riscv: sifive: fix Kconfig errata warning
    c9811e379b21 riscv: Add mem kernel parameter support
    b03fbd4ff24c sched: Introduce task_is_running()
    314b781706e3 riscv: kasan: Fix MODULES_VADDR evaluation due to local variables' name
    3a02764c372c riscv: Ensure BPF_JIT_REGION_START aligned with PMD size
    a9ee6cf5c60e mm: replace CONFIG_NEED_MULTIPLE_NODES with CONFIG_NUMA
    63703f37aa09 mm: generalize ZONE_[DMA|DMA32]
    70c7605c08c5 riscv: pass the mm_struct to __sbi_tlb_flush_range
    3f1e782998cd riscv: add ASID-based tlbflushing methods
    47513f243b45 riscv: Enable KFENCE for riscv64
    c10bc260e7c0 riscv: Introduce set_kernel_memory helper
    e5c35fa04019 riscv: Map the kernel with correct permissions the first time
    fac7757e1fb0 mm: define default value for FIRST_USER_ADDRESS
    1c2f7d14d84f mm/thp: define default pmd_pgtable()
    658e2c5125bb riscv: Introduce structure that group all variables regarding kernel mapping
    9eb4fcff2207 riscv: mm: fix build errors caused by mk_pmd()
    70eee556b678 riscv: ptrace: add argn syntax
    31da94c25aea riscv: add VMAP_STACK overflow detection
    ca6eaaa210de riscv: __asm_copy_to-from_user: Optimize unaligned memory access and pipeline stall
    7761e36bc722 riscv: Fix PTDUMP output now BPF region moved back to module region
    10cc32788391 riscv/Kconfig: make direct map manipulation options depend on MMU
    7bb7f2ac24a0 arch, mm: wire up memfd_secret system call where relevant
    723a42f4f6b2 riscv: convert to setup_initial_init_mm()
    9cf6fa245844 mm: rename pud_page_vaddr to pud_pgtable and make it return pmd_t *
    8633ef82f101 drivers/firmware: consolidate EFI framebuffer setup for all arches
    d0e4dae74470 riscv: Fix 32-bit RISC-V boot failure
    c79e89ecaa24 RISC-V: load initrd wherever it fits into memory
    b7d2be48cc08 riscv: kprobes: implement the auipc instruction
    67979e927dd0 riscv: kprobes: implement the branch instructions
    c09dc9e1cd3c riscv: Fix memory_limit for 64-bit kernel
    c99127c45248 riscv: Make sure the linear mapping does not use the kernel mapping
    db6b84a368b4 riscv: Make sure the kernel mapping does not overlap with IS_ERR_VALUE
    76f5dfacfb42 riscv: stacktrace: pin the task's stack in get_wchan
    6010d300f9f7 riscv: __asm_copy_to-from_user: Fix: overrun copy
    22b5f16ffeff riscv: __asm_copy_to-from_user: Fix: fail on RV32
    d4b3e0105e3c riscv: __asm_copy_to-from_user: Remove unnecessary size check
    ea196c548c0a riscv: __asm_copy_to-from_user: Fix: Typos in comments
    78d9d8005e45 riscv: stacktrace: Fix NULL pointer dereference
    f5e81d111750 bpf: Introduce BPF nospec instruction for mitigating Spectre v4
    13e47bebbe83 riscv: Implement thread_struct whitelist for hardened usercopy
    a18b14d88866 riscv: Disable STACKPROTECTOR_PER_TASK if GCC_PLUGIN_RANDSTRUCT is enabled
    8165c6ae8e3a riscv: Allow forced irq threading
    bcf11b5e99b2 riscv: Enable idle generic idle loop
    ecd4916c7261 riscv: Enable GENERIC_IRQ_SHOW_LEVEL
    6d7f91d914bc riscv: Get rid of CONFIG_PHYS_RAM_BASE in kernel physical address conversion
    59a27e112213 riscv: Optimize kernel virtual address conversion macro
    0aba691a7443 riscv: Introduce va_kernel_pa_offset for 32-bit kernel
    526f83df1d83 riscv: Get rid of map_size parameter to create_kernel_page_table
    6f3e5fd241c3 riscv: Use __maybe_unused instead of #ifdefs around variable declarations
    977765ce319b riscv: Simplify BUILTIN_DTB device tree mapping handling
    fe45ffa4c505 riscv: Move early fdt mapping creation in its own function
    030d6dbf0c2e riscv: kexec: do not add '-mno-relax' flag if compiler doesn't support it
    fdf3a7a1e0a6 riscv: Fix comment regarding kernel mapping overlapping with IS_ERR_VALUE
    fb31f0a49933 riscv: fix the global name pfn_base confliction error
    8ba1a8b77ba1 riscv: Support allocating gigantic hugepages using CMA
    4aae683f1327 tracing: Refactor TRACE_IRQFLAGS_SUPPORT in Kconfig
    aa3e1ba32e55 riscv: Fix a number of free'd resources in init_resources()
    c4b2b7d150d2 block: remove CONFIG_DEBUG_BLOCK_EXT_DEVT
    2931ea847dcc riscv: Remove non-standard linux,elfcorehdr handling
    379eb01c2179 riscv: Ensure the value of FP registers in the core dump file is up to date
    7f85b04b08ca riscv: Keep the riscv Kconfig selects sorted
    8341dcfbd8dd riscv: Enable Undefined Behavior Sanitizer UBSAN
    fde9c59aebaf riscv: explicitly use symbol offsets for VDSO
    803930ee35fa riscv: use strscpy to replace strlcpy
    a290f510a178 RISC-V: Fix VDSO build for !MMU
    c24a19674258 riscv: add support for hugepage migration
    4b92d4add5f6 drivers: base: cacheinfo: Get rid of DEFINE_SMP_CALL_CACHE_FUNCTION()
    a7259df76702 memblock: make memblock_find_in_range method private
    8350229ffceb riscv: only select GENERIC_IOREMAP if MMU support is enabled
    8b097881b54c trap: cleanup trap_init()
    3a87ff891290 riscv: defconfig: enable BLK_DEV_NVME
    efe1e08bca9a riscv: defconfig: enable NLS_CODEPAGE_437, NLS_ISO8859_1
    d5935537c825 riscv: Improve stack randomisation on RV64
    399c1ec8467c riscv: move the (z)install rules to arch/riscv/Makefile
    54fed35fd393 riscv: Enable BUILDTIME_TABLE_SORT
    6f55ab36bef5 riscv: Move EXCEPTION_TABLE to RO_DATA segment
    d20758951f8f riscv: remove Kconfig check for GCC version for ARCH_RV64I
    7962c2eddbfe arch: remove unused function syscall_set_arguments()
    8aa0fb0fbb82 riscv: rely on core code to keep thread_info::cpu updated
    9c89bb8e3272 kprobes: treewide: Cleanup the error messages for kprobes
    96fed8ac2bb6 kprobes: treewide: Remove trampoline_address from kretprobe_trampoline_handler()
    adf8a61a940c kprobes: treewide: Make it harder to refer kretprobe_trampoline directly
    bb4a23c994ae riscv/vdso: Refactor asm/vdso.h
    78a743cd82a3 riscv/vdso: Move vdso data page up front
    8bb0ab3ae7a4 riscv/vdso: make arch_setup_additional_pages wait for mmap_sem for write killable
    3f2401f47d29 RISC-V: Add hypervisor extension related CSR defines
    99cdc6c18c2d RISC-V: Add initial skeletal KVM support
    a33c72faf2d7 RISC-V: KVM: Implement VCPU create, init and destroy functions
    cce69aff689e RISC-V: KVM: Implement VCPU interrupts and requests handling
    92ad82002c39 RISC-V: KVM: Implement KVM_GET_ONE_REG/KVM_SET_ONE_REG ioctls
    34bde9d8b9e6 RISC-V: KVM: Implement VCPU world-switch
    9f7013265112 RISC-V: KVM: Handle MMIO exits for VCPU
    5a5d79acd7da RISC-V: KVM: Handle WFI exits for VCPU
    fd7bb4a251df RISC-V: KVM: Implement VMID allocator
    9d05c1fee837 RISC-V: KVM: Implement stage2 page table programming
    9955371cc014 RISC-V: KVM: Implement MMU notifiers
    3a9f66cb25e1 RISC-V: KVM: Add timer functionality
    5de52d4a23ad RISC-V: KVM: FP lazy save/restore
    4d9c5c072f03 RISC-V: KVM: Implement ONE REG interface for FP registers
    dea8ee31a039 RISC-V: KVM: Add SBI v0.1 support
    dffe11e280a4 riscv/vdso: Add support for time namespaces
    f2928e224d85 riscv: set default pm_power_off to NULL
    21ccdccd21e4 riscv: mm: don't advertise 1 num_asid for 0 asid bits
    59a4e0d5511b RISC-V: Include clone3() on rv32
    5d4595db0e1c riscv: add rv32 and rv64 randconfig build targets
    bb8958d5dc79 riscv: Flush current cpu icache before other cpus
    6644c654ea70 ftrace: Cleanup ftrace_dyn_arch_init()
    42a20f86dc19 sched: Add wrapper for get_wchan() to keep task blocked
    bd2259ee458e riscv: Use of_get_cpu_hwid()
    8f04db78e4e3 bpf: Define bpf_jit_alloc_exec_limit for riscv JIT
    2fe35f8ee726 irq: add a (temporary) CONFIG_HANDLE_DOMAIN_IRQ_IRQENTRY
    7ecbc648102f irq: riscv: perform irqentry in entry code
    0953fb263714 irq: remove handle_domain_{irq,nmi}()
    f9ace4ede49b riscv: remove .text section size limitation for XIP
    683b33f7e7ec riscv/vdso: Drop unneeded part due to merge issue
    ce5e48036c9e ftrace: disable preemption when recursion locked
    64a19591a293 riscv: fix misalgned trap vector base address
    ffa7a9141bb7 riscv: defconfig: enable DRM_NOUVEAU
    252c765bd764 riscv, bpf: Add BPF exception tables
    27de809a3d83 riscv, bpf: Fix potential NULL dereference
    cf11d01135ea riscv: Do not re-populate shadow memory with kasan_populate_early_shadow
    54c5639d8f50 riscv: Fix asan-stack clang build
    0a86512dc113 RISC-V: KVM: Factor-out FP virtualization into separate sources
    7c8de080d476 RISC-V: KVM: Fix GPA passed to __kvm_riscv_hfence_gvma_xyz() functions
    7b161d9cab5d RISC-V: KVM: remove unneeded semicolon
    bbd5ba8db766 RISC-V: KVM: fix boolreturn.cocci warnings
    4b54214f39ff riscv, bpf: Increase the maximum number of iterations
    f47d4ffe3a84 riscv, bpf: Fix RV32 broken build, and silence RV64 warning
    3ecc68349bba memblock: rename memblock_free to memblock_phys_free
    4421cca0a3e4 memblock: use memblock_free for freeing virtual pointers
    0e2e64192100 riscv: kvm: fix non-kernel-doc comment block
    37fd3ce1e64a KVM: RISC-V: Cap KVM_CAP_NR_VCPUS by KVM_CAP_MAX_VCPUS
    12c484c12b19 RISC-V: Enable KVM in RV64 and RV32 defconfigs as a module
    5a19c7e06236 riscv: fix building external modules
    756e1fc16505 KVM: RISC-V: Unmap stage2 mapping when deleting/moving a memslot
    74c2e97b0184 RISC-V: KVM: Fix incorrect KVM_MAX_VCPUS value
    4bc5e64e6cf3 efi: Move efifb_setup_from_dmi() prototype from arch headers

当然，内容还是太多，1000 多条记录，所以还是需要分解，我们目前基于上述的 Commits 以及收集的相关资料，整理出了一份[任务清单](https://gitee.com/tinylab/riscv-linux/blob/master/plan/README.md)。

任务清单中大体做了模块划分，但是还比较粗糙，建议大家在分析的过程中直接提交 PR 进行修订。

大家可结合自己的兴趣认领感兴趣的模块，比如说 Ftrace，认领后可以重点分析相关代码，这样的话，可以用关键字 ftrace 过滤出这部分的 commits：

    $ git rev-list --oneline 76d2a0493a17^..v5.16 --reverse arch/riscv | grep -i ftrace
    10626c32e382 riscv/ftrace: Add basic support
    a1d2a6b4cee8 riscv/ftrace: Add RECORD_MCOUNT support
    c15ac4fd60d5 riscv/ftrace: Add dynamic function tracer support
    bc1a4c3a8425 riscv/ftrace: Add dynamic function graph tracer support
    71e736a7d655 riscv/ftrace: Add ARCH_SUPPORTS_FTRACE_OPS support
    aea4c671fb98 riscv/ftrace: Add DYNAMIC_FTRACE_WITH_REGS support
    b785ec129bd9 riscv/ftrace: Add HAVE_FUNCTION_GRAPH_RET_ADDR_PTR support
    1dd985229d5f riscv/ftrace: Export _mcount when DYNAMIC_FTRACE isn't set
    57a489786de9 RISC-V: include linux/ftrace.h in asm-prototypes.h
    397182e0db56 riscv: remove unused variable in ftrace
    1d8f65798240 riscv: ftrace: correct the condition logic in function graph tracer
    e05d57dcb8c7 riscv: Fixup __vdso_gettimeofday broke dynamic ftrace
    66d18dbda846 RISC-V: Take text_mutex in ftrace_init_nop()
    9d750c75bd2c risc-v: kernel: ftrace: Fixes improper SPDX comment style
    67d945778099 riscv: Fixup wrong ftrace remove cflag
    5ad84adf5456 riscv: Fixup patch_text panic in ftrace
    829adda597fe riscv: Add KPROBES_ON_FTRACE supported
    288f6775a089 riscv: ftrace: Use ftrace_get_regs helper
    bab1770a2ce0 ftrace: Fix spelling mistake "disabed" -> "disabled"
    e31be8d343e6 riscv: kprobes/ftrace: Add recursion protection to the ftrace callback
    adebc8817b5c riscv: Select HAVE_DYNAMIC_FTRACE when -fpatchable-function-entry is available
    6644c654ea70 ftrace: Cleanup ftrace_dyn_arch_init()
    ce5e48036c9e ftrace: disable preemption when recursion locked

根据这些 Commits，又可以分析各个子功能又是如何一步一步添加的，对于一些简单的 fixups 和 Comments 修订，完全可以直接纳入到某个子功能当中去，无需单独输出分析报告。

其他的特性功能也可以类似分析，比如 KVM，eBPF, kprobes 等等。

## 阅读具体代码

接下来简单介绍如何结合 vim 与 cscope 查阅代码。

首先，创建代码索引（如果系统内存不够，可能会被Kill掉从而无法创建完整索引），方便阅读时跳转：

    $ cd /labs/linux-lab
    $ make kernel cscope

创建后，进入 Linux 构建目录：

    $ cd build/riscv64/build-v5.16-virt/
    $ vim
    :cs add cscope.out
    :cs find g setup_arch

以上即可找到 `setup_arch` 的定义，如果手动不方便，可以参考 [把 VIM 打造成源代码编辑器](https://tinylab.org/make-vim-source-code-editor/) 配置 cscope 的快件键，加速代码阅读体验。

在阅读源代码的过程中，建议参考 `refs/README.md` 中列出的官方 Spec 等资料进行更准确地解释。

## 代码修改实验

在分析的过程中，如果想调整代码以便观察运行效果或者发现了 Bug 想验证修订与否，可以直接用 Linux Lab 或 Linux Lab Disk 运行：

    $ make boot

## 输出分析成果

在分析完某个模块以后，可以撰写成类似本文的原始风格 markdown 格式（请注意段落层次、代码风格等，不要用复杂的 markdown 风格），并提交 PR 到 `articles/` 目录下。

如果某个模块还是比较大，可以细分成多个子模块进行分析和输出。在完成度比较高的情况下，也可以制作成幻灯片进行视频讲解。

如涉及网络已存在的资料和图片引用等，请直接用“链接”方式，如果是自己设计、绘制或者制作的图片，可以上传到 `articles/images/your-article-short-title` 目录下。

## 小结

本文简单介绍了如何分析 Linux 内核的 RISC-V 架构支持。

接下来，非常期待大家对各个模块的分析成果。

[1]: https://tinylab.org
