---
title: 源码分析：代码计数工具及其效率与准确度
author: Wu Zhangjin
layout: post
draft: true
album: 源码分析之道
permalink: /source-code-analysis-the-best-code-counting-tool/
tags:
  - cloc
  - sloccount
  - scc
  - loc
  - tokei
  - gocloc
  - 著作权
categories:
  - 源码分析
---

> By Falcon of [TinyLab.org][1]
> 2019/04/05


## 背景

源码分析是程序员离不开的话题。无论是研究开源项目，还是平时做各类移植、开发，都避免不了对源码的深入解读。

一次偶然的著作权申请需要获取项目代码行数以及代码用到的语言，于是有了这一篇。这篇文章主要介绍如何统计项目代码，能用的工具以及它们的优劣。

## wc

统计代码行数最直观的想法是用 `wc` 统计代码文件的行数。

首先得用 `find` 工具找出所有源代码，然后再用 `wc` 统计，然后删掉空行和评论，以 [Linux 0.11](https://github.com/tinyclub/linux-0.11-lab) 为例，粗略统计如下：

    $ git clone https://github.com/tinyclub/linux-0.11-lab.git
    $ cd linux-0.11-lab/0.11
    $ find . -name "*.[hcs]" | xargs -i cat {} | grep -v "^ *$" | grep -v " */\*.*\*/" | wc -l
    10816

可是我们对于评论的处理过于粗糙，而且漏掉了 Shell 和 Makefile 代码。

    $ find . -name "*.[hcs]" -or -name *.sh -or -name Makefile | xargs -i cat {} | grep -v "^ *$" | grep -v " */\*.*\*/" | wc -l
    11356

但是，这种临时拼凑的脚本的工作效率和准确度都大打折扣，所以应该有更好的办法？

## cloc & sloccount

简单的检索过后发现了 `cloc` 和 `sloccount`，两款都是用 `perl` 撰写的，直观的印象是两者首次运行时间都很长。


    $ sudo apt-get install cloc sloccount
    $ cloc .
         106 text files.
         106 unique files.
           4 files ignored.

    http://cloc.sourceforge.net v 1.60  T=0.56 s (181.8 files/s, 24607.5 lines/s)
    -------------------------------------------------------------------------------
    Language                     files          blank        comment           code
    -------------------------------------------------------------------------------
    C                               50            770           1034           6640
    C/C++ Header                    33            329            283           2154
    Assembly                         8            164            209           1579
    make                            10             97             59            449
    Bourne Shell                     1              8              9             23
    -------------------------------------------------------------------------------
    SUM:                           102           1368           1594          10845
    -------------------------------------------------------------------------------

`cloc` 统计出来的纯代码行数为 10845 行，比自己用脚本计算的少一些，可能原因就是部分注释我们未能彻底过滤掉。

    $ sloccount .
    Have a non-directory at the top, so creating directory top_dir
    Adding /media/falcon/develop/cloud-lab/labs/linux-0.11-lab/0.11/./Makefile to top_dir
    Adding /media/falcon/develop/cloud-lab/labs/linux-0.11-lab/0.11/./Makefile.head to top_dir
    Creating filelist for boot
    Creating filelist for fs
    Creating filelist for include
    Creating filelist for init
    Creating filelist for kernel
    Creating filelist for lib
    Creating filelist for mm
    Creating filelist for tools
    Categorizing files.
    Finding a working MD5 command....
    Found a working MD5 command.
    Computing results.


    SLOC	Directory	SLOC-by-Language (Sorted)
    4355    kernel          ansic=3391,asm=964
    2677    fs              ansic=2677
    2062    include         ansic=2062
    474     boot            asm=474
    332     mm              ansic=304,asm=28
    208     lib             ansic=208
    152     init            ansic=152
    22      tools           sh=22
    0       top_dir         (none)


    Totals grouped by language (dominant language first):
    ansic:         8794 (85.53%)
    asm:           1466 (14.26%)
    sh:              22 (0.21%)




    Total Physical Source Lines of Code (SLOC)                = 10,282
    Development Effort Estimate, Person-Years (Person-Months) = 2.31 (27.73)
     (Basic COCOMO model, Person-Months = 2.4 * (KSLOC**1.05))
    Schedule Estimate, Years (Months)                         = 0.74 (8.84)
     (Basic COCOMO model, Months = 2.5 * (person-months**0.38))
    Estimated Average Number of Developers (Effort/Schedule)  = 3.14
    Total Estimated Cost to Develop                           = $ 312,121
     (average salary = $56,286/year, overhead = 2.40).
    SLOCCount, Copyright (C) 2001-2004 David A. Wheeler
    SLOCCount is Open Source Software/Free Software, licensed under the GNU GPL.
    SLOCCount comes with ABSOLUTELY NO WARRANTY, and you are welcome to
    redistribute it under certain conditions as specified by the GNU GPL license;
    see the documentation for details.
    Please credit this data as "generated using David A. Wheeler's 'SLOCCount'."


`sloccount` 按目录统计了不同语言的占比以及整个项目的各语言代码行数，在这个项目上统计出来的 C 语言代码行数跟 `cloc` 高度一致，都是 8794 行，但是在统计 Assembly 的时候出现了偏差。

很有意思的是， `sloccount` 还基于 Basic COCOMO 模型（由 TRW 公司开发，Boehm 提出的结构化成本估算模型。是一种精确的、易于使用的成本估算方法），给出了项目开发所需的人月数估算以及人力投入成本预估。

## loc & tokei


`cloc` 与 `sloccount` 的慢对于大型项目确实是难以忍受的，所以进一步的检索发现还有 `loc` 和 `tokei`，两个都用 `rust` 语言撰写，效率有数十倍到 100 倍左右的提升。

    $ sudo apt-get install cargo
    $ cargo install loc tokei
    $ echo "export PATH=\$PATH:~/.cargo/bin" >> ~/.bashrc
    $ . ~/.bashrc


    $ loc .
    --------------------------------------------------------------------------------
     Language             Files        Lines        Blank      Comment         Code
    --------------------------------------------------------------------------------
     C                       50         8444          770         1035         6639
     C/C++ Header            33         2766          329          283         2154
     Assembly                 8         1952          164          333         1455
     Makefile                11          656          107           64          485
     Bourne Shell             1           40            8           10           22
    --------------------------------------------------------------------------------
     Total                  103        13858         1378         1725        10755
    --------------------------------------------------------------------------------

    $ tokei .
    -------------------------------------------------------------------------------
     Language            Files        Lines         Code     Comments       Blanks
    -------------------------------------------------------------------------------
     Assembly                8         1952         1788            0          164
     C                      50         8444         6637         1037          770
     C Header               33         2766         2143          294          329
     Makefile               10          605          449           59           97
     Shell                   1           40           22           10            8
    -------------------------------------------------------------------------------
     Total                 102        13807        11039         1400         1368
    -------------------------------------------------------------------------------

    $ tokei  --sort Code .
    -------------------------------------------------------------------------------
     Language            Files        Lines         Code     Comments       Blanks
    -------------------------------------------------------------------------------
     C                      50         8444         6637         1037          770
     C Header               33         2766         2143          294          329
     Assembly                8         1952         1788            0          164
     Makefile               10          605          449           59           97
     Shell                   1           40           22           10            8
    -------------------------------------------------------------------------------
     Total                 102        13807        11039         1400         1368
    -------------------------------------------------------------------------------

两者在速度上的提升相当明显，几乎都是秒出结果。不过两者的统计数据也有差异，在主体语言 C 上的统计都还算精准。

`tokei` 官网宣称其准确度比 `loc` 要高，感兴趣的可以看看这里的[对比测试结果](https://github.com/XAMPPRocky/tokei/blob/master/COMPARISON.md)。

另外，有趣的是 `tokei` 还提供了 `Badge` 服务，可以类似这样在 `Markdown` 中引用：

    [![](https://tokei.rs/b1/github/XAMPPRocky/tokei)](https://github.com/XAMPPRocky/tokei).

## scc

[scc](https://github.com/boyter/scc) 用 `go` 语言撰写，在效率上与 `loc` 和 `tokei` 相当，但是引入一个很有意义的 `complexity` 数据，这个用于评估[软件复杂度](https://blog.csdn.net/t_1007/article/details/53034408)。

在 [scc Releases](https://github.com/boyter/scc/releases) 下载一个编译好的版本，试运行如下：

    $ scc .
    ───────────────────────────────────────────────────────────────────────────────
    Language                 Files     Lines     Code  Comments   Blanks Complexity
    ───────────────────────────────────────────────────────────────────────────────
    C                           50      8444     6640      1039      765       1452
    C Header                    33      2766     2154       288      324         44
    Makefile                    10       605      449        59       97          0
    Assembly                     8      1952     1851         0      101         26
    gitignore                    3        11       11         0        0          0
    Shell                        1        40       22        10        8          7
    ───────────────────────────────────────────────────────────────────────────────
    Total                      105     13818    11127      1396     1295       1529
    ───────────────────────────────────────────────────────────────────────────────
    Estimated Cost to Develop $339,072
    Estimated Schedule Effort 10.171895 months
    Estimated People Required 3.948618
    ───────────────────────────────────────────────────────────────────────────────


`scc` 对 COCOMO 的评估结果跟 `sloccount` 接近。

## gocloc

[gocloc](https://github.com/hhatto/gocloc) 是用 `go` 写的另外一个类  `cloc` 工具，速度与 `loc` 和 `tokei` 相当，这里不做介绍。


## 小结

以上工具各有各的优势，`cloc` 和 `sloccount` 可轻松获得，而综合速度和准确度来看，tokei 优势明显，而 scc 则提供了 complexity 这样的特殊功能，另外，`sloccount` 同 `scc` 一样提供了 COCOMO 评估。请大家根据需要进行选择。更多代码计数器的功效请参考其他用户的经验：[Why count lines of code?](https://boyter.org/posts/why-count-lines-of-code/)。

其实，除了用法，这篇文章隐藏了一个非常有趣的问题，那就是为什么用 Rust 和 Go 写的 `loc`, `tokei`, `gocloc` 和 `scc` 的速度提升这么明显？非常值得进一步探索，可参考 [Sloc Cloc and Code - What happened on the way to faster Cloc](https://boyter.org/posts/sloc-cloc-code/)。
