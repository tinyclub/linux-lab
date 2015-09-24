---
title: 利用 GDB 进行远程调试
author: Wu Zhangjin
layout: post
permalink: /for-remote-debugging-using-gdb/
views:
  - 26
tags:
  - 远程调试
  - gdb
  - gdbserver
categories:
  - Linux
---

> By Falcon of [TinyLab.org][1]
> 2007/04/22


## 简介

在进行嵌入式系统开发时，受到嵌入式系统资源的限制，调试环境和通用桌面系统的调试环境有差别，于是引入了远程调试技术。这时，调试器运行于通用桌面系统，被调试的程序则运行于基于特定硬件平台的嵌入式系统（目标系统）。因此，要求调试器和被调试程序之间进行通信，调试器还需要能够处理某些特定硬件平台的信息。

插桩（stub）方案是在目标系统和调试器内分别加入某些功能模块，二者互通信息来进行调试。而通过引入 `gdbserver` 这个远程服务程序，正好可以充当目标机上的 stub，本地主机上运行通常使用的调试器 `gdb`，但是在指定“调试目标”时不再用 `file` 命令指定调试的可执行文件，而是用 `target remote` 命令来指定需要调试的目标机，由它发起对目标机的连接。

## 用 gdb/gdbserver 进行远程调试

这里通过搭建一个主机 PC 端和目标机端的 `gdbserver` 来做实验。

1. 编译宿主机上的 gdb 调试器

    如果目标机是 ARM 内核的话，就得用 `arm-linux-gcc` 来编译 gdb 了，X86 直接就可以用系统已经安装的 `gdb`。

    这里简单介绍如何交叉编译 `gdb` 和 `gdbserver`：

        * gdb 是调试客户端，而 gdbserver 是调试服务器。
        * 前者运行在本地机器上，但是调试的目标代码是运行在板子上的，后者本身就运行在板子上，用来调试板子上的代码，所以编译时需要分别编译，编译时通过`--host`，`--target` 等参数指定以便能够正确编译。当然，交叉编译它们之前首先得建立目标开发板的交叉编译环境。可自己编译：[《如何为嵌入式开发建立交叉编译环境》](http://www.ibm.com/developerworks/cn/linux/l-embcmpl/) 也可以直接从 Linaro 等仓库下载编译现成的。


2. 编译目标机上的 stub 程序，即编译一个 `gdbserver`

    这个 stub 程序也应该是符合目标机处理器体系结构的，如果是 ARM，也需要用 `arm-linux-gcc` 来编译）并下载到目标机上去，这里直接用已经安装好的 `gdbserver`。

3. 编写一个简单的用于调试的程序

        /* test.c */
        #include <stdio.h>

        int main()
        {
                int i;

                i = 10;

                printf("i = %d\n", i);
                return 0;
        }


4. 编译可运行于目标板的机器代码，并下载到目标机上

    如果目标板是 ARM，那么应该这么编译：

        $ arm-linux-gcc  -g -o test test.c


    X86 直接这么编译就可以：

        $ gcc  -g -o test test.c


    编译好以后就要下载到目标机上，并且在宿主机上也要保留一份。

5. 在目标机上运行 `gdbserver` 服务

        $ gdbserver 127.0.0.1:2345 test
        Process test created; pid = 12655
        Listening on port 2345


6. 在宿主机上发起连接和调试

        $ gdb test
        GNU gdb 6.4-debian
        Copyright 2005 Free Software Foundation, Inc.
        GDB is free software, covered by the GNU General Public License, and you are
        welcome to change it and/or distribute copies of it under certain conditions.
        Type "show copying" to see the conditions.
        There is absolutely no warranty for GDB.  Type "show warranty" for details.
        This GDB was configured as "i486-linux-gnu"...Using host libthread_db library "/lib/tls/i686/cmov/libthread_db.so.1".

        (gdb) target remote 127.0.0.1:2345
        Remote debugging using 127.0.0.1:2345
        0xb7f4d790 in ?? ()


    这时可以看到目标机那边出现了下面的信息：

        Remote debugging from host 127.0.0.1


    说明连接成功，下面就可以在宿主机上进行调试。这个调试和平时在桌面系统进行 `gdb` 调试是一样的。 比如列出源代码信息：

        (gdb) l
        1       /* test.c */
        2       #include <stdio.h>
        3
        4       int main()
        5       {
        6               int i;
        7
        8               i = 10;
        9
        10              printf("i = %d\n", i);


## <span id="_gdbkgdb_Linux">用 <code>gdb/kgdb</code> 调试 Linux 内核</span>

调试内核时也可以使用远程调试，只不过，远程调试服务程序被实现在内核里头，即 `kGDB`。

使用时，需要事先配置 `kGDB` 支持，并在启动内核时传入参数让开发板开机即加载 kGDB 调试服务，之后调试过程就跟调试应用类似。

具体细节这里不详述，可以直接参考本站早期的另外一篇文章：[《用kGDB调试Linux内核》][2]。





 [1]: http://tinylab.org
 [2]: /kgdb-debugging-kernel/
