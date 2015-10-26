---
title: 记录命令行输出日志
author: Wu Zhangjin
layout: post
permalink: /record-command-line-output-logs/
tags:
  - minicom
  - screen
  - script
categories:
  - Shell
---
* 问题描述

  如果用Linux，蛮多工作是在命令行进行的，很多时候为了分析和回顾问题，经常需要记录操作过程以及相关操作的输出日志。

* 问题分析

  最常用的方法是直接从控制台复制屏幕输出，但是这个有一些弊端，比如说，需要修改控制的回滚行数（一般通过Edit->preferences->Scrollback lines改大），否则老的记录会被冲掉。另外一个弊端是，控制台的输出不方便检索和定位。所以通常我们需要谋求其他更方便的办法。

* 解决方案

  其实我们有蛮多的选择：

  比如，如果只是为了抓取串口的输出，可以直接用`minicom -C`指定记录日志的文件名。

      $ sudo apt-get install minicom
      $ minicom -D /dev/ttyUSB0 -C /tmp/minicom.cap


  又比如，用`screen -L`可以记录之后的所有操作以及输出日志，直到主动键入exit退出。日志文件保存在：screenlog.0中。

      $ sudo apt-get install screen
      $ screen -L
      $ cat /proc/version
      $ exit
      $ ls screenlog.0

  但是上面适合人机交互的场景，如果想自动执行一些命令并记录这些命令的输出甚至想确认这些命令是否执行成功，则可以用script。

      $ script -e -c "make CROSS_COMPILE=arm-none-linux-gnueabi- -j8" -a compile.log

  其中，`-a`指定日志文件，如果不指定，默认为typescript；`-c`指定要执行的命令；`-e`记录所执行命令的退出状态。
