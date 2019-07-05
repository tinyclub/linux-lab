---
layout: post
author: 'Wu Zhangjin'
title: "如何创建一个可启动光盘（ISO文件）"
draft: true
license: "cc-by-sa-4.0"
permalink: /create-iso-for-i386-pc-board/
description: "本文介绍如何使用 mkisofs 制作一个可以通过 qemu-system-x86 启动的光盘，用于启动的 Linux 内核和文件系统源自 Linux Lab 的板级支持包 qemu-i386-pc。"
category:
  - 制作 Linux 启动盘
tags:
  - syslinux
  - isolinux
  - mkisolinux
  - Linux Lab
  - pc
  - iso 制作
---

> By Falcon of [TinyLab.org][1]
> Jul 06, 2019

## 简介

有同学问到如何把 Linux 系统制作成可启动的光盘（ISO文件），刚好笔者早期在研究 RTOS 时制作过一个开发环境，里头用到 mkisofs 制作光盘。

翻了下之前做实验的资料，参考后，把 [Linux Lab](/linux-lab) 的板级支持包 [qemu-i386-pc](https://gitee.com/tinylab/qemu-i386-pc) 中预先编译的内核和文件系统直接制作成了可引导的光盘，这里分享下制作过程。

## 准备工作

### 安装 syslinux, genisoimage, qemu-system-x86

  syslinux 中包含了 i386/pc 的 bootloader: isolinux，而 genisoimage 提供了制作 ISO 的 mkisofs 工具，qemu-system-x86 提供模拟器，用于验证 iso 能否正常启动。

    $ sudo apt-get install syslinux genisoimage qemu-system-x86

### 下载 i386/pc bsp

    $ git clone https://gitee.com/tinylab/qemu-i386-pc.git i386-pc-bsp

### 创建目录架构并拷贝文件

    $ mkdir -p i386-pc-iso/{boot,isolinux}
    $ mkdir -p i386-pc-iso/boot/{v2.6,v4.6,v5.1}

    $ cp /usr/lib/syslinux/{isolinux.bin,vesamenu.c32} i386-pc-iso/isolinux/

    $ cp i386-pc-bsp/kernel/v5.1/bzImage i386-pc-iso/boot/v5.1/
    $ cp i386-pc-bsp/kernel/v4.6.7/bzImage i386-pc-iso/boot/v4.6/
    $ cp i386-pc-bsp/kernel/v2.6.36/bzImage i386-pc-iso/boot/v2.6/
    $ cp i386-pc-bsp/root/2019.02.2/rootfs.cpio.gz i386-pc-iso/boot/initrd.img

### 添加配置文件

    $ vim i386-pc-iso/isolinux/isolinux.cfg
    DEFAULT vesamenu.c32
    TIMEOUT 600

    MENU clear
    MENU title Linux Lab
    MENU vshift 8
    MENU rows 18
    MENU margin 8
    MENU helpmsgrow 15
    MENU tabmsgrow 13

    MENU tabmsg Press Tab for full configuration options on menu items.

    LABEL linux v2.6.36
      KERNEL /boot/v2.6/bzImage
      INITRD /boot/initrd.img
      APPEND rw root=/dev/ram0

    LABEL linux v4.6.7
      KERNEL /boot/v4.6/bzImage
      INITRD /boot/initrd.img
      APPEND rw root=/dev/ram0

    LABEL linux v5.1
      KERNEL /boot/v5.1/bzImage
      INITRD /boot/initrd.img
      APPEND rw root=/dev/ram0

## 创建可启动的光盘（ISO）文件

    $ mkisofs -o i386-pc.iso -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table i386-pc-iso/

## 通过 Qemu 验证

    $ qemu-system-i386 -boot d -cdrom i386-pc.iso

## 启动界面截图

![i386 pc boot menu](/wp-content/uploads/2019/07/i386-pc-iso-boot-screenshot.jpg)

相关成果，包括制作好的 iso 文件，都已经上传到了 [I386 PC ISO](https://gitee.com/tinylab/i386-pc-iso.git)。

[1]: http://tinylab.org
