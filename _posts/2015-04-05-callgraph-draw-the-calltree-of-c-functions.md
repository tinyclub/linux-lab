---
title: 源码分析：静态分析 C 程序函数调用关系图
author: Wu Zhangjin
layout: post
album: 源码分析之道
permalink: /callgraph-draw-the-calltree-of-c-functions/
tags:
  - Callgraph
  - dot
  - graphviz
  - Linux
  - Linux 0.11
  - tree2dotx
categories:
  - C
  - 源码分析
---

<!-- Title: Callgraph: Draw the calltree of the C functions -- Static Analysis (part1) -->

<!-- TODO: 把 callgraph, tree2dotx 工具从 Linux 0.11 拿出来，形成一个独立的工具，并添加必要的参数，比如说过滤，比如说指定深度，还有就是指定目标路径。 -->

> By Falcon of [TinyLab.org][1]
> 2015/04/03


## 故事缘由

源码分析是程序员离不开的话题。无论是研究开源项目，还是平时做各类移植、开发，都避免不了对源码的深入解读。

工欲善其事，必先利其器。今天我们来玩转一个小工具，叫 Callgraph，它可以把 C 语言的函数调用树（或者说流程图）画出来。

传统的命令行工具 Cscope, Ctags 可以结合 vim 等工具提供高效快捷的跳转，但是无法清晰的展示函数内部的逻辑关系。

至于图形化的IDE，如 QtCreator, Source Insight, Eclipse, Android Studio 等，却显得笨重，而且不一定支持导出调用关系图。

在[开源软件在线代码交叉检索][2] 一文中我们也介绍到了诸如 LXR, OpenGrok 之类的工具，它们避免了本地代码库而且提供了方便的 Web 展示，不过也无法提供函数关系的清晰展示。

下面开始 Callgraph 之旅。

## 安装 Callgraph

Callgraph 实际由三个工具组合而成。

  * 一个是用于生成 C 函数调用树的 cflow 或者 calltree，下文主要介绍 cflow。
  * 一个处理 dot 文本图形语言的工具，由 graphviz 提升。建议初步了解下：[DOT 语言][3]。
  * 一个用于把 C 函数调用树转换为 dot 格式的脚本：tree2dotx

以 Ubuntu 为例，分别安装它们：

    $ sudo apt-get install cflow graphviz


如果确实要用 calltree，请通过如下方式下载。不过 calltree 已经年久失修了，建议不用。

    $ wget -c https://github.com/tinyclub/linux-0.11-lab/raw/master/tools/calltree


接下来安装 tree2dotx 和 Callgraph，这里都默认安装到 `/usr/local/bin`。

    $ wget -c https://github.com/tinyclub/linux-0.11-lab/raw/master/tools/tree2dotx
    $ wget -c https://github.com/tinyclub/linux-0.11-lab/raw/master/tools/callgraph
    $ sudo cp tree2dotx callgraph /usr/local/bin
    $ sudo chmod +x /usr/local/bin/{tree2dotx,callgraph}


**注**：部分同学反馈，`tree2dotx`输出结果有异常，经过分析，发现用了 `mawk`，所以请提交安装下`gawk`：

    $ sudo apt-get install gawk


## 分析 Linux 0.11

### 准备

先下载泰晓科技提供的五分钟 Linux 0.11 实验环境：[Linux-0.11-Lab][4]。

    $ git clone https://github.com/tinyclub/linux-0.11-lab.git && cd linux-0.11-lab


### 初玩

回到之前在 [Linux-0.11-Lab][4] 展示的一副图：

![Linux 0.11 CallGraph of main][5]

它展示了 Linux 0.11 的主函数 main 的调用层次关系，清晰的展示了内核的基本架构。那这样一副图是如何生成的呢？非常简单：

    $ make cg f=main
    Func: main
    Match: 3
    File:
         1    ./init/main.c: * main() use the stack at all after fork(). Thus, no function
         2    ./init/main.c: * won't be any messing with the stack from main(), but we define
         3    ./init/main.c:void main(void)        /* This really IS void, no error here. */
    Select: 1 ~ 3 ? 3
    File: ./init/main.c
    Target: ./init/main.c: main -> callgraph/main.__init_main_c.svg


需要注意的是，上面提供了三个选项用于选择需要展示的图片，原因是这个 callgraph 目前的函数识别能力还不够智能，可以看出 3 就是我们需要的函数，所以，上面选择序号 3。

生成的函数调用关系图默认保存为 callgraph/main._\_init\_main_c.svg。

图片导出后，默认会调用 chromium-browser 展示图片，如果不存在该浏览器，可以指定其他图片浏览工具，例如：

    $ make cg b=firefox


上面的 `make cg` 实际调用 `callgraph`：

    $ callgraph -f main -b firefox


### 玩转它

类似 `main` 函数，实际也可渲染其他函数，例如：

    $ callgraph -f setup_rw_floppy
    Func: setup_rw_floppy
    File: ./kernel/blk_drv/floppy.c
    Target: ./kernel/blk_drv/floppy.c: setup_rw_floppy -> callgraph/setup_rw_floppy.__kernel_blk_drv_floppy_c.svg


