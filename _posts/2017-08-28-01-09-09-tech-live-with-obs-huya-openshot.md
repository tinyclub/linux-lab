---
layout: post
author: 'Wu Zhangjin'
title: "用 OBS 和虎牙进行 IT 技术直播"
tagline: "Linux直播第1期：用 Linux Lab 做《奔跑吧 Linux 内核》实验"
album: Linux 直播
permalink: /tech-live-with-obs-huya-openshot/
description: "本文介绍在Macbook下，如何用OBS和虎牙进行IT技术直播，并顺带介绍如何用Openshot剪辑视频并发布到腾讯视频上。"
category:
  - Linux Lab
  - 视频直播
tags:
  - OBS
  - 虎牙
  - Openshot
  - 腾讯视频
  - Open Broadcaster Software
  - 奔跑吧Linux内核
---

> By Falcon of [TinyLab.org][1]
> 2017-08-28 01:09:09

## 如何进行 IT 技术直播

随着手机的普及和网络带宽的提升，直播现在变成了一种潮流，打开手机，随时随地可以跟友人还有粉丝分享所有的喜怒哀乐，这类直播的内容蛮多是轻松娱乐的范畴，而素材通常是图像，对手机显示非常友好。

更为严谨的 IT 技术直播也在逐步兴盛起来。由于 IT 技术直播通常伴随代码的展示、命令的执行，这些不能轻松地在屏幕较小的手机上完成，必须借助台式机或者笔记本。不过，受限于直播软件，这类直播目前局限于 Windows 系统。包括虎牙、易直播、斗鱼等软件都只支持 Windows 系统，而且不支持虚拟机中的 Windows，因为即使知名如 Virtualbox 和 VMware 都无法支持 DX11。

作为 Linux 控和 Macbook 用户，是颇为苦恼的。不过幸甚地是，有一款强大的 [OBS][3] 软件解决了这个难题，它支持 Windows 7、MacOS 10.10+ 和 Linux，而且完全通过 [Github][4] 开源。

OBS 不仅实现了本地录制，还可以通过推流实现直播。它内建支持多家流媒体服务机构，我们需要做的是找到一家国内较为知名的流媒体服务器提供商。而虎牙（YY）恰好支持第三方推流，这实际上就解决了客户端的问题，因为虎牙可以同时通过客户端或者浏览器观看。

OBS 录制的视频可以通过 Linux 上的知名视频编辑工具 Openshot 完成编辑，编辑完成后即可上传到腾讯视频等渠道发布。

上述工具的具体用法如下：

### 虎牙

* 首先注册[虎牙][7]帐号
* 下载 YY 手机客户端（方便测试）
* 在线获取推流地址
    * 进入[虎牙个人中心][8]
    * 通过主播设置，开通远程推流
    * 设置直播模式为“普通左右3D”（必须，否则在 Macbook 下直播时客户端没有声音）
    * 获取推流地址并开播。记下这个流地址。

![Huya Image](/wp-content/uploads/2017/08/i.huya.com.png)

### OBS

* 在 [OBS主页][3] 或者 [Github项目发布页][5] 下载对应系统的版本，MacOS 就下载 pkg，Linux 就根据[这里][6]下载。
* 安装完成后启动 OBS 并进行相应设置
    * 在“通用”里头选择好语言
    * 在“流”中配置好流媒体服务，选择自定义类型，并把 URL 设置为在虎牙获得的流地址。
    * 在“视频”中设置 FPS 为 30。
    * 另外需要在“输出”设置中选择一个剩余空间较大的位置存放录像，并勾选生成没有空格的文件名。
    * 其他内容保持默认设置。
* 直播素材可以选择各种丰富的来源
    * 音频设备
    * 视频设备
    * 整个桌面
    * 单个窗口
    * 某个幻灯片
* 作为 IT 技术直播，我们选择捕获某个窗口。记得先开启该窗口，并打开一个画面，然后再选择窗口捕获。如果录制时屏幕黑屏，请多次按下 `ALT+Enter` 快捷键。
* 之后就可以根据需要选择“开始推流”，“开始录制”。
* 点击“开始推流”后，在虎牙里头就应该可以正常看到视频、听到声音。

![OBS Image](/wp-content/uploads/2017/08/obs.png)

### Openshot

录制完的视频可以用 Linux 下的 Openshot 进行剪接，剪接时可以根据进度和需要进行分片、标记、删除、重排，也可以插入图片和其他视频素材。

内容可以根据录制的分辨率选择是 HD 720P 30fps （1280x720）还是 HD 1080P 30fps（1920x1080），输出格式保留为 OBS 默认的 FLV (h.264)，中等质量。

![Openshot Image](/wp-content/uploads/2017/08/openshot.png)

### 腾讯视频

通过 QQ 或者QQ安全中心扫码即可登陆上传[腾讯视频][9]，至此一个完整的直播、收看、录像编辑和视频发布就完工了。

## 泰晓第一期公益直播

泰晓的第一期公益直播就用上述工具完成。

我们于 2017/8/26 15:00 准时进行了一场题为“用 Linux Lab 做《奔跑吧 Linux 内核》实验”的直播，该直播旨在通过演示和互动的方式进一步介绍如何高效地学习 Linux。

[《奔跑吧 Linux 内核》][10]一书于 2017/8/22 日上市，基于 ARM32/ARM64 架构介绍了 Linux 4.0，以实际问题为导向，讲解深入透彻并反映内核社区技术发展。

[Linux Lab][11] 基于 Docker 和 Qemu，可用于快速构建一套嵌入式 Linux 系统和内核的实验环境，内建 4 大架构和 10 多款虚拟开发板，支持调试和测试，内置交叉编译器，预编译了内核和文件系统，可高效开展 Uboot、内核、驱动和文件系统等实验，可用于辅助 Linux 内核、嵌入式 Linux 系统的学习，也可以用于辅助验证提往官方 Linux 的内核 Patch。

这期直播充分展示了 Linux Lab 的便利性，也初步展示了如何开展《奔跑吧 Linux 内核》一书中基于 ARM32/ARM64 架构的内核实验。

## 直播成果展示

直播过程中我们录制了一份视频并上传到了腾讯视频网站上，欢迎观看并回复交流。请大家切换画质到高清观看，在手机上需要腾讯视频客户端才能看高清。

点击如下图片即可进入视频播放界面：

<a target="_blank" href="https://v.qq.com/x/page/y0543o6zlh5.html" title="用Linux Lab做《奔跑吧Linux内核》实验">![Linux Lab with Docker](/wp-content/uploads/2017/08/docker-linux-lab.jpg)</a>

如果喜欢该内容，也欢迎扫描如下二维码赞助和鼓励我们继续制作更精彩的 IT 技术直播和视频。

[1]: http://tinylab.org
[2]: https://v.qq.com/x/page/y0543o6zlh5.html
[3]: https://obsproject.com
[4]: https://github.com/jp9000/obs-studio
[5]: https://github.com/jp9000/obs-studio/releases
[6]: https://github.com/jp9000/obs-studio/wiki/Install-Instructions#linux
[7]: http://www.huya.com
[8]: http://i.huya.com
[9]: https://v.qq.com
[10]: /learning-rlk4.0-in-linux-lab/
[11]: /linux-lab
