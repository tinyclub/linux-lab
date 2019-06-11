---
layout: post
author: 'Wu Zhangjin'
title: "Linux Lab 新开发板添加指南"
tagline: 如何成为 Linux Lab Developer
draft: false
license: "cc-by-sa-4.0"
permalink: /add-new-board-for-linux-lab/
description: "Linux Lab 的可扩展性很强，添加一款新板子轻而易举。"
category:
  - Linux Lab
  - 开源项目
tags:
  - risc-v
  - qemu
  - gcc
  - buildroot
  - linux
---

> By Falcon of [TinyLab.org][1]
> Jun 11, 2019

## 背景

陆陆续续有很多同学对 Linux Lab 本身的实现原理很感兴趣，目前有十多位同学希望成为 Linux Lab Developer，但是之前这块的资料比较匮乏，也没来得及整理。在 [Linux Lab v0.1 rc1](http://tinylab.org/linux-lab-v0.1-rc1/) 发布之后，我们终于有时间开始撰写这些材料。

## 简介

Linux Lab 是一套极速的 Linux 内核学习、开发和测试环境。它本身不是操作系统，也不是什么发行版，只是一套工具集，一个学习 Linux 内核的实验室，只是实验室的很多工具都是已经准备好的，可以立即上手做实验，不需要做大量繁杂的准备工作。

## 组织架构

Linux Lab 由三大组件构成：

- [Cloud Lab](/cloud-lab)：基于 Docker 构建的实验环境，包含 Linux 内核实验所需的Qemu虚拟机、工具链、编辑器等，并提供了本地和远程的 ssh/vnc 登陆方式。

- [Linux Lab](/linux-lab)：Linux 内核实验相关的配置工具、脚本、patch等，也是 Linux Lab 的核心模块。

- [Prebuilt](https://github.com/tinyclub/prebuilt)：预编译好的内核、文件系统以及实验环境中未支持的新版本Qemu、更新的工具链等。

## 目录结构

    $ tree -L 1 ./linux-lab
    ./linux-lab
    ├── Makefile     -- 核心 Makefile，会包含开发板目录中各板级 Makefile
    ├── boards       -- 开发板管理目录
    ├── qemu         -- qemu submodule，虚拟机源代码
    ├── buildroot    -- buildroot submodule，buildroot 源代码
    ├── linux-stable -- linux-stable sbumodule，Linux Stable 源代码
    ├── u-boot       -- u-boot submodule, Uboot 源代码
    ├── prebuilt     -- prebuit submodule，预编译好的文件所在目录
    ├── COPYING      -- 版权声明
    ├── doc          -- 综合性文档
    ├── examples     -- 实践案例，含汇编、Shell、Makefile等
    ├── modules      -- 内核模块管理目录，用于管理各种内核模块学习案例
    ├── feature      -- 内核特性管理目录，含相关的配置、patch、环境需求
    ├── hostshare    -- 9pnet 共享协议默认共享目录，可通过 SHAREDIR 修改
    ├── logging      -- 测试结果保存的路径
    ├── output       -- 所有构建的部分都在这里
    ├── patch        -- 用于管理共性的各种 patchset
    ├── system	     -- 用于扩展 guest 系统，用于添加测试、共享、网络配置等能力
    ├── tools        -- 各种辅助脚本和工具，主要是跑在本地
    ├── tftpboot     -- 用于 U-boot 加载镜像的 tftpboot 默认路径
    ├── README.md    -- 详细使用文档
    ├── TODO.md      -- Linux Lab 未来计划加入的功能，部分已经完成但是还未删除
    └── VERSION      -- 版本号


## 板子目录

    $ tree boards/ -L 1
    boards/
    ├── aarch64      -- ARM 64
    ├── arm          -- ARM 32
    ├── mipsel       -- mips 32
    ├── ppc          -- ppc 32
    ├── riscv32      -- riscv 32
    ├── riscv64      -- riscv 64
    ├── i386         -- X86 32
    └── x86_64       -- x86 64

    $ tree boards/arm/ -L 2
    boards/arm/
    ├── versatilepb                        -- Versatilepb 板子
    │   ├── buildroot_arm926t_defconfig    -- buildroot 配置文件
    │   ├── uboot_v2015.07_defconfig       -- uboot 配置文件
    │   ├── linux_v2.6.36_defconfig        -- linux 配置文件
    │   ├── linux_v4.6.7_defconfig
    │   ├── linux_v5.0.13_defconfig
    │   ├── linux_v5.1_defconfig
    │   └── Makefile                       -- 板子配置信息
    └── vexpress-a9                        -- Vexpress-a9 板子
        ├── buildroot_cortex-a9_defconfig
        ├── linux_v3.18.39_defconfig
        ├── linux_v4.6.7_defconfig
        ├── linux_v5.0.10_defconfig
        ├── linux_v5.1_defconfig
        ├── Makefile
        └── uboot_v2015.07_defconfig

## Prebuilt 目录

    $ tree prebuilt/ -L 2
    prebuilt/
    ├── README.md
    ├── bios            -- 部分板子需要加载特定的 bios
    │   └── ppc
    ├── fullroot        -- fullroot 所在目录，目前主要指发布到 docker 的 ubuntu 镜像
    │   ├── build       -- 构建 docker 镜像所需的 Dockerfile 等
    │   ├── README.md
    │   └── tmp         -- 所有 docker 镜像抽取出来的文件系统临时存放路径
    ├── kernel          -- 所有板子预先编译好的内核、dtb 等内核相关镜像
    │   ├── aarch64
    │   ├── arm
    │   ├── i386
    │   ├── mipsel
    │   ├── ppc
    │   ├── riscv32
    │   ├── riscv64
    │   └── x86_64
    ├── qemu            -- 预编译好的 Qemu 虚拟机，包括 qemu-system-XARCH 和 qemu-XARCH-static
    │   ├── aarch64
    │   ├── arm
    │   ├── README.md
    │   ├── riscv32
    │   └── riscv64
    ├── root            -- 用 buildroot 制作的 mini rootfs: xxx.cpio.tar.gz
    │   ├── aarch64
    │   ├── arm
    │   ├── i386
    │   ├── mipsel
    │   ├── ppc
    │   ├── riscv32
    │   ├── riscv64
    │   └── x86_64
    ├── toolchains      -- 第三方平台预先编译好的交叉编译器
    │   ├── aarch64
    │   ├── arm
    │   ├── i386
    │   ├── riscv64
    │   └── x86_64
    └── uboot           -- 预编译好的 Uboot 镜像文件
        └── arm

## 选择处理器架构

以 risc-v 的 64 位版本为例：

    $ mkdir boards/riscv64/

## 选择一款开发板

在 [Qemu Documentation Platforms](https://wiki.qemu.org/Documentation/Platforms) 下可以找到 [Risc-V](https://wiki.qemu.org/Documentation/Platforms/RISCV) 的基本支持信息。

另外在 Buildroot 的 [board/qemu](https://github.com/buildroot/buildroot/tree/master/board/qemu) 下可以找到支持的板子信息，包括内核配置以及 qemu 启动脚本，在 [configs/](https://github.com/buildroot/buildroot/tree/master/configs) 下则有相应的 rootfs 配置信息。

综合两个信息，可以选择一款能够快速支持的板子，那就是 riscv64/virt。

    $ mkdir boards/riscv64/virt

参考资料：

- buildroot: [board/qemu/riscv64-virt/](https://github.com/buildroot/buildroot/tree/master/board/qemu/riscv64-virt)
- buildroot: [configs/qemu_riscv64_virt_defconfig](https://github.com/buildroot/buildroot/blob/master/configs/qemu_riscv64_virt_defconfig)

## 准备一个极简的板子配置文件

可以基于最相近的板子复制一份配置文件，我们从 aarch64/virt 作为模板：

    $ cp boards/aarch64/virt/Makefile boards/riscv64/virt/

然后修改几项基本配置：

    ARCH     = riscv
    XARCH    = riscv64

其他的保持不变，暂时不管即可。

## 配置和编译 Qemu

由于 Risc-V 是近几年才冒出来然后飞速发展的处理器架构，所以老版本的 Qemu 根本就不支持，所以需要自行编译。Linux Lab 为此提供了极度便利的支持。

为了获取尽可能最多的特性，这里选择最新的版本 v4.0.0，在板子 Makefile 中把 QEMU 配置为 v4.0.0。

    QEMU    ?= v4.0.0

需要分别编译 qemu-system-XARCH 和 qemu-XARCH-static，前者为全系统模拟（平时使用），后者为指令集翻译（学习汇编，通过chroot使用文件系统时需要）。首先配置 `QEMU_US` 为 0 来编译 qemu-system-XARCH，之后配置 `QEMU_US` 为 1 再编译一遍（`QEMU_US` 即可 `QEMU_USER_STATIC`）。

    $ make qemu-download
    $ make qemu-checkout
    $ make qemu-patch     // 打上两笔 patch，目前 v4.0.0 有两处错误，需要打 patch 才能正常配置和编译
    $ make qemu-defconfig
    $ make qemu
    $ make qemu-save

编译完即时保存，并 clean 掉，然后修改 Makefile 中的 `QEMU_US` 为 1，再配置和编译就可以编译出 qemu-XARCH-static。两者不能同时编译，因为 qemu-system-XARCH 暂时不能静态编译，会出错。

    $ make qemu-clean
    $ make qemu-defconfig
    $ make qemu
    $ make qemu-save

请务必记得做完 `make qemu-save` 再 `make qemu-clean`，确保编译完的已经安装到 `prebuilt` 目录下。

编译完 Qemu 以后可以查看其支持的板子信息。

    $ ./prebuilt/qemu/riscv64/v4.0.0/bin/qemu-system-riscv64 -M ?
    Supported machines are:
    none                 empty machine
    sifive_e             RISC-V Board compatible with SiFive E SDK
    sifive_u             RISC-V Board compatible with SiFive U SDK
    spike_v1.10          RISC-V Spike Board (Privileged ISA v1.10) (default)
    spike_v1.9.1         RISC-V Spike Board (Privileged ISA v1.9.1)
    virt                 RISC-V VirtIO Board (Privileged ISA v1.10)

可以看到 `riscv64/virt` 支持 Privileged ISA v1.10，查看该板子下支持的 CPU 类型：

    $ ./prebuilt/qemu/riscv64/v4.0.0/bin/qemu-system-riscv64 -M virt -cpu ?
    any
    rv64gcsu-v1.10.0
    rv64gcsu-v1.9.1
    rv64imacu-nommu
    sifive-e51
    sifive-u54

由于现有的基础资料都显示 qemu 启动脚本无需指定特定的 cpu，在板子 Makefile 中配置 CPU 为 any 即可。

    CPU ?= any

## 配置和编译 Rootfs

接下来很关键的一项是通过 buildroot 编译文件系统，编译完成后会生成一份交叉编译工具链，这份工具链可以用来编译后面的内核，另外，为了提升移植的效率，避免遇到过多陷阱，起初可以完全复用 buildroot 的配置文件：`configs/qemu_riscv64_virt_defconfig`。

另外，同样地，为了确保拿到最新的 Risc-V 支持，选择当前最新的一版 buildroot，即：2019.05，配置板子 Makefile 如下：

    BUILDROOT ?= 2019.05

之后，直接配置和编译 rootfs：

    $ make root-download
    $ make root-checkout
    $ make root-defconfig RCFG=qemu_riscv64_virt_defconfig
    $ make root

编译完以后，会在 `output/riscv64/buildroot-2019.05-any/images` 目录下生成相应的镜像文件：

    $ tree output/riscv64/buildroot-2019.05-any/images/
    output/riscv64/buildroot-2019.05-any/images/
    ├── fw_jump.elf	-- riscv 特有的 proxy kernel，用于切换处理器模式并加载真正的内核
    ├── Image           -- 内核镜像文件
    ├── rootfs.ext2     -- 根文件系统镜像, ext2 格式
    └── vmlinux         -- 带符号的内核镜像文件

之后，可以立马参考 [board/qemu/riscv64-virt/readme.txt](https://github.com/buildroot/buildroot/tree/master/board/qemu/riscv64-virt/readme.txt) 中的 qemu 脚本做启动验证。

    $ ./prebuilt/qemu/riscv64/v4.0.0/bin/qemu-system-riscv64 -M virt -kernel output/riscv64/buildroot-2019.05-any/images/fw_jump.elf -device loader,file=output/riscv64/buildroot-2019.05-any/images/Image,addr=0x80200000 -drive file=output/riscv64/buildroot-2019.05-any/images/rootfs.ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0  -nographic -append "root=/dev/vda ro"

引导正常，立即保存编译好的文件系统、proxy kernel 以及配置文件，保存之前先在板子 Makefile 中对 proxy kernel 做个配置（目前只要 riscv 需要）：

    PORIIMG ?= fw_jump.elf
    PKIMAGE  ?= $(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/$(PORIIMG)

接着保存即可：

    $ make root-save
    $ make root-saveconfig


会自动生成一份 `boards/riscv64/virt/buildroot_any_defconfig`，在这个基础上增加几个基础配置：

    # System
    BR2_WGET="wget -c --passive-ftp -nd -t 3"
    # Filesystem
    BR2_TARGET_GENERIC_HOSTNAME="linux-lab"
    BR2_TARGET_GENERIC_ISSUE="Welcome to Linux Lab"
    BR2_PACKAGE_BUSYBOX_SHOW_OTHERS=y
    BR2_PACKAGE_BASH=y
    BR2_TARGET_ROOTFS_CPIO=y
    BR2_TARGET_ROOTFS_CPIO_GZIP=y

另外，Kernel 相关的编译配置只要保留头文件，无需编译内核，内核可以独立配置。

Buildroot 生成的交叉编译工具链放在 `output/riscv64/buildroot-2019.05-any/host/bin/`。Linux Lab 会默认引用该工具链。

说明：这里的 RCFG 和后面的 KCFG，都只需要在首次配置时使用，不指定的时候就会用板子目录下默认的配置。

## 配置和编译 Linux

接下来编译内核，首先在板子 Makefile 中配置内核为最新的 v5.1，并配置好基本的参数：

    LINUX ?= v5.1
    KRN_ADDR ?= 0x80200000
    ORIIMG  ?= arch/$(ARCH)/boot/Image
    KIMAGE  ?= $(PREBUILT_KERNEL)/$(XARCH)/$(MACH)/$(LINUX)/Image

接着开始下载、配置和编译：

    $ make kernel-download
    $ make kernel-defconfig KCFG=defconfig
    $ make kernel
    $ make kernel-save
    $ make kernel-saveconfig

编译完以后，立马验证：

    $ ./prebuilt/qemu/riscv64/v4.0.0/bin/qemu-system-riscv64 -M virt -kernel output/riscv64/buildroot-2019.05-any/images/fw_jump.elf -device loader,file=output/riscv64/linux-v5.1-virt/arch/riscv/boot/Image,addr=0x80200000 -drive file=output/riscv64/buildroot-2019.05-any/images/rootfs.ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0  -nographic -append "root=/dev/vda ro"

接着就是根据 Linux Lab 的需要进行更细粒度的内核配置，后续这部分可以完全通过 `make feature` 完成，目前只完成了一部分，比如 9pnet、debug 等。

    $ make f f=9pnet,debug

更多特性请通过 menuconfig 添加，比如 nfsroot, devtmpfs, virtio 网络等配置：

    $ make kernel-menuconfig

具体配置请以已经上传的各大板子内核配置为准，上述公共特性基本都支持。配置完以后即可进行启动验证，没问题就再次保存。

    $ make kernel-save
    $ make kernel-saveconfig

## 配置和编译 Uboot

TODO

## 准备外置 Toolchain

由于 buildroot 编译生成的工具链略大，也没有合适的地方上传，这里选择一个更轻的方式，那就是直接复用 sifive 官网提供的最新版工具链，只要在 `prebuilt/toolchains/riscv64/` 下面新增一个 Makefile 和 README.md 即可，可参考 aarch64/virt 进行配置。

配置完以后在板子配置文件中指定板子：

    # To use this prebuilt toolchain, please run `make toolchain` before `make kernel`
    CCPRE   ?= $(XARCH)-unknown-elf-
    CCVER   ?= 8.2.0-2019.02.0
    CCPATH  ?= $(PREBUILT_TOOLCHAINS)/$(XARCH)/riscv64-unknown-elf-gcc-$(CCVER)-x86_64-linux-ubuntu14/bin/

使用的时候，先执行如下命令自动下载和解压 toolchain，之后就可以默认使用：

    $ make toolchain

## 各种组合的启动测试与验证

上面是直接通过 qemu 脚本进行启动验证，接下来很重要的是需要通过 `make boot` 启动，这意味着 `make boot` 需要自动根据板子 Makefile 自动构建上述 qemu 启动脚本。

正常情况下配置完上述板子，即可执行 `make boot`，但是 risc-v 需要对 `-kernel` 参数做个 workaround，所以在主 Makefile 中，追加了这么一个判断：

    # If proxy kernel exists, hack the default -kernel option
    ifneq ($(PORIIMG),)
      KERNEL_OPT ?= -kernel $(PKIMAGE) --device loader,file=$(KIMAGE),addr=$(KRN_ADDR)
    else
      KERNEL_OPT ?= -kernel $(KIMAGE)
    endif

有配置 Proxy kernel （PORIIMG）的情况下，`-kernel` 指向 proxy kernel，然后通过 loader device 加载真正的内核。

然后即可用 `make boot` 验证。

    $ make boot

另外，也建议调整 `ROOTDEV` 来以不同方式加载文件系统：`/dev/ram`, `/dev/vda`, `/dev/nfs` 等。还可以传递 `SHARE=1` 验证 9pnet sharin 等，更多基础用法请参照 README.md，请务必确保做足充分的验证，确保 README.md 中的核心内容都是可以完美工作的。

## 保存配置文件

再次确认各大配置文件已经保存：

    $ make root-saveconfig
    $ make kernel-saveconfig

## 保存各大镜像

再次确认各大配置文件已经保存：

    $ make root-save
    $ make kernel-save
    $ make qemu-save

## 代码入库前验证

下面这条命令对 prebuilt 的各大镜像进行测试。

    $ tools/testing/boot.sh riscv64/virt

## 提交代码入库

之后，把板级目录 `boards/riscv64/virt` 和核心 Makefile 的相关变更提交进 [Linux Lab 仓库](https://github.com/tinyclub/linux-lab)。

而 prebuilt 相关的代码请提交进 [Prebuilt repo](https://github.com/tinyclub/prebuilt)。

至此，一款新的板子开发完成。


[1]: http://tinylab.org
