---
title: 源码分析：函数调用关系绘制方法与逆向建模
author: Wu Zhangjin
layout: post
album: 源码分析之道
permalink: /source-code-analysis-how-best-to-draw-a-function-call/
tags:
  - c
  - clang
  - dot
  - fdp
  - FlameGraph
  - gcc
  - graph-easy
  - Linux
  - twopi
  - UML
  - 函数调用，tree
  - 源码分析
categories:
  - C
  - 源码分析
---

<!-- Title: 源码分析：如何更好地展示函数调用关系/流程图
<!-- Cat: Linux, C -->

<!-- TAG: Linux, C, 源码分析, 函数调用，tree, dot, twopi, fdp, graph-easy, FlameGraph -->

> By Falcon of [TinyLab.org][1]
> 2015/04/28


## 缘由

源码分析是程序员离不开的话题。无论是研究开源项目，还是平时做各类移植、开发，都避免不了对源码的深入解读。

工欲善其事，必先利其器。

前三篇分别介绍了如何静态/动态分析源码的函数调用关系（流程图），并介绍了三种不同的展示方式，这里再来回顾并介绍更多展示方式。

这几篇文章的思路汇总起来就是如何利用各类工具从源码或者从程序运行的情况逆向构建源码的模型，可以说是逆向建模，只不过这里只是停留在函数调用关系层面，所以在本文的后面，我们抽出一个章节来初步讨论如何逆向建模。

## tree

树状调用关系是最常见的一种展示方式，包括 `calltree`, `cflow` 等的默认输出结果都是如此。

这里补充介绍两个工具，都是编译器，一个是 `clang`，一个是 `gcc`。

### clang

