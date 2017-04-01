---
layout: post
author: 'Wu Zhangjin'
title: "桌面秀（Showdesk.io）— 轻松录制，即时分享"
tagline: "人类因知识而进步，因分享而伟大，桌面秀（Showdesk.io）让进步来得更猛烈些。"
group: original
permalink: /showdesk-record-and-share-your-desktop/
description: "桌面秀（showdesk.io）基于开源项目 noVNC 和 pyvnc2swf 编写了一套桌面会话录制和播放工具，录制的视频允许通过网页直接播放。"
category:
  - Showdesk.io
  - 效率工具
tags:
  - VNC
  - noVNC
  - Pyvnc2swf
  - Vplayer
---

> By Falcon of [TinyLab.org][1]
> 2017-04-02 01:46:26

## 简介

[Showterm.io][2] 可以轻松录制并分享命令行操作，它有一个很大的优势是可以直接 Copy-paste。但是不足也显而易见，它无法录制完整的桌面会话。

本站在开发虚拟实验平台 [Cloud Lab][3] 时，首先想到了用 Showterm.io 来录制实验过程进而方便新手参照演示内容进行学习，但是发现很多实验依赖图形界面，纯命令行无法完整展示实验过程。巧合地是，该平台的关联项目 [Cloud Ubuntu][4] 用到的 [noVNC][11] 有一个视频录制和演示的雏形，虽然该功能的完整性和易用性无从说起，但至少可以看到桌面会话录制和播放的可行性。

于是，在过去差不多一个月的业余时间里，通过大量艰辛的努力，[Showdesk.io][5]横空出世。

Showdesk.io 的功能性和易用性几乎等同 Showterm.io，但是考虑到桌面会话录制的文件比命令行的纯文本文件要大很多而且可录制的内容更加丰富，为了保障内容的质量并管控文件的大小，Showdesk.io 的文件上传功能是受控的，目前只允许通过 Github 发送 Pull Request。

Showdesk.io 本身即是一套工具集，也是一个集合发布的界面。它集成了视频录制工具（Pyvnc2swf 和 Cloud Ubuntu），视频播放器（Vplayer），视频处理工具（Vtools）以及视频数据库（Vrecordings）：

1. 视频录制工具
    * [Pyvnc2swf][7]：本地录制工具，可以访问标准的 VNC 服务器，并保存为包括 noVNC，FLV，SWF，MPEG 等格式在内的多种视频格式。该工具本身用 Python 编写，因此是跨平台的。
    * [Cloud Ubuntu][4]：集成 noVNC 并用 Docker 容器化：`tinylab/cloud-ubuntu-web`，而且增强了很多功能：优化了 noVNC 的视频大小，加入了可在线控制的录制开关，并允许直接输入标准的 VNC 服务器地址，录制完成后支持直接回放。

2. 视频播放器
    * [Vplayer][6]：基于 noVNC 的回放雏形打造出了一个全功能的播放器(http://vplayer.io)，可通过浏览器打开，可播放本地和远程的视频数据，可通过键盘快捷键、鼠标以及触摸的方式控制启、停和播放进度，也可类似 Showterm.io 轻松嵌入到其他 Web 页面，从而大大方便了视频的分享和传播，进而大大丰富博客、项目首页、开源书籍（如Gitbook）等平台的内容展示形式。

3. 视频处理工具
    * [Vtools][8]：noVNC 默认生成的视频文件过大，无法直接通过网络播放（加载速度无法忍受），该工具通过压缩、Base64编码以及智能拆分等方式进行小型化和流媒体化，不仅节省了流量，也从技术上几乎彻底消除了文件加载带来的长时间等待问题，从而让录制的 noVNC 数据在普通网络包括移动网络环境下播放变得可能。

4. 视频数据库
    * [Vrecordings][9] 暂时未启用独立的数据存储服务，而是直接使用 Github 仓库来存放录制的视频，由于短时间的视频文件大小可控（大约1M/1分钟），而且是拆分成片的，所以对于 Git 来说也是友好的，而且也方便通过 Pull Request 进行视频内容审核。由于 Vplayer 可以播放来自公网任何位置的视频，所以该数据库可以灵活存放。甚至可以直接存放在博客作者们自己的服务器上，又或者直接存放在开源项目的源码目录下。

## 录制、回放、分享

接下来介绍如何通过 Showdesk.io 完成桌面操作视频的录制、回放和分享。

首先下载和安装 Showdesk.io：

    $ git clone https://github.com/tinyclub/showdesk.io
    $ cd showdesk.io
    $ tools/install.sh

上述命令会在桌面创建两个快捷图标，一个是录制工具（noVNC REC），一个是播放器（noVNC Player）。可直接点击开始录制或者回放，也可以通过命令行启动：

    $ tools/record.sh
    $ tools/play.sh

录制完成后，会自动在 `recordings/default/` 下生成视频并生成会话（用于内嵌到其他页面）和发布页面（用于集中展示），例如：

* `recordings/default/2017-03-11/linux-lab.slice*`
* `sessions/2017-03-11-14-16-15-linux-lab.session.md`
* `_posts/2017-03-11-14-16-15-linux-lab.post.md`

之后，即可把上面三类文件提交到服务器上进行分享，可先提交到自己 Fork 的 Git 仓库，再发 PR。需要注意的是，为了方便维护，数据部分需要提交到 `recordings/default` 或者确实有必要，可以在 `recordings` 下再增加一个子的数据仓库。而 `Sessions` 和 `_posts` 需要统一提交到 Showdesk.io 下。

## 内嵌到其他网站

如果要嵌入上述视频到其他站点，可以先从 `sessions/2017-03-11-14-16-15-linux-lab.session.md` 找到地址，例如：

    $ grep permalink sessions/2017-03-11-14-16-15-linux-lab.session.md
    permalink: /7977891c1d24e38dffbea1b8550ffbb8/

接着直接嵌入如下代码即可：

    <iframe src="http://showdesk.io/7977891c1d24e38dffbea1b8550ffbb8/?f=1" width="100%" marginheight="0" marginwidth="0" frameborder="0" scrolling="no" border="0" allowfullscreen></iframe>

如果要自适应视频大小，可以使用 [iframeresizer][5]，在网页中加入如下代码即可：

    <script type="text/javascript" src="https://raw.githubusercontent.com/davidjbradshaw/iframe-resizer/master/js/iframeResizer.min.js"></script>
    <script>
    function resize_iframe() {
        iFrameResize({
                log: false,
                autoResize: true,
                interval: -1,
                minHeight: 300,
                heightCalculationMethod: "lowestElement",
        });
    }

    $(document).ready(function () {
      resize_iframe();
      $('iframe').iframeAutoHeight({debug: false});
    });
    </script>

## 演示效果

<iframe src="http://showdesk.io/7977891c1d24e38dffbea1b8550ffbb8/?f=1" width="100%" marginheight="0" marginwidth="0" frameborder="0" scrolling="no" border="0" allowfullscreen></iframe>


[1]: http://tinylab.org
[2]: http://showterm.io
[3]: https://github.com/tinyclub/cloud-lab
[4]: https://github.com/tinyclub/cloud-ubuntu
[5]: http://showdesk.io
[6]: http://vplayer.io
[7]: https://github.com/tinyclub/pyvnc2swf
[8]: https://github.com/tinyclub/vtools
[9]: https://github.com/tinyclub/vrecordings
[10]: https://github.com/davidjbradshaw/iframe-resizer
[11]: https://github.com/novnc/noVNC
