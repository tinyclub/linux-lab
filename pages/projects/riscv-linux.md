---
layout: page
title: 'RISC-V Linux 内核剖析'
tagline: '剖析 Linux 内核对 RISC-V 处理器架构的支持'
author: Wu Zhangjin
album: 'RISC-V Linux'
permalink: /riscv-linux/
description: 该项目旨在研究和分享 Linux 内核对开源 RISC-V 处理器架构的支持。
toc: false
update: 2022-03-19
categories:
  - 开源项目
  - Risc-V
tags:
  - RISC-V
  - Linux
  - 内核剖析
---

## 项目简介

鉴于 RISC-V 芯片相关技术的蓬勃发展，泰晓科技 Linux 技术社区组建了一个开放的 RISC-V Linux 内核兴趣小组，致力于 RISC-V Linux 内核以及周边技术与社区的跟踪、调研、剖析、贡献和分享。

* 协作仓库：<https://gitee.com/tinylab/riscv-linux>
* 实验环境：<https://tinylab.org/linux-lab-disk>

## 报名方式

该活动对外开发，详细报名方式请参考 [RISC-V Linux 内核兴趣小组招募爱好者-ing](https://tinylab.org/riscv-linux-analyse/)。

## 相关输出

本站将陆续输出该活动成果，相应的公众号、B站、知乎、泰晓学院、星球也将连载。其中星球用于速记活动过程中的各类资料和片段。

* 公众号：泰晓科技
* 知乎专栏：<https://zhihu.com/column/tinylab>
* B 站频道：<https://space.bilibili.com/687228362>
* 泰晓学院：<https://m.cctalk.com/inst/sh8qtdag>
* 星球专栏：<https://t.zsxq.com/uB2vJyF>

<hr>

<section id="home">
  {% assign articles = site.posts %}
  {% assign condition = 'album' %}
  {% assign value = 'RISC-V Linux' %}
  {% include widgets/articles %}
</section>

