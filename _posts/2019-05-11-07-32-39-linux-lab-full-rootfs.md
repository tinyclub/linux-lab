---
layout: post
author: 'Wu Zhangjin'
title: "为 Linux Lab 新增全功能 Rootfs 支持"
draft: true
group: 'original'
license: "cc-by-sa-4.0"
permalink: /linux-lab-full-rootfs/
description: "Linux Lab 虽然用 buildroot 预先构建了 rootfs，但是仅仅满足基本的内核启动、基础特性验证，无法满足较复杂的应用开发需求，所以本文介绍了如何为 Linux Lab 新增一个全功能的 Rootfs"
category:
  - 根文件系统
  - Linux Lab
tags:
  - rootfs
  - distribution
  - openembedded
  - yocto
  - buildroot
  - busybox
  - docker
  - Dockerfile
  - qemu
  - arm
---

> By Falcon of [TinyLab.org][1]
> May 11, 2019

## 背景介绍

这篇文章缘起于有同学希望为 [Linux Lab](/linux-lab) 提供一个全功能的 rootfs，方便在里头开发完整的应用，以便更全面的测试内核特性。

这个需求是很自然的，因为 Linux Lab 截止到目前只考虑了 “嵌入式” 需求，只是通过 buildroot 预先构建了一个 mini rootfs（没有各种库，没有包管理），没有关注到应用开发层面所需要的 full rootfs。

如果要在 Linux Lab 这样一个虚拟化平台做应用开发，确实会面临一些问题，要在 Linux Lab 的实验环境提供一个完整的交叉编译环境不是很现实，它会导致实验环境的镜像无限增大，而且这个环境还会经常变更，维护会是一个大麻烦，并且用户的应用可能会对各种库有依赖，最终会导致烦恼没有止境。

一个可选方案是：制作一个完全独立的全功能的 rootfs，这个 rootfs 放在 Linux Lab 之外独立维护，但是可以通过 Linux Lab 启动。

当然，启动也有两种方案，一种是基于 qemu-user-static 直接 chroot 进去使用，另外一种是通过 `make boot` 指定通过 NFS 挂载启动。前者只做指令翻译运行速度可能更快适合做应用的开发和编译，后者是系统级模拟则能够用于验证配套开发的内核特性是否确实正常工作。

## 制作 Full Rootfs

如何快速高效地制作一个可以独立使用的并且功能完备的 Rootfs，这个课题值得好好考虑一下。Linux 世界丰富多彩的地方在于，不同的群体为不同需求设计了诸多不同的方案，所以选择很多，如何从这么多方案中选择最合适的那个，比较难。

### 明确需求

首先明确 Full rootfs 需求：

1. 要能方便的独立使用，所以最好是可以以目录的方式管理
2. 需要避免什么都从头开始，节约时间和精力，聚焦应用开发
3. 需要能够自由定制，必须有包管理，方便安装缺失的工具和库
4. 需要能够有不同处理器架构的支持，至少得支持 ARM 等架构
5. 方便下载和安装，不能太大，仅提供基础环境，其他通过包管理解决

### 7 大制作方法调研

Linux 基金会为 Rootfs 制定了规范文档：[Linux FHS][9]，社区可以基于它开发自己的实现，下面是社区的一些候选制作方法：

- [Busybox][2]，BusyBox combines tiny versions of many common UNIX utilities into a single small executable.
- [Buildroot][5]，a simple, efficient and easy-to-use tool to generate embedded Linux systems through cross-compilation.
- [Openembedded][6]，the build framework for embedded Linux.
- [Yocto][7]，NOT AN EMBEDDED LINUX DISTRIBUTION, IT CREATES A CUSTOM ONE FOR YOU.
- [LFS][3]，a project that provides you with step-by-step instructions for building your own custom Linux system, entirely from source code.
- [CLFS][4]，a project that provides you with step-by-step instructions for cross building your own customized Linux system entirely from source.
- [Distributions][8]，top 10 most popular linux distributions compared

Busybox 小巧轻灵，本身提供了常见 Unix 工具集的 tiny 实现，麻雀虽小，五脏俱全，进行微小的调整就可以制作一个随 Linux 内核启动的符合 FHS 的文件系统，特别适合入门嵌入式 Linux 开发，不需要花很多时间，就可以了解 Linux 文件系统的组织结构和启动引导过程。

