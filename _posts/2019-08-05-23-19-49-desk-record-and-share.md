---
layout: post
author: 'Wu Zhangjin'
title: "记录和分享桌面的 n 重境界"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /desk-record-and-share/
description: "本文介绍桌面操作记录和分享的多种方法，包括截图，录制 gif，录制视频，分享视频，直播等。"
category:
  - 效率工具
tags:
  - 桌面截屏
  - Gimp
  - Shutter
  -
---

> By Falcon of [TinyLab.org][1]
> Aug 05, 2019

继上次总结命令行记录和分享之后，又调研了一下桌面分享。

下面依序来介绍：

## 桌面截屏

静态截屏是最常见最简单的操作。对码农来讲，最容易理解的应该是从 `/dev/fb` 直接导出数据，然后自己填充一下 header 变成  bmp，但是这么一来就有点复杂了。何不用简单常用的工具呢，这类工具有 `gimp`, `shutter`。


  * Gimp 用法：`File --> Create --> Screenshot`，选择一个窗口，一块区域或者整个桌面。

  * Shutter 用法：顶栏菜单就提供了非常直观的视觉，同样支持区域选择、桌面选择和某个活动窗口选择。

## 图片格式转化

截屏后的数据格式通常是 `png`，可以做一些转换，主要是调整大小什么的。通常用 `gimp` 也可以搞定，如果要用命令行，可以用 `imagemagick` 提供的 `convert` 工具，可以直接转，它提供比较丰富的命令行选项。如果不想这么麻烦，还是 `gimp` 省事。

    $ convert xxx.png convert.jpg

## 动态录制桌面

桌面视频录制工具超级多，但是好用的呢，并不太多，验证过有效的几个：

* [Simplescreenrecorder](https://www.maartenbaert.be/simplescreenrecorder/)：Ubuntu 17.04 自带
* [OBS Studio](https://obsproject.com/)：跨平台，还可以用来直播
* [Peek](https://www.ghacks.net/2018/04/27/a-look-at-peek-screen-recorder-for-gnu-linux/)： 不支持声音，支持 gif，但是界面很直观
* kazam：支持截图和录屏，格式比较丰富，PPA: `ppa:kazam-team/stable-series`
* [Showdesk.io/pyvnc2swf](http://www.showdesk.io)：VNC 录屏和分享

## 视频格式转换

先来个比较常用的，那就是视频转换为 `gif`，这个很有用，因为 `gif` 是所有浏览器都支持的格式，类似，`jpg`, `png`，但是却是一种动图（视频）表达方式。

从调研的资料来看，一般都是先用 `mplayer/ffmpeg` 把视频转为 `png/jpg`，然后用 `convert` 或者 `gifski` 转换为 `gif`：

    $ mplayer -ao null `XXX`.mp4 -vo jpeg:outdir=./`XXX`
    $ convert ./tabs/*.jpg view.gif

或者

    $ ffmpeg -i video.mp4 frame%04d.png
    $ gifski -o file.gif frame*.png

`mplayer`, `ffmpeg` 可以用 `apt-get` 安装，`gifski` 可用 `snap` 安装。

## 图像编辑

再次画重点，gimp。

## 视频编辑

调研过比较好用的就数：Openshot

更多：[Linux 上最好的 9 个免费视频编辑软件（2018）](https://linux.cn/article-10185-1.html)

## 视频分享

B 站、腾讯视频、抖音等

## 视频直播

虎牙、快手、斗鱼等

[1]: http://tinylab.org
