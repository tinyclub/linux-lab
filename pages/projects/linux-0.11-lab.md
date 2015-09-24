---
title: 'Linux-0.11-Lab: 五分钟实验环境'
author: Wu Zhangjin
layout: page
permalink: /linux-0.11-lab/
views:
  - 320
---

## 项目描述

该项目致力于快速构建一个 Linux 0.11 实验环境，可配合[《Linux内核完全注释》][1] 一书使用。

  * 使用文档： [README.md][2]
  * 代码仓库：[https://github.com/tinyclub/linux-0.11-lab.git][3]
  * 基本特性： 
      * 包含所有可用的映像文件: ramfs/floppy/hard disk image。
      * 轻松支持 qemu 和 bochs，可通过配置 tools/vm.cfg 切换。
      * 可以生成任何函数的调用关系，方便代码分析：`make cg f=func d=file|dir`
      * 支持 Ubuntu 和 Mac OS X，在 VirtualBox 的支持下也可以在 Windows 上工作。
      * 测试过的编译器: Ubuntu: gcc-4.8， Mac OS X：i386-elf-gcc 4.7.2
      * 在解压之前整个大小只有 30M

## 相关文章

  * [五分钟内搭建 Linux 0.11 的实验环境][4]
  * [基于 Docker 快速构建 Linux 0.11 实验环境][5]

## 五分钟教程

### 准备

以 Ubuntu 和 Qemu 为例, 对于 Mac OS X 和 Bochs 的用法，请参考 [README.md][2].

    apt-get install vim cscope exuberant-ctags build-essential qemu
    

### 下载

    git clone https://github.com/tinyclub/linux-0.11-lab.git
    

### 编译

    make
    

### 从硬盘启动

    make start-hd
    

### 调试

打开一个终端并启动进入调试模式:

    make debug-hd
    

打开另外一个终端启动 gdb 开始调试:

    gdb images/kernel.sym
    (gdb) target remote :1234
    (gdb) b main
    (gdb) c
    

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




 [1]: http://www.oldlinux.org/download/clk011c-3.0.pdf
 [2]: https://github.com/tinyclub/linux-0.11-lab/blob/master/README.md
 [3]: https://github.com/tinyclub/linux-0.11-lab
 [4]: /take-5-minutes-to-build-linux-0-11-experiment-envrionment/
 [5]: /build-linux-0-11-lab-with-docker/
 [6]: /wp-content/uploads/2015/03/linux-0.11.jpg
