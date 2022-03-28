---
layout: post
author: 'Jia Xianhua'
title: "D1-H 开发板——哪吒 开发入门"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /nezha-d1-quickstart/
description: "本文分享了 RISC-V 开发板 —— 哪吒 D1 开发入门，后续还有两篇。该成果由 RISC-V Linux 内核兴趣小组输出。"
category:
  - 开源项目
  - Risc-V
tags:
  - RISC-V
  - 哪吒
  - D1
  - Linux
  - 平头哥
  - 全志
---

> Author:  iosdevlog
> Date:    2022/03/17
> Project: <https://gitee.com/tinylab/riscv-linux>

## 背景简介

去年 Linux-Lab v0.9 准备添加 RISC-V 的支持，我也申请到了一个 D1 开发板。

大概是在 2021年8月，我在 [Notion](https://nosion.so) 记录了一下如何按通官方文档测试 D1 开发板。

后期由于多种原因，没有继续参加后面的开发测试。

本文准备把之前的笔记整理一下，正式参与到 Linux RISC-V 项目中来。

今天我再次下载源码的时候，发现 `repo` 初始化不成功，看到网上留言可能是珠海服务器出问题了。

可以去这里 <https://pan.baidu.com/s/1v55AKMFripaEu22tJ92lmw?pwd=awol> 下载完整版 code。

## Tina Linux 系统介绍 

【哪吒】是全志在线基于全志科技 D1-H 芯片定制的 AIoT 开发板，是全球首款支持 64bit RISC-V指令集并支持 Linux 系统的可量产开发板。

![D1](https://bbs.aw-ol.com/assets/uploads/files/1619509771886-bd24f754-f0d9-46ef-ac17-0123375c1ef3-image.png)

D1-H 哪吒开发板默认自带 Tina Linux 系统。 Tina Linux 是全志科技基于 Linux 内核开发的针对智能硬件类产品的嵌入式软件系统。Tina Linux 基于 openwrt-14.07 版本的软件开发包，包含了 Linux 系统开发用到的内核源码、驱动、工具、系统中间件与应用程序包。

> openwrt 是知名的开源嵌入式 Linux 系统自动构建框架，是由 Makefile 脚本和 Kconfig 配置文件构成的。使得用户可以通过 menuconfig 配置，编译出一个完整的可以直接烧写到机器上运行的 Linux 系统软件。 

![系统框图](https://d1.docs.aw-ol.com/assets/img/Tina_Linux_ARCH.png)

Tina 系统软件架构如上图所示。

从下至上分别为 Kernel && Driver、Libraries、System Services、Applications 四层。

## 开发入门

### 源码下载

#### 全志客户服务平台官网：[全志客户服务平台](https://open.allwinnertech.com/#/login?cas=true) 注册。

V2.0 SDK 仓库下载说明

1. 上传公钥
2. 安装 repo 引导脚本
3. 下载代码

下载服务器统一为：<sdk.allwinnertech.com>

下载请注意：如有 lichee 和 android 两仓库，务必放在同一级目录

#### 上传公钥

第一步：生成公钥

使用SSH协议下载，通过公钥认证的方式避免输入密码：

客户在本机上生成公钥私钥对（使用命令 `ssh-keygen`，一直回车，不用输入口令）。

成功后会在 `~/.ssh/` 目录下生成 id_rsa.pub 和 id_rsa 两个文件。

第二步：上传公钥

将 id_rsa.pub 公钥文件内容拷贝，点击 资源下载->公钥管理->创建，上传当前生成的公钥到服务器。公钥上传成功后，即可下载代码。

![id_rsa.pub](https://open.allwinnertech.com/guide/yht2/assets/AF1C6995-6057-4b87-A9E9-CB349586F5B1.png)

注意事项：

1. 公钥和私钥文件一定要保存好，不能删除。最好备份这两个文件，误删除时可恢复。

2. 客户下载代码时，如果命令行前面加了 `sudo`，那么生成公钥的命令 `ssh-keygen` 前
面也要加 `sudo`（也就是要么都加 `sudo`，要么都不加，必须保持一致）。

#### 安装 repo 引导脚本

不能使用 google 的，需要用全志的。

1. 从全志服务器下载安装 repo 引导脚本，将 username 替换成客户下载账号的用户名

```
$ git clone ssh://username@sdk.allwinnertech.com/git_repo/repo.git
```

2. 修改 `repo/repo` 文件中下面一行，将 username 替换成客户下载账号的用户名

```
REPO_URL='ssh://username@sdk.allwinnertech.com/git_repo/repo.git'
```

3. 把 repo 引导脚本添加到自己计算机环境变量中

```
$ cp repo/repo /usr/bin/repo
$ chmod 777 /usr/bin/repo
```

#### 代码下载

这里会用到 Python2，如果默认安装 Python3，需要切回 Python2。

```
$ mkdir tina-d1-h
$ cd tina-d1-h
$ python2.7 /usr/bin/repo init -u ssh://<username>@sdk.allwinnertech.com/git_repo/D1_Tina_Open/manifest.git -b master -m tina-d1-h.xml
$ python2.7 /usr/bin/repo sync
$ python2.7 /usr/bin/repo start product-smartx-d1-h-tina-stable-v2.0 --all # 全部下载完成之后，创建分支
```

### 编译环境配置

嵌入式产品开发流程中，通常有两个关键的步骤，编译源码与烧写固件。源码编译需要先准备好编译环境，而固件烧写则需要厂家提供专用烧写工具。本文主要介绍如何搭建环境来实现 Tina sdk 的编译和打包。

一个典型的嵌入式开发环境包括本地开发主机和目标硬件板：

本地开发主机作为编译服务器，需要提供 Linux 操作环境，建立交叉编译环境，为软件开发提供代码更新下载，代码交叉编译服务。

本地开发主机通过串口或 USB 与目标硬件板连接，可将编译后的镜像文件烧写到目标硬件板， 并调试系统或应用程序。

**编译环境要求**

Tina Linux SDK 是在 Ubuntu14.04 开发测试的，推荐使用 Ubuntu 14.04 主机环境进行源码编译。

```
$ sudo apt-get update
$ sudo apt-get install build-essential subversion git-core libncurses5-dev zlib1g-dev gawk flex quilt libssl-dev xsltproc libxml-parser-perl mercurial bzr ecj cvs unzip lib32z1 lib32z1-dev lib32stdc++6 libstdc++6 -y
```

我测试在 Ubuntu 20.04 也可以正常使用：

```
$ sudo apt-get install libc6-i386 libstdc++6-i386-cross lib32ncurses6 lib32z1 -y
```

### 编译和烧写

#### 编译

编译打包命令如下：

```
source build/envsetup.sh
lunch d1_nezha-tina
make -j32
pack
```

其中：

1. `source build/envsetup.sh` ：获取环境变量
2. `lunch d1_nezha-tina` 选择 d1_nezha-tina 方案，也可以不加参数直接 `lunch`，这样会有选项可以选择，其中 `lunch d1_nezha-tina` 是 `d1_nezha-tina` 的标准方案，`lunch d1_nezha_min-tina` 是只能让系统跑起来的最小系统方案。
3. `make -j32` ：编译，其中 -j 后面的数字参数为编译用的线程数，可根据开发者编译用的 PC 实际情况选择。
4. `pack` : 打包，将编译好的固件打包成一个 .img 格式的固件，固件路径 `/out/d1_nezha-tina/tina_d1-nezha_uart0.img`。

#### 烧写

烧写，即将编译打包好的固件下载到设备

**烧写方式简介**

全志平台为开发者提供了多种多样的烧写方式和烧写工具：

（1） PhoenixSuit：基于 Windows 的系统的烧写工具，是最常用的烧写工具，通过数据线将 PC 和开发板连接，把固件烧到开发板上，支持分区烧写，适用于开发和小规模生产使用。建议开发者开发时使用该工具进行固件升级。

（2）LiveSuit：基于 Ubuntu 的系统的烧写工具，通过数据线将 PC 和开发板连接，把固件烧到开发板上，即 Ubuntu 版的 PhoenixSuit，适用于 Ubuntu 系统开发者进行开发烧写。

（3）PhoenixUSBpro：基于 Windows 的系统的烧写工具，通过数据线将 PC 和开发板连接，把固件烧到开发板上，一台 PC 可同时连接 8 台设备，分别控制其进行烧写，适用于产线批量生产。

（4）PhoenixCard：基于 Windows 的系统的量产 SD 卡制作工具，可以将普通的 .img 固件制作成 SD 卡量产固件，生产时在设备端插入量产 SD 卡即会自动烧写固件，适用于带 SD 卡卡槽的设备大规模量产。

（5）存储器件批量烧写生产：用专有设备将提前将固件烧写到未贴片的存储器件（如 emmc、nand、nor 等）上，再上机贴片，可提高设备生产效率，需要拉通存储器件前才原厂和全志原厂定制设备联调，适用于超大规模产品的量产。

![PhoenixSuit](https://d1.docs.aw-ol.com/assets/img/image-20210310195432915.png)

### 开发板硬件简介

D1-H 哪吒开发板，宛若一把瑞士军刀，可以连接许多外部设备。

![连接示意图](https://d1.docs.aw-ol.com/assets/img/image-20210415171224695.png)

![](https://d1.docs.aw-ol.com/assets/img/D1-H%E5%93%AA%E5%90%92%E6%A1%86%E5%9B%BE.png)

### 编译第一个程序：Hello World

`hello_world.c`

```
#include <stdio.h>
int main(int argc, char const *argv[])
{
    printf("Hello NeZha\n");
    return 0;
}
```

**交叉编译**

交叉编译是指在我们的 PC 机上编译可以在开发板上运行的可执行程序文件，因为是在上位机上编译，然后在不同体系结构的开发板上跑，所以叫 *交叉编译*。

```
./prebuilt/gcc/linux-x86/riscv/toolchain-thead-glibc/riscv64-glibc-gcc-thead_20200702/bin/riscv64-unknown-linux-gnu-gcc -o hello_world hello_world.c
```

**下载 Hello World 文件**

编译完成后需要将编译好的 hello_world 文件下载到开发板上运行。

传入文件可使用的方法多种多样，仁者见仁智者见智。可用的方法简传单列举：

1. ADB 工具
2. nfs 挂载文件系统
3. 使用 SD 卡挂载

```
$ adb push hello_world ./
```

![adb](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/c80696d3-3860-4157-b272-41f0a6a88799/Untitled.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20220317%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20220317T165734Z&X-Amz-Expires=86400&X-Amz-Signature=bb640411add3a1d36dac84e8e64a26c4d3322bf95ff2b874081f8459522a5bc2&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22Untitled.png%22&x-id=GetObject)

### USB 摄像头拍照 Demo

USB Camera demo 代码包，下载地址：[D1-H USB camera demo source code](https://www.aw-ol.com/downloads/resources/43)

![usb camera](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/ee5671bb-c15e-495a-ac58-035f0a8dc102/Untitled.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=AKIAT73L2G45EIPT3X45%2F20220317%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20220317T165912Z&X-Amz-Expires=86400&X-Amz-Signature=4bdf9de0e0887dbea4af8663d5ce72627efe128036cec78ad73d78d4316e654c&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22Untitled.png%22&x-id=GetObject)

使用公司的 UVC（webcam) 摄像头测试可以抓取图像。

![uvc](/wp-content/uploads/2022/03/riscv-linux/images/d1/uvc.jpeg)

后面还有更多示例，我就没有一一测试了。

## 参考文档 

1. [D1-H 芯片介绍](https://d1.docs.aw-ol.com/)
2. [D1_SDK_Howto](https://linux-sunxi.org/D1_SDK_Howto)
3. [ADB Download - Get the latest version of ADB and fastboot](https://adbdownload.com/)
