---
layout: post
author: 'Wu Zhangjin'
title: "Linux 内核实时化技术的走向"
album: '实时 Linux'
permalink: /the-outlook-of-real-time-linux/
description: "本文摘自 泰晓原创团队 微信群，内容源自清华大学陶品老师和泰晓主创吴章金的一问一答。本文主要讨论了 Linux 内核本身进行实时化改造的发展方向。"
category:
  - 实时抢占
  - 实时性
tags:
  - Linux
  - Real Time
  - RT Preempt
  - 实时
  - 抢占
---

> By Falcon of TinyLab.org
> 2015-11-24

## 背景介绍

2015 年 11 月 19 日，泰晓原创团队微信群发起了讨论，讨论主要围绕 Linux 内核实时化技术的一个发展走向。

刚开始有几个同学在问实时抢占补丁（RT Preempt）的维护状态、移植、验证和优化等内容，也提到了 RTAI、Xenomai 等其他实时化方案。后面，来自清华大学的陶老师针对实时抢占补丁提了三个问题，笔者结合自己早期的相关研究和社区工作进行了回答。内容整理如下。

**注**：如果想事先了解更多 Linux 实时抢占项目的背景，可以阅读笔者早前的文章：《[嵌入式 Linux 系统怎样保证实时性](https://tinylab.org/how-to-make-a-linux-system-real-time/)》。

## 三问三答

陶老师的提问内容如下：

> 看到上午大家讨论 RT Linux 的一些发言，又去所提供的链接看了看，包括 Wu Zhangjin 的 [Porting RT-preempt to Loongson2F](http://lwn.net/images/conf/rtlws11/papers/proc/p14.pdf) 那篇论文，看到这方面的工作这么出色，不禁对我原先的看法有所动摇。因为之前我自己对 Linux 实时化的看法是负面的，我是觉得要想实时就单做一个小 RT 核心和 Linux 并行运行就好了，原因是：

> * 如果想让 Linux 全部改为 RT，要做的修改太多，而且还得随着 Linux 内核主线版本的提升而提升，维护工作量太大。
> * RT 需求和节能低功耗、服务器高吞吐量等需求相抵触，内核的技术演化方向不能在两种相抵触的需求之间摇摆，最后可能会放弃 RT。
> * RT 改来改去，由于 Linux 代码太复杂，无论怎么改，怎么测试，估计也不能万无一失，万一有地方没有考虑到呢？没有测试到呢？而且很多RT的杀手是其他人开发的外挂模块，难以防范。如果找专业团队来做，研发成本可能太高。

笔者思考后作答如下：

### RT Preempt 维护量是否过大？

__问__：如果想让 Linux 全部改为 RT，要做的修改太多，而且还得随着 Linux 内核主线版本的提升而提升，维护工作量太大。

__答__：维护的确是一个巨大的工程，但相对于 Linux，简直是九牛一毛，Linux 都有生态在维护，RT 更是，何况 RT 本身的很多工作对主线 Linux 是有益处的，会带来性能等方面的提升或者是架构的演进，RT-preemt 本身的维护就是不断跟进主线 Linux，大部分变更已经逐步合并进入主线，部分还在不断迭代，与这个过程持续地伴随着地是，内核从早期的自愿抢占，低延迟到 RT-preempt 本身的目标：完全抢占，部分维护工作为主线 Linux 各子系统 maintainers 自己接管，Rt-preempt 由第三方维护那些还有待继续迭代完善的补丁。目前这个由 Thomas 领导的 OSADL 在维护。需要特别提到的是，RT-preempt 为桌面等传统低延迟的需求也带来了巨大的好处，比如说衍生于该项目的 Ftrace，Android 基于它开发的 Systrace 为性能和交互体验优化带来了巨大的便利。

### 如何平衡 RT 与其他看似矛盾的需求？

__问__：RT 需求和节能低功耗、服务器高吞吐量等需求相抵触，内核的技术演化方向不能在两种相抵触的需求之间摇摆，最后可能会放弃 RT。

__答__：其实内核本身就是对各种需求妥协的产物，妥协的结果是架构的逐步完善以应对各类看似相互矛盾的需求。除了 RT，很多矛盾的内容已经在主线 Linux 上得到了很好地 balance，比如说功耗需要降频，性能需要提频，那内核的解决思路是 DVFS+Cpufreq 等以及未来即将引入的 EAS，尽量在确保性能的前提下满足功耗的需求。而 RT 也是类似，如果任意 DVFS，系统的确定性是无解的，那内核的解决思路是什么，PM Qos，可以根据 Latency 需求主动锁定资源。当然这些相比纯实时系统或者半虚拟化，对于开发来说潜在增加了应用开发的难度，也实际因此会引入“不确定性”。就开发复杂度可能引入的这种“不确定性”而言，退化的解决方案或许是纯 RT 或者 Xtratum+PartiKle+Linux 或者是风河的虚拟机+Vxworks+Linux 等方案，即虚拟化+RT+Linux，当然，纯 RT 功能不及 Linux 丰富，虚拟化引入了架构的复杂性以及额外的 Guest OS 的开发复杂度，同样有自己的弱势。这些并不是非此即彼的 Solutions，要看应用需求三选一：纯 Linux（Rt preempt）、纯RT、或者是虚拟化+RT+Linux。无论怎样，Linux 本身这种 RT 演进会不断持续深化，不仅是为满足部分 RT 专有场景需求，也是 Linux 本身演化的需要（架构的清晰化，普通场景的性能提升等）。并且随着演进的深入，这种 Solution（Rt preempt）必然会有越来越多的应用场景，事实上据我所知，RT Preempt 的企业客户很多。

### RT 的复杂度对 Linux 质量影响几何？

__问__：RT 改来改去，由于 Linux 代码太复杂，无论怎么改，怎么测试，估计也不能万无一失，万一有地方没有考虑到呢？没有测试到呢？而且很多 RT 的杀手是其他人开发的外挂模块，难以防范。如果找专业团队来做，研发成本可能太高。

__答__：首先，RT 所涉猎地内容的确是 Linux 最核心的部分，也是最复杂的部分：时钟、中断、调度、同步、互斥等等，但是正是这些子系统的核心贡献者和维护者在推动或者主导 RT 的演化，在代码质量和准入层面基本是由他们在把控。其次，这些演化本身也在倒过来推动内核架构的完善和清晰，甚至部分会简化，解决本身原有的问题，比如大内核锁的去除。第三，所参与厂商的自动化验证，比如说 Redhat 和 IBM 等维护的 [auotest.github.io](http://autotest.github.io)，Intel 两年前左右部署的[大型 Linux 衰退测试系统](http://lwn.net/Articles/514278)，可用于或者一直在监测 Linux 的衰退。第四，就 RT-preempt 本身，OSADL 部署了几个大型机架在做持续不间断的[压力和衰退测试](http://www.osadl.org/QA-Farm-Realtime.qa-farm-about.0.html)的同时在跑 Cyclictest，几十台机器，几种主流架构，这些结果在一定程度上可以认为就是确定性，比如说，几年下来都是 80us，这个就是 deterministic。第五，除此之外，针对 Linux 的形式化认证工作也有研究机构和企业在做，研究方面，比如我上学那会在 DSLab 参与的 Sil4Linux 研究以及主导开发的[形式化分析系统](http://sil4linux.dslab.lzu.edu.cn)；实际上也有企业已经认证 Linux 在某些受限条件下达到 SIL4 级别（两年前 Nicholas 回复确认）。当然，最后一个环节是产品应用，这个需要良好的研发技术积累、研发流程代码管控、自动化验证体系，以及可能要引入的第三方代码形式化评估和认证机构，具体要看容错的投入和认证的开销了，又或者即使有 failure，这种故障导致的后果是否可以接受。至于外挂部分其实不是 Safety 的内容，而是 Security，这部分内核有 SELinux 等安全框架，目前 Android 默认启用了 SELinux，以便细粒度地管控权限，如果授权解决了，未知应用的优先级和资源使用受控就不会引起问题了，实际上，其他方案也有类似的安全问题。

## 小结

RT 从 2006 年左右启动至今，Linux 内核本身已经达到了一定的产品级实时化程度，关注该方案的企业和机构肯定会越来越多，但是目前来看，实际产品使用经验以及相应的公开资料很少，尤其是上层应用的产品级开发和应用实例严重缺失，导致有需求的企业或者机构处在观望状态。未来如果要继续推广和普及 RT Preempt，加强实际实时应用的开发案例和文档的建设尤为关键。在实时应用开发方面，推荐一本书：《POSIX.4: Programming for the Real World》。

笔者从 2008 年左右从事 RT Preempt 相关的研究，完成了[龙芯 2F 系列的 RT Preempt](https://github.com/tinyclub/preempt-rt-linux) 支持，[移植 FTrace 到了 MIPS/龙芯 平台](http://lwn.net/Articles/361128/)，也维护了一段时间的 MIPS 平台的 RT Preempt，另外，也算是在国内较早系统地研究 RT Preempt，相应的研究论文报告为：《[Research and Practice on Preempt-RT Patch of Linux](/wp-content/uploads/2015/11/linux-preempt-rt-research-and-practice.pdf)》。未来希望跟企业合作，在实际工业应用方面做一些尝试，与此同时，会优先在泰晓这个平台分享更多的相关技术分析文章。

[1]: https://tinylab.org
