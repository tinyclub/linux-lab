---
layout: post
author: 'Wang Chen'
title: "LWN 149877: 动态时钟补丁的最新状况"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-149877/
description: "LWN 文章翻译，动态时钟补丁的最新状况"
category:
  - 时钟系统
  - LWN
tags:
  - Linux
  - timer
---

> 原文：[The state of the dynamic tick patch](https://lwn.net/Articles/149877/)
> 原创：By corbet @ Aug. 31, 2005
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [guojian-at-wowo](https://github.com/guojian-at-wowo)

> The configurable timer interrupt frequency patch, part of the 2.6.13 kernel, led to a certain amount of controversy over the optimal default value. That default is 250 Hz, but there arguments in favor of both increasing and decreasing that value. There was no consensus on what the default should really be, but there is a certain amount of agreement that the real solution is to merge the [dynamic tick patch](https://lwn.net/Articles/138969/). By varying the timer interrupt frequency in response to the actual system workload, the dynamic tick approach should be able to satisfy most users.

在 2.6.13 版本的内核中所引入的 “支持定时器中断频率可配置” 这个补丁，一定程度上引发了社区对最优 HZ 默认值的争议。补丁中 HZ 的默认值设置为 250 赫兹，赞成增大和减小该值的人都有。看上去希望在默认值的选择上达成一致是不可能的了，但有个好消息就是大家对合入[动态时钟补丁](https://lwn.net/Articles/138969/)倒是都持赞成意见。动态时钟可以在系统运行过程中根据实际的工作负荷动态地调整定时器中断发生的频率，应该能够满足大多数用户的需求。

> Now that patches are being merged for 2.6.14, the obvious question came up: will dynamic tick be one of them? The answer, it seems, is almost certainly "no." This patch, despite being around in one form or another for years, is still not quite ready.

现在已经启动了针对 2.6.14 版本的补丁合入工作，那么问题就来了：动态时钟补丁这次也会被接纳吗？很可惜，目前看起来，答案几乎肯定是 “不会”。尽管该补丁已经以多种方式存在了多年，但目前看上去还没有为最终合入主线做好准备。

> One issue, apparently, is that systems running with dynamic tick tend to boot slowly, and nobody has yet figured out why. The problem can be masked by simply waiting until the system has booted before turning on dynamic tick, but that solution appeals to nobody. Until this behavior is understood, there will almost certainly be opposition to the merging of this patch.

影响其合入主线的一个最显而易见的问题是，使能动态时钟的系统往往启动缓慢，具体原因还无人知晓。当然我们可以绕过这个问题，具体的方法就是在系统启动完成之后再打开动态时钟，但很明显没有人会愿意这么做。看起来只有首先解决了这个问题，该补丁才有可能被内核所接纳。

> Another problem with the current patch is that it does not work particularly well on SMP systems. It requires that all CPUs go idle before the timer interrupt frequency can be reduced. But an SMP system may well have individual CPUs with no work to do while others are busy; such a situation could come up fairly often. Srivatsa Vaddagiri is working on [a patch for SMP systems](https://lwn.net/Articles/147370/), but it is still a work in progress and has not received widespread testing.

目前该补丁还存在另外一个问题，它在 SMP 系统上运行效果不佳。它要求在所有的 CPU 都空闲后才可以执行降低定时器中断频率的动作。但对于一个 SMP 系统来说，通常很少会出现所有 CPU 都空闲的情况。Srivatsa Vaddagiri 正在致力于[一个针对 SMP 系统的补丁](https://lwn.net/Articles/147370/)，但它仍在开发过程中，尚未得到广泛的测试。

> The end result is that dynamic tick is unlikely to come together in time to get into 2.6.14; the window for merging of patches of this magnitude is supposed to close within a week or so. So this patch will be for 2.6.15 at the earliest. If the revised development process works as planned, 2.6.15 should not be all that far away. Hopefully.

由于下一个版本的内核集成窗口期会在一周左右结束，目前看来，动态时钟补丁是来不及合入 2.6.14 了。 如果该补丁的开发过程能够按计划进行，最快有希望随 2.6.15 合入内核主线（译者注，最终合入动态时钟补丁的内核版本是 2.6.21，离本文发表也是快一年半以后的事情了 :-)）。

[1]: http://tinylab.org
