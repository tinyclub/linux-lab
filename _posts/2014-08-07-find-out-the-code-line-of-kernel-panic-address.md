---
title: 如何快速定位 Linux Panic 出错的代码行
author: Wu Zhangjin
layout: post
permalink: /find-out-the-code-line-of-kernel-panic-address/
tags:
  - Backtrace
  - gdb
  - objdump
  - Panic
categories:
  - 内核调试与跟踪
  - 调试技巧
  - objdump
  - addr2line
  - 稳定性
---
* 问题描述

  内核调试中最常见的一个问题是：内核Panic后，如何快速定位到出错的代码行？

  就是这样一个常见的问题，面试过的大部分同学都未能很好地回答，这里希望能够做很彻底地解答。

* 问题分析

  内核Panic时，一般会打印回调，并打印出当前出错的地址：

  kernel/panic.c:panic():

      #ifdef CONFIG_DEBUG_BUGVERBOSE
        /*
         * Avoid nested stack-dumping if a panic occurs during oops processing
         */
        if (!test_taint(TAINT_DIE) && oops_in_progress <= 1)
            dump_stack();
      #endif


  而`dump_stack()`调用关系如下：

      dump_stack() --> __dump_stack() --> show_stack() --> dump_backtrace()


  `dump_backtrace()`会打印整个回调，例如：

      [<001360ac>] (unwind_backtrace+0x0/0xf8) from [<00147b7c>] (warn_slowpath_common+0x50/0x60)
      [<00147b7c>] (warn_slowpath_common+0x50/0x60) from [<00147c40>] (warn_slowpath_null+0x1c/0x24)
      [<00147c40>] (warn_slowpath_null+0x1c/0x24) from [<0014de44>] (local_bh_enable_ip+0xa0/0xac)
      [<0014de44>] (local_bh_enable_ip+0xa0/0xac) from [<0019594c>] (bdi_register+0xec/0x150)


  通常，上面的回调会打印出出错的地址。

* 解决方案

  通过分析，要快速定位出错的代码行，其实就是快速查找到出错的地址对应的代码？

    * 情况一

      在代码编译连接时，每个函数都有起始地址和长度，这个地址是程序运行时的地址，而函数内部，每条指令相对于函数开始地址会有偏移。那么有了地址以后，就可以定位到该地址落在哪个函数的区间内，然后找到该函数，进而通过计算偏移，定位到代码行。

    * 情况二

      但是，如果拿到的日志文件所在的系统版本跟当前的代码版本不一致，那么编译后的地址就会有差异。那么简单地直接通过地址就可能找不到原来的位置，这个就可能需要回调里头的函数名信息。先通过函数名定位到所在函数，然后通过偏移定位到代码行。

  相应的工具有addr2line, gdb, objdump等，这几个工具在[How to read a Linux kernel panic?][1]都有介绍，我们将针对上面的实例做更具体的分析。

  需要提到的是，代码的实际运行是不需要符号的，只需要地址就行。所以如果要调试代码，必须确保调试符号已经编译到内核中，不然，回调里头打印的是一堆地址，根本看不到符号，那么对于上面提到的情况二而言，将无法准确定位问题。

  如果要获取到足够多的调试信息，请根据需要打开如下选项：

      CONFIG_KALLSYMS=y
      CONFIG_KALLSYMS_ALL=y
      CONFIG_DEBUG_BUGVERBOSE=y
      CONFIG_STACKTRACE=y


  下面分别介绍各种用法。

    * addr2line

      如果出错的内核跟当前需要调试的内核一致，而且编译器等都一致，那么可以通过addr2line直接获取到出错的代码行，假设出错地址为0019594c：

          $ addr2line -e vmlinux_with_debug_info 0x0019594c
          mm/backing-dev.c:335


      然后用vim就可以直接找到代码出错的位置：

          $ vim mm/backing-dev.c +335


      如果是情况二，可以先通过nm获取到当前的vmlinux中`bdi_register`函数的真实位置。

          $ nm vmlinux | grep bdi_register
          0x00195860 T bdi_register


      然后，加上0xec的偏移，即可算出真实地址：

          $ echo "obase=16;ibase=10;$((0x00195860+0xec))" | bc -l
          19594C


    * gdb

      这个也适用情况二，因为可以直接用 符号+偏移 的方式，因此，即使其他地方有改动，这个相对的位置是不变的。

          $ gdb vmlinux_with_debug_info
          $ list *(bdi_register+0xec)
          0x0019594c is in bdi_register (/path/to/mm/backing-dev.c:335).
          330     bdi->dev = dev;
          331
          332     bdi_debug_register(bdi, dev_name(dev));
          333     set_bit(BDI_registered, &#038;bdi->state);
          334
          335     spin_lock_bh(&#038;bdi_lock);
          336     list_add_tail_rcu(&#038;bdi->bdi_list, &#038;bdi_list);
          337     spin_unlock_bh(&#038;bdi_lock);
          338
          339     trace_writeback_bdi_register(bdi);


      如果是情况一，则可以直接用地址：`list *0x0019594c`。

    * objdump

      如果是情况一，直接用地址dump出来。咱们回头看一下Backtrace信息：`bdi_register+0xec/0x150`，这里的0xec是偏移，而0x150是该函数的大小。用objdump默认可以获取整个vmlinux的代码，但是咱们其实只获取一部分，这个可以通过`--start-address`和`--stop-address`来指定。另外`-d`可以汇编代码，`-S`则可以并入源代码。

          $ objdump -dS vmlinux_with_debug_info --start-address=0x0019594c --end-address=$((0x0019594c+0x150))


      如果是情况二，也可以跟addr2line一样先算出真实地址，然后再通过上面的方法导出。

  总地来看，gdb还是来得简单方便，无论是情况下和情况二都适用，而且很快捷地就显示出了出错的代码位置，并且能够显示代码的内容。

  对于用户态来说，分析的方式类似。如果要在应用中获取Backtrace，可以参考[Generating backtraces][2]。其例子如下：

      #include <execinfo.h>
      #define BACKTRACE_SIZ 64
      
      void show_backtrace (void)
      {
            void    *array[BACKTRACE_SIZ];
            size_t   size, i;
            char   **strings;
      
            size = backtrace(array, BACKTRACE_SIZ);
            strings = backtrace_symbols(array, size);
      
            for (i = 0; i < size; i++) {
                printf("%p : %s\n", array[i], strings[i]);
            }
      
            free(strings);  // malloced by backtrace_symbols
      }


  编译代码时需要加上：`-funwind-tables`，`-g`和`-rdynamic`。




 [1]: http://stackoverflow.com/questions/13468286/how-to-read-a-linux-kernel-panic
 [2]: http://www.stlinux.com/devel/debug/backtrace