<pre>$ sudo apt-get install clang
$ clang -cc1 -ast-dump test.c 2>/dev/null | egrep "FunctionDecl|Function "
|-FunctionDecl 0x2eb9350 &lt;test.c:3:1, col:14> a 'int (void)'
|-FunctionDecl 0x2eb94e0 &lt;line:4:1, col:21> b 'int (int)'
|       `-DeclRefExpr 0x2eb9588 &lt;col:16> 'int (void)' Function 0x2eb9350 'a' 'int (void)'
|-FunctionDecl 0x2f027f0 &lt;line:6:1, line:15:1> main 'int (void)'
|   |   `-DeclRefExpr 0x2f02970 &lt;col:9> 'int (void)' Function 0x2eb9350 'a' 'int (void)'
|   | | `-DeclRefExpr 0x2f029d8 &lt;col:9> 'int (int)' Function 0x2eb94e0 'b' 'int (int)'
|   | | `-DeclRefExpr 0x2f02cc0 &lt;col:9> 'int (const char *restrict, ...)' Function 0x2f02b70 'scanf' 'int (const char *restrict, ...)'
`-FunctionDecl 0x2f02b70 &lt;line:12:9> scanf 'int (const char *restrict, ...)' extern
</pre>

### gcc

较新版本的 `gcc` 在编译过程中可以直接生成流程图，以之前用到 `fib.c` 为例：

`$ gcc fib.c -fdump-tree-ssa-graph=fib`

上述命令会导出 `fib.dot`，处理后就是流程图，不过只是展示了函数内部的情况，函数间的关系未能体现。

另外，需要补充的是，`-fdump-tree-cfg-graph` 有 BUG，生成的 `dot` 文件缺少文件头，转换下查看效果。

`$ cat fib.dot | dot -Tsvg -o fib.svg`

效果如下：

![fib-gcc-dump-graph][2]

## Graphviz: dot / twopi / fdp

`tree2dotx` 能够将上述诸多标准的 `tree` 状结构转换为 `dot` 格式，并通过 Graphviz 的 `dot` 工具进一步转换为 svg 等可以直接显示的图文。

实际上，除了 dot 工具，Graphviz 还提供了另外几组类似的工具，通过 `man dot` 可以看到一堆：

  * dot &#8211; filter for drawing directed graphs
  * neato &#8211; filter for drawing undirected graphs
  * twopi &#8211; filter for radial layouts of graphs
  * circo &#8211; filter for circular layout of graphs
  * fdp &#8211; filter for drawing undirected graphs
  * sfdp &#8211; filter for drawing large undirected graphs
  * patchwork &#8211; filter for tree maps

通过验证发现，`fdp` 针对 `tree2dotx` 的结果展示效果不错：

`$ cd linux-0.11/
$ cflow -b -m main init/main.c | tree2dotx | fdp -Tsvg -o linux-0.11-fdp.svg`

效果如下：

![Linux 0.11 main callgraph with fdp][3]

## graph-easy

`graph-easy` 是另外一个展示 `dot` 图形的方式，有点类似 Graphviz 提供的上述工具中的一种，不过它有点特别，展示的结果尽可能做到整体对齐平铺，有点像硬件原理图的感觉。

先安装：

`$ sudo perl -MCPAN -e 'install Graph::Easy'
$ sudo perl -MCPAN -e 'install Graph::Easy::As_svg'`

用法：

`$ cflow -b -m main init/main.c | tree2dotx | \
        graph-easy --as=svg --output=linux-0.11-graph-easy.svg`

可以看到 `graph-easy` 的输出结果又是另外一种风格：

![graph-easy output of linux-0.11 main callgraph][4]

## FlameGraph

`FlameGraph` 之前主要是用于展示程序运行时的动态数据，实际上它也可以用来展示 `dot`，我们只要把 `dot` 转换为 `Flame` 需要的数据格式就好。

刚把 `tree2dotx` 改造了一下，添加了 `-o [dot|flame]` 参数以便支持 `FlameGraph` 采用的 `Flame` 格式。

&#8220;\` $ wget -c https://github.com/tinyclub/linux-0.11-lab/raw/master/tools/tree2dotx $ sudo cp tree2dotx /usr/local/bin/

$ cflow -b -m main init/main.c | tree2dotx -o flame | flamegraph.pl > linux-0.11-flame.svg &#8220;\`

效果如下：

![Linux 0.11 main callgraph with flame][5]

## 逆向建模

上述源码分析的诸多努力其实都是希望理顺源码的结构，而逆向建模则是这类努力的更专业的做法。

### 普通绘图工具

上述工具最终都可以转换为一种可以编辑的 svg 图片格式，如果想把这些图片用到书籍或者演示文稿中，那么可能还需要编辑或者转换，推荐 `inkscape`。

如果要制作流程图，比较推荐 `dia` 或者在线的工具 <https://www.draw.io/>。

另外，还有一种纯文本的绘图工具：<http://asciiflow.com/>，也非常有趣，这种图可以直接跟文本一起贴到文档里头，不过字体得用等宽字体，否则图文排版的时候会乱掉。

### UML 建模工具

除此之外，还有一些逆向建模工具，可以根据源码甚至二进制可执行文件直接进行逆向 UML 建模。不过暂时未能找到针对 C 语言的开源逆向建模工具。

而不支持逆向的建模工具则比较多，开源的有：

  * [yEd][6]

  * [yUML][7]

  * [OpenAmeos][8]

最后一笔工具还支持从建模语言生成代码模板。不过 OpenAmeos 的安装有点麻烦，而且其界面很难看。

OpenAmeos 安装时的注意事项：

  * 需要注释掉install: `export LD_ASSUME_KERNEL`
  * 把 `/path/to/Ameos_V10.2/bin` 路径加入 PATH 配置
  * 安装图形库 `libmotif*` 并修改 `bin/ameos` 里头的 `MOTIFHOME:=/usr/X11R6` 为 `MOTIFHOME:=/usr/`

不过据说有一些收费的软件支持 C 语言逆向建模，比如 Enterprise Architect，IDA，更多的建模工具见：

  * [UML 中国收集的相关工具一览][9]
  * [开源中国收集的 UML 工具][10]

### C 语言模块化开发

传统的 C 语言开发蛮多只是注重基本的编程风格（Coding Style），不像面向对象化编程，关于结构化、模块化的设计规范讨论很少。

恰好有同学在尝试用模块化的方法开发 C 语言程序，是不错的尝试：[模块化 C 代码与 UML 对象模型之间的映射][11]。

## 小结

截止到该篇，整个源码分析（函数级别）暂时告一段落。关于代码行层面的分析，我们放到以后再做，大家也可以提前了解 `gcov` 和 `kgcov` 这两个工具，它们分别针对应用程序和内核空间。





 [1]: http://tinylab.org
 [2]: /wp-content/uploads/2015/04/callgraph/fib-gcc-dump-graph.svg
 [3]: /wp-content/uploads/2015/04/callgraph/linux-0.11-fdp.svg
 [4]: /wp-content/uploads/2015/04/callgraph/linux-0.11-graph-easy.svg
 [5]: /wp-content/uploads/2015/04/callgraph/linux-0.11-flame.svg
 [6]: http://www.yworks.com/en/products_download.php
 [7]: http://www.yuml.me/diagram/scruffy/usecase/draw
 [8]: https://www.scopeforge.de/cb/project/8
 [9]: http://www.umlchina.com/Tools/Newindex1.htm
 [10]: http://www.oschina.net/project/tag/177/uml?sort=view&lang=0&os=37
 [11]: http://www.uml.org.cn/oobject/201201121.asp
