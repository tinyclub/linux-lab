---
layout: post
author: 'Wu Zhangjin'
title: "借力 markdown-lab 沉浸式撰写文档"
group: original
album: Markdown 用法详解
permalink: /write-documents-with-markdown-lab/
description: "本文介绍了如何使用 markdown lab 快速搭建 markdown 文档编辑环境并进行各类文档撰写。"
category:
  - Markdown
tags:
  - Markdown Lab
  - 文档撰写
  - Docker
  - 幻灯片
  - Slides
  - Resume
  - 简历
  - 文章
  - Articles
  - Books
  - 书籍
---

> By Falcon of TinyLab.org
> 2016-08-02 14:04:10

## 简介

不知不觉已使用 Markdown 很多年，从早期的 M$ Office，到 LibreOffice，到 Latex，Html，以及各类在线文本编辑工具，再到如今的 [Markdown][10]，才终于找到了文档编辑的最佳助手。

Markdown 本质上彻底解决了内容和样式的纠缠，让我们在撰写内容的时候可以更加专注。至于样式，Markdown 的简洁使得样式的呈现手段多样而且便利，最出名的辅助工具当属 [Pandoc][8]，它可以把 Markdown 转换为包括 Latex, Html, pdf 等各种其他的文档表现形式：[pandoc-templates][9]。

早期用 Markdown 完成了文章、幻灯片、简历和书籍的撰写，相比其他的编辑工具而言，它的每个体验都令人畅快淋漓：

* [用 Markdown 写文档][4]
* [用 Markdown 制作简历][5]
* [用 Markdown 高效地写幻灯片][6]
* [Docker 快速上手：用 Docker + GitBook 写书][7]

但是，令人不堪地是，每次更换系统或者升级电脑，要安装配套的工具还是相当繁琐的。所以，为了消除这些烦恼，Docker 就派上用场了。

这不，实在是忍受不了，前几天赶紧基于 Docker 创建了一套 [Markdown Lab][1]，把所有的环境安装过程简化成一条 Linux 命令，并且为上述每种文档样式提供了预制模板，而且很方便设计师们介入进行模板深度定制。

有了这套 Lab，在省掉很多心力的同时，可以让我们更多地沉浸于内容的创作之中。

## 用法

下面稍微介绍一下超级简单的用法，更多用法请参考：[README.md][2]。

### 准备

以 Ubuntu 为例：

### 下载

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab/ && tools/docker/choose markdown-lab

### 安装

Docker 安装/启动：

    $ tools/docker/pull         # Pull from docker hub
    or
    $ tools/docker/build        # Build from source

    $ tools/docker/run

### 使用

#### 幻灯片

    $ cd slides/
    $ make

如果想调整内容主题（theme）和颜色风格（colortheme），可参考 `slides/doc/` 并在 Makefile 中配置 `latex_theme` 和 `latex_colortheme`。

对于字体，则可打开 `templates/zh_template.tex` 并对 `\set*font` 指定的字体进行配置。字体可从 `fc-list` 结果中选择。

#### 简历

    $ cd resume/
    $ make

如果没有明确指明 `gravatar.jpg`，在配置了邮件地址后，如果存在的话，会自动从 gravatar.com 加载头像。

可通过如下方式禁止自动加载：

    $ GRAVATAR_OPTION=--no-gravatar make

对于字体，可类似上面进行配置，但是配置文件在：`templates/header.tex`。

#### 文章

    $ cd article/
    $ make

字体配置同上，也是在 `templates/header.tex`。

#### 书籍

    $ git submodule update --init book
    $ cd book/
    $ make

字体配置可通过 `book.json` 的 `fontFamily` 实现。


[1]: http://tinylab.org/markdown-lab
[2]: https://github.com/tinyclub/markdown-lab/blob/master/README.md
[3]: https://github.com/tinyclub/markdown-lab
[4]: http://tinylab.org/use-markdown-to-write-document/
[5]: http://tinylab.org/write-resume-with-markdown/
[6]: http://tinylab.org/use-markdown-to-write-slides/
[7]: http://tinylab.org/docker-quick-start-docker-gitbook-writing-a-book/
[8]: http://pandoc.org/demo/example19/Pandoc_0027s-Markdown.html
[9]: https://github.com/jgm/pandoc-templates
[10]: http://wowubuntu.com/markdown/
