---
title: '[c-faq] 2.14, 2.15-offsetof和struct成员异类访问'
author: Wen Pingbo
album: C FAQ
layout: post
permalink: /c-faq2-14-2-15-offsetof-and-struct-members-heterogeneous-access/
views:
  - 188
tags:
  - c
  - faq
  - kernel
  - offsetof
categories:
  - C
  - Computer Language
---

> by PingboWen of [TinyLab.org](http://tinylab.org)
> 2013/08/24

今天在看 c-faq 的时候，碰到一个很奇怪的写法：

    *(int *)((char *)structp + offsetf) = value;

其中 `offsetf` 是由 `offsetof` 宏计算出来的。这个表达式是用来不通过名字来引用结构体成员，而是通过偏移量来引用这个成员。感觉很有意思，那咱就深究一下吧！

首先，咱看一下 `offsetof` 这个 ANSI C 定义的宏，它是专门用来计算 struct 或者 union 类型成员的偏移量的。它的定义在 stddef.h 这个头文件中，用法很简单，给个例子就明白了：

    struct test {
        char c;
        int i;
    };

针对上面的结构体，`offsetof(struct test, i)` 就会返回成员i在这个结构体中的相对偏移量。

用法清楚了，现在我对它的实现感兴趣！来看看它的源码！

在 linux 下面，如果你安装了 kernel header 的话，你可能会找到这个文件： `/usr/include/linux/stddef.h` 。这个文件不是 glibc 的 stddef.h ，而是 kernel 用的头文件，如果你打开的话，发现这是一个空的头文件。其实用户态程序真真引用的 stddef.h 在你对应的编译器相关目录下面，由于我用的是 gcc ，所以要找的头文件在这： `usr/lib/gcc/x86_64-linux-gnu/4.7/include/stddef.h` 。

打开这个头文件，定位到 offsetof 宏，发现它的定义是这样的：

    /* Offset of member MEMBER in a struct of type TYPE. */
    #define offsetof(TYPE, MEMBER) __builtin_offsetof (TYPE, MEMBER)

好吧，看来 gcc 并没有按照 ANSI C 来走，它这个地方做了一个跳转，网上的说法是为了兼容 C++ 。先不管了，从标准 stddef.h 扒下来一份，发现有两种版本，最传统的版本是这样的：

    #define offsetof(type,m) ((size_t)&(((type *)0)->m))

初看，你会觉得，额，有点复杂。其实把这个分解一下，还是可以理解的。这个表达式首先把一个 null 转换成一个 type 型的指针，然后用这个指针去引用成员 m ，然后取 m 的地址，并转换成 size_t 类型。就相当于把一个结构体和 0 对齐，然后 m 的地址就是这个成员相对于结构体的相对偏移量了。

但是，这个并不是一个通用的实现方法。你可能会说，它引用了空指针，肯定运行不了。其实这并不算引用空指针问题，尽管表面上看上去是，因为这个偏移量是在编译时确定的，并不是在运行时。但是还是会有一些编译器拒绝接受这种写法，这要看具体的编译器的实现了。

既然那个版本不是通用的，那么修改一下：

    #define offsetof(type,m) ( (size_t) (((char *)&(((type *)0)->m)) - (char *)((type *)0)) )

好吧，这个更复杂了。这个比上一个版本多做了两件事，一个是减去 0 的地址，这可以避免一些编译器的 null 并不是 0 的情况；另外一个是在做减法的时候，全部转成 char * 的类型，这就可以保证最后计算的结果是以字节为单位。

可能你会说，这个版本还是没有解决 null 指针引用的问题，那么就学学 gcc 把，直接用一个函数 `__builtin_offsetof` ，这个不但可以计算 struct 的偏移量，还能计算 class 的偏移量。

OK ，清楚了 offsetof 的实现后，咱再回过头来看看那个 struct 成员的异类访问：

先定义一个结构体，并初始化：

    struct test {
        char c;
        int i;
        long l;
        double t;
    };
    struct test st;

假如我要把 st 中的 t 赋值为 7.89 ，正常的写法，应该是这样的：

    st.t=7.89;

那么，看一下另类写法：

    *(double *)((char *)&st+offsetof(struct test, t))=7.89;

如果你真的看懂了 `offsetof` 的实现，那这个也就不是问题了。

其实在 kernel 开发中，还有一个类似的用法，那就是 `container_of`, 它是这样定义的：

    #define container_of(ptr, type, member) ({ \
        const typeof( ((type *)0)->member ) *__mptr = (ptr); \
        (type *)( (char *)__mptr - offsetof(type,member) );})

上面那个用法，是通过 struct 的首地址，加上相对偏移量来确定某个成员的地址。而 `container_of` 是通过结构体内部的一个成员地址，减去它的偏移量，从而得到它的父结构体的首地址。就相当于一个指针往下移，一个往上移，原理是一样的！

附上我写这个文章的时候，写的实验代码，可以自己试一试：

    test.c:

    #include <stdio.h>
    //#define offsetof(type,m) ((size_t)&(((type *)0)->m))
    #define offsetof(type,m) ( (size_t) (((char *)&(((type *)0)->m)) - (char *)((type *)0)) )

    struct test {
        char c;
        int i;
        long l;
        double t;
    };

    int main(int argc,char *argv[])
    {
        struct test st;

        printf("t pre: %f\n", st.t);

        *(double *)((char *)&st+offsetof(struct test, t))=7.89;
        printf("i after:%f\n", st.t);

        return 0;
    }
