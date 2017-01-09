---
title: 基于 Docker 快速构建 Linux 0.11 实验环境
author: Wu Zhangjin
layout: post
permalink: /build-linux-0-11-lab-with-docker/
tags:
  - Dockerfile
  - Linux
  - 实验环境
  - 操作系统
categories:
  - Linux 0.11
  - Docker
---

> by Falcon of [TinyLab.org][1]
> 2015/05/02


## 简介

[五分钟内搭建 Linux 0.11 的实验环境][2]介绍了如何快速构建一个 Linux 0.11 实验环境。

本文介绍如何快速构建一个独立于宿主机的 Linux 0.11 实验环境，该实验环境可以用于任何操作系统的宿主开发机，将非常方便各类学生学习 Linux 0.11，本文只介绍 Ubuntu。在 Windows 和 Mac 下可以用 VirtualBox + [Boot2Docker][3] 来启动。

## 拉下 Linux 0.11 实验环境

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab && tools/docker/choose linux-0.11-lab

## 通过 Docker 构建一个独立的实验环境

    $ tools/docker/pull         # Pull from docker hub
    or
    $ tools/docker/build        # Build from source

## 启动装有实验环境的 Docker 容器

    $ tools/docker/run


## 远程登录实验环境

上面的命令会打开一个 VNC 登陆界面，从控制台的日志中获取密码并登录即可。

之后也可以直接通过 `tools/docker/vnc` 来启动 VNC 页面。

## 简单使用

登录后，无须再额外安装任何工具，因为刚才在构建 Docker 容器时就已经默认安装好。所以用法与 [五分钟内搭建 Linux 0.11 的实验环境][2] 稍有差异。基本步骤如下：

  * 登录后，通过左下角的启动菜单，找到 `Accessories`，再打开控制台 `LXTerminal`
  * 进入实验环境所属目录：`cd /linux-0.11-lab`
  * 进行各种开发与调试动作
      * 例如：`make start-hd`
      * 也可切换 bochs 启动，例如：`make switch; make start-fd`
  * 更多用法请参考：`make help`

效果如下：

![Linux 0.11 Lab with Docker][4]





 [1]: http://tinylab.org
 [2]: /take-5-minutes-to-build-linux-0-11-experiment-envrionment/
 [3]: http://boot2docker.io/
 [4]: /wp-content/uploads/2015/05/linux-0.11-lab-with-docker-vncserver+novnc.jpg