Buildroot，看名字主要是制作 Rootfs，集成了 Busybox，uclibc 等大量轻量级的工具、代码库，可以用熟悉的内核配置工具来配置，用于制作面向嵌入式环境的根文件系统，所以之前就用它来制作了 Linux Lab 的 mini rootfs。它不仅提供了多种架构预先编译的交叉编译工具链，本身也可以用来制作交叉编译工具，还可以用来编译内核、Qemu 等。为什么不用 Buildroot 来制作 full rootfs 呢？最重要的是，它没有包管理，需要有一个基础的下载和编译过程，这个是有点费时间。但是，如果需要制作比较小的嵌入式系统，这个过程是值得的，首次编译以后，后面就相对比较轻松。

Openembedded，提供了更灵活的配置功能，引入了“菜谱”这样的概念，引入了专门的配置工具：Bitbake，也增加了可扩展性，但是复杂度和编译时间大大增加。相比而言，Buildroot 隐藏了这些细节。

Yocto，相比 Openembedded 在配置性和可扩展性上更进一步，甚至通过引入 BSPs，支持真实的机器和开发板，也可以通过配置加入包管理工具，所以它有能力通过大量预制的“菜谱”制作一个完整的 Linux Distribution。Yocto 和 Openembedded 之间共享 Bitbake 和 openembedded-core，它们是 Openembedded 的构建系统，Yocto 基于此做了自己的构建工具：Poky。Yocto 和 Buildroot 的更完整比较请看：[Buildroot v.s. Openembedded/Yocto Project][16]。

LFS, Linux From Scratch，从名字就可以理解，它是从头开始制作一个 Linux，manually, step-by-step，相比 Busybox，它包含了各种 normal-size 的包，本身还会制作工具链，制作代码库，Busybox 带了 tiny-size 的代码库，但是没有工具链。

CLFS，Cross LFS，这里主要体现是交叉编译，就是在一个架构上 step-by-step 完成另外一个架构的 LFS 过程。

Distributions，Linux 世界的发行版百花齐放，不同主题、不同桌面、不同领域、不同更新频次、不同包管理工具让人眼花缭乱，目前业界还在常用的有这么几种：Ubuntu、Debian、Arch Linux、CentOS、Android。Ubuntu 现在被各大企业广泛使用，每年 4 月和 10 月各发行一个版本；Debian 更新更慢，可能也更为稳定；Arch Linux 的 package 滚动更新，比较快能拿到单个软件的新版本；CentOS 基本是 Redhat 的社区版；Android 面向手机。Distributions 的好处是有预编译的工具链、工具以及 Qemu，还有各种代码库，比较适合聚焦应用开发。不过并不是所有发行版都支持多种架构，这里头 Ubuntu 和 Debian 是特例，它们都支持 ARM、PowerPC 和 S390，Debian 还支持 MIPS。除了 CD 包，Ubuntu 还提供了 Ubuntu-base （非常基础） 和 Ubuntu-core（功能更丰富） 的文件系统的压缩包，14.10 以后只提供制作好的 img，之前有纯粹的压缩包。另外，Ubuntu 和 Debian 都提供了 debootstrap 机制，允许直接拉一个 base 系统，然后在之上安装其他的 package。

### 选择 Ubuntu-core 压缩包

所以，综合来看，根据前述 Full Rootfs 需求，下载一个现成的 Ubuntu-core 是一个很好的选择，不需要用 [debootstrap][10]，而是直接下载下来解压即可，只是 Ubuntu 不支持 MIPS，所以会是一个遗憾。本文先介绍如何使用现成的 Ubuntu-core，而不是 debootstrap，后续再考虑介绍它，到时顺便介绍 [debian debootstrap][11] 以及 [debootstrap for arm64][12]。

从 Ubuntu 16 开始，其 Ubuntu-core 的发布地址和包的格式发生了变化：

- [Ubuntu >= 16 / xenial][13]，制作成了含 MBR 的 img，不能直接把根文件系统拿出来，需要用带 offset 的方式挂载后拷贝出来。但实际 mount 出来后没有找到 rootfs，不过幸运的是，我们通过 [arm32v7/ubuntu][18] 这个 docker image 的首页找到了另外一个 Ubuntu core 的[发布地址][17]，几乎所有历史版本都有，这个 Ubuntu core 包含更小的配置，连 ifconfig 命令都没有，仅有 30M 左右。

- [Ubuntu <= 14 / trusty][14]，制作成了压缩包，可以直接解压使用，压缩包在 60M 左右，包含更多基础的工具。

这里以 ARM / Ubuntu 14.04 为例，后面再考虑更新如何使用 Ubuntu 16 的 Ubuntu-core 镜像文件。

