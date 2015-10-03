---
title: Shell 编程学习笔记
author: Wu Zhangjin
layout: post
album: Shell 编程范例
permalink: /shell-programming-study-notes/
tags:
  - Bash
  - 编程
  - 范例
  - Linux
  - Shell
  - 学习笔记
  - 实例
  - 例子
categories:
  - Shell
---

> by falcon of [TinyLab.org][2]
> 2006/04/03

## 前言

这是作者早期的 Shell  编程学习笔记，主要包括 Shell 概述、 Shell 变量、位置参数、特殊符号、别名、各种控制语句、函数等 Shell  编程知识。

要想系统地学 Shell ，应该找些较系统的资料，例如： [《 Shell 编程范例序列》][3] 和 [《鸟哥学习 Shell Scripts 》][4] 。

## 执行 Shell 脚本的方式

### 范例：输入重定向到 Bash

    $ bash < ex1

可以读入 ex1 中的程序，并执行

### 范例：以脚本名作为参数

其一般形式是：

    $ bash 脚本名 [参数]

例如：

    $ bash ex2 /usr/meng /usr/zhang

其执行过程与上一种方式一样，但这种方式的好处是能在脚本名后面带有参数，从而将参数值传递给程序中的命令，使一个 Shell 脚本可以处理多种情况，就如同函数调用时可根据具体问题传递相应的实参。

### 范例：以 . 来执行

如果以当前 Shell （以·表示）执行一个 Shell 脚本，则可以使用如下简便形式：

    $ · ex3[参数]

### 范例：直接执行

将 Shell 脚本的权限设置为可执行，然后在提示符下直接执行它。

具体办法：

    $ chmod a+x ex4
    $ ./ex4

这个要求在 Shell 脚本的开头指明执行该脚本的具体 Shell ，例如 /bin/bash ：

    #!/bin/bash

## Shell 的执行原理

 Shell 接收用户输入的命令（脚本名），并进行分析。如果文件被标记为可执行，但不是被编译过的程序， Shell 就认为它是一个 Shell 脚本。 Shell 将读取其中的内容，并加以解释执行。所以，从用户的观点看，执行 Shell 脚本的方式与执行一般的可执行文件的方式相似。

因此，用户开发的 Shell 脚本可以驻留在命令搜索路径的目录之下（通常是`/bin`、`/usr/bin`等），像普通命令一样使用。这样，也就开发出自己的新命令。如果打算反复使用编好的 Shell 脚本，那么采用这种方式就比较方便。

## 变量赋值

可以将一个命令的执行结果赋值给变量。有两种形式的命令替换：一种是使用倒引号引用命令，其一般形式是： `命令表`。

### 范例：获取当前的工作目录并存放到变量中

例如：将当前工作目录的全路径名存放到变量dir中，输入以下命令行：

    $ dir=`pwd`

另一种形式是：$(命令表)。上面的命令行也可以改写为：

    $ dir=$(pwd)

## 数组

Bash 只提供一维数组，并且没有限定数组的大小。类似与 C 语言，数组元素的下标由 0 开始编号。获取数组中的元素要利用下标。下标可以是整数或算术表达式，其值应大于或等于 0 。用户可以使用赋值语句对数组变量赋值。

### 范例：对数组元素赋值

对数组元素赋值的一般形式是：`数组名[下标]＝值`，例如：

    $ city[0]=Beijing
    $ city[1]=Shanghai
    $ city[2]=Tianjin

也可以用 declare 命令显式声明一个数组，一般形式是：

    $ declare -a 数组名

### 范例：访问某个数组元素

读取数组元素值的一般格式是： `${数组名[下标]}` ，例如：

    $ echo ${city[0]}
    Beijing

### 范例：数组组合赋值

一个数组的各个元素可以利用上述方式一个元素一个元素地赋值，也可以组合赋值。定义一个数组并为其赋初值的一般形式是：

    数组名=(值1 值2 ... 值n)

其中，各个值之间以空格分开。例如：

    $ A=(this is an example of shell script)
    $ echo ${A[0]} ${A[2]} ${A[3]} ${A[6]}
    this an example script
    $ echo ${A[8]}

由于值表中初值共有 7 个，所以 A 的元素个数也是 7 。 `A[8]` 超出了已赋值的数组 A 的范围，就认为它是一个新元素，由于预先没有赋值，所以它的值是空串。

若没有给出数组元素的下标，则数组名表示下标为 0 的数组元素，如 city 就等价于 `city[0]` 。

### 范例：列出数组中所有内容

使用 `*` 或 `@` 做下标，则会以数组中所有元素取代。

    $ echo ${A[*]}
    this is an example of shell script

