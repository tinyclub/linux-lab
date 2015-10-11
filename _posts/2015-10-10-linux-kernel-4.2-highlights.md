---
layout: post
author: 'Wen Pingbo'
title: "Linux 内核 4.2 变更快报"
group: news
permalink: /linux-kernel-4.2-highlights/
category:
  - 技术动态
tags:
  - Linux
  - qspinlock
  - CDG
  - Geneve

---

> By Pingbo of TinyLab.org
> 2015-09-25

## 说明

Linux 内核 4.2 是在 8.30 号发布的，这次版本的变更总共包含 14750 个提交。估计打破记录了:)

以下对 4.2 内核新增内容的介绍并不是很全面，只是摘取了一些比较重要的内容。若需要详细的代码变更记录，可以下载 Linus 的仓库，然后运行如下命令：

    $ git log v4.1..v4.2 --oneline

想要了解 4.0，4.1 版本的变更，请看[< Linux 片面报告：从 4.0 到 4.2 >](http://tinylab.org/linux-one-sided-reports-from-4-0-to-4-2/)。

## 全新的 LSM Stack

经过两年的开发，patches 迭代了 21 个版本后， LSM(Linux Security Module) Stack 终于合入到了 Linux 内核 4.2。现在我们可以在一个系统通过并行组合 SELinux, Smack, TOMOYO, 和 AppArmor 等安全策略，灵活控制系统的资源和权限。

- 详细介绍：<https://lwn.net/Articles/635771/>
- 相关提交：<https://lwn.net/Articles/636056/>

## 支持 Geneve 协议

Geneve 是 Intel, Microsoft, Red Hat 和 VMware 开发出的一种全新虚拟网络封装协议，就像 VXLAN 一样。开发 Geneve 协议主要是统一现有的封装协议（VXLAN, NVGRE, 和 STT），同时提供高可扩展性。只要链路两端之间支持最新的 Geneve 扩展，则可以在不更新硬件的前提下，切换到新协议。Geneve 协议主要是影响网络层之上的数据格式，所以现有的交换机等链路层设备是兼容 Geneve 协议的。Geneve 协议一般应用于数据中心，云平台等场合。

- Geneve 协议定义：<http://tools.ietf.org/html/draft-gross-geneve-02>
- Geneve 介绍：<https://blogs.vmware.com/cto/geneve-vxlan-network-virtualization-encapsulations/>
- 提交记录：<https://lwn.net/Articles/644938/>

## 支持新网络拥堵控制算法 - CDG

我们现在用的传统网络拥堵控制算法是基于丢包率来检测当前连接是否处于拥堵状态。当路由器的缓存满了后，就会开始丢包。而链路的另一端在检测到丢包后，就会缩减 TCP 发送窗口。这里的控制逻辑有一个前提假设：丢包都是由于接收方缓存满了导致的。但是实际情况并不是这样，有很多其他原因也会造成丢包的发生。比如，一台手机连接到了一个信号极差的 Wifi，就会导致网络包丢失。但是这种情况并不需要去调整发送窗口。

CDG(CAIA delay gradient) 算法的出现，在一定程度上改善了这种缺陷。CDG 算法会统计一段时间内，一个连接的最小 RTT(round-trip time) 时间和最大 RTT 时间，以及最小 RTT 时间变化率和最大 RTT 时间变化率。CDG 算法的核心就是利用这几个参数来判断当前连接是否处于拥堵状态。比如：当最小 RTT 时间变大，其变化率就会为正数，CDG 就会认为当前连接状态不是很好，开始主动调整发送窗口。

尽管 CDG 已经合入到了 Linux 内核 4.2，但是社区里并不是所有人都看好它。这估计需要一段时间来检验这个算法。

- 提交记录：<https://lwn.net/Articles/645015/>
- CDG 算法详细介绍：<http://caia.swin.edu.au/cv/dahayes/content/networking2011-cdg-preprint.pdf>

## 提升内存回写性能

Linux 内核上的回写（writeback）是指把内存中的脏页回写到永久存储介质上。一般内核的内存管理会把脏页的比例控制在 15%。但这只是全局性的，无法具体精确到一个控制组。若系统中开启了 control group，这个 patches 会有比较大的性能提升。

- 提交记录：<https://lwn.net/Articles/645708/>

## 合入 queue spinlock

spinlock 在内核中使用的非常频繁，同时，对它的改进也在不断的进行中。最原始的 spinlock 存在这样的缺陷：在竞态状态下，spinlock 无法保证等待最久的进程能够最先获取锁；同时，频繁的 compare-and-swap 操作，让 spinlock 需要不断在各个 cpu 和 cache 之间移动，浪费大量的时间。总结起来，spinlock 在非竞态状态（uncontended）下，工作非常好。但是在竞态状态下，spinlock 存在公平性问题和过度切换问题。在社区里，一般把这个问题称为 contention problems。

在之前的内核版本中，Nick 有提交一个新的 spinlock 机制，称作 ticket spinlock。通过把之前的整形数劈成两半，一般用作 next，另一半用作 owner，来解决 spinlock 公平性问题。由于多了一倍的判断赋值操作，ticket spinlock 其实引进了一些其他消耗，但是和公平性问题相比，这点代价是可以忍受的。

而最近，来自 HP 公司的 Waiman Long 和他的团队尝试解决 ticket spinlock 带来的问题，从而推出了 queue spinlock。qspinlock 可以代替 ticket spinlock，在解决竞态状态下公平性问题的同时，也能保持原有 spinlock 结构体大小不变，效率也提升很多。跟随这次提交而增加的新 spinlock 还包括：pvqspinlock 和 qrwlock。

现在 qspinlock 特性在 x86 平台上已经默认打开，若感兴趣，可以自己自己下载编译。需要注意的是，尽管 qspinlock 带来了很多的性能提升，但 Waiman Long 也指出， qspinlock 并没有解决 spinlock 的根本性问题（contention problems）。

有趣的是，在这之前，Tim Chen 曾推出过一个全新的机制 - MCS lock。尝试从根本上解决 spinlock 的 contension problems。

感兴趣的可以看看这里：<https://lwn.net/Articles/590243/>

- ticket spinlock 介绍：<https://lwn.net/Articles/267968/>
- queue spinlock 提交记录：<https://lkml.org/lkml/2015/6/22/68>

## 文件系统更新

- 移除 ext3 驱动

  由于 ext4 是向后兼容的，所以这次提交只是移除一些不用的代码，对上层应用来说，是透明的。

  - 相关提交记录：<https://lkml.org/lkml/2015/7/15/438>

- 诸多 XFS 优化

  这次 XFS 有很多的提交，但比较关注的是，XFS 开始支持 DAX（direct access eXciting），这可以让 XFS 直接绕过文件系统的页缓存，对于那些带非丢失的 RAM 机器来说，这绝对是一个好消息。

- btrfs raid 5/6 and trim fixes
- ext4 improvement
- f2fs improvement

## 新平台以及硬件的支持

- 支持 A23 smp 和 BCM63138 smp
- 支持 Socpga 的 Big endian
- 支持 HiSilicon hi6220
- 支持 Nvidia Tegra HDA
- 支持 Intel Skylake Graphics "Gen9"
- 支持 AMD R9 Fury
- 支持 Vmware OpenGL 3.3
