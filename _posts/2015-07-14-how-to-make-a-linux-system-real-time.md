---
title: 嵌入式 Linux 系统怎样保证实时性
author: Wu Zhangjin
layout: post
permalink: /how-to-make-a-linux-system-real-time/
tags:
  - 硬实时
  - 软实时
  - Real Time
  - 实时
categories:
  - Linux
  - Real Time
---

> By Falcon of [TinyLab.org][2]
> 2015/7/14


## 简介

笔者前段时间在[知乎][3]回答了该问题，考虑到更多同学可能需要，这里再展开解释。

简单来说，可以根据实时需求选择不同实时 Linux 方案，然后在选定方案上针对特定需求做进一步的优化。

展开的话，

## 明确需求

首先看具体使用环境，确定是硬实时环境（Safety-Critical，低延时，比如几十个us内）还是软实时（几百个us~几个/几十个ms)，还是普通的低延迟桌面（几个ms到几百个ms）等？

比如说有航天飞控，汽车制动系统、动力传输解决方案、精密仪器等都有较高的硬实时要求，硬实时通常跟高可确定性、靠性要求同时出现，如果达不到，可能会造成重大生命或者财产损失。

而普通的，比如音、视频播放、游戏画面，对于实时性要求相对较低，只要达到播放的 Frame Rate 就好，比如说视频播放 24 个 FPS，而游戏 40~60 FPS 就很流畅，几乎感觉不到卡顿，也就是 16.6 ms。

而桌面交互应用点击，网页加载，应用启动这类则没有那么高的要求，通常在 100ms 以内，加上过度动画，就会有很好的体验效果。

对于软实时，可靠性要求没那么高，即使出现了延迟，造成的损失可控，比如说音频失真，视频过度不自然或者是交互不顺畅。而硬实时领域，通常一旦出现延迟，造成的损失可能不可估量，所以要求有比较高的可确定性。

## 可选方案

Linux 本身已经有硬实时的方案，比如来自风河的 RT Linux，或者西班牙一家研究所的 XtratuM + PartiKle，还有其他的比如 Xenomai，RTAI 等。另外，内核官方还有完全抢占内核（Preempt-RT Linux）的支持，这个在某些情况下也达到了硬实时要求，比如我 09 年移植的 MIPS 实时抢占 Linux 在 Loongson-2F 上的 Latency 已经达到 100us 左右，看图：

![Loongson 2F Real Time Latency][4]

原图地址：[Latency plot of Loongson Real Time Linux system in OSADL][5]

*注*：这个机器（龙芯 2F 盒子）是笔者的奥地利导师 09 年带到 [OSADL][6] 的，放在那里跑了几年，实时性一直都很稳定，笔者当时移植最早的一版是 `linux-2.6.26.8-rt16`，现在都支持：`Linux 3.12.24-rt38` 了。OSADL 也是当前 Preempt-RT 的官方维护机构。

如果要求再低一些，用内核里头的其他抢占选项就可以。

然后就是各种优化，包括驱动（irq, preempt disable), spin lock 等使用，中断函数线程化，mdelay 替换为 usleep_range() 等，详细的可以参考我几年前写的论文吧：[Research and Practice on Preempt-RT Patch of Linux][7] 和 [Porting RT-preempt to Loongson2F][8]。论文是 09 年底，10 年初写的，5 年间很多游离的 Patch 应该都已经进入了 Linux 主线，当然，还有更多新特性在持续开发和维护。

优化时需要用到很多工具，比如 Ftrace, Perf, Cyclictest, [Oscilloscope][9] 等。

需要提到的是，除了系统以外，硬件本身的低延迟设计、可靠性设计等也会严重影响系统的实时性，所以在选择方案时一定要兼顾考虑这部分，比如说 ARM Cortex A/R/M 三系中的 R 就是专为高端嵌入式实时系统设计的，比如说在中断行为方面做了优化。这里不做深度展开。

更多内容请查看后续参考资料，回复该文，或者关注 [@泰晓科技][10] 后私信。

## 相关资料

  * [OSADL 实时抢占内核补丁/工具下载地址][11]
  * [Linux 官方 Real Time Wiki][12]
  * [嵌入式 Linux Wiki 中的 Real Time 部分][13]
  * [实时抢占补丁研究与实践][7]
  * [Porting RT-preempt to Loongson2F][8]
  * [Preempt RT 4 Loongson 项目首页][14]





 [2]: http://tinylab.org
 [3]: http://www.zhihu.com/question/20610026
 [4]: /wp-content/uploads/2015/07/loongson-2f-preempt-rt-latency.gif
 [5]: https://www.osadl.org/Latency-plot-of-system-in-rack-2-slot.qa-latencyplot-r2s4.0.html?latencies=&showno=&slider=159
 [6]: https://www.osadl.org
 [7]: http://www.docin.com/p-170582115.html
 [8]: http://lwn.net/images/conf/rtlws11/papers/proc/p14.pdf
 [9]: /tinydraw/
 [10]: http://weibo.com/tinylaborg
 [11]: https://www.osadl.org/Downloads.downloads.0.html
 [12]: https://rt.wiki.kernel.org/index.php/Main_Page
 [13]: http://www.elinux.org/Real_Time
 [14]: /preempt-rt-4-loongson
