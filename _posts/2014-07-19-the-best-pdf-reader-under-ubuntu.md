---
title: Ubuntu 下最佳 pdf 阅读器
author: Wu Zhangjin
layout: post
permalink: /the-best-pdf-reader-under-ubuntu/
tags:
  - acroread
  - evince
  - pdf reader
  - Ubuntu
  - xpdf
  - 原理图
categories:
  - Ubuntu
---
  * 问题描述

    在阅读pdf格式的原理图时，用过自带的evince, 也安装过xpdf和FoxitReader, 发现在搜索特定字符和链接跳转方面，都让人抓狂，后两个更差劲。

  * 问题分析

    通过查看手册，解决了evince的搜索字符显示问题。因为这个工具默认会把搜索到的字符背景加黑，如果原理图的背景是黑色，那么即使跳转到了搜索的页面，那么你也看不到字符的位置。

    evince的手册页提到，按照提示点击：`View -> Inverted Colors`就会把背景改为白色，这样搜索到内容以后，字符会被被色标记出来，比较容易看到。

    > Invert colors on a page:
    >
    > To swap black for white, white for black, and so on, click View ▸ Inverted Colors.

    不过，evince的文档内链接跳转真是让人难以忍受，点击链接后不会自动跳到目标页面，而是把整个文档显示自动设置为50%的大小显示，不知道跳到什么位置了。

  * 解决方案

    最佳最好体验的还是要传统PDF编辑器老大的acroread，这个阅读器非常完美地解决了字符搜索与文档内链接跳转的显示问题：

      * 字符搜索

        如果显示字符够大会自动居中显示，如果字符太小，外面会用白色框框起来，非常人性化。

      * 文档内链接跳转

        自动跳转到所在页面，并且把跳转的目标页和相应内容放到显示，非常人性化。

    下面让我们安装它：

        $ apt-get install acroread
