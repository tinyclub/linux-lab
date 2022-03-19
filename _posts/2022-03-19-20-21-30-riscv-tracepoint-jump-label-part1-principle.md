---
layout: post
author: 'Wu Zhangjin'
title: "RISC-V tracepoint jump_label 架构支持详解，第 1 部分：技术背景"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /riscv-jump-label/
description: "本文是对 RISC-V jump_label 架构支持分析成果的第 1 部分，主要介绍 Jump Label 的相关技术背景，接下来会陆续展开介绍其实现细节。"
category:
  - 开源项目
  - Risc-V
tags:
  - Linux
  - RISC-V
  - Tracepoint
  - Jump Label
  - 条件分支
  - 无条件跳转
  - NOP
  - ISA
  - 指令编码
---

> Author:  Wu Zhangjin <falcon@tinylab.org>
> Date:    2022/03/19
> Project: https://gitee.com/tinylab/riscv-linux

## Tracepoint 简介

大家好，[Tracepoint](https://www.kernel.org/doc/html/latest/core-api/tracepoint.html) 是一种很重要的内核特性，很多地方看到可能叫 Trace events。

首先，相比于基于硬件 breakpoint 的 kprobes/eBPF，它是一种 software probe 机制，前者几乎可以 probe 任意代码行，非常灵活，而 tracepoints 则是 “写死” 在内核中的，提前插入到了内核中某些函数的特定位置，但是即使有 eBPF 这样的新前端出现，前者还是不如 Tracepoints 易用，后者只要 `echo`, `cat` 这样的命令就可以用起来。

另外，相比于 Ftrace function tracer，它则能深入到函数内部，方便嗅探内部的特定状态，更为灵活。

## Tracepoint 性能问题

早期的 Tracepoints 有类似这样的实现：

    static inline trace_foo(args)
    {
        if (unlikely(trace_foo_enabled))
            goto do_trace_foo;
        return;
    do_trace_foo:
        /* Actually do tracing stuff */
    }

在用户态可以通过接口设定 `trace_foo_enabled`，从而方便启停某个 Tracepoint，但是即使是停止以后，还是会有访存+条件跳转指令。

虽然 Gcc 会对 `unlikely` 做一定的优化，但是随着 Tracepoints 越加越多，这个条件跳转带来的性能影响会越来越突出。

## Jump Label 如何优化

Tracepoints 的性能问题引起了大家的注意，[jump_label](https://lwn.net/Articles/412072/) 应运而生。

Jump Label 把上述函数替换为类似下面的机制：

    #define JUMP_LABEL(foo)                \
        if (unlikely(*foo))                \
            goto label(foo);        /* do_trace_foo */

那 `trace_foo` 可以定义为：`JUMP_LABEL(foo)`，如果只是这样，当然不够。

更进一步地，`unlikely()` 部分，这么改造一下：

    #define unlikely(foo) {      \
    addr(foo): asm("nop")        \
        return false;            \
    label(foo):                  \
        return true;             \
    }

    static inline trace_foo(args) {         \
        if (unlikely(*foo)) {               \
            /* Actually do tracing stuff */ \
        }                                   \
    }

它把 `addr(foo)` 记录下来，记录到一张表格中。

然后，如果把 `addr(foo)` 替换为 `nop` 指令，什么也不做，反之，替换为 `goto label(foo)`。

这样就不需要运行时访存+条件分支了，而只需要一条 `nop` 或者一条无条件跳转。

## 三种指令的性能比较

兴趣小组的 @hev 实测下来，无条件跳转（`goto label(foo)`）在两款国产非 RISC-V 处理器上的开销大概是 `nop` 的 2 倍左右，开销很小：

 Time Cost   | MIPS64 | AARCH64 ARMv8   | RISC-V
-------------|--------|-----------------|---------------
 nop         | 4.35s  | 5.40s           | TBD
 ubranch     | 8.71s  | 7.72s           | TBD
 branch      | TBD    | TBD             | TBD

说明：

* 表格中：ubranch = unconditional branch, branch = conditional branch
* 测试程序为：在一个大循环中，nop 所在行用 `nop` 指令，ubranch 所在行用 `goto label(foo)` 这种方式

例如：

    // ubranch
    1:
        b 2f
    2:

    // nop
    1:
        nop
    2:

而 **访存+条件分支** 涉及 Cache Miss 和 Branch Miss，最坏情况就影响比较大了。

**TODO**：欢迎大家实测一下 RISC-V 处理器上的情况。

## Jump Label 实现思路

接下来简单讨论一下 Jump Label 的实现思路。

首先就是设计一张表格，把所有 tracing points 的关键信息记录下来，主要有：

* `foo`：tracing point name 或其唯一对应的信息
* `addr(foo)`：tracing point 动态使能的关键地址，需要写入 `nop` 或者 `goto label(foo)`，需要通过 `foo` 从表中找出来
* `label(foo)`：`goto label(foo)` 编码时需要用到

那后面就牵涉到这么几个部分：

1. 如何实现 `unlikely(foo)`
2. 如何编码 `nop` 和 `goto label(foo)` 指令
3. 如何在运行时交换 `nop` 和 `goto label(foo)` 指令

上述工作都是跟架构强相关的，所以后面需要结合 RISC-V ISA 来分析源代码，且听下回分解。

## 参考资料

* [Jump Label](https://lwn.net/Articles/412072/)
* [Tracepoint](https://www.kernel.org/doc/html/latest/core-api/tracepoint.html)
