---
layout: post
author: 'Zhao Yimin'
title: "LWN 577218: Btrfs 入门"
# tagline: " 子标题，如果存在的话 "
album: "LWN 中文翻译"
group: "translation"
license: "cc-by-sa-4.0"
permalink: /lwn-577218/ 
description: "文章摘要：介绍如何开始上手使用 Btrfs 文件系统。"
category:
  - 文件系统
  - LWN
tags:
  - Linux
  - Btrfs
---

> 原文：[Btrfs: Getting started](https://lwn.net/Articles/577218/)
> 原创：By Jonathan Corbet @ Dec 11, 2013
> 翻译：By [Tacinight](https://github.com/tacinight)
> 校对：By [guojian-at-wowo](https://github.com/guojian-at-wowo)

> This is the second article in a series on the Btrfs filesystem; those who have not seen the first segment may wish to take a quick look. This installment will cover the basics of finding the requisite software and getting started with a Btrfs filesystem, while leaving the advanced features for the future. Using Btrfs as a simple Unix-style filesystem is a straightforward matter once the proper tools are in place.

这是介绍 Btrfs 文件系统系列文章的第二篇；那些没有看过第一篇的人可以快速浏览回顾一下第一篇文章。本部分将介绍一些基础知识，包括查找必要的前置软件以及如何开始使用 Btrfs 文件系统，同时留下一些高级功能以后讲解。一旦准备好适当的工具，Btrfs 作为一个简单 Unix 风格的文件系统，使用起来就会相当容易。

> The Btrfs filesystem code itself has been in the mainline kernel since the 2.6.29 release in early 2009. Since then, development of the in-kernel code has mostly been done upstream, so the mainline kernel contains all of the code that is deemed ready for use. In general, users wanting to use Btrfs for real work are probably best advised to stay close to the current mainline releases. Fixes are still being made at a high rate; it is probably preferable to run the fixed code than to get a demonstration of why the fixes were necessary. One can get even newer code by pulling from the [Btrfs development repository](https://btrfs.wiki.kernel.org/index.php/Btrfs_source_repositories), but that may be a bit too new for anybody who is not actively developing Btrfs.

Btrfs 文件系统的代码自 2009 年初内核发布 2.6.29 版本以来，就一直在存在于内核主线中。从那时起，Btrfs 内核部分代码的开发工作都已经基本完毕，所以内核主线已经包含了准备就绪，随时可以使用的代码。一般来说，希望在实际工作中使用 Btrfs 的用户，建议最好同步当前最新的主线版本。目前很多问题的修复工作仍在高速进行中，相比较去了解最新修复补丁的内容，直接去运行补丁代码可能更值得推荐。任何人可以直接从 [Btrfs 开发库][2] 中获取最新的代码，但是对于那些并非活跃的 Btrfs 开发者的人而言，那就有点儿太新了。

> The current user-space tools, which handle the creation and management of Btrfs filesystems, can be pulled from the repository at:

当前处理 Btrfs 文件系统创建和管理的用户空间工具可以从以下位置的仓库中提取：

```
git://git.kernel.org/pub/scm/linux/kernel/git/mason/btrfs-progs.git
```

> Until recently, the last "release" of btrfs-progs was 0.19, made in June 2009. Toward the end of November, though, the version number was [set to "v3.12"](https://lwn.net/Articles/577222/), inaugurating a new era in which version numbering will be tied to kernel releases. Btrfs developer Chris Mason noted at the time that he expected to make btrfs-progs releases with approximately the same frequency as the kernel going forward. Since much of the needed work is on the user-space side, this should be a welcome development for Btrfs users.

直到最近（译者注：文章的时间是 2013 年），btrfs-progs 的最新一个“发行版”是 2009 年 6 月份发布的 0.19。但到了11月底，版本号[被设置为”v3.12”][3]，进入了一个版本号绑定内核版本的新时代。Btrfs 开发人员 Chris Mason 当时指出，他预计将会以与内核更新的频率大致相同的频率发布 btrfs-progs 版本。由于大部分所需的工作都在用户空间上，所以对于 Btrfs 用户来说，这应该是一个值得高兴的事。

> Once again, those wanting to make serious use of Btrfs are likely to want to run something close to the current versions of the supporting user-space utilities. A lot of work (and bug fixes) is going into this code, but one needs to stay current to take advantage of that work. Some distributions follow progress in the btrfs-progs repository more closely than others; Fedora 19 already has v3.12, for example, so there is no real need for Fedora users to build their own version. Users whose distribution does not track the btrfs-progs repository so closely may want to install their own version built from the repository.

再一次申明，对于那些想要认真使用 Btrfs 的人而言，他们可能需要运行一些接近当前内核版本并且支持该版本的用户空间工具。很多工作（包括错误修复）正在加入到这个工具的代码中，但用户需要随时保持关注，才能使用最新的工作成果。一些发行版也要比其他发行版更加关注 btrfs-progs 的代码仓库；例如，Fedora 19 已经内置了版本为 v3.12 的工具，所以 Fedora 用户并不需要创建符合自己系统版本的工具。如果用户的发行版没有如此紧密地跟进 btrfs-progs 代码库，那么他们就需要依照直接系统的版本来安装构建自己的工具。

## 创建和挂载 Btrfs 文件系统 (Creating and mounting Btrfs filesystems)

> The utility to create a Btrfs filesystem is, unsurprisingly, mkfs.btrfs; it can be invoked directly or via the mkfs program. In its simplest form, it can be run as:

创建一个 Btrfs 文件系统正如意料之中那样简单，可以直接使用 `mkfs.btrfs` 命令，也可以通过 `mkfs` 程序创建。最简单的创建方式如下：

```
mkfs.btrfs /dev/partition-name
```

> Where partition-name is, of course, the actual name of the partition that is to contain the filesystem.

其中的 `partition-name` 是安装文件系统的分区的实际名称。

> Naturally, mkfs.btrfs has a fair number of options, though fewer than some other filesystems offer. Some of those that are relevant for basic usage include --force (necessary to convince mkfs.btrfs to overwrite an existing filesystem on the target partition), --label to set a label, and --version to just print out the version number and exit. One can also specify --mixed to cause the filesystem to mix data and metadata blocks together. Normally that will slow things down, so it is only recommended for situations where space is at an absolute premium; the [man page](http://man7.org/linux/man-pages/man8/mkfs.btrfs.8.html) suggests only using it for filesystems up to 1GB in size.

当然，`mkfs.btrfs` 有相当多的选项，但比其他的文件系统相对少一些。其中一些常用的基本用法包括 `--force`（必须指定这个选项，从而让 `mkfs.btrfs` 覆盖目标分区上的现有文件系统），`--label` 用来设置标签，`--version` 只是简单的打印版本号并且退出。也可以指定 `--mixed`，使文件系统将数据和元数据块混合在一起。通常这会降低文件系统效率，所以只能在存储空间绝对宝贵的情况下使用。[man 手册][4] 中建议仅将其用于最大1GB大小的文件系统中。

> Btrfs filesystems are made accessible via the mount command as usual. Like most non-trivial filesystems, Btrfs has [a number of specialized mount options](https://btrfs.wiki.kernel.org/index.php/Mount_options) that can be used to control its behavior. Some of these options will be discussed in later installments; a few that are of general interest include:

Btrfs 文件系统可以正常的通过 `mount` 命令来挂载访问。与大多数特殊的文件系统一样，Btrfs 有许多专门的[挂载选项][5]，用来控制安装好之后的运行活动。其中一些选项将在后面部分讨论；但有一些有意思的选项包括：

> - autodefrag  
> Enables automatic defragmentation of the filesystem in the background while it is running. Comments in the documentation suggest that this feature is still under development and may not produce optimal results for all workloads.
> - compress [=zlib|lzo|no]
> Turn on compression of data. With an argument, it specifies which compression algorithm should be used. The compress-force option forces the use of compression even on files that do not compress well.
> - nodatacow  
> Turns off the copy-on-write mechanism, but only for newly created files. Turning off COW removes an important integrity mechanism and disables compression and data checksumming. In a few situations (the documentation says "large database files") there may be a significant performance improvement, but most users will probably not want to use this option.
> - nodatasum  
> Turns off the creation of data checksums for newly created files.

- autodefrag  
在后台，打开文件系统的自动碎片整理功能。文档中的一些意见表明此功能仍在开发中，可能并不会在各种工作负载下产生理想的优化效果。
- compress [=zlib|lzo|no]  
打开数据压缩功能。其中可以用参数指定使用哪种压缩算法。（译者注：在 Wiki 中有 compress-force 这一选项）即使对不易压缩的文件，该功能也会强制对其进行压缩。
- nodatacow  
关闭写入时复制（copy on write，COW）机制，但仅对之后新创建的文件生效。关闭 COW 会使得文件系统重要的完整性机制失效，同时还会禁用压缩和数据校验功能。在少数情况下（例如在文档中提到的“大型数据库文件”）可能会有显著的性能改进，但大多数用户可能不会想使用此选项。
- nodatasum  
停止对新创建的文件启用数据校验功能。

> A mounted Btrfs filesystem feels mostly like any other Linux filesystem. Every now and then, some differences leak out. It can be disconcerting, for example, to delete a large file and not see an increase in the amount of available free space. Look back a minute or two later, though, and the missing space will have reappeared — assuming, of course, that said large file does not exist in any snapshots. Btrfs does a lot more work in the background than many other filesystems do.

挂载后 Btrfs 文件系统看起来似乎和其他 Linux 文件系统没什么两样。但是时不时也能看到一些不同之处。例如，删除一个大文件后，可用空间量并不会立即增加，这可能会令人不安。然而，一两分钟后再看一眼，消失的空间又再次出现了。当然，还要假设这个文件不存在任何快照。Btrfs 在后台方面相比许多其他文件系统做了很多的工作。

## Btrfs下的一些工具 (Other Btrfs tools)

> The btrfs-progs repository contains a number of programs beyond mkfs.btrfs. One of the more recent additions is the btrfsck filesystem check and repair tool. The [man page](http://man7.org/linux/man-pages/man8/btrfsck.8.html) makes the newness of this tool clear: "Considering it is not well-tested in real-life situations yet, if you have a broken Btrfs filesystem, btrfsck may not repair but cause additional damages." So users will want to think hard before running btrfsck in the --repair mode and, probably, make use of the "restore" functionality described below.

btrfs-progs 存储库包含许多除了 `mkfs.btrfs` 以外的程序。最近增加的一个是 `btrfsck` 文件系统检查和修复工具。[Man 手册][6] 中特地为这个新工具做了说明：“考虑到它在实际生产中还没有很好的被测试，如果你有一个损坏的 Btrfs 文件系统，btrfsck 可能无法修复它，而且可能造成更大的损坏。”所以用户在 `--repair` 修复模式下运行 `btrfsck` 之前可要好好想想，但是也可以使用待会要讲的“恢复”功能。

> The lack of a battle-hardened btrfsck utility remains one of the top reasons why system administrators often shy away from this filesystem. But the sad truth is that the only way to really make a truly comprehensive filesystem repair tool is to observe, over time, the ways in which a filesystem can become corrupted and come up with ways to fix those problems. So btrfsck will eventually mature into a tool that can handle a wide variety of problems, but there are no easy ways to shortcut that process.

没有经过足够 “战争洗礼” 的 btrfsck 工具也是系统管理员经常回避这个文件系统的首要原因之一。但是残酷的现实告诉我们，制作一个全面有效的文件系统修复工具的唯一方法就是：随着时间的推移，观察文件系统可能被破坏的方式，并提出解决这些问题的方法。所以 btrfsck 最终将成熟为一个可以处理各种问题的工具，但是在那之前，没有捷径可以缩短这个过程。

> Meanwhile, anybody working with Btrfs will eventually need to make use of another tool, called simply btrfs. This tool is the Swiss Army Knife of the Btrfs world; it can be used to perform a wide variety of actions on a Btrfs filesystem. Thus, unsurprisingly, btrfs implements a large number of commands, many of which will be examined in the later parts of this series. A few that merit mention now are:

同时，任何使用 Btrfs 文件系统的人都还需要使用的一个工具，简称为 btrfs 。这个工具是 Btrfs 世界的瑞士军刀；它可以用来在 Btrfs 文件系统上执行各种各样的操作。因此也毫不奇怪，btrfs 中提供了大量的命令，其中许多命令将在本系列后面的部分中进行介绍。但其中有一些值得一提的先放在这里：

> - `btrfs filesystem df filesystem`  
> Provides free space information about the given filesystem with more detail than is available from the standard df command.
> - `btrfs filesystem show [filesystem]`  
> Print information about one or more of the available Btrfs filesystems.
> - `btrfs filesystem defragment [file...]`  
> Perform online defragmentation of a Btrfs filesystem; defragmentation is limited to the given files if they are specified.
> - `btrfs restore device`  
> This command will try to extract the data from the given device, which, presumably, contains a filesystem with problems. By using this tool prior to attempting to repair the filesystem with btrfsck, a system administrator can maximize the chances of retrieving the data from the device even if btrfsck fails badly. See this wiki page for details on how to use this tool.
> - `btrfs scrub filesystem`  
> Launch a "scrub" operation on the given filesystem; scrubbing involves checking metadata and data against the checksums stored in the filesystem and correcting any errors found. Scrubbing can take some time, needless to say; it can be paused and resumed with variants of the btrfs scrub command if need be.
> - `btrfs send subvol`  
> - `btrfs receive mount`  
> Controls the [send/receive](https://lwn.net/Articles/506244/) functionality, which can be used to replicate filesystems remotely or to implement incremental backup operations.

- `btrfs filesystem df filesystem`  
提供有关指定文件系统的可用空间信息，其详细信息可能比标准 df 命令的要更多。
- `btrfs filesystem show [filesystem]`  
打印有关一个或多个可用 Btrfs 文件系统的信息。
- `btrfs filesystem defragment [file...]`  
执行 Btrfs 文件系统的联机碎片整理；可以通过参数指定来限定碎片整理的文件范围。
- `btrfs restore device`  
这个命令会尝试从给定的设备中提取数据，其中该设备中可能包含一个有问题的文件系统。可以在尝试使用 btrfsck 修复文件系统之前使用此工具。这样即便 btrfsck 运行失败了，系统管理员也可以最大限度地提高从设备中恢复数据的机会。请参阅此[维基页面][7] 以了解更多关于如何使用此工具的详细信息。
- `btrfs scrub filesystem`  
在给定的文件系统上启动“擦洗”操作；擦洗包括检查元数据和数据存储在文件系统中的校验和，发现并纠正错误。不用说，擦洗操作非常耗时；如果需要的话，可以通过 `btrfs scrub` 中其他子命令（译者注：如 `cancel` 暂停，`resume` 恢复）的来暂停或者恢复。
- `btrfs send subvol`  
- `btrfs receive mount`  
控制 [发送/接收][8] 功能，可用于远程复制文件系统或实施增量备份操作。

> The basics described thus far are enough to get started with Btrfs, treating it as just another Unix-style filesystem, possibly with added compression and data checksumming. But it's the advanced features of the Btrfs filesystem that make it truly unique in the Linux world. One of those features — the built-in multiple-device and RAID functionality — will be the subject of the next installment in this series.

到目前为止所描述的基本知识已经足够开始使用 Btrfs。我们将它视为另一种 Unix 风格的文件系统就好，还顺带地增加了压缩功能和数据校验功能。但正是这些 Btrfs 文件系统的高级功能，使其在 Linux 世界中成为真正独特的存在。例如，”内置的多设备和 RAID 功能“特性，而这个特性将成为本系列下一篇文章的主题。

[1]: http://tinylab.org
[2]: https://btrfs.wiki.kernel.org/index.php/Btrfs_source_repositories
[3]: https://lwn.net/Articles/577222/
[4]: http://man7.org/linux/man-pages/man8/mkfs.btrfs.8.html
[5]: https://btrfs.wiki.kernel.org/index.php/Mount_options
[6]: http://man7.org/linux/man-pages/man8/btrfsck.8.html
[7]: https://btrfs.wiki.kernel.org/index.php/Restore
[8]: https://lwn.net/Articles/506244/
