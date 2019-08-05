---
layout: post
author: 'Wu Zhangjin'
title: "记录和分享命令行的 n 重境界"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /cli-record-and-share/
description: "本文介绍了记录和分享命令行的若干工具，包括 script, screen, ttyrec/ttyplay, tmux, showterm 等。"
category:
  - 效率工具
tags:
  - script
  - screen
  - ttyrec
  - ttyplay
  - tmux
  - showterm
  - 共享命令行
  - 录制命令行
  - 回放命令行
---

> By Falcon of [TinyLab.org][1]
> Aug 05, 2019

张健老师说职业成长一个很重要的习惯是：记录工作日志。

非常认可，好记性不如烂笔头，我原来有一个小结：记录工作日志是为了避免在重复遇到同类问题时不知所措、抓狂和恐慌。

您怎么记录工作日志呢？用传统的纸和笔，还是写在博客上，写在博客上是静态的纯文字，还是结合一些 Repeatable 的辅助工具呢？用工具记录操作过程的好处是可以避免手动敲错。

笔者认为现代的工作日志记录方法有 n 重境界，我把它们都藏在 [Linux Lab](http://tinylab.org/linux-lab) 了，让我们一一揭秘。

## 第 1 重：静态记录和分享

`script` 可以录制所有命令行操作，默认存放在 `typescript` 文件中。用法：

    $ script
    $ # do what you like
    $ exit

## 第 2 重：动态记录、回放和分享

`script` 支持录制时间信息，`scriptreplay` 支持回放。

    $ script --timing=typetime
    $ # do what you like
    $ exit

    $ scriptreplay typetime

补充一下，类似 `script/scriptreplay` 记录时间戳并回放的功能，有一个 `ttyrec/ttyplay` 可以实现同样功能，只不过，后者把操作过程和时间戳打包在一个文件里头，不方便人类阅读，不过好处是，分享给其他人的时候，分享单一文件即可。

## 第 3 重：交互式记录和分享（共享命令行）

如果想交互式分享，也就是说，一个人在操作，另外一个人可以实时看到命令行操作过程的话，可以用 `screen`，目前 Linux Lab 默认没安装。

    $ sudo apt-get install screen

开启一个控制台，启动会话：

    $ screen -S sharing

开启另外一个，连接过去，可以完全共享，两个都可以操作：

    $ screen -x sharing

要记录日志的话，加个 `-L`，默认存在 `screenlog.0` 这样的文件中。

张健老师补充：`tmux` 可以实现类似功能，测试了一下，果然可以。

    $ sudo apt-get install tmux

新建一个会话：

    $ tmux new -s sharing

连上去：

    $ tmux a -t sharing

## 第 4 重：本地记录，回放，分享到任何地方

Linux Lab 有提供一个 `showterm` 工具，用法类似 `script`，但是录制完会自动上传到网络并生成一个链接，链接通过浏览器打开就可以回放录制的结果。

    $ showterm
    $ # do whatever ...
    $ exit
    showterm recording finished.
    Uploading...
    showterm

上述链接可以分享到朋友圈，嵌入到博客，例如：

    <iframe src="showterm width="100%" height="480" marginheight="0" marginwidth="0" frameborder="0" scrolling="no" border="0" allowfullscreen></iframe>

补充一下，有一个 [ttyplayer.js](https://github.com/meowtec/ttyplayer.js) 可以类似 `showterm` 那样把录制好的命令行视频发布到网络上。

[1]: http://tinylab.org
