---
layout: post
author: 'Wang Chen'
title: "Shell 的内置（builtin）命令是什么，常常傻傻分不清"
draft: true
license: "cc-by-sa-4.0"
permalink: /shell-builtin-command/
description: "什么是 Shell 的 builtin 命令，常常傻傻分不清，这次彻底搞清楚了"
category:
  - Shell
tags:
  - builtin
  - bash
---

> By unicornx of [TinyLab.org][1]
> July 1, 2019

最近在总结 Shell 编程的相关概念时碰到一个以前没有很重视的概念，就是 Shell 的 “内置（builtin）” 命令的概念，概念上总有点模模糊糊的，上网搜了搜，搞得差不多清楚了，赶紧记下来和大家分享一下。

原来我们在 Shell 里敲的 “命令（command）” 还分两种（注：严格地说 Shell 环境下可以接受的命令的类型不止这里讨论的两种，还包括 alias 和 function 以及 keyword，详细可以参考泰晓科技另一篇文章 [“为什么 Shell 脚本不工作，语法之外的那些事儿”](/why-shell-scripts-fails/) 的 “程序搜索类型（Type）” 部分的介绍），一种就是普通的命令，譬如常用的 `ls` 这些，而且我们知道这些普通命令实际对应的就是磁盘文件系统里的一个可执行程序，如果要查看这个程序的具体位置，可以使用 `which` 命令如下：

```
$ which ls
/bin/ls
```

也就是说 `ls` 这个程序文件的全路径是 `/bin/ls`。

另外一种 Shell 支持的命令即本文要重点总结的 builtin（“内置”） 命令，builtin 命令是 shell （譬如 bash）里自带的命令，由于其作为 shell 程序（进程）的一部分常驻在内存中，所以和一个普通命令相比起来， builtin 命令的执行速度要快得多。具体的原因很简单，就是因为在 Shell 中执行普通命令即运行程序，要先 `fork()`，然后是 `exec()`，经历创建 子 Shell 进程以及从磁盘上调入程序覆盖原进程的完整过程，而调用一个 builtin 命令本质上只是执行 bash 进程中的一个常驻内存的函数，其速度绝对不可同日而语。

Shell 内部实现了很多 builtin 的命令，其主要目的就是为了提高 shell 命令的执行效率。不同 Shell 程序实现的 builtin 命令集各不相同。为了详细了解你当前使用的 Shell 所支持的 builtin 命令，需要查看 man 手册。譬如对于我们常用的 bash，运行 `man bash` 后搜索 “SHELL BUILTIN COMMANDS” 关键字会有专门的章节介绍 bash 所支持的 builtin 命令。如果我们只是想快速地列出所有 bash 支持的 builtin 命令，也可以在 bash 中执行 `help` 命令，这个命令本身就是一个 builtin 命令。如果是想查看具体的某个 builtin 命令的使用，可以带上 `-m` 参数，如下：

```
$ help -m help
NAME
    help - Display information about builtin commands.

SYNOPSIS
    help [-dms] [pattern ...]

DESCRIPTION
    Display information about builtin commands.
    
    ......

```

由于各种 Shell 所支持的 builtin 命令各不相同，对于有些常用的命令，为避免用户当前所使用的 Shell 不支持，系统会提供同名的程序文件。譬如 `echo`，既是 bash 的 builtin 命令也是一个独立的命令程序。根据 bash 中执行命令的优先级，对于同名的命令，内置命令会优先被执行，所以当我们在 bash 中直接输入 `echo` 命令时执行的是 bash 的 buildin 命令，如果要执行独立的命令程序 `echo`，则需要输入全路径 `/bin/echo`。

如果想要快速确定一个命令究竟是 bash 的 builtin 命令还是一个普通的程序命令，可以使用 `type` 命令进行检测。具体的例子如下，譬如我们要检测一下 `echo` 这个命令对于当前的 Shell 是否是 builtin 命令，可以输入：

```
$ type echo
echo is a shell builtin
```

Shell 如果打印出 `xxx is a shell builtin` 字样，则说明这个命令是一个 builtin 命令。如果不是，则输出类似执行 `which` 的效果，譬如 `cp` 就不是 bash 的 builtin 命令。

```
$ type cp
cp is /usr/bin/cp
```

注意我们在判断一个命令是否是 builtin 命令时，应该使用 `type` 而非 `which`，因为根据 POSIX 的要求， 所有符合 POSIX 标准的 shell 都必须以 builtin 方式支持 type 命令，而 `which` 命令本身就可能不是一个 Shell 的 builtin 命令，自然就无法依靠该命令得知一个 Shell 的buildin 的支持情况。

builtin 命令和普通的命令还有一个明显的区别在于，builtin 命令因为是 shell 的一部分，所以执行 builtin 命令可能会改变 shell的内部状态。从这个角度出发，就不难理解为何我们常用的 `cd` 命令其实是一个 builtin 命令，因为该命令需要改变 Shell 的 pwd（当前工作路径）属性，所以需要实现为一个 builtin 命令。

如果您对这个主题感兴趣，请扫描二维码加微信联系我们：

![tinylab wechat](/images/wechat/tinylab.jpg)

[1]: http://tinylab.org
