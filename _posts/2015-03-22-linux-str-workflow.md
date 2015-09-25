---
title: 以龙芯 3A 为例图解 Linux 休眠唤醒流程
author: Tao HongLiang
layout: post
permalink: /linux-str-workflow/
tags:
  - 3A
  - 龙芯
  - kernel
  - Linux
  - Resume
  - str
  - Suspend
  - 快速恢复
  - 一图流
  - 休眠
categories:
  - Linux
  - Power Management
---

<!-- title: 图解 Linux STR 流程 -->

<!-- %s/!\[image\](/&\/wp-content\/uploads\/2015\/03\// -->

> by Tao HongLiang of [TinyLab.org][1]
> 2015/3/22


## 前言

STR，全名 Suspend To Ram，中文名休眠。是一种集省电，快速恢复等优点于一体的电源管理技术。当你把笔记本盒盖再打开，或是按下手机电源键关屏又再次点亮。就是 STR 完成它的职责之时。本文通过一张图描绘出 Linux STR 全貌，让你不再只是管中窥豹。

## 流程图

![流程图][2]

(笔者是在 Loongson-3A 平台上完成的实验，其他平台流程大同小异)

## 看图说话

### 整体框架

从图中可以清晰的看到，有一个结构体贯穿始终：suspend_ops，这就是我们该做的。我们需要根据自己硬件平台的特点实现这个结构体。

<pre>struct   {
    int (*valid)(suspend_state_t state);
    int (*begin)(suspend_state_t state);
    int (*prepare)(void);
    int (*prepare_late)(void);
    int (*enter)(suspend_state_t state);
    void (*wake)(void);
    void (*finish)(void);
    bool (*suspend_again)(void);
    void (*end)(void);
    void (*recover)(void);
}
</pre>

Loongson-3A 相关实现请参考：[arch/mips/loongson/common/pm.c][3]

### Suspend 前要做的事

  1. 保存 CPU 所有通用寄存器，协处理器寄存器的值到内存中
  2. 保存 Resume 时，程序需要跳转到哪个地址去执行的指针
  3. Flush cache L1, L2 …
  4. 调用或者跳转到 BIOS 中，设置内存控制器，令其进入 Self Refresh 模式(省电，并保持内存中的数据)
  5. 设置硬件，进入 S3 状态

### Resume 后要做的事

  1. 在 BIOS 将要 Resume 前 Flush TLB，否则如果错误的 TLB 被命中，你会惨死在 Resume 的路上
  2. BIOS 判断是开机，还是从 S3 恢复。如果是正常开机，就继续 BIOS 后续流程，如果是 S3，则直接跳转到之前保持的 wakeup start 地方执行
  3. 进入内核后，恢复协处理器寄存器，和通用寄存器的内容
  4. 大功告成，可以跳转到 RA 继续完成剩下的工作

【编者注：该文介绍的内容基于[龙芯][4]多核处理器：[Loongson-3A][5]，该处理器兼容 MIPS 指令集，提到的 PMON 是 Bootloader，RA 是返回地址，即跳转前存放的下一条指令的地址。需要提到的是，Loongson-3A 的 Linux 支持经过 [Lemote][6] 员工的长久努力，目前也跟 Loongson-2E/2F 一样，已经进入到了 Linux 官方，ARCH 相关代码路径：arch/mips/loongson】





 [1]: http://tinylab.org
 [2]: /wp-content/uploads/2015/03/linux_str.jpg
 [3]: https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/arch/mips/loongson/common/pm.c
 [4]: http://www.loongson.cn/
 [5]: http://www.loongson.cn/product_info.php?id=31
 [6]: http://www.lemote.com/
