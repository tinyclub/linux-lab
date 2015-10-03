---
title: 源码分析：动态分析 Linux 内核函数调用关系
author: Wu Zhangjin
layout: post
album: 源码分析之道
permalink: /source-code-analysis-dynamic-analysis-of-linux-kernel-function-calls/
tags:
  - 函数调用
  - 源码分析
categories:
  - C
  - 源码分析 
  - FlameGraph
  - Ftrace
  - Perf
---

> By Falcon of [TinyLab.org][1]
> 2015/04/18

## 缘由

源码分析是程序员离不开的话题。

无论是研究开源项目，还是平时做各类移植、开发，都避免不了对源码的深入解读。

工欲善其事，必先利其器。

前两篇介绍了静态分析和应用程序部分的动态分析。这里开始讨论如何动态分析 Linux 内核部分。

## 准备工作

### Ftrace

类似于用户态的 `gprof`，在跟踪内核函数之前，需要对内核做额外的一些配置，在内核相关函数插入一些代码，以便获取必要信息，比如调用时间，调用次数，父函数等。

早期的内核函数跟踪支持有 KFT，它基于 `-finstrument-functions`，在每个函数的出口、入口插入特定调用以便截获上面提到的各类信息。早期笔者就曾经维护过 KFT，并且成功移植到了 Loongson/MIPS 平台，相关邮件记录见：[kernel function tracing support for linux-mips][2]。不过 Linux 官方社区最终采用的却是 `Ftrace`，为什么呢？虽然是类似的思路，但是 `Ftrace` 有重大的创新：

  * Ftrace 只需要在函数入口插入一个外部调用：mcount，而 KFT 在入口和出口都要加
  * Ftrace 巧妙的拦截了函数返回的地址，从而可以在运行时先跳到一个事先准备好的统一出口，记录各类信息，然后再返回原来的地址
  * Ftrace 在链接完成以后，把所有插入点地址都记录到一张表中，然后默认把所有插入点都替换成为空指令（nop），因此默认情况下 Ftrace 的开销几乎是 0
  * Ftrace 可以在运行时根据需要通过 Sysfs 接口使能和使用，即使在没有第三方工具的情况下也可以方便使用

所以，本文只介绍 `Ftrace`，关于其详细用法，推荐看 `Ftrace` 作者 Steven 在 [LWN][3] 写的序列文章，例如：

  * Debugging the kernel using Ftrace: [1][4], [2][5]
  * [Secrets of the Ftrace function tracer][6]
  * [trace-cmd: A front-end for Ftrace][7]

对于本文要介绍的内容，大家只要使能 `Ftrace` 内核配置就可以，我们不会直接使用它的底层接口：

    CONFIG_FUNCTION_TRACER
    CONFIG_DYNAMIC_FTRACE
    CONFIG_FUNCTION_GRAPH_TRACER


除此之外，还需要把内核函数的符号表编译进去：

    CONFIG_KALLSYMS=y
    CONFIG_KALLSYMS_ALL=y


如果要直接使用 `Ftrace` 的话，可以安装下述工具，不过本文不做进一步介绍：

    $ sudo apt-get install trace-cmd kernelshark pytimerchart


### Perf

`Perf` 最早是为取代 `Oprofile` 而生，从 2009 年开始只是增加了一个新的系统调用，如今强大到几乎把 `Oprofile` 逼退历史舞台。因为它不仅支持硬件性能计数器，还支持各种软件计数器，为 Linux 世界提供了一套完美的性能 Profiling 工具，当然，内核底层部分的函数 Profiling 离不开 `Ftrace` 支持。

关于 `Perf` 的详细用法，可以参考：[Perf Wiki][8]。

Ok，同样需要使能如下内核配置：

    CONFIG_HAVE_PERF_EVENTS=y
    CONFIG_PERF_EVENTS=y


客户端安装：

    $ sudo apt-get install linux-tools-`uname -r`


### FlameGraph

