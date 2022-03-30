---
layout: post
author: 'Wu Zhangjin'
title: "RISC-V Linux 内核兴趣小组招募爱好者-ing"
draft: false
license: "cc-by-nc-nd-4.0"
album: 'RISC-V Linux'
permalink: /riscv-linux-analyse/
description: "社区近日成立了 RISC-V Linux 内核兴趣小组，短期目标是剖析 Linux 内核的 RISC-V 架构支持。"
category:
  - 开源项目
  - Risc-V
tags:
  - Linux
  - RISC-V
---

> By Falcon of [TinyLab.org][1]
> Mar 09, 2022

## 背景简介

鉴于 RISC-V 芯片相关技术的蓬勃发展，[泰晓科技 Linux 技术社区][1] 计划组建一个开放的 RISC-V Linux 内核兴趣小组，致力于 RISC-V Linux 内核以及周边技术与社区的跟踪、调研、剖析、贡献和分享。

泰晓科技这几年陆陆续续都有一些跟进，但是不够持续和系统，咱们前期的一些分享有：

* 技术状态整理：[RISC-V 发展迅猛，正是关注好时机](https://tinylab.org/riscv-overview/)
* 内核实验环境：[Linux Lab v0.3 正式支持 riscv32/virt 和 riscv64/virt 两块虚拟开发板](https://tinylab.org/linux-lab-v0.3/)
* 课程实验支持：[通过 Linux Lab Disk 开展最新的 RVOS 操作系统课程实验](https://tinylab.org/rvos-on-linux-lab/)

## RISC-V 发展现状

当前整个 RISC-V 国内外的进展非常快，国产 RISC-V 芯片、开发板、工具链、Linux 内核、周边软件以及各个 Linux 发行版的支持都在顺利推进，但是跟其他成熟的处理器架构相比，目前还只能算是一个起步不久的状态，所以恰好有很多坑值得去填。另外，由于足够开放，RISC-V 目前吸引了来自行业的很多研究机构、企业、开发人员的关注和投入，前景也因此很看好。

国产 RISC-V 芯片与开发板方面，前有 k210，D1，新近有香山等等，工具链和 Linux 发行版方面，软件所 PLCT 相关团队正在热火朝天地持续参与和贡献，Linux 内核方面，D1 支持团队目前也做了非常多的工作，泰晓科技技术社区在 RISC-V 操作系统实验与开发环境方面则做了不少的工作。

## RISC-V Linux 最新进展

接下来我们打算继续发挥泰晓科技 Linux 技术社区的优势，重点聚焦 Linux 内核以及周边的技术对 RISC-V 架构的支持。

从邮件列表来看，目前 Linux for RISC-V 各项开发工作非常活跃，例如：

* Add Sstc extension support (KVM related timer support)
* RISC-V IPI Improvements (Multi-core support)
* Fixes KASAN and other along the way (KASAN support)
* RISCV_EFI_BOOT_PROTOCOL support in linux (UEFI boot support)
* Risc-V Svinval support (for the Svinval v1.0 defined in Privileged specification)
* riscv: compat: Add COMPAT mode support for rv64
* Provide a fraemework for RISC-V ISA extensions
* Improve RISC-V Perf support using SBI PMU and sscofpmf extension (Perf support)
* riscv: compat: vdso: Add rv32 VDSO base code implementation (VDSO support)
* RISC-V CPU Idle Support (cpuidle support)
* KVM RISC-V SBI v0.3 support (KVM & SBI)
* KVM/riscv fixes for 5.17, take #1 (KVM)
* Add Sv57 page table support (MM Paging, try from 5-level page table to 3-level page table)
* Introduce sv48 support without relocatable kernel
* unified way to use static key and optimize pgtable_l4_enabled
* riscv: support for Svpbmt and D1 memory types ("Supervisor-mode: page-based memory types" for things like non-cacheable pages or I/O memory pages.)
* riscv: fix oops caused by irqsoff latency tracer (Ftrace irqsoff tracer)
* riscv: cpu-hotplug: clear cpu from numa map when teardown (Multi-core support: cpu hotplug)
* Improve KVM's interaction with CPU hotplug (KVM and CPU hotplug)
* riscv: add irq stack support (kernel stack max size)
* Sparse HART id support (hartid (core id) v.s. NR_CPUS)
* RISC-V: Prevent sbi_ecall() from being inlined (standard deviate)
* Public review of Supervisor Binary Interface (SBI) Specification (what SBI is and v1.0-rc2 is in review)
* riscv: switch to relative extable and other improvements (extable)
* riscv: Fixes for XIP support (XIP)
* riscv: bpf: Fix eBPF's exception tables (eBPF)
* RISC-V: Use SBI SRST extension when available (SBI)
* Public review for RISC-V psABI v1.0-rc1 (psABI)
* riscv: Add vector ISA support (vector ISA)

以上简单遍历了一下 2022 年年初 3 个月的 RISC-V Linux 内核邮件活动，内容涉及到了方方面面，从 Spec, 多核, KVM, XIP, eBPF, Perf, vector ISA, ISA extensions, Paging, KASAN, VDSO, UEFI 等，其中 Spec 方面，可以看到 psABI 和 SBI 刚好都在 v1.0-rc1 的阶段，意味者 v1.0 正式版本快了。

接下来的三个月打算优先聚焦 Linux 内核的 RISC-V 核心架构支持，From Scratch 这种，也就是从 Linux v4.15 开始，初略看了一下，初始支持（含 merge）记录一共 1000 多条：

    $ git rev-list --oneline 76d2a0493a17d4c8ecc781366850c3c4f8e1a446..v5.16 --reverse arch/riscv | wc -l
    1400

数据不算太多，去掉 merge 记录：

    $ git rev-list --oneline 76d2a0493a17d4c8ecc781366850c3c4f8e1a446..v5.16 --reverse arch/riscv | grep -v " Merge " | wc -l
    1178

去掉一些驱动、构建等相关的非核心代码：

    $ git rev-list --oneline 76d2a0493a17d4c8ecc781366850c3c4f8e1a446..v5.16 --reverse arch/riscv | egrep -v " Merge | Backmerge | dts| kbuild| asm-generic| firmware| include| Documentation| Revert| drivers | config | Rename" | wc -l
    1058

这里直接贴出筛选出来最初的支持部分：

    $ git rev-list --oneline 76d2a0493a17d4c8ecc781366850c3c4f8e1a446..v5.16 --reverse arch/riscv | egrep -v " Merge | Backmerge | dts| kbuild| asm-generic| firmware| include| Documentation| Revert| drivers | config | Rename"
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
    ...

## 大体计划

* 首先结合开放文档与课程学习 RISC-V ISA, SBI, psABI 等 Spec，并输出学习记录
* 结合 Spec 从引导、中断、时钟、内存、调度、多核、系统调用等逐次展开 RISC-V 架构相关 Linux 内核源码的分析与解读，输出分析报告或者视频讲解，对发现的问题进行修复与改进并提交 PR 给官方社区
* 然后延申到 Ftrace、Perf、eBPF、KVM、Real Time 等内核关键特性，逐个分析与解读，同样可以输出报告或提交 PR

目前已经组建了 3 人的小组，由于内容较多，而且大家平时工作也比较忙，进度方面可能会比较缓慢，所以计划召集更多爱好者，尤其是正在从事相关工作（例如，正在从事 RISCV 芯片、工具链、OS、驱动、发行版、应用等开发工作）的同学参与进来，可以选择自己感兴趣的子系统或者特性进行剖析，然后以文字或者视频（包括直播）的方式分享给整个开源社区。当然，也欢迎大家对 RISC-V 目前缺失的一些特性做开发并提交进官方。

## 协作仓库

已创建本次活动的协作专用仓库：[RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux)

建议先参考 refs/README.md 了解一下相关背景资料，之后结合 articles 下的第 1 篇和 plan/README.md 开始认领任务。认领前请先通过后面的联系方式加入协作群组。

## 实验环境

[Linux Lab](https://tinylab.org) 对 RISC-V 内核开发与实验提供了完善的支持，推荐大家自行安装 Linux Lab 或者直接使用 [Linux Lab Disk](https://shop155917374.taobao.com/)（某宝检索“泰晓 Linux”可找到，可申请内置 riscv64/virt 和 riscv32/virt 虚拟开发板）。认领任务并成功输出一篇分析成果后可免费申请 riscv64/virt 和 riscv32/virt 虚拟开发板。

## 联系我们

直接加微信号 tinylab 并介绍一下自己的技术背景以及希望参与分析的子系统或者特性，如果能提供自己发表过的相关技术文章、视频、代码 Patch、博客网站链接等就更好。

动起来吧，点赞、转发、分享也需要，后续分析成果将直接发布在该专栏等渠道，记得收藏哈。

[1]: https://tinylab.org
