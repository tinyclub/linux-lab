---
title: '[c-faq] 3.16-左值和右值'
author: Wen Pingbo
album: C FAQ
layout: post
permalink: /c-faq3-16-left-and-right-values/
views:
  - 211
tags:
  - c
  - lvalue
  - rvalue
categories:
  - C
  - Computer Language
---

> by Pingbo Wen of TinyLab.org
> 2013/08/11

在 C 和 C++ 中，我们经常会碰到两个概念， lvalue 和 rvalue 。甚至在编译程序的时候，也会碰到一些关于 lvalue 和 rvalue 的错误。

在 ISO IEC 的标准文档中，对这两个概念并没有详细说明，特别是 rvalue ，只在一个地方提了一下。

在 IBM 的 XL C/C++ V8.0 for AIX  的标准文档中是这样来规定 lvalue ：

> An object is a region of storage that can be examined and stored into. An lvalue is an expression that refers to such an object.

也就是说 lvalue 是一个表达式，且指向一个可读写的存储区域。而 rvalue ，可以为任何表达式。 lvalue 和 rvalue 的取名，是来自于一个赋值表达式中的。对于一个合法的赋值表达式：

    L = R;

我们就说 L 是 lvalue ， R 是 rvalue 。 lvalue 必须是可写的，且 lvalue 可以转换为 rvalue ，但是 rvalue 却不一定能转换成 lvalue 。比如：

    int x;
    x=1;

这个赋值是合法的，因为 x 是一个 lvalue ，但是：

这种写法明显是错误的，因为 1 只是一个 rvalue 。

左值和右值不仅仅存在于变量中，在表达式中，也是存在的。因为在 lvalue 和 rvalue 的定义中，它们的本质就是一个表达式。不是所有的表达式都会产生 lvalue 的。比如：

这是一个错误的赋值语句，因为加法产生的结果是 rvalue 。对于一些一元运算符，有的会产生 lvalue ，比如：

    int m,*p;
    p=&m;
    &m=p; //error

明显，最后一个是错误的，因为 & 产生的是 rvalue ，但是这种写法：

却是正确的，因为 * 产生的是 lvalue 。再举一个复杂的例子：

    ((condition) ? a : b) = complicated_expression; //error
    *((condition) ? &a : &b) = complicated_expression; //correct

对于很多类型转换，你可能会这么用：

    char *p;
    ((int *)p)++;

你的目的是想让指针 p 跳过几个 int 大小的位置，但是这个代码却不能正常执行。   原因有两个，一个是类型转换操作最后产生的是一个 rvalue ，也就无法用于 ++ 。另外一个，类型转换只是做一个类型转换，   并不会让编译器也随着类型改变相应的大小，也就是说最后， ++ 操作所加的大小并不是一个 int 的大小，而是一个 char 的大小。   所以你应该这样做：

    p = (char *)((int *)p + 1);

* 参考资料

  * <http://books.gigatux.nl/mirror/cinanutshell/0596006977/cinanut-CHP-5-SECT-1.html>
  * <http://ieng9.ucsd.edu/~cs30x/Lvalues%20and%20Rvalues.htm>
  * <http://publib.boulder.ibm.com/infocenter/comphelp/v8v101/index.jsp?topic=%2Fcom.ibm.xlcpp8a.doc%2Flanguage%2Fref%2Flvalue.htm>
