---
title: Clear Containers 介绍
author: Tao HongLiang
layout: post
group: translation
permalink: /clear-containers-introduction/
views:
  - 25
tags:
  - Container
  - 翻译，Clear Containers
  - Docker
  - Linux
  - LWN
categories:
  - Linux
  - Virtualization
---

<!-- title: Clear Containers 介绍 -->

<!-- 作者：陶宏亮，taohl04@gmail.com, 65036336 -->

<!-- 时间：2015/6/11 -->

<!-- 分类：Linux -->

<!-- 标签：Linux,Container,LWN,翻译，Clear Containers -->

> 原文：[An introduction to Clear Containers][1]
> 作者：Arjan van de Ven
> 译者：Tao Hongliang

## 简述

Containers 最近很火，每个人都对它赞不绝口。对开发者而已，它更易开发；而对于 IT 部门而言，它易于管理和部署。Containers 进入公众视野，很大程度上源于 Docker 像 Iphone 改变客户端程序设计一样改变了服务器端的应用开发。

广义上的 container 不仅仅是一个应用程序，还被用作描述一种可以独立运行一组软件的技术。kernel container 通过控制 groups 来管理资源和内核 namespaces， 从而限制 container 中的 app 资源可见度。对于一个典型的 LWN 读者而言，LWN 就是一个 container。

虚拟机的昂贵和响应过慢使得很多人提倡使用 containers 技术。Containers 给了他们另外一种高效的选择。通常的反对观点是，对利用内核漏洞进行攻击而言，内核级的容器到底有多安全。人们在这个话题上的争论旷日持久，然后事实却是只有极少的潜在 container 用户会认为这是一个亮点（showstopper）。很多开源项目和公司正在努力提高 containers 和 namespaces 的安全性了。

在 container 技术的安全性上，我们(The Intel Clear Containers group)有一些不同的看法。回到最基本的问题上： 虚拟机技术是否真的昂贵？ 要回答这个问题，我们通过 2 个维度来考量性能：响应速度和内存开销。响应速度显示出你的数据中心应答一个新的请求所需要的时间。而内存开销决定了你在一台服务器上能部署多少个 container。

结果就是：我们使用虚拟化技术启动这样一个安全的 container 低于 150ms, 而内存消耗大概是 18 &#8211; 20MB (这意味着你可以在一个 128GB 内存大小的服务器上运行 3500个 container )。然后它还是没有最快的使用内核 namespaces 技术的 Docker 快。但对于大多数应用，这已经足够了。并且我们还在持续优化中。

那么，我们是如何做到的呢？

## Hypervisor

KVM 是 Hypervisor (虚拟机管理机) 的一个选择， 我们着眼于 QEMU 层。QEMU 能很好的运行 Windows 和旧的 Linux 系统。但是这种灵活性成为了一种很大的开销。不光所有的竞争会消耗内存，而且它需要一定形式的底层固件支持。这些额外的东西增加了虚拟机的启动时间。(500ms to 700ms 不等)。

因此，我们使用 kvmtool 作为 mini-hypervisor。通过 kvmtool, 我们不再需要 BIOS or UEFI； 同时我们可以直接跳转到 Linux 内核。当然，Kvmtool 也是有消耗的， 启动 kvmtool 并创建 CPU 上下文需要花费大约 30ms。 我们扩展了 kvmtool，让他可以在内核上支持 execute-in-place。从而避免去解压内核镜像； 我们仅通过 mmap() 来映射 vmlinux 文件，然后跳转过去，这样做同时节省了内存和时间。

## Kernel

Linux 内核启动得相当快速。在一个真实机器上，内核大部分的启动时间都花在了初始化各种硬件上。但是，在虚拟机上，没有真实的硬件存在。我们只使用一个 virtio 类的设备，它的启动几乎没有开销。我们优化了一些 early-boot CPU 初始化的一些延迟；但是，在一个虚拟机里启动一个内核依然需要 32ms, 这里面还有很大的优化空间。

我们也解决了很多内核中的 BUG, 一些补丁已经被上游接收，其他的也将在几周后进入上游。

## User space

在 2008 年， 我们在 Plumbers 研讨会上讲 5 秒启动。从那以后，很多事情发生了变化， 尤其是 systemd 的出现。Systemd 让桌面环境的快速启动变得不重要了。我愿意写一长篇论文来描述我们是怎么优化用户空间的，但是事实上，用户空间已经启动的非常快了。(小于 75 秒)

## Memory 开销

已经支持 ext4 文件系统的 4.0 内核的一个关键特性 DAX 对内存开销有很大的帮助。如果你的存储就像整齐的内存一样对 CPU 可见。DAX 可以让系统执行 execute-in-place 文件并存储在哪里。换句话说，当使用 DAX， 你会完全绕过页 cache 和虚拟内存子系统。对于使用 mmap() 的应用程序，这意味着真正的 0 拷贝方法。对于使用 read() 调用的代码，你也只需要一次数据的拷贝。DAX 原本是为像内存一样对 CPU 可见的类似 flash 的快速存储而设计的。但在一个虚拟机环境里，这种类型的存储很容易模拟。我们只需要把主机的磁盘镜像文件映射到客户机的物理内存上，然后在客户机内核上使用一个小的驱动程序把这块内存区域注册为一个 DAX 的块设备即可。

DAX 提供了一个 0-copy, 0-memory-cost 的解决方案用来把所有操作系统代码和数据映射到客户机的用户空间。并且，当 MAP\_PRIVATE 标志在 hypervisor 中被使用。存储就变成了 copy-on-write； 在客户机上写文件系统就不再连续，所以当客户机 container 关闭时都将消失。MAP\_PRIVATE 这个 flag 使得在所有 containers 之间共享磁盘镜像不再重要，即使某个 container 被操作系统镜像污染。这些改动在未来的 container 中将会消失。

对于减少主机端内存消耗，KSM (kernel same-page merging) 是第二个关键特性。KSM 是一种消除处理器和 KVM 客户端之间内存的方法。

最后，我们为了最小的内存消耗优化了核心用户空间。大部分 glibc 的 malloc_trim() 函数的调用发生在最后初始化原生 daemon 时。导致他们返回了 glibc 保持的由 malloc() 生成的 buffers 给内核。Glibc 默认实现了一种滞后机制的优化方式，可以保持一部分空闲内存以防内存在很短的时间内再次被使用。

## Next steps

我们正在为验证 RKT（一种 [appc spec][3] 的实现）持续的工作。一旦验证工作更加成熟，我们会着手在 Docker 中添加对它的支持。你可以在 clearlinux.org 中找到更多如何上手和获取代码的信息，一旦我们的集成和优化工作取得进展，我们都会在该网站上更新。





 [1]: http://lwn.net/Articles/644675/
 [2]: http://tinylab.org
 [3]: http://lwn.net/Articles/644089/#appc
