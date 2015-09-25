---
title: Android Linux 可靠性（RAS）研究与实践 
author: Wu Zhangjin
layout: post
permalink: /android-linux-ras-research-and-practice/
transposh_can_translate:
  - 'true'
tags:
  - Android
  - 珠海GDG
  - Google IO
  - Linux
  - RAS
  - 可用性
  - 可维护性
  - 可靠性
categories:
  - Android
  - Reliability, Availability, Serviceability
---

> by falcon <wuzhangjin@gmail.com> of TinyLab.org
> 2013/06/04 10:20

**安卓手机**跟**死机王**这两个关键字在搜索引擎的匹配度很高，这反应了发布到市场上的安卓手机参差不齐，有些手机产品的稳定性确实不高，但是 Google 的 Andriod 系统在可靠性（Reliability）、可用性（Availability）和可维护性（Serviceability）三个方面都做了大量的工作，而且 Android 系统倚重的 Linux 内核在服务器领域的占有率很高，这说明 Linux 本身的可靠性以及相应的保障机制是非常到位的。

那么，很重要的原因就是 Android 手机方案的提供商和 Android 产品的制造商做的工作不够系统，不够专业，或者是有些厂商缺乏这样的意识，因而没有足够的投入。当然，可能的其他原因还有：手机产品本身的复杂度很高，而且迫于市场压力，发布周期越来越短，那意味着留给工程师们解决问题的时间其实不多。如果没有系统的研究，长期的积累以及规范化的软件工程流程，那么，要提升产品的稳定性是相当困难的。

下面的这个幻灯将从三个方面跟大家分享如何提升Android系统的这三项指标：RAS，即可靠性（Reliability）、可用性（Availability）和可维护性（Serviceability）。这三个方面分别是：

1. 制定并明确 RAS 的应用目标；
2. 研究 Android Linux 在 RAS 方面的一些工作成果。
3. 从软件工程的角度设计一套完整的解决方案，并在该方案中部署 Android 的相关成果。

考虑到时间和篇幅的关系，这个幻灯并没有介绍 Linux 本身在 RAS 方面的诸多工作，计划在后续文章中逐步补充。

受 [珠海GDG](http://www.chinagdg.com/forum-94-1.html) 邀请，作者于 2013 年 5 月 16 号晚在今年的 Google IO 直播大会珠海唐家分场，与在场的来自附近高校的一些学生和南方软件园的一些工程师们一起探讨了 Android 系统的稳定性问题，现场交流气氛活跃。

下载该幻灯片，请点击：[Android_Linux_RAS_practice.pdf](/wp-content/uploads/2013/06/Android_Linux_RAS_practice.pdf)。
