---
title: 'Markdown 文档编辑环境'
tagline: '快速构建基于 Docker 的 Markdown 文档编辑环境，用于写书、简历、文章和幻灯片。'
author: Wu Zhangjin
layout: page
permalink: /markdown-lab/
description: Markdown 是非常重要的效率工具，可用于写书、简历、文档和幻灯片等日常工具，该项目用于快速构建一个基于 Docker 的 Markdown 文档编辑环境。
update: 2016-06-19
categories:
  - 开源项目
  - Markdown
tags:
  - 文档编辑
  - Gitbook
  - Beamer
  - Docker
  - Resume
  - 简历
  - 文章
  - 幻灯片
  - 书籍
---

<iframe src="http://showterm.io/1809186b57f904d51aeff" style="align:center;width:100%;height:680px;"></iframe>

## 项目描述

该项目致力于快速构建一个基于 Docker 的 Markdown 文档编辑环境。

  * 使用文档：[README.md][2]
  * 代码仓库：[https://github.com/tinyclub/markdown-lab.git][3]
  * 基本特性：
      * 基于 Docker，一键安装，几分钟内就可构建，节约生命，生命，生命。
      * 直接通过 Web 访问，非常便捷，便捷，便捷。
      * 基于 Markdown，并内建书、简历、文档和幻灯片的主题模板，可专心内容创作。

## 五分钟教程

### 准备

以 Ubuntu 为例：

### 下载

    $ git clone https://github.com/tinyclub/markdown-lab.git
    $ cd markdown-lab/

### 安装

本地安装：

    $ sudo tools/install-local-lab.sh

Docker 安装：

    $ sudo tools/install-docker-lab.sh

    or

    $ sudo tools/install-docker.sh
    $ sudo docker pull tinylab/markdown-lab

    
    $ tools/update-lab-uid.sh         # 确保 uid 一致，两边都可操作
    $ tools/update-lab-identify.sh    # 关闭登陆密码，允许无密登陆
    $ tools/run-docker-lab.sh

通过 Docker 安装后，上述命令或者 `tools/open-docker-lab.sh` 会打开一个 VNC 页面，用 'ubuntu' 密码登陆后，会看到桌面的 "Markdown Lab" 图标，点击后即可进入操作终端。

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

## 相关文章

在这之前，本站已经针对 Markdown 有多篇介绍性文章并有多个独立的项目仓库，如今，所有早期代码仓库都已经合并进来，所以之前的相关代码仓库全部废弃并删除。

* [用 Markdown 写文档][4]
* [用 Markdown 制作简历][5]
* [用 Markdown 高效地写幻灯片][6]
* [Docker 快速上手：用 Docker + GitBook 写书][7]

## Demo

![Markdown Lab Demo](/wp-content/uploads/2016/08/30/markdown-lab-demo.jpg)

 [2]: https://github.com/tinyclub/markdown-lab/blob/master/README.md
 [3]: https://github.com/tinyclub/markdown-lab
 [4]: http://tinylab.org/use-markdown-to-write-document/
 [5]: http://tinylab.org/write-resume-with-markdown/
 [6]: http://tinylab.org/use-markdown-to-write-slides/
 [7]: http://tinylab.org/docker-quick-start-docker-gitbook-writing-a-book/
