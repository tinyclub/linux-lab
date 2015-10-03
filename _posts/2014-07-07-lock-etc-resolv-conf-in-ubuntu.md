---
title: Ubuntu 中锁定域名配置文件 /etc/resolv.conf
author: Wu Zhangjin
layout: post
permalink: /faqs/lock-etc-resolv-conf-in-ubuntu/
tags:
  - /etc/resolv.conf
  - DNS
  - 锁定
categories:
  - Shell
---
* 问题描述

  DHCP服务器有时候可能会抽风，导致DNS服务器的配置文件/etc/resolv.conf经常被搞乱，影响网络的连接，那如何保护/etc/resolv.conf呢？

* 问题分析

  为了避免上述问题，咱们可以锁定/etc/resolv.conf，也就是说禁止其他人乱写该文件。

* 解决方案

  本来可以直接用`chattr +i`命令，但是发现在某个Ubuntu版本上不管用了。

  经过分析发现，在某个版本以后，这个/etc/resolv.conf不再是个普通文件，而是个符号链接，这个就是`chattr +i`不能直接起作用的原因。

  知道原因后，把符号连接删掉，重新创建一个文件就ok，那完整的解决思路就是：

      $ cp /etc/resolv.conf /tmp/resolv.conf
      $ rm /etc/resolv.conf
      $ mv /tmp/resolv.conf /etc/resolv.conf
      $ echo "nameserver 8.8.8.8" &gt;&gt; /etc/resolv.conf
      $ chattr +i /etc/resolv.conf