因为只匹配到一个 `setup_rw_floppy`，无需选择，直接就画出了函数调用关系图，而且函数名自动包含了函数所在文件的路径信息。

  * 模糊匹配

    例如，如果只记得函数名的一部分，比如 `setup`，则可以：

        $ callgraph -f setup
        Func: setup
        Match: 4
        File:
             1    ./kernel/blk_drv/floppy.c:static void setup_DMA(void)
             2    ./kernel/blk_drv/floppy.c:inline void setup_rw_floppy(void)
             3    ./kernel/blk_drv/hd.c:int sys_setup(void * BIOS)
             4    ./include/linux/sys.h:extern int sys_setup();
        Select: 1 ~ 4 ?


    因为 `setup_rw_floppy` 函数是第 2 个被匹配到的，选择 2 就可以得到相同的结果。

  * 指定函数所在文件（或者文件所在的目录）

        $ callgraph -f setup -d ./kernel/blk_drv/hd.c


    类似的， `make cg` 可以这么用：

        $ make cg f=setup d=./kernel/blk_drv/hd.c


    看看效果：

![Linux 0.11 CallGraph of setup_rw_floppy][6]

## 分析新版 Linux

### 初玩

先来一份新版的 Linux，如果手头没有，就到 www.kernel.org 搞一份吧：

    $ wget -c https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.10.73.tar.xz
    $ tar Jxf linux-3.10.73.tar.xz && cd linux-3.10.73


玩起来：

    $ callgraph -f start_kernel -d init/main.c


### 酷玩

  * 砍掉不感兴趣的函数分支

    上面生成的图，有没有觉得 `printk` 之类的调用太多，觉得很繁琐。没关系，用 `-F` 砍掉。

        $ callgraph -f start_kernel -d init/main.c -F printk


    如果要砍掉很多函数，则可以指定一个函数列表：

        $ callgraph -f start_kernel -d init/main.c -F "printk boot_cpu_init rest_init"


  * 指定函数调用深度：

    用 `-D` 命令可以指定：

        $ callgraph -f start_kernel -d init/main.c -F "printk boot_cpu_init rest_init" -D 2


  * 指定函数搜索路径

    我们来看看 `update_process_times` 的定义，用 `-d` 指定搜索路径：

        $ callgraph -f update_process_times -d kernel/


    它会自动搜索 `kernel/` 目录并生成一副图，效果如下：

    ![Linux CallGraph of update_process_times][7]

    考虑到 `callgraph` 本身的检索效率比较低（采用grep），如果不能明确函数所在的目录，则可以先用 `cscope` 之类的建立索引，先通过这些索引快速找到函数所在的文件，然后用 `-d` 指定文件。

    例如，假设我们通过 `cs find g update_process_times` 找到该函数在 `kernel/timer.c` 中定义，则可以：

        $ callgraph -f update_process_times -d kernel/timer.c


## 原理分析

`callgraph` 实际上只是灵活组装了三个工具，一个是 cflow，一个是 tree2dotx，另外一个是 dot。

### cflow：拿到函数调用关系

    $ cflow -b -m start_kernel init/main.c > start_kernel.txt


### tree2dotx: 把函数调用树转换成 dot 格式

    $ cat start_kernel.txt | tree2dotx > start_kernel.dot


### 用 dot 工具生成可以渲染的图片格式

这里仅以 svg 格式为例：

    $ cat start_kernel.dot | dot -Tsvg -o start_kernel.svg


实际上 dot 支持非常多的图片格式，请参考它的手册：`man dot`。

## 趣玩 tree2dotx

关于 `tree2dotx`，需要多说几句，它最早是笔者 2007 年左右所写，当时就是为了直接用图文展示树状信息。该工具其实支持任意类似如下结构的树状图：

    a
      b
      c
        d
        x
          y
      e
      f


所以，我们也可以把某个目录结构展示出来，以 Linux 0.11 为例：

    $ cd linux-0.11
    $ tree -L 2 | tree2dotx | dot -Tsvg -o tree.svg


如果觉得一张图显示的内容太多，则可以指定某个当前正在研读的内核目录，例如 `kernel` 部分：

    $ tree -L 2 kernel | tree2dotx -f Makefile | dot -Tsvg -o tree.svg


看下效果：

![Linux 0.11 tree Graph of kernel/][8]

## What&#8217;s more?

上文展示了如何把源码的调用关系用图文的方式渲染出来。好处显而易见：

  * 不仅可以清晰的理解源码结构，从而避免直接陷入细节，进而提高源码分析的效率。
  * 也可以基于这个结果构建流程图，然后用 `inkscape` 之类的工具做自己的调整和扩充，方便做后续展示。
  * 还可以把这些图文用到文档甚至书籍中，以增加可读性。

`Callgraph` 的图文展示基于 `cflow` 或者 `calltree`，它们都只是静态源码分析的范畴。

后续我们将从从运行时角度来动态分析源码的实际执行路径。我们计划分开展示应用部分和内核部分。





 [1]: http://tinylab.org
 [2]: /online-cross-references-of-open-source-code-softwares/
 [3]: http://zh.wikipedia.org/wiki/DOT%E8%AF%AD%E8%A8%80
 [4]: /linux-0-11-lab/
 [5]: /wp-content/uploads/2015/04/callgraph/linux-0.11-main.svg
 [6]: /wp-content/uploads/2015/04/callgraph/linux-0.11-setup_rw_floppy.svg
 [7]: /wp-content/uploads/2015/04/callgraph/linux-update_process_times.svg
 [8]: /wp-content/uploads/2015/04/callgraph/linux-0.11-kernel-tree.svg
