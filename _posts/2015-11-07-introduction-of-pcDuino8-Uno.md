---
title: "开源硬件迎来8核时代"
author: 'Yao Qi'
album: pcDuino
layout: post
permalink: /introduction-of-pcDuino8-Uno/
description: "本文将介绍LinkSprite公司近日推出的高性能的卡片式电脑。"
categories:
  - pcDuino
  - ARM
tags:
  - pcDuino8 Uno
  - 开源硬件
---

> by  youkee of [TinyLab.org][6]
> 2015/11/07 15:09

## 简介

近日，[LinkSprite公司](www.linksprite.com)推出一款高性能的卡片式电脑，采用[全志H8](http://www.allwinnertech.com/clq/processorh/AllwinnerH8.html) 8核ARM Cortex-7处理器，主频可达2.0GHz。可运行诸如Ubuntu、Android等操作系统。pcDuino8 Uno图形化桌面输出采用HDMI接口，最高支持1080P显示。内置硬件视频处理引擎，支持1080p 60fps 视频解码器和1080p 30fps H.265/HDEV视频编码。pcDuino8 Uno的I/O引脚兼容非常流行的Arduino生态系统，可接入Arduino Shield扩展板；系统自带多种开发工具，如Arduino-IDE，Scratch等编程软件，也可以支持python、processing等编程。

该开源板迎合了开源社区对硬件处理速度的需求，满足了用户对Arduino生态系统兼容性，提升了pcDuino开发板的易用程度；又因为带有高性能的H8处理器，同时还有丰富的扩展接口，包括音频视频输出接口，摄像头接口，USB接口，极大地扩展了该开发板的应用领域，这正是H8 SoC的。

 <img src="/images/boards/pcDuino/pcduino8_uno_1.jpg" title="pcDuino8 Uno 正面" width="300">
 <img src="/images/boards/pcDuino/pcduino8_uno_2.jpg" title="pcDuino8 Uno 背面" width="300">

## 主要特性

### 1. CPU
pcDuino8 Uno采用全志的H8 SoC，CPU基于台积电最新领先的28纳米制造工艺，采用8个ARM Cortex-A7内核，支持8核心同时2.0GHz高速运行。

### 2. GPU
搭配Imagination旗下强劲的PowerVR SGX544 图像处理架构, 工作频率可达700M左右，支持OpenGL ES2.0/1.1, OpenCL 1.1 API。

### 3.多媒体处理特性
* 支持多种的1080p@60fps视频处理
* 支持H.265/HEVC格式
* 集成8M ISP图像信号处理架构，可支持800万像素摄像头。

### 4. 视频输出
* HDMI接口输出，支持1080p@60fps显示
* 支持HDCP V1.2协议
* 支持HDMI CEC

### 5.其他通用接口
* 千兆以太网接口
* 1 x USB
* 1 x USB OTG，可支持OTG-to-Ethernet
* Micro USB 5V，2V直流供电

### 6. Arduino兼容I/O接口
* 14 x GPIO
* 2 x PWM
* 1 x UART
* 1 x SPI
* 1 x I2C
* 6 x ADC(需外接扩展模块)

### 7. 操作系统
* Ubuntu 14.04
* Android 4.4

### 8. 编程工具
* Arduino IDE
* Scratch
* Processing
* Python

## pcDuino8 Uno接口
 <img src="/images/boards/pcDuino/pcDuino8_uno_3.png" title="pcDuino8 Uno 接口" width="300">

## pcDunino8 Uno VS 树莓派2
|参数|pcDuino8 Uno|树莓派2|
|---|---|---|
|CPU|全志H8 8-Core Cortex-A7 @ 2.0GHz|博通BCM2836 4-Core ARM7 @900MHz|
|GPU|Power VR SG544 @720MHz|Dual-Core Videocore IV@250MHz|
|DRAM|	DDR3 1GB	DDR2 1GB|
|板上存储|microSD卡|microSD卡|
|网络接口|10/100/1000兆以太网|10/100兆以太网|
|操作系统|Ubuntu 14，Android|NOOBS,RASPBIAN,Ubuntu Mate, Windows 10 IOT,OSMC等|
|视频输出|HDMI 1.4，分辨率最高支持1920x1080|HDMI 1.4，分辨率支持从640 x 350 至 1920 x 1200|
|GPIO扩展口|兼容Arduino Uno I/O，包括：14x GPIO, 2xPWM, 1x UART, 1x SPI，1x I2C，6xADC（需外接ADC模块）|40 x GPIO|
|HDMI|1 x HDMI 1.4|1 x HDMI 1.4|
|音频输出|3.5mm模拟音频接口|3.5mm模拟音频接口|
|红外接收|红外接收器接口（可安装）|无|
|摄像头|MIPI接口|CSI接口|
|USB|1 x USB Host, 1 x USB OTG	4xUSB host|
|电源供电|5V, 2000mA Micro USB|5V, 1000mA Micro USB|
|尺寸|	92x54mm	86x56mm

## 试用体验

 <img src="/images/boards/pcDuino/pcduino8_uno_4.png" title="pcDuino8 Uno上手体验" width="300">
pcDuino8 Uno拿在手上，确实小巧，迫不及待地按照网上提供的教程刷了Ubuntu 14.04系统。接上显示器，鼠标和键盘，上电启动，10秒左右，进入系统桌面，这速度真是够可以的。再想想我现在快要淘汰的笔记本，开机速度接近两分钟，这一对比，心中都是泪啊。

既然是8核，标称2.0GHz的处理器，恨不得将8个核全部跑满。于是用来编译openCV、编译系统内核，完全当作一个编译服务器来用，这时觉得1G DRAM还真是不够用啊，编译开个8线程（是不是要疯啊），内存就扛不住了。后来装上了VLC，转播视频流，当作一个视频服务器。再接着用openCV做各种图像和视频处理，比如视频监控、摄像头的人脸识别、运动检测等等。试用结果看，pcDuino8 Uno的性能确实有着很大的优势，但问题来了，如何在程序中充分挖掘多核的性能呢！

 <img src="/images/boards/pcDuino/pcduino8_uno_5.png" title="人脸识别" width="300">
 <img src="/images/boards/pcDuino/pcduino8_uno_6.png" title="网络视频监控" width="300">

利用各种开源的项目，在pcDuino8 Uno上折腾，乐在其中！最近还想把Lakka（开源的模拟游戏终端，是一种轻量级的Linux系统）移植到pcDuino8 Uno上，卡片电脑摇身一变成了游戏终端，这是要“造福”多少人类！有兴趣的童鞋，欢迎加入其中。

另外，还有笔者还有几个非常优秀的开源硬件相关的微信群，欢迎微信本人（ID：yaoqee），带你进入开源硬件世界。

## 非常有用的链接

1. [pcDuino8 Uno][1]产品介绍
2. [pcDuino8 Uno系统镜像下载地址][2]，提供了Ubuntu 14.04的系统镜像，烧录到micro-SD卡中即可
3. [LinkSprite中文学习中心][3]提供了pcDuino各种开源平台的入门教程和开发实例。
4. [pcDuino中文论坛][4]，欢迎各位开源爱好者加入。

## 好消息！好消息！好消息！
重要的事情说3遍，双十一期间，[LinkSprite官方淘宝直营店][5]会针对pcDuino8 Uno推出很大的优惠活动，敬请关注。

 [1]: www.linksprite.com/?page_id=1477
 [2]: www.linksprite.com/image-for-pcduino8-uno/
 [3]: cnlearn.linksprite.com
 [4]: https://shop69294605.taobao.com/?spm=a230r.7195193.1997079397.297.MchY8F
 [5]: www.pcduino.org
 [6]: http://TinyLab.org
