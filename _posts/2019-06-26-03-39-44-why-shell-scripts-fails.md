---
layout: post
author: 'Wu Zhangjin'
title: "为什么 Shell 脚本不工作，语法之外的那些事儿"
draft: false
album: 'Debugging+Tracing'
permalink: /why-shell-scripts-fails/
description: "当一个 Shell 程序的语法确认无误后，还可能有什么原因导致它不能正常工作？有搜索路径、搜索类型、执行权限、不匹配的解释器、平台差异等。"
category:
  - Shell
  - 程序执行
tags:
  - 调试技巧
  - bat
  - bash
  - 解释器
  - 搜索路径
  - 搜索类别
  - 执行权限
  - 平台差异
---

> By Falcon of [TinyLab.org][1]
> May 15, 2019

## 背景简介

前两周群里有同学问了一个问题，是关于 Windows 下的批处理程序，他反反复复检查了语法，没有任何错误，但是执行却出错。

首先，如提问同学讲的：“windows 的 bat 语法真的很反人类啊”：bat 和 shell 一比，以 for 循环为例，确实是反人类！

- Shell 版本

      for i in `seq $2 $3`
      do
          ...
      done

- Bat 版本

      for /1 %%i in (1, 1, %count%) do (
          ...
      )


但是同学们反复看了“确实没问题”，最后有个同学提议把文件名修改一下，原来是 ping.bat，建议修改为 pingip.bat，确实就 ok。

## 程序搜索路径（Path）

从上述修改方法生效的结果来看，猜测是这个 ping.bat 调用到了自己，因为提问者把 bat 文件里头的 ping 改为 ping.exe 也同样 ok。

后面有同学补充到：Windows 下不仅有 `Path` 指定目录的搜索优先级，也有 `PATHEXT` 指定文件后缀的搜索优先级。用 set 命令可以查看（只截取部分 Path）：

    Path=C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\
    PATHEXT=.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC

排在前面优先被搜索。这个 Windows 问题到此为止，作为对比，看看 Linux 有什么不同。

Linux 的不同之处在于，Linux 在程序执行时必须明确指定后缀，没有 `PATHEXT` 一说，只有 `PATH`，可以这样查看，例如：

    $ echo $PATH
    /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

也可以用 export 和 env 命令：

    $ export | grep " PATH="
    $ env | grep ^PATH=

另外，Linux 的 `PATH` 用了冒号分隔符，而 Windows 则是分号。

如果多个程序同名，且放在 `PATH` 指定的不同路径下，可以用 `which` 命令确认是否确实是按前后顺序做优先级的？

    $ which test
    /usr/bin/test
    $ sudo cp /usr/bin/test /usr/sbin/test
    which test
    /usr/sbin/test
    $ sudo rm /usr/sbin/test

从结果来看，确实是 /usr/sbin/ 在前面，先被检索到。

同理，如果自己下载了一个新的编译器，放在某个用户名下的目录下，想优先被使用，那么追加到该路径即可。例如：`~/download/compiler/bin`：

    $ export PATH=~/download/compiler/bin:$PATH

要想这个变量针对用户一直生效，可以把这一行加到 `~/.profile`，如果用户的 SHELL 是 `/bin/bash` 的话，也可以直接追加到 `~/.bashrc`。

    $ echo $SHELL
    /bin/bash

如果要明确执行 /usr/bin/test 这个呢？那就给具体路径吧。

    $ /usr/bin/test 1 -lt 2 && echo "1 < 2"

或

    $ cd /usr/bin/
    $ ./test 1 -lt 2 && echo "1 < 2"

## 程序搜索类型（Type）

除了程序之间同名，还可能跟 builtin、function、alias 同名，它们之间也有执行优先级。

- alias

      $ alias test='echo def'

- function

      $ function test { echo 'abc'; }

- builtin

      $ help test
      test: test [expr]
      Evaluate conditional expression.

- file

      $ which test
      /usr/bin/test

