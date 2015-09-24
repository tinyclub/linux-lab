---
title: 把 Android FrameBuffer 裸数据转成图片
author: Wu Zhangjin
layout: post
permalink: /faqs/turn-raw-data-into-a-picture-framebuffer/
views:
tags:
  - Android
  - ffmpeg
  - Framebuffer
categories:
  - Linux
---
* 问题描述

  在Android手机上，假设屏幕正亮着并且显示了一个很好的画面，如果想把这个画面保存下来，该怎么办？

* 问题分析

  正常情况下是截图，用`screenshot`或者`screencap`命令，但是如果系统里头连这两个命令都没有或者不支持，该怎么办？比如在老版本的Android上或者在还没移植好Android只有Linux内核加Busybox文件系统的情况下？

* 解决方案

  可以类似那两个数据，先把FrameBuffer里头的数据拷贝出来，然后转换为某种特定类型的格式。最简单地，可以转换为BMP，因为Framebuffer本身就是BMP图片的裸数据(raw data)，只需要加上BMP的图片头就行，但是手动添加肯定不行，那咱们用工具：ffmpeg。

  假设屏幕分辨率为1280 * 800，FB每个像素的组织方式为RGB32，那么可以：

      $ sudo apt-get install ffmpeg
      $ adb shell cat /dev/graphics/fb0 &gt; fb0.raw
      $ ffmpeg -vframes 1 -vcodec rawvideo -f rawvideo -pix_fmt rgb32 -s 1280x800 -i fb0.raw -f image2 -vcodec bmp img-%d.bmp
