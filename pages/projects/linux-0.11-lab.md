---
title: 'Linux 0.11 实验环境'
tagline: '可快速构建，支持 Docker, Qemu, Bochs, Ubuntu, Mac OSX, Windows'
author: Wu Zhangjin
layout: page
permalink: /linux-0.11-lab/
description: 可快速搭建的 Linux 0.11 实验环境，支持 Docker, 支持 Ubuntu / Windows / Mac OS X，也内置支持 Qemu / Bochs。
update: 2015-10-1
categories:
  - 开源项目
  - Linux 0.11
tags:
  - 实验环境
---

## 项目描述

该项目致力于快速构建一个 Linux 0.11 实验环境，可配合[《Linux内核完全注释》][1] 一书使用。

  * 使用文档：[README.md][2]

  * 在线实验
      * [泰晓实验云台](http://tinylab.cloud:6080/labs/)

  * 考古计划
      * [Linux 考古笔记](http://tinylab.org/lad-book)

  * 在线演示
      * 命令行
          * [基本用法](http://showterm.io/ffb67385a07fd3fcec182)
          * [添加一个新的系统调用](http://showterm.io/4b628301d2d45936a7f8a)
      * [视频演示](http://showdesk.io/50bc346f53a19b4d1f813b428b0b7b49)

  * 代码仓库
      * [https://gitee.com/tinylab/linux-0.11-lab.git][7]
      * [https://github.com/tinyclub/linux-0.11-lab.git][3]

  * 基本特性：
      * 包含所有可用的映像文件: ramfs/floppy/hard disk image。
      * 轻松支持 qemu 和 bochs，可通过配置 tools/vm.cfg 切换。
      * 可以生成任何函数的调用关系，方便代码分析：`make cg f=func d=file|dir`
      * 通过 Docker Toolbox 或 Docker CE 支持所有系统：Linux、Windows 和 Mac OSX。
      * 支持最新的编译器和调试器，可直接用 Qemu/Bochs + gdb 调试
      * 在解压之前整个大小只有 30M
      * 支持 Docker 一键构建
      * 可通过 Web 直接访问

## 相关文章

  * [五分钟内搭建 Linux 0.11 的实验环境][4]
  * [基于 Docker 快速构建 Linux 0.11 实验环境][5]

## 五分钟教程

注：不再推荐如下方式使用 Linux 0.11 Lab，请参考 [基于 Docker 快速构建 Linux 0.11 实验环境][5]，基于 Docker，可以轻松在 Windows，Linux 和 Mac OSX 下使用 Linux 0.11 Lab。

### 准备

以 Ubuntu 和 Qemu 为例, 对于 Mac OS X 和 Bochs 的用法，请参考 [README.md][2].

    apt-get install vim cscope exuberant-ctags gcc gdb binutils qemu lxterminal

更多可选工具：
 
    apt-get install bochs vgabios bochsbios bochs-doc bochs-x libltdl7 bochs-sdl bochs-term
    apt-get install graphviz cflow

### 下载

    git clone https://gitee.com/tinylab/linux-0.11-lab.git

    Or

    git clone https://gitee.com/tinylab/linux-0.11-lab.git
    

### 编译

    make
    

### 从硬盘启动

    make start-hd
    

### 调试

打开一个终端并启动进入调试模式:

    make debug-hd

### 获得帮助

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
    

### 生成 main 函数调用关系

    make cg
    ls calltree/linux-0.11.jpg
    

See:

![Linux 0.11 Calltree][6]

### 演示图片

![Linux 0.11 Lab][7]

## 视频演示

<iframe src="http://showdesk.io/50bc346f53a19b4d1f813b428b0b7b49/?f=1" width="100%" marginheight="0" marginwidth="0" frameborder="0" scrolling="no" border="0" allowfullscreen></iframe>

 [1]: http://www.oldlinux.org/download/clk011c-3.0.pdf
 [2]: https://gitee.com/tinylab/linux-0.11-lab/blob/master/README.md
 [3]: https://github.com/tinyclub/linux-0.11-lab
 [7]: https://gitee.com/tinylab/linux-0.11-lab
 [4]: /take-5-minutes-to-build-linux-0-11-experiment-envrionment/
 [5]: /build-linux-0-11-lab-with-docker/
 [6]: /wp-content/uploads/2015/03/linux-0.11.jpg
 [7]: /wp-content/uploads/2015/03/linux-0.11-lab.jpg
