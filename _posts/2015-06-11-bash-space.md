---
title: BASH 中的空格
author: Wen Pingbo
layout: post
permalink: /bash-space/
tags:
  - assignment word
  - Bash
  - Linux
  - space
categories:
  - Linux
  - Shell
---

> By WEN Pingbo of [TinyLab.org][1]
> 2015/06/10

对于大部分 BASH 初学者而言，在动手写脚本时，遇到最频繁的错误，我想，大概就是这样：

<pre>#!/bin/bash

msg = "hello world" # msg: command not found

echo "My message: $msg"
</pre>

在刚接触 BASH 时，我也在这个地方纠结了很久，为什么 `=` 前后不能有空格？但 google 了半天，几乎所有的人都只是说，这种写法是 BASH 固有的语法，而没有更深一层去追究这个问题。这里，这篇文章尝试从 BASH 的词法设计上去追寻这个问题的本质。

<!-- more -->

在我们所熟悉的语言 ( c / c++ ) 中，`=` 通常是一个操作符，而空格只是作为一个字分隔符。当一个表达式中出现操作符时，其本身也起到了分隔符的作用。这个时候操作符前后的空格就显的可有可无。这也是为什么 `int i = 1;` 和 `int i=1;` 都是正确的写法。但在 BASH 中，`=` 却不是操作符。在 [bash manual definitions][2] 部分，定义的操作符只有如下几种：

<pre>||, &#038;&#038;, &#038;, ;, ;;, |, |&#038;, (, ), newline, redirection operator
</pre>

由于 `=` 并不是操作符，那么如果一个赋值语句中出现空格，那么 BASH 解析时，跟我们的预期就完全不一样。比如：

<pre>var=test #把test赋值给变量var
var = test #运行命令var，其参数为 = 和 test
var= test #把环境变量var设为空字符，并运行命令test
var =test #运行命令var，其参数为=test
</pre>

既然 `=` 不是操作符，那么在 BASH 中，赋值是怎么定义呢？其实在 BASH 词法定义中，有专门定义一个 [ASSIGNMENT_WORD][3]，是 WORD 中的一种。也就是说，`var=test` 在 BASH 中是被解析成一个词法单元。这中间自然也不允许空格把它分割成多个词法单元。而 `simple command` 之前放置变量赋值，也都是解析为 `ASSIGNMENT_WORD`。比如：

<pre>DEBUG=1 ./your_script
</pre>

在 BASH 中，若没有操作符，则必须用空格，或者其他 `blank character` 来分割一条语句中的字(WORD)。但有一些字符，看上去像是操作符，其实只是一个 reserved word。这个时候，若不加空格，则会造成类似的错误。比如：

<pre>[1 -eq 1] # wrong, [ 是 BASH 内置命令，不是操作符
[ 1 -eq 1 ] # right

[[1 -eq 1]] # wrong, [[ 是 BASH 关键字，不是操作符
[[ 1 -eq 1 ]] # right

(echo this is a test) # right, ( 和 ) 是 BASH 操作符
{echo this is a test} # wrong, { 是 BASH 关键字，不是操作符
{ echo this is a test} # wrong, } 是 BASH 关键字，不是操作符
{ echo this is a test;} # right, ; 是 BASH 操作符
</pre>

总结起来，在 BASH 中，一定要记住什么是操作符，什么不是。只有这样，才会知道什么时候必须加空格，什么时候就可有可无。





 [1]: http://tinylab.org
 [2]: http://www.gnu.org/software/bash/manual/bashref.html#Definitions
 [3]: http://code.metager.de/source/xref/gnu/bash/parse.y#348
