---
layout: post
author: 'Wu Zhangjin'
title: "通过网络访问串口"
permalink: /serial-port-over-internet/
description: "串口是嵌入式开发中常用的调试、通信和下载工具，本文介绍了如何通过网络访问嵌入式设备上的串口，从而极大地方便远程调试和操作嵌入式设备。"
category:
  - 串口
  - NodeMCU
tags:
  - Linux
  - socat
  - netcat
  - ser2net
  - remserial
  - conmux
---

> By Falcon of TinyLab.org
> 2015-12-07

## 简介

串口是嵌入式设备中常见的调试、通信和下载接口。通常情况下，仅仅需要在开发主机上访问该串口，可通过标准的串口线或者 USB 线连到串口上。

如果要在开发主机之外也能访问到串口呢？

## Serial Port Over Network

通过网络虚拟化串口的基本需求很简单，首先要把串口虚拟化为网络端口，之后在网络中的另外一台主机上通过 telnet 等工具直接访问该网络端口或者反过来把网络端口逆向为一个虚拟化的串口，进而通过串口的 minicom 等工具也可以访问。

这样的工具有 socat, netcat, ser2net, remserial, conmux，发现 socat 非常好用，这里在参考 [socat-ttyovertcp.txt](http://www.dest-unreach.org/socat/doc/socat-ttyovertcp.txt) 的基础上介绍它的用法。

串口以接入到 MacBook Pro 的 cp2102 为例：`/dev/tty.SLAB_USBtoUART`。

另外假设主机 IP 地址为：`192.168.1.168`，在远端要虚拟的串口命名为：`/dev/vmodem001`。

### 串口转 TCP 端口

    sudo socat tcp-l:54321,reuseaddr,fork file:/dev/tty.SLAB_USBtoUART,waitlock=/var/run/tty0.lock,clocal=1,cs8,nonblock=1,ixoff=0,ixon=0,ispeed=9600,ospeed=9600,raw,echo=0,crtscts=0

也可简单使用：

    sudo socat tcp-l:54321 /dev/tty.SLAB_USBtoUART,clocal=1,nonblock

### TCP 端口转虚拟串口

    sudo socat pty,link=/dev/vmodem001,waitslave tcp:192.168.1.168:54321

### 远程访问串口

    sudo minicom -D /dev/vmodem001

或

    telnet 192.168.1.168 54321

### 安全访问

如果关心安全，那么请参考 [socat-openssl.txt](http://www.dest-unreach.org/socat/doc/socat-openssl.txt)。

## 应用实例

在哪些情况下会需要在开发主机之外访问串口呢？

一个典型的实例是：

最近刚用到一款 Wifi 物联网开发板（NodeMCU），开发主机是 MacBook Pro 笔记本，但是开发环境搭建在 Virtualbox 上跑的 Linux 中，因此，需要在 Linux 系统中访问串口，但是发现该串口（cp2102）即使通过 Virtualbox 正确设置允许 Linux 访问并且相应的驱动也正常启动，但是 minicom 无法访问该串口（怀疑是 Virtualbox 使用了 ohci，但该设备实际为 uhci），这个时候通过网络虚拟化的串口就非常有帮助了。

更多的例子可能是，如果想远程控制该设备，而该设备本身不支持网络，那么把串口接入带有网络的主机，并把串口通过网络虚拟化就很有帮助了。
