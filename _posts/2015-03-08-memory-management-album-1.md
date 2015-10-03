---
title: 技术专辑：内存管理（1）
author: Wu Zhangjin
layout: post
album: 内存管理
permalink: /memory-management-album-1/
tags:
  - CMA
  - jemalloc
  - Linux
  - malloc
  - Memory
  - OS X
  - SSDAlloc
categories:
  - C
---

> by 主编 of [泰晓科技 | TinyLab.org][1]
> 2015/3/8

本专辑主要介绍内存管理、内存分配相关内容。

* [“茴”字有几种写法 — 结构体占多少空间你造吗？][2]

  > 近来无意卷入某个考试，题风颇为远古，中有若干结构体空间占用的题目，i.e. “sizeof(struct …)”，你懂的。问谷歌，发现几处文章均不十分符实验。本文据网上文章所留线索，结合实验总结而来，呈现：“茴字有几种写法，你造么？”

* [SSDAlloc：用 SSD 扩展内存][3]

  > 某次在企业存储工程师的职位描述中看到 SSDAlloc，细查了下，SSDAlloc 是用 SSD 来扩展内存的一种方法。直接用 SSD 做 swap 不就行了，为啥还要整一个 SSDAlloc ？答案是 SSDAlloc 性能要好太多。

* [Buddy和CMA简介以及在Android中实际使用CMA遇到问题的改进][4]

  > 本文是朱辉在 中国Linux内核开发者大会 上作的标题为 《Buddy 和 CMA 简介以及在 Android 中实际使用 CMA 遇到问题的改进》 的话题幻灯片。其中包括手持的讲稿，所以文字比较多。

* [内存分配奥义·jemalloc(一)][5]

  > C 中动态内存分配malloc 函数的背后实现有诸派：dlmalloc 之于 bionic；ptmalloc 之于 glibc …… 以及 jemalloc 之于 FreeBSD/NetBSD/Firefox。

* [<内存分配奥义·jemalloc(二)>][6]

  > 我们疑惑 jemalloc 的层层缓冲会造成过多的内存占用，这对实时性要求较高，内存较为紧张的移动设备影响较大。对此，jemalloc 如何应对呢？还有，是否存在系统内存紧张时，减少缓冲的联动机制呢？

* [内存分配奥义·malloc in OS X][7]

  > 苹果的一切似乎都透着其背后的设计气息～苹果的代码也不例外，通常表现抽象的模型，通常直击清晰的场景，通常带着一些防呆编码来侦测客户代码中的错误。抽象的模型在不同代码间塑现，使得呈现出一种整体性；清晰的场景来垂直整合，使得呈现一种便利性&#8230;





 [1]: http://tinylab.org
 [2]: /anise-word-there-are-several-ways-to-approach-how-much-space-do-you-make/
 [3]: /ssdalloc-using-ssd-for-expandable-memory/
 [4]: /buddy-actually-use-cma-and-cma-brochures-as-well-as-android-problem-improving/
 [5]: /memory-allocation-mystery-%c2%b7-jemalloc-a/
 [6]: /memory-allocation-mystery-%c2%b7-jemalloc-b/
 [7]: /memory-allocation-mystery-malloc-in-os-x-ios/
