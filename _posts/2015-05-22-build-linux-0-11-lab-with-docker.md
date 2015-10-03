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

下文要求已经安装 git 和 docker，如果没有安装请首先安装：

  * 安装 git

        $ sudo apt-get install git


  * 安装 docker

        $ sudo apt-get install software-properties-common # 增加 add-apt-repository 命令
        $ sudo apt-get install python-software-properties
        $ sudo add-apt-repository ppa:dotcloud/lxc-docker # 增加一个ppa源，如：ppa:user/ppa-name
        $ sudo apt-get -y update
        $ sudo apt-get install lxc-docker


## 拉下 Linux 0.11 实验环境

    $ git clone https://github.com/tinyclub/linux-0.11-lab.git


## 通过 Docker 构建一个独立的实验环境

    $ cd linux-0.11-lab
    $ docker build -t tinylab/linux-0.11-lab ./


## 启动装有实验环境的 Docker 容器

    $ CONTAINER_ID=$(docker run -d -p 6080:6080 dorowu/ubuntu-desktop-lxde-vnc)


## 获得实验环境的密码

    $ docker logs $CONTAINER_ID | sed -n 1p
    User: ubuntu Pass: ubuntu


**注**：登录密码为 `Pass` 之后的字符串，这里为 `ubuntu`。

## 远程登录实验环境

  * 在本地宿主机登录
      * http://localhost:6080/vnc.html

  * 远程登录

      * 获得实验环境所属容器的 IP 地址

            $ docker exec $CONTAINER_ID ifconfig eth0 | grep "inet addr:"
            inet addr:172.17.0.1  Bcast:0.0.0.0  Mask:255.255.0.0


      * 访问地址：`http://172.17.0.1:6080/vnc.html`

## 简单使用

登录后，无须再额外安装任何工具，因为刚才在构建 Docker 容器时就已经默认安装好。所以用法与 [五分钟内搭建 Linux 0.11 的实验环境][2] 稍有差异。基本步骤如下：

  * 登录后，通过左下角的启动菜单，找到 `Accessories`，再打开控制台 `LXTerminal`
  * 进入实验环境所属目录：`cd /linux-0.11-lab`
  * 进行各种开发与调试动作
      * 例如：`make start-hd`
      * 也可切换 bochs 启动，例如：`echo bochs > tools/vm.cfg; make start-fd`
  * 更多用法请参考：`make help`

效果如下：

![Linux 0.11 Lab with Docker][4]





 [1]: http://tinylab.org
 [2]: /take-5-minutes-to-build-linux-0-11-experiment-envrionment/
 [3]: http://boot2docker.io/
 [4]: /wp-content/uploads/2015/05/linux-0.11-lab-with-docker-vncserver+novnc.jpg
