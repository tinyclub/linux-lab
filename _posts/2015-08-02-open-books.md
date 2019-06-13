---
title: 泰晓开放书籍计划介绍
author: Wu Zhangjin
layout: post
permalink: /open-books/
tags:
  - C 语言编程透视
  - Shell 编程范例
  - 嵌入式 Linux 知识库
categories:
  - 开源书籍
---

> by Falcon of [TinyLab.org][1]
> 2015/08/02


## 简介

基于 Linux 相关开源技术，[泰晓科技][1]致力于在计算机基础技术方面的持续积累和分享。

相关原创分享会逐步整理成开放书籍并统一发布到：<http://tinylab.gitbooks.io/>，目前已涵盖 Shell、C 和 嵌入式 Linux，未来会逐步加入 汇编、操作系统、编译原理、系统优化 等其他基础课程。

早在 2013 年，我们就系统地分析了 [为什么计算机的学生要学习 Linux 开源技术](http://tinylab.org/why-computer-students-learn-linux-open-source-technologies/)，希望这些开放书籍可以提供更多的助力。

也欢迎更多来自高校和企业的同学参与进来，联合开发公开课程，把企业需求和前沿技术带进传统大学课堂，提升教学水平，优化教学质量，缩小高校教学和企业需求之间的差距。

## 已经发布

1. C 语言编程透视
  * 首页：<http://tinylab.org/open-c-book>
  * 阅读：<https://tinylab.gitbooks.io/cbook>
  * 简介：以实验的方式去探究类似 `Hello World` 这样的小程序在开发与执行过程中的微妙变化，一层层揭开 C 语言开发过程的神秘面纱，透视背后的秘密，不断享受醍醐灌顶的美妙。

2. Shell 编程范例
  * 首页：<http://tinylab.org/open-shell-book>
  * 阅读：<https://tinylab.gitbooks.io/shellbook>
  * 简介：不同于传统 Shell 书，本书未花大篇幅介绍 Shell 语法，而以面向“对象”的方式引入大量实例介绍 Shell 日常操作，“对象” 涵盖数值、逻辑值、字符串、文件、进程、文件系统等。这样有助于学以致用中加强兴趣。也可作为 Shell 编程索引，随时检索。

3. 嵌入式 Linux 知识库（eLinux.org 中文版）
  * 首页：<http://tinylab.org/elinux>
  * 阅读：<https://tinylab.gitbooks.io/elinux>
  * 简介：Embedded Linux Wiki (elinux.org) 的 GitBook 版本，目前[中文翻译][2]工作正在持续进行中。

## 正在撰写

1. Linux 0.11 考古笔记
  * 首页：<http://tinylab.org/lad-book>
  * 阅读：<https://tinylab.gitbooks.io/lad-book>
  * 简介：基于现有的 [5 分钟 Linux 0.11 实验环境][6]，再读 Linux 0.11 并写读书笔记，阅读过程中，争取逐步把 Linux 0.11 移植到 MIPS, ARM 和 PowerPC 平台。

2. 嵌入式 Linux 系统开发公开课（基于 Linux Lab）
  * 首页：<http://tinylab.org/elinux-course>
  * 简介：Linux Lab 基于 Docker 和 Qemu，为学生和老师提供了一个即时的嵌入式 Linux 开发环境，本课程将介绍如何[利用 Linux Lab 完成嵌入式系统软件开发全过程][8]。


## 计划发布

1. Linux 汇编语言上手
  * 简介：基于 [CS630 课程][3] ，同时介绍 [4 大架构汇编语言][4]，内容也会设法涵盖[王爽老师的大学汇编语言][5]课本。

2. TCC 完全注释
  * 简介：[Tiny C Compiler][7] 是一款轻量级 C 语言编译器，打算通过阅读和注释 TCC，进而全面温习编译原理。

## 参与原创和翻译

热烈欢迎更多同学加入泰晓原创和翻译团队，参与相关文章的撰写和翻译或者书籍的整理。参与方式非常简单：

1. 直接在 [Github.com/tinyclub][9] 上 Start/Fork 我们的任意一个项目，发送 Pull Request 提交任何修订。
2. 通过微信直接联系我们，扫码加我们微信吧：

![tinylab wechat](/images/wechat/tinylab.jpg)

## 赞助我们

泰晓科技的所有内容全部开放，所有原创作者和翻译作者们都是利用业余时间兼职投入，为了创造更多优质的内容，非常期望喜欢我们的读者们赞助我们，赞助费用会回馈给作者和译者们，将用于 T Shirt 制作，钢笔购买，网站域名和服务托管等。

赞助途径：

  1. 每篇文章的最后有一个 微信赞助二维码，扫描后可赞助。
  2. 每本开源书籍的介绍章节会有一个 微信赞助二维码，扫描后可赞助。
  3. 通过 [泰晓原创服务中心](http://weidian.com/?userid=335178200) 赞助我们，可以获得更多免费技术咨询和培训服务。


 [1]: http://tinylab.org
 [2]: /elinux/
 [3]: /cs630-qemu-lab/
 [4]: /linux-assembly-language-quick-start/
 [5]: /assembly
 [6]: /linux-0.11-lab/
 [7]: http://bellard.org/tcc/
 [8]: /using-linux-lab-to-do-embedded-linux-development/
 [9]: http://github.com/tinyclub
