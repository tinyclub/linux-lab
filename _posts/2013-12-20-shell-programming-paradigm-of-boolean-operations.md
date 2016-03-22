---
title: Shell 编程范例之布尔运算
author: Wu Zhangjin
layout: post
album: Shell 编程范例
permalink: /shell-programming-paradigm-of-boolean-operations/
tags:
  - Bash
  - 编程
  - 范例
  - Linux
  - Shell
  - 实例
  - 布尔运算
  - 例子
categories:
  - Shell
---

> by falcon of [TinyLab.org][2]
> 2007-11-09


## 开篇

上个礼拜介绍了 [Shell 编程范例之数值运算][3] ，对 Shell 下基本数值运算方法做了简单的介绍，这周将一起探讨布尔运算，即如何操作“真假值”。

在 Bash 里有这样的常量（实际上是两个内置命令，在这里我们姑且这么认为，后面将介绍），即 true 和 false ，一个表示真，一个表示假。对它们可以进行与、或、非运算等常规的逻辑运算，在这一节，我们除了讨论这些基本逻辑运算外，还将讨论 SHELL 编程中的条件测试和命令列表，并介绍它们和布尔运算的关系。

## 常规的布尔运算

这里主要介绍 Bash 里头常规的逻辑运算，与、或、非。

### 在 Shell 下如何进行逻辑运算

#### 范例：true or false

单独测试 true 和 false ，可以看出 true 是真值， false 为假

<pre>$ if true;then echo "YES"; else echo "NO"; fi
YES
$ if false;then echo "YES"; else echo "NO"; fi
NO
</pre>

#### 范例：与运算

<pre>$ if true && true;then echo "YES"; else echo "NO"; fi
YES
$ if true && false;then echo "YES"; else echo "NO"; fi
NO
$ if false && false;then echo "YES"; else echo "NO"; fi
NO
$ if false && true;then echo "YES"; else echo "NO"; fi
NO
</pre>

#### 范例：或运算

<pre>$ if true || true;then echo "YES"; else echo "NO"; fi
YES
$ if true || false;then echo "YES"; else echo "NO"; fi
YES
$ if false || true;then echo "YES"; else echo "NO"; fi
YES
$ if false || false;then echo "YES"; else echo "NO"; fi
NO
</pre>

#### 范例：非运算，即取反

<pre>$ if ! false;then echo "YES"; else echo "NO"; fi
YES
$ if ! true;then echo "YES"; else echo "NO"; fi
NO
</pre>

可以看出 true 和 false 按照我们对逻辑运算的理解进行着，但是为了能够更好的理解 Shell 对逻辑运算的实现，我们还得弄清楚， true 和 false 是怎么工作的？

### Bash 里头的 true 和 false 是我们通常认为的 1 和 0 么？

回答是：否。

#### 范例：返回值 v.s. 逻辑值

 true 和 false 它们本身并非逻辑值，它们是 Shell 内置命令，返回了“逻辑值”

<pre>$ true
$ echo $?
0
$ false
$ echo $?
1
</pre>

#### 范例：查看 true 和 false 帮助和类型

<pre>$ help true false
true: true
     Return a successful result.
false: false
     Return an unsuccessful result.
$ type true false
true is a Shell builtin
false is a Shell builtin
</pre>

说明： $? 是一个特殊的变量，存放有上一个程序的结束状态 ( 退出状态码 ) 。

从上面的操作不难联想到在 C 语言程序设计中为什么会强调在 main 函数前面加上 int ，并在末尾加上 return 0 。因为在 Shell 里头，将把 0 作为程序是否成功结束的标志，这就是 Shell 里头 true 和 false 的实质，它们用以反应某个程序是否正确结束，而并非传统的真假值（ 1 和 0 ），相反的，它们返回的是 0 和 1 。不过庆幸的是，我们在做逻辑运算时，无须关心这些。

## 条件测试

从上一节中，我们已经清楚的了解了 Shell 下的“逻辑值”是什么：是程序结束后的返回值，如果成功返回，则为真，如果不成功返回，则为假。

而条件测试正好使用了 test 这么一个指令，它用来进行数值测试（各种数值属性测试）、字符串测试（各种字符串属性测试）、文件测试（各种文件属性测试），我们通过判断对应的测试是否成功，从而完成各种常规工作，在加上各种测试的逻辑组合后，将可以完成更复杂的工作。

