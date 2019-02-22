---
layout: post
author: 'Zhao Yimin'
title: "LWN 576276: Btrfs文件系统介绍"
# tagline: " 子标题，如果存在的话 "
album: "LWN 中文翻译"
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-576276/
description: "LWN 文章翻译，本文是系列文章的第一篇，简单介绍了 Btrfs 文件系统，包括了发展历史以及一些简要的特性介绍。"
category:
  - 文件系统
  - LWN
tags:
  - Linux
  - btrfs
---
> 原文：[The Btrfs filesystem: An introduction](https://lwn.net/Articles/576276/)
> 原创：By Jonathan Corbet @ Dec 11, 2013
> 翻译：By Tacinight of [TinyLab.org][1] @ Nov 28, 2017
> 校对：By Unicornx of [TinyLab.org][1]

> The Btrfs filesystem has been through almost every part of the hype cycle at one point or another in its short history. For a time, it was the next-generation filesystem that was going to solve many of our problems; distributors were racing to see who could be the first to ship it by default. Then it became clear that all those longtime filesystem developers weren't totally out to lunch when they warned that it takes many years to get a filesystem to a point where it can be trusted with important data. At this point, it is possible to go to a conference and hear almost nothing positive about Btrfs; disillusionment appears to have set in. By the time Btrfs is truly ready, some seem to think, it will be thoroughly obsolete.

Btrfs 文件系统几乎在它短暂的历史中，经历了舆论评价的大起大落。有一段时间，它被视为将解决我们许多问题的下一代文件系统； Linux 版本的发行商们正在争先恐后地看到谁可能首先搭载它。后来，那些长期以来的文件系统开发人员还仍然很清醒，他们警告说还需要假以时日才能信任其在重要数据应用上的稳定支持能力。现在，你可能去参加一个会议并且几乎听不到任何关于Btrfs的积极态度；幻想似乎已经破灭了。在Btrfs还没真正准备好的时候，有些人甚至已经认为它彻底过时了。

> The truth may not be quite so grim. Development on Btrfs continues, with a strong emphasis on stability and performance. Problems are getting fixed, and users are beginning to take another look at this promising filesystem. More users are beginning to play with it, and openSUSE considered the idea of using it by default back in September. Your editor's sense is that the situation may be bottoming out, and that we may, slowly, be heading into a new phase where Btrfs takes its place — still slowly — as one of the key Linux filesystems.  
  
事实可能不是那么严峻。Btrfs 的发展仍在继续，其重点在于加强稳定性和改进性能。问题也正在被得到解决，用户开始重新审视这个有前途的文件系统。越来越多的用户也开始使用它，openSUSE 在9月份时就考虑过使用它的想法。小编的感觉是，情况可能已从低谷走出，接下来我们可能会慢慢地进入一个新的阶段：Btrfs 将成为 Linux 关键的文件系统之一，虽然这个过程仍然是漫长的。

> This article is intended to be the first in a series for users interested in experimenting with and evaluating the Btrfs filesystem. We'll start with the basics of the design of the filesystem and how it is being developed; that will be followed by a detailed look at specific Btrfs features. One thing that will not appear in this series, though, is benchmark results; experience says that proper filesystem benchmarking is hard to do right; it's also highly workload- and hardware-dependent. Poor-quality results would not be helpful to anybody, so your editor will simply not try.

小编准备为有兴趣尝试和评估 Btrfs 文件系统的用户撰写一个系列文章，本文则是该系列文章的第一篇。我们将从文件系统设计的基础知识开始，介绍它是如何发展的。之后将详细介绍特定的 Btrfs 特性。但是，这个系列中不会出现基准测试结果。经验表明，精确的文件系统基准测试是很难做到的，因为这对测试负载和硬件高度依赖。质量不好的结果不会对任何人有帮助，所以小编也不会轻易去尝试。

## 是什么让 Btrfs 与众不同？ (What makes Btrfs different?) 

> Not that long ago, Linux users were still working with filesystems that had evolved little since the Unix days. The ext3 filesystem, for example, was still using block pointers: each file's inode (the central data structure holding all the information about the file) contained a list of pointers to each individual block holding the file's data. That design worked well enough when files were small, but it scales poorly: a 1GB file would require 256K individual block pointers. More recent filesystems (including ext4) use pointers to "extents" instead; each extent is a group of contiguous blocks. Since filesystems work to store data contiguously anyway, extent-based storage greatly reduces the overhead of managing a file's space.

不久以前，Linux 用户还在使用自Unix时代以来几乎没有进化的文件系统。例如，ext3 文件系统，它仍在使用块(block)指针：每个文件的inode（包含所有关于文件的信息的中央数据结构）都包含指向保存文件数据的每个单独块(block)的指针列表。当文件很小的时候，这种设计能工作得很好，但是它的扩展性很差：一个 1GB 的文件需要 256K 大小的空间存放独立的块(block)指针。一些最新的文件系统（包括 ext4 ）使用指向“范围(extent)”的指针；每个范围(extent)是一组连续的块(block)。由于文件系统总是连续存储数据，基于范围(extent)的存储大大减少了管理文件空间的开销。

> Naturally, Btrfs uses extents as well. But it differs from most other Linux filesystems in a significant way: it is a "copy-on-write" (or "COW") filesystem. When data is overwritten in an ext4 filesystem, the new data is written on top of the existing data on the storage device, destroying the old copy. Btrfs, instead, will move overwritten blocks elsewhere in the filesystem and write the new data there, leaving the older copy of the data in place.

自然地，Btrfs 也使用基于范围(extent)的存储。但它与大多数其他 Linux 文件系统有很大的不同：它是一个“写入时拷贝”（copy-on-write，以下简称"COW"）的文件系统。当数据在 ext4 文件系统中被覆盖时，新数据被写在存储设备中现有数据之上，并且销毁旧的副本。相反，Btrfs 会把文件系统中，需要覆盖的块移动到其他位置，在新的空间中写入数据，留下较旧的数据副本不受影响（译者注：之后会有相应的回收机制清理）。

> The COW mode of operation brings some significant advantages. Since old data is not overwritten, recovery from crashes and power failures should be more straightforward; if a transaction has not completed, the previous state of the data (and metadata) will be where it always was. So, among other things, a COW filesystem does not need to implement a separate journal to provide crash resistance.

COW 操作模式带来了一些显着的优点。由于旧数据不会被覆盖，所以从崩溃和电源故障恢复应该会更直接；如果一个事务还没有完成，数据（和元数据）的前一个状态将会在原来的地方保持不变。所以，COW 文件系统不需要额外的日志功能来提供宕机后的数据一致性恢复问题。

> Copy-on-write also enables some interesting new features, the most notable of which is snapshots. A snapshot is a virtual copy of the filesystem's contents; it can be created without copying any of the data at all. If, at some later point, a block of data is changed (in either the snapshot or the original), that one block is copied while all of the unchanged data remains shared. Snapshots can be used to provide a sort of "time machine" functionality, or to simply roll back the system after a failed update.

写入时复制还可以启用一些有趣的新功能，其中最值得一提的是快照功能。快照是文件系统内容的虚拟副本；它可以在不复制任何数据的情况下创建。如果在稍后的某个时间点，某个数据块被更改（在快照或原始数据中），那么那个块将被复制，同时所有未更改的数据保持共享。快照可用于提供类似于“时间机器”的功能，或者在一次更新失败后简单地回滚系统。

> Another important Btrfs feature is its built-in volume manager. A Btrfs filesystem can span multiple physical devices in a number of RAID configurations. Any given volume (collection of one or more physical drives) can also be split into "subvolumes," which can be thought of as independent filesystems sharing a single physical volume set. So Btrfs makes it possible to group part or all of a system's storage into a big pool, then share that pool among a set of filesystems, each with its own usage limits.

另一个 Btrfs 重要的功能是其内置的卷管理器。一个 Btrfs 文件系统可以在多个 RAID 配置中跨越多个物理设备。任何给定的卷（一个或多个物理驱动器的集合）也可以分成“子卷”，这可以被认为是共享单个物理卷集的独立文件系统。因此，Btrfs 可以将系统的部分或全部存储聚合成一个大的存储池，然后将这个池共享给一组文件系统，每个文件系统都有自己的使用限制。

> Btrfs offers a wide range of other features not supported by other Linux filesystems. It can perform full checksumming of both data and metadata, making it robust in the face of data corruption by the hardware. Full checksumming is expensive, though, so it remains likely to be used in only a minority of installations. Data can be stored on-disk in compressed form. The send/receive feature can be used as part of an incremental backup scheme, among other things. The online defragmentation mechanism can fix up fragmented files in a running filesystem. The 3.12 kernel saw the addition of an offline de-duplication feature; it scans for blocks containing duplicated data and collapses them down to a single, shared copy. And so on.

Btrfs 还提供了一大堆其他 Linux 文件系统不支持的功能。它可以对数据和元数据执行完整的校验和检查，使其在面对硬件数据损坏的情况下保持可靠性。尽管如此，全面的校验仍是昂贵的，所以它只会被用于少数安装场合。数据可以以压缩形式存储在磁盘上。另外，发送/接收功能可以用作增量备份方案的一部分。联机碎片整理机制可以修复正在运行的文件系统中的碎片文件。 3.12 内核增加了一个脱机重复数据删除功能；它会扫描包含重复数据的块，并将其合并为单个共享副本。这样的功能还有很多。

> It is worth noting that the copy-on-write approach is not without its costs. Obviously, some sort of garbage collection is required or all those block copies will quickly eat up all of the available space on the filesystem. Copying blocks can take more time than simply overwriting them as well as significantly increasing the filesystem's memory requirements. COW operations will also have a tendency to fragment files, wrecking the nice, contiguous layout that the filesystem code put so much effort into creating. Fragmentation hurts less with solid-state devices than on rotational storage, but, even in the former case, fragmented files will not be as quick to access.

值得注意的是，写入时复制的方法并不是没有代价的。很明显，需要某种垃圾回收机制，否则所有这些块副本会快速占用文件系统上的所有可用空间。相比简单地覆盖数据块，复制块需要花费更多的时间，以及会显著增加文件系统的内存需求。COW 操作也倾向于导致文件碎片化，这会破坏文件系统致力于追求的，所谓的存储连续分布的布局。固态硬盘的碎片化造成的损害比机械硬盘要少，但即使在前一种情况下，碎片文件也不能被快速访问。

> So all this shiny new Btrfs functionality does not come for free. In many settings, administrators may well decide that the costs associated with Btrfs outweigh the benefits; those sites will stick with filesystems like ext4 or XFS. For others, though, the flexibility and feature set provided with Btrfs are likely to be quite appealing. Once it is generally accepted that Btrfs is ready for real-world use, chances are it will start popping up on a lot of systems.

所以所有这些 Btrfs 诱人的新功能都是需要付出一定代价的。在许多情况下，系统管理员可能会认为 Btrfs 带来的相关的成本要大于它的好处；这些站点也将继续拥护像 ext4 或 XFS 这样的文件系统。但对于其他人来说，Btrfs 提供的灵活性和功能集可能会相当吸引人。一旦 Btrfs 准备就绪并且被人们所普遍接受，相信其很快就会在众多系统上得到应用。

## 发展 (Development)

> One concern your editor has heard in conference hallways is that the pace of Btrfs development has slowed. For the curious, here's the changeset count history for the Btrfs code in the kernel, grouped into approximately one-year periods:

小编听闻一件可能让人有所顾虑的事情是，Btrfs 的开发进程有放缓的趋势。出于关切，我将 btrfs 在内核中的变更记录按照以一年为单位整理出来，供大家参考：

|Year	|Changesets	|Developers
|----|---|----|
|2008 (2.6.25—29)	|913	|42
|2009 (2.6.30—33)	|279	|45
|2010 (2.6.34—37)	|193	|33
|2011 (2.6.38—3.2)	|610	|67
|2012 (3.3—8)	|773	|63
|2013 (3.9—13)	|671	|68

> These numbers, on their own, do not demonstrate a slowing of development; there was an apparent slow period in 2010, but the number of changesets and the number of developers contributing them has held steady thereafter. That said, there are a couple of things to bear in mind when looking at those numbers. One is that the early work involved the addition of features to a brand-new filesystem, while work in 2013 is almost entirely fixes. So the size of the changes has shrunk considerably, but one could easily argue that things should be just that way.

这些数字本身并没有表现出发展速度放缓的痕迹; 2010 年有一个明显的缓慢时期，但改动的数量和开发者的数量在此后保持稳定。也就是说，在查看这些数字时，需要牢记几件事情。一个是，早期的工作涉及到为一个全新的文件系统添加功能，而这些在 2013 年的工作中几乎完全修复完了。所以变化的规模已经大大缩小了，但是人们想当然的认为变慢是一件不好的事情，这样的担心是没有必要的。

> The other relevant point is that contributions by Btrfs creator Chris Mason have clearly fallen in recent years. Partly that is because he has been working on the user-space btrfs-progs code — work which is not reflected in the above, kernel-side-only numbers — but it also seems clear that he has been busy with other work-related issues. It will be interesting to see how things change now that Chris and prolific Btrfs contributor Josef Bacik have found a new home at Facebook.

另一个相关的观点是 Btrfs 的创造者 Chris Mason 的贡献近年来明显下降。部分原因是因为他一直在研究用户空间 btrfs-progs 代码 - 这在上面的内核方面没有反映出来 - 但是似乎很清楚，他一直在忙于其他与工作相关的问题。一个有意思的事是，Chris 和高产的 Btrfs 贡献者 Josef Bacik 入职了 Facebook，之后看看事情会发生怎样的变化吧。

> In summary, the amount of new code going into Btrfs has clearly fallen in recent years, but that will be seen as good news by anybody hoping for a stable filesystem anytime soon. There is still some significant effort going into this filesystem, and chances are good that developer attention will increase as distributors look more closely at using Btrfs by default.

总之，进入 Btrfs 的新代码的数量近年虽然有所下降，但任何人都能在不久的将来看到一个更加稳定的文件系统，这算是一个好消息。这个文件系统还有一些重要的工作要做，而且随着发行版更倾向于地使用 Btrfs 作为他们默认的文件系统，开发人员的关注度也会提高。

## 下一步是什么 (What's next)

> All told, Btrfs still looks interesting, and it seems like the right time to take a closer look at what is still the next generation Linux filesystem. Now that the introductory material is out of the way, the next article in this series will start to actually play with Btrfs and explore its feature set. Those articles (appearing here as they are published) are:

总而言之，Btrfs 看起来还是很有趣的，现在看来，正是时候仔细研究这个下一代的 Linux 文件系统了。本篇介绍的材料就到此为止了，本系列的下一篇文章将开始接受如何使用 Btrfs 并探索其功能集。这些文章（出现在这的是已经发布了的）包括：

> - [Getting started](https://lwn.net/Articles/577218/): where to get the software, and the basics of creating and using a Btrfs filesystem.  
> - [Working with multiple devices](https://lwn.net/Articles/577961/): a Btrfs filesystem is not limited to a physical device; instead, the filesystem supports multiple-device filesystems in a number of RAID and RAID-like configurations. This article describes that functionality and how to make use of it.  
> - [Subvolumes and snapshots](https://lwn.net/Articles/579009/): creating multiple filesystems on a single storage volume, along with the associated snapshot mechanism.  
> - [Send/receive and ioctl()](https://lwn.net/Articles/581558/): using the send/receive feature for incremental backups, a brief overview of functionality available with ioctl(), and concluding notes.  
> By the end of the series, we plan to have a reasonably comprehensive introduction to Btrfs in place; stay tuned.

- [入门](https://lwn.net/Articles/577218/)：从哪里获得软件，以及创建和使用 Btrfs 文件系统的基础知识。  
- [使用多个设备](https://lwn.net/Articles/577961/)：Btrfs 文件系统不限于物理设备；相反，文件系统支持多个 RAID 和类 RAID 配置的多设备文件系统。本文将介绍该功能以及如何使用它。  
- [子卷和快照](https://lwn.net/Articles/579009/)：在单个存储卷上创建多个文件系统以及相关的快照机制。  
- [发送/接收和ioctl()](https://lwn.net/Articles/581558/)：使用发送/接收功能进行增量备份，简要介绍 ioctl() 提供的功能以及结束语。  

在系列的最后，我们计划对 Btrfs 进行合理全面的介绍，敬请关注。

[1]: http://tinylab.org
[2]: http://tinylab.org/lwn
