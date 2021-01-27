---
layout: post
draft: false
top: false
author: 'Wang Chen'
title: "Linux 内核的代码仓库管理与开发流程简介"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-nc-nd-4.0"
permalink: /linux-repo-intro/
description: "简单介绍一下 Linux 内核的三个主要代码仓库以及它们的管理与开发流程"
category:
  - Linux 内核
  - Linux 综合知识
tags:
  - Linux
---

> By unicornx of [TinyLab.org][1]
> Sep 16, 2020

入门 Linux 内核学习时，首先得先了解一下 Linux 这个项目的源码仓库和版本的发布策略还是有必要的，今天就给大家简单掰一下，有什么说得不到位的，敬请拍砖补充。

Linux 的源码仓库主要有下面三个：

## linux 仓库

这个一般指的是 Linus Torvalds 本尊亲自维护的那个仓库。该仓库的官方位置在：<https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/>。大部分情况下我们访问的都是它的镜像，其中 “第二官方” 的镜像在 github，地址是：<https://github.com/torvalds/linux>。对于国内的朋友，推荐访问国内的 mirror，这里我就不列举了，大家网上搜搜。

这个仓库只有一个 master 分支，该分支由 Linus Torvalds 维护，对于不同的版本的内核是采用打 tag 的方式进行发布的，一般在发布一个正式版本之前，都会先发布一系列的候选（Release Candidate， 简称 RC）版本，比如 v5.4 最终版发布之前先发布了 v5.4-rc1 到 v5.4-rc8 共计 8 个 RC 版本，rc 值越大越接近最终版本，每个大版本，譬如 5.3 到 5.4 之间的发布周期目前稳定在大致在两个月左右。**linux 仓库** 中的 master 即我们常说的 mainline。

```
$ git tag | grep 5.4
v5.4
v5.4-rc1
v5.4-rc2
v5.4-rc3
v5.4-rc4
v5.4-rc5
v5.4-rc6
v5.4-rc7
v5.4-rc8
```
从 3.0 之后的版本，mainline 中的内核版本号只涉及主版本号和次版本号两个：x.y。我们会看到形如 x.y.z 版本的内核一般都是指 stable 版本，这也是接下来要给大家介绍的第二个仓库：**linux-stable 仓库**。

## linux-stable 仓库

这个仓库的官方位置在 <https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/>。其 “第二官方” 的镜像在 github，地址是：<https://github.com/gregkh/linux>。其主要维护者是 Linux 社区的另一位大佬 Greg Kroah-Hartman。

**linux-stable 仓库** 基本上是前面介绍的 Linus 维护的 **linux 仓库** 的克隆，但在其基础上又创建了许多新的分支（branch），比如 `linux-5.6.y` 分支，用这些分支来维护 5.6 版本 stable 内核，**linux-stable 仓库** 和 **linux 仓库** 的合作关系如下（以 5.6 版本为例）：

- 当 Linus Torvalds 在其维护的 **linux 仓库** 中发布了 5.6 版本后，commit 节点被 Linus 标记（tag）为 5.6，此时 Greg 就会从 **linux 仓库** 的 master 上 pull 一份过来，同时 checkout 出来一个分支 `linux-5.6.y`。

- 后续 `linux-5.6.y` 分支的维护将由 **linux-stable 仓库** 维护者进行维护，内核版本号变为 5.6.y，这里的 y 从 1 开始以此递增，也就是说 stable 版本会在主版本和次版本之后再多一个版本号，用来记录稳定版的更新序列号。

- 自此之后 `linux-5.6.y` 分支将和 Linus 维护的 mainline 分支分道扬镳，mainline 继续新特性的开发，stable 则只会合入特定的一些 patch 以保证稳定性，并且定期打上 tag：譬如 `v5.6.1`、`v5.6.2` ......

- 某些 Linux 版本会被宣布为长期维护（Long Term Support，简称 LTS）版本，譬如 5.4，则于其对应的 stable 分支  `linux-5.6.y` 会得到额外的垂青，也就是说该分支的维护时间会较长，多达几年，所以 `v5.6.y` 的 y 值会变得很大。

## linux-next 仓库

**linux-next 仓库** 用于存放那些希望在下一个 merge 窗口被合入 mainline 的补丁代码。由 Stephen Rothwell 维护。官方原始仓库位置在：<https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git>。

Linus 一般会在某个正式版本（譬如 v5.4）发布的同时就会为下一个版本（譬如 v5.5）开启一个 merge windows，所谓的窗口期你可以理解成一段时间，大概在两周左右，在此期间，**linux 仓库** 的 master 分支会从 **linux-next 仓库** 以及各个子模块的维护者处接收 patch 并合入 master，当合入一些 patch 后，就会形成下一个版本的候选版本（这里是 `v5.5-rc1`），然后一般会经历多个 RC 版本，等待时机成熟后就会正式发布下一个版本的 Mainline 内核（这里是 `v5.5`）。

所以说 **linux-next 仓库** 已经成为内核开发过程中不可或缺的一部分；也就是说，如果你希望你的补丁进入 mainline 内核，特别是进入下一个主线版本，那你就得在相应的合并窗口打开之前的一段时间争取将你的补丁被接纳进入 **linux-next 仓库**，当然这要取决于你的能力外加一点点运气 ;)。

以上就是和 Linux 相关的三个主要开发代码仓库，大家搞明白了么？

## 参考文献

- [Kernel 官网有关 release 分类的说明](https://www.kernel.org/category/releases.html)
- [Working with linux-next](https://www.kernel.org/doc/man-pages/linux-next.html)
- [The linux-next and -stable trees](https://lwn.net/Articles/571980/)

[1]: http://tinylab.org


