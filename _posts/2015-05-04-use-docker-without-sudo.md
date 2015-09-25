---
title: 如何免 sudo 使用 docker
author: Wu Zhangjin
layout: post
permalink: /use-docker-without-sudo/
tags:
  - Docker
  - sudo
categories:
  - Linux
  - Virtualization
---

> by Falcon of [TinyLab.org][1]
> 2015/05/02


## 简介

默认安装完 docker 后，每次执行 docker 都需要运行 sudo 命令，非常浪费时间影响效率。如果不跟 sudo，直接执行 `docker images` 命令会有如下问题：

> FATA[0000] Get http:///var/run/docker.sock/v1.18/images/json: dial unix /var/run/docker.sock: permission denied. Are you trying to connect to a TLS-enabled daemon without TLS?

于是考虑如何免 sudo 使用 docker，经过查找资料，发现只要把用户加入 docker 用户组即可，具体用法如下。

## 免 sudo 使用 docker

  * 如果还没有 docker group 就添加一个：

        sudo groupadd docker


  * 将用户加入该 group 内。然后退出并重新登录就生效啦。

        sudo gpasswd -a ${USER} docker


  * 重启 docker 服务

        sudo service docker restart


  * 切换当前会话到新 group 或者重启 X 会话

        newgrp - docker

        OR

        pkill X


注意，最后一步是必须的，否则因为 `groups` 命令获取到的是缓存的组信息，刚添加的组信息未能生效，所以 `docker images` 执行时同样有错。

## 原因分析

  * 因为 `/var/run/docker.sock` 所属 docker 组具有 setuid 权限

        $ sudo ls -l /var/run/docker.sock
        srw-rw---- 1 root docker 0 May  1 21:35 /var/run/docker.sock






 [1]: http://tinylab.org
