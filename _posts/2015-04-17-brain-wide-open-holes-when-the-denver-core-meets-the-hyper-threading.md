---
title: 大开脑洞：当丹佛核心遇上超线程
author: Chen Jie
layout: post
permalink: /brain-wide-open-holes-when-the-denver-core-meets-the-hyper-threading/
tags:
  - Denver
  - 超线程
  - HT
  - Hyper-Threading
  - NVIDIA
  - SMT
  - Tegra
  - Tegra K1
  - VLIW
  - 丹佛
categories:
  - ARM
  - ISA
  - Tegra
---

<!-- title: 大开脑洞：当丹佛核心遇上超线程 -->

<!-- %s/!\[image\](/&#038;\/wp-content\/uploads\/2015\/04\// -->

> by Chen Jie of [TinyLab.org][1]
> 2015/4/15

最近，先是某表火爆销售，随后 12 寸的新 Macbook 也终于开卖。后者的一些评测报告也纷纷出现，最有意思的大概是下面这个：

![image][2]

iPad Air2 A8X CPU 的性能渐近新 Macbook 搭载的低功耗版 Core M。这大概是苹果产品上，首次嵌入式 CPU 性能如此接近桌面级 CPU —— 并不是 Intel CPU 不给力，只是 ARM 阵营发展太猛。

说到 ARM 阵营的强 U，除了水果的 A8，就数 NVIDIA 丹佛（Denver）核心的 Tegra K1。后者采用了独特的动态剖析，并据此生成优化 VLIW (Very Long Instruction Word) 代码并缓存起来，供后续使用。进一步了解可戳[这里][3]。

如果我们能站在 CPU 的一排执行单元前，看着指令进来，最壮观的景象大概是下面这个样子：

![image][4]

—— 就好像一排车流，驶在各自车道上，通过这个路口。这里，紫色的“车”好比是指令，而各“车道”则类比做各个执行单元。如果 CPU 能长时间保持上述壮景，性能就碉堡了！

那么问题来了，怎样做到每个时刻内，每条“车道”都有“车”在跑呢？

现应用于产品的，有两技术，一种叫做乱序执行，就是通过增加硬件来调度指令，这是主流技术。

另一种，走的是软件方式：或编译时，或运行时生成 VLIW 指令 —— 如果将一般的指令，比作占有一条“车道”的“车”，那么 VLIW 指令就是一次占满全部“车道”的“**超宽**” “*连环*” “车”。此方法的好处在于省硬件，省下的芯片面积可以用来增强其他硬件功能；另外 VLIW 本身就是调度结果的一个保存，即无需每次进行指令调度，从而节能。因此 NVIDIA 放出豪言：“Dynamic Code Optimization is the architecture of the future”。

当然，理想是美好的，现实是带感的，带着一丝骨感。站在 Tegra K1 的执行单元前，相当时间大概会看到下面的景象：

![image][5]

每时刻只有一辆“车”（指令）跑在一个 “车道”（执行单元）上通过路口（确切的说，这也算是理想，实际上会有一些时刻没有一辆“车”通过路口）—— 偌大的超宽 n “车道”，就这么白白浪费了。换句话说，这种情况下，Tegra K1 退化成了一个顺序执行的 U。

顺序执行的 U，常有用到另一种增加执行单元利用率的方法，且耗的硬件资源不多。这方法大名叫做“超线程”，学名唤做“同时多线程”（SMT）技术。即是将来自两个以上线程的指令混在一起，丢给执行单元：

![image][6]

上图继续前文的比喻，绿色“车” 和紫色“车” 类比为来自两线程的指令，当它们行驶在不同“车道”上时（使用不同执行单元），“车道”的利用率提升了（执行单元利用率提升了）。这对 Tegra K1 这样拥有丰富执行单元的硬件而言，是非常划得来的。

不过当一组 VLIW 指令被执行时，“车道”被完全占满，另一线程指令连着好几个周期得不到执行，就像下面酱紫：

![image][7]

此时，该怎么办呢？想一想，比如让这个虚拟的 CPU 下线（i.e. CPU hotplug），例如：

  1. 当 VLIW 指令连着执行时，即阻塞了另一线程，硬件上在某寄存器中加以标识。
  2. 内核在中断和异常处理返回前，检测该寄存器，并调整 *被阻塞线程* 的运行时间（runtime），以期使进程调度更公平些。
  3. 为消除 CPU 下线带来的进程迁移开销，让运行在同一核心（Core）、不同虚拟 CPU 上的调度器，共享同一调度队列（runqueue）。

YY 结束，未来会不会有这样的实现呢？且骑着驴看唱本 —— 走着瞧。





 [1]: http://tinylab.org
 [2]: http://cdn.macrumors.com/article-new/2015/04/geekbenchmacworld.jpg
 [3]: /nvidia%E9%BB%91%E7%A7%91%E6%8A%80-%E4%B8%B9%E4%BD%9B%E6%A0%B8%E5%BF%83%E6%9D%80%E5%88%B0%EF%BC%81/
 [4]: /wp-content/uploads/2015/04/yy-denver-smt-VLIW.jpg
 [5]: /wp-content/uploads/2015/04/yy-denver-smt-inorder.jpg
 [6]: /wp-content/uploads/2015/04/yy-denver-smt-inorder-with-smt.jpg
 [7]: /wp-content/uploads/2015/04/yy-denver-smt-when-VLIW.jpg
