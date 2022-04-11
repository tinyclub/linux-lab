---
layout: post
author: 'Wu Zhangjin'
title: "RISC-V Linux jump_label 详解，第 1 部分：技术背景"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /riscv-jump-label-part1/
description: "本文是对 RISC-V jump_label 架构支持分析成果的第 1 部分，主要介绍 Jump Label 的相关技术背景，接下来会陆续展开介绍其实现细节。"
category:
  - 开源项目
  - Risc-V
  - Tracepoint
tags:
  - Linux
  - RISC-V
  - Jump Label
  - 条件分支
  - 无条件跳转
  - NOP
  - ISA
  - 指令编码
---

> Author:  Wu Zhangjin <falcon@tinylab.org>
> Date:    2022/03/19
> Project: [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux)

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

在用户态可以通过接口设定 `trace_foo_enabled`，从而方便启停某个 Tracepoint，但是即使是停止以后，还是会有访存+条件跳转指令，这部分是我们最关心的，也就是禁用 Tracepoints 的情况下开销要尽可能地小。

虽然 Gcc 会对 `unlikely` 做一定的代码执行顺序的优化，但是随着 Tracepoints 越加越多，这个 **访存+条件跳转** 带来的性能影响会越来越突出。

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

要达到这种效果，当然还是需要编译器配合把代码顺序优化好，尽量把 `original code` 顺序执行，而 `tracing code` 用无条件跳转来做，这样在禁用 tracing 的情况下，就只多出来一条 `nop` 指令。

原始代码示意：

    kernel_func() {
        original_code_part1()

        trace_foo(args)

        original_code_part2()

        return
    }

编译后效果示意：

    kernel_func() {
        original_code_part1()

    addr(foo): nop             // disabled: nop; enabled: goto label(foo)
    2:
        original_code_part2()
        return

    label(foo):
        trace_foo_code(args)   // 实际上可能没这么简单，args 可能跟代码执行顺序相关
        goto 2
    }

考虑到必须保留 Gcc 的 `unlikely` 实现，这里改造为：

    #define static_branch(foo) { \
    addr(foo): asm("nop")        \
        return false;            \
    label(foo):                  \
        return true;             \
    }

    static inline trace_foo(args) {             \
        if (unlikely(static_branch(*foo))) {    \
            /* Actually do tracing stuff */     \
        }                                       \
    }

## 不同指令的性能比较

兴趣小组的 @hev 和 @dlan17 实测下来，无条件跳转（`goto label(foo)`）在两款国产非 RISC-V 处理器上的开销大概是 `nop` 的 2 倍左右，开销很小：

 Time Cost             | MIPS64 | AARCH64 ARMv8   | RISC-V
-----------------------|--------|-----------------|---------------
 nop                   | 4.35s  | 5.30s           | 5.03s
 ubranch               | 8.71s  | 7.6s            | 5.05s
 branch in bnez        | 8.71s  | 7.6s            | 7.54s
 branch in beqz        | 12.3s  | 4.6s            | 7.54s
 load+branch           | 8.7s   | 7.6s            | 5.87s
 load+branch+cache miss| 25.2s  | TBD             | 28.3s

说明：

* ubranch = unconditional branch, branch = conditional branch
* load 测试引入了全局变量控制
* cache miss 测试引入了多核交互 + false sharing

而 **访存+条件分支** 的 Worse Case 情况涉及 Cache Miss 和 Branch Miss，从初步的测试数据来看，最坏情况影响比较大了。

而优化后，变成了更为确定的 `nop` 和 `goto label(foo)`，虽然在个别平台上，`branch in beqz` 这种 Case 比 `ubranch` 表现要好，但是跟 `nop` 也是相当的。

也就是说，在优化过后，禁用 Tracepoint 之后的开销只增加了一个 `nop`，而之前如果存在 Cache Miss，可能要 5-6 倍开销，不存在 Cache Miss 时，要 1-3 倍开销，所以优化效果还是很明显的。

并且当前测试的 ubranch 和 branch 都是极短跳转，比实际情况短得多，不排除会被处理器做特殊优化，所以测试结果跟实际情况可能会有一定差异，也就是说即使不存在 Cache Miss 时，原来可能也不止 1-3 倍开销。

**TODO**: 欢迎从事处理器设计的同学对这部分进行补充。

## Jump Label 实现思路

接下来简单讨论一下 Jump Label 的实现思路。

首先就是设计一张表格，把所有 tracing points 的关键信息记录下来，主要有：

* `foo`：tracing point name 或其唯一对应的信息
* `addr(foo)`：tracing point 动态使能的关键地址，需要写入 `nop` 或者 `goto label(foo)`，需要通过 `foo` 从表中找出来
* `label(foo)`：`goto label(foo)` 编码时需要用到

那后面就牵涉到这么几个部分：

1. 如何实现 `static_branch(foo)`
2. 如何编码 `nop` 和 `goto label(foo)` 指令
3. 如何在运行时交换 `nop` 和 `goto label(foo)` 指令

上述工作都是跟架构强相关的，所以后面需要结合 RISC-V ISA 来分析源代码，且听下回分解。

## 参考资料

* [Jump Label](https://lwn.net/Articles/412072/)
* [Tracepoint](https://www.kernel.org/doc/html/latest/core-api/tracepoint.html)
