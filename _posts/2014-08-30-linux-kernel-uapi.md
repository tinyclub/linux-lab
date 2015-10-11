---
title: Linux Kernel UAPI
author: Wen Pingbo
layout: post
permalink: /faqs/linux-kernel-uapi/
tags:
  - Header
  - UAPI
  - Linux
categories:
  - 内核函数库
---
  * 问题描述

    从3.5开始，Linux Kernel 里多了一个 uapi 文件夹，里面放了很多 Linux Kernel 各个模块的头文件。如果是第一次碰到，可能会对这个不是很了解。

  * 问题分析

    Linux Kernel 中新增的这些 uapi 头文件，其实都是来自于各个模块原先的头文件，最先是由 David Howells 提出来的。uapi 只是把内核用到的头文件和用户态用到的头文件分开。

  * 解决方案

    在 3.5 之前，Linux Kernel 的头文件一般是这样的：

        /* Header comments (copyright, etc.) */
        
        #ifndef _XXXXXX_H
        #define _XXXXXX_H
        
        [User-space definitions]
        
        #ifdef __KERNEL__
        
        [Kernel-space definitions]
        
        #endif /* __KERNEL__ */
        
        [User-space definitions]
        
        #endif


    而在 3.5 之后，这样一个头文件就会被分为两个：

        .filename.h
        /* Header comments (copyright, etc.) */
        #ifndef XXXX_H
        #define XXXX_H
        
        #include &lt;include/uapi/path/to/header.h>
        
        [Kernel-space definitions]
        
        #endif
        
        ./uapi/filename.h
        /* Header comments (copyright, etc.) */
        
        #ifndef _UAPI_XXXX_H
        #define _UAPI_XXXX_H
        
        [User-space definitions]
        
        #endif


    这样做有什么好处呢？一个是解决 Linux Kernel 里的交叉引用，另外一个就是方便用户态的开发者，可以简单的查看 uapi 里的代码变化来确定 Linux Kernel 是否改变了系统 API。

    参考资料：

      * http://lwn.net/Articles/507832/
      * http://lwn.net/Articles/507794/
