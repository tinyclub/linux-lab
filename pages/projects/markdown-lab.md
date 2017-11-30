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

## 项目描述

该项目致力于快速构建一个基于 Docker 的 Markdown 文档编辑环境。

  * 使用文档：[README.md][2]
  * 在线实验：<http://tinylab.cloud:6080/labs>
  * 在线演示：<http://showterm.io/1809186b57f904d51aeff>
  * 代码仓库：[https://github.com/tinyclub/markdown-lab.git][3]
  * 基本特性：
      * 基于 Docker，一键安装，几分钟内就可构建，节约生命，生命，生命。
      * 直接通过 Web 访问，非常便捷，便捷，便捷。
      * 基于 Markdown，并内建书、简历、文档和幻灯片的主题模板，可专心内容创作。
      * 通过 Docker Toolbox 和 Docker CE 支持所有系统：Linux、Windows 和 Mac OSX

## 五分钟教程

### 准备

在实验之前，请先参考下面文档安装好 Docker。

* Linux 和 Mac 系统：[Docker CE](https://store.docker.com/search?type=edition&offering=community)
* Windows 系统：[Docker Toolbox](https://www.docker.com/docker-toolbox)

安装完 docker 后如果想免 `sudo` 使用 linux lab，请务必把用户加入到 docker 用户组并重启系统。

    $ sudo usermod -aG docker $USER

由于 docker 镜像文件比较大，有 1G 左右，下载时请耐心等待。另外，为了提高下载速度，建议通过配置 docker 更换镜像库为本地区的，更换完记得重启 docker 服务。

    $ grep registry-mirror /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --registry-mirror=https://docker.mirrors.ustc.edu.cn"
    $ service docker restart

如果 docker 默认的网络环境跟本地的局域网环境地址冲突，请通过如下方式更新 docker 网络环境，并重启 docker 服务。

    $ grep bip /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --bip=10.66.0.10/16"
    $ service docker restart

请务必注意，通过 Docker Toolbox 安装的 `default` 系统中默认的 `/root` 目录仅仅挂载在内存中，关闭系统后数据会丢失，请千万不要用它来保存实验数据。可以使用另外的目录来存放，比如 `/mnt/sda1`，它是在 Virtualbox 上外挂的一个虚拟磁盘镜像文件，默认有 17.9 G，足够存放常见的实验环境。

### 工作目录

再次提醒，在 Linux 或者 Mac 系统，可以随便在 `~/Downloads` 或者 `~/Documents` 下找一处工作目录，然后进入，比如：

    $ cd ~/Documents

但是如果使用的是 Docker Toolbox 安装的 `default` 系统，该系统默认的工作目录为 `/root`，它仅仅挂载在内存中，因此在关闭系统后所有数据会丢失，所以需要换一处上面提到的 `/mnt/sda1`，它是外挂的一个磁盘镜像，关闭系统后数据会持续保存。

    $ cd /mnt/sda1

### 下载

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab/ && tools/docker/choose markdown-lab

### 安装

Docker 安装：

    $ tools/docker/pull    # Pull from docker hub
    or
    $ tools/docker/build   # Build from source

    
    $ tools/docker/run

通过 Docker 安装后，上述命令或者 `tools/docker/vnc` 会打开一个 VNC 页面，从控制台日志中获取密码并登陆后，会看到桌面的 "Markdown Lab" 图标，点击后即可进入操作终端。

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
    $ gitbook install
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