### 范例：获取数组元素个数

    $ echo ${#A[*]}
    7

## 参数传递

假如要编写一个 Shell 来求两个数的和，可以怎么实现呢？   为了介绍参数传递的用法，编写这样一个脚本：

    $ cat > add
    let sum=$1+$2
    echo $sum

保存后，执行一下：

    $ chmod a+x ./add
    $ ./add 5 10
    15

可以看出 5 和 10 分别传给了 $1 和 $2 ，这是 Shell 自己预设的参数顺序，其实也可以先定义好变量，然后传递进去。

例如，修改上述脚本得到：

    let sum=$X+$Y
    echo $sum

再次执行：

    $ X=5 Y=10 ./add
    15

可以发现，同样可以得到正确结果。

## 设置环境变量

export 一个环境变量：

    $ export opid=True

这样子就可以，如果要登陆后都生效，可以直接添加到 `/etc/profile` 或者 ` ~ /.bashrc` 里头。

## 键盘读起变量值

可以通过 read 来读取变量值，例如，来等待用户输入一个值并且显示出来：

    $ read -p "请输入一个值 ： "  input ; echo "你输入了一个值为 ：" $input
    请输入一个值 ： 21500
    你输入了一个值为 ： 21500

## 设置变量的只读属性

有些重要的 Shell 变量，赋值后不应该修改，那么可设置它为 readonly ：

    $ oracle_home=/usr/oracle7/bin
    $ readonly oracle_home

## 条件测试命令 test

语法：`test 表达式` 如果表达式为真，则返回真，否则，返回假。

### 范例：数值比较

先给出数值比较时常见的比较符：

> `-eg =；-ne !=；-gt >；-ge >=；-lt <；-le <=`

    $ test var1 -gt var2

### 范例：测试文件属性

文件的可读、可写、可执行，是否为普通文件，是否为目录分别对应：

> `-r; -w; -x; -f; -d`

    $ test -r filename

### 范例：字符传属性以及比较

> 串的长度为零：`-z`； 非零：`-n`，如:

    $ test -z s1

如果串 s1 长度为零，返回真。

### 范例：串比较

> 相等`"s1"="s2"`； 不相等 `"s1"!="s2"`

还有一种比较串的方法(可以按字典序来比较)：

    $ if [[ "abcde" < "abcdf" ]]; then  echo "yeah,果然是诶"; fi
    yeah,果然是诶

## 整数算术或关系运算 expr

可用该命令进行的运算有：

> 算术运算：`+ - * / %`；逻辑运算`：= ! < <= > >=`

如:

    $ i=5;expr $i+5

另外， bc 是一个命令行计算器，可以进行一些算术计算。

## 控制执行流程命令

### 范例：条件分支命令if

if 命令举例：如果第一个参数是一个普通文件名，那么分页打印该文件；否则，如果它为目录名，则进入该目录并打印该目录下的所有文件，如果也不是目录，那么提示相关信息。

    if test -f $1
    then
        pr $1>/dev/lp0
    elif
        test-d $1
    then
        (cd $1;pr *>/dev/lp0)
    else
        echo $1 is neither a file nor a directory
    fi

### 范例：case 命令举例

case 命令是一个基于模式匹配的多路分支命令，下面将根据用户键盘输入情况决定下一步将执行那一组命令。

    while [ $reply!="y" ] && [ $reply!="Y" ]                         #下面将学习的循环语句
    do
        echo "\nAre you want to continue?(Y/N)\c"
        read reply             #读取键盘
        case $replay in
            (y|Y) break;;         #退出循环
            (n|N) echo "\n\nTerminating\n"
                  exit 0;;
                *) echo "\n\nPlease answer y or n"
                continue;       #直接返回内层循环开始出继续
        esac
    done

### 范例：循环语句 while, until

语法：

    while/until 命令表1
    do
        命令表2
    done

区别是，前者执行命令表 1 后，如果退出状态为零，那么执行 do 后面的命令表 2 ，然后回到起始处，而后者执行命令表 1 后，如果退出状态非零，才执行类似操作。   例子同上。

### 范例：有限循环命令 for

语法：

    for 变量名 in 字符串表
    do
        命令表
    done

举例：

    FILE="test1.c myfile1.f pccn.h"
    for i in $FILE
    do
        cd ./tmp
        cp $i $i.old
        echo "$i copied"
    done

## 函数

现在来看看 Shell 里头的函数用法，先看个例子：写一个函数，然后调用它显示 "Hello,World!" 

    $ cat > show
    # 函数定义
    function show
    {
        echo $1$2;
    }
    H="Hello,"
    W="World!"
    # 调用函数，并传给两个参数H和W
    show $H $W

演示：

    $ chmod 770 show
    $./show
    Hello,World!

看出什么蹊跷了吗？

    $ show $H $W

咱们可以直接在函数名后面跟实参。

实参顺序对应“虚参”的 `$1,$2,$3` ……

注意：假如要传入一个参数，如果这个参数中间带空格，怎么办？ 先试试看。

来显示 "Hello World"( 两个单词之间有个空格 ) 

    function show
    {
        echo $1
    }
    HW="Hello World"
    show "$HW"

如果直接 `show $HW` ，肯定不行，因为 `$1` 只接受到了 Hello ，所以结果只显示 Hello ，原因是字符串变量必须用 `"` 包含起来。

## 后记

感兴趣的话继续学习吧！还有好多强大的东西等着呢，比如 cut, expr, sed, awk 等等。

 [2]: http://tinylab.org
 [3]: /shell-programming-paradigm-series-index-review/
 [4]: http://www.chinaunix.net/jh/24/628472.html
