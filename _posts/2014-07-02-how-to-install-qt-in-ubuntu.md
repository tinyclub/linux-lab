---
title: 在 Ubuntu 下安装 Qt 开发环境
author: Wu Zhangjin
layout: post
permalink: /faqs/how-to-install-qt-in-ubuntu/
tags:
  - QtCreator
  - Ubuntu
categories:
  - Qt
---
* 问题描述

  Qt是一个1991年由奇趣科技开发的跨平台C++图形用户界面应用程序开发框架。它既可以开发GUI程序，也可用于开发非GUI程序，比如控制台工具和服务器。全面支持iOS、Android、WP。

  Qt分为商业版和开源版。其开源版本仅仅为了开发自由和开放源码软件， 提供了和商业版本同样的功能。GNU通用公共许可证下，它是免费的。

  目前有诸多的项目是用Qt开发的，著名的例子有开源3D打印机B9Creator，Virtualbox等。

* 问题分析

  在Ubuntu下安装软件可以直接用包管理工具：apt-get，或者从官方下载源码包安装：<http://download.qt-project.org>

* 解决方案  

  * 安装Qt基本开发工具

        $ sudo apt-get install libX11-dev libXext-dev libXtst-dev g++
        $ sudo apt-get install qt4-dev-tools qt4-doc qt4-qtconfig qt4-demos qt4-designer</pre>

  * 安装IDE: QtCreator

    方法一：在Ubuntu Software Center搜索qtcreator，点击安装即可。 方法二：直接下载qtcreator安装包，安装后可直接使用。

        $ sudo apt-get install qtcreator

  * 运行qtcreator:

        $ qtcreator
