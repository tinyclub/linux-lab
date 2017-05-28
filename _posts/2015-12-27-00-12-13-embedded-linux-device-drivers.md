---
layout: post
author: 'Wu Zhangjin'
title: "嵌入式 Linux 设备驱动"
album: "嵌入式 Linux 知识库"
group: translation
permalink: /embedded-linux-device-drivers/
description: "本文介绍了嵌入式 Linux 设备驱动开发相关的书籍、教程和样例驱动。"
category:
  - 设备驱动
tags:
  - LDT
  - Linux
  - 驱动模板
  - LDD3
  - 虚拟设备驱动
  - V4L2
  - USB
  - 帧缓冲设
  - GPIO
  - 设备树
---

> 书籍：[嵌入式 Linux 知识库](https://gitbook.com/book/tinylab/elinux)
> 原文：[eLinux.org](http://eLinux.org/Device_drivers "http://eLinux.org/Device_drivers")
> 翻译：[@lzufalcon](https://github.com/lzufalcon)

## 使用手册

-   [Linux 内核内部参考手册，维基书](http://en.wikibooks.org/wiki/The_Linux_Kernel) - 正在建设中
-   [Linux 设备驱动，第 3 版](http://www.makelinux.net/ldd3/)
-   [写并口驱动的教程](http://www.makelinux.net/reference.d/drivers_linux)

## 样例驱动

-   [LDT - Linux 驱动模板](https://github.com/makelinux/ldt/) - Linux 设备驱动样例模板，用于学习和开始编写一个自定义驱动程序。举了 UART 字符设备驱动的例子，用到了下述 Linux 设施：模块，平台驱动，文件操作（读/写、内存映射、ioctl、阻塞/非阻塞模式、轮询），kfifo, completion, interrupt, tasklet, work, kthread, timer, misc device, proc fs, UART 0x3f8, HW loopbakc, SW loopback, ftracer。代码可以工作并且用测试脚本运行过。

-   [LDD3 - 更新过的第三版《Linux 设备驱动》样例](https://github.com/martinezjavier/ldd3/)，可以用 3.2.0 内核编译
    -   [pci_skel.c](https://github.com/martinezjavier/ldd3/blob/master/pci/pci_skel.c)
        - PCI 梗概
    -   [sbull.c](https://github.com/martinezjavier/ldd3/blob/master/sbull/sbull.c)
        - 简单的块设备
    -   [scull](https://github.com/martinezjavier/ldd3/tree/master/scull)
        - 简单的字符设备
    -   [snull.c](https://github.com/martinezjavier/ldd3/blob/master/snull/snull.c)
        - 简单的网络设备
-   [vivi.c - 虚拟设备驱动，使用 V4L2](http://lxr.free-electrons.com/source/drivers/media/video/vivi.c) （可以工作）
-   [mem2mem_testdev.c - 虚拟的 v4l2-mem2mem 样例设备驱动程序](http://lxr.free-electrons.com/source/drivers/media/video/mem2mem_testdev.c)
-   [usb-skeleton.c - USB 驱动梗概](http://lxr.free-electrons.com/source/drivers/usb/usb-skeleton.c)（经过少许修改后可以编译）
-   [skeletonfb.c - 帧缓冲设备梗概](http://lxr.free-electrons.com/source/drivers/video/skeletonfb.c)（无法编译。。。）
-   [pcihp_skeleton.c - PCI 热插拔控制器基本驱动程序](http://lxr.free-electrons.com/source/drivers/pci/hotplug/pcihp_skeleton.c)
-   [loopback.c - 一份简单的 `net_device`，实现了`ifconfig lo`](http://lxr.free-electrons.com/source/drivers/net/loopback.c)
-   [gpio_driver - 一个为树莓派 B+ 编写的 GPIO 驱动](https://github.com/23ars/linux_gpio_driver)（未经完整测试验证）

## 资源

-   [设备树](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Device_Tree/Device_Tree.html "Device Tree") - 关于设备树的信息（越来越多地为新的嵌入式驱动程序所需要！）
