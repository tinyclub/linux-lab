---
title: BASH 的调试手段
author: Wen Pingbo
layout: post
permalink: /bash-debugging-tools/
tags:
  - Bash
  - bashdb
  - Debug
  - Linux
categories:
  - Linux
---

> By WEN Pingbo of [TinyLab.org][1]
> 2015/06/01

平时在写 BASH 脚本时，总是会碰到让人抓狂的 BUG。和 C/C++ 这么丰富的调试工具相比，BASH 又有什么调试手段呢？


## echo/print (普通技)

打印一些变量，或者提示信息。这应该是一个通用的方法了。在 BASH 里，我们可以简单的用 echo，或者 print 来输出一些 log，或者加一些 loglevel 来过滤一些 log。这里贴一下我平常用的函数：

<pre>_loglevel=2

DIE() {
    echo "Critical: $1" >&#038;2
    exit 1
}

INFO() {
    [ $_loglevel -ge 2 ] &#038;&#038; echo "INFO: $1" >&#038;2
}

ERROR() {
    [ $_loglevel -ge 1 ] &#038;&#038; echo "ERROR: $1" >&#038;2
}
</pre>

<!-- more -->

这里的实现只是简单的加了一个 loglevel，其实可以把 log 输出到一个文件中，或者给 log 加上颜色。比如：

<pre># add color
[ $_loglevel -ge 1 ] &#038;&#038; echo -e "\033[31m ERROR:\033[0m $1" >&#038;2
# redirect to file
[ $_loglevel -ge 1 ] &#038;&#038; echo "ERROR: $1" > /var/log/xxx_log.$BASHPID

</pre>

## set -x (稀有技)

-x(xtrace) 选项会导致 BASH 在执行命令之前，先把要执行的命令打印出来。这个选项对调试一些命令错误很有帮助。

有的时候，由于传进来的参数带有一些特殊字符，导致 BASH 解析时不是按照我们预想的进行。这个时候，把 -x 打开，就能在命令执行前，把扩展后的命令打印出来。比如基于前面写的函数：

<pre>set -x
INFO "this is a info log"
ERROR "this is a error log"
set +x
</pre>

然后就可以看到如下输出：

<pre>+ INFO 'this is a info log'
+ '[' 2 -ge 2 ']'
+ echo -e '\033[32m INFO:\033[0m this is a info log'
 INFO: this is a info log
+ ERROR 'this is a error log'
+ '[' 2 -ge 1 ']'
+ echo -e '\033[33m ERR:\033[0m this is a error log'
 ERR: this is a error log
+ set +x
</pre>

如果想全程打开 xtrace，可以在执行脚本的时候加 `-x` 参数。

## trap/bashdb (史诗技)

为了方便调试，BASH 也提供了陷阱机制。这跟之前介绍的两种方法高级不少。我们可以利用 trap 这个内置命令来指定各个 sigspec 应该执行的命令。trap 的具体用法如下：

<pre>trap [-lp] [[arg] sigspec ...]
</pre>

sigspec 包括 `<signal.h>` 中定义的各个 signal， EXIT，ERR，RETURN 和 DEBUG。

各个 signal 这里就不介绍了。EXIT 会在 shell 退出时执行指定的命令。若当前 shell 中有命令执行返回非零值，则会执行与 ERR 相关联的命令。而 RETURN 是针对 `source` 和 `.` ，每次执行都会触发 RETURN 陷阱。若绑定一个命令到 DEBUG，则会在每一个命令执行之前，都会先执行 DEBUG 这个 trap。这里要注意的是，ERR 和 DEBUG 只在当前 shell 有效。若想函数和子 shell 自动继承这些 trap，则可以设置 -T(DEBUG/RETURN) 和 -E(ERR)。

比如，下面的脚本会在退出时，执行echo：

<pre>#!/bin/bash

trap "echo this is a exit echo" EXIT

echo "this is a normal echo"
</pre>

或者，让脚本中命令出错时，把相应的命令打印出来：

<pre>#!/bin/bash

trap 'echo $BASH_COMMAND return err' ERR

echo this is a normal test
UnknownCmd
</pre>

这个脚本的输出如下：

<pre>this is a normal test
tt.sh: line 6: UnknownCmd: command not found
UnknownCmd return err
</pre>

亦或者，让脚本的命令单步执行：

<pre>#!/bin/bash

trap '(read -p "[$0 : $LINENO] $BASH_COMMAND ?")' DEBUG

echo this is a test

i=0
while [ true ]
do
    echo $i
    ((i++))
done
</pre>

其输出如下：

<pre>[tt.sh : 5] echo this is a test ?
this is a test
[tt.sh : 7] i=0 ?
[tt.sh : 8] [ true ] ?
[tt.sh : 10] echo $i ?
0
[tt.sh : 11] ((i++)) ?
[tt.sh : 8] [ true ] ?
[tt.sh : 10] echo $i ?
1
[tt.sh : 11] ((i++)) ?
[tt.sh : 8] [ true ] ?
[tt.sh : 10] echo $i ?
2
[tt.sh : 11] ((i++)) ?
</pre>

是不是有点意思了？其实有一个 [bashdb][2] 的开源项目，也是利用 trap 机制，模拟 gdb 做了一个 bash 脚本的调试器。它本身也是一个 bash 脚本。在加载要调试的脚本后，可以用和 gdb 类似的命令，甚至缩写也是一样的，大家可以尝试一下:)

(上个月沉迷于 Diablo3，最后发现自己脸不行，悴！还是回来写点东西吧！)





 [1]: http://tinylab.org
 [2]: http://bashdb.sourceforge.net/
