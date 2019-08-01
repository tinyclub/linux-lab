---
layout: post
author: 'Wu Zhangjin'
title: "在 Linux 下使用分屏提升工作效能"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /linux-multi-screens-usage/
description: "本文介绍了包括 vim, terminator, tmux 在内的几种支持分屏显示的工具，分屏可以提升很多工作的效能，比如说比对代码。"
category:
  - 效率工具
tags:
  - vim
  - terminator
  - tmux
---

> By Falcon of [TinyLab.org][1]
> Aug 01, 2019


手机分屏曾经成为一个大热点，很方便同时做不同的事情，比如说一边看电影，一边跟人聊天。

在 Linux 下，多独立窗口的分屏本来就支持，但是重新开一个窗口其实有点费事，所以一个窗口内分屏就成为了需求。

分屏的一个很重要应用是做代码 porting，可以直接在两屏内分别显示目标代码和参考代码，一眼就可以看到两份代码，无需在多个 Tab 或者多个窗口切来切去。

来个直观的例子，vimdiff 打开两个文件会自动分屏，并高亮显示差异：

    $ vimdiff old.txt new.txt

下面来介绍一下包括 vim, terminator, tmux 在内的三种工具是怎么使用分屏的。

## vim 分屏

vim 是 Linux 系统下最流行的编辑器之一，它支持分屏，而且很好用。

**新建/取消屏幕**

* `:new`：新建文件并水平分屏， 快捷键：`Ctrl + w，n`
* `:vnew`：新建文件并垂直分屏， 快捷键，`Ctrl + w，v`
* `:spilt`：水平分屏，将当前屏分为两个。快捷键：`Ctrl + w, s`
* `:vsplit`：垂直分屏，将当前屏分为两个。快捷：`Ctrl + w, v`
* `:sv 文件路径/文件名`：在新的水平分屏中打开文件
* `:vs 文件路径/文件名`：在新的垂直分屏中打开文件
* `:only`：取消分屏，仅保留光标所在屏幕，关闭其他

**关闭屏幕**

* 关闭当前屏：`Ctrl + w，c`
* 关闭其他屏：`Ctrl + w, o`，效果同 `:only`

**切换窗口**

* `Ctrl + w, w` 后一个
* `Ctrl + w, p` 前一个
* `Ctrl + w, h/j/k/l` 四个方向

注：如果通过浏览器使用控制台，`Ctrl + w` 会关闭浏览器，切换窗口会成为一个麻烦，请在 `~/.vimrc` 添加一个映射，用 `Ctrl + Home/end` 来做切换。

    $ cat ~/.vimrc
    :noremap <c-Right> <c-w>w
    :noremap <c-Left> <c-w>p

## terminator 分屏

Terminator 是 Ubuntu 平台下很强大的控制台工具，它的一个很重要的特性就是分屏。

**新建屏幕**

* `Ctrl + Shift + O`：上下开新窗口
* `Ctrl + Shift + E`：垂直开新窗口

**关闭屏幕**

* `Ctrl + Shift + W`：关闭当前窗口
* `Ctrl + Shift + Q`：退出 terminator

**切换屏幕**

* `Ctrl + Shift + N` 或 `Ctrl + Tab`：前后切换窗口
* `Ctrl + Shift + P` 或 `Ctrl + Shift + Tab`
* `Alt + Up/Down/Left/Right`：上下左右切换窗口

**其他**

* `Ctrl + Shift + Right/Left/Up/Down`：四个方向调整窗口大小
* `Ctrl + Shift + F`：在当前窗口搜索字符串
* `Ctrl + Shift + X`：最大化当前窗口
* `Ctrl + Shift + Z`：切换显示所有窗口 or 仅显示当前窗口

## tmux 分屏

tmux 是另外一款分屏工具，有很多粉丝。

**新建屏幕**

* 上下分屏：`Ctrl + b, "` (按 `Shift + "` 所在按键，很奇葩的设计，得按两次）
* 左右分屏：`Ctrl + b, %` (按 `Shift + %` 所在按键）

**关闭屏幕**

* `Ctrl + b, x`

**切换屏幕**

* `Ctrl + b, o`
* `Ctrl + b, 空格`：上下分屏与左右分屏切换

[1]: http://tinylab.org
