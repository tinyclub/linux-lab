---
layout: post
author: 'Wu Zhangjin'
title: "多屏通过 Synergy 共享鼠标、键盘和剪切板"
permalink: /share-mouse-keyboard-and-clipboard-among-sreens/
description: "本文介绍如何通过 Synergy 实现多个屏幕之间共享同一套鼠标、键盘和剪切板，方便快捷高效率的工作。"
category:
  - Synergy
tags:
  - 效率工具
  - QuikSynergy
  - SynergyKM
---

> By Falcon of [TinyLab.org][1]
> 2017-09-29 21:26:32

## 背景

很多实验场景下，需要多个屏幕协同工作，比如一个屏幕打开电子书，另外一个屏幕对照电子书进行操作。这样就不需要在一个屏幕里头来回切换实验终端和电子书阅读器。

如果两个屏幕接入的是不同的主机，则往往需要接入两套不同的键盘和鼠标，此时需要在两套不同键盘和鼠标之间来回切换，也会非常不便利。这种情况下，通过网络共享其中一套键盘和鼠标就能够解决问题。

而 Synergy 正是这样一套开源解决方案，它不仅可以共享键盘和鼠标，而且共享了剪切板，对于上述实验场景更为便利，可以直接拷贝书中的例子到实验终端加快实验过程。

## Synergy

Synergy 支持多个平台：Windows, Mac 和 Linux。可以通过其 [官方网站](https://symless.com/synergy) 付费获取专业版本，也可以使用较为基础的免费版。其相关源码开放在：<https://github.com/symless/synergy-core>。

## 下载和安装

在 Ubuntu 下可以直接安装：

    $ sudo apt-get install synergy quicksynergy

在 Mac 下可以安装 synergykm.com 提供的版本，经测试，在 MacOS X EI Caption (Version 10.11.4) 上，只有 [1.0.1 版](http://synergykm.com/SynergyKM-1.0.1-Installer.zip) 工作。

    $ wget -c http://synergykm.com/SynergyKM-1.0.1-Installer.zip

下载下来后先解压，安装并授权。

在 Windows 下请自行研究。

## 配置并使用

下面介绍如何在 Mac 和 Ubuntu 下共享鼠标和键盘。

这里把 Macbook 笔记本作为服务器，把另外一台 Ubuntu 台式机作为客户端，也就是说把笔记本上的鼠标和键盘共享到台式机上。

* 事先在 Macbook 上通过 `System Preferences --> SynergyKM` 进行配置，作为服务器启用，并记下该服务器的 IP 地址。

  ![synergykm server](/wp-content/uploads/2017/10/synergykm-general.png)

* 接着在 Ubuntu 上启动 Quicksynergy，在 `Use` 处填入刚记下的 IP 地址并配置本机屏幕的名称，例如：`myubuntu-screen`，然后点击 `Execute` 运行。

  ![synergykm server](/wp-content/uploads/2017/10/quicksynergy.png)

* 紧接着回到 Macbook 上，在 SynergyKM 的 `Server Configuration` 处添加屏幕并通过 `Edit Screen Options` 把名字设置为`myubuntu-screen`

* 根据台式机屏幕和笔记本屏幕的位置关系，在 SynergyKM 的 `Server Configuration` 处调整好位置关系，比如台式机显示器在上面，笔记本屏幕在下面，则可以把 `myubuntu-screen` 拖动到笔记本屏幕的上面。

  ![synergykm server](/wp-content/uploads/2017/10/synergykm-config.png)

* 调整后，点击下面的 `Apply Now` 即可建立连接。

接下来，把鼠标从屏幕上方移出屏幕即可进入到台式机上的显示器，键盘操作也会相应地移动到台式机那边。反之，向下移动则可以回到笔记本。

由于支持共享剪切板，也可以在一个屏幕上拷贝内容，移动到另外一个屏幕上，再粘贴出来，从而实现跨屏幕之间的快速文本共享。

[1]: http://tinylab.org