[FlameGraph][9] 是 Profiling 数据展示领域的一大创新，传统的树状结构占用的视觉面积很大，而且无法精准地找到热点，而 `FlameGraph` 通过火焰状的数据展示，采用层叠结构，占用页面空间小，可以快速清晰地展示出每条路径的占比，而且基于 SVG 可以自由缩放，基于 Javascript 可以动态地展示每个函数的具体样本和占比。

Ok，把 `FlameGraph` 准备好：

    $ git clone https://github.com/brendangregg/FlameGraph.git
    $ sudo cp FlameGraph/flamegraph.pl /usr/local/bin/
    $ sudo cp FlameGraph/stackcollapse-perf.pl /usr/local/bin/


在使用 `FlameGraph` 前，我们简单介绍一个例子以便更好地理解它的独到之处。

> a;b;c;d 90 e; 10

这个数据有三个信息：

  * 函数调用关系：a 依次调用 b, c, d
  * 调用次数占比：a 分支 90 次，e 分支 10 次
  * 主要有两个大的分支：a 和 e

要渲染这个数据，如果用之前的 `dot` 描述语言，相对比较复杂一些，特别是当函数节点特别多的时候，几乎会没法查看，但是 `FlameGraph` 处理得很好，把上面的信息保存为 calls.log 并处理如下：

    $ cd FlameGraph
    $ cat calls.log | flamegraph.pl > calls-flame.svg


效果如下：

![Simple Flame Graph For Calls][10]

## 更多准备

日常程序开发时我们基本都只是关心用户态的情况，在系统级的优化中，则会兼顾系统库甚至内核部分，因为日常应用运行时的蛮多工作除了应用本身的各类操作外，还有蛮大一部分会访问到各类系统库，然后通过库访问到各类底层系统调用，进而访问到 Linux 内核空间。

我们回到上篇文章的例子：`fib.c`，可以通过 `ltrace` 和 `strace` 查看库函数和系统调用的情况：

    $ ltrace -f -T -ttt -c ./fib 2>&1 > /dev/null
    % time     seconds  usecs/call     calls      function
    ------ ----------- ----------- --------- --------------------
    100.00    0.006063         141        43 printf
    ------ ----------- ----------- --------- --------------------
    100.00    0.006063                    43 total

    $ strace -f -T -ttt -c ./fib 2>&1 > /dev/null
    % time     seconds  usecs/call     calls    errors syscall
    ------ ----------- ----------- --------- --------- ----------------
     22.77    0.000051           6         8           mmap
     15.18    0.000034           9         4           mprotect
     11.61    0.000026           9         3         3 access
      9.82    0.000022          22         1           munmap
      9.38    0.000021          21         1           execve
      8.93    0.000020          10         2           open
      7.14    0.000016           5         3           fstat
      4.46    0.000010           5         2           close
      3.12    0.000007           7         1           read
      3.12    0.000007           7         1           brk
      2.68    0.000006           6         1         1 ioctl
      1.79    0.000004           4         1           arch_prctl
      0.00    0.000000           0         1           write
    ------ ----------- ----------- --------- --------- ----------------
    100.00    0.000224                    29         4 total


上面文章可以看到应用本身的 `fibonnaci()` 占用了几乎 `100%` 的时间开销，但实际上在一个应用程序运行时，库函数和内核都有开销。上述 `ltrace` 反应了库函数的调用情况，`strace` 则反应了系统调用的情况，内核开销则是通过系统调用触发的，当然，还有一部分是内核本身调度，正文切换，内存分配等开销。大概的时间占比可以通过 `time` 命令查看：

    $ time ./fib 2>&1 > /dev/null
    real        0m5.887s
    user        0m5.881s
    sys         0m0.004s


接下来，咱们切入正题。通过基于 `Ftrace` 的 `Perf` 来综合看看一个应用程序运行时用户空间和内核空间两部分的调用情况并通过 `FlameGraph` 绘制出来。

## 内核函数调用

