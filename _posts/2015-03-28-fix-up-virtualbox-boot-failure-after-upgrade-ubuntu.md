---
title: 升级 Ubuntu 后 VirtualBox 因驱动失效无法启动
author: Wu Zhangjin
layout: post
permalink: /faqs/fix-up-virtualbox-boot-failure-after-upgrade-ubuntu/
tags:
  - DKMS
  - linux-headers
  - Ubuntu
  - VirtualBox
categories:
  - Linux
---
  * 问题描述

    本来已经安装好的 VirtualBox，在升级完 Ubuntu 后，发现原来安装好的映像文件无法加载了，查看错误发现是驱动没有安装：

    > Kernel driver not installed (rc=-1908)
    >
    > The VirtualBox Linux kernel driver (vboxdrv) is either not loaded or there is a permission problem with /dev/vboxdrv. Please reinstall the kernel module by executing
    >
    > &#8216;/etc/init.d/vboxdrv setup&#8217;
    >
    > as root. If it is available in your distribution, you should install the DKMS package first. This package keeps track of Linux kernel changes and recompiles the vboxdrv kernel module if necessary.

  * 问题分析

    从上面的信息一眼就可以看出是驱动没有安装，那问题的原因自然是升级以后驱动有问题。

    根据之前的经验，第一反应是重新安装 VirtualBox 相关的包，但是重装以后发现没用，细看以后模块还是不在。分析了一下，发现升级 Ubuntu 后，内核版本也升级了，那是不是 VirtualBox 的 dkms 内核模块未能随着内核版本正确编译呢？

    仔细一看，发现连内核的头文件都没有安装，所以……

  * 解决方案

    Ok，开始安装：



        $ sudo apt-get install linux-headers-`uname -r`
        $ sudo apt-get install virtualbox-guest-dkms virtualbox virtualbox-dkms --reinstall --purge
        $ sudo insmod /lib/modules/`uname -r`/updates/dkms/vboxguest.ko


    重启 Virtualbox，一切搞定！



