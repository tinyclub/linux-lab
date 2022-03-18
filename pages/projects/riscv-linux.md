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
---

## 项目简介

鉴于 RISC-V 芯片相关技术的蓬勃发展，泰晓科技 Linux 技术社区计划组建一个开放的 RISC-V Linux 内核兴趣小组，致力于 RISC-V Linux 内核以及周边技术与社区的跟踪、调研、剖析、贡献和分享。

* 协作仓库：<https://gitee.com/tinylab/riscv-linux>
* 实验环境：<https://gitee.com/tinylab/linux-lab-disk>

## 相关输出

本站将陆续输出该活动成果，相应的公众号、B站、知乎也将连载。

<hr>

<section id="home">
  {% assign articles = site.posts %}
  {% assign condition = 'album' %}
  {% assign value = 'RISC-V Linux' %}
  {% include widgets/articles %}
</section>

