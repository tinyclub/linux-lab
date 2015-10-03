---
title: KDBUS 合入 Linux Kernel：激烈论战，目前暂歇
author: Chen Jie
layout: post
group: news
permalink: /kdbus-in-linux-kernel-the-debate-the-current-respite/
tags:
  - Binder
  - DBus
  - IPC
  - KDBUS
  - Plumber
  - SIMPL
categories:
  - 进程通信
---

<!-- title: KDBUS 合入 Linux Kernel：激烈论战，目前暂息 -->

<!-- %s/!\[image\](/&#038;\/wp-content\/uploads\/2015\/05\// -->

> by Chen Jie of [TinyLab.org][1]
> 2015/5/16

(消息来源: [phoronix.com][2]) 随着 Linux Kernel 4.1 合并窗口的关闭，KDBUS 此番未能合并入主线，不过其论战依旧激烈，直至最近渐歇。

本期来来去去的邮件[在此][3]，正方的意见似乎有这些呢：

  1. KDBUS 能用上内核安全机制（aka LSM、SELinux）
  2. KDBUS 能避免一些临界状况
  3. KDBUS 实现效率更高

而反方的意见看起来有：

  1. 能不能在已有 IPC 上扩展，比如扩展 UNIX Domain + 多播功能？
  2. 到底哪些临界情况被避免了？？
  3. 效率更高？请说明用户态代码已经高度优化了，就差必要的内核优化了

KDBUS 是 Freedesktop DBus IPC 在内核的实现，一些有趣的信息摘录如下：

  * 13 年的 汽车 Linux 春季峰会（Automotive Linux Summit Spring）上，提到了[一些 Linux 下（高级）IPC 方案，及 KDBUS 意义][4]。
  * DBus 设计思路，及与 Binder 比较：[其一][5]、[其二][6] （呃，三星打算用 KDBUS 来实现 Binder 接口？）
  * 其他一些可考虑的 IPC：[Plumber][7]（贝尔实验室 Plan 9 系统上的 IPC）、[SIMPL][8]（QNX 消息 API 在 Linux 上的实现）





 [1]: http://tinylab.org
 [2]: http://www.phoronix.com/scan.php?page=news_item&px=KDBUS-Fizzled-May
 [3]: http://lkml.iu.edu/hypermail/linux/kernel/1504.3/index.html#03336
 [4]: https://lwn.net/Articles/551969/
 [5]: http://lkml.iu.edu/hypermail/linux/kernel/1505.0/00678.html
 [6]: http://lkml.iu.edu/hypermail/linux/kernel/1505.0/01551.html
 [7]: https://lists.debian.org/debian-user/2014/12/msg00802.html
 [8]: http://icanprogram.com/simpl/
