---
layout: post
author: 'Wang Chen'
title: "Shell 中的 2>&1 命令是什么，这次彻底搞清楚了"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /shell-redirect-stderr-stdout/
description: "Shell 中的 2>&1 命令是什么，常常傻傻记不清，这次彻底搞清楚了"
category:
  - Shell
tags:
  - stderr
  - stdout
  - redirect
  - bash
---

> By unicornx of [TinyLab.org][1]
> Jan 22, 2020

在 Shell 编程中我们经常会看到一些命令的尾巴上会加上 “2>&1”，譬如：
```
ls foo > output.txt 2>&1
```
由于以前对它的语法一直是抱着得过且过的态度，所以每次用起来就老是记不清楚，然后就是一通搜索、拷贝、黏贴。如此恶性循环，终于今天忍受不了自己的放纵，上网搜了搜，搞得差不多清楚了，赶紧记下来和大家分享一下，希望真正成为自己的知识。


## 标准输出重定向

先从一个我们平时最常见的操作开始讲起。如果想看一个文件的内容，最常使用的是 cat 命令。默认情况下，cat 命令会将指定文件的内容打印出来并输出到一个接收输出的对象上，我们称这个接受程序打印输出内容的对象为 “标准输出（standard output）” ，简称 “stdout”。具体这个 stdout 是什么或指向谁，并不固定，默认情况下它指向我们计算机的屏幕（或者叫终端 terminal），逻辑关系可以想象成这样：

```
command ---> stdout ---> terminal
```

假设这里 command 是 `cat hello.txt`。换句话说，就是 cat 命令会将 hello.txt 的文件内容通过 stdout 输出显示在屏幕上，命令执行效果如下：

```
$ cat hello.txt
Hello world！
```

“Hello world!” 是 hello.txt 文件的内容，被 cat 打印在屏幕上了。

但是我们可以改变 stdout 指向的对象。这就涉及到 “重定向” 的概念了。首先我们要知道 Shell 的 “重定向” 功能分两种，一种输入重定向，一种是输出重定向；从字面上理解，输入输出重定向就是 “重新改变输入与输出的方向” 的意思。在这里我们主要以输出重定向为例，假设我们希望将 cat 命令的输出打印到一个名为 output.txt 的文件中去，而不是打印到屏幕上。其本质就是将 stdout 从原本指向屏幕改为指向 output.txt 这个文件，逻辑关系修改如下：

```
command ---> stdout ---> output.txt
```

为实现以上方式，命令行可以这么写：

```
$ cat hello.txt > output.txt

$ cat output.txt
Hello world！
```

其中 `>` 就是 shell 中实现 “重定向” 输出的操作符。观察第一条命令的执行结果我们会发现，cat 命令不会在屏幕上产生任何输出。因为我们已经将输出的默认位置更改为文件，所以 cat 命令会将 hello.txt 的内容打印到 output.txt 文件里，所以第二条 cat 命令在屏幕上输出 output.txt 的内容，我们看到了 hello.txt 的内容。


实际上我们常写的 `cat hello.txt > output.txt` 这种语法是简写形式，标准的写法如下：
```
$ cat hello.txt 1> output.txt
```

这里注意几点：
- `1` 是 stdout 在 Shell 中的代号（官方的说法是文件描述符的值，但本文不打算展开这个知识点），大部分用过 Linux/Unix 的人应该都是知道的。
- `1` 和 `>` 之间不可以有空格，这个是 Shell 的语法要求，`1> output.txt` 整体上表达的意思就是 stdout 现在指向了 output.txt。
- `>` 和 `output.txt` 之间可以没有空格，也就是说，写成 `cat hello.txt 1>output.txt` 或者 `cat hello.txt >output.txt` 都是可以的。

## 标准出错重定向

如果我们执行 shell 的命令发生错误，譬如 cat 一个不存在的文件，如下所示，Shell 会产生 “出错信息”。注意，这里是执行出错才产生的输出信息，有别于正常情况下输出的文件中的内容信息，Shell 会将 “出错信息” 输出给另一个特殊的对象，这个对象我们称之为 “标准出错（standard error）” ，简称 “stderr”。具体这个 stderr 是什么或指向谁，并不固定，和 stdout 一样，默认情况下它指向我们计算机的终端，逻辑关系可以想象成这样：

