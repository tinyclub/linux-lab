---
title: 通过网络使用 ADB
author: Hu Hongbing
layout: post
permalink: /faqs/use-adb-via-network/
views:
  - 66
tags:
  - ADB
  - 网络
  - 开发小工具
categories:
  - Android
---
* 问题描述

  使用adb调试时，我们一般是通过USB来连接手机和个人电脑。如果需要adb调试USB设备怎么办呢？

* 问题分析

  adb提供了通过网络传输让手机和个人电脑进行交互的能力。

* 解决方法

  直接使用adb的网络工作模式。

  其使用步骤如下，以下命令都在host上运行。

  * 先插入USB，并打开手机端的 USB调试 模式，确保adb命令可以执行

  * 通知手机`adbd`，切换通信方式为网络

    这里设置端口为5555：

        $ adb tcpip 5555

  * 让个人电脑上的`adb server`通过网络连接手机adbd

    需要指定地址和端口。地址可以通过`adb shell netcfg获取`，例如：

        $ adb shell netcfg
        ip6tnl0  DOWN                                   0.0.0.0/0   0x00000080 00:00:00:00:00:00
        rmnet0   DOWN                            10.213.228.170/32  0x00000090 00:00:00:00:00:00
        p2p0     UP                                     0.0.0.0/0   0x00001003 3a:bc:1a:f7:2a:9f
        sit0     DOWN                                   0.0.0.0/0   0x00000080 00:00:00:00:00:00
        lo       UP                                   127.0.0.1/8   0x00000049 00:00:00:00:00:00
        wlan0    UP                               192.168.2.100/24  0x00001043 38:bc:1a:f7:2a:9f

    这里2G/3G网络rmnet0和wifi网络wlan0都开启了，不过因为rmnet0是在局域网里头，无法访问，另外，也需要确保电脑接入了Wifi地址所处的网络，否则也将无法访问。

    这样我们可以直接连接 地址：端口，即192.168.2.100:5555。

        $ adb connect 192.168.2.100:5555

    完工后，现在可以拔掉USB线。通过网络，让手机与个人电脑交互。

  * 如果要切换回USB模式呢？

        $ adb usb
