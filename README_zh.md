**Subscribe Wechat**：<br/><img src='doc/tinylab-wechat.jpg' width='110px'/><br/>

# Linux Lab

This project aims to create a Qemu-based Linux development Lab to easier the learning, development and testing of [Linux Kernel](http://www.kernel.org).
本项目致力于创建一个基于 QEMU 的用于 Linux 开发的实验环境，方便大家学习、开发和测试 [Linux Kernel](http://www.kernel.org)。

For Linux 0.11, please try our [Linux 0.11 Lab](http://gitee.com/tinylab/linux-0.11-lab).
如果您想尝试 Linux 0.11，请访问我们的 [Linux 0.11 实验环境](http://gitee.com/tinylab/linux-0.11-lab)。

[![Docker Qemu Linux Lab](doc/linux-lab.jpg)](http://showdesk.io/2017-03-11-14-16-15-linux-lab-usage-00-01-02/)

## Contents

- [Why](#why)
- [Homepage](#homepage)
- [Demonstration](#demonstration)
- [Install docker](#install-docker)
- [Choose a working directory](#choose-a-working-directory)
- [Download the lab](#download-the-lab)
- [Run and login the lab](#run-and-login-the-lab)
- [Update and rerun the lab](#update-and-rerun-the-lab)
- [Quickstart: Boot a board](#quickstart-boot-a-board)
- [Usage](#usage)
   - [Using boards](#using-boards)
      - [List available boards](#list-available-boards)
      - [Choosing a board](#choosing-a-board)
      - [Using as plugins](#using-as-plugins)
   - [Downloading](#downloading)
   - [Checking out](#checking-out)
   - [Patching](#patching)
   - [Configuration](#configuration)
      - [Default Configuration](#default-configuration)
      - [Manual Configuration](#manual-configuration)
      - [Old default configuration](#old-default-configuration)
   - [Building](#building)
   - [Saving](#saving)
   - [Booting](#booting)
   - [Using](#using)
      - [Linux](#linux)
        - [non-interactive configuration](#non-interactive-configuration)
        - [using kernel modules](#using-kernel-modules)
        - [using kernel features](#using-kernel-features)
      - [Uboot](#uboot)
      - [Qemu](#qemu)
      - [Toolchain](#toolchain)
      - [Rootfs](#rootfs)
   - [Debugging](#debugging)
   - [Testing](#testing)
   - [Sharing](#sharing)
      - [Install files to rootfs](#install-files-to-rootfs)
      - [Share with NFS](#share-with-nfs)
      - [Transfer via tftp](#transfer-via-tftp)
      - [Share with 9p virtio](#share-with-9p-virtio)
- [More](#more)
   - [Add a new board](#add-a-new-board)
      - [Choose a board supported by qemu](#choose-a-board-supported-by-qemu)
      - [Create the board directory](#create-the-board-directory)
      - [Clone a Makefile from an existing board](#clone-a-makefile-from-an-existing-board)
      - [Configure the variables from scratch](#configure-the-variables-from-scratch)
      - [At the same time, prepare the configs](#at-the-same-time,-prepare-the-configs)
      - [Choose the versions of kernel, rootfs and uboot](#choose-the-versions-of-kernel,-rootfs-and-uboot)
      - [Configure, build and boot them](#configure,-build-and-boot-them)
      - [Save the images and configs](#save-the-images-and-configs)
      - [Upload everything](#upload-everything)
   - [Learning Assembly](#learning-assembly)
   - [Running any make goals](#running-any-make-goals)
- [FAQs](#faqs)
   - [Poweroff hang](#poweroff-hang)
   - [Boot with missing sdl2 libraries failure](#boot-with-missing-sdl2-libraries-failure)
   - [NFS/tftpboot not work](#nfstftpboot-not-work)
   - [Run tools without sudo](#run-tools-without-sudo)
   - [Speed up docker images downloading](#speed-up-docker-images-downloading)
   - [Docker network conflicts with LAN](#docker-network-conflicts-with-lan)
   - [Why not allow running Linux Lab in local host](#why-not-allow-running-linux-lab-in-local-host)
   - [Why kvm speedding up is disabled](#why-kvm-speedding-up-is-disabled)
   - [How to switch windows in vim](#how-to-switch-windows-in-vim)
   - [How to delete typo in shell command line](#how-to-delete-typo-in-shell-command-line)
   - [How to tune the screen size](#how-to-tune-the-screen-size)
   - [How to exit qemu](#how-to-exit-qemu)
   - [How to work in fullscreen mode](#how-to-work-in-fullscreen-mode)
   - [How to record video](#how-to-record-video)
   - [Linux Lab not response](#linux-lab-not-response)
   - [Language input switch shortcuts](#language-input-switch-shortcuts)
   - [No working init found](#no-working-init-found)
   - [linux/compiler-gcc7.h: No such file or directory](#linuxcompiler-gcc7h-no-such-file-or-directory)
   - [Network not work](#network-not-work)
   - [linux-lab/configs: Permission denied](#linux-labconfigs-permission-denied)
   - [Client.Timeout exceeded while waiting headers](#clienttimeout-exceeded-while-waiting-headers)
   - [VNC login fails with wrong password](#vnc-login-fails-with-wrong-password)
   - [scripts/Makefile.headersinst: Missing UAPI file: ./include/uapi/linux/netfilter/xt_CONNMARK.h](#scriptsmakefileheadersinst-missing-uapi-file-includeuapilinuxnetfilterxt_connmarkh)
   - [Ubuntu Snap Issues](#ubuntu-snap-issues)
- [Contact and Sponsor](#contact-and-sponsor)

## 章节列表

- [项目的发展历史](#why)
- [项目主页](#homepage)
- [演示](#demonstration)
- [安装 docker](#install-docker)
- [选择工作目录](#choose-a-working-directory)
- [下载实验环境](#download-the-lab)
- [运行并登录 Linux Lab](#run-and-login-the-lab)
- [更新实验环境并重新运行](#update-and-rerun-the-lab)
- [快速上手：启动一个开发板](#quickstart-boot-a-board)
- [使用说明](#usage)
    - [使用开发板](#using-boards)
          - [列出支持的开发板](#list-available-boards)
          - [选择一个开发板](#choosing-a-board)
          - [以插件方式使用](#using-as-plugins)
    - [下载](#downloading)
    - [检出](#checking-out)
    - [打补丁](#patching)
    - [配置](#configuration)
        - [缺省配置](#default-configuration)
        - [手动配置](#manual-configuration)
        - [使用旧的缺省配置](#old-default-configuration)
    - [编译](#building)
    - [保存](#saving)
    - [启动](#booting)
    - [使用](#using)
        - [Linux](#linux)
            - [非交互方式配置](#non-interactive-configuration)
            - [使用内核模块](#using-kernel-modules)
            - [使用内核特性](#using-kernel-features)
        - [Uboot](#uboot)
        - [Qemu](#qemu)
        - [Toolchain](#toolchain)
        - [Rootfs](#rootfs)
    - [调试](#debugging)
    - [测试](#testing)
    - [共享](#sharing)
        - [在 rootfs 中安装文件](#install-files-to-rootfs)
        - [采用 NFS 共享文件](#share-with-nfs)
        - [通过 tftp 传输文件](#transfer-via-tftp)
        - [通过 9p virtio 共享文件](#share-with-9p-virtio)
- [更多](#more)
    - [添加一个新的开发板](#add-a-new-board)
        - [选择一个 qemu 支持的开发板](#choose-a-board-supported-by-qemu)
        - [创建开发板的目录](#create-the-board-directory)
        - [从一个已经支持的开发板中复制一份 Makefile](#clone-a-makefile-from-an-existing-board)
        - [从头开始配置变量](#configure-the-variables-from-scratch)
        - [同时准备 configs 文件](#at-the-same-time,-prepare-the-configs)
        - [选择 kernel，rootfs 和 uboot 的版本](#choose-the-versions-of-kernel,-rootfs-and-uboot)
        - [配置，构造和启动](#configure,-build-and-boot-them)
        - [保存生成的镜像文件和配置文件](#save-the-images-and-configs)
        - [上传所有工作](#upload-everything)
    - [学习汇编](#learning-assembly)
    - [运行任意的 make 目标](#running-any-make-goals)
- [常见问题](#faqs)
    - [关机挂起问题](#poweroff-hang)
    - [无法登录 VNC](#vnc-login-with-password-failure)
    - [引导时报缺少 sdl2 库](#boot-with-missing-sdl2-libraries-failure)
    - [NFS/tftpboot 不工作](#nfstftpboot-not-work)
    - [不使用 sudo 运行 tools 命令](#run-tools-without-sudo)
    - [加快 docker images 下载的速度](#speed-up-docker-images-downloading)
    - [Docker 的网络与 LAN 冲突](#docker-network-conflicts-with-lan)
    - [为何不支持在本地主机上直接运行 Linux Lab](#why-not-allow-running-linux-lab-in-local-host)
    - [为何不支持 kvm 加速](#why-kvm-speedding-up-is-disabled)
    - [如何在 vim 中切换窗口](#how-to-switch-windows-in-vim)
    - [如何删除 shell 命令行中打错的字](#how-to-delete-typo-in-shell-command-line)
    - [如何调节窗口的大小](#how-to-tune-the-screen-size)
    - [如何退出 qemu](#how-to-exit-qemu)
    - [如何进入全屏模式](#how-to-work-in-fullscreen-mode)
    - [如何录屏](#how-to-record-video)
    - [Linux Lab 无响应](#linux-lab-not-response)
    - [如何快速切换中英文输入](#language-input-switch-shortcuts)
    - [运行报错 “No working init found”](#no-working-init-found)
    - [运行报错 “linux/compiler-gcc7.h: No such file or directory”](#linuxcompiler-gcc7h-no-such-file-or-directory)
    - [网络不通](#network-not-work)
    - [运行报错 “linux-lab/configs: Permission denied”](#linux-labconfigs-permission-denied)
    - [运行报错 “Client.Timeout exceeded while waiting headers”](#clienttimeout-exceeded-while-waiting-headers)
    - [登录 VNC 时报密码错误](#vnc-login-fails-with-wrong-password)
    - [运行报错：“scripts/Makefile.headersinst: Missing UAPI file: ./include/uapi/linux/netfilter/xt_CONNMARK.h”](#scriptsmakefileheadersinst-missing-uapi-file-includeuapilinuxnetfilterxt_connmarkh)
    - [Ubuntu Snap 问题](#ubuntu-snap-issues)    
- [联系我们以及赞助我们](#contact-and-sponsor)

## Why
## <span id="why">项目的发展历史</span>

About 9 years ago, a tinylinux proposal: [Work on Tiny Linux Kernel](https://elinux.org/Work_on_Tiny_Linux_Kernel) accepted by embedded
linux foundation, therefore I have worked on this project for serveral months.
大约九年前，在 embeded linux foundation 上，发起了一个 tinylinux 的计划，具体参考 [Work on Tiny Linux Kernel](https://elinux.org/Work_on_Tiny_Linux_Kernel)。我在这个项目上工作了几个月。

During the project cycle, several scripts written to verify if the adding tiny features (e.g. [gc-sections](https://lwn.net/images/conf/rtlws-2011/proc/Yong.pdf))
breaks the other kernel features on the main cpu architectures.
在项目开发过程中，编写了几个脚本用于验证一些新的小特性（譬如：[gc-sections](https://lwn.net/images/conf/rtlws-2011/proc/Yong.pdf)）是否破坏了几个主要的处理器架构上的内核功能。

These scripts uses qemu-system-ARCH as the cpu/board simulator, basic boot+function tests have been done for ftrace+perf, accordingly, defconfigs,
rootfs, test scripts have been prepared, at that time, all of them were simply put in a directory, without a design or holistic consideration.
这些脚本使用 qemu-system-ARCH 作为处理器/开发板的模拟器，在模拟器上利用 ftrace 和 perf 运行启动测试和功能测试，并为之相应开发了缺省的内核配置文件（defconfig）、根文件系统（rootfs）以及一些测试脚本。但在当时的条件下，所有的工作只是简单地归档在一个目录下，并没有从整体上将它们组织起来。

They have slept in my harddisk for several years without any attention, untill one day, docker and novnc came to my world, at first, [Linux 0.11 Lab](http://gitee.com/tinylab/linux-0.11-lab) was born, after that, Linux Lab was designed to unify all of the above scripts, defconfigs, rootfs and test scripts.
这些工作成果在我的硬盘里闲置了好多年，直到有一天我遇到了 novnc 和 docker，并基于这些新技术开发了第一个 [Linux 0.11 Lab](http://gitee.com/tinylab/linux-0.11-lab)，此后，为了将此前开发的那些零散的脚本，内核缺省配置，根文件系统和测试脚本整合起来，我开发了 Linux Lab 这个系统。

Now, Linux Lab becomes an intergrated Linux learning, development and testing environment, it supports:
现在，Linux Lab 已经发展为一个学习，开发和测试 Linux 的集成环境，它支持以下功能：

**Boards**: Qemu based, 6+ main Architectures, 10+ popular boards, one `make list` command for all boards, qemu options are hidden.
- **开发板**：基于 QEMU，支持 6+ 主流体系架构，10+ 个流行的开发板，只用输入一个 `make list` 命令就可以列出所有支持的开发板，用户无需关心具体的 QEMU 命令选项和参数。
**Components**: Uboot, Linux / Modules, Buildroot, Qemu are configurable, patchable, compilable, buildable, Linux v5.1 supported.
- **组件**：对 Uboot，Linux / 内核模块，Buildroot，Qemu 全都支持可自行配置，支持打补丁、编译以及构建，最新已支持到 Linux 内核版本 v5.1。
**Prebuilt**: all of above components have been prebuilt and put in board specific bsp submodule for instant using, qemu v2.12.0 prebuilt for arm/arm64.
- **预置组件**：针对以上所有组件均已提供预制件，并按照开发板分类存放在 bsp 子模块中，可随时使用；针对 arm / arm64 平台预置了 v2.12.0 版本的 qemu。
**Rootfs**: Builtin rootfs support include initrd, harddisk, mmc and nfs, configurable via ROOTDEV/ROOTFS, Ubuntu 18.04 for ARM available as docker image: tinylab/armv32-ubuntu.
- **根文件系统（Rootfs）**：对内置的 rootfs 支持包括 initrd，harddisk，mmc 和 nfs，可通过 ROOTDEV / ROOTFS 进行配置， 以 docker 镜像方式提供了 ARM 架构的 Ubuntu 18.04 文件系统，具体仓库路径在：`tinylab/armv32-ubuntu`。
**Docker**: Environment (cross toolchains) available in one command in serveral minutes, 5 main architectures have builtin support, external ones configurable via `make toolchain`.
- **Docker**：编译环境（交叉工具链）可通过一条命令在数分钟内提供，支持 5 种主要架构，还可通过 `make toolchain` 命令配置外部的交叉工具链。
**Browser**: usable via modern web browsers, once installed in a internet server, available everywhere via web vnc or web ssh.
- **浏览器**：当前支持通过网络浏览器访问使用，一旦安装在 Internet 服务器中，即可通过 Web vnc 或 Web ssh 在任何地方进行访问。
**Network**: Builtin bridge networking support, every board support network.
- **网络**：内置桥接（bridge）网络支持，每个开发板都支持网络。
**Boot**: Support serial port, curses (ssh friendly) and graphic booting.
- **启动**：支持串口，curses（用于 ssh 访问）和图形化方式启动。
**Testing**: Support automatic testing via `make test` target.
- **测试**：支持通过 `make test` 命令对目标板进行自动化测试。
**Debugging**: debuggable via `make debug` target.
- **调试**：可通过 `make debug` 命令对目标板进行调试。

Continue reading for more features and usage.
更多特性和使用方法请看下文介绍。

## Homepage
## <span id="homepage">项目主页</span>

See: <http://tinylab.org/linux-lab/>
参考：<http://tinylab.org/linux-lab/>

## Demonstration
## <span id="demonstration">演示</span>

Basic:
基本操作:

* [Basic Usage](http://showdesk.io/7977891c1d24e38dffbea1b8550ffbb8)
* [基本使用](http://showdesk.io/7977891c1d24e38dffbea1b8550ffbb8)
* [Learning Uboot](http://showterm.io/11f5ae44b211b56a5d267)
* [学习 Uboot](http://showterm.io/11f5ae44b211b56a5d267)
* [Learning Assembly](http://showterm.io/0f0c2a6e754702a429269)
* [学习汇编](http://showterm.io/0f0c2a6e754702a429269)
* [Boot ARM Ubuntu 18.04 on Vexpress-a9 board](http://showterm.io/c351abb6b1967859b7061)
* [在 Vexpress-a9 开发板上引导启动 ARM Ubuntu 18.04](http://showterm.io/c351abb6b1967859b7061)
* [Boot Linux v5.1 on ARM64/Virt board](http://showterm.io/9275515b44d208d9559aa)
* [在 ARM64/Virt 开发板上引导启动 Linux v5.1](http://showterm.io/9275515b44d208d9559aa)
* [Boot Riscv32/virt and Riscv64/virt boards](http://showterm.io/37ce75e5f067be2cc017f)
* [引导启动 Riscv32/virt 和 Riscv64/virt 开发板](http://showterm.io/37ce75e5f067be2cc017f)
* [One command of testing a specified kernel feature](http://showterm.io/7edd2e51e291eeca59018)
* [一条命令测试某项内核功能](http://showterm.io/7edd2e51e291eeca59018)
* [One command of testing multiple specified kernel modules](http://showterm.io/26b78172aa926a316668d)
* [一条命令测试多个内核模块](http://showterm.io/26b78172aa926a316668d)
* [Batch boot testing of all boards](http://showterm.io/8cd2babf19e0e4f90897e)
* [批量测试引导启动所有开发板](http://showterm.io/8cd2babf19e0e4f90897e)
* [Batch testing the debug function of all boards](http://showterm.io/0255c6a8b7d16dc116cbe)
* [批量测试所有开发板的调试功能](http://showterm.io/0255c6a8b7d16dc116cbe)

More:
更多操作:

* [Learning RLK4.0 Book (Chinese)](https://v.qq.com/x/page/y0543o6zlh5.html)
* [用 Linux Lab做《奔跑吧Linux内核》实验](https://v.qq.com/x/page/y0543o6zlh5.html)
* [Developing Embedded Linux (Chinese)](http://tinylab.org/using-linux-lab-to-do-embedded-linux-development/).
* [利用 Linux Lab 完成嵌入式系统软件开发全过程](http://tinylab.org/using-linux-lab-to-do-embedded-linux-development/).

## Install docker
## <span id="install-docker">安装 docker</span>

Docker is required by Linux Lab, please install it at first:
运行 Linux Lab 需要基于 Docker，所以请先安装 Docker：

- Linux, Mac OSX, Windows 10: [Docker CE](https://store.docker.com/search?type=edition&offering=community)
- Linux, Mac OSX, Windows 10: 使用 [Docker CE](https://store.docker.com/search?type=edition&offering=community)

- older Windows: [Docker Toolbox](https://www.docker.com/docker-toolbox) or Virtualbox/Vmware + Linux
- 更早的 Windows 版本: 使用 [Docker Toolbox](https://www.docker.com/docker-toolbox) 或者 Virtualbox/Vmware + Linux

Before running Linux Lab, please make sure the following command works without sudo and without any issue:
在运行 Linux Lab 之前，请确保无需 sudo 权限也可以正常运行以下命令：

    $ docker run hello-world

Othewise, please read the following notes and more [official docker docs](https://docs.docker.com).
否则，请阅读以下说明和更多 [官方 docker 文档](https://docs.docker.com)。

**Notes:**
**注意:**

In order to run docker without password, please make sure your user is added in the docker group and activate the change via newgrp:
为了避免在运行 docker 命令时需要输入管理员权限密码，请确保将您的用户帐号添加到 docker 组中：

    $ sudo usermod -aG docker $USER
    $ newgrp docker

In order to speedup docker images downloading, please configure a local docker mirror in `/etc/default/docker`, for example:
为了加速 docker 镜像的下载，请在 `/etc/default/docker` 文件中配置本地 docker mirror，举例如下：

    $ grep registry-mirror /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --registry-mirror=https://docker.mirrors.ustc.edu.cn"
    $ service docker restart

If still have errors like 'Client.Timeout exceeded while waiting headers', please try the other docker mirror sites:
如果在运行中仍然会遇到错误提示：'Client.Timeout exceeded while waiting headers'，请尝试其他的 docker mirrir 站点，譬如：

* Aliyun (Register Required): <http://t.cn/AiFxJ8QE>
* Aliyun (需要注册后才能使用): <http://t.cn/AiFxJ8QE>
* Docker China: https://registry.docker-cn.com

In order to avoid network ip address conflict, please try following changes and restart docker:
为避免网络 ip 地址冲突，尝试以下修改后再重启 docker 服务：

    $ grep bip /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --bip=10.66.0.10/16"
    $ service docker restart

If the above changes not work, try something as following:
如果以上措施还未解决您的问题，请尝试如下操作：

    $ grep dockerd /lib/systemd/system/docker.service
    ExecStart=/usr/bin/dockerd -H fd:// --bip=10.66.0.10/16 --registry-mirror=https://docker.mirrors.ustc.edu.cn
    $ service docker restart

For Ubuntu 12.04, please install the new kernel at first, otherwise, docker will not work:
如果您使用的是 Ubuntu 12.04， 请先安装新的内核版本，否则 docker 有可能无法工作：

    $ sudo apt-get install linux-generic-lts-trusty

## Choose a working directory
## <span id="choose-a-working-directory">选择工作目录</span>

If installed via Docker Toolbox, please enter into the `/mnt/sda1` directory of the `default` system on Virtualbox, otherwise, after poweroff, the data will be lost for the default `/root` directory is only mounted in DRAM.
如果您是通过 Docker Toolbox 安装，请在 Virtualbox 上进入 `default` 系统的 `/mnt/sda1`，否则，关机后所有数据会丢失，因为缺省的 `/root` 目录是挂载在内存中的。 

    $ cd /mnt/sda1

For Linux, please simply choose one directory in `~/Downloads` or `~/Documents`.
对于 Linux 用户，可以简单地在 `~/Downloads` 或者 `~/Documents` 下选择一个工作路径。

    $ cd ~/Documents

For Mac OSX, to compile Linux normally, please create a case sensitive filesystem as the working space at first:
对于 Mac OSX 用户，要正常编译 Linux，请首先创建一个区分大小写的文件系统作为工作空间：

    $ hdiutil -type SPARSE create -size 60g -fs "Case-sensitive Journaled HFS+" -volname labspace labspace.dmg
    $ hdiutil attach -mountpoint ~/Documents/labspace -no-browse labspace.dmg
    $ cd ~/Documents/labspace

## Download the lab
## <span id="download-the-lab">下载实验环境</span>

Use Ubuntu system as an example:
以 Ubuntu 系统为例:

Download cloud lab framework, pull images and checkout linux-lab repository:
下载 cloud lab，然后再选择 linux-lab 仓库

    $ git clone https://gitee.com/tinylab/cloud-lab.git
    $ cd cloud-lab/ && tools/docker/choose linux-lab

## Run and login the lab
## <span id="run-and-login-the-lab">运行并登录 Linux Lab</span>

Launch the lab and login with the user and password printed in the console:
启动 Linux Lab 并根据控制台上打印的用户名和密码登录实验环境：

    $ tools/docker/run linux-lab

Re-login the lab via web browser:
通过 web 浏览器重新登录实验环境：

    $ tools/docker/vnc linux-lab

The other login methods:
其他登录方式：

    $ tools/docker/webvnc linux-lab   # The same as tools/docker/vnc
    $ tools/docker/webssh linux-lab
    $ tools/docker/ssh linux-lab
    $ tools/docker/bash linux-lab

Summary of login methods:
登录方式的总结：

|   Login Method |   Description      |  Default User    |  Where               |
|----------------|--------------------|------------------|----------------------|
|   webvnc/vnc   | web desktop        |  ubuntu          | anywhere via internet|
|   webssh       | web ssh            |  ubuntu          | anywhere via internet|
|   ssh          | normal ssh         |  ubuntu          | localhost            |
|   bash         | docker bash        |  root            | localhost            |

|   登录方法     |   描述             |  缺省用户        |  登录所在地          |
|----------------|--------------------|------------------|----------------------|
|   webvnc/vnc   | web 桌面           |  ubuntu          | 互联网在线即可       |
|   webssh       | web ssh            |  ubuntu          | 互联网在线即可       |
|   ssh          | 普通 ssh           |  ubuntu          | 本地主机             |
|   bash         | docker bash        |  root            | 本地主机             |

## Update and rerun the lab
## <span id="update-and-rerun-the-lab">更新实验环境并重新运行</span>

If want a newer version, we **must** back up any local changes at first, and then update everything:
为了更新 Linux Lab 的版本，我们首先 **必须** 备份所有的本地修改，然后就可以执行更新了：

    $ tools/docker/update linux-lab

If fails, please try to clean up the containers:
如果更新失败，请尝试清理当前运行的容器:

    $ tools/docker/rm-full

Or even clean up the whole environments:
如果有必要的话清理整个环境:

   $ tools/docker/clean-all

## Quickstart: Boot a board
## <span id="quickstart-boot-a-board">快速上手：启动一个开发板</span>

Issue the following command to boot the prebuilt kernel and rootfs on the default `vexpress-a9` board:
输入如下命令在缺省的 `vexpress-a9` 开发板上启动预置的内核和根文件系统：

    $ make boot

Login as 'root' user without password(password is empty), just input 'root' and press Enter:
使用 'root' 帐号登录，不需要输入密码（密码为空），只需要输入 'root' 然后输入回车即可：

    Welcome to Linux Lab

    linux-lab login: root

    # uname -a
    Linux linux-lab 5.1.0 #3 SMP Thu May 30 08:44:37 UTC 2019 armv7l GNU/Linux

## Usage
## <span id="usage">使用说明</span>

### Using boards
### <span id="using-boards">使用开发板</span>

#### List available boards
#### <span id="list-available-boards">列出支持的开发板</span>

List builtin boards:
列出内置支持的开发板:

    $ make list
    [ aarch64/raspi3 ]:
          ARCH     = arm64
          CPU     ?= cortex-a53
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/mmcblk0
    [ aarch64/virt ]:
          ARCH     = arm64
          CPU     ?= cortex-a57
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/vda
    [ arm/versatilepb ]:
          ARCH     = arm
          CPU     ?= arm926t
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/ram0
    [ arm/vexpress-a9 ]:
          ARCH     = arm
          CPU     ?= cortex-a9
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/ram0
    [ i386/pc ]:
          ARCH     = x86
          CPU     ?= i686
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/ram0
    [ mipsel/malta ]:
          ARCH     = mips
          CPU     ?= mips32r2
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/ram0
    [ ppc/g3beige ]:
          ARCH     = powerpc
          CPU     ?= generic
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/ram0
    [ riscv32/virt ]:
          ARCH     = riscv
          CPU     ?= any
          LINUX   ?= v5.0.13
          ROOTDEV ?= /dev/vda
    [ riscv64/virt ]:
          ARCH     = riscv
          CPU     ?= any
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/vda
    [ x86_64/pc ]:
          ARCH     = x86
          CPU     ?= x86_64
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/ram0

#### Choosing a board
#### <span id="choosing-a-board">选择一个开发板</span>

By default, the default board: 'vexpress-a9' is used, we can configure, build and boot for a specific board with 'BOARD', for example:
系统缺省使用的开发板型号为 'vexpress-a9'，我们也可以自己配置，制作和使用其他的开发板，具体使用 'BOARD' 选项，举例如下：

    $ make BOARD=malta
    $ make boot

If using `board`, it only works on-the-fly, the setting will not be saved, this is helpful to run multiple boards at the same and not to disrupt each other:
如果使用的命令选项是小写的 `board`，这表明创建的开发板的配置不会被保存，提供该选项的目的是为了方便用户同时运行多个开发板而不会相互冲突。

    $ make board=malta boot

This allows to run multi boards in different terminals or background at the same time.
使用该命令允许在多个不同的终端中或者以后台方式同时运行多个开发板。

Check the board specific configuration:
检查开发板特定的配置：

    $ cat boards/arm/vexpress-a9/Makefile

#### Using as plugins
#### <span id="using-as-plugins">以插件方式使用</span>

The 'Plugin' feature is supported by Linux Lab, to allow boards being added and maintained in standalone git repositories. Standalone repository is very important to ensure Linux Lab itself not grow up big and big while more and more boards being added in.
Linux Lab 支持 “插件” 功能，允许在独立的 git 仓库中添加和维护开发板。采用独立的仓库维护可以确保 Linux Lab 在支持愈来愈多的开发板的同时自身的代码体积不会变得太大。

Book examples or the boards with a whole new cpu architecture benefit from such feature a lot, for book examples may use many boards and a new cpu architecture may need require lots of new packages (such as cross toolchains and the architecture specific qemu system tool).
该特性有助于支持基于 Linux Lab 学习一些书上的例子以及支持一些采用新的处理器体系架构的开发板，书籍中可能会涉及多个开发板或者是新的处理器架构，并可能会需要多个新的软件包（譬如交叉工具链和与体系架构相关的 qemu 的系统工具）。

Here maintains the available plugins:
这里列出当前维护的插件:

- [C-Sky Linux](https://gitee.com/tinylab/csky)
- [Loongson Linux](https://gitee.com/loongsonlab/loongson)
- [RLK4.0 Book Examples](https://gitee.com/tinylab/rlk4.0)
- [《奔跑吧 Linux 内核》例子代码实验](https://gitee.com/tinylab/rlk4.0)

### Downloading
### <span id="downloading">下载</span>

Download board specific package and the kernel, buildroot source code:
下载特定开发板的软件包、内核以及 buildroot 的源码：

    $ make core-source -j3

Download one by one:
如果需要单独下载这些部分：

    $ make bsp-source
    $ make kernel-source
    $ make root-source

### Checking out
### <span id="checking-out">检出</span>

Checkout the target version of kernel and builroot:
检出（checkout）你需要的 kernel 和 buildroot 版本：

    $ make checkout

Checkout them one by one:
单独检出相关部分:

    $ make kernel-checkout
    $ make root-checkout

If checkout not work due to local changes, save changes and run to get a clean environment:
如果由于本地更改而导致检出不起作用，请保存更改并运行清理以获取一个干净的环境：

    $ make kernel-cleanup
    $ make root-cleanup

The same to qemu and uboot.
以上操作也适用于 qemu 和 uboot。

### Patching
### <span id="patching">打补丁</span>

Apply available patches in `boards/<BOARD>/bsp/patch/linux` and `patch/linux/`:
给开发板打补丁，补丁包的来源是存放在 `boards/<BOARD>/bsp/patch/linux` 和 `patch/linux/` 路径下：

    $ make kernel-patch

### Configuration
### <span id="configuration">配置</span>

#### Default Configuration
#### <span id="default-configuration">缺省配置</span>

Configure kernel and buildroot with defconfig:
使用缺省配置（defconfig）配置 kernel 和 buildroot：

    $ make config

Configure one by one, by default, use the defconfig in `boards/<BOARD>/bsp/`:
单独配置，缺省情况下使用 `boards/<BOARD>/bsp/` 下的 defconfig：

    $ make kernel-defconfig
    $ make root-defconfig

Configure with kernel patching:
配置内核补丁：

    $ make kernel-defconfig KP=1
    $ make root-defconfig RP=1

Configure with specified defconfig:
使用特定的 defconfig 配置：

    $ make B=raspi3
    $ make kernel-defconfig KCFG=bcmrpi3_defconfig
    $ make root-defconfig KCFG=raspberrypi3_64_defconfig

If only defconfig name specified, search boards/<BOARD> at first, and then the default configs path of buildroot, u-boot and linux-stable respectivly: buildroot/configs, u-boot/configs, linux-stable/arch/<ARCH>/configs.
如果仅提供 defconfig 的名字，则搜索所在目录的次序依次为：首先 `boards/<BOARD>`，然后是 buildroot 的缺省配置路径 `buildroot/configs`，再次是 u-boot 的缺省配置路径 `u-boot/configs`，最后是 linux-stable 源码仓库的缺省配置路径 `linux-stable/arch/<ARCH>/configs`。

#### Manual Configuration
#### <span id="manual-configuration">手动配置</span>

    $ make kernel-menuconfig
    $ make root-menuconfig

#### Old default configuration
#### <span id="old-default-configuration">使用旧的缺省配置</span>

    $ make kernel-olddefconfig
    $ make root-olddefconfig
    $ make uboot-oldefconfig

### Building
### <span id="building">编译</span>

Build kernel and buildroot together:
一起编译 kernel 和 buildroot：

    $ make build

Build them one by one:
单独编译 kernel 和 buildroot:

    $ make kernel
    $ make root

### Saving
### <span id="saving">保存</span>

Save all of the configs and rootfs/kernel/dtb images:
保存所有的配置以及 rootfs/kernel/dtb 的 image 文件：

    $ make save

Save configs and images to `boards/<BOARD>/bsp/`:
保存配置和 image 文件到 `boards/<BOARD>/bsp/`：

    $ make kernel-saveconfig
    $ make root-saveconfig

    $ make root-save
    $ make kernel-save

### Booting
### <span id="booting">启动</span>

Boot with serial port (nographic) by default, exit with 'CTRL+a x', 'poweroff', 'reboot' or 'pkill qemu' (See [poweroff hang](#poweroff-hang)):
缺省情况下采用非图形界面的串口方式启动，如果要退出可以使用 'CTRL+a x', 'poweroff', 'reboot' 或者 'pkill qemu' 命令（具体参考 [“关机挂起问题”](#poweroff-hang)）

    $ make boot

Boot with graphic (Exit with 'CTRL+ALT+2 quit'):
图形方式启动 (如果要退出请使用 'CTRL+ALT+2 quit'):

    $ make b=pc boot G=1 LINUX=v5.1
    $ make b=versatilepb boot G=1 LINUX=v5.1
    $ make b=g3beige boot G=1 LINUX=v5.1
    $ make b=malta boot G=1 LINUX=v2.6.36
    $ make b=vexpress-a9 boot G=1 LINUX=v4.6.7 // LINUX=v3.18.39 works too

  **Note**: real graphic boot require LCD and keyboard drivers, the above boards work well, with linux v5.1,
  `raspi3` and `malta` has tty0 console but without keyboard input.
  **注意**：真正的图形化方式启动需要 LCD 和键盘驱动的支持，上述开发板可以完美支持 Linux 内核 5.1 版本的运行，`raspi3` 和 `malta` 两款开发板支持 tty0 终端但不支持键盘输入。

  `vexpress-a9` and `virt` has no LCD support by default, but for the latest qemu, it is able to boot
  with G=1 and switch to serial console via the 'View' menu, this can not be used to test LCD and
  keyboard drivers. `XOPTS` specify the eXtra qemu options.
  `vexpress-a9` 和 `virt` 缺省情况下不支持 LCD，但对于最新的 qemu，可以通过在启动时指定 `G=1` 参数然后通过选择 “View” 菜单切换到串口终端，但这么做无法用于测试 LCD 和键盘驱动。我们可以通过 `XOPTS` 选项指定额外的 qemu 选项参数。

    $ make b=vexpress-a9 CONSOLE=ttyAMA0 boot G=1 LINUX=v5.1
    $ make b=raspi3 CONSOLE=ttyAMA0 XOPTS="-serial vc -serial vc" boot G=1 LINUX=v5.1

Boot with curses graphic (friendly to ssh login, not work for all boards, exit with 'ESC+2 quit' or 'ALT+2 quit'):
基于 curses 图形方式启动（这么做适合采用 ssh 的登录方式，但不是对所有开发板都有效，退出时需要使用 'ESC+2 quit' 或 'ALT+2 quit'）

    $ make b=pc boot G=2

Boot with PreBuilt Kernel, Dtb and Rootfs (if no new available, simple use `make boot`):
使用预编译的内核、Dtb 和 Rootfs 启动（如果没有则直接使用 `make boot` 代替）

    $ make boot PBK=1 PBD=1 PBR=1
    or
    $ make boot k=0 d=0 r=0
    or
    $ make boot kernel=0 dtb=0 root=0

Boot with new kernel, dtb and rootfs if exists (if new available, simple use `make boot`):
使用新的内核、dtb 和 rootfs 启动（如果没有则直接使用 `make boot` 代替）

    $ make boot PBK=0 PBD=0 PBR=0
    or
    $ make boot k=1 d=1 r=1
    or
    $ make boot kernel=1 dtb=1 root=1

Boot without Uboot (only `versatilepb` and `vexpress-a9` boards tested):
使用 Uboot 启动（目前仅测试并支持了 `versatilepb` 和 `vexpress-a9` 两款开发板）：

    $ make boot U=0

Boot with different rootfs (depends on board, check `/dev/` after boot):
使用不同的 rootfs 启动（依赖于开发板的支持，启动后检查 `/dev/`）

    $ make boot ROOTDEV=/dev/ram      // support by all boards, basic boot method
    $ make boot ROOTDEV=/dev/nfs      // depends on network driver, only raspi3 not work
    $ make boot ROOTDEV=/dev/sda
    $ make boot ROOTDEV=/dev/mmcblk0
    $ make boot ROOTDEV=/dev/vda      // virtio based block device

Boot with extra kernel command line (XKCLI = eXtra Kernel Command LIne):
使用额外的内核命令行参数启动（格式：XKCLI = eXtra Kernel Command LIne）：

    $ make boot ROOTDEV=/dev/nfs XKCLI="init=/bin/bash"

List supported options:
列出支持的选项：

    $ make list-ROOTDEV
    $ make list-BOOTDEV
    $ make list-CCORI
    $ make list-NETDEV
    $ make list-LINUX
    $ make list-UBOOT
    $ make list-QEMU

And more 'xxx-list' are also supported with 'list-xxx', for example:
使用 'list-xxx' 可以实现更多 'xxx-list'，例如：

    $ make list-features
    $ make list-modules
    $ make list-gcc

### Using
### <span id="using">使用</span>

#### Linux
#### <span id="linux">Linux</span>

##### non-interactive configuration
##### <span id="non-interactive-configuration">非交互方式配置</span>

A tool named `scripts/config` in linux kernel is helpful to get/set the kernel
config options non-interactively, based on it, both of `kernel-getconfig`
and `kernel-setconfig` are added to tune the kernel options, with them, we
can simply "enable/disable/setstr/setval/getstate" of a kernel option or many
at the same time:
Linux 内核提供了一个脚本 `scripts/config`，可用于非交互方式获取或设置内核的配置选项值。基于该脚本，实验环境增加了两个选项 `kernel-getconfig` 和 `kernel-setconfig`，可用于调整内核的选项。基于该功能我们可以方便地实现类似 "enable/disable/setstr/setval/getstate" 内核选项的操作。

Get state of a kernel module:
获取一个内核模块的状态：

    $ make kernel-getconfig m=minix_fs
    Getting kernel config: MINIX_FS ...

    output/aarch64/linux-v5.1-virt/.config:CONFIG_MINIX_FS=m

Enable a kernel module:
使能一个内核模块：

    $ make kernel-setconfig m=minix_fs
    Setting kernel config: m=minix_fs ...

    output/aarch64/linux-v5.1-virt/.config:CONFIG_MINIX_FS=m

    Enable new kernel config: minix_fs ...

More control commands of `kernel-setconfig` including `y, n, c, o, s, v`:
更多 `kernel-setconfig` 命令的控制选项：`y, n, c, o, s, v`：

    `y`, build the modules in kernel or enable anther kernel options.
    `y`, 编译内核中的模块或者使能其他内核选项。
    `c`, build the modules as pluginable modules, just like `m`.
    `c`, 以插件方式编译内核模块，类似 `m` 选项。
    `o`, build the modules as pluginable modules, just like `m`.
    `o`, 以插件方式编译内核模块，类似 `m` 选项。
    `n`, disable a kernel option.
    `n`, 关闭一个内核选项。
    `s`, `RTC_SYSTOHC_DEVICE="rtc0"`, set the rtc device to rtc0
    `s`, `RTC_SYSTOHC_DEVICE="rtc0"`，设置 rtc 设备为 rtc0
    `v`, `v=PANIC_TIMEOUT=5`, set the kernel panic timeout to 5 secs.
    `v`, `v=PANIC_TIMEOUT=5`, 设置内核 panic 超时为 5 秒。

Operates many options in one command line:
在一条命令中使用多个选项：

    $ make kernel-setconfig m=tun,minix_fs y=ikconfig v=panic_timeout=5 s=DEFAULT_HOSTNAME=linux-lab n=debug_info
    $ make kernel-getconfig o=tun,minix,ikconfig,panic_timeout,hostname

##### using kernel modules
##### <span id="using-kernel-modules">使用内核模块</span>

Build all internel kernel modules:
编译所有的内部内核模块：

    $ make modules
    $ make modules-install
    $ make root-rebuild     // not need for nfs boot
    $ make boot

List available modules in `modules/`, `boards/<BOARD>/bsp/modules/`:
列出 `modules/` 和 `boards/<BOARD>/bsp/modules/` 路径下的所有模块：

    $ make module-list

If `m` argument specified, list available modules in `modules/`, `boards/<BOARD>/bsp/modules/` and `linux-stable/`:
如果加上 `m` 参数，除了列出 `modules/` 和 `boards/<BOARD>/bsp/modules/` 路径下的所有模块外，还会列出 `linux-stable/` 下的所有模块：

    $ make module-list m=hello
         1	m=hello ; M=$PWD/modules/hello
    $ make module-list m=tun,minix
         1	c=TUN ; m=tun ; M=drivers/net
         2	c=MINIX_FS ; m=minix ; M=fs/minix

Enable one kernel module:
使能一个内核模块：

    $ make kernel-getconfig m=minix_fs
    Getting kernel config: MINIX_FS ...

    output/aarch64/linux-v5.1-virt/.config:CONFIG_MINIX_FS=m

    $ make kernel-setconfig m=minix_fs
    Setting kernel config: m=minix_fs ...

    output/aarch64/linux-v5.1-virt/.config:CONFIG_MINIX_FS=m

    Enable new kernel config: minix_fs ...

Build one kernel module (e.g. minix.ko):
编译一个内核模块（例如：minix.ko）

    $ make module M=fs/minix/
    Or
    $ make module m=minix

Install and clean the module:
安装和清理模块：

    $ make module-install M=fs/minix/
    $ make module-clean M=fs/minix/

More flexible usage:
其他用法：

    $ make kernel-setconfig m=tun
    $ make kernel x=tun.ko M=drivers/net
    $ make kernel x=drivers/net/tun.ko
    $ make kernel-run drivers/net/tun.ko

Build external kernel modules (the same as internel modules):
编译外部内核模块（类似编译内部模块）：

    $ make module m=hello
    Or
    $ make kernel x=$PWD/modules/hello/hello.ko


##### using kernel features
##### <span id="using-kernel-features">使用内核特性</span>

Kernel features are abstracted in `feature/linux/, including their
configurations patchset, it can be used to manage both of the out-of-mainline
and in-mainline features.
内核的众多特性都集中存放在 `feature/linux/`，其中包括了特性的配置补丁，可以用于管理已合入内核主线的特性和未合入的特性功能。

    $ make feature-list
    [ feature/linux ]:
      + 9pnet
      + core
        - debug
        - module
      + ftrace
        - v2.6.36
          * env.g3beige
          * env.malta
          * env.pc
          * env.versatilepb
        - v2.6.37
          * env.g3beige
      + gcs
        - v2.6.36
          * env.g3beige
          * env.malta
          * env.pc
          * env.versatilepb
      + kft
        - v2.6.36
          * env.malta
          * env.pc
      + uksm
        - v2.6.38

Verified boards and linux versions are recorded there, so, it should work
without any issue if the environment not changed.
这里列出了针对某项特性验证时使用的内核版本，如果其他条件未改变的话该特性应该可以正常工作。

For example, to enable kernel modules support, simply do:
例如，为了使能内核模块支持，可以执行如下简单的操作：

    $ make feature f=module
    $ make kernel-olddefconfig
    $ make kernel

For `kft` feature in v2.6.36 for malta board:
为了在 malta 开发板上验证基于 2.6.36 版本的 `kft` 特性，可以执行如下操作：

    $ make BOARD=malta
    $ export LINUX=v2.6.36
    $ make kernel-checkout
    $ make kernel-patch
    $ make kernel-defconfig
    $ make feature f=kft
    $ make kernel-olddefconfig
    $ make kernel
    $ make boot

#### Uboot
#### <span id="uboot">Uboot</span>

Choose one of the tested boards: `versatilepb` and `vexpress-a9`.
从 `versatilepb` 和 `vexpress-a9` 中选择一个测试的开发板：

    $ make BOARD=vexpress-a9

Download Uboot:
下载 Uboot：

    $ make uboot-source

Checkout the specified version:
检出一个特定的版本：

    $ make uboot-checkout

Patching with necessary changes, `BOOTDEV` and `ROOTDEV` available, use `tftp` by default.
应用必要的补丁修改，可以指定 `BOOTDEV` 和 `ROOTDEV` 两个选项设置，如果不指定则缺省值使用 `tftp`。

    $ make uboot-patch

Use `tftp`, `sdcard` or `flash` explicitly, should run `make uboot-checkout` before a new `uboot-patch`:
如果要明确指定值为 `tftp`, `sdcard` 或者 `flash`，则必须在输入 `uboot-patch` 之前运行 `make uboot-checkout`：

    $ make uboot-patch BOOTDEV=tftp
    $ make uboot-patch BOOTDEV=sdcard
    $ make uboot-patch BOOTDEV=flash

  `BOOTDEV` is used to specify where to store and load the images for uboot, `ROOTDEV` is used to tell kernel where to load the rootfs.
  `BOOTDEV` 用于设定 uboot 的存放设备以便从该设备引导，`ROOTDEV` 用于告诉内核从哪里加载 rootfs。

Configure:
配置 U-boot：

    $ make uboot-defconfig
    $ make uboot-menuconfig

Building:
编译 U-boot：

    $ make uboot

Boot with `BOOTDEV` and `ROOTDEV`, use `tftp` by default:
使用 `BOOTDEV` 和 `ROOTDEV` 引导，缺省采用 `tftp` 方式：

    $ make boot U=1

Use `tftp`, `sdcard` or `flash` explicitly:
显式使用 `tftp`, `sdcard` 或者 `flash` 方式：

    $ make boot U=1 BOOTDEV=tftp
    $ make boot U=1 BOOTDEV=sdcard
    $ make boot U=1 BOOTDEV=flash

We can also change `ROOTDEV` during boot, for example:
我们也可以在启动引导阶段改变 `ROOTDEV` 选项，例如：

    $ make boot U=1 BOOTDEV=flash ROOTDEV=/dev/nfs

Clean images if want to update ramdisk, dtb and uImage:
执行清理，更新 ramdisk, dtb 和 uImage：

    $ make uboot-images-clean
    $ make uboot-clean

Save uboot images and configs:
保存 uboot 镜像和配置：

    $ make uboot-save
    $ make uboot-saveconfig

#### Qemu
#### <span id="qemu">Qemu</span>

Builtin qemu may not work with the newest linux kernel, so, we need compile and
add external prebuilt qemu, this has been tested on vexpress-a9 and virt board.
内置的 qemu 或许不能和最新的 Linux 内核配套工作，为此我们有时不得不自己编译 qemu，自行编译 qemu 的方法在 vexpress-a9 和 virt 开发板上已经验证通过。

At first, build qemu-system-ARCH:
首先，编译 qemu-system-ARCH：

    $ make B=vexpress-a9

    $ make qemu-download
    $ make qemu-checkout
    $ make qemu-patch
    $ make qemu-defconfig
    $ make qemu
    $ make qemu-save

qemu-ARCH-static and qemu-system-ARCH can not be compiled together. to build
qemu-ARCH-static, please enable `QEMU_US=1` in board specific Makefile and
rebuild it.
qemu-ARCH-static 和 qemu-system-ARCH 是不能一起编译的，为了制作 qemu-ARCH-static，请在开发板的 Makefile 中首先使能 `QEMU_US=1` 然后再重新编译。

If QEMU and QTOOL specified, the one in bsp submodule will be used in advance of
one installed in system, but the first used is the one just compiled if exists.
如果指定了 QEMU 和 QTOOL，那么实验环境会优先使用 bsp 子模块中的 QEMU 和 QTOOL，而不是已经安装在本地系统中的版本，但会优先使用最近编译和存在的版本。

While porting to newer kernel, Linux 5.0 hangs during boot on qemu 2.5, after
compiling a newer qemu 2.12.0, no hang exists. please take notice of such issue
in the future kernel upgrade.
在为新的内核实现移植时，如果使用 2.5 版本的 QEMU，Linux 5.0 在运行过程中会挂起，将 QEMU 升级到 2.12.0 后，问题消失。请在以后内核升级过程中注意相关的问题。

#### Toolchain
#### <span id="toolchain">Toolchain</span>

The pace of Linux mainline is very fast, builtin toolchains can not keep up, to
reduce the maintaining pressure, external toolchain feature is added. for
example, ARM64/virt, CCVER and CCPATH has been added for it.
Linux 内核主线的升级非常迅速，内置的工具链无法与其保持同步，为了减少维护上的压力，环境支持添加外部工具链。譬如 ARM64/virt, CCVER 和 CCPATH。

List available prebuilt toolchains:
列出支持的预编译工具链：

    $ make gcc-list

Download, decompress and enable the external toolchain:
下载，解压缩和使能外部工具链：

    $ make gcc

Switch compiler version if exists, for example:
切换编译器版本，例子如下：

    $ make gcc-switch CCORI=internal GCC=4.7

    $ make gcc-switch CCORI=linaro

If not external toolchain there, the builtin will be used back.
如果未指定外部工具链，则缺省使用内置的工具链。

If no builtin toolchain exists, please must use this external toolchain feature, currently, aarch64, arm, riscv, mipsel, ppc, i386, x86_64 support such feature.
如果不存在内置的工具链，则必须指定外部工具链。当前对该特性已经支持 aarch64, arm, riscv, mipsel, ppc, i386, x86_64 多个体系架构。

GCC version can be configured in board specific Makefile for Linux, Uboot, Qemu and Root, for example:
GCC 的版本可以分别在开发板特定的 Makefile 中针对 Linux, Uboot, Qemu 和 Root 分别指定：

    GCC[LINUX_v2.6.11.12] = 4.4

With this configuration, GCC will be switched automatically during defconfig and compiling of the specified Linux v2.6.11.12.
采用以上配置方法，在编译 v2.6.11.12 版本的 Linux 内核时会在 defconfig 时自动切换为使用指定的 GCC 版本。

To build host tools, host gcc should be configured too(please specify b=`i386/pc` explicitly):
在编译主机（host）的工具链时，也需要做相应配置（需要显式指定 b=`i386/pc`）：

    $ make gcc-list b=i386/pc
    $ make gcc-switch CCORI=internal GCC=4.8 b=i386/pc

#### Rootfs
#### <span id="rootfs">Rootfs</span>

Builtin rootfs is minimal, is not enough for complex application development,
which requires modern Linux distributions.
内置的 rootfs 很小，不足以应付复杂的应用开发，如果需要涉及高级的应用开发，需要使用现代的 Linux 发布包。

Such a type of rootfs has been introduced and has been released as docker
image, ubuntu 18.04 is added for arm32v7 at first, more later.
环境提供了针对 arm32v7 的 ubuntu 18.04 的根文件系统，该文件系统已经制作成 docker 镜像，以后有机会再提供更多更好的文件系统。

Run it via docker directly:
可以通过 docker 直接使用：

    $ docker run -it tinylab/arm32v7-ubuntu

Extract it out and run in Linux Lab:
可以将文件系统提取出来在 Linux Lab 中使用：

  ARM32/vexpress-a9:

    $ tools/rootfs/docker/extract.sh tinylab/arm32v7-ubuntu arm
    $ make boot B=vexpress-a9 U=0 V=1 MEM=1024M ROOTDEV=/dev/nfs ROOTFS=$PWD/prebuilt/fullroot/tmp/tinylab-arm32v7-ubuntu

  ARM64/raspi3:

    $ tools/rootfs/docker/extract.sh tinylab/arm64v8-ubuntu arm
    $ make boot B=raspi3 V=1 ROOTDEV=/dev/mmcblk0 ROOTFS=$PWD/prebuilt/fullroot/tmp/tinylab-arm64v8-ubuntu

More rootfs from docker can be found:
其他 docker 中更多的根文件系统：

    $ docker search arm64 | egrep "ubuntu|debian"
    arm64v8/ubuntu   Ubuntu is a Debian-based Linux operating system  25
    arm64v8/debian   Debian is a Linux distribution that's composed  20

### Debugging
### <span id="debugging">调试</span>

Compile the kernel with debugging options:
使用调试选项编译内核：

    $ make feature f=debug
    $ make kernel-olddefconfig
    $ make kernel

Compile with one thread:
编译时使用一个线程：

    $ make kernel JOBS=1

And then debug it directly:
运行如下命令直接调试：

    $ make debug

It will open a new terminal, load the scripts from .gdbinit, run gdb automatically.
将打开一个新的终端窗口，从 `.gdbinit` 加载脚本，自动运行 gdb。

It equals to:
以上命令等价于运行如下命令：

   $ make boot DEBUG=1

to automate debug testing:
自动调试测试可以运行如下命令：

   $ make test DEBUG=1

### Testing
### <span id="testing">测试</span>

Use 'aarch64/virt' as the demo board here.
以 'aarch64/virt' 作为演示的开发板：

    $ make BOARD=virt

Prepare for testing, install necessary files/scripts in `system/`:
为测试做准备，在 `system/` 目录下安装必要的文件/脚本：

    $ make rootdir
    $ make root-install
    $ make root-rebuild

Simply boot and poweroff (See [poweroff hang](#poweroff-hang)):
直接引导启动（参考 [“关机挂起问题”](#poweroff-hang)）

    $ make test

Don't poweroff after testing:
测试完毕后不要关机：

    $ make test TEST_FINISH=echo

Run guest test case:
运行一下客户机的测试用例：

    $ make test TEST_CASE=/tools/ftrace/trace.sh

Run guest test cases (`COMMAND_LINE_SIZE` must be big enough, e.g. 4096, see `cmdline_size` feature below):
运行客户机的测试用例（`COMMAND_LINE_SIZE` 必须足够大，譬如，4096，查看下文的 `cmdline_size` 特性 ）

    $ make test TEST_BEGIN=date TEST_END=date TEST_CASE='ls /root,echo hello world'

Reboot the guest system for several times:
多次重启客户机系统：

    $ make test TEST_REBOOT=2
    
    NOTE: reboot may 1) hang, 2) continue; 3) timeout killed, TEST_TIMEOUT=30; 4) timeout continue, TIMEOUT_CONTINUE=1
    注意: reboot 可以有以下几种选项 1) 挂起, 2) 继续; 3) 超时后被杀死, TEST_TIMEOUT=30; 4) 继续超时, TIMEOUT_CONTINUE=1

Test a feature of a specified linux version on a specified board(`cmdline_size` feature is for increase `COMMAND_LINE_SIZE` to 4096):
在一个特定的开发板上测试一个特定的 Linux 版本的某个功能（`cmdline_size` 特性用于增加 `COMMAND_LINE_SIZE` 为 4096）：

    $ make test f=kft LINUX=v2.6.36 b=malta TEST_PREPARE=board-init,kernel-cleanup
    
  NOTE: `board-init` and `kernel-cleanup` make sure test run automatically, but `kernel-cleanup` is not safe, please save your code before use it!!
        To cleanup all of root,uboot,qemu and kernel, please use `cleanup` instead.
  注意：`board-init` 和 `kernel-cleanup` 用于确保测试自动运行，但是 `kernel-cleanup` 不安全，请在使用前保存代码！
        要清除所有的 root，uboot，qemu 和 kernel，请改用 `cleanup`。

Test a kernel module:
测试一个内核模块：

    $ make test m=hello

Test multiple kernel modules:
测试多个内核模块：

    $ make test m=exception,hello

Test modules with specified ROOTDEV, nfs boot is used by default, but some boards may not support network:
基于指定的 ROOTDEV 测试模块，缺省使用 nfs 引导方式，但注意有些开发板可能不支持网络：

    $ make test m=hello,exception TEST_RD=/dev/ram0

Run test cases while testing kernel modules (test cases run between insmod and rmmod):
在测试内核模块是运行测试用例（在 insmod 和 rmmod 命令之间运行测试用例）：

    $ make test m=exception TEST_BEGIN=date TEST_END=date TEST_CASE='ls /root,echo hello world' TEST_PREPARE=board-init,kernel-cleanup f=cmdline_size

Run test cases while testing internal kernel modules:
在测试内部内核模块时运行测试用例：

    $ make test m=lkdtm TEST_BEGIN='mount -t debugfs debugfs /mnt' TEST_CASE='echo EXCEPTION ">" /mnt/provoke-crash/DIRECT'

Run test cases while testing internal kernel modules, pass kernel arguments:
在测试内部内核模块时运行测试用例，传入内核参数：

    $ make test m=lkdtm lkdtm_args='cpoint_name=DIRECT cpoint_type=EXCEPTION'

Run test without feature-init (save time if not necessary, FI=`FEATURE_INIT`):
测试时不使用 feature-init （若非必须可以节省时间，FI=`FEATURE_INIT`）

    $ make test m=lkdtm lkdtm_args='cpoint_name=DIRECT cpoint_type=EXCEPTION' FI=0
    Or
    或者
    $ make raw-test m=lkdtm lkdtm_args='cpoint_name=DIRECT cpoint_type=EXCEPTION'

Run test with module and the module's necessary dependencies (check with `make kernel-menuconfig`):
测试模块以及模块的依赖（使用 `make kernel-menuconfig` 进行检查）：

    $ make test m=lkdtm y=runtime_testing_menu,debug_fs lkdtm_args='cpoint_name=DIRECT cpoint_type=EXCEPTION'

Run test without feature-init, boot-init, boot-finish and no `TEST_PREPARE`:
测试时不使用 feature-init，boot-init，boot-finish 以及不带 `TEST_PREPARE`：

    $ make boot-test m=lkdtm lkdtm_args='cpoint_name=DIRECT cpoint_type=EXCEPTION'

Test a kernel module and make some targets before testing:
测试一个内核模块并且在测试前制作一些目标板：

    $ make test m=exception TEST=kernel-checkout,kernel-patch,kernel-defconfig

Test everything in one command (from download to poweroff, see [poweroff hang](#poweroff-hang)):
使用一条命令测试所有功能（从下载到关机，参考 [“关机挂起问题”](#poweroff-hang)）：

    $ make test TEST=kernel,root TEST_PREPARE=board-init,cleanup

Test everything in one command (with uboot while support, e.g. vexpress-a9):
使用一条命令测试所有功能（带 uboot，如果支持的话，譬如：vexpress-a9）：

    $ make test TEST=kernel,root,uboot TEST_PREPARE=board-init,cleanup

Test kernel hang during boot, allow to specify a timeout, timeout must happen while system hang:
测试引导过程中内核挂起，允许指定超时，超时时间必须在系统挂起时发生：

    $ make test TEST_TIMEOUT=30s

Test kernel debug:
测试内核调试：

    $ make test DEBUG=1

### Sharing
### <span id="sharing">共享</span>

To transfer files between Qemu Board and Host, three methods are supported by
default:
缺省支持三种方法在 Qemu 开发板和主机之间传输文件：

#### Install files to rootfs
#### <span id="install-files-to-rootfs">在 rootfs 中安装文件</span>

Simply put the files with a relative path in `system/`, install and rebuild the rootfs:
将文件放在 `system/` 的相对路径中，安装和重新制作 rootfs：

    $ cd system/
    $ mkdir system/root/
    $ touch system/root/new_file
    $ make root-install
    $ make root-rebuild
    $ make boot G=1

#### Share with NFS
#### <span id="share-with-nfs">采用 NFS 共享文件</span>

Boot the board with `ROOTDEV=/dev/nfs`,
使用 `ROOTDEV=/dev/nfs` 选项启动开发板，

Boot/Qemu Board:
启动/Qemu 开发板：

    $ make boot ROOTDEV=/dev/nfs

Host:
主机：

    $ make env-dump | grep ROOTDIR
    ROOTDIR = /linux-lab/<BOARD>/bsp/root/<BUILDROOT_VERSION>/rootfs

#### Transfer via tftp
#### <span id="transfer-via-tftp">通过 tftp 传输文件</span>

Using tftp server of host from the Qemu board with the `tftp` command.
在 Qemu 开发板上运行 `tftp` 命令访问主机的 tftp 服务器。

Host:
主机侧：

    $ ifconfig br0
    inet addr:172.17.0.3  Bcast:172.17.255.255  Mask:255.255.0.0
    $ cd tftpboot/
    $ ls tftpboot
    kft.patch kft.log

Qemu Board:
Qemu 开发板：

    $ ls
    kft_data.log
    $ tftp -g -r kft.patch 172.17.0.3
    $ tftp -p -r kft.log -l kft_data.log 172.17.0.3

**Note**: while put file from Qemu board to host, must create an empty file in host firstly. Buggy?
注意：当把文件从 Qemu 开发板发送到主机侧时，必须先在主机上创建一个空的文件，这是一个 bug？

#### Share with 9p virtio
#### <span id="share-with-9p-virtio">通过 9p virtio 共享文件</span>

To enable 9p virtio for a new board, please refer to [qemu 9p setup](https://wiki.qemu.org/Documentation/9psetup). qemu must be compiled with `--enable-virtfs`, and kernel must enable the necessary options.
有关如何为一个新的开发板启用 9p virtio，请参考 [qemu 9p setup](https://wiki.qemu.org/Documentation/9psetup)。编译 qemu 时必须使用 `--enable-virtfs` 选项，同时内核必须打开必要的选项。 

Reconfigure the kernel with:
重新配置内核如下：

    CONFIG_NET_9P=y
    CONFIG_NET_9P_VIRTIO=y
    CONFIG_NET_9P_DEBUG=y (Optional)
    CONFIG_9P_FS=y
    CONFIG_9P_FS_POSIX_ACL=y
    CONFIG_PCI=y
    CONFIG_VIRTIO_PCI=y
    CONFIG_PCI_HOST_GENERIC=y (only needed for the QEMU Arm 'virt' board)

  If using `-virtfs` or `-device virtio-9p-pci` option for qemu, must enable the above PCI related options, otherwise will not work:
  如果需要使用 qemu 的 `-virtfs` 或者 `-device virtio-9p-pci` 选项，需要使能以上 PCI 相关的选项，否则无法工作：

    9pnet_virtio: no channels available for device hostshare
    mount: mounting hostshare on /hostshare failed: No such file or directory'

  `-device virtio-9p-device` requires less kernel options.
  `-device virtio-9p-device` 需要较少的内核选项。

  To enable the above options, please simply type:
  为了使能以上选项，请输入以下命令：

   $ make feature f=9pnet
   $ make kernel-olddefconfig

Docker host:
Docker 主机：

    $ modprobe 9pnet_virtio
    $ lsmod | grep 9p
    9pnet_virtio           17519  0
    9pnet                  72068  1 9pnet_virtio

Host:
主机：

    $ make BOARD=virt

    $ make root-install	       # Install mount/umount scripts, ref: system/etc/init.d/S50sharing
    $ make root-rebuild

    $ touch hostshare/test     # Create a file in host

    $ make boot U=0 ROOTDEV=/dev/ram0 PBR=1 SHARE=1

    $ make boot SHARE=1 SHARE_DIR=modules   # for external modules development

    $ make boot SHARE=1 SHARE_DIR=output/aarch64/linux-v5.1-virt/   # for internal modules learning

    $ make boot SHARE=1 SHARE_DIR=examples   # for c/assembly learning

Qemu Board:
Qemu 开发板：

    $ ls /hostshare/       # Access the file in guest
    test
    $ touch /hostshare/guest-test   # Create a file in guest


Verified boards with Linux v5.1:
使用 Linux v5.1 验证开发板：

    aarch64/virt: virtio-9p-device (virtio-9p-pci breaks nfsroot)
    arm/vexpress-a9: only work with virtio-9p-device and without uboot booting
    arm/versatilepb: only work with virtio-9p-pci
    x86_64/pc, only work with virtio-9p-pci
    i386/pc, only work with virtio-9p-pci
    riscv64/virt, work with virtio-9p-pci and virtio-9p-dev
    riscv32/virt, work with virtio-9p-pci and virtio-9p-dev

## More
## <span id="more">更多</span>

### Add a new board
### <span id="add-a-new-board">添加一个新的开发板</span>

#### Choose a board supported by qemu
#### <span id="choose-a-board-supported-by-qemu">选择一个 qemu 支持的开发板</span>

list the boards, use arm as an example:
列出支持的开发板，以 arm 架构为例：

    $ qemu-system-arm -M ?

#### Create the board directory
#### <span id="create-the-board-directory">创建开发板的目录</span>

Use `vexpress-a9` as an example:
以 `vexpress-a9` 为例：

    $ mkdir boards/arm/vexpress-a9/

#### Clone a Makefile from an existing board
#### <span id="clone-a-makefile-from-an-existing-board">从一个已经支持的开发板中复制一份 Makefile</span>

Use `versatilepb` as an example:
以 `versatilepb` 为例：

    $ cp boards/arm/versatilebp/Makefile boards/arm/vexpress-a9/Makefile

#### Configure the variables from scratch
#### <span id="configure-the-variables-from-scratch">从头开始配置变量</span>

Comment everything, add minimal ones and then others.
为所有的修改添加注释，确保每次修改量不要太大，以及其他。

Please refer to `doc/qemu/qemu-doc.html` or the online one `http://qemu.weilnetz.de/qemu-doc.html`.
具体参考 `doc/qemu/qemu-doc.html` 或者在线说明 `http://qemu.weilnetz.de/qemu-doc.html`。

#### At the same time, prepare the configs
#### <span id="at-the-same-time,-prepare-the-configs">同时准备 configs 文件</span>

We need to prepare the configs for linux, buildroot and even uboot.
我们需要为 Linux，buildroot 甚至 uboot 准备 config 文件。

Buildroot has provided many examples about buildroot and kernel configuration:
Buildroot 已经为 buildroot 和内核配置提供了许多例子：

* buildroot: `buildroot/configs/qemu_ARCH_BOARD_defconfig`
* kernel: `buildroot/board/qemu/ARCH-BOARD/linux-VERSION.config`

Uboot has also provided many default configs:
Uboot 也提供了许多缺省的配置文件：

* uboot: `u-boot/configs/vexpress_ca9x4_defconfig`

Kernel itself also:
内核本身也提供了缺省的配置：

* kernel: `linux-stable/arch/arm/configs/vexpress_defconfig`

Linux Lab itself also provide many working configs too, the `-clone` target is a
good helper to utilize existing configs:
Linux Lab 本身也提供许多有效的配置，`-clone` 命令有助于利用现有的配置：

    $ make list-kernel
    v4.12 v5.0.10 v5.1
    $ make kernel-clone LINUX=v5.1 LINUX_NEW=v5.4
    $ make kernel-menuconfig
    $ make kernel-saveconfig

    $ make list-root
    2016.05 2019.02.2
    $ make root-clone BUILDROOT=2019.02.2 BUILDROOT_NEW=2019.11
    $ make root-menuconfig
    $ make root-saveconfig

Edit the configs and Makefile untill they match our requirements.
编辑配置文件和 Makefile 直到它们满足我们的需要。

    $ make kernel-menuconfig
    $ make root-menuconfig
    $ make board-edit

The configuration must be put in `boards/<BOARD>/` and named with necessary
version and arch info, use `raspi3` as an example:
配置文件必须放在 `boards/<BOARD>/` 目录下并且在命名上需要注明必要的版本和架构信息，以 `raspi3` 为例：

    $ make kernel-saveconfig
    $ make root-saveconfig
    $ ls boards/aarch64/raspi3/bsp/configs/
    buildroot_2019.02.2_defconfig  linux_v5.1_defconfig

`2019.02.2` is the buildroot version, `v5.1` is the kernel version, both of these
variables should be configured in `boards/<BOARD>/Makefile`.
`2019.02.2` 是 buildroot 的版本，`v5.1` 是内核版本，这两个变量需要在 `boards/<BOARD>/Makefile` 中设置好。

#### Choose the versions of kernel, rootfs and uboot
#### <span id="choose-the-versions-of-kernel,-rootfs-and-uboot">选择 kernel，rootfs 和 uboot 的版本</span>

Please use 'tag' instead of 'branch', use kernel as an example:
检出版本时请使用 'tag' 命令而非 'branch' 命令，以 kernel 为例：

    $ cd linux-stable
    $ git tag
    ...
    v5.0
    ...
    v5.1
    ..
    v5.1.1
    v5.1.5
    ...

If want v5.1 kernel, just put a line "LINUX = v5.1" in `boards/<BOARD>/Makefile`.
如果我们需要的是 v5.1 的 kernel，那么可以在 `boards/<BOARD>/Makefile` 添加一行："LINUX = v5.1"

Or clone a kernel config from the old one or the official defconfig:
或者从旧的版本或者是官方的 defconfig 文件中复制一份内核的配置：

    $ make kernel-clone LINUX_NEW=v5.3 LINUX=v5.1

    Or
    或者

    $ make B=i386/pc
    $ pushd linux-stable && git checkout v5.4 && popd
    $ make kernel-clone LINUX_NEW=v5.4 KCFG=i386_defconfig

If no tag existed, a virtual tag name with the real commmit number can be configured as following:
如果不存在对应的 tag，可以直接使用 commit 号同时为它模拟一个 tag 名字，配置方法如下：

    LINUX = v2.6.11.12
    LINUX[LINUX_v2.6.11.12] = 8e63197f

    # The real commit number
    LINUX_COMMIT = $(call _v,LINUX,LINUX)

Linux version specific ROOTFS are also supported:
可以配置和 Linux 版本对应的 ROOTFS：

    ROOTFS[LINUX_v2.6.12.6]  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs32.cpio.gz

#### Configure, build and boot them
#### <span id="configure,-build-and-boot-them">配置，编译和启动</span>

Use kernel as an example:
以 kernel 为例：

    $ make kernel-defconfig
    $ make kernel-menuconfig
    $ make kernel
    $ make boot

The same to rootfs, uboot and even qemu.
同样的方法适用于 rootfs，uboot，甚至 qemu。

#### Save the images and configs
#### <span id="save-the-images-and-configs">保存生成的镜像文件和配置文件</span>

    $ make root-save
    $ make kernel-save
    $ make uboot-save

    $ make root-saveconfig
    $ make kernel-saveconfig
    $ make uboot-saveconfig

#### Upload everything
#### <span id="upload-everything">上传所有工作</span>

At last, upload the images, defconfigs, patchset to board specific bsp submodule repository.
最后，将 images、defconfigs、patchset 上传到开发板特定的 bsp 子模块仓库。

Firstly, get the remote bsp repository address as following:
首先，获取远端 bsp 仓库的地址，方法如下：

    $ git remote show origin
    * remote origin
      Fetch URL: https://gitee.com/tinylab/qemu-aarch64-raspi3/
      Push  URL: https://gitee.com/tinylab/qemu-aarch64-raspi3/
      HEAD branch: master
      Remote branch:
        master tracked
      Local branch configured for 'git pull':
        master merges with remote master
      Local ref configured for 'git push':
        master pushes to master (local out of date)

Then, fork this repository from gitee.com, upload your changes, and send your pull request.
然后，在 gitee.com 上 fork 这个仓库，上传你的修改，然后发送你的 pull request。 

### Learning Assembly
### <span id="learning-assembly">学习汇编</span>

Linux Lab has added many assembly examples in `examples/assembly`:
Linux Lab 在 `examples/assembly` 目录下有许多汇编代码的例子：

    $ cd examples/assembly
    $ ls
    aarch64  arm  mips64el	mipsel	powerpc  powerpc64  README.md  x86  x86_64
    $ make -s -C aarch64/
    Hello, ARM64!

### Running any make goals
### <span id="running-any-make-goals">运行任意的 make 目标</span>

Linux Lab allows to access Makefile goals easily via `xxx-run`, for example:
Linux Lab 支持通过形如 `xxx-run` 方式访问 Makefile 中定义的目标，譬如：

    $ make kernel-run help
    $ make kernel-run menuconfig

    $ make root-run help
    $ make root-run busybox-menuconfig

    $ make uboot-run help
    $ make uboot-run menuconfig

  `-run` goals allows to run sub-make goals of kernel, root and uboot directly without entering into their own building directory.
  执行这些带有 `-run` 的目标允许我们无需进入相关的构造目录就可以直接运行这些 make 目标来制作 kernel、rootfs 和 uboot。


## FAQs
## <span id="faqs">常见问题</span>

### Poweroff hang
### <span id="poweroff-hang">关机挂起问题</span>

Both of the 'poweroff' and 'reboot' commands not work on these boards currently (LINUX=v5.1):
当前对以下开发板，基于内核版本 5.1（LINUX=v5.1），'poweroff' 和 'reboot' 命令无法正常工作：

  * mipsel/malta (exclude LINUX=v2.6.36)
  * aarch64/raspi3
  * arm/versatilepb

System will directly hang there while running 'poweroff' or 'reboot', to exit qemu, please pressing 'CTRL+a x' or using 'pkill qemu'.
在运行 'poweroff' 或者 'reboot' 时，系统会直接挂起，为了退出 qemu，请使用 'CTRL+a x' 或者执行 shell 命令 'pkill qemu'。

To test such boards automatically, please make sure setting 'TEST_TIMEOUT', e.g. `make test TEST_TIMEOUT=50`.
为了自动化测试这些开发板，请确保设置 'TEST_TIMEOUT'，例如：`make test TEST_TIMEOUT=50`。

Welcome to fix up them.
欢迎提供修复意见。

### Boot with missing sdl2 libraries failure
### <span id="boot-with-missing-sdl2-libraries-failure">引导时报缺少 sdl2 库</span>

That's because the docker image is not updated, just rerun the lab (please must not use 'tools/docker/restart' here for it not using the new docker image):
这是由于 docker 的 image 没有更新导致，解决的方法是重新运行 lab（这里不要使用 'tools/docker/restart'，因为并没有使用新的 docker image）：

    $ tools/docker/pull linux-lab
    $ tools/docker/rerun linux-lab

    Or
    或者

    $ tools/docker/update linux-lab

With 'tools/docker/update', every docker images and source code will be updated, it is preferred.
使用 'tools/docker/update'，所有的 docker images 和源码都会被更新，这是推荐的做法。

### NFS/tftpboot not work
### <span id="nfstftpboot-not-work">NFS/tftpboot 不工作</span>

If nfs or tftpboot not work, please run `modprobe nfsd` in host side and restart the net services via `/configs/tools/restart-net-servers.sh` and please
make sure not use `tools/docker/trun`.
如果 nfs 或 tftpboot 不起作用，请在主机端运行 `modprobe nfsd` 并通过运行 `/configs/tools/restart-net-servers.sh` 重新启动网络服务，请确保不要使用 `tools/docker/trun`。

### Run tools without sudo
### <span id="run-tools-without-sudo">不使用 sudo 运行 tools 命令</span>

To use the tools under `tools` without sudo, please make sure add your account to the docker group and reboot your system to take effect:
如果需要在不使用 sudo 的情况下执行 `tools' 目录下的命令，请确保将您的帐户添加到 docker 组并重新启动系统以使其生效：

    $ sudo usermod -aG docker $USER

### Speed up docker images downloading
### <span id="speed-up-docker-images-downloading">加快 docker images 下载的速度</span>

To optimize docker images download speed, please edit `DOCKER_OPTS` in `/etc/default/docker` via referring to `tools/docker/install`.
为了优化 Docker 镜像的下载速度，请参考 `tools/docker/install` 脚本的内容编辑 `/etc/default/docker` 中的 `DOCKER_OPTS`。

### Docker network conflicts with LAN
### <span id="docker-network-conflicts-with-lan">Docker 的网络与 LAN 冲突</span>

We assume the docker network is `10.66.0.0/16`, if not, we'd better change it as following:
假设 docker 网络为 `10.66.0.0/16`，否则，最好采用如下方式对其进行更改：

    $ sudo vim /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --bip=10.66.0.10/16"

    $ sudo vim /lib/systemd/system/docker.service
    ExecStart=/usr/bin/dockerd -H fd:// --bip=10.66.0.10/16

Please restart docker service and lab container to make this change works:
请重新启动 docker 服务和 lab 容器以使更改生效：

    $ sudo service docker restart
    $ tools/docker/rerun linux-lab

If lab network still not work, please try another private network address and eventually to avoid conflicts with LAN address.
如果 Linux Lab 的网络仍然无法正常工作，请尝试使用另一个专用网络地址，并最终避免与 LAN 地址冲突。

### Why not allow running Linux Lab in local host
### <span id="why-not-allow-running-linux-lab-in-local-host">为何不支持在本地主机上直接运行 Linux Lab</span>

The full function of Linux Lab depends on the full docker environment managed by [Cloud Lab](http://tinylab.org/cloud-lab), so, please really never try and therefore please don't complain about why there are lots of packages missing failures and even the other weird issues.
Linux Lab 的完整功能依赖于 [Cloud Lab]（http://tinylab.org/cloud-lab）所管理的完整 docker 环境，因此，请切勿尝试脱离 [Cloud Lab]（http://tinylab.org/cloud-lab）在本地主机上直接运行 Linux Lab，否则系统会报告缺少很多依赖软件包以及其他奇怪的错误。

Linux Lab is designed to use pre-installed environment with the docker technology and save our life by avoiding the packages installation issues in different systems, so, Linux Lab would never support local host using even in the future.
Linux Lab 的设计初衷是旨在通过利用 docker 技术使用预先安装好的环境来避免在不同系统中的软件包安装问题，从而加速我们上手的时间，因此 Linux Lab 暂无计划支持在本地主机环境下使用。

### Why kvm speedding up is disabled
### <span id="why-kvm-speedding-up-is-disabled">为何不支持 kvm 加速</span>

kvm only supports both of qemu-system-i386 and qemu-system-x86_64 currently, and it also requires the cpu and bios support, otherwise, you may get this error log:
kvm 当前仅支持 qemu-system-i386 和 qemu-system-x86_64，并且还需要 cpu 和 bios 支持，否则，您可能会看到以下错误日志：

    modprobe: ERROR: could not insert 'kvm_intel': Operation not supported

Check cpu virtualization support, if nothing output, then, cpu not support virtualization:
检查 cpu 的虚拟化支持能力，如果没有输出，则说明 cpu 不支持虚拟化：

    $ cat /proc/cpuinfo | egrep --color=always "vmx|svm"

If cpu supports, we also need to make sure it is enabled in bios features, simply reboot your computer, press 'Delete' to enter bios, please make sure the 'Intel virtualization technology' feature is 'enabled'.
如果 cpu 支持，我们还需要确保在 BIOS 中启用了该功能，只需重新启动计算机，按 “Delete” 键进入 BIOS，请确保 “Intel virtualization technology” 功能已启用。

### How to switch windows in vim
### <span id="how-to-switch-windows-in-vim">如何在 vim 中切换窗口</span>

`CTRL+w` is used in both of browser and vim, to switch from one window to another, please use 'CTRL+Left' or 'CTRL+Right' key instead, Linux Lab has remapped 'CTRL+Right' to `CTRL+w` and 'CTRL+Left' to `CTRL+p`.
浏览器和 vim 中都使用了 `CTRL+w`，要从一个窗口切换到另一个窗口，请改用 `CTRL+Left` 或 `CTRL+Right` 键，Linux Lab 已将 `CTRL+Right` 映射为 `CTRL+w`，将 `CTRL+Left` 映射为 `CTRL+p`。

### How to delete typo in shell command line
### <span id="how-to-delete-typo-in-shell-command-line">如何删除 shell 命令行中打错的字</span>

Long keypress not work in novnc client currently, so, long 'Delete' not work, please use 'alt+delete' or 'alt+backspace' instead, more tips:
长按键目前在 novnc 客户端中不起作用，因此，长按 “Delete” 键不起作用，请改用 “alt+delete” 或 “alt+backspace” 组合键，以下是更多有关组合键的小技巧：

* Bash
  * ctrl+a/e (begin/end)
  * ctrl+a/e (光标重定位到命令行首/末位置)
  * ctrl+home/end (forward/backward)
  * ctrl+home/end (向前/后退跳过一个单词)
  * alt+delete/backspace (delete one word backward)
  * alt+delete/backspace (反向删除一个单词)
  * alt+d (delete one word forward)
  * alt+d (正向删除一个单词)
  * ctrl+u/k (delete all to begin, delete all to end)
  * ctrl+u/k (删除从当前位置到行首/行尾的所有字符)
* Vim
  * ^/$ (begin/end)
  * ^/$ (光标重定位到命令行首/末位置)
  * w/b; ctrl+home/end (forward/backward)
  * w/b; ctrl+home/end (向前/后退跳过一个单词)
  * db (delete one word backward)
  * db (反向删除一个单词)
  * dw (delete one word forward)
  * dw (正向删除一个单词)
  * d^/d$ (delete all to begin, delete all to end)
  * d^/d$ (删除从当前位置到行首/行尾的所有字符)

### How to tune the screen size
### <span id="how-to-tune-the-screen-size">如何调节窗口的大小</span>

The screen size of lab is captured by xrandr, if not work, please check and set your own, for example:
Linux Lab 的屏幕尺寸是由 xrandr 捕获的，如果不起作用，请检查并自行设置，例如：

Get available screen size values:
获取可用的屏幕尺寸值：

    $ xrandr --current
    Screen 0: minimum 1 x 1, current 1916 x 891, maximum 16384 x 16384
    Virtual1 connected primary 1916x891+0+0 (normal left inverted right x axis y axis) 0mm x 0mm
       1916x891      60.00*+
       2560x1600     59.99
       1920x1440     60.00
       1856x1392     60.00
       1792x1344     60.00
       1920x1200     59.88
       1600x1200     60.00
       1680x1050     59.95
       1400x1050     59.98
       1280x1024     60.02
       1440x900      59.89
       1280x960      60.00
       1360x768      60.02
       1280x800      59.81
       1152x864      75.00
       1280x768      59.87
       1024x768      60.00
       800x600       60.32
       640x480       59.94

Choose one and configure it:
选择一个并对其进行配置：

    $ cd /path/to/cloud-lab
    $ tools/docker/rm-all
    $ SCREEN_SIZE=800x600 tools/docker/run linux-lab

If want the default one, please remove the manual setting at first:
如果要使用默认设置，请先删除手动设置：

    $ cd /path/to/cloud-lab
    $ rm configs/linux-lab/docker/.screen_size
    $ tools/docker/rm-all
    $ tools/docker/run linux-lab

### How to exit qemu
### <span id="how-to-exit-qemu">如何退出 qemu</span>

1. Serial Port Console: Exit with 'CTRL+A X'
1. 串口控制台: 使用 'CTRL+A X'
2. Curses based Graphic: Exit with 'ESC+2 quit' Or 'ALT+2 quit'
2. 基于 Curses 的图形终端: 使用 'ESC+2 quit' 或者 'ALT+2 quit'
3. X based Graphic: Exit with 'CTRL+ALT+2 quit'
3. 基于 X 的图形终端: 使用 'CTRL+ALT+2 quit'

### How to work in fullscreen mode
### <span id="how-to-work-in-fullscreen-mode">如何进入全屏模式</span>

Open the left sidebar, press the 'Fullscreen' button.
打开左边的侧边栏，点击 “Fullscreen” 按钮。

### How to record video
### <span id="how-to-record-video">如何录屏</span>

* Enable recording
* 使能录制

  Open the left sidebar, press the 'Settings' button, config 'File/Title/Author/Category/Tags/Description' and enable the 'Record Screen' option.
  打开左侧边栏，按 “Settings” 按钮，配置 “File/Title/Author/Category/Tags/Description”，然后启用 “Record Screen” 选项。

* Start recording
* 开始录制

  Press the 'Connect' button.
  按下 “Connect” 按钮。

* Stop recording
* 停止录制

  Press the 'Disconnect' button.
  按下 “Disconnect” 按钮。

* Replay recorded video
* 重放录制的视频

  Press the 'Play' button.
  按下 “Play” 按钮。

* Share it
* 分享视频

  Videos are stored in 'cloud-lab/recordings', share it with help from [showdesk.io](http://showdesk.io/post).
  视频存储在 “cloud-lab/recordings” 目录下，参考 [showdesk.io](http://showdesk.io/post) 的帮助进行分享。

### Linux Lab not response
### <span id="linux-lab-not-response">Linux Lab 无响应</span>

The VNC connection may hang for some unknown reasons and therefore Linux Lab may not response sometimes, to restore it, please press the flush button of web browser or re-connect after explicitly disconnect.
VNC 连接可能由于某些未知原因而挂起，导致 Linux Lab 有时可能无法响应，要恢复该状态，请点击 Web 浏览器的刷新按钮或断开连接后重新连接。

### Language input switch shortcuts
### <span id="language-input-switch-shortcuts">如何快速切换中英文输入</span>

In order to switch English/Chinese input method, please use 'CTRL+s' shortcuts, it is used instead of 'CTRL+space' to avoid conflicts with local system.
为了切换英文/中文输入法，请使用 “CTRL+s” 快捷键，而不是 “CTRL+space”，以避免与本地系统冲突。

### No working init found
### <span id="no-working-init-found">运行报错 “No working init found”</span>

This means the rootfs.ext2 image may be broken, please remove it and try `make boot` again, for example:
这意味着 rootfs.ext2 文件可能已损坏，请删除该文件，然后再次尝试执行 `make boot`，例如：

    $ rm boards/aarch64/raspi3/bsp/root/2019.02.2/rootfs.ext2
    $ make boot

`make boot` command can create this image automatically.
`make boot` 命令可以自动创建该映像。

### linux/compiler-gcc7.h: No such file or directory
### <span id="linuxcompiler-gcc7h-no-such-file-or-directory">运行报错 “linux/compiler-gcc7.h: No such file or directory”</span>

This means using a newer gcc than the one linux kernel version supported, there are two solutions, one is [switching to an older gcc version](#toolchain) with 'make gcc-switch', use `i386/pc` board as an example:
这意味着你使用了一个比 Linux 内核版本所支持的 gcc 的版本更新的 gcc，有两种解决方案，一种是使用 `make gcc-switch` 命令 [切换到较旧的 gcc 版本](#toolchain)，以 `i386 / pc` 开发板为例：

    $ make gcc-list
    $ make gcc-switch CCORI=internal GCC=4.4

### Network not work
### <span id="network-not-work">网络不通</span>

If ping not work, please check one by one:
如果无法 ping 通，请根据下面列举的方法逐一排查：

**DNS issue**: if `ping 8.8.8.8` work, please check `/etc/resolv.conf` and make sure it is the same as your host configuration.
**DNS 问题**：如果 `ping 8.8.8.8` 工作正常，请检查 `/etc/resolv.conf` 并确保其与主机配置相同。

**IP issue**: if ping not work, please refer to [network conflict issue](#docker-network-conflicts-with-lan) and change the ip range of docker containers.
**IP 问题**：如果 ping 不起作用，请参阅 [网络冲突问题](#docker-network-conflicts-with-lan) 并更改 docker 容器的 ip 地址范围。

### linux-lab/configs: Permission denied
### <span id="linux-labconfigs-permission-denied">运行报错 “linux-lab/configs: Permission denied”</span>

This may happen at `make boot` while the repository is cloned with `root` user, please simply update the owner of `cloud-lab/` directory:
这个错误会在执行 `make boot` 时报出，原因可能是由于克隆代码仓库时使用了 `root` 权限，解决方式是修改 `cloud-lab /` 目录的所有者：

    $ cd /path/to/cloud-lab
    $ sudo chown $USER:$USER -R ./
    $ tools/docker/rerun linux-lab

Or directly use `sudo make boot`.
或者直接使用 `sudo make boot`。

### Client.Timeout exceeded while waiting headers
### <span id="clienttimeout-exceeded-while-waiting-headers">运行报错 “Client.Timeout exceeded while waiting headers”</span>

This means must configure one of the following docker images mirror sites:
解决方法是选择配置以下 docker images 的 mirror 站点中的一个：

* Aliyun (Register Required): <http://t.cn/AiFxJ8QE>
* Docker China: https://registry.docker-cn.com
* USTC: https://docker.mirrors.ustc.edu.cn

Configuration in Ubuntu:
Ubuntu 中的配置方法如下：

    $ echo "DOCKER_OPTS=\"\$DOCKER_OPTS --registry-mirror=<your accelerate address>\"" | sudo tee -a /etc/default/docker
    $ sudo service docker restart

### VNC login fails with wrong password
### <span id="vnc-login-fails-with-wrong-password">登录 VNC 时报密码错误</span>

VNC login fails while using mismatched password, to fix up such issue, please clean up all and rerun it:
使用不匹配的密码时会导致 VNC 登录失败，要解决此问题，请清除所有内容并重新运行：

    $ tools/docker/clean linux-lab
    $ tools/docker/rerun linux-lab

### scripts/Makefile.headersinst: Missing UAPI file: ./include/uapi/linux/netfilter/xt_CONNMARK.h
### <span id="scriptsmakefileheadersinst-missing-uapi-file-includeuapilinuxnetfilterxt_connmarkh">运行报错：“scripts/Makefile.headersinst: Missing UAPI file: ./include/uapi/linux/netfilter/xt_CONNMARK.h”</span>

This means MAC OSX not use Case sensitive filesystem, create one using hdiutil or Disk Utility yourself:
这是因为 MAC OSX 不使用区分大小写的文件系统，请使用 hdiutil 或 Disk Utility 自己创建一个：

    $ hdiutil create -type SPARSE -size 60g -fs "Case-sensitive Journaled HFS+" -volname labspace labspace.dmg
    $ hdiutil attach -mountpoint ~/Documents/labspace -no-browse labspace.dmg
    $ cd ~/Documents/labspace

### Ubuntu Snap Issues
### <span id="ubuntu-snap-issues">Ubuntu Snap 问题</span>

Users report many snap issues, please use apt-get instead:
用户报告了许多 snap 相关的问题，请改用 apt-get：

* users can not be added to docker group and break non-root operation.
* 无法将用户添加到 docker 组导致非 root 用户的操作被中断。
* snap service exhausts the /dev/loop devices and break mount operation.
* snap 服务会耗尽 `/dev/loop` 设备从而导致 mount 操作被打断。

## Contact and Sponsor
## <span id="contact-and-sponsor">联系我们以及赞助我们</span>

Our contact wechat is **tinylab**, welcome to join our user & developer discussion group.
我们的微信号是 **tinylab**，欢迎加入我们的用户和开发人员讨论组。

** Contact us and Sponsor via wechat **
** 扫微信号二维码联系我们或者提供赞助 **

![contact-sponsor](doc/contact-sponsor.png)
