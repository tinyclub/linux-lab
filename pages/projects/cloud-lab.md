---
title: 'Cloud Lab -- 泰晓实验云台'
tagline: '可快速构建的计算机课程在线实验平台'
author: Wu Zhangjin
layout: page
permalink: /cloud-lab/
description: 基于 Docker 的计算机课程在线实验平台。
update: 2017-10-06
categories:
  - 开源项目
  - Cloud Lab
tags:
  - 实验云台
  - 实验环境
  - Lab
  - Docker
---

## 项目描述

该项目致力于创建一套计算机课程的在线实验平台。

  * 使用文档：[README.md][2]
  * 在线演示：[泰晓实验云台][10]
  * 注册帐号：[泰晓开源小店][11]
  * 代码仓库：[https://github.com/tinyclub/cloud-lab.git][3]
  * 基本特性：
      * 基于 Docker，一键安装，几分钟内就可构建，节约生命，生命，生命。
      * 通过 Docker CE 和 Docker Toolbox 支持所有 Linux，Windows，Mac OS 平台
      * 可直接通过 Web 远程访问（支持ssh和vnc），非常便捷，便捷，便捷。
      * 支持即时录制，随时记录和分享学习过程。
      * 已内置多个示例实验环境：Linux Lab，Linux 0.11 Lab, CS630 Qemu Lab
      * 可轻松扩展更多实验环境
      * 支持多人协同实验
      * 支持广播教学模式

  * 登陆界面

  ![Cloud Lab 登陆界面](/wp-content/uploads/2017/10/tinylab.cloud.png)

## 相关文章

  * [如何快速部署云实验环境（Cloud-Lab）][12]
  * [桌面秀（Showdesk.io）— 轻松录制，即时分享][13]
  * [利用 Linux Lab 完成嵌入式系统开发全过程][7]
  * [基于 Docker/Qemu 快速构建 Linux 内核实验环境][6]
  * [基于 Docker 快速构建 Linux 0.11 实验环境][5]

## 五分钟教程

### 安装 Docker

Docker 是 Cloud Lab 的基础，必须先安装。如果还没有安装，请参考：

* Linux：[Docker CE](https://store.docker.com/search?type=edition&offering=community)
* Mac 和 Windows 系统：[Docker Toolbox](https://www.docker.com/docker-toolbox)

#### Linux

在 Linux 系统上，安装完 Docker CE 后就会自动启动 docker 服务。

#### Mac OS 和 Windows

以 Mac 系统为例，安装完 Docker Toolbox 以后，打开 `kitematic` 并运行，会在 Virtualbox 中创建一个名为 `default` 的 Linux 系统，该系统为 TinyCoreLinux，其中集成了 docker 服务。

需要提示的是，该系统启动后，会挂载两个目录，可以用来存放我们的实验环境，它们是：

* `/Users`：由 Mac OS 的 `/Users` 挂载过来，方便在 Mac OS 和该系统之间交换文件。
* `/mnt/sda1`：在 Virtualbox 上外挂的一个虚拟磁盘镜像文件，默认有 17.9 G，足够存放常见的实验环境。

#### 免 root 使用

安装完 docker 后如果想免 `sudo` 使用 Cloud Lab，请务必把用户加入到 docker 用户组并重启系统。

    $ sudo usermod -aG docker $USER

### 工作目录

在 Mac 系统上，请先启动 Virtualbox 上 default 系统，并进入 `/mnt/sda1` 目录下，Windows 应该类似。

    $ cd /mnt/sda1

在 Linux 系统上，找一处当前用户可存储的目录即可，例如 `~/Documents`。

    $ cd ~/Documents/

### 下载

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab

### 选择并下载一个实验环境

可以列出来再选择：

    $ tools/docker/choose
    LOG: Current Lab is linux-0.11-lab
    LOG: Available Labs:

     1	cs630-qemu-lab
     2	linux-0.11-lab
     3	linux-lab
     4	markdown-lab
     5	qing-lab
     6	tinylab.org

    LOG: Choose the lab number: 2

    LOG: Download the lab...

    Already on 'master'
    Your branch is up-to-date with 'origin/master'.

    Already up-to-date.
    LOG: Source code downloaded to cloud-lab/labs/linux-0.11-lab

也可以直接指定并下载：

    $ tools/docker/choose linux-0.11-lab

实验源码下载在：

    $ ls cloud-lab/labs/linux-0.11-lab
    book	   COPYING  examples  Makefile	   Makefile.emu   Makefile.help  README.md  src
    callgraph  doc	    images    Makefile.cg  Makefile.head  Makefile.tags  rootfs     tools

### 拉取并运行该实验环境

下述命令会直接拉取 Linux 0.11 Lab 实验环境的 Docker 镜像并运行，运行完以后会打印出 VNC 的登陆链接。

    $ tools/docker/run
    LOG: VNC screen recorded in cloud-lab/recordings
    LOG: User: ubuntu ,Password: n4sqtv ,VNC Password: 3m9k7h ,Viewonly Password: c9tt4h
    Please login:

      *   Normal: http://localhost:6080/?u=3699ab&p=3m9k7h
      * Viewonly: http://localhost:6080/?r=3699abc9tt4h

            User: 3699ab
        Password: 3m9k7h
        Password: c9tt4h (Viewonly)

其中实验会话录制的默认目录为 `recordings/`。

正常的实验环境登陆地址为 `Normal` 所在行，而 `Viewonly` 所在行可以用在广播教学中，给学生观看。

该登陆地址可以通过现代浏览器打开，比如 Firefox, Chromium-browser 以及 Safari，Chromium-browser 为首选，其兼容性和性能最好。

### 登陆实验环境

Cloud Lab 提供了多种方式：

* `tools/docker/bash` 在本地直接登陆容器并运行 bash 命令行
* `tools/docker/ssh` 通过 ssh 在本地或者远程登陆命令行
* `tools/docker/webssh` 通过浏览器登陆 ssh 命令行
* `tools/docker/vnc` 通过浏览器登陆桌面

而 `tools/docker/run` 运行完打印的就是 `tools/docker/vnc` 执行的结果。

执行 `tools/docker/vnc` 后会打开一个网页，本地执行会自动填入帐号和密码登陆，远程的话，复制链接或者根据提示手动输入帐号和密码即可登陆。

### 开展实验

登陆进去以后就可以根据不同的实验环境做实验，请参考：

* [CS630 Qemu Lab](http://tinylab.org/cs630-qemu-lab)：X86 Linux 汇编语言实验环境
* [Linux 0.11 Lab](http://tinylab.org/linux-0.11-lab)： Linux 0.11 内核实验环境
* [Linux Lab](http://tinylab.org/linux-lab)：Linux 内核和嵌入式 Linux 实验环境

### 实验效果

这里有一份 Linux Lab 的实验效果图：

![Linux Lab Demo](/wp-content/uploads/2016/06/docker-qemu-linux-lab.jpg)

以及相应的演示视频：

<iframe src="http://showdesk.io/7977891c1d24e38dffbea1b8550ffbb8/?f=1" width="100%" marginheight="0" marginwidth="0" frameborder="0" scrolling="no" border="0" allowfullscreen></iframe><br>

更多实验演示效果请参考 [桌面秀 -- showdesk.io](http://showdesk.io)。

### 多人协同

Cloud Lab 默认开启了多人共享模式，同一个 `Normal` 链接可以在多处登陆，登陆后，双方都可以操作，也可以看到对方的操作，当然，由于登陆的是同一个桌面，多人不能同时操作。

### 广播教学

Cloud Lab 提供的 `Viewonly` 链接可以用于学生，该链接可以多人同时登陆，但是只可以观看，不能操作，因此很适合教学时学生使用。

在课堂或者实验室教学中，老师使用 `Normal` 链接进行操作演示，学生们使用 `Viewonly` 链接观看老师的演示，就可以完成教学过程。

如果学生们在观看完老师的演示以后也想做实验，那么可以人手创建一个帐号，这个可以用 `tools/deploy` 下的工具进行自动化部署。

例如，为学生 `john` 和 `tom` 分别创建一个 Linux 0.11 Lab：

    $ tools/deploy/run linux-0.11-lab john
    $ tools/deploy/run linux-0.11-lab tom

查看实验帐号：

    $ tools/deploy/release
    Lab: linux-0.11-lab-29979, User: tom
      * VNC: http://localhost:6080/?u=1e6005&p=ktft7s
      * VNC_VIEWONLY: http://localhost:6080/?r=1e6005w7lxxm
      * Webssh: http://localhost:4433/?ssh=ssh://tom:n7p7fd@10.66.0.3:22
    Lab: linux-0.11-lab-29965, User: john
      * VNC: http://localhost:6080/?u=3699ab&p=7cn9wn
      * VNC_VIEWONLY: http://localhost:6080/?r=3699ab3mvmmp
      * Webssh: http://localhost:4433/?ssh=ssh://john:tk9lbf@10.66.0.2:22

默认地址是 `localhost`，如果有一个域名或者主机之外可访问的 IP 地址，可以填入 `.host_name`，例如：

    $ echo tinylab.cloud:6080 > .host_name
    $ tools/deploy/release
    Lab: linux-0.11-lab-29979, User: tom
      * VNC: http://tinylab.cloud:6080:6080/?u=1e6005&p=ktft7s
      * VNC_VIEWONLY: http://tinylab.cloud:6080:6080/?r=1e6005w7lxxm
      * Webssh: http://tinylab.cloud:6080:4433/?ssh=ssh://tom:n7p7fd@10.66.0.3:22
    Lab: linux-0.11-lab-29965, User: john
      * VNC: http://tinylab.cloud:6080:6080/?u=3699ab&p=7cn9wn
      * VNC_VIEWONLY: http://tinylab.cloud:6080:6080/?r=3699ab3mvmmp
      * Webssh: http://tinylab.cloud:6080:4433/?ssh=ssh://john:tk9lbf@10.66.0.2:22

该功能可以用于大学实验室教学，企业培训，甚至是课堂或者讲座时即时演示。

### 添加新的实验环境

可以先尽量复用现在的实验环境，如果现有的实验环境无法满足要求，也可以自行添加。

添加一个实验环境的过程很简单，主要有如下几步：

#### 添加实验环境

以 `linux-0.11-lab` 为例。

实验环境的配置文件放在 `configs/` 目录下，先来看看目录结构：

    $ tree configs/linux-0.11-lab/
    configs/linux-0.11-lab/
    ├── docker
    │   ├── caps
    │   ├── devices
    │   ├── limits
    │   ├── name
    │   └── volumemap
    ├── Dockerfile
    └── system
        └── home
            └── ubuntu
                └── Desktop
                    ├── help.desktop
                    ├── lab.desktop
                    ├── showdesk.desktop
                    └── showterm.desktop

下面对这三部分做介绍：

* `Dockerfile`

    先找一个基础 Docker 镜像，比如 `ubuntu:14.04.5`，又比如 `tinylab/cloud-ubuntu-vm`，然后在这个基础上写 Dockerfile，添加新的工具。可通过 `docker search tinylab` 查看现有镜像：

        $ docker search tinylab
        tinylab/linux-0.11-lab ...
        tinylab/linux-lab ...
        tinylab/cs630-qemu-lab ...
        tinylab/cloud-ubuntu-dev ...

* `docker/`

    该目录用于设置镜像名，配置资源，或者添加需要用到的设备等。镜像名命名规则为 `tinylab/<LAB_NAME>`，例如：`tinylab/linux-0.11-lab`。

* `system/`

    该目录按照 Linux 标准目录结构存放，例如这里添加了几个桌面快捷方式。也可以添加其他文件，例如预先编译好的程序或者脚本文件。

除此之外，还有一个比较重要的目录，在这里没有用到，那就是 `tools`，该目录下可以添加两个重要文件：

* `tools/host-run`

    在启动实验环境之前在主机上运行，可以用于做一些必要的准备，比如说针对 Linux Lab，就需要先插入 nfsd 内核模块。

* `tools/container-run`

    在启动实验环境后在容器内运行，比如 Linux Lab 中有用来启动一些网络服务。

准备好之后，就可以构建 Docker 镜像：

    $ tools/docker/build linux-0.11-lab

构建以后如果觉得该环境有通用性，也可以往 [Cloud Lab 代码仓库][3] 提交。

#### 添加实验源码

实验用到的源代码、文档和工具等可以创建一个 Git 仓库存放起来，甚至上传到 Github 中，然后作为 git submodule 导入到 `labs/` 目录下。例如：

    $ cd labs/
    $ git submodule add https://github.com/tinyclub/linux-0.11-lab.git

### 录制学习视频

Cloud Lab 支持自动录制实验过程。登陆进去之前，进行如下设置并点击 `Apply` 后再登陆即可开启录制。要停止录制，退出实验环境即可。

![Cloud Lab 录制视频](/wp-content/uploads/2017/10/tinylab.cloud-recording.png)

录制完的视频可以回放，通过设置上面的播放页面进去，选择刚录制的内容播放即可。

该功能可以用于老师录制教学演示视频，也可以用于学生交作业，检查学生的实操练习情况。

### 获取帐号

如果想快速体验，欢迎通过 [泰晓开源小店][11] 购买已经创建好的在线实验帐号。

如果觉得该实验平台非常有用，欢迎扫下面的二维码赞助我们。

 [2]: https://github.com/tinyclub/cloud-lab/blob/master/README.md
 [3]: https://github.com/tinyclub/cloud-lab
 [4]: /take-5-minutes-to-build-linux-0-11-experiment-envrionment/
 [5]: /build-linux-0-11-lab-with-docker/
 [6]: http://tinylab.org/docker-qemu-linux-lab/
 [7]: http://tinylab.org/using-linux-lab-to-do-embedded-linux-development/
[10]: http://tinylab.cloud:6080/
[11]: http://weidian.com/?userid=335178200
[12]: http://tinylab.org/how-to-deploy-cloud-labs/
[13]: http://tinylab.org/showdesk-record-and-share-your-desktop/
