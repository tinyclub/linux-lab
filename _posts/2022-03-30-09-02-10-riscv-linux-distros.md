---
layout: post
author: 'Wu Zhangjin'
title: "两分钟内极速体验 RISC-V Linux 系统发行版"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /riscv-linux-distros/
description: "本文介绍了一种快速体验 RISC-V Linux 系统发行版的方法，即使你手头并没有任何的 RISC-V 开发板。"
category:
  - 开源项目
  - Risc-V
tags:
  - Linux
  - RISC-V
  - 发行版
  - Ubuntu
  - Debian
  - 开发板
  - Linux Lab Disk
---

> Author:  Wu Zhangjin <falcon@tinylab.org>
> Date:    2022/03/30
> Project: [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux)

## 背景简介

随着 [RISC-V Linux 内核兴趣小组](https://tinylab.org/riscv-linux-analyse/) 活动的不断推进，大家迫切需要更完善的 RISC-V 开发环境。

在 RISC-V Linux 内核开发方面，社区研发的 [Linux Lab](https://tinylab.org/linux-lab) 已经完美支持了 [RISC-V Linux 内核 v5.17](https://www.bilibili.com/video/BV1aU4y1d7zi?spm_id_from=333.999.0.0) 的开发支持：

* 支持 riscv32/virt 虚拟开发板
* 支持 riscv64/virt 虚拟开发板

两款板子都已经支持最新的 qemu 6.0 和 Linux v5.17。

并且都提供了可以直接运行的内核和小型文件系统，但是我们还需要一个方便软件安装的较为完整的 RISC-V Linux 发行版。

好消息是，Linux Lab 和 [Linux Lab Disk](https://gitee.com/tinylab/linux-lab-disk) 在这方面也做了非常非常便利的功能，且听一一道来。

## RISC-V Linux 发行版支持状态

RISC-V 的各个主流 Linux 发行版都在火热开发中，比如社区前段刚介绍过 [为哪吒 D1 开发板安装 ArchLinux RISC-V rootfs](https://tinylab.org/nezha-d1-archlinux/)，除了 ArchLinux，咱们也在本次活动参考资料的 [思维导图](https://gitee.com/tinylab/riscv-linux/raw/master/refs/riscv-linux.xmind) 中做了详细地整理：

* [Ubuntu](https://wiki.ubuntu.com/RISC-V)
* [Fedora](https://lwn.net/Articles/749443/)
* [openEuler](https://gitee.com/openeuler/RISC-V)
* [Debian](https://wiki.debian.org/RISC-V)
* [ArchLinux](https://archriscv.felixc.at/)
* [AIpine](https://drewdevault.com/2018/12/20/Porting-Alpine-Linux-to-RISC-V.html)
* [Deepin](https://github.com/linuxdeepin/deepin-riscv)

## 如何使用 RISC-V Linux 发行版

常规的 RISC-V Linux 发行版用法是：

1. 先购买一块 RISC-V 的开发板
2. 按照发行版的官方文档进行安装
3. 配置一番，然后开机体验

第一步就很麻烦，目前的板子都比较贵而且性能极慢（大概在 1-1.2G 左右），问题是还很难买到。

第二步也相当困难，首先是大部分发行版的支持正在开发过程中，其次是安装方式还是嵌入式或 Hacker 级别的，如 [为哪吒 D1 开发板安装 ArchLinux RISC-V rootfs](https://tinylab.org/nezha-d1-archlinux/)。

第三步如果要换一个大一点外置存储卡启动，可能得去设置启动开关，很多时候，找开发板手册上的开关序列跟猜密码一样。

总之，传统的这种使用方式其实门槛挺高的。

当然，也有机构提供了远程访问方式，但是一般仅向开发人员开放，而且资源非常有限。

有没有更轻松愉快的体验方式呢？当然。

## 更亲民的 RISC-V Linux 系统使用方式

咱们这里介绍的方式贼简单，大家只要有一台 X86 电脑，装上 Docker 就行，接下来我们演示一下。

### 简单准备

咱们以本次活动推荐的统一实验环境 [Linux Lab Disk](https://tinylab.org/linux-lab-disk) 为例（其他环境请自行安装 Docker）。

Linux Lab Disk 已经支持 6 大主流 Linux 发行版，包括 Ubuntu, Kali, Mint, Deepin, Manjaro, Fedora 等，这里任选了一个 Kali 版本来做实验。

首先是打开桌面的 `Cloud Lab Manager`，并安装 `qemu-user-static`，以 Ubuntu, Kali, Mint, Deepin 版本为例，除了软件安装命令略有差异，其他都一样。

    $ sudo apt install -y qemu-user-static jq

接着是直接进入到 Linux Lab 的工作目录：

    $ pwd
    ~/Develop/cloud-lab
    $ cd labs/linux-lab

### 查询支持的 RISC-V Linux 发行版

然后检索 Docker 中已经支持的 riscv64 发行版：

    $ docker search riscv64 | grep ^riscv64/
    riscv64/debian                  Debian is a Linux distribution that's compos…   1
    riscv64/busybox                 Busybox base image.                             0
    riscv64/alpine                  A minimal Docker image based on Alpine Linux…   0
    riscv64/ubuntu                  Ubuntu is a Debian-based Linux operating sys…   0

可以看到已经有 busybox, debian, alpine 和 ubuntu，接下来以 ubuntu 为例，先看看支持的 tags：

    $ ../../tools/docker/tags riscv64/ubuntu
    "latest"
    "devel"
    "jammy"
    "jammy-20220315"
    "22.04"
    "rolling"
    "impish"
    "impish-20220316"
    "21.10"
    "focal"

可以看到，最新已经支持 Ubuntu 22.04 了。

### 任选一个下载下来

这里来选 `22.04` 下载下来：

    $ tools/root/docker/extract.sh riscv64/ubuntu:22.04
    LOG: Pulling riscv64/ubuntu:22.04
    22.04: Pulling from riscv64/ubuntu
    779c5da60b92: Pull complete
    Digest: sha256:4de0b5a51c63b54d27ad151217f6cefaa4114a5db33abce6f47fc6a1f2c3bc2b
    Status: Downloaded newer image for riscv64/ubuntu:22.04
    docker.io/riscv64/ubuntu:22.04
    LOG: Running riscv64/ubuntu:22.04
    WARNING: The requested image's platform (linux/riscv64) does not match the detected host platform (linux/amd64) and no specific platform was requested
    LOG: Creating temporary rootdir: /home/kali/Develop/cloud-lab/labs/linux-lab/prebuilt/fullroot/tmp/riscv64-ubuntu-22.04
    LOG: Extract docker image to /home/kali/Develop/cloud-lab/labs/linux-lab/prebuilt/fullroot/tmp/riscv64-ubuntu-22.04
    [sudo] password for kali:
    LOG: Removing docker container
    2b3b9d005682e664f40f4ff80ce483e3673828eaafef51809757e2d91b2ba090
    LOG: Chroot into new rootfs
    Linux linux-lab-host 5.10.0-kali9-amd64 #1 SMP Debian 5.10.46-4kali1 (2021-08-09) riscv64 riscv64 riscv64 GNU/Linux
    Ubuntu Jammy Jellyfish (development branch) \n \l

### 极速体验目标 Linux 系统

然后通过 chroot 运行：

    $ tools/root/docker/chroot.sh riscv64/ubuntu:22.04
    LOG: Chroot into /home/kali/Develop/cloud-lab/labs/linux-lab/prebuilt/fullroot/tmp/riscv64-ubuntu-22.04
    root@linux-lab-host:/#
    root@linux-lab-host:/# uname -a
    Linux linux-lab-host 5.10.0-kali9-amd64 #1 SMP Debian 5.10.46-4kali1 (2021-08-09) riscv64 riscv64 riscv64 GNU/Linux
    root@linux-lab-host:/# uname -m
    riscv64
    root@linux-lab-host:/# exit

如果不想持久化保存运行的结果，那么可以直接用 `tools/root/docker/run.sh`，用完即弃！

## 跑个测试验证系统完整度和性能

刚好最近我们开发了一套 [microbench](https://gitee.com/tinylab/riscv-linux/tree/master/test/microbench) 测试工具，正缺少 RISC-V 的开发环境，这不，一拍即合。

这里同样用 chroot 方式运行，先准备好这个套件需要的基本工具：

    $ tools/root/docker/chroot.sh riscv64/ubuntu:22.04
    LOG: Chroot into /home/kali/Develop/cloud-lab/labs/linux-lab/prebuilt/fullroot/tmp/riscv64-ubuntu-22.04
    root@linux-lab-host:/#
    root@linux-lab-host:/# apt update -y
    root@linux-lab-host:/# apt install -y git make

因为里面是直接可以上网的，咱们直接 clone 代码，然后跑测试：

    root@linux-lab-host:/# git clone https://gitee.com/tinylab/riscv-linux.git
    Cloning into 'riscv-linux'...
    remote: Enumerating objects: 503, done.
    remote: Counting objects: 100% (503/503), done.
    remote: Compressing objects: 100% (422/422), done.
    remote: Total 503 (delta 242), reused 59 (delta 22), pack-reused 0
    Receiving objects: 100% (503/503), 20.22 MiB | 2.05 MiB/s, done.
    Resolving deltas: 100% (242/242), done.
    root@linux-lab-host:/home# cd riscv-linux/test/microbench/
    root@linux-lab-host:/home# make
    ...
    benchmark/build/test/riscv64
    2022-03-29T20:12:04+00:00
    Running benchmark/build/test/riscv64
    Run on (3 X 1992 MHz CPU s)
    Load Average: 1.17, 0.82, 0.66
    -------------------------------------------------------------------------
    Benchmark                               Time             CPU   Iterations
    -------------------------------------------------------------------------
    BM_nop                               1.65 ns         1.65 ns    359748100
    BM_ub                                1.36 ns         1.36 ns    558737615
    BM_bnez                              1.48 ns         1.48 ns    441950287
    BM_beqz                              1.56 ns         1.55 ns    418441841
    BM_load_bnez                         1.50 ns         1.49 ns    516576425
    BM_load_beqz                         1.55 ns         1.55 ns    483432569
    BM_cache_miss_load_bnez              6.90 ns         6.74 ns    100000000
    BM_cache_miss_load_beqz              5.03 ns         4.62 ns    109358335
    BM_branch_miss_load_bnez             9.36 ns         9.22 ns    102308122
    BM_branch_miss_load_beqz             8.27 ns         7.97 ns     68458283
    BM_cache_branch_miss_load_bnez       10.7 ns         9.21 ns    100000000
    BM_cache_branch_miss_load_beqz       10.9 ns         10.9 ns     51663839

上述的 `make` 命令会自动下载源码、安装 gcc 和 g++ 开发环境、自动编译并运行，所以能够确保该文件系统满足 RISC-V 的基本开发需求。

这个测试数据恰好又能反映我们用这种方式运行该 RISC-V Linux 系统的真实性能。

通过与 `logs/` 目录下的真实 4 核心 SiFive 机器数据相比：

    -------------------------------------------------------------------------
    Benchmark                                Time                 CPU   Iterations
    -------------------------------------------------------------------------
    BM_nop                              2.10 ns             2.10 ns        334100173
    BM_ub                               2.93 ns             2.93 ns        238630940
    BM_bnez                             2.51 ns             2.51 ns        278384258
    BM_beqz                             2.51 ns             2.51 ns        278395329
    BM_load_bnez                        1.68 ns             1.68 ns        417591333
    BM_load_beqz                        4.19 ns             4.19 ns        167046897
    BM_cache_miss_load_bnez             9.49 ns             9.48 ns         73806185
    BM_cache_miss_load_beqz             9.54 ns             9.54 ns         73725342
    BM_branch_miss_load_bnez            13.4 ns             13.4 ns         52280162
    BM_branch_miss_load_beqz            13.3 ns             13.3 ns         52296957
    BM_cache_branch_miss_load_bnez      13.3 ns             13.3 ns         52293050
    BM_cache_branch_miss_load_beqz      13.4 ns             13.4 ns         52244654

不难发现，即使是跑在虚拟机下，并且有指令翻译开销，X86 主机（1.9GHz）比 1.2GHz 的 RISC-V 板子还是更快一些。

当然，大家也可以自行按照上述步骤把这个测试用例放到 RISC-V 开发板上跑。如果目标机器的系统太简陋，非常简单，开启静态编译即可：

    root@linux-lab-host:/home# make distclean
    root@linux-lab-host:/home# make STATIC=1
    root@linux-lab-host:/home# ls benchmark/build/test/riscv64
    benchmark/build/test/riscv64
    root@linux-lab-host:/home# apt install -y file
    root@linux-lab-host:/home# file benchmark/build/test/riscv64
    benchmark/build/test/riscv64: ELF 64-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (GNU/Linux), statically linked, BuildID[sha1]=9936c98555982fefd19eb014fe575a11aeb5aa6c, for GNU/Linux 4.15.0, not stripped

然后，把这个测试程序放到 RISC-V 目标系统上运行就可以评估 RISC-V 板子的真实性能了。欢迎大家在各种不同厂家的 RISC-V 开发板上测试，然后把数据提交到 [RISC-V Linux](https://gitee.com/tinylab/riscv-linux) 项目中。

提交数据很简单，这样就可以：

    root@linux-lab-host:/home# make logging

建议同时跑一组：

    root@linux-lab-host:/home# make logging O=0

把 `logs/` 目录下新增的结果提交 Pull Request 上来即可。

目前该测试用例仅适配了 `x86` 和 `riscv64` 架构，如需在其他架构上运行，请参考 `test/` 下的测试用例自行移植，同样欢迎提交 Pull Request。

## 小结

由 [Linux Lab Disk](https://tinylab.org/linux-lab-disk)  提供的这种使用 RISC-V Linux 发行版的方式非常方便：

* 无需购买 RISC-V 开发板
* 无需复杂的安装过程，不用懂嵌入式等 Hacking 技巧
* 仅需几分钟就能通过简单的步骤直接运行，还可以做复杂的 C/C++ 等程序开发

有了 RISC-V Linux 系统发行版以后，很多开发工作就更好开展，比如说软件开发、软件优化与软件打包，甚至做汇编语言开发，指令架构研究和编译器开发等。

除了 RISC-V，大家也可以用同样地方式体验其他处理器架构的 Linux 系统发行版，一样轻松自如。

最后，我们来留一个悬念，如果需要的 RISC-V Linux 发行版还不在 docker 镜像库呢，怎么办？且听下回分解。
