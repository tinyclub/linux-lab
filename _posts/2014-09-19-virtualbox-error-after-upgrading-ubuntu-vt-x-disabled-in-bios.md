---
title: 升级 Ubuntu 后 VirtualBox 报错
tagline: VT-x is disabled in the BIOS
author: 泰晓科技
layout: post
permalink: /faqs/virtualbox-error-after-upgrading-ubuntu-vt-x-disabled-in-bios/
tags:
  - 14.04
  - BIOS
  - 虚拟机
  - Intel Virtulization Technology
  - Ubuntu
  - VirtualBox
  - VT-x
categories:
  - Ubuntu
---
  * 问题描述

    升级 Ubuntu 到 14.04 后，发现 VirtualBox 无法启动，并报告：

        VT-x is disabled in the BIOS


  * 问题分析

    通过查找资料，发现 `VT-x`：

    > Intel VT-x (Intel Virtualization Technology for IA-32 and Intel 64 Processors) Intel VT-x (previously known as Intel VT) is the implementation of an Intel Secure Virtual Machine for the x86 IA-32 and Intel 64 architectures.

    那，既然 Disable 了，可能就是 BIOS 惹的祸。

  * 解决方案

      * 重启系统
      * 长按 `DEL` 进入 BIOS
      * 方向键切到 BIOS Features
      * 选中如下选项

    > Intel Virtualization Technology

      * 选择 Enable
      * 按下 `F10` 保存并重启

    重启后，VirtualBox 就可以正常启动之前安装的系统了。



