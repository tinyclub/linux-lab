---
title: 'C 语言编程透视'
tagline: 一本透视 C 语言开发过程的开源书籍
author: Wu Zhangjin
layout: page
album: 'C 语言编程透视'
permalink: /open-c-book/
description: 以实验的方式去探究类似 `Hello World` 这样的小程序在开发与执行过程中的微妙变化，一层层揭开 C 语言开发过程的神秘面纱，透视背后的秘密，不断享受醍醐灌顶的美妙。
update: 2015-10-1
categories:
  - 开源书籍
  - C
tags:
  - gcc
  - 程序执行
  - 进程
  - 动态链接
  - ELF
---

> 成绩简报：
> 1. Gitbook 中文类书籍 Top 100，260+ Stars
> 2. 过去一年，在线阅读量 45000+，下载量 22000+
> 3. Github 仓库，220+ Stars 90+ Forks

## 背景

2007 年开始系统地学习 Shell 编程，并在[兰大开源社区][1]写了系列文章。

在编写[《Shell 编程范例》][2]文章的[《进程操作》][3]一章时，为了全面了解进程的来龙去脉，对程序开发过程的细节、ELF格式的分析、进程的内存映像等进行了全面地梳理，后来搞得“雪球越滚越大”，甚至脱离了Shell编程关注的内容。所以想了个小办法，“大事化小，小事化了”，把涉及到的内容进行了分解，进而演化成另外一个完整的系列。

2008 年 3 月 1 日，当初步完成整个系列时，做了如下的小结：

> 到今天，关于 "Linux下 C 语言开发过程" 的一个简单视图总算粗略地完成了，从寒假之前的一段时间到现在过了将近一个月左右吧。写这个主题的目的源自“Shell 编程范例之进程操作”，当写到这一章时，突然对进程的由来、本身和去向感到“迷惑不解”。所以想着好好花些时间来弄清楚它们，现在发现，这个由来就是这里的程序开发过程，进程来自一个普通的文本文件，在这里是 C 语言程序，C 语言程序经过编辑、预处理、编译、汇编、链接、执行而成为一个进程；而进程本身呢？当一个可执行文件被执行以后，有了 exec 调用，被程序解释器映射到了内存中，有了它的内存映像；而进程的去向呢？通过不断地执行指令和内存映像的变化，进程完成着各项任务，等任务完成以后就可以退出了(exit)。
> 
> 这样一份视图实际上是在寒假之前绘好的，可以从下图中看到它；不过到现在才明白背后的很多细节。这些细节就是这个系列的每个篇章，可以对照“视图”来阅读它们。

![C 语言程序开发过程视图][4]

## 计划

考虑到整个 Linux 世界的蓬勃发展，Linux 和 C 语言的应用环境越来越多，相关使用群体会不断增加，所以最近计划把该系列重新整理，以自由书籍的方式不断更新，以便惠及更多的读者。

打算重新规划、增补整个系列，并以开源项目的方式持续维护，并通过 [TinLab.org][13] 平台接受读者的反馈，直到正式发行出版。

自由书籍将会维护在 TinyLab 的[项目仓库][14]中。项目相关信息如下：

  * 在线阅读：<https://gitbook.com/book/tinylab/cbook>
  * 代码仓库：[https://github.com/tinyclub/open-c-book.git][14]
  * 项目首页：[Open-C-Book](/open-c-book/)

## 获取书稿

可以通过下载书籍的 markdown 源码自行编译。

* 下载 pdf 版

  狂击 [《C 语言编程透视》][15]下载。

* 下载并编译该书

      $ git clone https://github.com/tinyclub/open-c-book.git
      $ make

      或者

      $ gitbook pdf

## 历史

之前整个系列大部分都已经以 Blog 的形式写完，大体结构目下：

  * [《把 VIM 打造成源代码编辑器》][5]
    
      * 源代码编辑过程：用 VIM 编辑代码的一些技巧
      * 更新时间：2008-2-22

  * [《GCC 编译的背后》][6]
    
      * 编译过程：预处理、编译、汇编、链接
      * 第一部分：《预处理和编译》（更新时间：2008-2-22）
      * 第二部分：《汇编和链接》（更新时间：2008-2-22）

  * [《程序执行的那一刹那 》][7]
    
      * 执行过程：当从命令行输入一个命令之后
      * 更新时间：2008-2-15

  * [《进程的内存映像》][8]
    
      * 进程加载过程：程序在内存里是个什么样子？
      * 第一部分（讨论“缓冲区溢出和注入”问题）（更新时间：2008-2-13）
      * 第二部分（讨论进程的内存分布情况）（更新时间：2008-6-1）

  * [《进程和进程的基本操作》][9]
    
      * 进程操作：描述进程相关概念和基本操作
      * 更新时间：2008-2-21

  * [《动态符号链接的细节》][10]
    
      * 动态链接过程：函数 puts/printf 的地址在哪里？
      * 更新时间：2008-2-26

  * [《为可执行文件“减肥”》][11]
    
      * ELF 详解：从”减肥”的角度一层一层剖开ELF文件
      * 更新时间：2008-2-23

  * [《代码测试、调试与优化小结》][12]
    
      * 程序开发过后：内存溢出了吗？有缓冲区溢出？代码覆盖率如何测试呢？怎么调试汇编代码？有哪些代码优化技巧和方法呢？
      * 更新时间：2008-2-29

## 反馈问题

欢迎大家指出本书初稿中的不足，甚至参与到相关章节的写作、校订和完善中来。

如果有时间和兴趣，欢迎参与，可以[联系我们][16]，也可以直接在 [TinyLab.org][17] 相关页面进行评论回复。

 [1]: http://oss.lzu.edu.cn
 [2]: /shell-programming-paradigm-series-index-review/
 [3]: /shell-programming-paradigm-of-process-operations/
 [4]: /wp-content/uploads/2014/03/c_dev_procedure.jpg
 [5]: /make-vim-source-code-editor/
 [6]: /behind-the-gcc-compiler/
 [7]: /program-execution-the-moment/
 [8]: /process-memory-image/
 [9]: /process-and-basic-operation/
 [10]: /details-of-a-dynamic-symlink/
 [11]: /as-an-executable-file-to-slim-down/
 [12]: /testing-debugging-and-optimization-of-code-summary/
 [13]: /
 [14]: https://github.com/tinyclub/open-c-book
 [15]: https://www.gitbook.com/download/pdf/book/tinylab/cbook
 [16]: /about/
 [17]: /the-c-programming-language-insight-publishing-version-0-01/
