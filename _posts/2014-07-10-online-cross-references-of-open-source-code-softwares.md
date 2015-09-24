---
title: 开源软件在线代码交叉检索
author: Wu Zhangjin
layout: post
permalink: /online-cross-references-of-open-source-code-softwares/
views:
  - 122
tags:
  - Android
  - Linux
  - LXR
  - OpenGrok
categories:
  - Computer Language
---

> by falcon of [TinyLab.org][2]
> 2014/07/10

为了方便快捷地查看代码，我们经常会使用诸如命令行工具cscope, ctags或者图形化的IDE，如qtcreator, source insight, eclipse等。

不过，本地查阅有一些局限性，比如说需要先把代码下载下来，还需要建立索引的额外开销。如果仅仅是为了查看和阅读一些现有的代码，则可以直接使用在线的一些开放交叉检索工具，例如：

* Android: [AndroidXRef][3]

  AndroidXRef in an independent project aimed to assist developers working with Android Internals.

* Linux: [LXR][4]

  LXR (formerly &#8220;the Linux Cross Referencer&#8221;) is a software toolset for indexing and presenting source code repositories. LXR was initially targeted at the Linux source code, but has proved usable for a wide range of software projects. lxr.linux.no is currently running an experimental fork of the LXR software.

* More: [Metager Xref][5]

  上面有大部分开源软件的交叉索引数据。

你也可以通过 [LXR][6] 或者 [OpenGrok][7] 在本地创建其他软件的交叉索引，或者如果有空闲的服务器，也可以为业界提供某些开源软件的免费检索服务。





 [2]: http://tinylab.org
 [3]: http://androidxref.com/
 [4]: http://lxr.linux.no/
 [5]: http://code.metager.de/source/xref/
 [6]: http://sourceforge.net/projects/lxr/
 [7]: http://opengrok.github.io/OpenGrok/
