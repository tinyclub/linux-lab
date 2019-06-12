---
title: '实时 Linux'
tagline: '实时 Linux 相关资源汇集'
author: Wu Zhangjin
layout: page
draft: true
permalink: /rtlinux/
album: '实时 Linux'
description: '为国内实时 Linux 开发者系统地收集和整理相关资料'。
update: 2019-06-12
categories:
  - 开源项目
  - 实时抢占
tags:
  - 实时性
  - PREEMPT
  - Linux
  - OSADL
  - elinux
---

该页面汇总跟实时 Linux 项目相关的资源，方便国内从事这块的同学们作为参考。

## 项目首页

   * [最新 RT Wiki](https://wiki.linuxfoundation.org/realtime/start)
   * [早期 RT Wiki](http://rt.wiki.kernel.org/)，已不再更新，但也有很多有价值的材料。

## 代码仓库

  * [linux rt 开发仓库](https://git.kernel.org/pub/scm/linux/kernel/git/rt/linux-rt-devel.git)
  * [linux rt 稳定版](https://git.kernel.org/pub/scm/linux/kernel/git/rt/linux-stable-rt.git/)

## 版本发布

  * [发布地址](https://cdn.kernel.org/pub/linux/kernel/projects/rt/)
  * [版本介绍](https://wiki.linuxfoundation.org/realtime/preempt_rt_versions)

## 邮件列表

  * [Rt maillist](https://wiki.linuxfoundation.org/realtime/communication/mailinglists)

## 相关文档

### 入口页面

  * [最新 RT Wiki](https://wiki.linuxfoundation.org/realtime/documentation/start)
    * [RT blog](https://wiki.linuxfoundation.org/realtime/rtl/blog)
  * [早期 RT Wiki](http://rt.wiki.kernel.org/)
  * [elinux RT 页面](https://elinux.org/Real_Time)
  * [OSADL RT 页面](https://www.osadl.org/Realtime-Linux.projects-realtime-linux.0.html)
  * [龙芯 RT 页面](/preempt-rt-4-loongson/)

### 本站文章

  * [Porting RT-preempt to Loongson2F][1]
  * [Research and Practice on Preempt-RT Patch of Linux][2]

**更多**

<hr>

<section id="home">
  {% assign articles = site.posts %}
  {% assign condition = 'album' %}
  {% assign value = '实时 Linux' %}
  {% include widgets/articles %}
</section>


[1]: http://lwn.net/images/conf/rtlws11/papers/proc/p14.pdf
[2]: /wp-content/uploads/2015/11/linux-preempt-rt-research-and-practice.pdf
