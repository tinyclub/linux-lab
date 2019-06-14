---
layout: post
author: 'Wu Zhangjin'
title: "嵌入式 Linux 文件系统"
album: "嵌入式 Linux 知识库"
group: translation
permalink: /embedded-linux-file-systems/
description: "介绍了 Linux 文件系统相关的各类信息"
category:
  - 文件系统
tags:
  - Linux
  - MTD
  - 分区
  - eMMC
  - F2FS
  - CramFS
  - JFFS2
  - NFS
  - UBIFS
---

> 书籍：[嵌入式 Linux 知识库](https://tinylab.gitbooks.io/elinux)
> 原文：[eLinux.org](http://eLinux.org/File_Systems "http://eLinux.org/File_Systems")
> 翻译：[@lzufalcon](https://github.com/lzufalcon)

## 简介

大多数嵌入式设备使用 [闪存](http://en.wikipedia.org/wiki/Flash_memory) 作为存储介质。

同时，系统尺寸和启动时间在许多消费电子产品中也非常重要，因此，专用文件系统经常具有不同的功能，例如，更高压缩比或者直接从闪存执行文件的能力。


### MTD

需要注意的是，闪存可能用 Linux 的 MTD 系统管理。从 [MTD/Flash FAQ](http://www.linux-mtd.infradead.org/faq/general.html) 可以查看相关信息。这里提到的大多数文件系统都构建在 MTD 系统之上。


### UBI

Linux 内核的 [Unsorted Block Images（未排序的块映像）](http://www.linux-mtd.infradead.org/doc/ubi.html) (UBI) 系统管理单个闪存上的多个逻辑卷。它通过 MTD 层提供了从逻辑块到物理可擦除块的映射。UBI 也提供了灵活的分区概念，允许跨越整个闪存设备均衡损耗。

可通过 [UBI](http://www.linux-mtd.infradead.org/doc/ubi.html) 或者 [UBI FAX and Howto](http://www.linux-mtd.infradead.org/faq/ubi.html) 查看更多信息。


### 分区

内核至少要有一个根（root）文件系统，确保其他系统有地方可以挂载。在非嵌入式系统中，经常只会用到一个文件系统。但是，为了优化有限的资源（闪存、RAM、处理器速度、启动时间），许多嵌入式系统把文件系统拆分成几个独立的部分，然后把每部分放在各自的分区（通常在不同类型的存储设备中）。

举例来说，开发人员可能希望拿到系统中所有只读文件，并放到闪存中一个压缩过的只读文件系统中。这样或许会牺牲掉一些读取时间的性能（解压所需），但是可以减少闪存空间的消耗。

其他的配置可能会把可执行文件放到未压缩的闪存上，这样它们就可以就地执行，从而节省 RAM 和 启动时间（会潜在有少许性能损失）。

对于可写数据，如果数据不需要永久存在，有时就可以用 Ramdisk。而文件数据是否压缩，则取决于性能需要和内存限制。

并没有单一的标准来确定文件系统的只读和读/写部分，这在很大程度上取决于项目中所有用到的嵌入式应用情况。


### eMMC and UFS

随着闪存越来越大，各种因素造成嵌入式设备从使用裸 NAND 转移到封装过的、可基于块寻址的 NAND 闪存。这些是包含固件的芯片，这些固件接收块 I/O 请求，类似于老的硬盘那样旋转存储介质并填充他们。这涉及到映射读写请求到芯片上的 NAND 闪存相应的区域，并管理 NAND 闪存并且尝试优化 Flash 闪存的可靠性和使用寿命。NAND 闪存必须以大块（可擦除的块）来重写，这种块是单个文件系统块的很多倍。因此，系统中的映射、重排和块分配后的垃圾回收机制相当重要。

这些芯片采用基于块的而不是基于闪存的文件系统（例如：Ext4）。截止 2012 年，针对这些芯片去优化 Ext4 文件系统是文件系统研究的一个热点领域，见：<http://lwn.net/Articles/502472>


## 嵌入式文件系统

这里有一些为嵌入式设备设计或者常用在嵌入式设备中的文件系统，以字母顺序排列：


### AXFS

-   [AXFS](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/File_Systems/AXFS/AXFS.html "AXFS") - 高级就地执行（XIP）文件系统
    -   网站：[http://axfs.sourceforge.net/](http://axfs.sourceforge.net/)
    -   此文件系统是为 XIP 操作特别设计的，它使用双阶段的办法。第一阶段是把文件系统放在闪存上并运行它获取分析数据，并注明哪些页面有被用到。二阶段使用这些分析数据来构建一个文件系统。该文件系统把所有分析文件中记录的页面作为 XIP 数据，这些数据之后被加载到内存并被挂载（然后作为 XIP 执行）。也可能把 XIP 页面放到 NOR 闪存中并直接在上面执行。


### Btrfs

-   [btrfs](https://btrfs.wiki.kernel.org/index.php/Main_Page) 是一种新的写时复制文件系统，首次出现在 2.6.29-rc1 内核并且 [被合入到了 2.6.30](http://lwn.net/Articles/342892/)。
-   截止 2011 年 4 月，Btrfs [还没有被许多流行的 Linux 文件系统工具（如 gparted）支持](http://gparted.sourceforge.net/features.php)
-   Btrfs 已经被用作 [MeeGo 平台的文件系统](http://lwn.net/Articles/387196/)。
-   [一个很赞的 btrfs 视频，来自 Chris Mason](http://training.linuxfoundation.org/linux-tutorials/introduction-to-btrfs)


### CramFS

-   [CRAMFS](http://en.wikipedia.org/wiki/Cramfs) - Linux 的一个压缩的只读文件系统，CRAMFS 的最大尺寸是 256M。
    -   "线性 Cramfs" 是指这样一种功能，即采用 Cramfs 文件系统，但是在线性块布局中使用非压缩文件。这个对于存储用于可就地执行的文件很有用。如果想了解更多线性 Cramfs 的信息，可以查看[应用程序就地执行（XIP）](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Application_XIP/Application_XIP.html "Application XIP")一文。


### F2FS

-   [F2FS](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/File_Systems/F2FS/F2FS.html "F2FS")[（维基百科入口）](http://en.wikipedia.org/wiki/F2FS) 是 Linux 的一款闪存友好的文件系统，由三星开发。


### InitRAMFS

来自 2006 年 3 月的 [Introducing initramfs, a new model for initial RAM disks](http://archive.linuxgizmos.com/introducing-initramfs-a-new-model-for-initial-ram-disks-a/) 一文显示：

> 引入 INITRAMFS 之初，是作为初始化内存盘的一个新模型，这点是很清楚的。技术性文章介绍 initramfs 时，把它描述为 Linux 2.6 内核的一个功能，该功能允许初始化根文件系统和初始化程序驻留在内核内存缓冲区中，而不是驻留在内存盘中（对于 initrd 文件系统是这样）。initramfs 作者提到，相比 initrd，initramfs 能够增加启动时间的灵活性、内存的有效性和简便性。对于嵌入式开发者而言，一个特别有趣的功能是，一个相对简单的嵌入式系统能够只用 initramfs 作为它们唯一的文件系统。

这里有一篇不错的文章介绍了如何构建 initramfs：

-   [http://www.landley.net/writing/rootfs-howto.html](http://www.landley.net/writing/rootfs-howto.html)

更多信息可以查看这里：[Documentation/early-userspace/README](https://www.kernel.org/doc/Documentation/early-userspace/README)


### JFFS2

-   [JFFS2](http://sourceware.org/jffs2/) - v2.0 的日志闪存文件系统。这个是最常用的闪存文件系统。
    -   JFFS2 的最大尺寸是 128MB。
    -   [http://sourceforge.net/projects/mtd-mods](http://sourceforge.net/projects/mtd-mods) 有一些来自 Alexey Korolev 的补丁，用于改善 JFFS2。


### LogFS

LogFS 是一个可伸缩性的闪存文件系统，致力于在大多数使用场景中替换掉 JFFS2。

不幸地是，它貌似现在已经被遗弃了。

可通过 [LogFS](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/File_Systems/LogFS/LogFS.html "LogFS") 查看更多细节。



### NFS

鉴于嵌入式设备的空间有限，通常在开发过程中会用一个网络文件系统来作为目标开发板的根文件系统。这样就允许目标开发板在开发时能够有一个非常大的空间来存放全尺寸（译者注：例如，包括各种调试符号）的二进制文件和各种开发工具。不过有一个缺点是在产品最终发布时（或者开发周期中的某些时候），系统还需要被重新配置以便支持本地文件系统（通常还需要被重新测试）。

NFS 客户端可以被编译到内核中，然后内核就可以通过配置来用 NFS 作为根文件系统。这个需要支持网络以及为目标开发板设置 IP 地址的机制，还需要指定 NFS 主机上的文件系统路径。通常，主机还需要通过运行 DHCP 服务器为目标板提供需要的 IP 地址和路径信息。

可以通过内核源码下的 [Documentation/filesystems/nfs/nfsroot.txt](https://www.kernel.org/doc/Documentation/filesystems/nfs/nfsroot.txt) 查看更多关于如何通过内核挂载 NFS 根文件系统的信息。


### PRAMFS

-   [PRAMFS](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/File_Systems/Pram_Fs/Pram_Fs.html "Pram Fs") - 持久并且受保护的文件系统


    PRAMFS 是一个全功能的可读/写文件系统，被设计于，可以与更快的 I/O 内存协同工作，并且如果使用非易失内存，那么文件系统就具有持久性。另外，它还支持就地执行（XIP）。

    关于 PRAMFS 规范相关的信息，可以查看：[PRAMFS 规范](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/File_Systems/Pram_Fs/Pram_Fs.html_Specification "Pram Fs Specification")。


### Romfs

-   [RomFs](http://romfs.sourceforge.net) - 一个小型的空间有效的只读文件系统。相关描述可以查看：[Documentation/filesystems/romfs.txt](https://www.kernel.org/doc/Documentation/filesystems/romfs.txt)。


### SquashFS

[Squash Fs](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/File_Systems/Squash_Fs/Squash_Fs.html "Squash Fs") 是 Linux 的一个具有更高压缩比的可压缩只读文件系统。该文件系统相比 JFFS2 或者 CRAMFS 有更高压缩比。 在主线内核之外游离了很长一段时间后，Squashfs 最终被合并并发布在 [2.6.29 内核](http://kernelnewbies.org/LinuxChanges#head-5ca2504b2b4f4e6583f50dcdf23b2e75b383252f) 中。

在运行 `mksquashfs` 时，可以调节压缩比。`-b` 选项允许我们指定块大小。更小的块大小通常产生更小的压缩比，相应地，`-b` 设置越大，压缩比更高。但是，这里也有一个缺点，那就是数据以块的方式从磁盘读出来，所以如果使用 128k 大小的块，使用 4k 大小的内存页，然后压缩过的相当于 128k 的数据会从闪存读出来。因为 128k 需要 32 个内存页，这会导致一次性读取 32 页的内容到缓冲区中，即使当时只需要读 1 页内容。通常，另外 31 页也可能会被用到，但是如果用不到(but if not)，就会浪费掉读取和解压未用数据的时间，而且会让未用数据平白无故占用缓冲区（甚至系统还会为了给这 31 个页面预留空间而把其他用到的页面从缓冲区中踢出去），从而会降低资源利用率并影响性能。

如果想获得一个最小的文件系统，那么可以考虑用最大的块。但是，如果更关心性能的话，那么可以考虑尝试更多选项来看下哪个最适合你（甚至可以完全不用压缩，`mksquashfs`提供了这些相应的控制选项：`-noInodeCompression, -noDataCompression`, `–noFragmentCompression`）。如果还想采用函数重排（[启动时间\#用户空间和应用程序加速](http://eLinux.org/Boot_Time "Boot Time")），大的块可能更适合你。

下表给出了不同块大小可以达到的压缩比信息，这些尺寸信息都是针对一个嵌入式设备的根文件系统测试出来的。

|       |  大小  | 压缩比   |
|-------|--------|----------|
|初始值  | 53128K |  100 %   |
|4K     | 17643K |  33.2 %  |
|8K     | 16572K |  31.2 %  |
|16K    | 15780K |  29.7 %  |
|32K    | 15204K |  28.6 %  |
|64K    | 14812K |  27.9 %  |

在 2008 年欧洲嵌入式 Linux 会议上，Phillip Lougher 做了一个关于 SquashFS 的报告：

- [演讲稿](http://tree.celinuxforum.org/CelfPubWiki/ELCEurope2008Presentations?action=AttachFile&do=get&target=squashfs-elce.pdf)

和

- [演讲视频](http://free-electrons.com/pub/video/2008/elce/elce2008-lougher-squashfs.ogv).


### UBIFS

[UBIFS](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/File_Systems/UBIFS/UBIFS.html "UBIFS") 是构建在 [UBI](http://eLinux.org/File_Systems#UBI "File Systems") 之上的一个闪存文件系统。

UBIFS 相比于 JFFS2 和 YAFFS，拥有更好的性能。

可以通过 [UBIFS](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/File_Systems/UBIFS/UBIFS.html "UBIFS") 获取更多详细信息。


### YAFFS2

-   [YAFFS](http://www.yaffs.net/yaffs-overview) - Yet Another Flash File System（另一个闪存文件系统，名副其实！） - 一个专门为 NAND 闪存设计的文件系统

    YAFFS2 是一个简单、可移植、可靠而且完备的文件系统。除了 Linux，它还广泛应用于各类嵌入式操作系统，并且能够脱离操作系统独立使用，例如可直接用于引导程序中。当和 Linux 一起使用时，它能够用 MTD 或者是它自己的闪存驱动。类似地，它能用 VFS 或者它自己的 POSIX 层。它采用日志结构和单线程。它自身并不支持压缩 - （如果要支持压缩的话）要么压缩数据本身，要么在 YAFFS2 之上用 Squashfs。

    YAFFS 设计时就考虑了快速启动（作为一个日志结构文件系统，必须扫描闪存）。它使用检查点技术（Checkpointing），所以如果分区被干净地卸载，那么上电时就不需要重新扫描闪存。该 FS 的所有功能都可以配置，所以可以充分权衡像最大文件/分区大小，闪存块大小，文件粒度之类的各类参数。除了确保有效使用块的缓存外，数据被直接写透到闪存中。YAFFS2 通过使用闪存的 OOB 作为其元数据，因为只需要读取 OOB 来做闪存扫描，所以允许更快引导。另外，在牺牲一些性能的情况下，它也能把元数据保留在主页区上。

    尽管从 2004 年开始，YAFFS 就已经结合 Linux 用在真实产品上，但是至今它还没有进入内核主线。

    -  在 2007 年欧洲嵌入式 Linux 会议上，由 Wookey 做的关于 YAFFS2 的报告：[yaffs.pdf](http://tree.celinuxforum.org/CelfPubWiki/ELCEurope2007Presentations?action=AttachFile&do=get&target=yaffs.pdf)
    -  在第 17 届 CELF 盛会上做的关于 2.6.10 内核上的 YAFFS 和 JFFS2 比较的报告：[celf\_flash.pdf](http://tree.celinuxforum.org/CelfPubWiki/JapanTechnicalJamboree17?action=AttachFile&do=view&target=celf_flashfs.pdf)

    YAFFS2 遵守 GPL 许可，但是也可以在双重授权条款（来自Aleph One Ltd）下，用于商业领域。


## 挂载文件系统

根文件系统由内核挂载，它通过使用一个内核命令行选项来做到。其他的文件系统从用户空间挂载，通常是 init 脚本或者是 init 程序用 `mount` 命令来实现。

下面是 Linux 通过命令行挂载根文件系统的一些例子：

-   使用首个 IDE 驱动的第一个分区作为根文件系统（老内核）：
    -   `root=/dev/hda1`
-   在最新的内核中则这么用：
    -   `root=/dev/sda1`

-   使用 NFS 根文件系统（必须有相应内核配置支持）
    -   `root=/dev/nfs`

    通常还需要添加一些其他参数来确保配置好内核 IP 地址或者指定好主机的 NFS 文件系统路径。

-   使用闪存文件系统的第 2 个分区：
    -   `root=/dev/mtdblock2`

-   使用 initramfs
    -   `root=/dev/ram0`

    通常，还需要指定 ramdisk_size 之类并且要使能相应的内核配置选项。


### 在 PC 上用 mtdram 挂载 JFFS2 镜像

因为不可能用 loopback 设备挂载 JFFS2 镜像，所以需要用到 `mtdram`。通常要工作起来得用到三部分：

-   mtdram: 在内存中创建一个 MTD 分区。以 kb 为单位，用 `total_size` 设置文件大小参数。

-   mtdblock: 用于创建访问上述分区的块设备。

-   jffs2: 因为 JFFS2 通常并不作为 PC 上的文件系统使用，所以需要手动加载该模块。

<!-- -->

    modprobe mtdram total_size=16384
    modprobe mtdblock
    modprobe jffs2


取决于目标板的字节序（endianess），如果不同，镜像文件可能需要转换为 PC 上的字节序。MTD 工具套件中的 `jffs2dump` 可以用来做这个事情。

    jffs2dump -b -c -e <output-filename> <input-filename>

最后的镜像文件可以用 `dd` 命令拷贝到块设备上：

    dd if=<image-file> of=/dev/mtdblock0

挂载则跟往常一样：

    mount /dev/mtdblock0 /tmp/jffs2 -t jffs2



### 在 PC 上用 nandsim 挂载 UBI 镜像

首先创建一个模拟的 NAND 设备（大小为 256MB，2048 页）。`<number>_id_byte=` 设置为发回给 NAND 的 ID 字节数。

    $ sudo modprobe nandsim first_id_byte=0x20 second_id_byte=0xaa third_id_byte=0x00 fourth_id_byte=0x15

检查确保创建好设备：

    $ cat /proc/mtd
    dev:    size   erasesize  name
    mtd0: 10000000 00020000 "NAND simulator partition 0"

接下来，挂到一个 MTD 设备上：

    $ sudo modprobe ubi mtd=0

然后，为了格式化，需要先卸载：

    $ sudo ubidetach /dev/ubi_ctrl -m 0

如果上面的 `ubidetech` 这步失败了，直接跳到下面格式化该 MTD 设备：

    $ sudo ubiformat /dev/mtd0 -f <image>.ubi
    ubiformat: mtd0 (nand), size 268435456 bytes (256.0 MiB), 2048 eraseblocks of 131072 bytes (128.0 KiB), min. I/O size 2048 bytes
    libscan: scanning eraseblock 2047 -- 100 % complete
    ubiformat: 2048 eraseblocks have valid erase counter, mean value is 1
    ubiformat: flashing eraseblock 455 -- 100 % complete
    ubiformat: formatting eraseblock 2047 -- 100 % complete

再次挂上：

    $ sudo ubiattach /dev/ubi_ctrl -m 0
    UBI device number 0, total 2048 LEBs (264241152 bytes, 252.0 MiB), available 0 LEBs (0 bytes), LEB size 129024 bytes (126.0 KiB)

创建目录，并挂载该设备：

    $ mkdir temp
    $ sudo mount -t ubifs ubi0 temp


## 在嵌入式中使用通用文件系统的问题


### MMC/sdcard 卡特性

MMCs 和 SDcards 都是闪存设备，对于它们的主机而言，都呈现为面向块的接口。

通常，它们用在嵌入式设备中并且针对使用 FAT 文件系统的块访问进行了特定优化。但是，它们呈现出来像个“黑盒子”，里头有内置逻辑和算法，这些并没有暴露给主机。

有些工作正在进行中，例如调查刻画这些属性，进而可以使 Linux 能够更有效地使用这些设备：

- [https://wiki.linaro.org/WorkingGroups/KernelConsolidation/Projects/FlashCardSurvey](https://wiki.linaro.org/WorkingGroups/KernelConsolidation/Projects/FlashCardSurvey)
- [https://wiki.linaro.org/WorkingGroups/KernelConsolidation/Projects/FlashDeviceMapper](https://wiki.linaro.org/WorkingGroups/KernelConsolidation/Projects/FlashDeviceMapper) 


## 专用文件系统


### ABISS

主动块 IO 调度系统（The Active Block I/O Scheduling System）是一个文件系统，其设计初衷是为文件系统 I/O 活动提供实时功能。

- [ABISS](http://abiss.sourceforge.net/)


### 分层的文件系统

分层的文件系统允许我们挂载只读介质，但是也提供写入的能力。当然，写操作会在某些地方终止，这部分由分层文件系统透明地处理。这类文件系统存在了有相当一段时间，下面是已经在嵌入式 Linux 系统中使用的一些例子。


#### UnionFS

要是文件系统能覆盖彼此的话，有时候还是挺方便的。举个例子来说，在嵌入式产品中，如果在一个可读写的文件系统下面，挂载一个压缩的只读文件系统，那会很有用。因为它看上去不仅提供了一个完整的可读写文件系统，而且，因为这些文件在产品生命周期内并不会被改变，所以依然能够享受压缩的文件系统带来的空间节省的好处。

UnionFS 是提供这样一个文件系统（提供了多种文件系统的“联合”）的项目。可以看下[这里](http://www.filesystems.org/project-unionfs.html)。

也可以看下联合挂载，描述在[这里](http://lkml.org/lkml/2007/6/20/18)（如果该功能合并后，也可以看下内核源码下的 Documentation/union-mounts.txt）。


#### aufs

另外一个 UnionFS，可从 [http://aufs.sourceforge.net](http://aufs.sourceforge.net) 获取更多信息。


#### mini\_fo

minifo = 迷你展开覆盖文件系统（fanout overlay file system）.

从 [http://www.denx.de/wiki/Know.MiniFOHome](http://www.denx.de/wiki/Know.MiniFOHome) 可以获得更多信息。

显然该项目已经没人维护了，最后的信息还是 2005 年的。


## 性能和基准测试


### 性能评测工具

对于一个非常简单的磁盘性能测试，可以用 `dd` 命令做到。下面往文件系统写入一个内容为全零的 2G 文件，然后清掉缓存，再读回来：

-   dd if=/dev/zero of=test bs=1048576 count=2048
-   sync
-   sudo echo 3 \>/proc/sys/vm/drop\_caches
-   dd if=test of=/dev/null bs=1048576

我们也可以用 IOZone 来测试一个 Linux 文件系统的性能，看[这里](http://www.iozone.org/)。

Linux 桌面上常用的一些基准测试工具有：

-   [bonnie](http://www.coker.com.au/bonnie++/)
-   [dbench](http://samba.org/ftp/tridge/dbench/)
-   [tiobench：可移植的，完全线程化的 I/O 基准测试程序](http://sourceforge.net/projects/tiobench/)
-   [ffsb：灵活的文件系统基准测试程序](http://sourceforge.net/projects/ffsb/)


### 闪存文件系统比较


#### Cogent Embedded 公司的测试 (2013)

本节有一些链接，有关于基准测试程序、测试和调优的信息。

-   [eMMC/SSD 文件系统调优方法 v1.0](http://eLinux.org/images/b/b6/EMMC-SSD_File_System_Tuning_Methodology_v1.0.pdf "EMMC-SSD File System Tuning Methodology v1.0.pdf")
    -   包含测试方法和结果（性能和鲁棒性），在不同的闪存设备上调优不同的文件系统（包括 btrfs, ext3 和 f2fs）


#### Free Electrons 公司的测试 (2011)

2011 年时, CE Linux 论坛联合 Free Electrons，针对多个内核版本上的多种闪存文件系统做了系统性的测试。

测试结果在 [Flash\_Filesystem\_Benchmarks](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/File_Systems/Flash_Filesystem_Benchmarks/Flash_Filesystem_Benchmarks.html "Flash Filesystem Benchmarks")。


## 其他项目


### 多媒体文件系统

-   XPRESS 文件系统
    -   从 ELC 2007 上发现该文件系统项目最近在三星内部已经暂停


### 维基百科文件系统

一个可以挂载的虚拟文件系统，允许把基于 mediawiki 搭建的网站用普通编辑器当作普通文件访问。目前该文件系统没人维护了，通过[这里](http://wikipediafs.sourceforge.net/)查看更多信息。


### 维基文件系统

类似 维基百科文件系统，但是志在 Plan9 和 inferno，查看[这里](http://www.cs.bell-labs.com/magic/man2html/4/wikifs) 可获取更多信息。

[分类](http://eLinux.org/Special:Categories "Special:Categories"):

-   [文件系统](http://eLinux.org/Category:File_Systems "Category:File Systems")
