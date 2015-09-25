---
title: 替换 Android 的默认 Console 为 BusyBox Ash
author: Wu Zhangjin
layout: post
permalink: /faqs/replace-the-default-console-for-busybox-android-ash/
tags:
  - Android
  - Ash
  - busybox
  - toolbox
categories:
  - Android
  - Linux
---
* 问题描述

  Android 默认的 [toolbox][1] 工具箱工具太少，而且不遵循标准的Unix工具用法，在Android开发过程中很有必要引入 [BusyBox][2] 这样的“庞然大物”，以满足一些特定的需要，那该怎么引入呢？

* 问题分析

  最简单的用法是直接拿到一个专门为Andriod目标平台编译好的 busybox，放上去，修改权限，直接运行。但是对于某些小型的系统，比如说升级系统或者是充电系统，又或者是刚开始开发的Linux BSP，这些场景下可能要内置BusyBox进去。 内置进去的方式有两种，一种是直接把 BusyBox 安装到目标系统，另外一种则是下面我们要介绍的方式。

* 解决方案

  这里介绍如何获取已经编译好的 BusyBox 工具包，然后内置到 Android 中并替换 Android 原有的 Shell 解释器并确保 BusyBox 的命令可以直接使用。

  * 下载预编译好的 BusyBox

    BusyBox 官方站点提供了二进制的下载地址：http://busybox.net/downloads/binaries/ 确定好自己的目标平台后，比如 ARM v7，则可以下载：

        $ wget -c http://busybox.net/downloads/binaries/1.21.1/busybox-armv7l
        $ mv busybox-armv7l busybox


  * 把 BusyBox 安装到 ramdisk (root) 目录中

    通常会先把 BusyBox 拷贝到厂家设备目录下：

        $ cp busybox device/COMPANY/DEVICE/


    然后在device.mk文件添加安装指令：

        LOCAL_PATH:= $(call my-dir)
 
        PRODUCT_COPY_FILES := \
            $(LOCAL_PATH)/busybox:root/busybox


  * 接下来先创建一个 busybox-console.sh 脚本，用于替代 /system/bin/sh

    这个脚本不仅要启动 busybox 中的 ash 解释器，配置环境变量 PATH 和 SHELL，还需要安装好其他的工具到 /bin 目录下。可以实现为 busybox-console.sh：

        #!/system/bin/sh
        # busybox-console.sh -- 安装BusyBox脚本到/bin并启动/bin/ash解释器
        
        mount -o remount,rw /
        
        mkdir /bin
        chmod 0777 /bin/
        chmod 0777 /busybox
        /busybox --install -s /bin
        
        export PATH=/bin:$PATH
        export SHELL=/bin/ash
        
        /bin/ash


    同样地，这个脚本需要类似步骤二安装到 ramdisk 文件系统中去，类似地先复制到厂家设备目录下：

        $ cp busybox-console.sh device/COMPANY/DEVICE/


    然后追加一条记录到device.mk。

        LOCAL_PATH:= $(call my-dir)

        PRODUCT_COPY_FILES := \
              $(LOCAL_PATH)/busybox:root/busybox
              $(LOCAL_PATH)/busybox-console.sh:root/busybox-console.sh


  * 之后修改 init.rc 替换掉 console 即可

    当然，先要授权，并确保 busybox 的安装路径 /bin 追加在 PATH 变量中，修改如下：

        loglevel 3

        +# Ensure busybox-console.sh executable
        +    chmod 0777 /busybox-console.sh
        +
         # setup the global environment
        -    export PATH /sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
        +    export PATH /bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
           export LD_LIBRARY_PATH /vendor/lib:/system/lib
           export ANDROID_BOOTLOGO 1
           export ANDROID_ROOT /system
        @@ -382,12 +385,9 @@ on property:selinux.reload_policy=1
           restart ueventd
           restart installd
        
        -service console /system/bin/sh
        +service console /busybox-console.sh
           class core
           console
           disabled
           user shell
           group log
        
         on property:ro.debuggable=1
           start console


    最后，编译 Android 就可以生成一个包含 BusyBox 命令并且已经使用 BusyBox ash 解释器的 console 。

    如果想直接在已经编译好的 ramdisk.img 中做上述工作，那么差异就是先要解压 ramdisk.img，拷贝进 busybox 和 busybox-console.sh 并修改 init.rc，随后重新压缩即可。

  * 解压

        $ cp ramdisk.img ramdisk.img.gz
        $ gunzip ramdisk.img.gz
        $ mkdir ramdisk/ && cd ramdisk/
        $ cpio -i -F ../ramdisk.img

  * 压缩

        $ cd ramdisk/
        $ find . | cpio -o -H newc > ../ramdisk.img
        $ gzip -c ramdisk.img > ramdisk.img.gz
        $ mv ramdisk.img.gz ramdisk.img


  关于更多 BusyBox 在 Android 上的用法，可以参考 [Optimizing Embedded Systems using Busybox][3] 一书。




 [1]: http://elinux.org/Android_toolbox
 [2]: http://busybox.net/
 [3]: /optimizing-embedded-systems-using-busybox/