### 条件测试基本使用

#### 范例：数值测试

<pre>$ if test 5 -eq 5;then echo "YES"; else echo "NO"; fi
YES
$ if test 5 -ne 5;then echo "YES"; else echo "NO"; fi
NO
</pre>

#### 范例：字符串测试

<pre>$ if test -n "not empty";then echo "YES"; else echo "NO"; fi
YES
$ if test -z "not empty";then echo "YES"; else echo "NO"; fi
NO
$ if test -z "";then echo "YES"; else echo "NO"; fi
YES
$ if test -n "";then echo "YES"; else echo "NO"; fi
NO
</pre>

#### 范例：文件测试

<pre>$ if test -f /boot/System.map; then echo "YES"; else echo "NO"; fi
YES
$ if test -d /boot/System.map; then echo "YES"; else echo "NO"; fi
NO
</pre>

### 各种逻辑测试的组合

#### 范例：如果 a,b,c 都等于下面对应的值，那么打印 YES ，这里通过 -a 进行 "与" 测试

<pre>$ a=5;b=4;c=6;
$ if test $a -eq 5 -a $b -eq 4 -a $c -eq 6; then echo "YES"; else echo "NO"; fi
YES
</pre>

#### 范例：测试某个“东西”是文件或者目录，这里通过 -o 进行“或”运算

<pre>$ if test -f /etc/profile -o -d /etc/profile;then echo "YES"; else echo "NO"; fi
YES
</pre>

#### 范例：测试非运算

<pre>$ if test ! -f /etc/profile; then echo "YES"; else echo "NO"; fi
NO
</pre>

上面仅仅演示了 test 命令一些非常简单的测试，你可以通过 help test 获取 test 的更多使用方法。在这里需要注意的是， test 命令内部的逻辑运算和 Shell 的逻辑运算符有一些区别，对应的为 `-a` 和 `&&` ，`-o` 与 `||` ，这两者不能混淆使用。而非运算都是 `!`，下面对它们进行比较。

### 比较 `-a` 与 `&&`, `-o` 与 `||`， `! test` 与 `test !`

#### 范例：要求某个文件有可执行权限并且有内容，用 `-a` 和 `&&` 分别实现

<pre>$ cat > test.sh
#!/bin/bash

echo "test"
$ chmod +x test.sh
$ if test -s test.sh -a -x test.sh; then echo "YES"; else echo "NO"; fi
YES
$ if test -s test.sh && test -x test.sh; then echo "YES"; else echo "NO"; fi
YES
</pre>

#### 范例：要求某个字符串要么为空，要么和某个字符串相等

<pre>$ str1="test"
$ str2="test"
$ if test -z "$str2" -o "$str2" == "$str1"; then echo "YES"; else echo "NO"; fi
YES
$ if test -z "$str2" || test "$str2" == "$str1"; then echo "YES"; else echo "NO"; fi
YES
</pre>

#### 范例：测试某个数字不满足指定的所有条件

<pre>$ i=5
$ if test ! $i -lt 5 -a $i -ne 6; then echo "YES"; else echo "NO"; fi
YES
$ if ! test $i -lt 5 -a $i -eq 6; then echo "YES"; else echo "NO"; fi
YES
</pre>

很容易找出它们的区别， -a 和 -o 使用在测试命令的内部，作为测试命令的参数，而 `&&` 和 `||` 是用来运算测试的返回值， ! 为两者通用。需要关注的是：

  *  有时候我们可以不用 ! 运算符，比如 -eq 和 -ne 刚好是相反的，用来测试两个数值是否相等； -z 与 -n 也是对应的，用来测试某个字符串是否为空。
  *  在 bash 里， test 命令可以用 [ ] 运算符取代，但是需要注意， [ 之后与 ] 之前需要加上额外的空格。
  *  在测试字符串的时候，所有变量建议用双引号包含起来，以防止变量内容为空的时候出现仅有测试参数，没有测试内容的情况。

下面我们用实例来演示上面三个注意事项：

 -ne 和 -eq 对应的，我们有时候可以免去 ! 运算

