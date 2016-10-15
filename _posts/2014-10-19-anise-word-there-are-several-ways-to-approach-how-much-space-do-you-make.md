---
title: '“茴”字有几种写法：结构体占多少空间你造吗？'
author: Chen Jie
layout: post
album: 内存管理
permalink: /anise-word-there-are-several-ways-to-approach-how-much-space-do-you-make/
tags:
  - big endness
  - bit-order
  - bitfield
  - c
  - clang
  - endness
  - gcc
  - little endness
  - sizeof
  - struct
  - 位序
categories:
  - C 语言
  - Gcc
---

> by Chen Jie of [TinyLab.org][1]
> 2014/10/15


## 前言

近来无意卷入某个考试，题风颇为远古，中有若干结构体空间占用的题目，i.e. “sizeof(struct &#8230;)”，你懂的。问谷歌，发现几处文章均不十分符实验。

本文据网上文章所留线索，结合实验总结而来，似是考据，呈现在此亦有如孔乙己那个名问：“茴字有几种写法，你造么？”，算是抒发一下无奈之情吧。

言归正传，关于C的基本数据类型，有几套说法，叫做 LP，ILP，LLP：

  * LP：long 和指针的位宽一致
  * ILP：int、long 和指针的位宽一致
  * LLP：long long 和指针的位宽一致

目前最常见的大概是 LP64 吧，即 long 和指针都是64位的。在此环境中，通常 GCC 等编译器还会自动定义宏“&#95;&#95;LP64&#95;&#95;”，因此可用此宏来判断当前是否为“LP64”。

那么问题来了，在 LP64 环境中，结构体的空间占用如何估算？

## 来自 sizeof(struct &#8230;) 的疑问

简单地说，sizeof(struct &#8230;) 并不是各成员的大小总和，还有若干padding：

  * 成员间的 padding，满足成员自然对齐要求而引入的 padding。
  * 结构体尾部的 padding。

### 结构体成员间的 padding

    struct stru_1 {
        unsigned char   mem_a;
        int             mem_b;
    };
    /* sizeof(struct stru_1) = ? */


答案是 8。若地址从 0 起，那么 mem\_a 之后为 1，不满足 int 类型“自然对齐”的要求，故插入 padding，使得 mem\_b 从 4 开始。

### 结构体尾部的 padding

    struct stru_2 {
        unsigned char   mem_a;
        int             mem_b;
        char            mem_c;
    };
    /* sizeof(struct stru_2) = ? */


答案是 12。因为结构体大小还需要是*结构体的对齐要求*的整数倍。进一步解释如下：

  * 在汇编层面，访存指令对访问的地址有对齐要求，例如 64 位访存指令访问的地址需要是 64 位对齐的，不然或性能下降或有异常。对此，编译器在栈中分配变量时，会插入一些 padding 来使变量对齐其宽度。
  * 结构体中间各成员也遵从上点，故有成员间的 padding。那么，结构体变量的对齐有何要求呢？
  * 结构体变量对齐要求，取其各成员对齐要求中的***最大***。例如“struct stru\_2 abc“，假设 abc 地址为“addr\_abc”，则 mem\_b 地址为 “addr\_abc + 1（mem\_a）+ 3（padding）”，须是 4 字节对齐才好。算术是数学老师教的童鞋马上就发现了，abc\_addr 必整除 4，即结构体地址是 4 字节（32 位）对齐的。
  * 最后，让我们来考虑“struct stru\_2 abc[2]”，如上点，abc[1] 的地址必是 4 字节（32 位）对齐的。若 abc[0]的大小是“1（mem\_a）+ 3（padding）+ 4（mem\_b） + 1（mem\_c）＝ 9”，加上 abc[0] 的起始地址（4 字节对齐），怎么算也是奇数啊！于是，必须再给结构体尾部加一些 padding，使得结构体总长是结构体对齐的整数倍。

### bitfield 怎么算？

提前向各位看官说明：以下例子需要用到不同编译器做对比。而说好的 LP64 环境来举例，却因为旅途中条件艰苦，没有合适的对比环境，只好用个 mingw32(gcc on Windows, 32bit) 来凑数。由于未用到 long 和指针，姑且将就下。

    struct stru_4 {
        char            mem_a:1;
        int             mem_b:4;
        int             mem_c:4;
    };
    /* sizeof(struct stru_4) = ? */


结果依赖编译环境：

  * 在64位 os x，clang 600.0.51 版本上，答案是 4。猜测相邻三个成员所占用位数加在一起，未超过三成员中最宽的 int 类型的位数。故实际只用 1 个 int 搞定。
  * 在 mingw32 环境中，gcc 4.8.1 上，答案是 8。猜测相邻同类型会合并，即 mem\_a 享有一个 char，mem\_b 和 mem_c 共享一个 int。char 和 int 之间有 3 字节的 padding。

以下把这两环境简称为 clang 和 gcc。

    struct stru_5 {
        char            mem_a:1;
        int             mem_b:4;
        int             mem_c:4;
        int             mem_d:24;
        int             mem_e:9;
    };
    /* sizeof(struct stru_5) = ? */


在两编译环境中，答案均是 12。对于该结果的猜测：

  * clang 上，mem\_a、mem\_b 和 mem\_c 享有一个 int，mem\_d 独享一个，mem\_e 独享一个。即 mem\_d 自身各个位，没有被分到两个 int 类型存储上。
  * gcc 上，mem\_a 享有一个 char，之后 3 字节 padding。接下来 mem\_b、mem\_c 和 mem\_d 共享一个 int，mem_e 享有最后一个 int。

### union和其他

    union uni_1 {
        struct stru_2   mem_a;
        long            mem_b;
    };
    /* sizeof(union uni_1) = ? */


答案是 16。首先 union 类型空间占用取其各成员中**最大者**，其次，同样考虑尾部 padding，还必须进一步增肥至_ union 对齐的整数倍_。

    struct stru_3 {
        char            mem_a;
        struct stru_2   mem_b;
    };
    /* sizeof(struct stru_3) = ? */


答案是 16。

### #pragma pack(N) 指示

至此，我们讲的都是*自然对齐*的情况。

然而可以通过“#pragma pack(N)“指示编译器，手工调整对齐。其中 N 可以为空（不填），此时就是自然对齐。

N 可以取 1, 2, 4, 8, &#8230;。当 N 指定时，结构体成员实际对齐要求为 MIN(N, 类型的自然对齐要求)，例如 N = 2 时，对于 int 型成员而言，其实际对齐要求为 MIN (2, 4) = 2。

另外，在空间占用估算中用到的结构体自身对齐要求，也成了 MIN(N, 结构体的自然对齐要求)。

以下给出上述结构体在一组 N 值下的大小：

  * N == 1：stru_1到5大小依次为 5，6, 7, 2(clang, gcc 上为 5), 6(clang，gcc 上为9)。可见此时没有 padding。

  * N == 2: stru_1到5大小依次为 6, 8, 10, 2(clang，gcc 上为 6), 6(clang，gcc 上为10)。

上述结果中含有 bitfield 的结构体再次亮了。随便挑个奇怪的结果来看，例如 N == 1 时, sizeof(stru_5) 在 clang 上为 2 字节，通过反汇编可知全部 bitfiled 被拼在了一起（64 位寄存器喔）。再次说明 bitfield 这货被编译器玩坏了。

## 大小尾端与位序

通常，多字节数据交换会考虑大小尾端的问题。例如 32 位（4 字节）数 “0&#215;12 34 56 78”：

  * 小尾端：*数值低位*在前（在内存的低地址），故本数在内存中，四个字节的排列为”0&#215;78“，“0&#215;56”，“0&#215;34”，“0&#215;12”。
  * 大尾端：*数值高位*在前（在内存的低地址），故本数在内存中，四个字节的排列为“0&#215;12”，“0&#215;34”，“0&#215;56”，“0&#215;78”。

上述提的是字节序。

再问，对于大小尾端，一个字节内，数值高、低位在内存中的顺序是什么？也就是位序的问题。

答案是与字节序一致。例如以下代码：

    struct {
        unsigned char   f1:3;
        unsigned char   f2:4;
    } bif;

    char *bif_p = (char *) &amp;bif;

    memset (&amp;bif, 0, sizeof(bif));

    bif.f1 = 2;
    bif.f2 = 5;

    printf ("0x%02x\n", bif_p[0]);


在小尾端上，打印输出为 0x2a。

成员 f1 内存地址该靠前，故对其赋值影响“字节数值”的低位。而 f2 由于地址靠后，赋值影响“字节数值”的高位。因此：

    0(not used)   0 1 0 1(f2)    0 1 0(f1)  （按照数值位高低排列，与地址序相反）
    即， 第 0-2 位，属于 f1；第 3-6 位，属于 f2。


在处理大小尾端时，大部分情况下不用考虑位序问题。例如在处理网络协议中，常用到htonl(s)，来将本机字节序转成网络序（网络序规定为大尾端）。该函数不对位序处理。在实际传输发生时，通过内存中“一字节的 8 个位”和“网卡 8个位” 的连线，即完成了转换。

对于将一个字节还要掰成许多位域的应用来说，那就要编程者自己费心了，总之字节的值是不会变的。以本节例子来说，大尾端上用 struct bif 对例中赋值进行解读，会得到错误的结果：

    0 0 1(f1)   0 1 0 1(f2)   0(not used)   （按照数值位高低排列，与地址序一致）


即，f1 的值变成了 1，f2 的值恰好还是 5。

可以在大尾端上定义新的结构体，来正确解读：

    struct {
        unsigned char   not_used:1;
        unsigned char   f2:4;
        unsigned char   f1:3;
    }


## 小结

费心思去了解一个结构体的内存布局，常见于对协议的解析，例如“p = (strcut ip_header *)(buffer);”。然而，使用某些库提供的 serialize/deserialize 功能（例如 [GVariant][2]）会是个更好的选择。

至于 bitfield，不要试图通过定义一个含位域的结构，来解析协议，因为不同编译器结果不同。乖乖地手动使用位操作来提取，虽然难看些，但毕竟可移植。

最后，大小尾端的位序由底层硬件来处理，通常无需考虑。





 [1]: http://tinylab.org
 [2]: https://developer.gnome.org/glib/stable/glib-GVariant.html
