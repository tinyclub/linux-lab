---
layout: post
author: 'Wu Zhangjin'
title: "如何快速部署云实验环境（Cloud-Lab）"
group: "original"
permalink: /how-to-deploy-cloud-labs/
description: "本文详细介绍了如何快速部署在线的云实验环境（Cloud-Lab）。Cloud-Lab 极大地方便高校、培训机构的实验环境搭建和部署。"
category:
  - 在线 Linux
  - Linux Lab
  - 开发环境
tags:
  - Cloud Lab
  - Cloud Ubuntu
  - 云实验环境
  - 在线实验
  - Linux 培训
  - Linux 实验
---

> By Falcon of [TinyLab.org][1]
> 2017-01-04 01:48:40

## 简介

为便利计算机课程的学习，泰晓科技在快速构建实验环境方面做了一系列渐进的努力，

* 创建了一系列实验环境：Labs
    * [CS630 Qemu Lab](http://tinylab.org/cs630-qemu-lab)：X86 Linux 汇编语言
    * [Linux 0.11 Lab](http://tinylab.org/linux-0.11-lab)： Linux 0.11 内核实验环境
    * [Linux Lab](http://tinylab.org/linux-lab)：Linux 内核和嵌入式 Linux 实验环境

* 通过 Docker 容器化实验环境：Cloud Lab
    * 为各实验环境添加了 Dockerfile，通过 Docker 加速环境的安装和可重复构建性
    * 创建了 Docker 镜像库：`tinylab/xxx`，方便直接下载实验环境
    * 添加了一系列便利化的管理脚本，方便环境的使用和部署
    * 拆分出 Cloud Lab 项目，解耦实验环境和实验代码本身，提高了环境管理脚本的可维护性
    * 添加了基于 novnc 和 gateone 的浏览器直接访问支持，进一步加速实验环境的易用性

* 提高可扩展性，创建基础云镜像：Cloud Ubuntu
    * 拆分出 Cloud Ubuntu 项目，专门管理各类基础镜像，比如编译环境、虚拟化支持、中文支持、嵌入式开发支持等
    * 为提高跨网络访问体验，在 Cloud Ubuntu 添加了代理和反向代理支持，方便外网访问内网的实验服务
    * 为节省包括端口在内的资源，拆分出了 novnc 和 gateone 的代理功能，并添加了自登陆功能

截止到目前，形成了三个层次的云实验环境抽象：Cloud Ubuntu、Cloud Lab 和 Labs。

* Cloud Ubuntu: <https://github.com/tinyclub/cloud-ubuntu.git>
* Cloud Lab: <https://github.com/tinyclub/cloud-lab.git>
* Labs: <https://github.com/tinyclub>

## Cloud Ubuntu：实验环境

Cloud Ubuntu 不仅实现了一系列基础镜像，而且提供了进一步快速扩展其他镜像的框架。

截止到目前，Cloud Ubuntu 实现了 13 个基础镜像，其中 base 镜像为 cloud-ubuntu，它提供了基础的 ssh 和 vnc 服务，其中 ssh 支持登陆失败限制。而 cloud-ubuntu-web 提供了 gateone 和 novnc，即 ssh 和 telnet 的 Web 代理，均支持 ssl。其他镜像还包括中文支持，中文输入支持（按下 `alt+s` 切换），基础开发环境（gcc+vim+git），虚拟化（qemu+bochs)，嵌入式开发，Markdown编辑，Jekyll网站以及代理服务/客户端，透明代理，代理转发和反向代理支持。

Cloud Ubuntu 极易扩展，要添加一个新的镜像，以 `xxx` 为例，步骤很简单：

* 在 `dockerfiles/` 下增加一个 `Dockerfile.xxx`。可在 Dockerfile 开头使用 "From tinylab/cloud-ubuntu" 之类来引用现有的基础镜像。
* 在 `system/` 目录下增加 `xxx/`，然后参照 Linux 标准目录结构放置目录和文件即可。其中，`etc/startup.aux/` 下可以放置新工具的配置脚本，`etc/supervisor/conf.d/` 下放置新工具的 supervisord 配置文件，supervisord 类似 init，能够 respawn 因故退出的服务。如确实有必要，也可以进一步客制化镜像的启动入口 `startup.sh`。
* 为了方便管理，可以在 `scripts/` 下增加一个管理脚本，用于传递环境变量之类的给 `etc/startup.aux/` 下的脚本。

在扩展之后，可以使用现有的工具来管理镜像：

* `./build xxx`: 构建
* `./run xxx`：运行
* `./rm xxx`：删除
* `./login/bash`: 直接登陆进容器并执行 bash
* `./login/ssh`：登陆 ssh
* `./login/webssh`：通过 web 登陆 ssh，需要先启动 web ubuntu：`./scripts/web-ubuntu.sh` 开启 ssh/vnc 代理服务
* `./login/vnc`：通过 web 登陆 vnc，同样需要先启动 web ubuuntu

## Cloud Lab：实验环境管理

Cloud Lab 用于连接实验环境（Cloud Ubuntu）和实验代码（Labs），它分为如下几部分：

* `labs/`: 实验代码子仓库

  该目录下导入了部分已经验证过的实验代码仓库，作为 submodule 导入到 cloud-lab 仓库中。

* `configs/`: 基于 Cloud Ubuntu 客制的实验环境

  该目录用于管理基于 Cloud Ubuntu 中提供的基础镜像的进一步配置，目前基本就是原有镜像的复用，只是改动了默认的启动脚本到 `tools/lab/run`，并允许通过 `configs/` 下与实验代码仓库同名的目录，进一步客制 system 并配置 docker 的一些运行参数。

* `tools/`: 一系列辅助管理工具

  * `lab/`：运行在容器中的工具
  * `docker/`: 用于管理容器的工具（单个实例）
  * `deploy/`: 用于部署容器的工具（可以方便运行任意多个实例，多个帐号并发布）
  * `system/`: 所有镜像公共的客制化部分

## Labs：实验代码

Labs 并没有特别的要求，可以是一系列代码加上一些必要的构建支持。

如果要集成一个新的 `xxx Lab` 进来，可以依次：

* 在 Cloud Ubuntu 中添加基础镜像 `xxx`
* 在 Cloud Lab 中添加 `configs/xxx` 并在 `labs/` 目录下通过 `git submodule add` 命令导入 `xxx Lab` 的代码仓库。

## 用法演示

首先下载 `Cloud Lab`：

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab/

接下来参照 Cloud Lab 中的 README.md 简单介绍如何使用一个现有的 Lab。

* 安装 Docker

      $ tools/docker/install

  安装以后，可根据实际情况自行配置 `/etc/default/docker`，包括 `--registry-mirror`，`--dns`，`--bip`，`dm.basesize` 等。修改后需要重启服务：

      $ sudo service docker restart

* 下载实验代码

  选择某个 Lab，以 tinylab.org 为例

      $ tools/docker/choose tinylab.org

  运行后，会自动 clone 实验代码。

* 下载实验环境

      $ tools/docker/pull

* 启动实验环境

      $ tools/docker/run

  运行后会自动启动 Web ubuntu 的 ssh/vnc 代理服务，并通过浏览器打开 ssh 和 vnc 服务，并且会自动使用完成登陆。由于浏览器不认识随机生成的 ssl key/cert，所以第一次需要手动设置一下，后续都可以自动完成登陆过程了。

* 大规模部署

  以下创建 10 个 tinylab.org 的实验环境，登陆帐号均为 falcon，密码随机生成。

      $ tools/deploy/run tinylab.org falcon 10

  创建后可以通过如下命令查看实验环境的访问地址、帐号和密码等：

      $ echo example.com > .host_name
      $ tools/deploy/release

## 在线体验

如果想快速体验 Cloud Lab，可以添加笔者微信号（lzufalcon）申请一天的免费在线体验帐号，添加时请备注：`Cloud Lab`。

也可以直接在[泰晓开源小店](http://weidian.com/?userid=335178200)赞助我们并免费获得一周的在线体验帐号。

## 总结

Cloud Lab 不仅为个人学习计算机课程提供了极度便捷的实验环境搭建方案，也为各类高校，乃至各类计算机培训机构甚至企业内部的专业培训提供了一种非常低成本和高效的实验环境部署方案。

早期的大学实验室学习 Linux 需要安装虚拟机，学习 Java 和数据库需要安装一堆工具，现在完全不需要，实验主机只要有个浏览器就可以了，实验环境可以提前用 Docker 容器化。而且离开了实验室，学生也完全可以通过自己的笔记本或者台式机远程访问实验环境进行实验，没有本地安装实验环境的必要，所以会极度地降低学习的门槛进而极大地提高大家动手学习的欲望。


[1]: http://tinylab.org
