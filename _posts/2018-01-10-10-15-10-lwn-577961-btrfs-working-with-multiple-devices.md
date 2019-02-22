---
layout: post
author: 'Zhao Yimin'
title: "LWN 577961: Btrfs 同多设备协作"
# tagline: " 子标题，如果存在的话 "
album: "LWN 中文翻译"
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-577961/
description: " 文章摘要 "
plugin: mermaid
category:
  - 文件系统
  - LWN
tags:
  - Linux
  - btrfs
---
> 原文：[Btrfs: Working with multiple devices](https://lwn.net/Articles/577961/)
> 原创：By Jonathan Corbet @ Dec 30, 2013
> 翻译：By Tacinight of [TinyLab.org][1]
> 校对：By [fan-xin](https://github.com/fan-xin)

> The previous installments of this series on the Btrfs filesystem have focused on the basics of using Btrfs like any other Linux filesystem. But Btrfs offers a number of features not supported by the alternatives; near the top of that list is support for multiple physical devices. Btrfs is not just a filesystem; it also has its own RAID mechanism built in. This article will delve into how this feature works and how to make use of it.

在本系列的前几部分中，我们集中讨论了如何像使用其他 Linux 文件系统一样使用 Btrfs。但是 Btrfs 还提供了大量不能被其他文件系统所替代的特性。而这些特性中，比较特别的一条是支持多个物理设备。 Btrfs 不只是一个文件系统，它还内置了自己的 RAID 机制。本文将深入研究这个功能，讲解工作原理以及如何使用它。

> There are two fundamental reasons to want to spread a single filesystem across multiple physical devices: increased capacity and greater reliability. In some configurations, RAID can also offer improved throughput for certain types of workloads, though throughput tends to be a secondary consideration. RAID arrays can be arranged into a number of configurations ("levels") that offer varying trade-offs between these parameters. Btrfs does not support all of the available RAID levels, but it does have support for the levels that most people actually want to use.

想要在单个文件系统中跨越多个物理设备有很多原因，其中最根本的两个原因是：增加容量和提高可靠性。在一些配置中，RAID 还可以为某些类型的工作负载提供更好的吞吐量，尽管吞吐量往往是次要的考虑因素。RAID 阵列可以编排成多个配置（“级别”），这些配置可以在例如吞吐量，容量等参数之间提供不同的权衡。Btrfs 不支持所有的 RAID 级别，但它所支持的级别已经足够大多数人实际使用。

> RAID 0 ("striping") can be thought of as a way of concatenating multiple physical disks together into a single, larger virtual drive. A strict striping implementation distributes data across the drives in a well-defined set of "stripes"; as a result, all of the drives must be the same size, and the total capacity is simply the product of the number of drives and the capacity of any individual drive in the array. Btrfs can be a bit more flexible than this, though, supporting a concatenation mode (called "single") which can work with unequally sized drives. In theory, any number of drives can be combined into a RAID 0 or "single" array.

RAID 0（译者注，这里“striping”译为“分条化”，或者”分条技术“，数据分条形成的具体单元称为”带区“，”带区集“）可以被认为是将多个物理磁盘连接成一个单一的，更大的虚拟磁盘的一种方式。在严格的分条化实现中，它通过定义良好的“带区”集合在磁盘中分配数据; 因此，所有磁盘必须具有相同的大小，并且整个虚拟磁盘的总容量仅仅是磁盘数量和阵列中任何单个磁盘的容量的乘积。然而 Btrfs 可以比这个更灵活一些，它支持一个连接模式（称为“单一模式”），可以使用不同大小的磁盘。理论上，任何数量的磁盘都可以组合成 RAID 0 或“单一”阵列。

> RAID 1 ("mirroring") trades off capacity for reliability; in a RAID 1 array, two drives (of the same size) store identical copies of all data. The failure of a single drive can kill an entire RAID 0 array, but a RAID 1 array will lose no data in that situation. RAID 1 arrays will be slower for write-heavy use, since all data must be written twice, but they can be faster for read-heavy workloads, since any given read can be satisfied by either drive in the array.

RAID 1（“镜像”）为了可靠性折衷了容量; 在 RAID 1 阵列中，两个（相同大小的）磁盘存储所有数据的相同副本。单个磁盘的故障会导致整个 RAID 0 阵列故障，但是在这种情况下，RAID 1 阵列将不会丢失任何数据。因为所有数据都必须写入两次，所以 RAID 1 阵列的写入速度会比较慢，但在偏重读取的工作负载下速度会更快，因为任何给定的读取都可以由阵列中的任意一个磁盘来响应。

> RAID 10 is a simple combination of RAID 0 and RAID 1; at least two pairs of drives are organized into independent RAID 1 mirrored arrays, then data is striped across those pairs.

RAID 10 是 RAID 0 和 RAID 1 的简单组合; 通过至少有两对磁盘组织成独立的 RAID 1 镜像阵列，然后再将数据在这些 RAID 1 镜像组之间分条，形成 RAID 0。

> RAID 2, RAID 3, and RAID 4 are not heavily used, and they are not supported by Btrfs. RAID 5 can be thought of as a collection of striped drives with a parity drive added on (in reality, the parity data is usually distributed across all drives). A RAID 5 array with N drives has the storage capacity of a striped array with N-1 drives, but it can also survive the failure of any single drive in the array. RAID 6 uses a second parity drive, increasing the amount of space lost to parity blocks but adding the ability to lose two drives simultaneously without losing any data. A RAID 5 array must have at least three drives to make sense, while RAID 6 needs four drives. Both RAID 5 and RAID 6 are supported by Btrfs.

RAID 2，RAID 3 和 RAID 4 并没有被大量使用，因此 Btrfs 也不支持它们。RAID 5 可以被认为是带有奇偶校验磁盘的分条磁盘的集合（实际上，奇偶校验数据通常分布在所有磁盘上）。具有 N 个磁盘的 RAID 5 阵列具有 N-1 个磁盘的分条阵列的存储容量，当阵列中的任何单个磁盘发生故障时，整个阵列依旧可以正常运转。RAID 6 增加了第二块奇偶校验盘，因此虽然增加了奇偶校验块的空间占用量，但也保证了即使丢失两个磁盘数据后，阵列整体依旧能平稳运行。RAID 5 阵列必须至少有三个磁盘才能有效运行，而 RAID 6 则需要四块磁盘。 Btrfs 同时支持 RAID 5 和 RAID 6。

> One other noteworthy point is that Btrfs goes out of its way to treat metadata differently than file data. A loss of metadata can threaten the entire filesystem, while the loss of file data affects only that one file — a lower-cost, if still highly undesirable, failure. Metadata is usually stored in duplicate form in Btrfs filesystems, even when a single drive is in use. But the administrator can explicitly configure how data and metadata are stored on any given array, and the two can be configured differently: data might be simply striped in a RAID 0 configuration, for example, while metadata is stored in RAID 5 mode in the same filesystem. And, for added fun, these parameters can be changed on the fly.

另外值得注意的一点是，Btrfs 不像对待文件数据那样对待元数据。元数据的丢失可能威胁到整个文件系统，而文件数据的丢失只影响到一个文件 - 尽管是一个代价较低的错误，但仍是不能接受。元数据通常在 Btrfs 文件系统中重复存储着，即使使用单个磁盘的时候也是如此。但管理员可以明确地配置数据和元数据如何存储在给定的阵列上，并且可以以不同的方式进行配置：例如，文件数据可能是配置成 RAID 0 这样的分条存储模式，而元数据则可以 RAID 5 的模式存储在同一个文件系统中。而且，好像是为了好玩，这些参数可以随时更改。

## 一个分条磁盘示例（A striping example）
> Earlier in this series, we used mkfs.btrfs to create a simple Btrfs filesystem. A more complete version of this command for the creation of multiple-device arrays looks like this:

在本系列前面部分，我们使用了 mkfs.btrfs 来创建一个简单的 Btrfs 文件系统。此命令用于创建多设备阵列时更完整版本如下：

    mkfs.btrfs -d mode -m mode dev1 dev2 ...

> This command will group the given devices together into a single array and build a filesystem on that array. The -d option describes how data will be stored on that array; it can be single, raid0, raid1, raid10, raid5, or raid6. The placement of metadata, instead, is controlled with -m; in addition to the modes available for -d, it supports dup (metadata is stored twice somewhere in the filesystem). The storage modes for data and metadata are not required to be the same.

这个命令将把给定的设备组合成一个设备集合，并在该设备集合上建立一个文件系统。`-d` 选项描述了文件数据如何存储在该集合上; 它可以是 single，raid 0，raid 1，raid 10，raid 5 或 raid 6。相对的，元数据的存放由 `-m` 来控制; 除了 `-d` 选项中可用的模式之外，它还支持 `dup`（元数据将在文件系统中的有两个备份）。数据和元数据的存储模式不需要完全相同。

> So, for example, a simple striped array with two drives could be created with:

因此，例如，可以使用两个磁盘创建一个简单的分条阵列：

    mkfs.btrfs -d raid0 /dev/sdb1 /dev/sdc1

> Here, we have specified striping for the data; the default for metadata will be dup. This filesystem is mounted with the mount command as usual. Either /dev/sdb1 or /dev/sdc1 can be specified as the drive containing the filesystem; Btrfs will find all other drives in the array automatically.

在这里，我们已经为数据指定了分条模式。元数据的默认值是 `dup`。这个文件系统像平常一样使用 `mount` 命令来挂载。可以将` /dev/sdb1` 或 `/dev/sdc1` 指定为包含文件系统的磁盘; Btrfs 将自动查找阵列中的所有其他磁盘。

> The df command will only list the first drive in the array. So, for example, a two-drive RAID 0 filesystem with a bit of data on it looks like this:

`df` 命令将仅列出阵列中的第一个磁盘。所以，比如一个双磁盘的 RAID 0 文件系统上有一些数据就会像下面这样：

    # df -h /mnt
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/sdb1       274G   30G  241G  11% /mnt

> More information can be had with the btrfs command:

`btrfs` 命令中提供了更多的信息：

    root@dt:~# btrfs filesystem show /mnt
    Label: none  uuid: 4714fca3-bfcb-4130-ad2f-f560f2e12f8e
	    Total devices 2 FS bytes used 27.75GiB
	    devid    1 size 136.72GiB used 17.03GiB path /dev/sdb1
	    devid    2 size 136.72GiB used 17.01GiB path /dev/sdc1

> (Subcommands to btrfs can be abbreviated, so one could type "fi" instead of "filesystem", but full commands will be used here). This output shows the data split evenly across the two physical devices; the total space consumed (17GiB on each device) somewhat exceeds the size of the stored data. That shows a commonly encountered characteristic of Btrfs: the amount of free space shown by a command like df is almost certainly not the amount of data that can actually be stored on the drive. Here we are seeing the added cost of duplicated metadata, among other things; as we will see below, the discrepancy between the available space shown by df and reality is even greater for some of the other storage modes.

（`btrfs` 的子命令可以缩写，可以输入 `fi` 来替代 `filesystem`，但是这里使用了完整版的命令）。此输出显示数据在两个物理设备上均匀分配; 所消耗的总空间（每个设备上有 17GB）略微超过了实际存储数据的大小。这显示了 Btrfs 经常遇到的一个特点：像 `df` 这样的命令显示的可用空间量几乎肯定不是实际上存储在磁盘上的数据量。在这里，我们看到了由于重复元数据所导致的成本增加。正如我们在下面也将看到的，由 `df` 显示的的可用空间和实际可用空间之间的差异，在其他一些存储模式下面甚至更大。

## 设备的添加和移除（Device addition and removal）
> Naturally, no matter how large a particular filesystem is when the administrator sets it up, it will prove too small in the long run. That is simply one of the universal truths of system administration. Happily, Btrfs makes it easy to respond to a situation like that; adding another drive (call it "/dev/sdd1") to the array described above is a simple matter of:

当然，不管管理员初始设置的一个特定文件系统有多大，从长远来看，这个文件系统都会变得不够用。这是系统管理的普遍真理之一。令人欣喜的是，Btrfs 可以轻松应对这种情况。向上述的磁盘集合中再添加另一个磁盘（例如 `/dev/sdd1`）是一件相当容易的事情：

    # btrfs device add /dev/sdd1 /mnt

> Note that this addition can be done while the filesystem is live — no downtime required. Querying the state of the updated filesystem reveals:

请注意，这个添加操作可以在文件系统正在运行时执行 - 而这并不需要停机。查询更新的文件系统的状态显示如下：

    # df -h /mnt
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/sdb1       411G   30G  361G   8% /mnt

    # btrfs filesystem show /mnt
    Label: none  uuid: 4714fca3-bfcb-4130-ad2f-f560f2e12f8e
	    Total devices 3 FS bytes used 27.75GiB
	    devid    1 size 136.72GiB used 17.03GiB path /dev/sdb1
	    devid    2 size 136.72GiB used 17.01GiB path /dev/sdc1
	    devid    3 size 136.72GiB used 0.00 path /dev/sdd1

> The filesystem has been expanded with the addition of the new space, but there is no space consumed on the new drive. It is, thus, not a truly striped filesystem at this point, though the difference can be hard to tell. New data copied into the filesystem will be striped across all three drives, so the amount of used space will remain unbalanced unless explicit action is taken. To balance out the filesystem, run:

注意到这里，文件系统已经新增加了的空间，但在新磁盘上并没有空间占用。尽管一个分条文件系统是什么样很难说清楚，但在这里，它还不是一个真正意义上的分条文件系统。新复制到文件系统中的数据将在这三个磁盘上分条存放，但是现在，除非采取明确的操作，已使用空间的将继续保持着不平衡的状态。要平衡文件系统，请运行以下命令：

    # btrfs balance start -d -m /mnt
    Done, had to relocate 23 out of 23 chunks

> The flags say to balance both data and metadata across the array. A balance operation involves moving a lot of data between drives, so it can take some time to complete; it will also slow access to the filesystem. There are subcommands to pause, resume, and cancel the operation if need be. Once it is complete, the picture of the filesystem looks a little different:

选项标志（`-d` 和 `-m`）表示要在整个阵列同时平衡数据和元数据。平衡操作涉及在磁盘之间移动大量数据，因此可能需要一些时间才能完成。它也会减慢这期间对文件系统的访问速度。如果需要，有子命令可以用来暂停，恢复和取消操作。一旦完成后，这时文件系统的样子看起来就有点不同了：

    # btrfs filesystem show /mnt
    Label: none  uuid: 4714fca3-bfcb-4130-ad2f-f560f2e12f8e
	    Total devices 3 FS bytes used 27.78GiB
	    devid    1 size 136.72GiB used 10.03GiB path /dev/sdb1
	    devid    2 size 136.72GiB used 10.03GiB path /dev/sdc1
	    devid    3 size 136.72GiB used 11.00GiB path /dev/sdd1
> The data has now been balanced (approximately) equally across the three drives in the array.

现在数据已经在阵列中的三个磁盘间大致平衡了。

> Devices can also be removed from an array with a command like:

也可以使用如下命令从阵列中删除设备：

    # btrfs device delete /dev/sdb1 /mnt

> Before the device can actually removed, it is, of course, necessary to relocate any data stored on that device. So this command, too, can take a long time to run; unlike the balance command, device delete offers no way to pause and restart the operation. Needless to say, the command will not succeed if there is not sufficient space on the remaining drives to hold the data from the outgoing drive. It will also fail if removing the device would cause the array to fall below the minimum number of drives for the RAID level of the filesystem; a RAID 0 filesystem cannot be left with a single drive, for example.

当然，在设备实际移除之前，需要重新定位存储在该设备上的数据。所以这个命令也需要花费很长时间去运行; 与平衡命令不同，删除设备的操作不提供暂停和重启操作。毋庸置疑，如果其余磁盘上没有足够的空间来保存被删除磁盘上的数据，那么命令将不会成功。如果删除设备会导致阵列磁盘数量低于 RAID 级别所要求的最小磁盘数量，那么命令同样也会失败。例如，RAID 0 的文件系统不能运转在单个磁盘上。

> Note that any drive can be removed from an array; there is no "primary" drive that must remain. So, for example, a series of add and delete operations could be used to move a Btrfs filesystem to an entirely new set of physical drives with no downtime.

请注意，任何磁盘都可以从阵列中移除; 并没有不能移除的“主”磁盘这一说。因此，比如，可以使用一系列的添加和删除操作将 Btrfs 文件系统转移至全新的一组物理磁盘上，而全程无需停机。

## 其他 RAID 级别（Other RAID levels）
> The management of the other RAID levels is similar to RAID 0. To create a mirrored array, for example, one could run:

其他 RAID 级别的管理与 RAID 0 类似。例如要创建一个镜像阵列，可以运行：

    mkfs.btrfs -d raid1 -m raid1 /dev/sdb1 /dev/sdc1

> With this setup, both data and metadata will be mirrored across both drives. Exactly two drives are required for RAID 1 arrays; these arrays, once again, can look a little confusing to tools like df:

使用此设置，数据和元数据将在两个磁盘之间镜像存放。 RAID 1 阵列需要两个磁盘。再一次，我们使用 `df` 工具来查看这个阵列，结果看起来令人困惑：

    # du -sh /mnt
    28G	    /mnt

    # df -h /mnt
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/sdb1       280G   56G  215G  21% /mnt

> Here, df shows 56GB of space taken, while du swears that only half that much data is actually stored there. The listed size of the filesystem is also wrong, in that it shows the total space, not taking into account that every block will be stored twice; a user who attempts to store that much data in the array will be sorely disappointed. Once again, more detailed and correct information can be had with:

在这里，`df` 命令显示了 56GB 的空间，而 `du` 命令宣称只有一半的数据存储在那里。同时，列出的文件系统的总量大小也是错误的，因为它只显示了总空间，没有考虑到每个数据块被存储了两次; 这可能会让那些试图将大量数据存储在这样阵列中的用户感到失望。当然，更详细也更加正确的信息可以这样查看：

    # btrfs filesystem show /mnt
    Label: none  uuid: e7e9d7bd-5151-45ab-96c9-e748e2c3ee3b
	    Total devices 2 FS bytes used 27.76GiB
	    devid    1 size 136.72GiB used 30.03GiB path /dev/sdb1
	    devid    2 size 142.31GiB used 30.01GiB path /dev/sdc1

> Here we see the full data (plus some overhead) stored on each drive.

这个结果里，我们看到了每个磁盘上存储的全部数据（外加一些开销）。

> A RAID 10 array can be created with the raid10 profile; this type of array requires an even number of drives, with four drives at a minimum. Drives can be added to — or removed from — an active RAID 10 array, but, again, only in pairs. RAID 5 arrays can be created from any number of drives with a minimum of three; RAID 6 needs a minimum of four drives. These arrays, too, can handle the addition and removal of drives while they are mounted.

可以使用 `raid10` 配置来创建 RAID 10 阵列; 这种类型的阵列需要偶数个磁盘，而且至少有四个。一个活跃的 RAID 10 阵列可以添加或移除磁盘，但是只能成对使用。RAID 5 阵列可以从 3 个以上的磁盘中去创建; RAID 6 至少需要四个磁盘。这些阵列也可以在挂载后进行磁盘的添加和移除操作。

## 转换和恢复（Conversion and recovery）
> Imagine for a moment that a three-device RAID 0 array has been created and populated with a bit of data:

假设现在一个拥有三个设备的 RAID 0 阵列已经创建并填充了一些数据：

    # mkfs.btrfs -d raid0 -m raid0 /dev/sdb1 /dev/sdc1 /dev/sdd1
    # mount /dev/sdb1 /mnt
    # cp -r /random-data /mnt

> At this point, the state of the array looks somewhat like this:

在某一个时间点上，阵列整体的状态看起来是这样：

    # btrfs filesystem show /mnt
    Label: none  uuid: 6ca4e92a-566b-486c-a3ce-943700684bea
	    Total devices 3 FS bytes used 6.57GiB
	    devid    1 size 136.72GiB used 4.02GiB path /dev/sdb1
	    devid    2 size 136.72GiB used 4.00GiB path /dev/sdc1
	    devid    3 size 136.72GiB used 4.00GiB path /dev/sdd1

> After suffering a routine disk disaster, the system administrator then comes to the conclusion that there is value in redundancy and that, thus, it would be much nicer if the above array used RAID 5 instead. It would be entirely possible to change the setup of this array by backing it up, creating a new filesystem in RAID 5 mode, and restoring the old contents into the new array. But the same task can be accomplished without downtime by converting the array on the fly:

通常在发生过常见的磁盘灾难之后，系统管理员会得出这样的结论：冗余有它的价值所在，因此，如果上面的阵列使用 RAID 5 的话，效果会更好。我们完全可以通过一系列的操作来改变这个阵列的级别，例如先备份，然后用 RAID 5 模式创建一个新的文件系统，最后将旧的内容恢复到新的阵列中。但在这里，同样的任务可以通过动态地转换阵列模式来完成：

    # btrfs balance start -dconvert=raid5 -mconvert=raid5 /mnt

> (The balance filters page on the Btrfs wiki and this patch changelog have better information on the balance command than the btrfs man page). Once again, this operation can take a long time; it involves moving a lot of data between drives and generating checksums for everything. At the end, though, the administrator will have a nicely balanced RAID 5 array without ever having had to take the filesystem offline:

（Btrfs 维基百科上有着关于 `balance` 命令过滤器以及补丁的更新日志的详细信息，要比 btrfs man 手册页的信息更加详细）。这个操作同样需要很长时间，它涉及在磁盘之间移动大量数据并为所有数据生成校验和。但操作完成之后，管理员将拥有一个良好平衡过的 RAID 5 阵列，而一过程不需要让文件系统下线：

    # btrfs filesystem show /mnt
    Label: none  uuid: 6ca4e92a-566b-486c-a3ce-943700684bea
	    Total devices 3 FS bytes used 9.32GiB
	    devid    1 size 136.72GiB used 7.06GiB path /dev/sdb1
	    devid    2 size 136.72GiB used 7.06GiB path /dev/sdc1
	    devid    3 size 136.72GiB used 7.06GiB path /dev/sdd1

> Total space consumption has increased, due to the addition of the parity blocks, but otherwise users should not notice the conversion to the RAID 5 organization.

由于增加了奇偶校验块，总空间的消耗增加了，否则用户就不会注意到文件系统转换成了 RAID 5 模式。

> A redundant configuration does not prevent disk disasters, of course, but it does enable those disasters to be handled with a minimum of pain. Let us imagine that /dev/sdc1 in the above array starts to show signs of failure. If the administrator has a spare drive (we'll call it /dev/sde1) available, it can be swapped into the array with a command like:

当然，冗余配置并不能完全避免磁盘灾难，但它确实能够以最小的代价来应对它。让我们想象一下上面的阵列中的 `/dev/sdc1` 显示了要故障的迹象。如果管理员有一个可用的备用驱​​动器（我们称之为 `/dev/sde1`），可以使用如下命令将其交换到阵列中：

    btrfs replace start /dev/sdc1 /dev/sde1 /mnt

> If needed, the -r flag will prevent the system from trying to read from the outgoing drive if possible. Replacement operations can be canceled, but they cannot be paused. Once the operation is complete, /dev/sdc1 will no longer be a part of the array and can be disposed of.

如果需要，`-r` 参数可以防止系统尝试从换出的磁盘中读取数据。更换操作可以取消，但不能暂停。一旦操作完成，`/dev/sdc1` 将不再是阵列的一部分，这时就可以丢弃它了。

> Should a drive fail outright, it may be necessary to mount the filesystem in the degraded mode (with the "-o degraded" flag). The dead drive can then be removed with:

如果磁盘发生故障，可能需要将文件系统转换成降级模式（使用 `-o degraded` 参数），然后可以使用以下命令删除故障磁盘：

    btrfs device delete missing /mnt

> The word "missing" is recognized as meaning a drive that is expected to be part of the array, but which is not actually present. The replacement drive can then be added with btrfs device add, probably followed by a balance operation.

其中的单词 `missing` 被认为是一个磁盘，它被认为是阵列中的一部分，但实际上并不存在。替换磁盘然后可以再使用 `btrfs device add` 命令添加，随后就是平衡操作。

## 总结（Conclusion）
> The multiple-device features have been part of the Btrfs design from the early days, and, for the most part, this code has been in the mainline and relatively stable for some time. The biggest exception is the RAID 5 and RAID 6 support, which was merged for 3.9. Your editor has not seen huge numbers of problem reports for this functionality, but the fact remains that it is relatively new and there may well be a surprise or two there that users have not yet encountered.

多设备功能是 Btrfs 早期设计目标之一，在大部分情况下，这些代码已经处于主线中并且相对稳定了一段时间。但是也有例外：对于 RAID 5 和 RAID 6 的支持刚被合并到了 3.9 内核版本中。小编尚未看到太多关于这个功能的问题报告。事实上，因为它相对较新，用户可能还没有遇到过任何形式的“惊喜”。

> Built-in support for RAID arrays is one of the key Btrfs features, but the list of advanced capabilities does not stop there. Another fundamental aspect of Btrfs is its support for subvolumes and snapshots; those will be discussed in the next installment in this series.

内置的对于 RAID 阵列的支持是 Btrfs 的关键功能之一，但高级功能列表并不止于此。Btrfs 的另一个重要方面是支持子卷和快照; 这些将在本系列的下一部分中讨论。

[1]: http://tinylab.org
