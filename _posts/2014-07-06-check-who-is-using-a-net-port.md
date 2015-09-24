---
title: 查看谁在使用某个网络端口
author: Wu Zhangjin
layout: post
permalink: /faqs/check-who-is-using-a-net-port/
tags:
  - fuser
  - lsof
  - nmap
  - port
categories:
  - Linux
---
* 问题描述

  如果某个端口不是常用端口，又担心服务器被谁黑掉了，想知道到底谁在用，那该怎么办？

* 问题分析

  通常可以通过nmap查看当前开放的端口，然后用lsof或者fuser工具来获取该端口对应的活动进程。

* 解决方案

  以9000为例，查看当前开放的进程：

      $ nmap localhost
      9000/tcp open  cslistener

  然后用fuser或者lsof查看端口对应的活动进程：

      $ sudo fuser -v 9000/tcp

  或者

      $ sudo lsof -i :9000