在使用 `Perf` 之前，除了上述内核配置外，还需要使能一个符号获取权限，否则结果会是一大堆 16 进制数字，看不到函数符号：

    $ echo 0 > /proc/sys/kernel/kptr_restrict


咱们先分开来看看用户空间，库函数和系统调用的情况，以该命令为例：

    find /proc/ -maxdepth 2 -name "vm" 2>&1 >/dev/null


### 用户空间

    $ valgrind --tool=callgrind find /proc/ -maxdepth 2 -name "vm" 2>&1 >/dev/null
    $ gprof2dot -f callgrind ./callgrind.out.24273 | dot -Tsvg -o find-callgrind.svg


效果如下：

![The Callgraph of the find command][11]

### 库函数

    $ ltrace -f -ttt -c find /proc/ -maxdepth 2 -name "vm" 2>&1 >/dev/null
    % time     seconds  usecs/call     calls      function
    ------ ----------- ----------- --------- --------------------
     30.75    2.939452          62     47175 strlen
     16.71    1.597174          62     25560 free
     15.38    1.469654          62     23589 memmove
      9.18    0.877211          63     13773 malloc
      8.55    0.817158          65     12542 readdir
      7.65    0.731476          62     11796 fnmatch
      7.56    0.722771          61     11793 __strndup
      1.73    0.165002          83      1966 __fxstatat
      0.41    0.039644          78       503 fchdir
      0.23    0.022348          54       408 memcmp
      0.23    0.022276          89       250 closedir
      0.23    0.021551          86       250 opendir
      0.22    0.021419          85       250 close
      0.22    0.021144          84       251 open
      0.21    0.019795          79       249 __fxstat
      0.21    0.019790       19790         1 qsort
      0.17    0.016417          65       250 dirfd
      0.16    0.015680          98       159 strcmp
      0.16    0.015218          60       252 __errno_location
      0.00    0.000417         417         1 dcgettext
      0.00    0.000404         404         1 setlocale
      0.00    0.000266         133         2 isatty
      0.00    0.000213         106         2 getenv
      0.00    0.000158         158         1 __fprintf_chk
      0.00    0.000158          79         2 fclose
      0.00    0.000135         135         1 uname
      0.00    0.000120         120         1 strtod
      0.00    0.000113          56         2 __fpending
      0.00    0.000110         110         1 bindtextdomain
      0.00    0.000107         107         1 gettimeofday
      0.00    0.000107         107         1 textdomain
      0.00    0.000107         107         1 fileno
      0.00    0.000106         106         1 strchr
      0.00    0.000106         106         1 memcpy
      0.00    0.000105         105         1 __cxa_atexit
      0.00    0.000102          51         2 ferror
      0.00    0.000092          92         1 fflush
      0.00    0.000079          79         1 realloc
      0.00    0.000076          76         1 strspn
      0.00    0.000072          72         1 strtol
      0.00    0.000052          52         1 calloc
      0.00    0.000051          51         1 strrchr
    ------ ----------- ----------- --------- --------------------
    100.00    9.558436                151045 total


### 系统调用

    $ strace -f -ttt -c find /proc/ -maxdepth 2 -name "vm" 2>&1 >/dev/null
    % time     seconds  usecs/call     calls    errors syscall
    ------ ----------- ----------- --------- --------- ----------------
     39.93    0.007072           4      1966           newfstatat
     22.44    0.003974           8       500           getdents
     10.53    0.001865           4       508           close
      8.27    0.001464           3       503           fchdir
      6.09    0.001079           4       261         4 open
      5.72    0.001013           4       250           openat
      4.68    0.000829           3       256           fstat
      0.68    0.000120           9        13           mmap
      0.36    0.000064          11         6           mprotect
      0.33    0.000058          12         5           brk
      0.27    0.000048          16         3           munmap
      0.20    0.000036           9         4         4 access
      0.19    0.000034           9         4           read
      0.11    0.000020           7         3         2 ioctl
      0.07    0.000012          12         1           write
      0.05    0.000009           9         1           execve
      0.03    0.000006           6         1           uname
      0.03    0.000006           6         1           arch_prctl
    ------ ----------- ----------- --------- --------- ----------------
    100.00    0.017709                  4286        10 total


