---
layout: post
author: 'Wu Zhangjin'
title: "实时 Linux 抖动分析 Step by step"
draft: false
top: true
album: '实时 Linux'
license: "cc-by-nc-nd-4.0"
permalink: /rtlinux-latency-tracing/
description: "本文介绍了实时 Linux 抖动分析的工具 Ftrace 以及具体分析步骤。"
category:
  - 实时系统
  - Latency
tags:
  - Ftrace
  - kernelshark
  - tracing_max_latency
  - irqsoff tracer
  - preemptoff tracer
  - preemptirqsoff tracer
---

> By Falcon of [TinyLab.org][1]
> Aug 08, 2019

前段时间有同学问到：

> 大家有显卡方面实时性调优经验交流吗？我现在是 x86，不加显示任务实时性可以保持在 20us 内，如果加上显示，抖动就飙升到 70us，其实显示是辅助功能。

其实造成抖动的原因已经清楚了，但是要解决问题还得定位到具体的代码，到底是哪段代码造成了这么大的抖动呢？

从问题本身来看，这个应该是可复现的，所以接下来就是要解决它。

解决这类问题通常是用专属工具 Ftrace 的 Max Latency Tracing，大体用法可参考 `Documentation/trace/ftrace.rst`。

大体分析过程如下：

## 使用抢占内核或者 preempt-rt 内核

如果用普通内核，请在内核 `General setup` 下 `preemption model` 开启 `low-latency desktop`。

    CONFIG_PREEMPT=y

从问题来看，应该是已经用上了实时抢占内核，这时需要打开如下配置：

    CONFIG_PREEMPT_RT_FULL=y

如果没有使用，得参考 [实时 Linux](/rtlinux) 一文从 [发布地址](https://cdn.kernel.org/pub/linux/kernel/projects/rt/) 找到相应版本的 patch 打上，并针对所用板子做进一步优化，而且要关闭很多可能影响实时性能的调试选项。

## 配置内核，打开中断和抢占关闭等 tracer

在内核配置 `Kernel Hacking` 下 `Tracers`

    --- Tracers
    [*] Kernel Function Tracer
    [*]   Kernel Function Graph Tracer
    [*] Interrupts-off Latency Tracer
    [*] Preemption-off Latency Tracer
    [*] Scheduling Latency Tracer
    [*] Enable upbrobed-based dynamic events
    [*] enable/disable function tracing dynamically

## 重新编译内核，启动到问题现场并开始分析

先确保能复现问题的场景是一直在跑的，然后就是参考上面 ftrace.rst 用法开始 tracing。

稍微补充几点小技巧：

- sys/kernel/tracing 挂载

  默认这个目录可能没挂载，

      $ mount -t tracefs none /sys/kernel/tracing

  早期内核可能用的 `/sys/kernel/debugfs/tracing` 目录，需要先挂载 `debugfs` 如下：

      $ mount -t debugfs none /sys/kernel/debugfs

- tracers：irqsoff, preemptoff, preemptirqsoff

  建议先用第三个，再逐步用第一个和第二个。第三个是两个的或，如果先用第一个或者第二个，即使解决了发现的问题，也可能不是造成 max latency 的热点路径。

- 开始 tracing 前，清空历史记录

  启动新的 `tracing` 之前，记得清空上次记录，避免造成误判，以 `irqsoff` 为例：

      echo 0 > options/function-trace
      echo irqsoff > current_tracer
      echo 1 > tracing_on
      echo 0 > tracing_max_latency

      do something for repeat the issue scene

      echo 0 > tracing_on

      cat trace > trace.log

最后就是分析日志和解决问题，原因不外乎是长时间关了抢占或者关了中断，这个就得具体问题具体分析，看情况是要做中断线程化还是主动加调度点等等。

对于 tracing 日志分析，类似 Android 上的 `Systrace` 图形化分析工具，Linux 上有 `kernelshark`。

[1]: http://tinylab.org