它们之间的执行顺序是什么呢？可以用 type 命令查看：


    $ help type
    type: type [-afptP] name [name ...]
    Display information about command type.


    $ type -a test
    test is aliased to `echo def'
    test is a function
    test () 
    { 
        echo 'abc'
    }
    test is a shell builtin
    test is /usr/bin/test

可以看到，执行顺序依次是 alias, function, builtin command 和 file。当然，还有一种是 keyword，就是 Shell 内建的关键字，例如 `function`。

`builtin` 和 file 可以明确指定：

- builtin

      $ builtin test

- file

      $ env test
      $ $(which test)
      $ /usr/sbin/test 

`alias` 和 `function` 如果存在的话，就会按顺序执行了。为了避免混淆，尽量不要定义同名的 alias, function, builtin 和 file，更不要跟 keyword 同名。

## 检查执行权限

如果执行下面的命令，会怎样？

    $ sudo chmod -x /usr/bin/test

    $ /usr/bin/test
    bash: /usr/bin/test: Permission denied
    $ which test

提示没有权限，并且用 `which` 找不到了，用 `type -a test` 也一样找不到。

所以，通常要让一个程序能够执行，必须要授予权限。

但是诸如 Shell 这类的解释型语言是个例外，因为可以通过传递参数的方式执行，只要解释器具有执行权限即可。

先看看普通的执行方式：

    $ echo "echo Hello" > hello.sh
    $ chmod a+x hello.sh 
    $ ./hello.sh 
    Hello
    $ chmod a-x hello.sh
    $ ./hello.sh
    bash: ./hello.sh: Permission denied

普通方式确实不可行，不过 `bash` 提供了三种另外的方式来执行：

    $ . hello.sh
    Hello
    $ source hello.sh
    Hello
    $ bash hello.sh
    Hello

    $ help source
    source: source filename [arguments]
      Execute commands from a file in the current shell.
    $ help .
    .: . filename [arguments]
      Execute commands from a file in the current shell.

`source` 和 `.` 是在当前 Shell 执行来自指定文件中的命令集，而 `bash file` 是启动一个新的 Shell 来执行。

## 指定正确的解释器

Shell 的解释器有很多种，常用的就有 bash，dash，zsh 等，每个支持的语法虽然大体相同，但是部分微小的差异可能就要死掉很多脑细胞。

在 dash 的 manpage 可以看到这么一段：

> dash is the standard command interpreter for the system. The current version of sh is in the process of being changed to conform with the POSIX 1003.2 and 1003.2a specifications for the shell. This version has many features which make it appear similar in some respects to the Korn shell, but it is not a Korn shell clone (see ksh(1)). Only features designated by POSIX, plus a few Berkeley extensions, are being incorporated into this shell. We expect POSIX conformance by the time 4.4 BSD is released. This man page is not intended to be a tutorial or a complete specification of the shell.

虽然有标准（POSIX 11003.2/1003.2a）对 Shell 做了约定，但是不同的解释器添加了自己的 Extensions。

由于 Shell 解释器的差异，在不同发行版下同一个程序的执行结果可能会千奇百怪。所以，明确指定一个特定的解释器是更为靠谱的方式。因为很难保证只用那些标准的 features，而且测试兼容性就是很靠费时间的而且蛮多时候是没必要的，比如本来就是想用 Shell 来解决一个临时问题，效率当然是首要的。

在脚本开头指定解释器，例如：

    #!/bin/bash

    echo Hello


由于 `/bin/sh` 通常只是指向某个解释器的链接，所以尽量不要用 `#!/bin/sh`：

    $ ls -l /bin/sh
    lrwxrwxrwx 1 root root 4 Mar 17 09:06 /bin/sh -> dash

在一个平台上可能是 dash，另外一个平台可能又链接到了 bash，脚本可能就废了。记得 Ubuntu 在某个版本之后把默认的 Shell 从 bash 换成了 dash，就导致了很多问题。

如果想延续自己的使用习惯，建议在安装新系统后，第一件事情是明确指定自己的 Shell 为自己喜欢和熟悉的，例如：

    $ chsh -s /bin/bash

也可以在创建新用户的时候指定，例如创建一个新用户叫 `tinylab`，并指定用 `/bin/dash`：

    $ sudo adduser --home /home/tinylab --shell /bin/dash tinylab
    $ su tinylab
    $ echo $SHELL
    /bin/dash

## 跨平台的语法差异

同名的程序在不同平台有很多差异，同一个选项，意义和实现很多都完全不一样。

之前在移植 [Cloud Lab](/cloud-lab) 到 Mac OSX 平台，就遇到大量的命令兼容性问题，这些命令有最常用的：date, stat, xargs, awk, chattr, ifconfig, echo。相关的兼容性修复记录可以查看这里：[Search · osx · GitHub](https://github.com/tinyclub/cloud-lab/search?p=1&q=osx&type=Commits)

在 debug 这些问题时可以用 `set -x` 开启打印 commands，用 `set -e` 设定在任意行执行的返回值不为 0 时退出（这种情况下不能用 `$?`），方便定位出错的位置。同时可以用 `man` 命令查看各个选项的说明，例如：

    #!/bin/bash

    set -x
    set -e

    [ ! -d /proc/test ] && echo 'ERR: not exists.' && exit 1

    echo Hello


效果如下：

    $ ./hello.sh
    ' '!' -d /proc/test ']'
    + echo 'ERR: not exists.'
    ERR: not exists.
    + exit 1 

这样就可以追查到出错的路径。

如果涉及到需要跨平台使用某个 Shell 程序，请务必做好兼容性测试。

## 小结

要让一个 Shell 程序正常工作，通常除了程序本身的语法之外，还需要注意程序运行的搜索路径、搜索类别，检查执行权限，指定正确的解释器，还需要注意平台差异。

欢迎大家联系作者微信 lzufalcon，做一进步补充。

[1]: http://tinylab.org
