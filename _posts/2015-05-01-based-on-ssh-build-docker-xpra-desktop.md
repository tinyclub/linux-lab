---
title: 基于 ssh + Xpra 构建 Docker 桌面系统
author: Wu Zhangjin
layout: post
permalink: /based-on-ssh-build-docker-xpra-desktop/
tags:
  - Desktop
  - Docker
  - ssh
  - Xpra
  - 桌面系统
categories:
  - Linux
  - Virtualization
---

> by Falcon of [TinyLab.org][1]
> 2015/05/01


## Docker 桌面系统

初识 Docker，发现大部分文章都只是介绍非 GUI 的应用。想到蛮多场景需要图形化界面，所以搜罗了一下 Docker 镜像：

<pre>$ sudo docker search desktop
NAME                                    DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
dorowu/ubuntu-desktop-lxde-vnc          Ubuntu with openssh-server and NoVNC on po...   12                   [OK]
rogaha/docker-desktop                   Docker Desktop enables you to create virtu...   10                   [OK]
</pre>

发现前两名分别是：

  * [dorowu/ubuntu-desktop-lxde-vnc][2]：基于 VNCServer + [noVNC][3] 项目
  * [rogaha/docker-desktop][4]：基于 Ssh + [Xpra][5] 项目

初步试用后发现两者都非常 Cool，一个基于 Web，一个基于传统的图形界面。笔者将写两篇文章分别介绍它们，首先介绍第二个。

## Xpra 初识

> Xpra is &#8216;screen for X&#8217;, and more: it allows you to run X programs, usually on a remote host and direct their display to your local machine. It also allows you to display existing desktop sessions remotely.
>
> Xpra is &#8220;rootless&#8221; or &#8220;seamless&#8221;, and sessions can be accessed over SSH, or password protected and encrypted over plain TCP sockets.

## 安装镜像：rogaha/docker-desktop

<pre>$ sudo docker pull rogaha/docker-desktop
</pre>

## 启动容器

<pre>$ CONTAINER_ID=$(sudo docker run -d -p 2222:22 rogaha/docker-desktop)
</pre>

**注**：`-p 2222:22` 把容器内的 Ssh 端口地址 22 映射到主机的 2222 端口。

## 获取登陆密码

<pre>$ echo $(sudo docker logs $CONTAINER_ID | sed -n 1p)
User: docker Password: aefieSahk2ci
</pre>

密码为 `Password` 后面的字符串。

**注**：该镜像通过 `pwgen` 随机产生了一个登陆密码，见 [startup.sh][6]。

## 连接桌面服务

### 通过 Ssh 启动一个 Xpra 会话

执行如下命令并输入上述密码即可：

<pre>$ ssh docker@192.168.56.102 -p 2222 "sh -c './docker-desktop -s 800x600 -d 10 > /dev/null 2>&#038;1 &#038;'"
</pre>

**注**：

  * `-p 2222` 连上 docker 那边的 ssh 服务
  * `-s 800x600` 设置桌面的分辨率
  * `-d 10` 设置显示服务会话编号

### 通过 Xpra Attach 上述会话

这里会真正拉起图形界面。

<pre>$ xpra --ssh="ssh -p 2222" attach ssh:docker@0.0.0.0:10
</pre>

### 注意事项

有其他文章介绍上述两步可直接通过如下命令加载：

<pre>ssh -Yc blowfish docker@0.0.0.0 -p 2222 ./docker-desktop -s 800x600 -d 11
</pre>

但实际上已经无法工作，会出现如下错误然后自动退出。

> Entering daemon mode; any further errors will be reported to:
>
> /home/docker/.xpra/:11.log

通过搜索，发现该镜像作者已经告知必须采用两步操作才能正常工作，具体见：[Error after login: connection failed: [Errno 2] No such file or directory][7]。

## 启动效果

![Docker Desktop with Ssh + Xpra][8]

## 自主构建

可直接拉下该镜像的 Dockerfile 和相关文件，自主构建。甚至根据自身需求，调整 Dockerfile 后再构建，以便满足实际需求。

<pre>$ git clone https://github.com/rogaha/docker-desktop.git
$ cd docker-desktop
$ docker build -t tinylab/docker-desktop .
</pre>

## 参考资料

  * [rogaha/docker-desktop][4]





 [1]: http://tinylab.org
 [2]: https://github.com/fcwu/docker-ubuntu-vnc-desktop
 [3]: https://kanaka.github.io/noVNC/
 [4]: https://github.com/rogaha/docker-desktop
 [5]: http://xpra.org/
 [6]: https://raw.githubusercontent.com/rogaha/docker-desktop/master/startup.sh
 [7]: https://github.com/rogaha/docker-desktop/issues/24
 [8]: /wp-content/uploads/2015/05/docker-desktop-with-ssh+xpra.jpg