假设当前就在 Linux Lab 主目录下，先创建一个 full-rootfs/arm-ubuntu 目录：

    $ mkdir -p full-rootfs/arm-ubuntu
    $ wget -c http://old-releases.ubuntu.com/releases/ubuntu-core/releases/14.10/release/ubuntu-core-14.10-core-armhf.tar.gz
    $ sudo tar zxf ubuntu-core-14.10-core-armhf.tar.gz -C full-rootfs/arm-ubuntu

这样就可以快速拿到一个 ARM 的 full rootfs core，要做开发环境，还得自己安装 build-essential 等工具。

## 验证 Full Rootfs

要在 Linux Lab 使用上面的 ARM / Ubuntu 14.04，有两种方式：

### Qemu + Chroot

其中一种方式是：qemu-arm-static + chroot，这个是直接使用指令集翻译。

由于编译环境当前的 qemu 版本有点老，第一种方法无法正常启动，进入就有 segmentation fault，所以首先要参考 [如何编译新版本的 qemu-arm-static][15] 编译一个新版本的 qemu-arm-static。

Linux Lab 已经预编译了一个放置到了 `prebuilt/qemu/arm/v2.12.0/bin/qemu-arm`，把这个复制到 `full-rootfs/arm-ubuntu/usr/bin/qemu-arm-static` 以后，即可通过 chroot 验证。

    $ sudo chroot full-rootfs/arm-ubuntu
    root@70c3a280af9a:/# uname -a
    Linux 70c3a280af9a 4.4.0-145-generic #171-Ubuntu SMP Tue Mar 26 12:43:40 UTC 2019 armv7l armv7l armv7l GNU/Linux

### 系统级模拟

另外一种是直接用 `make boot`，通过 Qemu 模拟完整的系统。这里选用 vexpress-a9 开发板，下面快速验证该环境。

为了方便编辑和维护，希望以纯目录的方式管理该文件系统。而要能够用 `make boot` 挂载目录，得用 NFS 的方式。

另外，考虑到 Ubuntu 本身启动过程的复杂性，先分阶段来验证，先通过内核参数修改 init，直接启动到 `/bin/bash`。

    $ make B=vexpress-a9 boot V=1 ROOTDEV=/dev/nfs ROOTDIR=$PWD/full-rootfs/arm-ubuntu XKCLI=init=/bin/bash
    ...
    Run /bin/bash as init process
    ...
    root@172:/# uname -a
    Linux 172.17.0.200 5.1.0+ #1 SMP Mon May 6 17:07:40 UTC 2019 armv7l armv7l armv7l GNU/Linux
    root@172:/# reboot -f


上述参数和命令解释如下：

- `B=vexpress-a9`，指定开发板
- `V=1`，显示更多的信息，方便调试
- `ROOTDEV=/dev/nfs`，通过 NFS 方式挂载根文件系统
- `ROOTDIR=$PWD/full-rootfs/arm-ubuntu`，指定 NFS 挂载的文件系统所在目录
- `XKCLI=init=/bin/bash`，给内核参数追加 `init=/bin/bash`，跑完内核后直接执行 `/bin/bash`
- `reboot -f`，退出 Qemu，也可以键入 `CTRL + a + x` 强制退出

这部分完美启动，基础验证就 ok 了，下面继续完善该开发环境。

## 完善 Full Rootfs

如果要作为一个比较全的开发环境，需要能完整启动 Ubuntu，需要重置登陆密码，添加串口登陆功能，配置网络，升级到 18.04，安装相关的开发包。

这里继续使用 `make boot` 做后续功能完善。

### 临时配置网络

由于 Linux Lab 已经提供了完善的网桥网络功能，已经给每一个新启动的系统预留了一个静态 IP，因此只需要给新文件系统配置一下路由和 DNS 就可以上网。

路由的地址可以从内核命令行那里获得：

    # cat /proc/cmdline
    route=172.17.0.5 root=/dev/nfs  nfsroot=172.17.0.5:/labs/linux-lab/full-rootfs/arm-ubuntu/ rw ip=172.17.0.210 console=ttyAMA0
    # route add default gw 172.17.0.5 eth0

域名解析服务（DNS）直接用 Google 的：

    # echo "nameserver 8.8.8.8" > /etc/resolv.conf

配置完以后就可以 ping 出去了。

    # ping tinylab.org

### 升级到最新 18.04 LTS

为了获取最新的软件包，先把系统升级到最新的 18.04 LTS。