接下来，通过 `perf` 来看看内核部分：

### 内核空间

    $ perf record -g find /proc -maxdepth 2 -name "vm" 2>&1 >/dev/null
    $ perf report -g --stdio
    $ perf script | stackcollapse-perf.pl > find.perf-outfolded
    $ flamegraph.pl find.perf-outfolded > find-flame.svg


上述几条命令大体意思如下：

  * `perf record -g` 记录后面跟着命令当次执行时的函数调用关系
  * `perf report -g --stdio` 在控制台打印出获取到的函数关系数据（输出结果有点类似于树状图）
  * `perf script | stackcollapse-perf.pl > find.perf-outfolded` 转换为 FlameGraph 支持的格式
  * `flamegraph.pl find.perf-outfolded > find-flame.svg` 生成火焰图

效果如下： ![The FlameGraph of the Profiling result of the find command][12]

## 小结

通过上述过程，咱们演示了如何分析一个应用程序执行时的内核空间部分函数调用情况，进而对前面两篇文章进行了较好的补充。

整个序列到目前为止主要都是函数调用关系的分析。对于源码的分析也好，对于性能的优化也好，都是完全不够的：

  * 一方面，这个只能辅助理解到函数级别，无法理解到代码级别。要做进一步，得 `gcov` 和 `kgcov` 的支持。
  * 如果要做性能分析，除了函数调用关系跟踪热点区域外，其实还缺少一些信息，比如整个调用时序，当前的处理器频率，内核调度情况等，并不能在这个序列体现。

接下来，针对该源码分析系列，我们会再补充三篇文章：

  * 函数调用关系（流程图）绘图方法介绍，将在现有的基础上再介绍几种新方法并分析优点和缺点。
  * 代码级别的源码分析，通过 `gcov` 和 `kgcov` 进行分析。

除此之外，我们会新开另外一个性能优化系列，来介绍各种性能优化的实例，包括应用程序与内核两个方面。

## 倡议

最后，笔者想对那些开源工具的开发者和贡献者们致敬！

Linux 领域聚拢了太多的天才，创意如泉涌般不断滋润 IT 世界，本文用到的三大工具的原创作者都是这类天才的代表，敬仰之情无以言表。

跟 Steven 有过一面之缘，而且在笔者 2009 年往官方社区提交 [Ftrace For MIPS][13] 时，他提供了诸多指导和帮助，感激之情化作无限专研的动力。

在这里，诚邀更多的一线工程师们汇聚到[泰晓科技][1]，一起协作，分享学习的心得，交流研发的经验，协同开发开源工具，一起致力于促进业界的交流与繁荣。目前已经有 15 个一线工程师参与进来，我们一同通过 `worktile` 协作，一起探讨，一起创作。如果乐意加入，可通过[联系我们][14]获得邀请。





 [1]: http://tinylab.org
 [2]: http://www.linux-mips.org/archives/linux-mips/2009-04/msg00244.html
 [3]: http://lwn.net
 [4]: https://lwn.net/Articles/365835/
 [5]: https://lwn.net/Articles/366796/
 [6]: https://lwn.net/Articles/370423/
 [7]: https://lwn.net/Articles/410200/
 [8]: https://perf.wiki.kernel.org/index.php/Tutorial
 [9]: http://www.brendangregg.com/FlameGraphs/cpuflamegraphs.html
 [10]: /wp-content/uploads/2015/04/callgraph/calls-flame.svg
 [11]: /wp-content/uploads/2015/04/callgraph/find-callgrind.svg
 [12]: /wp-content/uploads/2015/04/callgraph/find-flame.svg
 [13]: http://lwn.net/Articles/361128/
 [14]: /about/#Join_TinyLab
