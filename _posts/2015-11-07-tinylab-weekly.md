---
title: 泰晓周报·11月 / 第一周 / 2015
author: Chen Jie
layout: post
permalink: /weekly-11-1st-2015
tags:
  - jemalloc
  - malloc
  - heap profiling
  - jeprof
categories:
  - 泰晓周报
---

> by Chen Jie of [TinyLab.org][1]
> 2015/11/07

- [Anandtech：iPhone 6s 和 iPhone 6s Plus 评测报告](http://anandtech.com/show/9686/the-apple-iphone-6s-and-iphone-6s-plus-review)
<p style="padding-left:3em; text-indent:-1em; color:#53575f"><span style="font-size:25px">&quot;</span>
With yet another round of architectural improvements and a clockspeed approaching 2GHz, comparing Apple’s CPU designs to Intel’s is less rhetorical than ever before.
<span style="font-size:25px">&quot;</span></p>

<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">可能是技术最深度的评测报告，过瘾的 A9 芯片解读</p>
<br/>

- [The Information: Google 考虑自己设计芯片](https://www.theinformation.com/with-apple-in-mind-google-seeks-android-chip-partners)

<p style="padding-left:3em; text-indent:-1em; color:#53575f"><span style="font-size:25px">&quot;</span>
Google recently talked with some microchip makers about developing chips based on Google's own preferred designs
</p><p style="padding-left:4em; text-indent:-1em; color:#53575f">
That, Google hopes, would make its Android mobile operating system more competitive with Apple’s phones at the high end of the market and solve other major problems.
<span style="font-size:25px">&quot;</span></p>

<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">如 A 系列芯片之于 iOS；优化 Android 生态的垂直整合水平</p>
<br/>

- [Intel OTC: 我们做到了 Chrome OS 图形管线上的纹理零拷贝](https://01.org/zh/blogs/2015/zero-copy-texture-uploads-chrome-os)

<p style="padding-left:3em; text-indent:-1em; color:#53575f"><span style="font-size:25px">&quot;</span>
Native zero-copy in Intel architecture is always beneficial in both performance measurements and memory consumption measurements that we performed.
<span style="font-size:25px">&quot;</span></p>

<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">领略 Chrome OS 图形管线；内核 DRM 子系统与 dma-buf 框架之舞；CPU 与 GPU 统一寻址、HSA（Heterogeneous System Architecture）之小犀利</p>
<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">顺便说一句，Chrome OS 并入 Android 流言已由 Google 出面辟谣</p>
<br/>

- [Phoronix.com: NVIDIA 似蓄势待发 Vulkan 驱动](http://www.phoronix.com/scan.php?page=news_item&px=NVIDIA-Vulkan-Nearing-Release)

<p style="padding-left:3em; text-indent:-1em; color:#53575f"><span style="font-size:25px">&quot;</span>
NVIDIA is readying their Vulkan drivers for a same-day release and on the Windows side they've already begun exposing some of the Vulkan interface. 
<span style="font-size:25px">&quot;</span></p>

<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">次世代图形编程接口，OpenGL 接班人，这么快就来了</p>
<br/>

- [Phoronix.com: 触摸板 协议及 Weson 支持之开发再启动](http://www.phoronix.com/scan.php?page=news_item&px=Tablet-Revised-For-Wayland)

<p style="padding-left:3em; text-indent:-1em; color:#53575f"><span style="font-size:25px">&quot;</span>
Peter Hutterer is back to working on tablet protocol and support for Wayland/Weston.
<span style="font-size:25px">&quot;</span></p>

<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">移动互联时代，UI 交互之基础技术正发生积极变革。比如 Vulkan 替代 OpenGL，还有开源的 Wayland/Weston Stack 替代 Xorg</p>
<br/>

- [LKML: Btrfs 在 Linux 4.4 开发版本有许多改进](http://lkml.iu.edu/hypermail/linux/kernel/1511.0/04360.html)

<p style="padding-left:3em; text-indent:-1em; color:#53575f"><span style="font-size:25px">&quot;</span>
The Btrfs file-system in Linux 4.4 has a number of sub-volume quota improvements, many code clean-ups, and a number of allocator fixes based upon their usage at Facebook
<span style="font-size:25px">&quot;</span></p>

<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">Btrfs 被认为是 Linux 下一代文件系统，采用类似 ZFS COW 而非日志的可靠性机理。目前正在 FB 规模试用</p>
<br/>

- [LKML: Linux Kernel Library 让应用使用 Kernel 代码](http://lkml.iu.edu/hypermail/linux/kernel/1511.0/01898.html)

<p style="padding-left:3em; text-indent:-1em; color:#53575f"><span style="font-size:25px">&quot;</span>
With LKL, the kernel code is compiled into an object file that can be directly linked by applications.
</p><p style="padding-left:3em; text-indent:-1em; color:#53575f">
LKL is implemented as an architecture port in arch/lkl. It relies on host operations defined by the application or a host library (tools/lkl/lib).
<span style="font-size:25px">&quot;</span></p>

<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">与本站相似的点子。不过我们出发点是用户态复用内核 C 库，且臆想一份代码页，内核和用户空间两映射</p>
<br/>

- [LWN: 内核自我保护（Self Protection）项目启动](http://lwn.net/Articles/663361/rss)

<p style="padding-left:3em; text-indent:-1em; color:#53575f"><span style="font-size:25px">&quot;</span>
a community of people to work on the various kernel self-protection technologies (most of which are found in PaX and Grsecurity
<span style="font-size:25px">&quot;</span></p>

<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">华盛顿邮报近日撰文 <a href="http://www.washingtonpost.com/sf/business/2015/11/05/net-of-insecurity-the-kernel-of-the-argument/">指 Linux 缺乏安全性</a>。文中引 Linus 言：</p>
<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">"Security in itself is useless. . . . The upside is always somewhere else. The security is never the thing that you really care about."</p>
<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">"If you run a nuclear power plant that can kill millions of people, you don’t connect it to the Internet."</p>
<br/>

- [LKML: Linus 发飙写的丑的代码](http://lkml.iu.edu/hypermail/linux/kernel/1510.3/02866.html)

<p style="padding-left:3em; text-indent:-1em; color:#53575f"><span style="font-size:25px">&quot;</span>
The above code is sh*t, and it generates shit code. It looks bad, and there's no reason for it.
</p><p style="padding-left:4em; text-indent:-1em; color:#53575f">
All this kind of crap does is to make the code a unreadable mess with code that no sane person will ever really understand what it actually does.
<span style="font-size:25px">&quot;</span></p>

<p style="padding-left:3em; text-indent:-1em; color:#a6aaa9">死磕代码，才经得起时间，才托得了信任</p>

---
泰晓周报，汇总一周技术趣闻与文章。
