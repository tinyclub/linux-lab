---
title: '[c-faq] 2.10-designated initializer'
author: Wen Pingbo
album: C FAQ
layout: post
permalink: /c-faq2-10-designated-initializer/
tags:
  - c
  - faq
  - initializer
categories:
  - C
  - Computer Language
---

> by PingboWen of [TinyLab.org](http://tinylab.org)
> 2013/08/24

在阅读 kernel 源码的时候，经常会碰到类似的代码：

    struct test p= {
    	.initial=3;
    	.ptr=xx;
    };

好像有点陌生吧，这是什么写法？   这其实是 C99 新增的内容，叫做 designated initializer ，暂且翻译为 &rdquo; 标识初始器 &ldquo; 吧！   在 C90 之前，当你初始化一个数组，结构体或者联合体 (union) 的时候，你必须按照之前定义的顺序来初始化，且中间还不能跳跃。   这在 C99 之后，就已经打破了。

当我们初始化一个数组的时候， C90 之前，我们只能这样初始化：

    int a[6]={1,2,3,4,5,6};

在 C99 中，你可以用 '[index]' 的方式来指定初始化某个元素，其他没有明确初始化的元素，会按照默认值来初始化，所以我们可以这样来做：

    int a[6]={ [2] = 4, [5] = 8 };

就相当于

    int a[6]={0,0,4,0,0,8};

当我们的数组很大的时候，你还可以这样来初始化：

    int array[]={[0 ... 9] = 1, [55 ... 99] = 4, [100]=23};

注意：`...` 左右需要有空格，否则编译报错 甚至，我们可以和以前的初始化的方式，混合来写：

int array[6]={[1]=3,5,[4]=7};

这里 5 对应于第 3 个元素

而在结构体的初始化中，我们可以这么干：   假如有一个这样的结构体：

    struct point {
    	int x;
    	int y;
    };

当我们初始化它的一个实例的时候，在 C99 中，可以这样来：

    struct point p1={.y=3, .x=6};

注意，顺序和之前定义的是不同的哦，这就相当于：

    struct point p1={6,3};

还有一种写法是这样的：

    struct point p1={y:3, x:6};

这是一种老式的写法，在 gcc 2.5 之后，就废弃了，不过，你这么用的话，编译器也不会报错，向后兼容嘛   如果是结构体数组呢，该怎样写？那就混合着来呗：

    struct point parray[10]={[0].y=4,[0].x=1,[4].x=6};

这是在结构体，在联合体中，照样可以这么用， 假设有这样一个联合体：

    union foo{ int x; double y;};

在初始化的时候，可以这样做：

    union foo f={.y=5};

说这么多，可能有点迷糊了，那就做一个例子：

    #include <stdio.h>
    struct point {
        int x;
        int y;
    };

    int main(int argc,char *argv[])
    {
        int a[6]={ [4]=29, [2]=15};

        int widths[]={ [0 ... 9]=1, [10 ... 99]=2, [100]=3};

        struct point p1={.x=23, .y=55};

        struct point p2={x:43, y:12};

        int b[6]={ [1]=23,44,[4]=11};

        // struct point parray[10]={[2].y=33, [2].x=88, [0].x=20, [0].y:66};

        return 0;
    }

用 gcc 编译，可以通过编译，但同时也发现一个问题。 gcc 默认是按照 c89,c90 的标准来编译程序的，

但是这个程序没有加 `-std=c99` ，也能通过编译， WHY ？

其实虽然标识初始器是 C99 的标准，但是现在的 gcc 已经允许在 c90 的标准中出现这种写法。

官方对该特性说明的文档在：[Designated-Inits](http://gcc.gnu.org/onlinedocs/gcc/Designated-Inits.html)。