由于直接升级到 18.04 没有成功，需要分两步升级，先升级到 16.04/xenial，再升级到 18.04/bionic。

首先配置软件安装源，先升级到 16.04/xenial：

    # vi etc/apt/sources.list
    deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial main restricted
    deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-updates main restricted
    deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-security main restricted

然后做一些准备工作（提前解决 upgrade 过程可能遇到的错误）：

    # mkdir dev/pts
    # mount -t devpts none /dev/pts
    # mount -t proc none /proc
    # export PATH=$PATH

然后开始升级：

    # apt-get update; apt-get -y upgrade; apt-get -y dist-upgrade

之后调整源配置为 18.04/bionic 并继续升级：

    # vi etc/apt/sources.list
    deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial main restricted
    deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-updates main restricted
    deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-security main restricted

    # apt-get update; apt-get -y upgrade; apt-get -y dist-upgrade

升级完以后进行检查：

    # cat /etc/issue
    Ubuntu 18.04.2 LTS \n \l


### 修改登陆密码

在上述 `/bin/bash` 命令行环境，可以直接修改和验证登陆密码。

用 `passwd` 命令修改 `root` 密码为 `root`，键入命令后，连续两次按提示输入 `root` 即可。

    $ passwd root
    Enter new UNIX passwd:
    Retype new UNIX passwd:

下面用 `getty` 和负责当前输入输出的串口 ttyAMA0 验证该登陆密码。

    $ /sbin/getty -L 9600 ttyAMA0 vt100
    172 login: root
    Password:

键入密码后即可登陆，上面验证了串口登陆功能，下面为 Ubuntu 加入该功能，在启动以后提供一个登陆入口，否则串口下就没有命令行了。

### 添加串口登陆功能

对于极简的早期启动管理系统，可以直接在 `/etc/inittab` 打开这一行：

    T2:23:respawn:/sbin/getty -L ttyAMA0 9600 vt100

对于采用 upstart 的 Ubuntu，比如这里的 14.10，就需要在 `/etc/init/` 下添加一个独立的 `/etc/init/ttyAMA0.conf` 文件：

    # ttyAMA0 - getty
    #
    # This service maintains a getty on console from the point the system is
    # started until it is shut down again.

    start on stopped rc RUNLEVEL=[12345] and container CONTAINER=lxc

    stop on runlevel [!12345]

    respawn
    exec /sbin/getty -L 9600 ttyAMA0 vt100

添加完以后就可以不用传递 `XKCLI` 参数给 `make boot` 了：

    $ make B=vexpress-a9 boot V=1 ROOTDEV=/dev/nfs ROOTDIR=$PWD/full-rootfs/arm-ubuntu MEM=1024M
    ...
    Kernel command line: route=172.17.0.5 root=/dev/nfs  nfsroot=172.17.0.5:/labs/linux-lab/full-rootfs/arm-ubuntu/ rw ip=172.17.0.210 console=ttyAMA0
    ...
    [ OK ] Found device /dev/ttyAMA0.
    ...
    [ OK ] Started Serial Getty on ttyAMA0.

    Ubuntu 14.04 LTS localhost.localdomain ttyAMA0

    local host login: root
    Password:


键入密码即可登陆，这里追加了一个 `MEM=1024M`，替换默认的 128M 内存，确保需要更多内存的场景也可以工作，虽然这里 128M 也可以启动。

### 网络自动配置

把路由的配置放到 `/etc/rc.local`，启动的时候就可以自动配置：

    $ sudo vim full-rootfs/arm-ubuntu/etc/rc.local
    #!/bin/bash -e
    #
    # Configure route ip based on kernel command line
    #

    ROUTE_IP=`echo $(</proc/cmdline) | tr ' ' '\n' | grep route | tr '=' '\n' | tail -1`
    route add default gw $ROUTE_IP eth0

再次启动就可以自动配置网络，直接接通外部了。

### 安装更多软件包

接下来根据需要安装各种编辑、编译、开发工具即可：

   $ apt-get install -y vim build-essential gcc-8 cscope

为了控制包的大小，上面这几个软件没有包含在下面发布的 Rootfs 中，请自行根据需要安装。

## 发布 Full Rootfs

上述制作过程蛮耗费时间的，所以这个劳动成果要尽可能地分享出去，避免大家做重复工作。

一个共享的方式是发布到 Github，另外一个方式是直接制作成 Docker 镜像，这里直接选择第二种方式。

