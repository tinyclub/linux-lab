---
title: 获取某个存储设备的 UUID
author: Wu Zhangjin
layout: post
permalink: /faqs/get-and-set-the-uuid-of-a-disk-partition/
voted_ID:
  - 'a:2:{s:11:"A1945097411";s:10:"1405061853";s:11:"A1945097416";s:10:"1405637893";}'
votes_count:
  - 2
tags:
  - /dev/disk/by-uuid/
  - blkid
  - tune2fs
  - UUID
  - uuidgen
categories:
  - Linux
---
* 问题描述

  不记得从何时起，Ubuntu的/etc/fstab里头的设备项被替换成了一个看不懂的UUID字符串，这个东西其实就是一个标识符，用于唯一标记某一个分区。为什么要用这个呢，原因是原来的设备名字可能随着设备的加载顺序发生变化，导致设备插拔起来很麻烦，而这个UUID理论上是全球唯一的，只要这个UUID跟这个分区信息绑定在一起，无论分区加载顺序如何，系统都可以找到它。

* 问题分析

  那如何获取某个存储设备的UUID或者如何知道某个这个UUID具体对应到哪个设备呢？

* 解决方案

  方法很多，可选其一：

      $ ls -l /dev/disk/by-uuid/
      $ blkid
      $ tune2fs -l /dev/xvda1 |grep "UUID"

  那这个UUID是怎么来的呢？&#8221;UUID(Universally Unique Identifier)全局唯一标识符,是指在一台机器上生成的数字，它保证对在同一时空中的所有机器都是唯一的。按照开放软 件基金会(OSF)制定的标准计算，用到了以太网卡地址、纳秒级时间、芯片ID码和许多可能的数字。&#8221;

  这里是Linux下面咱们可以直接用到的一些方法，当然还有一些开放的库可以用：[libuuid][1]。

      $ uuidgen
      c58ecaa3-283b-4b8e-a038-2e42c216ae4d
      $ cat /proc/sys/kernel/random/uuid
      3972f570-735c-4711-8908-e4a2422af80e

  生成以后，咱们其实是可以用来设置或者替换某个磁盘分区的UUID，这里还是用tune2fs：

      $ tune2fs -U $UUID /dev/xvda1

 [1]: http://linux.die.net/man/3/libuuid
