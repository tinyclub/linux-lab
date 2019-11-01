---
layout: post
draft: true
author: 'Shaojie Dong'
title: "LWN 718639: 容器感知型文件系统"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-718639/
description: "LWN 文章翻译，容器感知型文件系统"
category:
  - 内核虚拟化
  - LWN
tags:
  - Linux
  - container
  - filesystem
---

> 原文：[Container-aware filesystems](https://lwn.net/Articles/718639/)
> 原创：By Jake Edge @ April 3, 2017
> 翻译：By [ShaojieDong](https://github.com/ShaojieDong)
> 校对：By [hal0936](https://github.com/hal0936)

> We are getting closer to being able to do unprivileged mounts inside containers, but there are still some pieces that do not work well in that scenario. In particular, the user IDs (and group IDs) that are embedded into filesystem images are problematic for this use case. James Bottomley led a discussion on the problem in a session at the 2017 Linux Storage, Filesystem, and Memory-Management Summit.

Linux对容器内部无特权挂载 ([Unprivileged mounts][1]) 的支持已经趋近完善，不过仍然存在一些小问题有待解决。尤其是存储在文件系统 image 的用户 ID (和组 ID )，在这种使用场景下是有问题的。在 2017 年的 Linux 存储，文件系统和内存管理峰会上，James Bottomley 主持了这个问题的讨论。

> The various containerization solutions in Linux (Docker, LXC, rkt, etc.) all use the same container interfaces, he said. That leads to people pulling in different directions for different use cases. But the problem with UIDs stored in filesystem images affects all of them. These images are typically full root filesystems for the containers that have lots of files owned by the root user.

他说，Linux 的多种容器化解决方案 (Docker, LXC, rkt 等) 都使用了相同的容器接口。这就导致了人们针对不同的使用场景引入了不同的研发方向。但是存储于文件系统 image 的 UID 的问题会对所有的场景产生影响。这些 image 通常是容器的完整根文件系统，该容器具有许多属于根用户的文件。

<img src="https://static.lwn.net/images/2017/lsfmm-bottomley.jpg" align="left" width="160"> Bottomley has [proposed shiftfs](https://lkml.org/lkml/2017/2/20/655) as a potential solution to this problem. It is similar to a bind mount, but translates the filesystem UIDs based on the user namespace mapping. It can be used by unprivileged containers to mount a subtree that has been specifically marked by the administrator as being shiftfs-mountable.

Bottomley [提出了 shiftfs 文件系统内核补丁][2] 作为这个问题的潜在解决方案。它类似于一个 bind mount，但是根据用户命名空间映射翻译文件系统 UID。它可以被非特权容器用于 mount 一棵被管理员标记为 shiftfs-mountable 的子树。

> An earlier effort to solve the problem added the `s_userns` field to the superblock in order to do UID translations, but that is a per-superblock solution that does not work well for containers that want to share a specific mounted filesystem among containers with different UID mappings. With shiftfs, an inode operation will translate the UID based on the namespace mapping to that of the underlying filesystem before passing the operation the lower level. That means the virtual filesystem (VFS) does not need changes, which makes for a cleaner solution, Bottomley said.

该问题的早期解决方案是在超级块中添加 `s_userns` 字段以进行 UID 翻译，但这是针对每个超级块的解决方案，当容器希望在具有不同 UID 映射的容器之间共享特定已经 mount 的文件系统时，这种方法就不适用了。使用 shiftfs，inode 操作会将基于命名空间映射的 UID 翻译为底层文件系统的 UID, 然后再将操作传递给更低级别。 Bottomley 说，这意味着虚拟文件系统 (VFS) 不需要更改, 由此可以得到一个更加干净的解决方案。

> There are some significant security implications to allowing arbitrary directory trees to be shift-mounted in unprivileged containers, including the ability for users to create setuid-root binaries. So the administrator must mark those subtrees (using extended attributes in his prototype) that are safe to be mounted that way.

允许将任意目录树 shift-mount 到非特权容器中，对安全会有重大影响，包括用户创建 setuid-root 二进制文件的能力。所以系统管理员必须对那些允许 shift-mount 的子树进行标记(通过 mount 命令的 `-o` 选项使用文件系统原型中的扩展属性)，从而确保 mount 是安全的。

> Al Viro asked if there is a plan to allow mounting hand-crafted XFS or ext4 filesystem images. That is an easy way for an attacker to run their own code in ring 0, he said. The filesystems are not written to expect that kind of (ab)use. When asked if it really was that easy to crash the kernel with a hand-crafted filesystem image, Viro said: "is water wet?"

Al Viro 询问是否有计划允许 mount 手动制作的 XFS 或者 ext4 文件系统 image，他说这是攻击者在 Ring 0 特权级运行自己代码的简单方法。编写文件系统并不是期望这样使用的。当被问到用手动制作的文件系统 image 是否真的那么容易使内核崩溃时，Viro 说:"那还用说？(is water wet?)"

> Amir Goldstein said that the current mechanism is to use FUSE to mount the filesystems in the unprivileged containers. But Bottomley is concerned that the FUSE daemon can be exploited, so it should run in the unprivileged container as well. If you restrict the mounts to USB sticks, it means an attacker would need physical access, which has plenty of other paths for system compromise so it is "safe" in that sense. But if loopback mounting of filesystems is to be supported at some point, the filesystem code will need to have no exploitable bugs.

Amir Goldstein 表示当前的机制是使用 FUSE 在非特权容器中 mount 文件系统，但是 Bottomley 担心 FUSE 的守护进程被代码漏洞利用，所以它也应该在非特权容器中运行。如果将 mount 限制在 USB 记忆棒上，这意味着攻击者需要物理访问，而物理访问还有许多别的途径可以破坏系统，从这个意义上讲使用 FUSE 是“安全的”。但是，如果需要支持文件系统的回环挂载 (loopback mounts)， 文件系统代码必须没有 bug 可被利用。

> In something of an aside, Goldstein reminded filesystem developers that their filesystems may be running under [overlayfs](https://lwn.net/Articles/403012/). He suggested that there needs to be more testing of different filesystems underneath overlayfs.

顺便提一下， Goldstein 提醒文件系统开发人员，他们的文件系统可能在 [overlayfs][3] 下运行。他建议需要对 overlayfs 下的不同文件系统做更多的测试。

> While the attendees recognized the problem for unprivileged containers, there does not seem to be a consensus on the right route to take to solve it.

虽然参会者认识到非特权容器的问题，但是并没有对解决该问题的正确方法达成共识。

[1]: https://lwn.net/Articles/265220/
[2]: https://lkml.org/lkml/2017/2/20/655
[3]: https://lwn.net/Articles/403012/