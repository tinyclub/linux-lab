---
layout: post
author: 'Zhao Bin'
title: "嵌入式 Linux 法律问题"
album: "嵌入式 Linux 知识库"
group: translation
permalink: /embedded-linux-legal-issues/
description: "本文描述了嵌入式领域中使用 Linux 相关的法律问题。"
category:
  - GPL
tags:
  - Linux
  - 版权
  - 法律
  - Signed-Off-By
  - CopyLeft
  - EXPORT_SYMBOL_GPL
---

> 书籍：[嵌入式 Linux 知识库](http://tinylab.gitbooks.io/elinux)
> 原文：[eLinux.org](http://eLinux.org/Legal_Issues "http://eLinux.org/Legal_Issues")
> 翻译：[@zxqhbd](https://github.com/zxqhbd)
> 校订：[@lzufalcon](https://github.com/lzufalcon)

## 嵌入式中使用 Linux 的法律问题


使用 GPL 许可证的复杂性已经在很多其他论坛中被多次的讨论过了。
以下是几个突出问题：


### 内核只被 GPL V2 许可

Linux 内核只在 GNU 通用公共许可协议 2.0 版本下被许可！

这个与许多其他项目不同，它们使用的默认用词允许 GPL V2  或者后期版本。这意味着 Linux 内核不会切换到 GPL V3 版本。

2006 年 9 月，当 GPL V3 起草时，一群内核开发者签署了一个立场声明，表明他们反对 GPL V3 。这更加表明了内核不可能改用 GPL V3 协议。


### 署名行 (signed-off-by) 和原创开发者证书 (DCO)

当开发者为内核贡献代码时，他们必须提供一个署名行 (signed-off-by)，表明他们承认那份开源协议并声明他们所做工作（据他们所知）为原创或者是兼容 GPL V2 许可的某些内容的衍生品。

查看[原创开发者证书][1]，包含在内核的 [Documentation/SubmittingPatches][2] 文件中。

[1]:http://elinux.org/Developer_Certificate_Of_Origin "原创开发者证书"
[2]:http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/Documentation/SubmittingPatches "SubmittingPatches"


### 有关法律分析和合规的资源

* 自由软件法律中心针对 GPL 有一份合规指南，很有用：
  + <http://www.softwarefreedom.org/resources/2014/SFLC-Guide_to_GPL_Compliance_2d_ed.pdf> - 2014 年 10 月

  + 注意不是所有人都同意这份文件中的所有法律解释，但总体而言，这是一份很好的资源

* 有关 copyleft 和 GNU 的通用公共许可协议的一份全面教程和指南：
   * <http://www.copyleft.org/guide/comprehensive-gpl-guide.html#comprehensive-gpl-guidepa1.html>


## EXPORT\_SYMBOL\_GPL


### 针对内核 USB API 的 EXPORT_SYMBOL_GPL

在 2008 年的 1 月，Greg Kroah Hartman 提交了一个补丁将核心 USB API 改变为 `EXPORT_SYMBOL_GPL`。这里是一些关于这个补丁的信息：

* [USB：将 USB 驱动标记为只被 GPL 许可 (LWN.net)][3]
* [Linux 2.6.25 版本没有 USB 闭源驱动 (Linux 杂志)][4]
* [在内核版本 2.6.25 中的 USB 驱动只受 GPL 许可 (Linux 世界)][5]
* [实际的 git commit][6]

[3]:http://lwn.net/Articles/266724/ "USB"
[4]:http://www.linux-magazine.com/Online/News/Linux-2.6.25-without-Closed-Source-USB-Drivers "Linux magazine"
[5]:http://www.networkworld.com/category/opensource-subnet/?q=taxonomy/term/24 "Linux world"
[6]:http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=782e70c6fc2290a0395850e8e02583b8b62264d8 "actual commit"

## 二进制专有的内核模块

在嵌入式 Linux 领域中一个很重要的，也是比较显著的一个法律问题就是二进制（非 GPL）内核模块是否违反 Linux 内核 GPL 协议。关于这个话题有不同的观点。
下面有一篇文章，包含了一些有趣的信息：

* [支持闭源模块之第一部分：版权和软件][7]
* [支持闭源模块之第二部分：法律和模块接口][8]
* [支持闭源模块之第三部分：消除 API 更新税][9]
  

[7]:http://www.networkworld.com/article/2301697/smb/encouraging-closed-source-modules-part-1--copyright-and-software.html "part 1"
[8]:http://www.networkworld.com/article/2301698/smb/encouraging-closed-source-modules-part-2--law-and-the-module-interface.html "part 2"
[9]:http://www.networkworld.com/article/2301701/smb/encouraging-closed-source-modules-part-3--elimating-the--api-update-tax-.html "part 3"

## 在用户空间中使用内核头文件

允许用户空间使用内核头文件是为了方便用户空间程序通过普通的系统调用与内核进行交互。这个被许可并且不会导致用户空间成为内核的衍生品并受限于 GPL 协议。

一般情况下，头文件的使用不会产生衍生品，尽管也会有例外。过去对于头文件中包含了多少代码量（例如代码行数）有投入很多的关注，但是现如今大家都不太关心这个问题了，并且几乎从来不是一个问题。理查德．斯托曼曾表示，针对数据结构，常量还有枚举类型（甚至小内联）的头文件的使用都不会产生衍生品。请看：
<http://lkml.indiana.edu/hypermail/linux/kernel/0301.1/0362.html>

用户空间中内核头文件的使用是预料中的也是常见的。它明确的说明了非 GPL 软件使用这些文件，不会受 GPL 协议的影响。为了安抚直接使用头文件的担心，还有防止内核内部信息泄露给用户空间（可能会被滥用），主线内核开发者给内核构建系统增加了一个选项，专门提供了一个“净化过的”头文件，这些头文件被认为可以安全用于用户空间程序，不会产生许可问题。

这些是在内核构建系统中 `make headers_check` 和 `make headers_install` 的目标。

一般使用下，使用这些被净化过的头文件是合法安全的（也就是说，头文件被特别地去除了大内联宏或者任何用户空间不需要的内容）。
这篇文章解释了如何用内核构建系统来创建净化过的内核头文件：
 <http://darmawan-salihun.blogspot.jp/2008/03/sanitizing-linux-kernel-headers-strange.html>

需要注意的是，Android 操作系统开发者是使用不同的过程来为他们的系统净化 bionic 头文件。他们的过程与主线头文件净化特性差不多同时开始。


## 其它链接

* <http://gpl-violations.org/>	— 这个 gpl-violations.org 项目试图解决 GPL  违规和增强 GPL 合规性的公共意识

* <http://www.softwarefreedom.org/> — 自由软件法律中心为开源项目提供法律代表并发布围绕开源相关的法律问题信息

* <http://www.linuxfoundation.org/programs/legal/compliance> — Linux   基金会的开放合规计划

* <http://www.binaryanalysis.org/> — 一个针对二进制进行分析的工具，用于调查 GPL 合规性

* <http://lwn.net/Articles/386280/> — LWN.net 上一篇关于二进制分析工具的文章（发表于 2010/05/06）

* <http://fossology.org/> —fossology 是一个框架用来扫描开源代码：它目前扫描版权和许可证信息，并能够很容易的进行扩展

[分类](http://eLinux.org/Special:Categories "Special:Categories"):

-   [开放源码许可](http://eLinux.org/Category:OpenSource_Licensing "Category:OpenSource Licensing")
