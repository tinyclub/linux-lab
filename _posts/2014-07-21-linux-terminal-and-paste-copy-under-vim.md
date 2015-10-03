---
title: 在 LINUX 终端和 VIM 下复制粘贴
author: Wen Pingbo
layout: post
permalink: /linux-terminal-and-paste-copy-under-vim/
tags:
  - clipboard
  - 粘贴
  - Linux
  - Vim
  - 复制
categories:
  - Vim
---

> by WEN Pingbo of [Tinylab.org][1]
> 2014/07/21

在GUI界面下，我们可以很自由的复制粘贴。但是在字符界面下，我们不得不用鼠标选定，然后单击右健，选择复制，再到别处去Ctrl-v。并且对于那些用没有配置过的VIM来说，VIM的粘贴板和X Window的粘贴板还不共享。这在码字的过程中，感觉非常不流畅。下面，我们就尝试解决这个问题。

首先我们得让VIM和X Window共享一个粘贴板，这样我们就可以像在GUI界面下一样去复制粘贴了。我们可以在自己的VIM配置文件.vimrc里添加这么一行：

<pre>set clipboard=unamedplus
</pre>

这行配置的意思是让VIM把$$&#8217;+'$$这个寄存器(粘贴板)设置为平常yank和p操作的默认粘贴板，而$$&#8217;+'$$寄存器在VIM里就是代表X Window的粘贴板。这样我们就让VIM和X Window共享一个粘贴板，再也不用担心VIM里复制的东西，不能在VIM外去粘贴。

但是这里要注意，如果你下载的是基本VIM的话，按照上面的设置是无法实现预期的效果的。因为VIM基本版默认不支持X Window的粘贴板，所以你得安装VIM完全版，或者巨型版。你可以执行如下命令去判断你的VIM是否支持X Window的粘贴板：

<pre>vim --version | grep clipboard
</pre>

如果clipboard和xterm_clipboard带有加号，那么就表示支持这个特性，减号就表示不支持。

在Ubuntu下面，你应该安装vim-gnome，而在fedora下面，你需要安装vim-X11。

这都做完后，你会发现VIM在每次退出的时候都会清空粘贴板，而这并不是我们想要的。我们可以在VIM配置文件里添加下面一行配置，来让VIM在退出的时候，保留粘贴板中的内容：

<pre>autocmd VimLeave * call system("xsel -ib", getreg('+'))
</pre>

这个配置其实就是在VIM每次退出的时候，运行xsel命令来把&#8217;+'寄存器中的内容保存到系统粘贴板中，所以这个配置要求你安装xsel。

现在，假设我们从VIM中yank一些内容，然后退出VIM，粘贴到终端命令行上，这个时候我们可能还是得拿起鼠标，右键粘贴。其实在大多数terminal中都有一个快捷键：Ctrl-Shift-v，把内容粘贴到命令行中。这样我们就解决了在终端下面粘贴的问题。

可能有人会问，在终端下面复制怎么办？这个，暂时还没有找到很满意的解决方案。





 [1]: http://tinylab.org