<pre>$ i=5
$ if test $i -eq 5; then echo "YES"; else echo "NO"; fi
YES
$ if test $i -ne 5; then echo "YES"; else echo "NO"; fi
NO
$ if test ! $i -eq 5; then echo "YES"; else echo "NO"; fi
NO
</pre>

用 [ ] 可以取代 test ，这样看上去会“美观”很多

<pre>$ if [ $i -eq 5 ]; then echo "YES"; else echo "NO"; fi
YES
$ if [ $i -gt 4 ] && [ $i -lt 6 ]; then echo "YES"; else echo "NO"; fi
YES
</pre>

记得给一些字符串变量加上 `"`，记得 [ 之后与 ] 之前多加一个空格。

<pre>$ str=""
$ if [ "$str" = "test"]; then echo "YES"; else echo "NO"; fi
-bash: [: missing `]'
NO
$ if [ $str = "test" ]; then echo "YES"; else echo "NO"; fi
-bash: [: =: unary operator expected
NO
$ if [ "$str" = "test" ]; then echo "YES"; else echo "NO"; fi
NO
</pre>

到这里，条件测试就介绍完了，下面我们将介绍“命令列表”，实际上在上面我们似乎已经使用过了，即多个 test 命令的组合，通过 `&&` ，`||` 和 `!` 组合起来的命令序列。这个命令序列可以有效替换 if/then 的条件分支结构。这不难想到我们在 C 语言程序设计中经常做的如下的选择题 ( 很无聊的例子，但是有意义 ) ：下面是否会打印 j ，如果打印，将打印什么？

<pre>#include <stdio.h>
int main()
{
                int i, j;

                i=5;j=1;
                if ((i==5) && (j=5))  printf("%d\n", j);

                return 0;
}
</pre>

很容易知道将打印数字 5 ，因为 i==5 这个条件成立，而且随后是 && ，要判断整个条件是否成立，我们得进行后面的判断，可是这个判断并非常规的判断，而是先把 j 修改为 5 ，再转换为真值，所以条件为真，打印出 5 。因此，这句可以解释为：如果 i 等于 5 ，那么把 j 赋值为 5 ，如果 j 大于 1 （因为之前已经为真），那么打印出 j 的值。这样用 && 连结起来的判断语句替代了两个 if 条件分支语句。

正是基于逻辑运算特有的性质，我们可以通过 `&&` ，`||` 来取代 if/then 等条件分支结构，这样就产生了命令列表。

## 命令列表

### 命令列表的执行规律

命令列表的执行规律符合逻辑运算的运算规律，用 `&&` 连接起来的命令，如果前者成功返回，将执行后面的命令，反之不然；用 `||` 连接起来的命令，如果前者成功返回，将不执行后续命令，反之不然。

#### 范例：如果 ping 通 www.lzu.edu.cn，那么打印连通信息

<pre>$ ping -c 1 www.lzu.edu.cn -W 1 && echo "=======connected======="
</pre>

非常有趣的问题出来了，即我们上面已经提到的：为什么要让 C 程序在 main 函数的最后返回 0 ？如果不这样，把这种程序放入命令列表会有什么样的结果？你自己写个简单的 C 程序看看，然后放入命令列表看看。

### 命令列表的作用

在有些时候取代 if/then 等条件分支结构，这样可以省略一些代码，而且使得程序比较美观、易读，例如：

#### 范例：在脚本里判断程序的参数个数，和参数类型

<pre>#!/bin/bash

echo $#
echo $1
if [ $# -eq 1 ] && echo $1 | grep ^[0-9]*$ >/dev/null;then
           echo "YES"
fi
</pre>

上例要求参数个数为 1 并且类型为数字。

再加上 exit 1 ，我们将省掉 if/then 结构

<pre>#!/bin/bash

echo $#
echo $1
! ([ $# -eq 1 ] && echo $1 | grep ^[0-9]*$ >/dev/null) && exit 1

echo "YES"
</pre>

这样处理后，对程序参数的判断仅仅需要简单的一行代码，而且变得更美观。

## 总结

这一节介绍了 Shell 编程中的逻辑运算，条件测试和命令列表。





 [2]: tinylab.org
 [3]: /shell-numeric-calculation/
