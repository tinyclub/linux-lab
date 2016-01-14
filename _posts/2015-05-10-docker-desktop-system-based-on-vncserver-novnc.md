---
title: 基于 VNCServer + noVNC 构建 Docker 桌面系统
author: Wu Zhangjin
layout: post
permalink: /docker-desktop-system-based-on-vncserver-novnc/
tags:
  - noVNC
  - VNCServer
  - 桌面系统
  - Linux
categories:
  - Docker
---

> by Falcon of [TinyLab.org][1]
> 2015/05/02


## 简介

[基于 ssh + Xpra 构建 Docker 桌面系统][2] 刚介绍了如何通过 Ssh + [Xpra][3] 构建 C/S 架构的 Docker 桌面系统。

本文介绍另外一种 B/S 架构的 Docker 桌面系统，即基于 VNCServer + [noVNC][4] 构建一个可以通过浏览器直接访问的 Docker 桌面系统。

## noVNC

VNCServer 是一个为了满足分布式用户共享服务器资源，而在服务器开启的一项服务，对应的客户端软件有图形化客户端 VNCViewer，而 noVNC 则是 HTML5 VNC 客户端，它采用 HTML 5 WebSockets, Canvas 和 JavaScript 实现。

noVNC 被普遍用在各大云计算、虚拟机控制面板中，比如 OpenStack Dashboard 和 OpenNebula Sunstone 都用的是 noVNC。noVNC 采用 WebSockets 实现，但是当前蛮多 VNC 服务器都不支持 WebSockets，所以 noVNC 不能直连 VNC 服务器，而是需要开启一个代理来做 WebSockets 和 TCP sockets 之间的转换。这个代理叫做 websockify。

更多细节请访问末尾的参考资料。

## 下载镜像：fcwu/docker-ubuntu-vnc-desktop

<pre>$ docker pull fcwu/docker-ubuntu-vnc-desktop
</pre>

## 启动容器并加载 VNCServer 服务

<pre>$ CONTAINER_ID=$(docker run -d -p 6080:6080 dorowu/ubuntu-desktop-lxde-vnc)
</pre>

## 获得登录密码

<pre>$ docker logs $CONTAINER_ID | sed -n 1p
User: ubuntu Pass: ubuntu
</pre>

**注**：`Pass` 后的字符串即为密码，这里为 `ubuntu`。

## 通过浏览器登录

测试过的浏览器有 Chrome。访问方式：

  * 本地宿主机访问

      * `http://localhost:6080/vnc.html`

  * 远程访问

      * 先获取 IP 地址

            $ docker exec $CONTAINER_ID ifconfig eth0 | grep "inet addr:"
            inet addr:172.17.0.1  Bcast:0.0.0.0  Mask:255.255.0.0


      * 远程访问：`http://172.17.0.1:6080/vnc.html`

连接后，输入上面获得的密码 `ubuntu` 即可访问。

## 效果图

![Docker desktop with VNCServer + noVNC][5]

## 自主构建

<pre>$ git clone https://github.com/fcwu/docker-ubuntu-vnc-desktop.git
$ cd docker-ubuntu-vnc-desktop
$ docker build -t tinylab/ubuntu-desktop-lxde-vnc .
</pre>

## 参考资料

  * [HTML 5案例研究：使用WebSockets、Canvas与JavaScript构建noVNC客户端][6]
  * [使用 noVNC 开发 Web 虚拟机控制台][7]





 [1]: http://tinylab.org
 [2]: /based-on-ssh-build-docker-xpra-desktop/
 [3]: http://xpra.org/
 [4]: http://kanaka.github.io/noVNC/
 [5]: /wp-content/uploads/2015/05/docker-desktop-with-vncserver+novnc.jpg
 [6]: http://www.infoq.com/cn/news/2010/07/html5-novnc
 [7]: http://www.vpsee.com/2013/07/integrating-novnc-with-our-vm-control-panel/