```
command ---> stderr ---> terminal
```

具体命令执行的例子如下，假设 nop.txt 这个文件并不存在。

````
$ cat nop.txt
cat: nop.txt: No such file or directory
```

“cat: nop.txt: No such file or directory” 是 cat 命令执行失败后输出的 “出错信息”，这里明显是打印在屏幕上了。

基于以上分析，我们应该可以自行分析以下命令为何还会在屏幕上看到出错的信息。

````
$ cat nop.txt > output.txt
cat: nop.txt: No such file or directory
```

出错信息仍然会显示在屏幕上。原因很简单，因为我们这里仅仅重定向了 “stdout”，并没有修改 “stderr” 的指向，所以 “出错信息” 当然还会出现在屏幕上。画一下上面这条命令对应的逻辑关系会更清楚：

```
command ---> stdout ---> output.txt
    |
    +------> stderr ---> terminal
```

因此，如果你不想在屏幕上看到出错打印，可以采取的办法就是重定向 stderr（重新改变 sterrr 的输出方向），将其指向其他的设备，譬如一个文件。和 stdout 类似，stderr 在 Shell 中也有自己的代号是 `2`，并参考前面标准输出的完整写法，我们可以写出如下形式：

```
$ cat nop.txt 2> output.txt

$ cat output.txt
cat: nop.txt: No such file or directory
```

从运行结果中我们可以看到：第一条语句执行后，由于出错信息被修改为打印到文件 output.txt 中，所以不会显示在屏幕上了。逻辑关系图如下所示（注意我们这里补上了 stdout）：

```
command ---> stdout ---> terminal
    |
    +------> stderr ---> output.txt
```

## 标准输出和标准出错同时重定向

如果我们希望 stdout 和 stderr 都输出到同一个磁盘文件中而不是显示在屏幕上该怎么办呢？这就回到开头的例子 `ls foo > output.txt 2>&1`，通过前面的介绍，差不多可以猜个八九不离十了。额外要解释一下的是这里的 `&1`。这依然是 Shell 要求的语法。`&1` 用于引用 stdout，所以 `2>&1` 的意思就是将 stderr 重定向到 stdout。注意在写法上，这里的 `>` 和 `&1` 之间不可以有空格，否则报语法错。完整地看，Shell 对这条命令的解释处理按照从左往右的顺序进行处理，先将 stdout 重定向到 output.txt，然后再将 stderr 重定向到 stdout，最后实现的逻辑关系表示如下：

```
command ---> stdout ---> output.txt
    |          A
    |          |
    +------> stderr 
```  

所以最后达到的效果就是将正常的输出（标准输出）和出错信息（标准出错）都打印到 output.txt 文件里。

再啰嗦一下的是 `2>&1` 不可以写成 `2>1`，否则对于 Shell 来说，不是将 stderr 重定向给 stdout，而是会将 stderr 重定向到一个名字为 `1` 的文件中去。

## 总结

这里总结一下本文介绍的知识点：

- Shell 中的命令会将输出发送给两个对象：标准输出（stdout）和标准错误（stderr），其中 stdout 用于接收正常的程序输出，stderr 用于接收程序出错时的输出。
- Shell 用一个整数值来标识 stdout（1）和 stderr（2）。
- 缺省情况下 stdout 和 stderr 都将输出打印在屏幕上，但我们可以将这些 “输出” 的方向重新修改为指向其他位置（例如文件），这就是所谓的 “重定向” 输出。在语法上 “重定向” 输出的语法是使用 `>`，以重定向 stdout 为例，具体语法是 `command 1> output`，注意 `1` 和 `>` 之间不可以有空格；以上语句也可以简写成 `command > output`。当需要在 `>` 的右边引用 stdout 和 stderr 时，我们需要将其写成 `&1` 和 `&2`，且它们和前面的 `>` 之间也不可以有空格 。
- `2>&1` 的作用是将 stderr 重定向到 stdout。

如果您对这个主题感兴趣，请扫描二维码加微信联系我们：

![tinylab wechat](/images/wechat/tinylab.jpg)

[1]: http://tinylab.org
