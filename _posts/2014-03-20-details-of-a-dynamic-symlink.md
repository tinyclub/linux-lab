---
title: 动态符号链接的细节
author: Wu Zhangjin
album: C 语言编程透视
layout: post
permalink: /details-of-a-dynamic-symlink/
tags:
  - C语言
  - 重定位表
  - 过程链接表
  - 全局偏移表
  - 动态符号链接
categories:
  - C
  - X86
---

> by falcon of [TinyLab.org][2]
> 2008-2-26

**【注】这是开源书籍[《C 语言编程透视》][3]第四章，如果您喜欢该书，请关注我们的新浪微博[@泰晓科技][4]。**

## 前言

Linux支持动态链接库，不仅节省了磁盘、内存空间，而且[可以提高程序运行效率][5]。不过引入动态链接库也可能会带来很多问题，例如[动态链接库的调试][6]、[升级更新][7]和潜在的安全威胁[1][8], [2][9]。这里主要讨论符号的动态链接过程，即程序在执行过程中，对其中包含的一些未确定地址的符号进行重定位的过程[1][10], [2][11]。

本篇主要参考资料[3][10]和[8][11]，前者侧重实践，后者侧重原理，把两者结合起来就方便理解程序的动态链接过程了。另外，动态链接库的创建、使用以及调用动态链接库的部分参考了资料[1][5], [2][12]。

下面先来看看几个基本概念，接着就介绍动态链接库的创建、隐式和显示调用，最后介绍符号的动态链接细节。

## 基本概念

### ELF

ELF是Linux支持的一种程序文件格式，本身包含重定位、执行、共享（动态链接库）三种类型(`man elf`)。

代码：

    /* test.c */
    #include <stdio.h>    

    int global = 0;

    int main()
    {
            char local = &#39;A&#39;;

            printf("local = %c, global = %dn", local, global);

            return 0;
    }


演示：

通过-c生成可重定位文件test.o，这里不会进行链接：

    $ gcc -c test.c
    $ file test.o
    test.o: ELF 32-bit LSB relocatable, Intel 80386, version 1 (SYSV), not stripped


链接后才可以执行：

    $ gcc -o test test.o
    $ file test
    test: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically linked (uses shared libs), not stripped


也可链接成动态链接库，不过一般不会把main函数链接成动态链接库，后面再介绍：

    $ gcc -fpic -shared -W1,-soname,libtest.so.0 -o libtest.so.0.0 test.o
    $ file libtest.so.0.0
    libtest.so.0.0: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), not stripped


虽然ELF文件本身就支持三种不同的类型，不过它有一个统一的结构。这个结构是：

    文件头部(ELF Header)
    程序头部表(Program Header Table)
    节区1(Section1)
    节区2(Section2)
    节区3(Section3)
    ...
    节区头部表(Section Header Table)


