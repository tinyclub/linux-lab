---
layout: post
author: 'Zhao Yimin'
title: "LWN 718803: 文件系统的管理接口"
# tagline: " 子标题，如果存在的话 "
album: "LWN 中文翻译"
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-718803-filesystem-management-interfaces/
description: "在LSFMM 2017的文件系统的专题会上，Steven Whitehouse 讨论了文件系统管理接口"
plugin: mermaid
category:
  - LWN
  - 文件系统
tags:
  - Linux
  - filesystem
---

> 原文：[Filesystem management interfaces](https://lwn.net/Articles/718803/)
> 原创：By By Jake Edge @ Apr 5, 2017
> 翻译：By Tacinight of [TinyLab.org][1]
> 校对：By [cee1](https://github.com/cee1)

> In a filesystem-only session at LSFMM 2017, Steven Whitehouse wanted to discuss an interface for filesystem management. There is currently no interface for administrators and others to receive events of interest from filesystems (and their underlying storage devices), though two have been proposed over the years. Whitehouse wanted to describe the need for such an interface and see if progress could be made on adding something to the kernel.

在 LSFMM 2017 文件系统的专题会上，Steven Whitehouse 讨论了文件系统的管理接口。尽管这些年来已有两个提案，但尚未有正式的接口，能够让系统管理员或者其他人来接收他们可能感兴趣的、来自文件系统（及其底层存储设备）事件通知。Whitehouse 试图通过澄清这种接口的需求描述，逐步向内核添加代码，来取得该方面的进展。

> Events like ENOSPC (out of space) for thin-provisioned volumes or various kinds of disk errors need to get to the attention of administrators. There are two existing proposals for an interface for filesystems to report these events to user space. Both use netlink sockets, which is a reasonable interface for these kinds of notifications, he said.

从系统管理员的需求角度，精简配置卷（thin-provisioned volumes）的 ENOSPC（空间不足）事件以及各种磁盘错误，是其所关心的。目前两个关于文件系统管理接口的提案，都是将这些事件通知到用户空间。Whitehouse 说，两个方案都使用 netlink 套接字，看起来很合理。

> Lukas Czerner posted one back in 2011, while Beata Michalska proposed another in 2015. The latter is too detailed, Whitehouse said, and has some performance issues. It notifies on events like changes to the block allocation in the filesystem, which is overkill for the kind of monitoring he is looking for.

Lukas Czerner 和 Beata Michalska 前后于 2011 和 2015 年分别提出各自的方案。Whitehouse 说，Beata 的方案内容太过琐碎，如每次文件系统中块分配都会上报，对于他心中理想的监控方案来说，信息过多了。此外还存在一些性能问题。

> The interface needs to provide a way to enumerate the superblocks of filesystems that are mounted on the system. Applications would register their interest in particular mounts and get notification messages from them. The messages would consist of two parts, a key that identified the kind of event being reported along with a set of messages with further information about the event.

从编程使用的角度，该接口应能枚举操作系统上已挂载文件系统的超级块。使用者应当在特定的挂载点上订阅他们感兴趣的事件通知。事件通知的消息体应当由两部分组成，一个 key 来标识报告事件类型，以及一组关于细节的描述。

> The messages would have a unique ID to identify the mount, which would consist of a device number (either the real one or one that was synthesized by the subsystem), supplemented with a UUID and/or volume label. Some kind of generation number might also be needed to distinguish between different mounts of the same filesystem.

这些消息中将有一个唯一的 ID 来标识挂载点，其中包含一个设备编号（无论是真实的还是由子系统合成的），一个 UUID 或者卷标。也许还需要某些计数来区分同一个文件系统不同的挂载点。

> Steve French asked which filesystems can provide a UUID; network filesystems can do so easily, but what about others? Ted Ts'o said that all server-class filesystems have a way to generate a UUID. He also said that the device number would be useful to help correlate device errors. Trond Myklebust suggested that the information returned by /proc/self/mountinfo might be enough to uniquely identify mounts.

Steve French 问了哪些文件系统可以提供 UUID; 网络文件系统可以这么做，但其他的文件系统怎么办？ Ted Ts'o 表示，所有的服务器级文件系统都可以生成一个 UUID。他还表示，设备编号还有助于校正设备的错误。Trond Myklebust 建议，`/proc/self/mountinfo` 返回的信息已经足够用来唯一地标识装载。

> Ts'o said that this management interface is really only needed for servers, since what Whitehouse is looking for is a realtime alarm that some attention needs to be paid to a volume. That might be because it is thin-provisioned and is running out of space or because it has encountered disk errors of some sort.

Ts'o 说，Whitehouse 寻找的是一个能够实时关注卷动态的警报系统，这个管理接口实际上只是服务器所需要的。关注的情况也是例如存储卷采用了精简配置，空间用完了或者遭遇了某种类型的磁盘错误。

> There was some discussion of how management applications might filter the messages so that they only process those of interest. Ts'o said that filtering based on device, message severity, filesystem type, and others would probably be needed. There was general agreement for the need for this kind of interface, though it was not clear what the next step would be.

之后还有一些讨论，关于管理应用程序如何进行过滤，以便只处理他们感兴趣的消息。 Ts'o 表示，可以基于设备、消息严重性、文件系统类型以及其他类型等进行过滤。对于这种接口的需求，大家普遍表示同意，但是尚不清楚下一步行动如何。

[1]: http://tinylab.org
