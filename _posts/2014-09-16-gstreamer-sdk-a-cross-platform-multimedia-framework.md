---
title: GStreamer 多媒体开发：现已加入 Android 和 iOS 平台
author: Chen Jie
layout: post
permalink: /gstreamer-sdk-a-cross-platform-multimedia-framework/
tags:
  - Android
  - Android NDK
  - GStreamer
  - GStreamer SDK
  - iOS
  - Multimedia
categories:
  - GStreamer
---

> by Chen Jie of [TinyLab.org][1]
> 2014/09/14


## 前言

曾经有人对比了 GNU/Linux 和 Android 的声音输出系统，即 [PulseAudio vs AudioFlinger][2]。结论是 PulseAudio 更加优秀，并建议保留 AudioFlinger 外部接口，用 PA 替代其内部实现。

的确，GNU/Linux 积累了一些优秀的组件。由于 Android 和 GNU/Linux 平台的一些相近性，使得这些组件被移植到 Android 平台，成为 Android NDK 开发中的有用组件。

本文介绍了我们在 Android 平台上使用多媒体库 GStreamer 进行开发的一些体验。

## GStreamer SDK 简介

GStreamer 是 GNU/Linux 一个主流的多媒体库。GStreamer 大部分内容是插件 &#8212; 按照 pipeline 模型，定义了类和接口。GStreamer 插件大部分是将已有多媒体库进行封装，使之能接入 pipeline。

一些公司围绕 GStreamer 框架提供商业服务。例如提供专有插件，甚至提供应用开发和咨询服务。为了在各平台上提供一个稳定的 GStreamer 基础，以便于商业化的开展，于是有了 [GStreamer SDK][3] 的发布。

GStreamer SDK 本身是开源的，支持 GNU/Linux、Android、Windows、iOS 和 Mac OS X 平台，并可通过名为 [cerbero][4] 的工具，[从源代码生成 SDK][5]。顺便说一句，cerbero 还能用于 [OS X 上的 GNU 编译环境的搭建][6]。

GStreamer.com 提供了若干[示例][7]，以便快速上手。

GStreamer 的魅力在于其 pipeline 模型，而基于 GStreamer 的应用开发，核心在于 GStreamer pipeline 的设计。

以下以电子书包应用中的视频广播功能点（[专利][8]申请号：2013104123754）为例，来展示 GStreamer 的开发体验。

## GStreamer 应用实例：电子书包中的视频广播功能

我们的电子书包视频广播功能中，有一台 PC 机作为教师机，并通过无线网络向教室内的学生平板推送视频 &#8212; 老师选择视频文件后播放，学生平板即显示视频。

    filesrc location= ! decodebin name=dec ! tee name=tee \
    tee. ! videoconvert ! some_encoder  ! rtp???pay ! some_netsink  \
    tee. ! queue max-size-buffers=0 max-size-bytes=0 max-size-time=1000000000 \
           min-threshold-time=1000000000 ! videoconvert ! some_videosink


上述是视频广播中教师机 GStreamer pipeline 的描述，“!” 表示连接 pipeline 中的各元素。本条 pipeline 以 filesrc 作为流媒体的源，decodebin 解析媒体流，分离视频和音频数据（demux），并分别解码。解码后的数据通过 tee 这个组件，分成一模一样的两路。其中一路编码后向网络输出（some\_netsink），另一路则直接在本地输出（some\_videosink）。

在实际场景中，使用无线组播来推送视频。然而无线组播的链路层是不可靠的，因此相比单播情形，丢包明显严重。于是，我们引入前向纠错编码技术（FEC）&#8211; 按照窗口发送，先发送 N 个有效数据包，再接着发送 M 个冗余数据包。

当网络丢包发生时，接收端只收到例如 &#8220;N &#8211; 1&#8243; 个有效数据。此时，当接收端再收到若干个冗余数据包，依据特定 FEC 算法，便能找回丢失的有效数据。换句话说，只有接收完一个窗口，才能进行 FEC 恢复并向后提交数据。这就产生了额外的延时。

再来看 tee 分出的两支，一支进行视频编码以后即向网络发送。而另一支，则进入一个队列（queue），队列规定了最小长度 `min-threshold-time=1000000000`，即队列中数据至少能回放 `10^9` 纳秒。队列同时又规定了最大长度 `max-size-buffer=0 max-size-bytes=0 max-size-time=1000000000`，即队列中的数据最多能回放 `10^9` 纳秒。

由于此固定长度为 1 秒的队列存在，使得本地视频输出总是晚于网络输出 1 秒钟。而这 1 秒钟，是用来覆盖 FEC 引入的延时，从而达成画面同步。

学生平板 GStreamer pipeline 如下：

    some_netsrc  caps='...' \
    rtpjitterbuffer latency=1000 ! rtp???depay ! some_decoder ! some_videosink


在学生平板，我们为 FEC 引入的传输窗口准备了 1 秒的延时，该延时用 **rtpjitterbuffer latency=** 方式告诉 GStreamer pipeline。

总结一下，在教师机，我们构造特殊的 GStreamer pipeline，使得同一帧画面，提前 1 秒在网络发送。而学生平板在 1 秒时间内，完成此帧接收并向后提交。双方几乎都在此帧原本该显示的时刻延后 1 秒来显示画面，从而达成画面同步。

## 小结

GStreamer SDK 是一个功能强大的多媒体框架，它支持多个平台。我们尝试将它运用于 Linux、Windows 和 Android 的应用开发中，并取得了成功。

就如同所有跨平台的框架一样，一定会遇到一些平台相关的问题。从我们的使用经验而言，GStreamer SDK 的 Windows 端问题相对较多，主要是因为 Windows 端需要使用非 POSIX 的 Windows APIs，这部分关注相对较少。

Android 端的问题分为几类。一是和设备搭载的 Android 系统本身质量参差不齐有关，例如我们遇到过 ARM v7 以上 CPU 级别还对快速非对齐访问报异常，导致应用退出。其次可能是 Android 平台的普遍性问题，例如 Mediacodec APIs 方面，我们测试过的平板都不能报正确的色彩格式，且 Android 的测试用例也未覆盖。最后，还可能与平板的硬件及对应支撑软件有关，例如硬件解码器不支持低延时、分片方式编码的视频流 &#8212; 或是底层硬解线程崩溃，或是画面卡住不动。相信这种情况在 “制式统一” 的 iOS 平台上不会出现。

最后 GStreamer SDK 也支持 Mac OS X 和 iOS 平台，然而我们尚未有机会进行此方面的尝试。





 [1]: http://tinylab.org
 [2]: http://lwn.net/Articles/475733/
 [3]: www.gstreamer.com
 [4]: http://docs.gstreamer.com/display/GstSDK/Multiplatform+deployment+using+Cerbero
 [5]: http://docs.gstreamer.com/display/GstSDK/Building+from+source+using+Cerbero
 [6]: http://cee1.github.io/blog/2013/12/13/life-with-mac-day-3/
 [7]: http://docs.gstreamer.com/display/GstSDK/Tutorials
 [8]: http://epub.sipo.gov.cn/
