---
layout: post
author: 'Wu Zhangjin'
title: "单个程序 Size 优化之压缩后自解压执行"
draft: false
top: true
license: "cc-by-nc-nd-4.0"
permalink: /program-size-opt-with-upx/
description: "本文介绍了一款优化程序 Size 的工具，它通过压缩程序后加入自解压代码允许压缩后的程序直接执行。"
category:
  - 系统裁剪
tags:
  - upx
  - 自解压
---

> By Falcon of [TinyLab.org][1]
> Dec 09, 2019

前面讨论[系统裁剪](http://tinylab.org//linux-product-evaluate-size-and-boot/)的时候，提到了内核和文件系统的压缩支持，实际上单个可执行文件也可以这样做。

基本原理跟内核压缩一样，就是先把 vmlinux 压缩一遍，然后把压缩完的内核作为新程序的一部分，在新程序的开头加上解压和执行代码。

这样的解决方案有 UPX，完全开源：

* 首页：[UPX: the Ultimate Packer for eXecutables - Homepag...](https://upx.github.io/)
* 源码：[GitHub - upx/upx: UPX - the Ultimate Packer for eX...](https://github.com/upx/upx)

需要注意的是，实际使用中，需要保证压缩率产生的收益比加上额外的解压代码要高，否则就没意义。

下面来用一用：

    $ sudo apt-get install upx-ucl

    $ ls -lh /bin/ls
    -rwxr-xr-x 1 root root 124K Mar  3  2017 /bin/ls

    $ upx ls
    Ultimate Packer for eXecutables

    File size   Ratio   Format    Name
    ------------   ------   ---------   -----------
    126584->57188 45.18% linux/ElfAMD ls

    Packed 1 file.

    $ ls -lh ls
    -rwxr-xr-x 1 falcon falcon 56K Aug 25 12:48 ls

压缩了有超过 50%。UPX 的压缩成绩是 50~70%，比 gzip 要好，关键是，这个压缩完还是可以执行的。

在内核中类似这样用时间换空间的做法很多，还有 @甜质粥  之前分享的 zram：

* [Linux Swap 与 Zram 详解](http://tinylab.org/linux-swap-and-zram/)

[1]: http://tinylab.org
