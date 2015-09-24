---
title: 五分钟内搭建 Linux 0.11 的实验环境
author: Wu Zhangjin
layout: post
permalink: /take-5-minutes-to-build-linux-0-11-experiment-envrionment/
views:
  - 484
tags:
  - Bochs
  - Callgraph
  - calltree
  - Linux 0.11
  - Linux内核完全注释
  - Mac OSX
  - Qemu
  - tree2dotx
  - Ubuntu
  - 实验环境
categories:
  - Linux
---

> by Falcon of [TinyLab.org][1]
> 2015/3/17


## 故事

大概在 2008 年 5 月份开始阅读赵博的[《Linux内核完全注释》][2]，并在当时 [兰大开源社区][3] 的博客系统上连载阅读笔记。

每阅读完一部分就会写一份笔记，当时社区的反响还是蛮大了，因此结识了很多技术方面的好友。

但是大概在 2009 年初，自己出去实习了。因为实习工作任务繁重，所以这部分阅读工作未能继续。另外，那个博客网站因为升级故障，导致数据被破坏，到如今都无法访问。

还好当时有做数据备份，2013 年左右在自己机器上重新把网站恢复出来，博客系统的数据总算找回来。并且已经陆续把部分重要文章整理到了如今的 [泰晓科技][1] 平台上，希望更多的同学受益。

计划逐步把当时的阅读笔记整理出来并抽空阅读剩下的部分。

这里先分享如何快速搭建一个 Linux 0.11 的实验环境，这是阅读这本书非常重要的准备工作，因为作为实践性很强的操作系统课程，实验环境是必要条件，否则无法深入理解。

## 更多细节

好了，如果想快速上手，可以直接跳到 [下一节][4]。

### 往事回首

赵老师书里头介绍的是在 Redhat 环境下用 Bochs 仿真系统来跑 Linux 0.11，通过实验发现诸多问题，不断摸索，阅读计划不断推迟，因为蛮多时间浪费在实验和调试环境的打造上了，分享一下这段历史吧：[目前已经成功地把linux-0.11移植到gcc 4.3.2][5]，当时还是做了一些工作的：

  * 可以在 32 位和 64 位的 Linux/x86 系统上编译
  * 支持最新的 Gcc 4.3.2，并同时支持 Gcc 3.4, 4.1, 4.2, 4.3，也就是说不管你机器上安装的是这里头的哪个版本，该代码都可以正常编译
  * 在最新的 Ubuntu 和 Debian 系统上测试通过
  * 在 bochs 2.3.7 和 qemu 0.9.1 上正常启动
  * 其中的 boot/bootsect.s 和 boot/setup.s 已经用 AT&T 语法重写，并把原来的版本剔除，因此无须再安装 bin86
  * Makefile 文件被调整和增加了一些内容，更方便用户调整编译选项和移植，并更方便地进行实验
  * 用 Shell 重写了 tools/build.c，更容易理解

最终达成的效果是，可以非常方便地在当时最新的 Ubuntu 系统上学习和调试 Linux 0.11，为后续进一步研究 Linux 0.11 提供了最基础的准备。

### 八年之后

废话不多说了，从 2008 年到现在，自己在 Linux 方面的学习有了一定的进步，回头再看看曾经奋斗的历程，稍微有点小小的感动。

因为当时的博客以及档案的下载地址都已经失效，所以很多网友还时长会发邮件过来咨询。一般是直接把机器上备份的一些档案邮寄给大家。

最近也稍有在 Google 上检索 Linux 0.11，非常有幸看到有蛮多的 github 仓库备份并改进了我当时上传的代码。非常精彩的例子有：

  * https://github.com/yuanxinyu/Linux-0.11
  * https://github.com/run/linux0.11

非常感谢大家的工作，上面都可以直接在当前的 Ubuntu 环境下工作，第一份甚至都已经支持 Mac OS X ;-)

不过也还有可稍微改进的地方：

  * 把实验需要的 rootfs 镜像直接通过压缩的方式上传到仓库

    这样就可以形成一个完整的实验环境，压缩的好处是可以加快网络下载的速度；另外，为了避免额外的解压工作，在 Makefile 里头，我这个脚本控当然是代劳了。

  * 合并更多未曾发布的内容

      * 把 [calltree][6] 二进制文件直接打包进去，这样就可以直接用了（注：calltree-2.3 源代码也已经无法在最新的 Ubuntu 系统编译了！）
      * 添加了脚本 tools/tree2dotx，可以把 calltree 的输出转换为图片
      * 把 floppy 和 ramdisk 的包也打包进去，方便阅读相关代码，不过可惜的是，发现从 floppy 启动一直死循环，后面再解决吧，应该是代码问题
      * 其他微小调整

整个实验环境目前只有 30 M，压缩成 xz 只有 18 M，非常小。

## 五分钟教程

### 预备

先准备个电脑，XP 已死，建议用 Ubuntu 或者 OS X，这里主要介绍 Ubuntu，OS X 看 [README.md][7] 吧。

    apt-get install vim cscope exuberant-ctags build-essential qemu


### 下载

    git clone https://github.com/tinyclub/linux-0.11-lab.git


### 编译

    cd linux-0.11-lab && make


### 从硬盘启动

    make start-hd


### 调试

打开一个控制台，从硬盘启动并进入 debug 模式：

    make debug-hd


通过 gdb 调试：

    gdb images/kernel.sym
    (gdb) target remote :1234
    (gdb) b main
    (gdb) c


### 查阅文档

[README.md][7]

### 查看帮助

    make help
    > Usage:
     make --generate a kernel floppy Image with a fs on hda1
     make start -- boot the kernel in qemu
     make start-fd -- boot the kernel with fs in floppy
     make start-hd -- boot the kernel with fs in hard disk
     make debug -- debug the kernel in qemu & gdb at port 1234
     make debug-fd -- debug the kernel with fs in floppy
     make debug-hd -- debug the kernel with fs in hard disk
     make disk  -- generate a kernel Image & copy it to floppy
     make cscope -- genereate the cscope index databases
     make tags -- generate the tag file
     make cg -- generate callgraph of the system architecture
     make clean -- clean the object files
     make distclean -- only keep the source code files


### 生成函数调用关系图

    make cg
    ls calltree/linux-0.11.jpg


生成的图片见最后。

## 后话

是不是够简单便捷？

遇到任何问题欢迎参与回复互动，或者关注我们的新浪微博/微信公众号互动：@泰晓科技。

也可以直接到赵老师的站点上参与交流和讨论：<http://www.oldlinux.org/oldlinux/>


![Linux 0.11 Calltree][8]





 [1]: http://tinylab.org
 [2]: http://www.oldlinux.org/download/clk011c-3.0.pdf
 [3]: http://oss.lzu.edu.cn
 [4]: #section-4
 [5]: http://www.oldlinux.org/oldlinux/archiver/?tid-11651.html
 [6]: http://sourceforge.net/projects/schilytools/files/calltree/
 [7]: https://github.com/tinyclub/linux-0.11-lab/blob/master/README.md
 [8]: /wp-content/uploads/2015/03/linux-0.11.jpg
