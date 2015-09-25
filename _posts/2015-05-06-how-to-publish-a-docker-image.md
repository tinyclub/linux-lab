---
title: 如何发布 docker 镜像到公有仓库
author: Wu Zhangjin
layout: post
permalink: /how-to-publish-a-docker-image/
tags:
  - Docker
  - Dockerfile
  - 发布
categories:
  - Linux
  - Virtualization
---

> by Falcon of [TinyLab.org][1]
> 2015/05/02


## 简介

如果准备好了一份非常酷的 docker 镜像，想分享给其他同学，那么有两种方式，一种是把 Dockerfile 放到 Github 等公有代码仓库中，另外一种方式是直接把编译好的镜像上传到 Docker 镜像的公有库：<https://registry.hub.docker.com/>。

如果只是希望分享给企业或者团队内部，则可以建立自己的私有库并发布上去，这里可以参考：[Docker介绍以及Registry的安装][2]。

本文只介绍如何把镜像发布到公有 Docker 镜像库。

## 注册 Docker 公有库帐号

访问这里 <https://registry.hub.docker.com/> 并注册帐号。

## 在本地准备好镜像

以 [Linux 0.11 Lab][3] 为例，下载带有 Dockerfile 的 Linux-0.11 Git 仓库并基于 Dockerfile 构建一个独立的 Linux 0.11 实验环境。

<pre>$ git clone https://github.com/tinyclub/linux-0.11-lab.git
$ cd linux-0.11-lab
$ docker build -t tinylab/linux-0.11-lab ./
$ docker images | grep linux-0.11
tinylab/linux-0.11-lab           latest              7880de82c885        31 minutes ago      1.083 GB
</pre>

## 发布镜像

<pre>$ git push tinylab/linux-0.11-lab
</pre>

按照提示输入上面注册的帐号、密码和邮箱地址即可。





 [1]: http://tinylab.org
 [2]: http://dockerone.com/article/108
 [3]: /linux-0-11-lab/
