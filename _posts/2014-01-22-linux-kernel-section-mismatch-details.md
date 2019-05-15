---
title: Linux 内核 Section Mismatch 详解
author: Wu Zhangjin
album: "Debugging"
layout: post
permalink: /linux-kernel-section-mismatch-details/
tags:
  - CONFIG_DEBUG_SECTION_MISMATCH
  - Linux
  - Section Mismatch
categories:
  - 内核调试与跟踪
  - 稳定性
  - 调试技巧
---

> by falcon of [TinyLab.org][2]
> 2014/01/22


## Section Mismatch 简介

 Section Mismatch 是非常严重的 Bug ，可能会导致无法预测的内存访问问题，建议谨慎对待，如果添加的驱动中有类似 Warning ，可能需要密切关注并解决掉。

下面就该问题的检测、原因、解决思路以及最新前沿进行分析。

## Section Mismatch 的检测

`CONFIG_DEBUG_SECTION_MISMATCH=y`

打开上述选项，内核就会调用 `modpost` 检测类似问题。

## Section Mismatch 的原因

Linux 为了减少不必要的内存消耗，对于一些仅仅在内核初始化时使用的资源（包括函数和变量等），会放在 init sections 中，这些 init sections 会在内核初始化完成以后被内核 Free 掉。除此之外，考虑到不同模块或者子系统的差异，它们的代码和数据也会放在各自的 Section 中，交叉的引用也可能出现潜在的问题。

如果一个 Section 引用了另外一个 Section 中的变量，就会出现 Section Mismatch 警告。如果是一个运行时函数引用了一个 Init Section 段中的函数，那么问题就出现了。

当 Linux 内核启动完成后， Init Section 占用的内存已经被 Free 掉，如果这部分内存被其他的设备申请，写进了不可预知的内容，那么系统就会存在不可预知的风险，也许有些时候会很幸运，这部分内存从来都没有被其他设备引用，所以，即使编译时看到了 Warning ，系统也没有崩溃，但是炸弹放在枕头边，很危险，早点搬走为好。

## Section Mismatch 的解决

有几种情况：

* 如果运行时函数引用了 Init Section 中的函数或者变量

  如果该运行时函数是必须要在运行时用到的，不能放到 Init Section 中，那么就把 Init Section 中的函数的 `__init*` 标记去掉，否则给前者加上相应的 Init 声明。

  相关的init标记请参考：include/linux/init.h

* 如果不同的 Section 之间存在交叉引用，这个交叉引用是安全的，则用 `__ref` 标记让 Section Mismatch Detector(modpost) 忽略相关检查

比如在 cpu hotplug 中，`__cpuinit` 不会放在 Init section 中，在运行时访问是安全的，如果有一个外部函数（无 `__cpuinit` 标记）访问了用 `__cpuinit` 标记的函数，这个时候就存在交叉引用。因为这种访问是安全的，所以可以让内核忽略对它的检测，用 `__ref` 标记该函数即可。

## Section Mismatch 的近况

在最新的 ARM 内核中，引入了一个智能检测，该检测是针对 Free 掉的内存被运行时函数访问的情况，前面的分析提到类似的情况会导致无法预测的风险，而该智能检测则会明确地报告出具体的问题。

该检测的原理是把所有 Init Section 的内存区域在内核初始化时把这些内存区域初始化为 0xe7fddef0 (an undefined instruction (ARM) or a branch to an undefined instruction (Thumb)) ，如果运行时函数非法访问到了这些区域，会触发一个 undef instruction 的异常并打印相应的回调，从而辅助开发人员更快地解决相关问题。

当然，这并不意味着我们不需要解决编译时的 Warning ，把问题 Delay 到运行时解决是更耗费精力的，应该在编码或者编译等早期开发过程中就解决掉，这样会提高开发效率，这个思路对其他的问题同样适用。

这部分的代码请参考：`arch/arm/mm/init.c: poison_init_mem()`





 [2]: http://tinylab.org
