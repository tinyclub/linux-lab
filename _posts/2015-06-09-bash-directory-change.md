---
title: 在 BASH 中进行高效的目录切换
author: Wen Pingbo
layout: post
permalink: /bash-directory-change/
tags:
  - Bash
  - dirstack
  - icd
  - Linux
  - popd
  - pushd
categories:
  - Shell
---

> By WEN Pingbo of [TinyLab.org][1]
> 2015/06/02

在 BASH 中你用的最多的命令是什么？这绝对非 cd 莫属(ls 也是个潜力股，暂时做老二吧)。所以在这篇文章中，我们聊聊如何高效的在 BASH 中切换目录。


## 往后切换目录

回退目录，正规的做法是 `cd ..`。但网上的小伙伴很有才，发明了更简洁实用的命令。这里把它搬过来，其实我自己也一直这么用的：

<pre>alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
</pre>

甚至可以定义5点的别名，但感觉用到的几率不大。有了这些别名，就可以愉快的用 N 个点来回退 N 级目录。

其实在进行目录切换时，BASH 默认会把上一个目录记录在 OLDPWD。可以用 `cd -`，或者 `cd $OLDPWD` 来在两个目录之间来回切换。这在两个不同的目录树下，很有作用。

<!-- more -->

## 往前切换目录

进入指定的目录，这个没什么特别的技巧了。老老实实用 `cd /path/to/dir` 来做吧。虽然目的地咱不能省，还是可以偷点懒的。

### CDPATH

我们可以利用 CDPATH 定义 `cd` 命令的 base 目录，然后就可以直达目的地，而不用在前面加一堆父目录。比如：

![bash cdpath][2]

不过这个方法不是很灵活，且有副作用。前段时间，我机器上编译 Android，死活过不去，最后发现是这货搞的鬼。所以，玩玩可以，在生产环境慎用！

### CDSPELL

在 BASH 中打开 cdspell(`shopt -s cdspell`)，可以在你目标目录写错的时候，BASH 能自动帮你矫正，省了重新敲一遍。效果如下：

![bash cdspell][3]

这个还是很有用的，建议打开。

## 目录堆栈

前面讲的大多数是两个目录之间的切换，我们可以简单的用一个变量 OLDPWD 来记录。如果涉及到多个目录，为了记录之前目录切换的历史记录，就得另起一套机制了。而 BASH 就为我们提供了这样一套机制 &#8211; &#8220;目录堆栈(dirs/pushd/popd)&#8221;。其运行机制就是一个堆栈，先进先出。我们可以用 `pushd dir` 来 push 对应的目录路径，用 `popd` 来弹出栈顶的目录，用 `dirs` 可以查看当前堆栈的内容。这个堆栈，在各个 BASH 实例之间是不通用的。也就是说在当前 BASH 中 push 的目录，不会影响其他 BASH。每开一个 BASH，都会初始化一个这样的堆栈。

有的时候，在脚本中需要临时保存当前工作路径，以便回溯。这个时候就可以利用这个目录堆栈了。

## 模拟 Windows Explorer (icd)

之前，我一直纠结在为什么 BASH 只能记录两层目录。当你的工作目录层数比较多的时候，你经常需要多次 `cd ..` 来把工作目录回退 A 目录，然后又要进入 B 目录，再进入 C 目录，最后还要回到 A 目录。尽管前面已经偷了很多懒，还是显得很繁琐。而我的想法是把 Windows 的文件浏览器中前进和后退功能添加到 BASH 中，就像 nautilus 和 各大浏览器做的那样。

为了实现这种效果，首先得记录每次进入的目录路径。这个 BASH 自带的目录堆栈可以做，但是 BASH 在 popd 之后，就把栈顶的路径删除了。这样就导致后退后，无法再前进了。所以得额外定义一套机制来保存目录记录。这里我用一个文件来存放，文件的第一行是记录的路径总数，第二行是当前所在的目录位置，而之后的的每一行就代表一条目录记录。比如：

<pre>3
2
/home
/home/wenpingbo
/var/log
</pre>

这样，后退可以到 `/home`，前进可以到 `/var/log`。另外，为了保证各个 BASH 之间互不干扰，还得引入 session 这个概念。还是直接为每一个 BASH 创建这样一个文件，放在 `/tmp` 下，文件名就以 BASHPID 为后缀，避免重名。

逻辑上，得实现 3 个函数 `icd_main`，`icd_backward` 和 `icd_forward`，用于进入新目录、后退、前进。然后定义快捷键绑定到这 3 个函数，来实现相应的功能。我自己是这样绑定的：

<pre>alias cd=icd_main
alias h=icd_backward
alias l=icd_forward

# Ctrl + right
bind '"\e[1;5D":"h\n"'
# Ctrl + left
bind '"\e[1;5C":"l\n"'
</pre>

这样，就可以用 `h` / `Ctrl-right` 来回退，`l` / `Ctrl-left` 来前进，`cd` 来做正常的目录改变。一起来看一下效果：

![icd][4]

对应的源码，可以在这找到 [icd src][5]





 [1]: http://tinylab.org
 [2]: /wp-content/uploads/2015/06/bash_cdpath.gif
 [3]: /wp-content/uploads/2015/06/bash_cdspell.gif
 [4]: /wp-content/uploads/2015/06/bash_icd.gif
 [5]: https://github.com/wengpingbo/ilinux/blob/master/.icd.conf
