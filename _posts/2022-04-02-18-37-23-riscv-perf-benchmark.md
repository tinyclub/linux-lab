---
layout: post
author: 'Wu Zhangjin'
title: "RISC-V 处理器指令级性能评测尝试"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /riscv-perf-benchmark/
description: "本文介绍了一款自研的 benchmark 工具，用于从指令层面评估处理器性能，并简单评测和对比了 x86_64 和 RISC-V 处理器架构的性能差异。"
category:
  - 开源项目
  - Risc-V
  - 基准测试
tags:
  - Linux
  - RISC-V
  - benchmark
  - microbench
  - 指令性能
  - riscv64
  - x86_64
  - c906
  - T-head
  - SiFive
  - unmatched
  - u74
---

> Author:  Wu Zhangjin <falcon@tinylab.org>
> Date:    2022/04/02
> Project: [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux)

## 简介

在分析 [RISC-V Jump Label](https://tinylab.org/riscv-jump-label-part1/) 的过程中，为了探究 Jump Label 的性能优化预期效果，我们在一周内专门基于 Google benchmark 框架开发了一款面向处理器基础指令性能测试的工具 —— microbench。

microbench 的最初目标是测试 Jump Label 涉及到的几条基础指令，比如：

* nop
* unconditional jump
* conditional branch (include beqz and bnez)
* load + branch
* cache miss + load + branch
* branch miss + load + branch
+ cache miss + branch miss + load + branch

目前已经支持 `x86_64`, `riscv64`，对其他架构的支持和数据测试工作也将陆续展开。

从长远来看，我们期待扩大每个架构的指令覆盖范围，并希望这款工具能帮助业界评估目标处理器的真实性能表现，当然，也希望最终能帮助处理器厂商发现并改进设计上的缺陷。

microbench 目前还很简陋，短期内将继续停留在 [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux/) 协作仓库内的 [test/microbench](https://gitee.com/tinylab/riscv-linux/tree/master/test/microbench) 目录下，未来将作为独立的项目发布和维护。

相信目前的 microbench 代码还有不少 Bug，包括 test case 命名，实现细节，多架构支持，耦合性问题等。

目前已知问题：

* cache 和 branch miss 相关的几组 test cases 结果仅适合多核
* 其中 BM_branch_miss 那组目前的实现实质上是 cache miss + likely miss

也许还有其他 Bug，欢迎 Review 并提交 PR 修订。

## 下载 microbench

当前可以从 [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux/) 下载：

    $ git clone https://gitee.com/tinylab/riscv-linux

代码结构非常简单：

    $ cd riscv-linux/test/microbench
    $ tree  ./
    ./
    ├── logs
    │   ├── D1-H-nezha-rv64imafdcvu-sv39-riscv64-20220330-123559-O1.log
    │   ├── D1-H-nezha-rv64imafdcvu-sv39-riscv64-20220330-123822-O0.log
    │   ├── SiFive-HiFive-Unmatched-A00-rv64imafdc-sv39-sifive-u74-mc-riscv64-20220323-150035-O1.log
    │   ├── SiFive-HiFive-Unmatched-A00-rv64imafdc-sv39-sifive-u74-mc-riscv64-20220323-150150-O0.log
    │   ├── TM1703-Intel-R-Core-TM-i7-8550U-CPU-1.80GHz-x86_64-20220323-035405-O1.log
    │   └── TM1703-Intel-R-Core-TM-i7-8550U-CPU-1.80GHz-x86_64-20220323-035454-O0.log
    ├── Makefile
    ├── README.md
    └── test
        ├── riscv64.cc
        └── x86_64.cc

## 运行 microbench

### 在标准 Linux 发行版上运行

microbench 已经支持本地编译、交叉编译、静态编译，所以使用是非常灵活的。

在标准的 Linux 发行版上，microbench 可以自动安装依赖，自动检测处理器架构，自动编译和运行，所以用法非常简单：

    $ make

如果要提交测试结果，可以这样：

    $ make logging

如果想完整提交测试结果，建议同时运行一版（阻止编译器优化）：

    $ make logging O=0

### 在嵌入式 Linux 上运行

如果目标系统缺少软件安装环境，无法提供 gcc, g++ 等编译工具，那么可以通过以下任意一种方式来支持。

**交叉编译**

首先介绍交叉编译。microbench 在交叉编译时自动开启静态链接：

比如，在 `x86_64` + Ubuntu 的主机上，可以直接交叉编译出 `riscv64` 的 microbench：

    $ make ARCH=riscv64
    $ cp benchmark/build/test/riscv64 microbench.riscv64.o1

如果要禁止优化的版本，建议同时编译一版：

    $ make ARCH=riscv64 O=0
    $ cp benchmark/build/test/riscv64 microbench.riscv64.o0

可以直接复制到目标机器上运行。

**静态编译**

如果本身还有 `riscv64` + Ubuntu 这样的环境，或者通过 [两分钟内极速体验 RISC-V Linux 系统发行版](https://tinylab.org/riscv-linux-distros/) 这种方式构建了这样的环境，那么可以通过静态链接的方式制作：

    $ make STATIC=1
    $ cp benchmark/build/test/riscv64 microbench.riscv64.o1
    $ make STATIC=1 O=0
    $ cp benchmark/build/test/riscv64 microbench.riscv64.o0

**扩展完整系统**

第三种方式同样是在 [两分钟内极速体验 RISC-V Linux 系统发行版](https://tinylab.org/riscv-linux-distros/) 的基础上，只不过需要用户通过外接 SD 卡或者 USB 的方式把系统载入目标嵌入式开发板中，然后通过 chroot 的方式切换文件系统即可。

切换后请自行挂载 `/proc`, `/tmp`, `/dev`, `/sys` 等虚拟文件系统：

    $ mount -t sysfs none /sys
    $ mount -t proc proc /proc
    $ mount -t devtmpfs none /dev
    $ mount -t tmpfs none /tmp

之后就可以按照第一种方式直接运行。

### 在当前未支持的架构上运行

microbench 目前的多架构支持还比较简单，未来将进行更灵活的改造。

以 `aarch64` 为例，现在可以从 `test/x86_64.cc` 中复制出一份 `test/aarch64.cc`，然后把前面几个 case 中的汇编指令替换为 `aarch64` 特有的指令即可，替换完以后用法跟上面完全一致。

## 数据汇总与对比

### 测试设备和数据简介

多位同学在运行完 microbench 后，提交了测试数据：

    $ tree  ./
    ./
    ├── logs
    │   ├── D1-H-nezha-rv64imafdcvu-sv39-riscv64-20220330-123559-O1.log
    │   ├── D1-H-nezha-rv64imafdcvu-sv39-riscv64-20220330-123822-O0.log
    │   ├── SiFive-HiFive-Unmatched-A00-rv64imafdc-sv39-sifive-u74-mc-riscv64-20220323-150035-O1.log
    │   ├── SiFive-HiFive-Unmatched-A00-rv64imafdc-sv39-sifive-u74-mc-riscv64-20220323-150150-O0.log
    │   ├── TM1703-Intel-R-Core-TM-i7-8550U-CPU-1.80GHz-x86_64-20220323-035405-O1.log
    │   └── TM1703-Intel-R-Core-TM-i7-8550U-CPU-1.80GHz-x86_64-20220323-035454-O0.log

分别为两款 RISC-V 开发板和一款 `x86_64` 主机。

* D1-H-nezh: 由全志基于平头哥 c906 开发, 1GHz\*1，以下用 T-head c906 指代
* SiFive-HiFive-Unmatched, 1.2GHz\*4，以下用 SiFive u74 指代
* TM1703-i7-8550U, 1.8GHz\*8，以下用 Intel i7-8550U 指代

### 数据对比

数据汇总成表：

* 不阻止优化迭代循环体的情况

    microbench                      | Intel i7-8550U   | SiFive u74 | T-head c906
    --------------------------------|------------------|------------|--------------
    BM_nop                          | 0.253 ns         | 2.10 ns    | 3.04 ns
    BM_ub                           | 0.909 ns         | 2.93 ns    | 3.55 ns
    BM_bnez                         | 0.912 ns         | 2.51 ns    | 3.06 ns
    BM_beqz                         | 0.918 ns         | 2.51 ns    | 3.04 ns
    BM_load_bnez                    | 0.253 ns         | 1.68 ns    | 4.05 ns
    BM_load_beqz                    | 0.254 ns         | 4.19 ns    | 4.06 ns
    BM_cache_miss_load_bnez         | 2.05 ns          | 9.49 ns    | 8.09 ns
    BM_cache_miss_load_beqz         | 2.16 ns          | 9.54 ns    | 8.09 ns
    BM_branch_miss_load_bnez        | 3.85 ns          | 13.4 ns    | 8.12 ns
    BM_branch_miss_load_beqz        | 3.90 ns          | 13.3 ns    | 8.10 ns
    BM_cache_branch_miss_load_bnez  | 4.70 ns          | 13.3 ns    | 8.13 ns
    BM_cache_branch_miss_load_beqz  | 5.68 ns          | 13.4 ns    | 8.13 ns

* 阻止优化迭代循环体的情况

    microbench                      | Intel i7-8550U   | SiFive u74 | T-head c906
    --------------------------------|------------------|------------|--------------
    BM_nop                          | 0.504 ns         |  5.03 ns   | 10.1 ns
    BM_ub                           | 0.755 ns         |  5.05 ns   | 10.2 ns
    BM_bnez                         | 0.505 ns         |  7.54 ns   | 10.1 ns
    BM_beqz                         | 0.918 ns         |  7.54 ns   | 10.1 ns
    BM_load_bnez                    | 0.662 ns         |  5.87 ns   | 12.2 ns
    BM_load_beqz                    | 0.776 ns         |  5.87 ns   | 12.2 ns
    BM_cache_miss_load_bnez         |  4.44 ns         |  28.3 ns   | 24.3 ns
    BM_cache_miss_load_beqz         |  4.33 ns         |  28.3 ns   | 24.3 ns
    BM_branch_miss_load_bnez        |  5.85 ns         |  53.4 ns   | 24.2 ns
    BM_branch_miss_load_beqz        |  5.87 ns         |  53.4 ns   | 24.3 ns
    BM_cache_branch_miss_load_bnez  |  8.07 ns         |  52.6 ns   | 24.4 ns
    BM_cache_branch_miss_load_beqz  |  8.33 ns         |  53.4 ns   | 24.7 ns

需要注意的是：

* 其中，c906 为单核，后面 6 个 test cases 的行为跟另外两个处理器存在差异，存在单核上多任务切换的情况而且并不能完整构造对应的 cache miss 和 branch miss。

## 小结

从 microbench 的初步测试数据来看：

* 两款 RISC-V 芯片的基础指令性能跟对比的 `x86_64` 芯片性能差异较大（4-10倍），即使换算到同等主频（2-5倍），差异也较为明显。
    * 说明：测试过程中，不排除 i7-8550U 会自动睿频到更高频率的情况，后续需要确认这部分。
* 而两款 RISC-V 芯片之间，排除掉核心数和主频的差异，两者表现较为接近，c906 相对偏弱。

所以，RISC-V 未来还有很多工作要做，比如，确保可以工作在更高的主频，更多的核心数，硬件指令级的优化，编译器的优化，访存性能等。

同时，欢迎处理器设计相关的专业朋友参与讨论和交流，也欢迎参与评审和改进 microbench，并对相关数据提出更专业的分析结论和原因推测，也可以讨论潜在的软硬件优化方向。
