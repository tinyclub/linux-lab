---
title: "开源硬件迎来 8 核时代"
author: 'Yao Qi'
album: "pcDuino 入门系列"
group: news
layout: post
permalink: /introduction-of-pcduino8-Uno/
description: "本文将介绍 LinkSprite 公司近日推出的高性能的卡片式电脑。"
categories:
  - pcDuino
  - ARM
  - 开源社区
  - 行业动向
tags:
  - pcDuino8 Uno
  - 开源硬件
---

> by youkee of [TinyLab.org][6]
> 2015/11/07 15:09

## 简介

近日，[LinkSprite 公司](www.linksprite.com)推出一款高性能的卡片式电脑，采用[全志 H8](http://www.allwinnertech.com/clq/processorh/AllwinnerH8.html) 8 核 ARM Cortex-7 处理器，主频可达 2.0GHz。可运行诸如 Ubuntu、Android 等操作系统。pcDuino8 Uno 图形化桌面输出采用 HDMI 接口，最高支持 1080P 显示。内置硬件视频处理引擎，支持 1080p 60fps 视频解码器和 1080p 30fps H.265/HDEV 视频编码。pcDuino8 Uno 的 I/O 引脚兼容非常流行的 Arduino 生态系统，可接入 Arduino Shield 扩展板；系统自带多种开发工具，如 Arduino-IDE，Scratch 等编程软件，也可以支持 Python、[Processing][7] 等编程。

该开源板迎合了开源社区对硬件处理速度的需求，满足了用户对 Arduino 生态系统兼容性，提升了 pcDuino 开发板的易用程度；又因为带有高性能的 H8 处理器，同时还有丰富的扩展接口，包括音频视频输出接口，摄像头接口，USB 接口，极大地扩展了该开发板的应用领域，这正是 H8 SoC 的。

<img src="/images/boards/pcduino/pcduino8_uno_1.jpg" title="pcDuino8 Uno 正面" width="300">
<img src="/images/boards/pcduino/pcduino8_uno_2.jpg" title="pcDuino8 Uno 背面" width="300">

## 主要特性

### CPU

pcDuino8 Uno 采用全志的 H8 SoC，CPU 基于台积电最新领先的 28 纳米制造工艺，采用 8 个 ARM Cortex-A7 内核，支持 8 核心同时 2.0GHz 高速运行。

### GPU

搭配 Imagination 旗下强劲的 PowerVR SGX544 图像处理架构, 工作频率可达 700M 左右，支持 OpenGL ES2.0/1.1, OpenCL 1.1 API。

### 多媒体处理特性

* 支持多种的 1080p@60fps 视频处理
* 支持 H.265/HEVC 格式
* 集成 8M ISP 图像信号处理架构，可支持 800 万像素摄像头。

### 视频输出

* HDMI 接口输出，支持 1080p@60fps 显示
* 支持 HDCP V1.2 协议
* 支持 HDMI CEC

### 其他通用接口

* 千兆以太网接口
* 1 x USB
* 1 x USB OTG，可支持 OTG-to-Ethernet
* Micro USB 5V，2V 直流供电

### Arduino 兼容 I/O 接口

* 14 x GPIO
* 2 x PWM
* 1 x UART
* 1 x SPI
* 1 x I2C
* 6 x ADC(需外接扩展模块)

### 操作系统

* Ubuntu 14.04
* Android 4.4

### 编程工具

* Arduino IDE
* Scratch
* Processing
* Python

## pcDuino8 Uno 接口

<img src="/images/boards/pcduino/pcduino8_uno_3.png" title="pcDuino8 Uno 接口" width="300">

## pcDuino8 Uno V.S. 树莓派2

|参数|pcDuino8 Uno|树莓派2|
|---|---|---|
|CPU|全志 H8 8-Core Cortex-A7 @ 2.0GHz|博通 BCM2836 4-Core ARM7 @900MHz|
|GPU|Power VR SG544 @720MHz|Dual-Core Videocore IV@250MHz|
|DRAM|	DDR3 1GB	DDR2 1GB|
|板上存储|microSD 卡|microSD 卡|
|网络接口|10/100/1000 兆以太网|10/100 兆以太网|
|操作系统|Ubuntu 14，Android|NOOBS,RASPBIAN,Ubuntu Mate, Windows 10 IOT,OSMC 等|
|视频输出|HDMI 1.4，分辨率最高支持 1920x1080|HDMI 1.4，分辨率支持从 640 x 350 至 1920 x 1200|
|GPIO扩展口|兼容 Arduino Uno I/O，包括：14x GPIO, 2xPWM, 1x UART, 1x SPI，1x I2C，6xADC（需外接ADC模块）|40 x GPIO|
|HDMI|1 x HDMI 1.4|1 x HDMI 1.4|
|音频输出|3.5mm 模拟音频接口|3.5mm 模拟音频接口|
|红外接收|红外接收器接口（可安装）|无|
|摄像头|MIPI 接口|CSI 接口|
|USB|1 x USB Host, 1 x USB OTG	4xUSB host|
|电源供电|5V, 2000mA Micro USB|5V, 1000mA Micro USB|
|尺寸|	92x54mm 86x56mm

## 试用体验

<img src="/images/boards/pcduino/pcduino8_uno_4.png" title="pcDuino8 Uno上手体验" width="300">

pcDuino8 Uno 拿在手上，确实小巧，迫不及待地按照网上提供的教程刷了 Ubuntu 14.04 系统。接上显示器，鼠标和键盘，上电启动，10 秒左右，进入系统桌面，这速度真是够可以的。再想想我现在快要淘汰的笔记本，开机速度接近两分钟，这一对比，心中都是泪啊。

既然是 8 核，标称 2.0GHz 的处理器，恨不得将 8 个核全部跑满。于是用来编译 openCV、编译系统内核，完全当作一个编译服务器来用，这时觉得 1G DRAM 还真是不够用啊，编译开个 8 线程（是不是要疯啊），内存就扛不住了。后来装上了 VLC，转播视频流，当作一个视频服务器。再接着用 openCV 做各种图像和视频处理，比如视频监控、摄像头的人脸识别、运动检测等等。试用结果看，pcDuino8 Uno 的性能确实有着很大的优势，但问题来了，如何在程序中充分挖掘多核的性能呢！

<img src="/images/boards/pcduino/pcduino8_uno_5.png" title="人脸识别" width="300">
<img src="/images/boards/pcduino/pcduino8_uno_6.png" title="网络视频监控" width="300">

利用各种开源的项目，在 pcDuino8 Uno 上折腾，乐在其中！最近还想把 Lakka（开源的模拟游戏终端，是一种轻量级的 Linux 系统）移植到 pcDuino8 Uno 上，卡片电脑摇身一变成了游戏终端，这是要“造福”多少人类！有兴趣的童鞋，欢迎加入其中。

另外，还有笔者还有几个非常优秀的开源硬件相关的微信群，欢迎微信本人（ID：yaoqee），带你进入开源硬件世界。

## 非常有用的链接

1. [pcDuino8 Uno][1] 产品介绍
2. [pcDuino8 Uno 系统镜像下载地址][2]，提供了 Ubuntu 14.04 的系统镜像，烧录到 micro-SD 卡中即可
3. [LinkSprite 中文学习中心][3]提供了 pcDuino 各种开源平台的入门教程和开发实例。
4. [pcDuino 中文论坛][4]，欢迎各位开源爱好者加入。

## 好消息！好消息！好消息！

重要的事情说 3 遍，双十一期间，[LinkSprite 官方淘宝直营店][5]会针对 pcDuino8 Uno 推出很大的优惠活动，敬请关注。

 [1]: http://www.linksprite.com/?page_id=1477
 [2]: http://www.linksprite.com/image-for-pcduino8-uno/
 [3]: http://cnlearn.linksprite.com
 [4]: http://www.pcduino.org
 [5]: https://shop69294605.taobao.com/?spm=a230r.7195193.1997079397.297.MchY8F
 [6]: http://TinyLab.org
 [7]: http://hiprocessing.net/
