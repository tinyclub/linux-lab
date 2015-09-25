---
title: 如何制作终端中的动画
author: Wen Pingbo
layout: post
permalink: /how-to-write-terminal-animation/
tags:
  - Bash
  - csi
  - Linux
  - script animation
categories:
  - Linux
---

> By WEN Pingbo of [TinyLab.org][1]
> 2015/06/03

在印象中，好像终端就是黑白界面，加扁平输出。是不是很乏味？其实现在 Linux/Unix 系统中带的终端模拟器是支持动画和彩色输出的。下面，一起来看看字符界面下的动画魅力！


## 定点输出

### 回车符(carriage return)

在这之前，我一直下意识的以为回车符和换行符是一个意思，相信有很多人也有这种错误的理解。其实不然，回车符(\r)是把光标返回到行首，而换行符(\n)才是把光标移到下一行。尽管在 Linux 中，是采用换行符作为新行的标识，但终端模拟器中还是会响应回车符 [[1][2]]。

OK，在理解了回车符和换行符的区别后，我们考虑一种情况：当在一行结束的时候，只输出回车符，而没有换行符，会发生什么？由于没有换行，只回到了行首，所以新打印的内容会把当前行覆盖。而我们可以基于这个特性，在脚本中做一些很有意思的动画。这里我写了一个例子，可以尝试一下：

<!-- more -->

<pre>#!/bin/bash

spin=('\' '|' '/' '-')
cnt=0
while(true)
do
    echo -n "handling $((cnt++)), please wait... ${spin[$((cnt % 4))]}"
    echo -n -e \\r
    sleep 0.2
done
</pre>

这里的关键就是 `-n`，强制 echo 不输出换行符。

### 光标移动(CSI码)

单纯在同一行做文章，可能还无法满足一些动画。这时候，可以采用 CSI 码来手动移动光标。CSI(private mode character) 是用来格式化终端的输出。其序列定义为 `[ESC][ + N1; N2; ... S`，而 ESC 可以用 `\e`，`\033` 和 `\x1B` 来表示。这里我们简单的控制一下输出：

<pre>echo -en '\e[2J\e[7;40f this is a test\e[6;38f this is another teset\n\n'
</pre>

这条命令首先用 `\e[2J` 来清屏，`\e[7;40f` 把光标移到到 7,40，输出内容，然后 `\e[6;38f` 把光标移动到 6,38，再输出内容。具体的 CSI 码可以在 [wiki][3] 找到，发挥你的想象力吧。

Linux 下有一个 tput 命令，可以设置终端的属性，若不想用 CSI 码，可以用 tput 代替，具体可以查看 tput 联机文档。

## 色彩化输出

现在输出位置可以自由控制了，那就只剩下颜色了。终端中的颜色也是通过 SGR(select graphic rendition) 码来控制。SGR 是 CSI 的一个子集，其格式为 `CSI + N + m`。其中 N 就是指定颜色的。可以利用 SGR 码来设定字体、加粗、下划线、背景色和前景色。具体效果可以在 [flogisoft][4] 查看，做的很全。这里只举一些基本的例子。

<pre>echo -e 'this is a \e[1mtest'
echo -e 'this is a \e[1;31mtest'
echo -e 'this is a \e[1;4;31mtest'
</pre>

可以看到，有一些效果是可以叠加的。只需中间用分号隔开就可以。

## 一些有趣的例子和工具

在分析完基本的东西后，一起来看看世界各地蛋疼的人做的成果。这里不是否定他们的工作，事实上，我也是这类人。

首先看一下我刚写的，打印一个倒三角形，然后加上一些颜色：

<pre>#!/bin/bash

while true
do
    for i in {20..1}
    do
        echo -en "\e[38;5;$((RANDOM % 256))m"
        # expand twice
        eval printf \' %.0s\' {1..$((41 - i))}
        eval printf \''#%.0s'\' {1..$((2*i -1))}
        echo -e "\e[0m"
    done

    echo -en "\e[20F"
    sleep 0.2
done
</pre>

这里在 for 循环中打印三角形，然后用 `\e[20F` 向上移动 20 行，再继续打印三角形。而 `\e[38;5;$((RANDOM % 256))m` 会在 256 中颜色中随机选择一种颜色。来看一下具体效果：

如果你喜欢《黑客帝国》，可以安装 cmatrix(apt-get install cmatrix)，体验一下字符刷屏的效果。如果你是《星球大战》的粉丝，可以运行一下这个命令 `telnet towel.blinkenlights.nl`，体验一下字符界面下的电影。如果你想要震撼的效果，字符界面下的分形图像，可以运行 `bb(apt-get install bb)`。

另外，如果你想把自己的文字变的很绚丽，可以试一下 toilet，你没看错，就这名字。

<pre>toilet -f term --gay this is a test
</pre>

【编者注：如果想查看更多的控制码，可以 `man console_codes`】





 [1]: http://tinylab.org
 [2]: http://en.wikipedia.org/wiki/Newline
 [3]: http://en.wikipedia.org/wiki/ANSI_escape_code
 [4]: http://misc.flogisoft.com/bash/tip_colors_and_formatting
