---
layout: post
author: 'Wu Zhangjin'
title: "全网可用交叉编译工具链大全"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /prebuilt-cross-toolchains/
description: "本文收录全网可下载的交叉编译工具链，方便大家做嵌入式 Linux 开发。"
category:
  - 交叉编译
tags:
  - GCC
  - Cross Toolchains
  - ARM
  - MIPS
  - X86
  - Risc-V
  - Bootlin
  - Linaro
  - Buildroot
  - 工具链
  - 嵌入式开发
---

> By Falcon of [TinyLab.org][1]
> Jul 31, 2019

嵌入式系统业界前辈 [@comcat](https://github.com/comcat) 说：

> 交叉编译工具链 (Toolchain) 是整个嵌入式软件工业的基础。

是的，交叉编译工具链 是学习处理器指令集、汇编语言、Linux 内核、Linux 驱动开发、嵌入式 Linux 等不可或缺的工具，目前这些工具基本由处理器研发厂商以及相应组织维护，都有提前编译好的版本。

如果想使用这类工具，可以用 buildroot 这样的工具自行构建，但是为节省时间，建议直接下载已编译好的版本。

本文将不断收录全网中可供下载的独立交叉编译工具链，其运行主机全部为 X86 平台。

## 仅提供某个架构或者处理器

### ARM

ARM 公司和 Linaro 联盟均有提供预编译好的 ARM 交叉编译工具链。

* ARM
  * [ARM Toolchains](https://developer.arm.com/open-source/gnu-toolchain)

* Linaro
  * [ARM Toolchains](https://releases.linaro.org/components/toolchain/binaries/)

### MIPS

* MIPS
  * [MIPS Toolchains](https://codescape.mips.com/components/toolchain/2018.09-03/downloads.html)

* Loongson
  * [Lemote Toolchains](http://mirror.lemote.com:8000/loongson3-toolchain/binaries/)

### Risc-V

* GNU-mcu-Eclipse
  * [Risc-V Toolchains](https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases)


**注**：截止到 2019.08.01，来自 <https://www.sifive.com/boards> 的工具链不提供 `-shared` 选项，无法编译内核 vdso，无法编译内核。

### X86

以 Ubuntu 为例：

    add-apt-repository -y ppa:ubuntu-toolchain-r/test
    apt-get -y update
    apt-get install -y --force-yes gcc-8

## 提供多个架构和处理器

* Bootlin.com (for Linux)
  * [Bootlin Toolchains](https://toolchains.bootlin.com/)

* gnutoolchains.com (for Windows)
  * [gnu toolchains](http://gnutoolchains.com/download/)

Bootlin 通过 Buildroot 为 36 个处理器系列，基于 glibc, uclibc, musl 三种库，按最新稳定工具和最新工具分别编译了 Stable 和 Bleeding Edge 版本。

## 更多来源

更多已经经过充分验证的工具链可以从 Buildroot 的 [toolchain/toolchain-external](https://gitee.com/mirrors/buildroot/tree/master/toolchain/toolchain-external) 目录下找到：

    $ ls | egrep -v ".mk|.in$"
    toolchain-external-andes-nds32
    toolchain-external-arm-aarch64
    toolchain-external-arm-aarch64-be
    toolchain-external-arm-arm
    toolchain-external-codescape-img-mips
    toolchain-external-codescape-mti-mips
    toolchain-external-codesourcery-aarch64
    toolchain-external-codesourcery-amd64
    toolchain-external-codesourcery-arm
    toolchain-external-codesourcery-mips
    toolchain-external-codesourcery-niosII
    toolchain-external-custom
    toolchain-external-linaro-aarch64
    toolchain-external-linaro-aarch64-be
    toolchain-external-linaro-arm
    toolchain-external-linaro-armeb
    toolchain-external-synopsys-arc

[1]: http://tinylab.org
