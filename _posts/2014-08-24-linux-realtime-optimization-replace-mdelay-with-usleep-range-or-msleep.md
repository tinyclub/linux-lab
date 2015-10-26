---
title: Linux 实时优化：批量优化 mdelay
author: Wu Zhangjin
layout: post
permalink: /linux-realtime-optimization-replace-mdelay-with-usleep-range-or-msleep/
tags:
  - alarm
  - Linux
  - mdelay
  - msleep
  - timer
  - usleep_range
  - workqueue
  - 实时优化
categories:
  - 实时性
---
  * 问题描述

    根据 [Linux时钟API使用详解：事关实时响应、功耗与调试][1]，如果想批量找到内核中的 mdelay() 调用，并根据实际情况优化为 usleep_range()或者msleep()等，该如何？

  * 问题分析

    首先需要确认哪些代码是我们用到的，接着就是找出这些代码中的 mdelay() 调用，最后就是作针对性的优化。

  * 解决方案

    下面这个就可以找出所有用到的mdelay，进入到使用的Linux内核源代码目录下执行即可：

        $ find ./ -name "*.o" | sed -e "s/.o$/.c/g" | xargs -i grep -uil mdelay {} 2>/dev/null


    之后就是根据 [Linux时钟API使用详解：事关实时响应、功耗与调试][1] 的原理进行优化：

      * 原子上下文或者某些特定场景的mdelay()保留，如果太大，考虑是否可以更小，或者把部分操作延迟到workqueue执行
      * 非原子上下文，把 > 100ms, < 20ms 的替换为 usleep\_range()，记得加一个范围，比如原来是mdelay(5)，并且这个delay可以更长，比如6ms，则可以优化为usleep\_range(5000,6000)。
      * 非原子上下文，把 > 20ms 的替换为 msleep()。
      * 如果超过1s，请用delayed workqueue或者timer，抑或是确实需要是才用alarm




 [1]: /the-usage-of-linux-time-api/