先把需要制作成镜像的文件系统搬到临时目录，之后直接用脚本构建：

    $ sudo cp -r full-rootfs/arm-ubuntu prebuilt/fullroot/tmp/arm32v7-ubuntu-18.04
    $ sudo tools/rootfs/docker/build.sh tinylab/arm32v7-ubuntu:18.04 arm32v7-ubuntu-18.04
    $ docker tag tinylab/arm32v7-ubuntu:18.04 tinylab/arm32v7-ubuntu:latest

构建完以后，直接发布到上游：

    $ docker push tinylab/arm32v7-ubuntu:latest
    $ docker push tinylab/arm32v7-ubuntu:18.04

## 下载 Full Rootfs

下载镜像并把整个文件系统拷贝出来：

    $ tools/rootfs/docker/extract.sh tinylab/arm32v7-ubuntu arm

文件系统默认拷贝在 `prebuilt/fullroot/tmp/tinylab-arm32v7-ubuntu`。

## 使用 Full Rootfs

通过 Docker 运行：

    $ tools/rootfs/docker/run.sh tinylab/arm32v7-ubuntu arm
    root@126a8be481fd:~# uname -a
    Linux 126a8be481fd 4.4.0-145-generic #171-Ubuntu SMP Tue Mar 26 12:43:40 UTC 2019 armv7l armv7l armv7l GNU/Linux
    root@126a8be481fd:~# cat /etc/issue
    Ubuntu 18.04.2 LTS \n \l

如果在 Docker 容器中安装了新的工具，可以 dump 出来，同样存在 `prebuilt/fullroot/tmp` 下：

    $ tools/rootfs/docker/dump.sh 126a8be481fd

通过 chroot 验证：

    $ tools/rootfs/docker/chroot.sh tinylab/arm32v7-ubuntu
    root@ubuntu:/# uname -a
    Linux ubuntu 4.4.0-145-generic #171-Ubuntu SMP Tue Mar 26 12:43:40 UTC 2019 armv7l armv7l armv7l GNU/Linux

通过 `make boot` 验证：

    $ make boot B=vexpress-a9 U=0 V=1 MEM=1024M ROOTDEV=/dev/nfs ROOTDIR=$PWD/prebuilt/fullroot/tmp/tinylab-arm32v7-ubuntu/

完整启动过程录制如下：

<iframe src="http://showterm.io/c351abb6b1967859b7061" width="100%" height="480" marginheight="0" marginwidth="0" frameborder="0" scrolling="no" border="0" allowfullscreen></iframe>

更多不同架构的 ubuntu/debian 可以直接从 docker image 抓取，并类似上面使用，列表请参考 `prebuilt/fullroot/README.md`。

## 小结

为了制作一个全功能、可以用于开发应用的 Full Rootfs，本文详细调研了多种 Rootfs 的制作方法，并最终选择 Ubuntu-core。

Ubuntu-core 提供了一个预先制作好的基础包，内置了包管理工具，并且支持 ARM、PowerPC、X86 和 S390 等处理器架构。

本文以 ARM 为例，详细介绍了基于 Ubuntu-core，逐步完善，制作出一个带开发环境的 Full Rootfs 的过程。

最后介绍了如何制作成 docker 镜像，并发布出去，以及发布后如何下载与使用。

欢迎联系笔者微信 lzufalcon，进一步深入探讨。

[18]: https://hub.docker.com/r/arm32v7/ubuntu
[17]: https://partner-images.canonical.com/core/
[16]: https://bootlin.com/pub/conferences/2016/elc/belloni-petazzoni-buildroot-oe/belloni-petazzoni-buildroot-oe.pdf
[15]: http://logan.tw/posts/2018/02/18/build-qemu-user-static-from-source-code/
[14]: http://old-releases.ubuntu.com/releases/ubuntu-core/releases/
[13]: http://cdimage.ubuntu.com/ubuntu-core/
[12]: https://a-delacruz.github.io/debian/debian-arm64.html
[11]: https://github.com/bithollow/bithollow.github.io/wiki/create-minimal-debian-rootfs
[10]: https://wiki.ubuntu.com/ARM/RootfsFromScratch/QemuDebootstrap
[9]: https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.pdf
[8]: https://www.howtogeek.com/191207/10-of-the-most-popular-linux-distributions-compared/
[7]: https://www.yoctoproject.org/
[6]: https://buildroot.org/
[5]: http://www.openembedded.org
[4]: http://www.cross-lfs.org/
[3]: http://www.linuxfromscratch.org/
[2]: https://www.busybox.net/
[1]: http://tinylab.org
