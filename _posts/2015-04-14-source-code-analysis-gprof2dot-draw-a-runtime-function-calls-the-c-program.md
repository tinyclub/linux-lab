---
title: 源码分析：动态分析 C 程序函数调用关系
author: Wu Zhangjin
album: 源码分析之道
layout: post
permalink: /source-code-analysis-gprof2dot-draw-a-runtime-function-calls-the-c-program/
tags:
  - Callgrind
  - Gprof
  - Gprof2dot
  - Kcachegrind
  - Valgrind
categories:
  - C
  - 源码分析
  - Gprof
  - Valgrind
---

> By Falcon of [TinyLab.org][1]
> 2015/04/14


## 缘由

源码分析是程序员离不开的话题。无论是研究开源项目，还是平时做各类移植、开发，都避免不了对源码的深入解读。

工欲善其事，必先利其器。

之前已经介绍了[如何通过 Callgraph 静态分析源代码][2]，这里介绍如何分析程序运行时的实际函数执行情况，考虑到应用部分和内核部分有比较大的差异，该篇先介绍应用部分。

主要介绍三款工具，一款是 `gprof`，另外一款是 `valgrind`，再一款则是能够把前两款的结果导出为 dot 图形的工具，叫 `gprof2dot`，它的功能有点类似于我们[上次][2]介绍的 `tree2dotx`。

## 准备

需要事先准备好几个相关的工具。

  * [gprof2dot][3]: converts the output from many profilers into a dot graph

        $ sudo apt-get install python python-pip
        $ sudo pip install gprof2dot


  * graphviz: dot 格式处理

        $ sudo apt-get install graphviz


  * gprof: display call graph profile data

        $ sudo apt-get install gprof


  * valgrind: a suite of tools for debugging and profiling programs

        $ sudo apt-get install valgrind


工具好了，再来一个典型的 C 程序，保存为：fib.c

    #include <stdio.h>

    int fibonacci(int n);

    int main(int argc, char **argv)
    {
        int fib;
        int n;

        for (n = 0; n <= 42; n++) {
            fib = fibonacci(n);
            printf("fibonnaci(%d) = %dn", n, fib);
        }

        return 0;
    }

    int fibonacci(int n)
    {
        int fib;

        if (n <= 0) {
            fib = 0;
        } else if (n == 1) {
            fib = 1;
        } else {
            fib = fibonacci(n -1) + fibonacci(n - 2);
        }

        return fib;
    }


## gprof

Gprof 用于对某次应用的运行时代码执行情况进行分析。

它需要对源代码采用 `-pg` 编译，然后运行：

    $ gcc -pg -o fib fib.c
    $ ./fib


运行完以后，会生成一份日志文件：

    $ ls gmon.out
    gmon.out


可以分析之：

    $ gprof -b ./fib | gprof2dot | dot -Tsvg -o fib-gprof.svg


查看 `fib-gprof.svg` 如下：

![Draw fibonacci by Gprof][4]

可以观察到，这个图表除了调用关系，还有每个函数的执行次数以及百分比。

## Valgrind s callgrind

Valgrind 是开源的性能分析利器。它不仅可以用来检查内存泄漏等问题，还可以用来生成函数的调用图。

Valgrind 不依赖 `-pg` 编译选项，可以直接编译运行：

    $ gcc -o fib fib.c
    $ valgrind --tool=callgrind ./fib


然后会看到一份日志文件：

    $ ls callgrind*
    callgrind.out.22737


然后用 `gprof2dot` 分析：

    $ gprof2dot -f callgrind ./callgrind.out.22737 | dot -Tsvg -o fib-callgrind.svg


查看 `fib-callgrind.svg` 如下：

![Draw fibonacii by Valgrind s callgrind][5]

需要提到的是 Valgrind 提取出了比 gprof 更多的信息，包括 main 函数的父函数。

不过 Valgrind 实际提供了更多的信息，用 `-n0 -e0` 把执行百分比限制去掉，所有执行过的全部展示出来：

    $ gprof2dot -f callgrind -n0 -e0 ./callgrind.out.22737 | dot -Tsvg -o fib-callgrind-all.svg


结果如下：

![Draw fibonacii by Valgrind s callgrind (All output)][6]

所有的调用情况都展示出来了。热点调用分支用红色标记了出来。因为实际上一个程序运行时背后做了很多其他的事情，比如动态符号链接，还有比如 `main` 实际代码里头也调用到 `printf`，虽然占比很低。

考虑到上述结果太多，不便于分析，如果只想关心某个函数的调用情况，以 `main` 为例，则可以：

    $ gprof2dot -f callgrind -n0 -e0 ./callgrind.out.22737 --root=main | dot -Tsvg -o fib-callgrind-main.svg


![Draw fibonacii by Valgrind s callgrind (Only Main)][7]

需要提到的是，实际上除了 `gprof2dot`，`kcachegrind` 也可以用来展示 `Valgrind's callgrind` 的数据：

    $ sudo apt-get install kcachegrind
    $ kcachegrind ./callgrind.out.22737


通过 `File --> Export Graph` 可以导出调用图。只不过一个是图形工具，一个是命令行，而且 `kcachegrind` 不能一次展示所有分支，不过它可以灵活逐个节点查看。

## What&#8217;s more?

上文我们展示了从运行时角度来分析源码的实际执行路径，目前只是深入到了函数层次。

结果上跟上次的静态分析稍微有些差异。

  * 实际运行时，不同分支的调用次数有差异，甚至有些分支可能根本就执行不到。这些数据为我们进行性能优化提供了可以切入的热点。
  * 实际运行时，我们观察到除了代码中有的函数外，还有关于 `main` 的父函数，甚至还有库函数如 `printf`的内部调用细节，给我们提供了一种途径去理解程序背后运行的细节。

本文只是介绍到了应用程序部分（实际上是程序运行时的用户空间），下回我们将分析，当某个应用程序执行时，哪些内核接口（系统调用）被调用到，那些接口的执行情况以及深入到内核空间的函数调用情况。





 [1]: http://tinylab.org
 [2]: /callgraph-draw-the-calltree-of-c-functions/
 [3]: https://github.com/jrfonseca/gprof2dot
 [4]: /wp-content/uploads/2015/04/callgraph/fib-gprof.svg
 [5]: /wp-content/uploads/2015/04/callgraph//fib-callgrind.svg
 [6]: /wp-content/uploads/2015/04/callgraph/fib-callgrind-all.svg
 [7]: /wp-content/uploads/2015/04/callgraph//fib-callgrind-main.svg
