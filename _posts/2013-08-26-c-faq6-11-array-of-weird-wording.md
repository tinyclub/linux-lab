---
title: '[c-faq] 6.11-数组怪异写法'
author: Wen Pingbo
album: C FAQ
layout: post
permalink: /c-faq6-11-array-of-weird-wording/
tags:
  - faq
  - 数组
categories:
  - C
---

> by PingboWen of [TinyLab.org](http://tinylab.org)
> 2013/08/24

先来看一段代码：

    int main(int argc, char *argv[])
    {
            printf("%c\n", 5["abcdssdc"]);
            return 0;
    }

你觉得这段程序会打印出什么？ s ，确实是 s 。原因很简单，因为 s 是字符串 "abcdssdc" 的第 5 个字符。我们把这个程序转换一下：

    int main(int argc, char *argv[])
    {
          char *tmp = "abcdssdc";
          printf("%c\n", tmp+5);
          return 0;
    }

现在应该清楚了。这种奇怪的写法其实是利用了，在 C 语言中， '[]'  操作符里外可以互换。一个数组表达式 "a[5]" ，可以写成 "5[a]" 。在编译器看来，这两种写法最后都会翻译成 "*(a+5)" 。更进一步，只要表达式 "x[y]" 中， x 和 y 可以进行加法运算，且运算后的结果可以正常作为一个地址被引用，那这种写法就是合法的，且编译器不会报任何错误。

但是，回过头来，这种写法在正常的程序中有用吗？个人感觉没有多大的实用价值，但是说不定会在 Obfuscated C Contest 中有用 :) 
