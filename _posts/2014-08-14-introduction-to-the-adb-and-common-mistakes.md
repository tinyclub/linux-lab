---
title: Android ADB 介绍及常见错误分析
author: Wen Pingbo
album: "Debugging"
layout: post
permalink: /introduction-to-the-adb-and-common-mistakes/
tags:
  - ADB
  - Android
  - 常见错误
categories:
  - ADB
---

> by WenPingbo of [TinyLab.org][1]
> 2014/08/14


## ADB简介

ADB(Android Debug Bridge) 是 Google 为了调试 Android 设备和 Android 模拟器实例而写的调试工具。整个 ADB 分为3个部分，ADB Server，ADB Client 和 ADB Daemon(adbd)。ADB Server 是在主机上运行的一个进程，用来处理 ADB Client 和 ADB Daemon 之间的通信。平常所用的 `adb kill-server` 就是 `kill` 这个进程。ADB Client 就是我们在终端里运行的程序，用于处理用户输入，并和 ADB Server 通信。通常 ADB Client 和 ADB Server 会编译到同一个可执行文件 `adb`，所以在运行 `adb` 命令时，会主动检测是否有 ADB Server 这个进程，如果没有，就会默认后台运行 ADB Server。ADB Daemon 是一个运行在 Android 客户端的守护进程，用于和 ADB Server 进行通信，并给主机提供一系列的服务。

在我们平常的开发中，可能会碰到一些 Android 设备无法通过 `adb` 去连接。这里分析两种常见的连接错误。

## 常见错误分析

### 设备找不到(device not found)

这种情况，一般现象是我们已经用 USB 把 Android 设备和主机连接在一起，但 `adb devices` 却无法正常识别该设备。但是通过 `lsusb` 命令却又能够看到该USB设备。

原因一般是 ADB 不识别该设备的 VenderID。我们可以新建一个 `$HOME/.android/adb_usb.ini` 文件，把我们 USB 设备上的 VenderID 添加到该文件里，一个一行，然后运行 `adb kill-server` 把 ADB Server 干掉。之后我们就能够正常使用 `adb` 连接到该 Android 设备。

关于这背后的具体细节，我们可以从ADB实现源码中找到。如果你现在手上有 Android 源码，可以在 `system/core/adb` 目录下找到 ADB 的实现代码。在 ADB 检测到一个 USB 设备时，会调用 `transport_usb.c:is_adb_interface` 函数。通过比对比对该设备的USB协议类型，VenderID 等字段，来检测该USB设备是否支持 ADB 连接。而所用的 VenderID 都是在 `usb_vendors.c:usb_vendors_init` 函数里生成的。`usb_venders_init` 函数首先会读取内置的 VenderID，然后判断是否在指定的目录存在一个 adb_usb.ini 文件，如果存在，就把该文件里的 VenderID 也加进来。所以如果你的 Android 设备不在内置的 VenderID 之列，就只能在 `adb_usb.ini` 文件里手动添加了。

### 没权限(permission denied) / 权限不足(insufficient permission)

这应该是比较常见的问题。这种问题，一般 ADB 可以发现该设备，但由于 LINUX 系统权限问题，无法在当前用户下打开该设备。于是就有了没权限的一说。这种情况其实跟 ADB 关系不大，解决思路一般是给设备节点文件分配相应的权限，我们可以通过设置 `udev` 的规则 `/etc/udev/rules.d/`，让 `udev` 在发现该设备时，自动分配我们设置的权限。`udev` 的规则语法如下：

<pre>SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4e12", MODE="0600", OWNER="username"
</pre>

我们也可以简单粗暴的用 `chmod` 命令临时改变 `/dev/bus/usb/` 下面的设备节点权限。

有的时候，你会发现按照上面做了，还是不行。请把 `udev` 服务重启，把 ADB Server 进程重启，把 USB 重插一遍，一般就能解决。如果还不能解决，我觉得你该检查你的 USB 线了。





 [1]: http://tinylab.org
