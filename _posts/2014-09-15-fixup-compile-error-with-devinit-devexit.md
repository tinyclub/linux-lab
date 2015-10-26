---
title: 移植 Linux 3.4 到 3.10:__devinit,__devexit 引起的编译失败
author: Wen Pingbo
layout: post
permalink: /fixup-compile-error-with-devinit-devexit/
tags:
  - 3.8
  - 编译失败
  - kernel
  - Linux
  - macro
  - __devexit
  - __devinit
categories:
  - 移植 Linux 内核
---
  * 问题描述

    当我们移植一些老驱动到 3.8 以上 Linux 内核时，有可能会碰到如下错误：

        xxxx.c:(.text+0x0): undefined reference to `function name'


  * 问题分析

    如果报错的函数前有 `__devinit` 或者 `__devexit` 等宏，那么罪魁祸首的就是这个了。因为这些宏在 Linux Kernel 3.8 之后，就已经移除了。

    在 Linux Kernel 3.4 之前，这些宏是存在的。比如：

        static int __devinit xxxx_init(void);
        static void __devexit xxxx_exit(void);

        .exit = __devexit_p(xxxx_exit)


    这些宏其实和 `__init` 和 `__exit` 宏类似，都是把被声明的函数放到特定的段中。具体的声明，都在 `include/linux/init.h` 文件中。`__init` 和 `__exit` 会分别把函数放到 `.init.text` 和 `.exit.text`。在 Kernel 完成初始化后，这些段就会被释放掉，来节约内存。`__devinit` 和 `__devexit` 宏的引入是为了支持一些设备的 HOTPLUG 特性。把这些函数放到特定的段中，这样可以在一些特定的条件下，把这些段释放掉。这里的 `__devexit_p` 宏是为了防止被 `__devexit` 宏声明的函数释放后，对其的引用。

  * 解决办法

    上面介绍的 __dev系列的宏，都在 [Linux Kernel 3.8][1] 中移除了。所以在移植一些老驱动到 Linux Kernel 3.8 以上版本的内核中，会碰到编译错误。这个时候，只需把这些宏删掉就可以了，不影响驱动的正常运行。

    更多从 Android Linux 3.4 到 3.10 移植驱动时需要注意的事项请参考： [Kernel 3.4 to 3.10 porting guide][2]。




 [1]: https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=54b956b903607
 [2]: http://elinux.org/Kernel_3.4_to_3.10_porting_guide
