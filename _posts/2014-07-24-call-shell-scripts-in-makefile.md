---
title: Makefile 中调用 Shell 脚本
author: Wu Zhangjin
layout: post
permalink: /call-shell-scripts-in-makefile/
tags:
  - Makefile
  - sed
  - Shell
categories:
  - Makefile
---
* 问题描述

  今天有同事问：如何在Makefile中把一个路径转换为`../`，即：

      usr/local/share/xml/misc/ --> ../../../../../

* 问题分析

  这个用sed命令替换就可以，然后在Makefile中通过shell调用来实现即可。

* 解决方案

  替换可以实现为：

      $ echo "usr/local/share/xml/misc/" | sed -e "s#[^/]*#%..#%g"
      ../../../../../


  不过在Makefile中调用有问题，不能正确工作，写Makefile如下：

      A := "usr/local/share/xml/misc/"
      B := $(shell echo $A | sed 's#[^/]*/#../#g')
      
      all:
            echo $(B)


  但发现如下问题：



      Makefile:3: *** unterminated call to function `shell': missing `)'.  Stop.

  发现并没有异常，一个一个排查后，竟然是sed中使用的 `#` 分隔符问题，替换为 `%` 即可。

      A := "usr/local/share/xml/misc/"
      B := $(shell echo $A | sed 's%[^/]*/%../%g')
      
      all:
            echo $(B)


  可能是 `#` 在Makefile里头被解析成注释符了。