无论是文件头部、程序头部表、节区头部表，还是节区，它们都对应着C语言里头的一些结构体（elf.h中定义）。文件头部主要描述ELF文件的类型，大小，运行平台，以及和程序头部表和节区头部表相关的信息。节区头部表则用于可重定位文件，以便描述各个节区的信息，这些信息包括节区的名字、类型、大小等。程序头部表则用于描述可执行文件或者动态链接库，以便系统加载和执行它们。而节区主要存放各种特定类型的信息，比如程序的正文区（代码）、数据区（初始化和未初始化的数据）、调试信息、以及用于动态链接的一些节区，比如解释器(`.interp`）节区将指定程序动态装载/链接器`ld-linux.so`的位置，而过程链接表(plt)、全局偏移表(got)、重定位表则用于辅助动态链接过程。

### 符号

对于可执行文件除了编译器引入的一些符号外，主要就是用户自定义的全局变量，函数等，而对于可重定位文件仅仅包含用户自定义的一些符号。

  * 生成可重定位文件

    $ gcc -c test.c $ nm test.o 00000000 B global 00000000 T main U printf

上面包含全局变量、自定义函数以及动态链接库中的函数，但不包含局部变量，而且发现这三个符号的地址都没有确定。

注：nm命令可用来查看ELF文件的符号表信息。

  * 生成可执行文件

    $ gcc -o test test.o $ nm test | egrep &#8220;main$| printf|global$&#8221; 080495a0 B global 08048354 T main U printf@@GLIBC_2.0

经链接，global和main的地址都已经确定了，但是printf却还没，因为它是动态链接库glibc中定义函数，需要动态链接，而不是这里的“静态”链接。

### <span id="i-5">重定位：<a href="http://162.105.203.48/web/gaikuang/submission/TN05.ELF.Format.Summary.pdf">是将符号引用与符号定义进行链接的过程</a></span>

从上面的演示可以看出，重定位文件`test.o`中的符号地址都是没有确定的，而经过“静态&#8221;链接(`gcc`默认调用`ld`进行链接)以后有两个符号地址已经确定了，这样一个确定符号地址的过程实际上就是链接的实质。链接过后，对符号的引用变成了对地址（定义符号时确定该地址）的引用，这样程序运行时就可通过访问内存地址而访问特定的数据。

我们也注意到符号printf在可重定位文件和可执行文件中的地址都没有确定，这意味着该符号是一个外部符号，可能定义在动态链接库中，在程序运行时需要通过动态链接器(`ld-linux.so`)进行重定位，即动态链接。

通过这个演示可以看出printf确实在glibc中有定义。

    $ nm -D /lib/`uname -m`-linux-gnu/libc.so.6 | grep " printf$"
    0000000000053840 T printf


除了`nm`以外，还可以用`readelf -s`查看`.dynsym`表或者用`objdump -tT`查看。

需要提到的是，用`nm`命令不带`-D`参数的话，在较新的系统上已经没有办法查看libc.so的符号表了，因为nm默认打印常规符号表（在`.symtab`和`.strtab`节区中），但是，在打包时为了减少系统大小，这些符号已经被strip掉了，只保留了动态符号（在`.dynsym`和`.dynstr`中）以便动态链接器在执行程序时寻址这些外部用到的符号。而常规符号除了动态符号以外，还包含有一些静态符号，比如说本地函数，这个信息主要是调试器会用，对于正常部署的系统，一般会用strip工具删除掉。

关于`nm`与`readelf -s`的详细比较，可参考：[nm vs “readelf -s”][13]。

### 动态链接

动态链接就是在程序运行时对符号进行重定位，确定符号对应的内存地址的过程。

Linux下符号的动态链接默认采用[Lazy Mode方式][10]，也就是说在程序运行过程中用到该符号时才去解析它的地址。这样一种符号解析方式有一个好处：只解析那些用到的符号，而对那些不用的符号则永远不用解析，从而提高程序的执行效率。

不过这种默认是可以通过设置`LD_BIND_NOW`为非空来打破的(下面会通过实例来分析这个变量的作用)，也就是说如果设置了这个变量，动态链接器将在程序加载后和符号被使用之前就对这些符号的地址进行解析。

### 动态链接库

上面提到重定位的过程就是对符号引用和符号地址进行链接的过程，而动态链接过程涉及到的符号引用和符号定义分别对应可执行文件和动态链接库，在可执行文件中可能引用了某些动态链接库中定义的符号，这类符号通常是函数。

为了让动态链接器能够进行符号的重定位，必须把动态链接库的相关信息写入到可执行文件当中，这些信息是什么呢？

    $ readelf -d test | grep NEEDED
     0x00000001 (NEEDED)                     Shared library: [libc.so.6]


ELF文件有一个特别的节区：`.dynamic`，它存放了和动态链接相关的很多信息，例如动态链接器通过它找到该文件使用的动态链接库。不过，该信息并未包含动态链接库`libc.so.6`的绝对路径，那动态链接器去哪里查找相应的库呢？

通过`LD_LIBRARY_PATH`参数，它类似shell解释器中用于查找可执行文件的PATH环境变量，也是通过冒号分开指定了各个存放库函数的路径。该变量实际上也可以通过/etc/ld.so.conf文件来指定，一行对应一个路径名。为了提高查找和加载动态链接库的效率，系统启动后会通过`ldconfig`工具创建一个库的缓存/etc/ld.so.cache。如果用户通过/etc/ld.so.conf加入了新的库搜索路径或者是把新库加到某个原有的库目录下，最好是执行一下`ldconfig`以便刷新缓存。

需要补充的是，因为动态链接库本身还可能引用其他的库，那么一个可执行文件的动态符号链接过程可能涉及到多个库，通过`readelf -d`可以打印出该文件直接依赖的库，而通过`ldd`命令则可以打印出所有依赖或者间接依赖的库。

    $ ldd test
            linux-gate.so.1 =>  (0xffffe000)
            libc.so.6 => /lib/libc.so.6 (0xb7da2000)
            /lib/ld-linux.so.2 (0xb7efc000)


`libc.so.6`通过`readelf -d`就可以看到的，是直接依赖的库；而`linux-gate.so.1`在文件系统中并没有对应的库文件，它是一个虚拟的动态链接库，对应进程内存映像的内核部分，更多细节请参考资料[11][14];而`/lib/ld-linux.so.2`正好是动态链接器，系统需要用它来进行符号重定位。那`ldd`是怎么知道/lib/ld-linux.so就是该文件的动态链接器呢？

那是因为ELF文件通过专门的节区指定了动态链接器，这个节区就是`.interp`。

    $ readelf -x .interp test

    Hex dump of section &#39;.interp&#39;:
      0x08048114 2f6c6962 2f6c642d 6c696e75 782e736f /lib/ld-linux.so
      0x08048124 2e3200                              .2.


可以看到这个节区刚好有字符串`/lib/ld-linux.so.2`，即`ld-linux.so`的绝对路径。

我们发现，与`libc.so`不同的是，`ld-linux.so`的路径是绝对路径，而`libc.so`仅仅包含了文件名。原因是：程序被执行时，`ld-linux.so`将最先被装载到内存中，没有其他程序知道去哪里查找`ld-linux.so`，所以它的路径必须是绝对的；当`ld-linux.so`被装载以后，由它来去装载可执行文件和相关的共享库，它将根据`PATH`变量和`LD_LIBRARY_PATH`变量去磁盘上查找它们，因此可执行文件和共享库都可以不指定绝对路径。

下面着重介绍动态链接器本身。

### 动态链接器(dynamic linker/loader)

Linux下elf文件的动态链接器是`ld-linux.so`，即`/lib/ld-linux.so.2`。从名字来看和静态链接器`ld`（`gcc`默认使用的链接器，见参考资料[10][15]）类似。通过`man ld-linux`可以获取与动态链接器相关的资料，包括各种相关的环境变量和文件都有详细的说明。

对于环境变量，除了上面提到过的`LD_LIBRARY_PATH`和`LD_BIND_NOW`变量外，还有其他几个重要参数，比如`LD_PRELOAD`用于指定预装载一些库，以便替换其他库中的函数，从而做一些安全方面的处理[6][8], [9][16], [12][17]，而环境变量`LD_DEBUG`可以用来进行动态链接的相关调试。

对于文件，除了上面提到的ld.so.conf和ld.so.cache外，还有一个文件/etc/ld.so.preload用于指定需要预装载的库。

从上一小节中发现有一个专门的节区`.interp`存放有动态链接器，但是这个节区为什么叫做`.interp(interpeter)`呢？因为当shell解释器或者其他父进程通过exec启动我们的程序时，系统会先为`ld-linux`创建内存映像，然后把控制权交给`ld-linux`，之后`ld-linux`负责为可执行程序提供运行环境，负责解释程序的运行，因此`ld-linux`也叫做`dynamic loader`（或intepreter）（关于程序的加载过程请参考资料[13][18]）

那么在exec()之后和程序指令运行之前的过程是怎样的呢？`ld-linux.so`主要为程序本身创建了内存映像(以下内容摘自资料[8][11])，大体过程如下：

  * 将可执行文件的内存段添加到进程映像中；
  * 把共享目标内存段添加到进程映像中；
  * 为可执行文件和它的共享目标(动态链接库)执行重定位操作；
  * 关闭用来读入可执行文件的文件描述符，如果动态链接程序收到过这样的文件描述符的话；
  * 将控制转交给程序，使得程序好像从exec()直接得到控制

关于第1步，在ELF文件的文件头中就指定了该文件的入口地址，程序的代码和数据部分会相继map到对应的内存中。而关于可执行文件本身的路径，如果指定了PATH环境变量，`ld-linux`会到PATH指定的相关目录下查找。

    $ readelf -h test | grep Entry
      Entry point address:               0x80482b0


对于第2步，上一节提到的`.dynamic`节区指定了可执行文件依赖的库名，`ld-linux`（在这里叫做动态装载器或程序解释器比较合适）再从`LD_LIBRARY_PATH`指定的路径中找到相关的库文件或者直接从/etc/ld.so.cache库缓冲中加载相关库到内存中。（关于进程的内存映像，推荐参考资料[14][19]）

对于第3步，在前面已提到，如果设置了`LD_BIND_NOW`环境变量，这个动作就会在此时发生，否则将会采用lazy mode方式，即当某个符号被使用时才会进行符号的重定位。不过无论在什么时候发生这个动作，重定位的过程大体是一样的（在后面将主要介绍该过程）。

对于第4步，这个主要是释放文件描述符。

对于第5步，动态链接器把程序控制权交还给程序。

现在关心的主要是第3步，即如何进行符号的重定位？下面来探求这个过程。期间会逐步讨论到和动态链接密切相关的三个数据结构，它们分别是ELF文件的过程链接表、全局偏移表和重定位表，这三个表都是ELF文件的节区。

### 过程链接表(plt)

从上面的演示发现，还有一个printf符号的地址没有确定，它应该在动态链接库`libc.so`中定义，需要进行动态链接。这里假设采用lazy mode方式，即执行到printf所在位置时才去解析该符号的地址。

假设当前已经执行到了printf所在位置，即`call printf`，我们通过`objdump`反编译test程序的正文段看看。

    $ objdump -d -s -j .text test | grep printf
     804837c:       e8 1f ff ff ff          call   80482a0 <printf@plt>


发现，该地址指向了plt（即过程链接表）即地址80482a0处。下面查看该地址处的内容。

    $ objdump -D test | grep "80482a0" | grep -v call
    080482a0 <printf@plt>:
     80482a0:       ff 25 8c 95 04 08       jmp    *0x804958c


发现80482a0地址对应的是一条跳转指令，跳转到0x804958c地址指向的地址。到底0x804958c地址本身在什么地方呢？我们能否从`.dynamic`节区(该节区存放了和动态链接相关的数据)获取相关的信息呢？

    $ readelf -d test

    Dynamic section at offset 0x4ac contains 20 entries:
      Tag        Type                         Name/Value
     0x00000001 (NEEDED)                     Shared library: [libc.so.6]
     0x0000000c (INIT)                       0x8048258
     0x0000000d (FINI)                       0x8048454
     0x00000004 (HASH)                       0x8048148
     0x00000005 (STRTAB)                     0x80481c0
     0x00000006 (SYMTAB)                     0x8048170
     0x0000000a (STRSZ)                      76 (bytes)
     0x0000000b (SYMENT)                     16 (bytes)
     0x00000015 (DEBUG)                      0x0
     0x00000003 (PLTGOT)                     0x8049578
     0x00000002 (PLTRELSZ)                   24 (bytes)
     0x00000014 (PLTREL)                     REL
     0x00000017 (JMPREL)                     0x8048240
     0x00000011 (REL)                        0x8048238
     0x00000012 (RELSZ)                      8 (bytes)
     0x00000013 (RELENT)                     8 (bytes)
     0x6ffffffe (VERNEED)                    0x8048218
     0x6fffffff (VERNEEDNUM)                 1
     0x6ffffff0 (VERSYM)                     0x804820c
     0x00000000 (NULL)                       0x0


发现0&#215;8049578地址和0x804958c地址比较近，通过资料[8][11]查到前者正好是`.got.plt`(即过程链接表)对应的全局偏移表的入口地址。难道0x804958c正好位于`.got.plt`节区中？

### 全局偏移表(got)

现在进入全局偏移表看看，

    $ readelf -x .got.plt test

    Hex dump of section &#39;.got.plt&#39;:
      0x08049578 ac940408 00000000 00000000 86820408 ................
      0x08049588 96820408 a6820408                   ........


从上述结果可以看出0x804958c地址(即0&#215;08049588+4)处存放的是a6820408，考虑到我的实验平台是i386，字节顺序是little-endian的，所以实际数值应该是080482a6，也就是说`*(0x804958c)`的值是080482a6，这个地址刚好是过程链接表的最后一项`call 80482a0<printf@plt>`中80482a0地址往后偏移6个字节，容易猜到该地址应该就是`jmp`指令的后一条地址。

    $ objdump -d -d -s -j .plt test |  grep "080482a0 <printf@plt>:" -A 3
    080482a0 <printf@plt>:
     80482a0:       ff 25 8c 95 04 08       jmp    *0x804958c
     80482a6:       68 10 00 00 00          push   $0x10
     80482ab:       e9 c0 ff ff ff          jmp    8048270 <_init+0x18>


80482a6地址恰巧是一条`push`指令，随后是一条`jmp`指令（暂且不管push指令入栈的内容有什么意义），执行完push指令之后，就会跳转到8048270地址处，下面看看8048270地址处到底有哪些指令。

    $ objdump -d -d -s -j .plt test | grep -v "jmp    8048270 <_init+0x18>" | grep "08048270" -A 2
    08048270 <__gmon_start__@plt-0x10>:
     8048270:       ff 35 7c 95 04 08       pushl  0x804957c
     8048276:       ff 25 80 95 04 08       jmp    *0x8049580


同样是一条入栈指令跟着一条跳转指令。不过这两个地址0x804957c和0&#215;8049580是连续的，而且都很熟悉，刚好都在`.got.plt`表里头（从上面我们已经知道`.got.plt`的入口是0&#215;08049578）。这样的话，我们得确认这两个地址到底有什么内容。

    $ readelf -x .got.plt test

    Hex dump of section &#39;.got.plt&#39;:
      0x08049578 ac940408 00000000 00000000 86820408 ................
      0x08049588 96820408 a6820408                   ........


不过，遗憾的是通过`readelf`查看到的这两个地址信息都是0，它们到底是什么呢？

现在只能求助参考资料[8][11]，该资料的“3.8.5 过程链接表”部分在介绍过程链接表和全局偏移表相互合作解析符号的过程中的三步涉及到了这两个地址和前面没有说明的`push $0x10`指令。

  * 在程序第一次创建内存映像时，动态链接器为全局偏移表的第二(0x804957c)和第三项(0&#215;8049580)设置特殊值。
  * 原步骤5。在跳转到`08048270 <__gmon_start__@plt-0x10>`，即过程链接表的第一项之前，有一条压入栈指令，即`push $0x10`，0&#215;10是相对于重定位表起始地址的一个偏移地址，这个偏移地址到底有什么用呢？它应该是提供给动态链接器的什么信息吧？后面再说明。
  * 原步骤6。跳转到过程链接表的第一项之后，压入了全局偏移表中的第二项（即0x804957c处），“为动态链接器提供了识别信息的机会”(具体是什么呢？后面会简单提到，但这个并不是很重要)，然后跳转到全局偏移表的第三项（0&#215;8049580，这一项比较重要），把控制权交给动态链接器。

从这三步发现程序运行时地址0&#215;8049580处存放的应该是动态链接器的入口地址，而重定位表0&#215;10位置处和0x804957c处应该为动态链接器提供了解析符号需要的某些信息。

在继续之前先总结一下过程链接表和全局偏移表。上面的操作过程仅仅从“局部”看过了这两个表，但是并没有宏观地看里头的内容。下面将宏观的分析一下， 对于过程链接表：

    $ objdump -d -d -s -j .plt test
    08048270 <__gmon_start__@plt-0x10>:
     8048270:       ff 35 7c 95 04 08       pushl  0x804957c
     8048276:       ff 25 80 95 04 08       jmp    *0x8049580
     804827c:       00 00                   add    %al,(%eax)
            ...

    08048280 <__gmon_start__@plt>:
     8048280:       ff 25 84 95 04 08       jmp    *0x8049584
     8048286:       68 00 00 00 00          push   $0x0
     804828b:       e9 e0 ff ff ff          jmp    8048270 <_init+0x18>

    08048290 <__libc_start_main@plt>:
     8048290:       ff 25 88 95 04 08       jmp    *0x8049588
     8048296:       68 08 00 00 00          push   $0x8
     804829b:       e9 d0 ff ff ff          jmp    8048270 <_init+0x18>

    080482a0 <printf@plt>:
     80482a0:       ff 25 8c 95 04 08       jmp    *0x804958c
     80482a6:       68 10 00 00 00          push   $0x10
     80482ab:       e9 c0 ff ff ff          jmp    8048270 <_init+0x18>


除了该表中的第一项外，其他各项实际上是类似的。而最后一项`080482a0 <printf@plt>`和第一项我们都分析过，因此不难理解其他几项的作用。过程链接表没有办法单独工作，因为它和全局偏移表是关联的，所以在说明它的作用之前，先从总体上来看一下全局偏移表。

    $ readelf -x .got.plt test

    Hex dump of section &#39;.got.plt&#39;:
      0x08049578 ac940408 00000000 00000000 86820408 ................
      0x08049588 96820408 a6820408                   ........


比较全局偏移表中0&#215;08049584处开始的数据和过程链接表第二项开始的连续三项中`push`指定所在的地址，不难发现，它们是对应的。而0x0804958c即`push 0x10`对应的地址我们刚才提到过（下一节会进一步分析），其他几项的作用类似，都是跳回到过程链接表的push指令处，随后就跳转到过程链接表的第一项，以便解析相应的符号（实际上过程链接表的第一个表项是进入动态链接器，而之前的连续两个指令则传送了需要解析的符号等信息）。另外0&#215;08049578和0&#215;08049580处分别存放有传递给动态链接库的相关信息和动态链接器本身的入口地址。但是还有一个地址0&#215;08049578，这个地址刚好是`.dynamic`的入口地址，该节区存放了和动态链接过程相关的信息，资料[8][11]提到这个表项实际上保留给动态链接器自己使用的，以便在不依赖其他程序的情况下对自己进行初始化，所以下面将不再关注该表项。

    $ objdump -D test | grep 080494ac
    080494ac <_DYNAMIC>:


### 重定位表

这里主要接着上面的`push 0x10`指令来分析。通过资料[8][11]发现重定位表包含如何修改其他节区的信息，以便动态链接器对某些节区内的符号地址进行重定位（修改为新的地址）。那到底重定位表项提供了什么样的信息呢？

  * 每一个重定位项有三部分内容，我们重点关注前两部分。
  * 第一部分是`r_offset`，这里考虑的是可执行文件，因此根据资料发现，它的取值是被重定位影响（可以说改变或修改）到的存储单元的虚拟地址。
  * 第二部分是`r_info`，此成员给出要进行重定位的符号表索引（重定位表项引用到的符号表），以及将实施的重定位类型（如何进行符号的重定位）。(Type)。

先来看看重定位表的具体内容，

    $ readelf -r test

    Relocation section &#39;.rel.dyn&#39; at offset 0x238 contains 1 entries:
     Offset     Info    Type            Sym.Value  Sym. Name
    08049574  00000106 R_386_GLOB_DAT    00000000   __gmon_start__

    Relocation section &#39;.rel.plt&#39; at offset 0x240 contains 3 entries:
     Offset     Info    Type            Sym.Value  Sym. Name
    08049584  00000107 R_386_JUMP_SLOT   00000000   __gmon_start__
    08049588  00000207 R_386_JUMP_SLOT   00000000   __libc_start_main
    0804958c  00000407 R_386_JUMP_SLOT   00000000   printf


仅仅关注和过程链接表相关的`.rel.plt`部分，`0x10`刚好是`1*16+0*1`，即16字节，作为重定位表的偏移，刚好对应该表的第三行。发现这个结果中竟然包含了和printf符号相关的各种信息。不过重定位表中没有直接指定符号printf，而是根据`r_info`部分从动态符号表中计算出来的，注意观察上述结果中的Info一列的1,2,4和下面结果的Num列的对应关系。

    $ readelf -s test | grep ".dynsym" -A 6
    Symbol table &#39;.dynsym&#39; contains 5 entries:
       Num:    Value  Size Type    Bind   Vis      Ndx Name
         0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND
         1: 00000000     0 NOTYPE  WEAK   DEFAULT  UND __gmon_start__
         2: 00000000   410 FUNC    GLOBAL DEFAULT  UND __libc_start_main@GLIBC_2.0 (2)
         3: 08048474     4 OBJECT  GLOBAL DEFAULT   14 _IO_stdin_used
         4: 00000000    57 FUNC    GLOBAL DEFAULT  UND printf@GLIBC_2.0 (2)


也就是说在执行过程链接表中的第一项的跳转指令(`jmp    *0x8049580`)调用动态链接器以后，动态链接器因为有了`push 0x10`，从而可以通过该重定位表项中的`r_info`找到对应符号(printf)在符号表(`.dynsym`)中的相关信息。

除此之外，符号表中还有`Offset(r_offset)`以及`Type`这两个重要信息，前者表示该重定位操作后可能影响的地址0804958c，这个地址刚好是got表项的最后一项，原来存放的是`push 0x10`指令的地址。这意味着，该地址处的内容将被修改，而如何修改呢？根据`Type`类型`R_386_JUMP_SLOT`，通过资料[8][11]查找到该类型对应的说明如下（原资料有误，下面做了修改）：链接编辑器创建这种重定位类型主要是为了支持动态链接。其偏移地址成员给出过程链接表项的位置。动态链接器修改全局偏移表项的内容，把控制传输给指定符号的地址。

这说明，动态链接器将根据该类型对全局偏移表中的最有一项，即0804958c地址处的内容进行修改，修改为符号的实际地址，即printf函数在动态链接库的内存映像中的地址。

到这里，动态链接的宏观过程似乎已经了然于心，不过一些细节还是不太清楚。

下面先介绍动态链接库的创建，隐式调用和显示调用，接着进一步澄清上面还不太清楚的细节，即全局偏移表中第二项到底传递给了动态链接器什么信息？第三项是否就是动态链接器的地址？并讨论通过设置`LD_BIND_NOW`而不采用默认的lazy mode进行动态链接和采用lazy mode动态链接的区别？

## 动态链接库的创建和调用

在介绍动态符号链接的更多细节之前，先来了解一下动态链接库的创建和两种使用方法，进而引出符号解析的后台细节。

### 创建动态链接库

首先来创建一个简单动态链接库。

代码：

    /* myprintf.c */
    #include <stdio.h>

    int myprintf(char *str)
    {
            printf("%sn", str);
            return 0;
    }

    /* myprintf.h */
    #ifndef _MYPRINTF_H
    #define _MYPRINTF_H

    int myprintf(char *);

    #endif


演示：

    $ gcc -c myprintf.c
    $ gcc -shared -W1,-soname,libmyprintf.so.0 -o libmyprintf.so.0.0 myprintf.o
    $ ln -sf libmyprintf.so.0.0 libmyprintf.so.0
    $ ln -fs libmyprintf.so.0 libmyprintf.so
    $ ls
    libmyprintf.so  libmyprintf.so.0  libmyprintf.so.0.0  myprintf.c  myprintf.h  myprintf.o


得到三个文件libmyprintf.so，libmyprintf.so.0，libmyprintf.so.0.0，这些库暂且存放在当前目录下。这里有一个问题值得关注，那就是为什么要创建两个符号链接呢？答案是为了在不影响兼容性的前提下升级库[5][7]。

### 隐式使用该库

现在写一段代码来使用该库，调用其中的myprintf函数，这里是隐式使用该库：在代码中并没有直接使用该库，而是通过调用myprintf隐式地使用了该库，在编译引用该库的可执行文件时需要通过`-l`参数指定该库的名字。

    /* test.c */
    #include <stdio.h>   
    #include <myprintf.h>

    int main()
    {
            myprintf("Hello World");

            return 0;
    }


编译：

    $ gcc -o test test.c -lmyprintf -L./ -I./


直接运行test，提示找不到该库，因为库的默认搜索路径里头没有包含当前目录：

    $ ./test
    ./test: error while loading shared libraries: libmyprintf.so: cannot open shared object file: No such file or directory


如果指定库的搜索路径，则可以运行：

    $ LD_LIBRARY_PATH=$PWD ./test
    Hello World


### 显式使用库

`LD_LIBRARY_PATH`环境变量使得库可以放到某些指定的路径下面，而无须在调用程序中显式的指定该库的绝对路径，这样避免了把程序限制在某些绝对路径下，方便库的移动。 虽然显式调用有不便，但是能够避免隐式调用搜索路径的时间消耗，提高效率，除此之外，显式调用为我们提供了一组函数调用，让符号的重定位过程一览无遗。

    /* test1.c */

    #include <dlfcn.h>      /* dlopen, dlsym, dlerror */
    #include <stdlib.h>     /* exit */
    #include <stdio.h>      /* printf */

    #define LIB_SO_NAME     "./libmyprintf.so"
    #define FUNC_NAME "myprintf"

    typedef int (*func)(char *);

    int main(void)
    {
            void *h;
            char *e;
            func f;

            h = dlopen(LIB_SO_NAME, RTLD_LAZY);
            if ( !h ) {
                    printf("failed load libary: %sn", LIB_SO_NAME);
                    exit(-1);
            }
            f = dlsym(h, FUNC_NAME);
            e = dlerror();
            if (e != NULL) {
                    printf("search %s error: %sn", FUNC_NAME, LIB_SO_NAME);
                    exit(-1);
            }
            f("Hello World");

            exit(0);
    }


演示：

    $ gcc -o test1 test1.c -ldl


这种情况下，无须包含头文件。从这个代码中很容易看出符号重定位的过程:

  * 首先通过`dlopen`找到依赖库，并加载到内存中，再返回该库的handle，通过`dlopen`我们可以指定`RTLD_LAZY`采用lazy mode动态链接模式，如果采用`RTLD_NOW`则和隐式调用时设置`LD_BIN_NOW`类似。
  * 找到该库以后就是对某个符号进行重定位，这里是确定myprintf函数的地址。
  * 找到函数地址以后就可以直接调用该函数了。

关于`dlopen`,`dlsym`等后台工作细节建议参考资料[15][20]。

隐式调用的动态符号链接过程和上面类似。下面通过一些实例来确定之前没有明确的两个内容：即全局偏移表中的第二项和第三项，并进一步讨论lazy mode和非lazy mode的区别。

## 动态链接过程

因为通过ELF文件，我们就可以确定全局偏移表的位置，因此为了确定全局偏移表位置的第三项和第四项的内容，有两种办法：

  * 通过gdb调试。
  * 直接在函数内部打印。

因为资料[3][10]详细介绍了第一种方法，这里试着通过第二种方法来确定这两个地址的值。

    /**
     * got.c -- get the relative content of the got(global offset table) of an elf file
     */

    #include <stdio.h>

    #define GOT 0x8049614

    int main(int argc, char *argv[])
    {
            long got2, got3;
            long old_addr, new_addr;

            got2=*(long *)(GOT+4);
            got3=*(long *)(GOT+8);
            old_addr=*(long *)(GOT+24);

            printf("Hello Worldn");

            new_addr=*(long *)(GOT+24);

            printf("got2: 0x%0x, got3: 0x%0x, old_addr: 0x%0x, new_addr: 0x%0xn",
                                            got2, got3, old_addr, new_addr);

            return 0;
    }


在写好上面的代码后就需要确定全局偏移表的地址，然后把该地址设置为代码中的宏GOT。

    $ make got
    $ readelf -d got | grep PLTGOT
     0x00000003 (PLTGOT)                     0x8049614


注：这里假设大家用的都是i386的系统，如果要在X86_64位系统上要编译生成i386上的可执行文件，需要给gcc传递一个`-m32`参数，例如：

    $ gcc -m32 -o got got.c


把地址0&#215;8049614替换到上述代码中，然后重新编译运行，查看结果。

    $ make got
    $ Hello World
    got2: 0xb7f376d8, got3: 0xb7f2ef10, old_addr: 0x80482da, new_addr: 0xb7e19a20
    $ ./got
    Hello World
    got2: 0xb7f1e6d8, got3: 0xb7f15f10, old_addr: 0x80482da, new_addr: 0xb7e00a20


通过两次运行，发现全局偏移表中的这两项是变化的，并且printf的地址对应的new_addr也是变化的，说明`libc`和`ld-linux`这两个库启动以后对应的虚拟地址并不确定。因此，无法直接跟踪到那个地址处的内容，还得借助调试工具，以便确认它们。

下面重新编译got，加上`-g`参数以便调试，并通过调试确认got2，got3，以及调用printf前后printf地址的重定位情况。

    $ gcc -g -o got got.c
    $ gdb ./got
    (gdb) l
    5       #include <stdio.h>
    6
    7       #define GOT 0x8049614
    8
    9       int main(int argc, char *argv[])
    10      {
    11              long got2, got3;
    12              long old_addr, new_addr;
    13
    14              got2=*(long *)(GOT+4);
    (gdb) l
    15              got3=*(long *)(GOT+8);
    16              old_addr=*(long *)(GOT+24);
    17
    18              printf("Hello Worldn");
    19
    20              new_addr=*(long *)(GOT+24);
    21
    22              printf("got2: 0x%0x, got3: 0x%0x, old_addr: 0x%0x, new_addr: 0x%0xn",
    23                                              got2, got3, old_addr, new_addr);
    24


在第一个printf处设置一个断点：

    (gdb) break 18
    Breakpoint 1 at 0x80483c3: file got.c, line 18.


在第二个printf处设置一个断点：

    (gdb) break 22
    Breakpoint 2 at 0x80483dd: file got.c, line 22.


运行到第一个printf之前会停止：

    (gdb) r
    Starting program: /mnt/hda8/Temp/c/program/got

    Breakpoint 1, main () at got.c:18
    18              printf("Hello Worldn");


查看执行printf之前的全局偏移表内容：

    (gdb) x/8x 0x8049614
    0x8049614 <_GLOBAL_OFFSET_TABLE_>:      0x08049548      0xb7f3c6d8      0xb7f33f10      0x080482aa
    0x8049624 <_GLOBAL_OFFSET_TABLE_+16>:   0xb7ddbd20      0x080482ca      0x080482da      0x00000000


查看GOT表项的最有一项，发现刚好是PLT表中push指令的地址：

    (gdb) disassemble 0x080482da
    Dump of assembler code for function puts@plt:
    0x080482d4 <puts@plt+0>:        jmp    *0x804962c
    0x080482da <puts@plt+6>:        push   $0x18
    0x080482df <puts@plt+11>:       jmp    0x8048294 <_init+24>


说明此时还没有进行进行符号的重定位，不过发现并非printf，而是puts(1)。

接着查看GOT第三项的内容，刚好是dl-linux对应的代码：

    (gdb) disassemble 0xb7f33f10
    Dump of assembler code for function _dl_runtime_resolve:
    0xb7f33f10 <_dl_runtime_resolve+0>:     push   %eax
    0xb7f33f11 <_dl_runtime_resolve+1>:     push   %ecx
    0xb7f33f12 <_dl_runtime_resolve+2>:     push   %edx


可通过`nm /lib/ld-linux.so.2 | grep _dl_runtime_resolve`进行确认。

然后查看GOT表第二项处的内容，看不出什么特别的信息，反编译时提示无法反编译：

    (gdb) x/8x 0xb7f3c6d8
    0xb7f3c6d8:     0x00000000      0xb7f39c3d      0x08049548      0xb7f3c9b8
    0xb7f3c6e8:     0x00000000      0xb7f3c6d8      0x00000000      0xb7f3c9a4


在`*(0xb7f33f10)`指向的代码处设置一个断点，确认它是否被执行：

    (gdb) break *(0xb7f33f10)
    break *(0xb7f33f10)
    Breakpoint 3 at 0xb7f3cf10
    (gdb) c
    Continuing.

    Breakpoint 3, 0xb7f3cf10 in _dl_runtime_resolve () from /lib/ld-linux.so.2


继续运行，直到第二次调用printf：

    (gdb)  c
    Continuing.
    Hello World

    Breakpoint 2, main () at got.c:22
    22              printf("got2: 0x%0x, got3: 0x%0x, old_addr: 0x%0x, new_addr: 0x%0xn",


再次查看GOT表项，发现GOT表的最后一项的值应该被修改：

    (gdb) x/8x 0x8049614
    0x8049614 <_GLOBAL_OFFSET_TABLE_>:      0x08049548      0xb7f3c6d8      0xb7f33f10      0x080482aa
    0x8049624 <_GLOBAL_OFFSET_TABLE_+16>:   0xb7ddbd20      0x080482ca      0xb7e1ea20      0x00000000


查看GOT表最后一项，发现变成了puts函数的代码，说明进行了符号puts的重定位(2)：

    (gdb) disassemble 0xb7e1ea20
    Dump of assembler code for function puts:
    0xb7e1ea20 <puts+0>:    push   %ebp
    0xb7e1ea21 <puts+1>:    mov    %esp,%ebp
    0xb7e1ea23 <puts+3>:    sub    $0x1c,%esp


通过演示发现一个问题(1)(2)，即本来调用的是printf，为什么会进行puts的重定位呢？通过`gcc -S`参数编译生成汇编代码后发现，gcc把printf替换成了puts，因此不难理解程序运行过程为什么对puts进行了重定位。

从演示中不难发现，当符号被使用到时才进行重定位。因为通过调试发现在执行printf之后，GOT表项的最后一项才被修改为printf(确切的说是puts)的地址。这就是所谓的lazy mode动态符号链接方式。

除此之外，我们容易发现GOT表第三项确实是`ld-linux.so`中的某个函数地址，并且发现在执行printf语句之前，先进入了`ld-linux.so`的`_dl_runtime_resolve`函数，而且在它返回之后，GOT表的最后一项才变为printf(puts)的地址。

本来打算通过第一个断点确认第二次调用printf时不再需要进行动态符号链接的，不过因为gcc把第一个替换成了puts，所以这里没有办法继续调试。如果想确认这个，你可以通过写两个一样的printf语句看看。实际上第一次链接以后，GOT表的第三项已经修改了，当下次再进入过程链接表，并执行“`jmp *(全局偏移表中某一个地址)`”指令时，`*(全局偏移表中某一个地址)`已经被修改为了对应符号的实际地址，这样jmp语句会自动跳转到符号的地址处运行，执行具体的函数代码，因此无须再进行重定位。

到现在GOT表中只剩下第二项还没有被确认，通过资料[3][10]我们发现，该项指向一个link_map类型的数据，是一个鉴别信息，具体作用对我们来说并不是很重要，如果想了解，请参考资料[16][21]。

下面通过设置`LD_BIND_NOW`再运行一下got程序并查看结果，比较它与默认的动态链接方式(lazy mode)的异同。

* 设置LD\_BIND\_NOW环境变量的运行结果

      $ LD_BIND_NOW=1 ./got Hello World got2: 0×0, got3: 0×0, old_addr: 0xb7e61a20, new_addr: 0xb7e61a20

* 默认情况下的运行结果

      $ ./got Hello World got2: 0xb7f806d8, got3: 0xb7f77f10, old_addr: 0x80482da, new_addr: 0xb7e62a20

通过比较容易发现，在非lazy mode（设置`LD_BIND_NOW`后）下，程序运行之前符号的地址就已经被确定，即调用printf之前GOT表的最后一项已经被确定为了printf函数对应的地址，即0xb7e61a20，因此在程序运行之后，GOT表的第二项和第三项就保持为0，因为此时不再需要它们进行符号的重定位了。通过这样一个比较，就更容易理解lazy mode的特点了：在用到的时候才解析。

到这里，符号动态链接的细节基本上就已经清楚了。

## 参考资料

  * [LINUX系统中动态链接库的创建与使用][5]

  * [LINUX动态链接库高级应用][12]

  * [ELF动态解析符号过程(修订版)][10]

  * [如何在 Linux 下调试动态链接库][6]

  * [Dissecting shared libraries][7]

  * [关于Linux和Unix动态链接库的安全][8]

  * [Linux系统下解析Elf文件DT_RPATH后门][9]

  * [ELF 文件格式分析][11]

  * 缓冲区溢出与注入分析(第二部分：缓冲区溢出和注入实例)

  * GCC编译的背后(第二部分：汇编和链接)
  * What is Linux-gate.so.1: [1][16], [2][15], [3][14]

  * [Linux下缓冲区溢出攻击的原理及对策][17]

  * 程序执行的那一刹那

  * Intel平台下Linux中ELF文件动态链接的加载、解析及实例分析[part1][18], [part2][19]

  * [ELF file format and ABI][20]





 [2]: http://tinylab.org
 [3]: /open-c-book/
 [4]: http://weibo.com/tinylaborg
 [5]: http://www.ccw.com.cn/htm/app/linux/develop/01_8_6_2.asp
 [6]: http://unix-cd.com/unixcd12/article_5065.html
 [7]: http://www.ibm.com/developerworks/linux/library/l-shlibs.html
 [8]: http://fanqiang.chinaunix.net/safe/system/2007-02-01/4870.shtml
 [9]: http://article.pchome.net/content-323084.html
 [10]: http://elfhack.whitecell.org/mydocs/ELF_symbol_resolve_process1.txt
 [11]: http://162.105.203.48/web/gaikuang/submission/TN05.ELF.Format.Summary.pdf
 [12]: http://www.vchome.net/tech/dll/dll9.htm
 [13]: http://stackoverflow.com/questions/9961473/nm-vs-readelf-s
 [14]: http://www.linux010.cn/program/Linux-gateso1-DeHanYi-pcee6103.htm
 [15]: http://isomerica.net/archives/2007/05/28/what-is-linux-gateso1-and-why-is-it-missing-on-x86-64/
 [16]: http://www.trilithium.com/johan/2005/08/linux-gate/
 [17]: http://www.ibm.com/developerworks/cn/linux/l-overflow/index.html
 [18]: http://www.ibm.com/developerworks/cn/linux/l-elf/part1/index.html
 [19]: http://www.ibm.com/developerworks/cn/linux/l-elf/part2/index.html
 [20]: http://www.x86.org/ftp/manuals/tools/elf.pdf
 [21]: http://www.muppetlabs.com/~breadbox/software/ELF.txt
