---
title: 'Cloud Lab: 泰晓实验云台'
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
  - 在线实验
  - 开发环境
  - Linux 培训
  - Linux 实验
  - Lab
  - Docker
---

## 项目描述

泰晓实验云台 项目致力于创建一套计算机课程的在线实验平台。

  * 使用文档：[README.md][2]
  * 注册帐号：[泰晓开源小店][11]
  * 代码仓库：
      * [https://gitee.com/tinylab/cloud-lab.git][8]
      * [https://github.com/tinyclub/cloud-lab.git][3]
  * 基本特性：
      * 基于 Docker，一键安装，几分钟内就可构建，节约生命，生命，生命。
      * 通过 Docker CE 和 Docker Toolbox 支持所有 Linux，Windows，Mac OSX 平台
      * 可直接通过 Web 远程访问（支持ssh和vnc），非常便捷，便捷，便捷。
      * 支持即时录制，随时记录和分享学习过程。
      * 已内置多个示例 Lab：Linux Lab，Linux 0.11 Lab, CS630 Qemu Lab，Markdown Lab
      * 可轻松扩展更多 Lab，欢迎大家参与贡献
      * 支持多人协同实验，适合远程一对一教学指导或者协同开发
      * 支持广播教学模式，适合大学课程实验、企业培训以及讲座即时演示
  * 登陆界面

  ![Cloud Lab 登陆界面](/wp-content/uploads/2017/10/tinylab.cloud.png)

## 相关文章

  * [桌面秀（Showdesk.io）— 轻松录制，即时分享][13]
  * [利用 Linux Lab 完成嵌入式系统开发全过程][7]
  * [基于 Docker/Qemu 快速构建 Linux 内核实验环境][6]
  * [基于 Docker 快速构建 Linux 0.11 实验环境][5]

## 安装 Docker

Docker 是 Cloud Lab 的基础，需要先安装好，可参考：

* Linux, Mac, Windows 10 系统：[Docker CE](https://store.docker.com/search?type=edition&offering=community)
* 老版本的 Windows 系统：[Docker Toolbox](https://www.docker.com/docker-toolbox)

安装完 docker 后如果想免 `sudo` 使用 linux lab，请务必把用户加入到 docker 用户组并重启系统。

    $ sudo usermod -aG docker $USER

由于 docker 镜像文件比较大，有 1G 左右，下载时请耐心等待。另外，为了提高下载速度，建议通过配置 docker 更换镜像库为本地区的，更换完记得重启 docker 服务。

Docker 镜像加速部分请参考：

  * [阿里云 Docker 镜像使用文档](https://help.aliyun.com/document_detail/60750.html)
  * [USTC Docker 镜像使用文档](https://lug.ustc.edu.cn/wiki/mirrors/help/docker)

如果 docker 默认的网络环境跟本地的局域网环境地址冲突，请通过如下方式更新 docker 网络环境，并重启 docker 服务。

    $ grep bip /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --bip=10.66.0.10/16"
    $ service docker restart

### Linux 和 Mac 系统

在 Linux 和 Mac 系统上，安装完 Docker CE 后就会自动启动 docker 服务。

在 Mac 系统下，虽然也可以通过 Docker Toolbox 来安装 Docker，不过 Docker CE 已经支持原生 Docker，性能和体验会更好，Cloud Lab 也已经支持这种方式，所以 Mac 下也推荐用 Docker CE 安装。

### Windows

Windows 虽然也支持通过 Docker CE 直接安装 Docker，但是如果要使用 Cloud Lab，需要一套兼容 Linux 和 Mac 的脚本环境，所以目前还是推荐 Windows 用户通过 Docker Toolbox 来安装 Docker。

由于没有可测试的 Windows 系统，下面以 Mac OSX 为例介绍如何通过 Docker Toolbox 安装 Docker。

以 Mac 系统为例，安装完 Docker Toolbox 以后，打开 `kitematic` 并运行，会在 Virtualbox 中创建一个名为 `default` 的 Linux 系统，该系统为 TinyCoreLinux，其中集成了 docker 服务。

该系统启动后，会挂载两个目录，可用于存放实验源码，它们是：

* `/Users`：由 Mac OSX 的 `/Users` 挂载过来，方便在 Mac OSX 和该系统之间交换文件。
* `/mnt/sda1`：在 Virtualbox 上外挂的一个虚拟磁盘镜像文件，默认有 17.9 G，足够存放常见的实验环境。

请务必注意，该 `default` 系统中默认的 `/root` 目录仅仅挂载在内存中，关闭系统后数据会丢失，请千万不要用它来保存实验数据。

另外，由于该系统未提供桌面，所以需要先获取该系统的外网地址，即 eth1 网口的 IP 地址，并通过 Windows 或者 Mac OSX 访问 Lab。

    $ ifconfig eth1 | grep 'inet addr' | tr -s ' ' | tr ':' ' ' | cut -d' ' -f4
    192.168.99.100

如果是自己通过 Virtualbox 安装的 Linux 系统，即使有桌面，也想在外部系统访问时，则可以通过设置 'Network -> Adapter2 -> Host-only Adapter' 来添加一个 eth1 网口设备。

### 免 root 使用 Docker

安装完 docker 后如果想免 `sudo` 使用 Cloud Lab，请务必把用户加入到 docker 用户组并重启系统。

    $ sudo usermod -aG docker $USER

### 免密运行 Lab

运行 Lab 过程中，部分操作需要 root 权限，如果想免密使用，可以配置下 sudo。如果配置过程中出错，可以用 `pkexec visudo` 补救。

    $ sudo -s
    $ echo "$SUDO_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$SUDO_USER

### 提升镜像下载速度

由于 docker 镜像文件比较大，有 1G 左右，下载时请耐心等待。另外，为了提高下载速度，建议通过配置 docker 更换镜像库为本地区的，更换完记得重启 docker 服务。

Docker 镜像加速部分请参考：

  * [阿里云 Docker 镜像使用文档](https://help.aliyun.com/document_detail/60750.html)
  * [USTC Docker 镜像使用文档](https://lug.ustc.edu.cn/wiki/mirrors/help/docker)

### 避免网络地址冲突

如果 docker 默认的网络环境跟本地的局域网环境地址冲突，请通过如下方式更新 docker 网络环境，并重启 docker 服务。

    $ grep bip /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --bip=10.66.0.10/16"
    $ service docker restart

如果上述改法不生效，请在类似 `/lib/systemd/system/docker.service` 这样的文件中修改后再重启 docker 服务。

    $ grep dockerd /lib/systemd/system/docker.service
    ExecStart=/usr/bin/dockerd -H fd:// --bip=10.66.0.10/16 --registry-mirror=https://docker.mirrors.ustc.edu.cn
    $ service docker restart

## 实验目录

如果使用了 Docker Toolbox 安装 Docker，则启动 Virtualbox 上的 `default` 系统后，请使用 `/mnt/sda1` 目录。因为默认的 `/root` 目录仅仅挂载在内存中，该系统关闭后数据会丢失。

    $ cd /mnt/sda1

在 Linux 或者 Mac 系统上，找一处当前用户可存储的目录即可，例如 `~/Documents`。

    $ cd ~/Documents/

## 下载 Cloud Lab

    $ git clone https://gitee.com/tinylab/cloud-lab.git
    $ cd cloud-lab

## 下载 Lab

可以列出来后再选择：

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

也可直接指定并下载：

    $ tools/docker/choose linux-0.11-lab

实验源码下载在 `labs/` 目录下：

    $ ls cloud-lab/labs/linux-0.11-lab
    book	   COPYING  examples  Makefile	   Makefile.emu   Makefile.help  README.md  src
    callgraph  doc	    images    Makefile.cg  Makefile.head  Makefile.tags  rootfs     tools

## 运行 Lab

下述命令会直接拉取实验环境的 Docker 镜像并运行，运行完以后会打印出 VNC 的登陆链接。

    $ tools/docker/run
    LOG: VNC screen recorded in cloud-lab/recordings
    LOG: User: ubuntu ,Password: n4sqtv ,VNC Password: 3m9k7h ,Viewonly Password: c9tt4h
    Please login:

      *   Normal: http://localhost:6080/?u=3699ab&p=3m9k7h
      * Viewonly: http://localhost:6080/?r=3699abc9tt4h

            User: 3699ab
        Password: 3m9k7h
        Password: c9tt4h (Viewonly)

从 Log 中可以看出，其中实验会话录制的默认目录为 `recordings/`。

正常的实验环境登陆地址为 `Normal` 所在行链接，而 `Viewonly` 所在行链接可用于广播教学，给学生观看。

该登陆链接可以通过现代浏览器打开，比如 Firefox, Chromium-browser 以及 Safari，Chromium-browser 为首选，其兼容性和性能最好。

## 登陆 Lab

Cloud Lab 提供了多种登陆方式：

* `tools/docker/bash`：在本地直接登陆容器并运行 bash 命令行
* `tools/docker/ssh`：通过 ssh 在本地或者远程登陆命令行
* `tools/docker/webssh`：通过浏览器登陆 ssh 命令行
* `tools/docker/vnc`：通过浏览器登陆桌面

而 `tools/docker/run` 运行的最后就是执行 `tools/docker/vnc` 自动登陆。`tools/docker/vnc` 会打开一个网页，本地执行会自动填入帐号和密码登陆，远程登陆的话，可复制链接或者根据提示手动输入帐号和密码。

## 开展实验

登陆以后就可以在桌面上点击 Lab 终端的快捷方式开展实验，在实验过程中，可以点击桌面的 `Help` 快捷页面查看帮助。

已添加 Lab 的详细用法，请参考：

* [CS630 Qemu Lab](http://tinylab.org/cs630-qemu-lab)：X86 Linux 汇编语言实验环境
* [Linux 0.11 Lab](http://tinylab.org/linux-0.11-lab)： Linux 0.11 内核实验环境
* [Linux Lab](http://tinylab.org/linux-lab)：Linux 内核和嵌入式 Linux 实验环境
* [Markdown Lab](http://tinylab.org/markdown-lab)：Markdown 文档编辑环境，包括文档、书籍、幻灯和简历模版

## 实验效果

这里有一份 Linux Lab 的实验效果图：

![Linux Lab Demo](/wp-content/uploads/2016/06/docker-qemu-linux-lab.jpg)

以及相应的演示视频，该视频由 Cloud Lab 自身录制：

<iframe src="http://showdesk.io/7977891c1d24e38dffbea1b8550ffbb8/?f=1" width="100%" marginheight="0" marginwidth="0" frameborder="0" scrolling="no" border="0" allowfullscreen></iframe><br>

更多实验演示效果请参考 [桌面秀 -- showdesk.io](http://showdesk.io)。

## 多人协同

Cloud Lab 默认开启了多人共享模式，同一个 `Normal` 链接可以在多处登陆，登陆后，双方都可以操作，也可以看到对方的操作，当然，由于登陆的是同一个桌面，多人不能同时操作。

## 广播教学

该广播教学功能可用于大学实验室教学、企业培训、远程授课、甚至是课堂或者讲座时即时演示。

### 授课模式

Cloud Lab 提供的 `Viewonly` 链接可以用于学生，该链接可以多人同时登陆，但是只可以观看，不能操作，因此很适合授课时学生使用。

在课堂或者实验室教学中，老师使用 `Normal` 链接进行操作演示，学生们使用 `Viewonly` 链接观看老师的演示，就可以完成授课过程。

### 互动模式（集中式）

**说明**：以下功能在开源版本中不再提供支持，如需相关功能，请联系我们提供[服务](/ruma.tech)。

如果学生们在观看老师的演示时也要同步做实验，那么可以人手创建一个可以操作的帐号。

### 互动模式（分布式）

上面的互动模式采用的是集中式，在单台服务器上创建所有实验帐号，好处是学生无需创建帐号，可以直接使用，这样的效率更高，坏处是如果同时上课的学生比较多，这台集中式的服务器就需要配置更好的硬件资源，包括处理器、内存和磁盘空间都需要根据人数进行合理配置。

如果没有这样的服务器资源，也可以采用分布式的方式，即学生们自行参照上述步骤在实验室的电脑或者自己携带的笔记本电脑上搭建好实验环境。

上述集中式的方式适合课堂上即时互动，下述分布式的方式适合在实验室上传统的实验课。

### 远程授课

上面介绍的三种方式适合面对面授课，如果想利用 Cloud Lab 做远程授课，需要通过 YY、钉钉、QQ、微信之类软件增加语音功能。

## 添加 Lab

先尽量复用现有的 Lab，如果现有的 Lab 无法满足要求，也可以自行添加。

一个 Lab 主要包括两部分：实验环境和实验源码，如需基于 Cloud Lab 添加新的实验环境，欢迎联系我们提供[服务](/ruma.tech)。

## 录制视频

Cloud Lab 支持自动录制实验过程。登陆进去之前，进行如下设置并点击 `Apply` 后再登陆即可开启录制。要停止录制，退出实验环境即可。

![Cloud Lab 录制视频](/wp-content/uploads/2017/10/tinylab.cloud-recording.png)

录制完的视频可以回放，通过设置上面的播放页面进去，选择刚录制的内容播放即可。

该功能可以用于老师录制教学演示视频，也可以用于学生交作业，检查学生的实操练习情况。

## 获取帐号

如果觉得该实验平台非常有用，欢迎扫下面的二维码赞助我们。

 [2]: https://gitee.com/tinylab/cloud-lab/blob/master/README.md
 [3]: https://github.com/tinyclub/cloud-lab
 [8]: https://gitee.com/tinylab/cloud-lab
 [4]: /take-5-minutes-to-build-linux-0-11-experiment-envrionment/
 [5]: /build-linux-0-11-lab-with-docker/
 [6]: http://tinylab.org/docker-qemu-linux-lab/
 [7]: http://tinylab.org/using-linux-lab-to-do-embedded-linux-development/
[11]: http://weidian.com/?userid=335178200
[13]: http://tinylab.org/showdesk-record-and-share-your-desktop/
