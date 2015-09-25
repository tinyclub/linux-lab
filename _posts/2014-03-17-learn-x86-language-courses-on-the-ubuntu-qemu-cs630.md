---
title: 'Linux 下通过 Qemu 学习 X86 AT T 汇编语言'
author: Wu Zhangjin
layout: post
permalink: /learn-x86-language-courses-on-the-ubuntu-qemu-cs630/
tags:
  - Assembly
  - AT&amp;T
  - CS630
  - Linux
  - Qemu
  - Ubuntu
categories:
  - Assembly
  - Qemu
  - X86
---

> by falcon of [TinyLab.org][2]
> 2014/03/16


## 简介

[CS630][3] 是旧金山大学的 [Allan B. Cruse][4] 教授开设的一门 Advanced Microcomputer Programming 课程，我在 2008 年左右初次学习，发现这门课程 **非常深入** 地介绍了 Linux 环境下 Intel X86 平台上的 AT&T 汇编语言开发。

但是比较郁闷地是，这门课程需要用一台裸机进行实验，当时自己只有一台学习和开发用的主机，何况 08 年已经比较难找到合适的 floppy 来做实验了。所以，很快决定务必让这门课程的例子能够在 Qemu 上跑起来，所以折腾了几天，写了几个脚本，改了几行代码，就开始通过 Qemu 做 CS630 上的所有实验了。如果没有记错地话，这门课程的所有汇编的例子应该都能在 Qemu 上工作。

为了感谢 Cruse 教授的 Great work ，我觉得很有必要把学习心得和通过 Qemu 做实验的方法告诉 Cruse 教授，以便更多的学生能够加快实验的过程，提高实验效率，所以那个时候 (9/16/2008) 给他发了一封邮件：

> Dear Cruse,
>
> I&#8217;m a postgraduate student of Lanzhou University, China. I&#8217;m a &#8220;student&#8221; of your online course: CS630(http://www.cs.usfca.edu/~cruse/cs630f06/).
>
> Thanks very much for your wonderful online course: CS630, It&#8217;s the best course about Microcomputer Programming and AT&T assembly Language programming under Linux I have learned. for finishing the exercises of this course, I build a VM-based experiment environment which can simplify the experiment procedure and save the time. I think it will be useful to the other students, so I decide to send it to you.
>
> you can download it from the attachment, which just include several scripts(configure, Makefile, qemu.sh) and a rewritten quickload.s(quickload_floppy.s) for loading floppy image. and there is a document README there to introduce how to use it.
>
> Best regards, Falcon

然后，Cruse 回信了：

> Hello, Falcon
>
> I&#8217;m amazed to receive your cs630-experiment-on-VM. I think, as an online &#8220;student&#8221;, you have earned an &#8216;A&#8217; for this course! I will let some Ubuntu-savvy students here know about what you&#8217;ve created, and we&#8217;ll see if they find it to be a timesaver, as it ought to be. Thanks for contributing these efforts to the class.

很令人鼓舞，后面我把那些脚本上传到了 [兰大开源社区][5] 的论坛，今天，为了让更多的学生能够分享到这门课程，我把当时的脚本和相应的文档做了简单地整理，并在 [https://github.com/][6] 上创建了源码仓库：

  * 项目首页：[CS630-Qemu: Learn CS630 on Qemu][7]
  * 源码仓库：[https://github.com/tinyclub/cs630-qemu-lab.git][6]

## 准备工作

先 clone 项目源码：

<pre>$ git clone https://github.com/tinyclub/cs630-qemu-lab.git
</pre>

接着，安装 Qemu:

<pre>$ sudo apt-get install qemu
</pre>

然后，下载课程提供的所有实验资料，包括所有例子：

<pre>$ cd cs630-qemu-lab/
$ make update
</pre>

[CS 630: Advanced Microcomputer Programming (Fall 2006)][3] 上的所有资料将下载到 res/ 目录，看看里头有什么：

<pre>$ ls res/
</pre>

## 通过 Qemu 学 CS630

我写了两个简单的文档，README.md 和 NOTE.md, 介绍了基本用法和注意事项，这里把实模式和保护模式下的两个例子分别介绍一下:

### 实模式：Real Mode

  * 打印 helloworld

<pre>$ ./configure src/helloworld.s
$ make boot
</pre>

  * 访问 rtc 并显示时钟

<pre>$ ./configure src/rtc.s
$ make boot
</pre>

### 保护模式：Protected Mode

  * 打印 helloworld

<pre>$ ./configure res/pmhello.s
$ make pmboot
</pre>

  * 访问 rtc 并显示时钟

<pre>$ ./configure res/rtcdemo.s
$ make pmboot
</pre>

## 演示截图

这里是保护模式下的 rtcdemo 通过 Qemu 运行的结果：

![image][8]

 [2]: http://tinylab.org
 [3]: http://www.cs.usfca.edu/~cruse/cs630f06/
 [4]: http://www.cs.usfca.edu/~cruse/
 [5]: http://oss.lzu.edu.cn
 [6]: https://github.com/tinyclub/cs630-qemu-lab/
 [7]: /cs630-qemu-lab/
 [8]: /wp-content/uploads/2014/03/cs630-qemu-pmrtc.png
