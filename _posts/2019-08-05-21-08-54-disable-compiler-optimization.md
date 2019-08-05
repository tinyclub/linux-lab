---
layout: post
author: 'Wu Zhangjin'
title: "Linux 下如何绕过编译器优化"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /disable-compiler-optimization/
description: "编译器优化效果通常是正向的，但是有些情况下确不希望编译器启动优化动作，比如说在调试的时候。"
category:
  - 调试和优化
  - Gcc
tags:
  - volatile
  - -O2
  - -Os
  - CFLAGS_REMOVE
  - KBUILD_CFLAGS
---

> By Falcon of [TinyLab.org][1]
> Aug 05, 2019

有同学在群里聊到编译器优化的事情，很多时候期望编译器默认做优化，但是有些场景是希望能绕过的，哪些呢？

这里举两个实实在在的例子。

第一个，在调试的时候，如果默认开启了优化，要关注的某个变量值，用 gdb 打印时可能会提示被优化掉了，会让人丈二和尚摸不着头脑。

第二个，就是某些场景，编译器并不理解背后的实际情况，比如说，连续往某个地址写两个值，编译器以为，这不是多此一举了，帮把最后一个写进去就好了，但是殊不知，这个地址可能是个硬件寄存器地址呢，写第一个，处理器调整一个状态，再写一个，再调整一个状态，两个都写完，才算完整，写不同的位有不同的含义。

## 怎么去掉显式优化参数

对于第一个，通常不太需要去改整个内核，比如说，把整个 `-O2/-Os` 都拿掉，这时可能引起的莫名情况比去 debug 某个问题可能还要棘手。所以，可以有针对性的，只对某个文件做优化参数调整即可。

这个本质上是拿掉 `CFLAGS` 里头的优化参数，其实用替换就好了，但是可选的用法有：

**文件级**：`CFLAGS_REMOVE_xxx.o = -O2`

`arch/mips/kernel/Makefile`:

    ifdef CONFIG_FUNCTION_TRACER
    CFLAGS_REMOVE_ftrace.o = -pg
    CFLAGS_REMOVE_early_printk.o = -pg
    CFLAGS_REMOVE_perf_event.o = -pg
    CFLAGS_REMOVE_perf_event_mipsxx.o = -pg
    endif

原理如下，就是从原始编译参数中 `filter-out` 掉特定参数：

    $ grep CFLAGS_REMOVE -ur linux-stable/scripts/Makefile.lib
    _c_flags       = $(filter-out $(CFLAGS_REMOVE_$(basetarget).o), $(orig_c_flags))

**目录级**：`KBUILD_CFLAGS := $(filter-out -O2, $(KBUILD_CFLAGS))`

`arch/mips/boot/compressed/Makefile`:

    KBUILD_CFLAGS := $(filter-out -pg, $(KBUILD_CFLAGS))

自己主动 `filter-out` 掉。也可以直接调用脚本替换：

    KBUILD_CFLAGS := $(shell echo $(KBUILD_CFLAGS) | sed -e "s/-pg//")

当然，用 Makefile 内置的 `filter-out` 效率会高，只是方便大家理解逻辑。

怎么确认这个编译参数是否真地生效呢，有两种方法：

一种是直接在相应 Makefile 打印 `KBUILD_CFLAGS`，例如：`$(error $(KBUILD_CFLAGS))`，另外一种是 `make /path/to/xxx.o V=1` 查看。在 Linux Lab 里头可以用 `make k-x /path/to/xxx.o V=1`。

## 怎么去掉隐式优化

第二个，也来看看实例：

`drivers/cpufreq/loongson2_cpufreq.c`:

    static void loongson2_cpu_wait(void)
    {
            unsigned long flags;
            u32 cpu_freq;

            spin_lock_irqsave(&loongson2_wait_lock, flags);

            cpu_freq = LOONGSON_CHIPCFG(0);
            LOONGSON_CHIPCFG(0) &= ~0x7;    /* Put CPU into wait mode */
            LOONGSON_CHIPCFG(0) = cpu_freq; /* Restore CPU state */

            spin_unlock_irqrestore(&loongson2_wait_lock, flags);
            local_irq_enable();
    }

上面中间三句，从 gcc 的角度来看，这不是傻嘛，啥也没做啊，又读又写是什么鬼，目标变量的值根本“没变”呢。原因是什么，这个背后的 `LOONGSON_CHIPCFG(0)` 是硬件寄存器地址，有它的时序意义，不同的位有不同的意义，写不同的值会有不同的动作。这个时候就得明确告诉 gcc：

`arch/mips/include/asm/mach-loongson64/loongson.h`:

    #define LOONGSON_CHIPCFG(id) (*(volatile u32 *)(loongson_chipcfg[id]))

这种情况怎么确认呢？`make /path/to/xxx.s`，看看代码还在不在。在 Linux Lab 里头可以用 `make k-x /path/to/xxx.s`。

[1]: http://tinylab.org
