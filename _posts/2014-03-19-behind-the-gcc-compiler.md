---
title: GCC 编译的背后
author: Wu Zhangjin
album: C 语言编程透视
layout: post
permalink: /behind-the-gcc-compiler/
tags:
  - as
  - cpp
  - 链接脚本
  - 预处理，链接，静态链接
  - ld
  - linker script
  - readelf
  - 动态链接
  - 汇编
categories:
  - C
  - Gcc
  - X86
---

> by falcon of [TinyLab.org][2]
> 2008-02-22

**【注】这是开源书籍[《C 语言编程透视》][3]第二章，如果您喜欢该书，请关注我们的新浪微博[@泰晓科技][4]。**

## 前言

平时在 Linux 下写代码，直接用 `gcc -o out in.c` 就把代码编译好了，但是这背后到底做了什么呢？如果学习过《编译原理》则不难理解，一般高级语言程序编译的过程莫过于：预处理、编译、汇编、链接。 `gcc` 在后台实际上也经历了这几个过程，可以通过 `-v` 参数查看它的编译细节，如果想看某个具体的编译过程，则可以分别使用 `-E` ， `-S` ， `-c` 和 `-O` ，对应的后台工具则分别为 `cpp` ， `cc1` ， `as` ， `ld` 。下面将逐步分析这几个过程以及相关的内容，诸如语法检查、代码调试、汇编语言等。

## 预处理

### 简述

预处理是 C 语言程序从源代码变成可执行程序的第一步，主要是 C 语言编译器对各种预处理命令进行处理，包括头文件的包含、宏定义的扩展、条件编译的选择等。

以前没怎么“深入”预处理，脑子对这些东西总是很模糊，只记得在编译的基本过程（词法分析、语法分析）之前还需要对源代码中的宏定义、文件包含、条件编译等命令进行处理。这三类的指令很常见，主要有 ` # define` ， ` # include` 和 ` # ifdef ...  # endif` ，要特别地注意它们的用法。

 ` # define` 除了可以独立使用以便灵活设置一些参数外，还常常和 ` # ifdef ...  # endif` 结合使用，以便灵活地控制代码块的编译与否，也可以用来避免同一个头文件的多次包含。关于 ` # include` 貌似比较简单，通过 `man` 找到某个函数的头文件，复制进去，加上 `<>` 就好。这里虽然只关心一些技巧，不过预处理还是隐藏着很多潜在的陷阱（可参考《 C Traps & Pitfalls 》）也是需要注意的。下面仅介绍和预处理相关的几个简单内容。

### 打印出预处理之后的结果

    $ gcc -E hello.c


这样就可以看到源代码中的各种预处理命令是如何被解释的，从而方便理解和查错。

实际上 `gcc` 在这里调用了 `cpp`( 虽然通过 gcc 的 `-v` 仅看到 `cc1`) ， cpp 即 The C Preprocessor ，主要用来预处理宏定义、文件包含、条件编译等。下面介绍它的一个比较重要的选项 `-D` 。

### 在命令行定义宏

    $ gcc -Dmacro hello.c


这个等同于在文件的开头定义宏，即 `# define macro` ，但是在命令行定义更灵活。例如，在源代码中有这些语句。

    #ifdef DEBUG
    printf("this code is for debuggingn");
    #endif


如果编译时加上 `-DDEBUG` 选项，那么编译器就会把 `printf` 所在的行编译进目标代码，从而方便地跟踪该位置的某些程序状态。这样 `-DDEBUG` 就可以当作一个调试开关，编译时加上它就可以用来打印调试信息，发布时则可以通过去掉该编译选项把调试信息去掉。

## 编译（翻译）

### 简述

编译之前， C 语言编译器会进行词法分析、语法分析，接着会把源代码翻译成中间语言，即汇编语言。如果想看到这个中间结果，可以用 `gcc -S` 。需要提到的是，诸如 Shell 等解释语言也会经历一个词法分析和语法分析的阶段，不过之后并不会进行“翻译”，而是“解释”，边解释边执行。

把源代码翻译成汇编语言，实际上是编译的整个过程中的第一个阶段，之后的阶段和汇编语言的开发过程没有什么区别。这个阶段涉及到对源代码的词法分析、语法检查（通过 `-std` 指定遵循哪个标准），并根据优化 (`-O`) 要求进行翻译成汇编语言的动作。

### 语法检查

如果仅仅希望进行语法检查，可以用 gcc 的 `-fsyntax-only` 选项；如果为了使代码有比较好的可移植性，避免使用 `gcc` 的一些扩展特性，可以结合 `-std` 和 `-pedantic` （或者 `-pedantic-erros`) 选项让源代码遵循某个 C 语言标准的语法。这里演示一个简单的例子：

    $ cat hello.c
    #include <stdio.h>
    int main()
    {
        printf("hello, worldn")
        return 0;
    }
    $ gcc -fsyntax-only hello.c
    hello.c: In function ‘main’:
    hello.c:5: error: expected ‘;’ before ‘return’
    $ vim hello.c
    $ cat hello.c
    #include <stdio.h>
    int main()
    {
            printf("hello, worldn");
            int i;
            return 0;
    }
    $ gcc -std=c89 -pedantic-errors hello.c    #默认情况下，gcc是允许在程序中间声明变量的，但是turboc就不支持
    hello.c: In function ‘main’:
    hello.c:5: error: ISO C90 forbids mixed declarations and code


语法错误是程序开发过程中难以避免的错误（人的大脑在很多情况下都容易开小差），不过编译器往往能够通过语法检查快速发现这些错误，并准确地告知语法错误的大概位置。因此，作为开发人员，要做的事情不是“恐慌”（不知所措），而是认真阅读编译器的提示，根据平时积累的经验（最好总结一份常见语法错误索引，很多资料都提供了常见语法错误列表，如《 C Traps&Pitfalls 》和编辑器提供的语法检查功能（语法加亮、括号匹配提示等）快速定位语法出错的位置并进行修改。

### 编译器优化

语法检查之后就是翻译动作， `gcc` 提供了一个优化选项 `-O` ，以便根据不同的运行平台和用户要求产生经过优化的汇编代码。例如，

    $ gcc -o hello hello.c         #采用默认选项，不优化
    $ gcc -O2 -o hello2 hello.c    #优化等次是2
    $ gcc -Os -o hellos hello.c    #优化目标代码的大小
    $ ls -S hello hello2 hellos    #可以看到，hellos比较小,hello2比较大
    hello2  hello  hellos
    $ time ./hello
    hello, world

    real    0m0.001s
    user    0m0.000s
    sys     0m0.000s
    $ time ./hello2     #可能是代码比较少的缘故，执行效率看上去不是很明显
    hello, world

    real    0m0.001s
    user    0m0.000s
    sys     0m0.000s

    $ time ./hellos     #虽然目标代码小了，但是执行效率慢了些
    hello, world

    real    0m0.002s
    user    0m0.000s
    sys     0m0.000s


根据上面的简单演示，可以看出 `gcc` 有很多不同的优化选项，主要看用户的需求了，目标代码的大小和效率之间貌似存在一个“纠缠”，需要开发人员自己权衡。

### 生成汇编语言文件

下面通过 `-S` 选项来看看编译出来的中间结果：汇编语言，还是以之前那个 hello.c 为例。

    $ gcc -S hello.c  #默认输出是hello.s，可自己指定，输出到屏幕`-o -`，输出到其他文件`-o file`
    $ cat hello.s
    cat hello.s
            .file   "hello.c"
            .section        .rodata
    .LC0:
            .string "hello, world"
            .text
    .globl main
            .type   main, @function
    main:
            leal    4(%esp), %ecx
            andl    $-16, %esp
            pushl   -4(%ecx)
            pushl   %ebp
            movl    %esp, %ebp
            pushl   %ecx
            subl    $4, %esp
            movl    $.LC0, (%esp)
            call    puts
            movl    $0, %eax
            addl    $4, %esp
            popl    %ecx
            popl    %ebp
            leal    -4(%ecx), %esp
            ret
            .size   main, .-main
            .ident  "GCC: (GNU) 4.1.3 20070929 (prerelease) (Ubuntu 4.1.2-16ubuntu2)"
            .section        .note.GNU-stack,"",@progbits


不知道看出来没？和课堂里学的 intel 的汇编语法不太一样，这里用的是 AT&T 语法格式。如果想学习 Linux 下的汇编语言开发，下一节开始的所有章节基本上覆盖了 Linux 下汇编语言开发的一般过程，不过这里不介绍汇编语言语法。

在学习后面的章节之前，建议自学旧金山大学的微机编程课程 CS630 ，该课深入介绍了 Linux/X86 平台下的 AT&T 汇编语言开发。如果想在 Qemu 上做这个课程里的实验，可以阅读本文作者写的 [CS630:Linux 下通过 Qemu 学习 X86 AT&T 汇编语言 ][5] 。

需要补充的是，在写 C 语言代码时，如果能够对编译器比较熟悉（工作原理和一些细节）的话，可能会很有帮助。包括这里的优化选项 ( 有些优化选项可能在汇编时采用 ) 和可能的优化措施，例如字节对齐、条件分支语句裁减 ( 删除一些明显分支 ) 等。

## 汇编

### 简述

汇编实际上还是翻译过程，只不过把作为中间结果的汇编代码翻译成了机器代码，即目标代码，不过它还不可以运行。如果要产生这一中间结果，可用 `gcc -c` ，当然，也可通过 `as` 命令处理汇编语言源文件来产生。

汇编是把汇编语言翻译成目标代码的过程，如果有在 Windows 下学习过汇编语言开发，大家应该比较熟悉 `nasm` 汇编工具 ( 支持 Intel 格式的汇编语言 ) ，不过这里主要用 `as` 汇编工具来汇编 AT&T 格式的汇编语言，因为 `gcc` 产生的中间代码就是 AT&T 格式的。

### 生成目标代码

下面来演示分别通过 `gcc -c` 选项和 `as` 来产生目标代码。

    $ file hello.s
    hello.s: ASCII assembler program text
    $ gcc -c hello.s   #用gcc把汇编语言编译成目标代码
    $ file hello.o     #file命令用来查看文件类型，目标代码可重定位的(relocatable)，
                       #需要通过ld进行进一步链接成可执行程序(executable)和共享库(shared)
    hello.o: ELF 32-bit LSB relocatable, Intel 80386, version 1 (SYSV), not stripped
    $ as -o hello.o hello.s        #用as把汇编语言编译成目标代码
    $ file hello.o
    hello.o: ELF 32-bit LSB relocatable, Intel 80386, version 1 (SYSV), not stripped


 `gcc` 和 `as` 默认产生的目标代码都是 ELF 格式的，因此这里主要讨论 ELF 格式的目标代码 ( 如果有时间再回顾一下 `a.out` 和 `coff` 格式，当然也可以先了解一下，并结合 `objcopy` 来转换它们，比较异同 ) 。

### ELF 文件初次接触

目标代码不再是普通的文本格式，无法直接通过文本编辑器浏览，需要一些专门的工具。如果想了解更多目标代码的细节，区分 `relocatable` （可重定位）、 `executable` （可执行）、 `shared libarary` （共享库）的不同，我们得设法了解目标代码的组织方式和相关的阅读和分析工具。下面主要介绍这部分内容。

> BFD is a package which allows applications to use the same routines to operate on object files whatever the object file format. A new object file format can be supported simply by creating a new BFD back end and adding it to the library.

 binutils(GNU Binary Utilities) 的很多工具都采用这个库来操作目标文件，这类工具有 `objdump` ， `objcopy` ， `nm` ， `strip` 等 ( 当然，我们也可以利用它。如果深入了解 ELF 格式，那么通过它来分析和编写 Virus 程序将会更加方便 ) ，不过另外一款非常优秀的分析工具 `readelf` 并不是基于这个库，所以也应该可以直接用 `elf.h` 头文件中定义的相关结构来操作 ELF 文件。

下面将通过这些辅助工具 ( 主要是 `readelf` 和 `objdump`) ，结合 ELF 手册来分析它们。将依次介绍 ELF 文件的结构和三种不同类型 ELF 文件的区别。

### ELF 文件的结构

    ELF Header(ELF文件头)
    Program Headers Table(程序头表，实际上叫段表好一些，用于描述可执行文件和可共享库)
    Section 1
    Section 2
    Section 3
    ...
    Section Headers Table(节区头部表，用于链接可重定位文件成可执行文件或共享库)


对于可重定位文件，程序头是可选的，而对于可执行文件和共享库文件（动态链接库），节区表则是可选的。可以分别通过 `readelf` 文件的 `-h` ， `-l` 和 `-S` 参数查看 ELF 文件头 (ELF Header) 、程序头部表（ Program Headers Table ，段表）和节区表 (Section Headers Table) 。

文件头说明了文件的类型，大小，运行平台，节区数目等。

### 三种不同类型 ELF 文件比较

先来通过文件头看看不同 ELF 的类型。为了说明问题，先来几段代码吧。

    /* myprintf.c */
    #include <stdio.h>

    void myprintf(void)
    {
        printf("hello, world!n");
    }

    /* test.h -- myprintf function declaration */

    #ifndef _TEST_H_
    #define _TEST_H_

    void myprintf(void);

    #endif

    /* test.c */
    #include "test.h"

    int main()
    {
        myprintf();
        return 0;
    }


下面通过这几段代码来演示通过 `readelf -h` 参数查看 ELF 的不同类型。期间将演示如何创建动态链接库 ( 即可共享文件 ) 、静态链接库，并比较它们的异同。

编译产生两个目标文件 myprintf.o 和 test.o ，它们都是可重定位文件 (REL) ：

    $ gcc -c myprintf.c test.c
    $ readelf -h test.o | grep Type
      Type:                              REL (Relocatable file)
    $ readelf -h myprintf.o | grep Type
      Type:                              REL (Relocatable file)


根据目标代码链接产生可执行文件，这里的文件类型是可执行的(EXEC)：

    $ gcc -o test myprintf.o test.o
    $ readelf -h test | grep Type
      Type:                              EXEC (Executable file)


用 ar 命令创建一个静态链接库，静态链接库也是可重定位文件(REL)：

    $ ar rcsv libmyprintf.a myprintf.o
    $ readelf -h libmyprintf.a | grep Type
      Type:                              REL (Relocatable file)


可见，静态链接库和可重定位文件类型一样，它们之间唯一不同是前者可以是多个可重定位文件的“集合”。

静态链接库可直接链接（只需库名，不要前面的 lib ），也可用 -l 参数， -L 指定库搜索路径。

    $ gcc -o test test.o -lmyprintf -L./


编译产生动态链接库，并支持 major 和 minor 版本号，动态链接库类型为 DYN ：

    $ gcc -Wall myprintf.o -shared -Wl,-soname,libmyprintf.so.0 -o libmyprintf.so.0.0
    $ ln -sf libmyprintf.so.0.0 libmyprintf.so.0
    $ ln -sf libmyprintf.so.0 libmyprintf.so
    $ readelf -h libmyprintf.so | grep Type
      Type:                              DYN (Shared object file)


动态链接库编译时和静态链接库类似：

    $ gcc -o test test.o -lmyprintf -L./


但是执行时需要指定动态链接库的搜索路径 , 把 LD\_LIBRARY\_PATH 设为当前目录，指定 test 运行时的动态链接库搜索路径：

    $ LD_LIBRARY_PATH=./ ./test
    $ gcc -static -o test test.o -lmyprintf -L./


在不指定 `-static` 时会优先使用动态链接库，指定时则阻止使用动态链接库，这时会把所有静态链接库文件加入到可执行文件中，使得执行文件很大，而且加载到内存以后会浪费内存空间，因此不建议这么做。

经过上面的演示基本可以看出它们之间的不同：

  * 可重定位文件本身不可以运行，仅仅是作为可执行文件、静态链接库（也是可重定位文件）、动态链接库的 “组件”。
  * 静态链接库和动态链接库本身也不可以执行，作为可执行文件的“组件”，它们两者也不同，前者也是可重定位文件（只不过可能是多个可重定位文件的集合），并且在链接时加入到可执行文件中去。
  * 而动态链接库在链接时，库文件本身并没有添加到可执行文件中，只是在可执行文件中加入了该库的名字等信息，以便在可执行文件运行过程中引用库中的函数时由动态链接器去查找相关函数的地址，并调用它们。

从这个意义上说，动态链接库本身也具有可重定位的特征，含有可重定位的信息。对于什么是重定位？如何进行静态符号和动态符号的重定位，我们将在链接部分和《动态符号链接的细节》一节介绍。

### ELF 主体：节区

下面来看看 ELF 文件的主体内容：节区（Section)。

 ELF 文件具有很大的灵活性，它通过文件头组织整个文件的总体结构，通过节区表 (Section Headers Table) 和程序头（ Program Headers Table 或者叫段表 ) 来分别描述可重定位文件和可执行文件。但不管是哪种类型，它们都需要它们的主体，即各种节区。

在可重定位文件中，节区表描述的就是各种节区本身；而在可执行文件中，程序头描述的是由各个节区组成的段（ Segment ），以便程序运行时动态装载器知道如何对它们进行内存映像，从而方便程序加载和运行。

下面先来看看一些常见的节区，而关于这些节区 (section) 如何通过重定位构成不同的段 (Segments) ，以及有哪些常规的段，我们将在链接部分进一步介绍。

可以通过 `readelf -S` 查看 ELF 的节区。（建议一边操作一边看文档，以便加深对 ELF 文件结构的理解）先来看看可重定位文件的节区信息，通过节区表来查看：

默认编译好 myprintf.c ，将产生一个可重定位的文件 myprintf.o ，这里通过 myprintf.o 的节区表查看节区信息。

    $ gcc -c myprintf.c
    $ readelf -S myprintf.o
    There are 11 section headers, starting at offset 0xc0:

    Section Headers:
      [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
      [ 0]                   NULL            00000000 000000 000000 00      0   0  0
      [ 1] .text             PROGBITS        00000000 000034 000018 00  AX  0   0  4
      [ 2] .rel.text         REL             00000000 000334 000010 08      9   1  4
      [ 3] .data             PROGBITS        00000000 00004c 000000 00  WA  0   0  4
      [ 4] .bss              NOBITS          00000000 00004c 000000 00  WA  0   0  4
      [ 5] .rodata           PROGBITS        00000000 00004c 00000e 00   A  0   0  1
      [ 6] .comment          PROGBITS        00000000 00005a 000012 00      0   0  1
      [ 7] .note.GNU-stack   PROGBITS        00000000 00006c 000000 00      0   0  1
      [ 8] .shstrtab         STRTAB          00000000 00006c 000051 00      0   0  1
      [ 9] .symtab           SYMTAB          00000000 000278 0000a0 10     10   8  4
      [10] .strtab           STRTAB          00000000 000318 00001a 00      0   0  1
    Key to Flags:
      W (write), A (alloc), X (execute), M (merge), S (strings)
      I (info), L (link order), G (group), x (unknown)
      O (extra OS processing required) o (OS specific), p (processor specific)


用 `objdump -d` 可看反编译结果，用 `-j` 选项可指定需要查看的节区：

    $ objdump -d -j .text   myprintf.o
    myprintf.o:     file format elf32-i386

    Disassembly of section .text:

    00000000 <myprintf>:
       0:   55                      push   %ebp
       1:   89 e5                   mov    %esp,%ebp
       3:   83 ec 08                sub    $0x8,%esp
       6:   83 ec 0c                sub    $0xc,%esp
       9:   68 00 00 00 00          push   $0x0
       e:   e8 fc ff ff ff          call   f <myprintf+0xf>
      13:   83 c4 10                add    $0x10,%esp
      16:   c9                      leave
      17:   c3                      ret


用 `-r` 选项可以看到有关重定位的信息，这里有两部分需要重定位：

    $ readelf -r myprintf.o

    Relocation section &#39;.rel.text&#39; at offset 0x334 contains 2 entries:
     Offset     Info    Type            Sym.Value  Sym. Name
    0000000a  00000501 R_386_32          00000000   .rodata
    0000000f  00000902 R_386_PC32        00000000   puts


 `.rodata` 节区包含只读数据，即我们要打印的 `hello, world!` 

    $ readelf -x .rodata myprintf.o

    Hex dump of section &#39;.rodata&#39;:
      0x00000000 68656c6c 6f2c2077 6f726c64 2100     hello, world!.


没有找到 `.data` 节区 ,  它应该包含一些初始化的数据：

    $ readelf -x .data myprintf.o

    Section &#39;.data&#39; has no data to dump.


也没有 `.bss` 节区，它应该包含一些未初始化的数据，程序默认初始为 0 ：

    $ readelf -x .bss       myprintf.o

    Section &#39;.bss&#39; has no data to dump.


 `.comment` 是一些注释，可以看到是是 GCC 的版本信息

    $ readelf -x .comment myprintf.o

    Hex dump of section &#39;.comment&#39;:
      0x00000000 00474343 3a202847 4e552920 342e312e .GCC: (GNU) 4.1.
      0x00000010 3200                                2.


 `.note.GNU-stack` 这个节区也没有内容：

    $ readelf -x .note.GNU-stack myprintf.o

    Section &#39;.note.GNU-stack&#39; has no data to dump.


 `.shstrtab` 包括所有节区的名字：

    $ readelf -x .shstrtab myprintf.o

    Hex dump of section &#39;.shstrtab&#39;:
      0x00000000 002e7379 6d746162 002e7374 72746162 ..symtab..strtab
      0x00000010 002e7368 73747274 6162002e 72656c2e ..shstrtab..rel.
      0x00000020 74657874 002e6461 7461002e 62737300 text..data..bss.
      0x00000030 2e726f64 61746100 2e636f6d 6d656e74 .rodata..comment
      0x00000040 002e6e6f 74652e47 4e552d73 7461636b ..note.GNU-stack
      0x00000050 00                                  .


符号表 `.symtab` 包括所有用到的相关符号信息，如函数名、变量名，可用 `readelf` 查看：

    $ readelf -symtab myprintf.o

    Symbol table &#39;.symtab&#39; contains 10 entries:
       Num:    Value  Size Type    Bind   Vis      Ndx Name
         0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND
         1: 00000000     0 FILE    LOCAL  DEFAULT  ABS myprintf.c
         2: 00000000     0 SECTION LOCAL  DEFAULT    1
         3: 00000000     0 SECTION LOCAL  DEFAULT    3
         4: 00000000     0 SECTION LOCAL  DEFAULT    4
         5: 00000000     0 SECTION LOCAL  DEFAULT    5
         6: 00000000     0 SECTION LOCAL  DEFAULT    7
         7: 00000000     0 SECTION LOCAL  DEFAULT    6
         8: 00000000    24 FUNC    GLOBAL DEFAULT    1 myprintf
         9: 00000000     0 NOTYPE  GLOBAL DEFAULT  UND puts


字符串表 `.strtab` 包含用到的字符串，包括文件名、函数名、变量名等：

    $ readelf -x .strtab myprintf.o

    Hex dump of section &#39;.strtab&#39;:
      0x00000000 006d7970 72696e74 662e6300 6d797072 .myprintf.c.mypr
      0x00000010 696e7466 00707574 7300              intf.puts.


从上表可以看出，对于可重定位文件，会包含这些基本节区`.text`, `.rel.text`, `.data`, `.bss`, `.rodata`, `.comment`, `.note.GNU-stack`, `.shstrtab`, `.symtab`和`.strtab`。

### 汇编语言文件中的节区表述

为了进一步理解这些节区和源代码的关系，这里来看一看 myprintf.c 产生的汇编代码。

    $ gcc -S myprintf.c
    $ cat myprintf.s
            .file   "myprintf.c"
            .section        .rodata
    .LC0:
            .string "hello, world!"
            .text
    .globl myprintf
            .type   myprintf, @function
    myprintf:
            pushl   %ebp
            movl    %esp, %ebp
            subl    $8, %esp
            subl    $12, %esp
            pushl   $.LC0
            call    puts
            addl    $16, %esp
            leave
            ret
            .size   myprintf, .-myprintf
            .ident  "GCC: (GNU) 4.1.2"
            .section        .note.GNU-stack,"",@progbits


是不是可以从中看出可重定位文件中的那些节区和汇编语言代码之间的关系？在上面的可重定位文件，可以看到有一个可重定位的节区，即 `.rel.text` ，它标记了两个需要重定位的项， `.rodata` 和 `puts` 。这个节区将告诉编译器这两个信息在链接或者动态链接的过程中需要重定位，   具体如何重定位？将根据重定位项的类型，比如上面的 `R_386_32` 和 `R_386_PC32` 。

到这里，对可重定位文件应该有了一个基本的了解，下面将介绍什么是可重定位，可重定位文件到底是如何被链接生成可执行文件和动态链接库的，这个过程除了进行一些符号的重定位外，还进行了哪些工作呢？

## 链接

### 简述

重定位是将符号引用与符号定义进行链接的过程。因此链接是处理可重定位文件，把它们的各种符号引用和符号定义转换为可执行文件中的合适信息 ( 一般是虚拟内存地址 ) 的过程。

链接又分为静态链接和动态链接，前者是程序开发阶段程序员用 `ld`(`gcc` 实际上在后台调用了 `ld`) 静态链接器手动链接的过程，而动态链接则是程序运行期间系统调用动态链接器 (`ld-linux.so`) 自动链接的过程。

比如，如果链接到可执行文件中的是静态链接库 libmyprintf.a ，那么 `.rodata` 节区在链接后需要被重定位到一个绝对的虚拟内存地址，以便程序运行时能够正确访问该节区中的字符串信息。而对于 `puts` 函数，因为它是动态链接库 libc.so 中定义的函数，所以会在程序运行时通过动态符号链接找出 `puts` 函数在内存中的地址，以便程序调用该函数。在这里主要讨论静态链接过程，动态链接过程见《动态符号链接的细节》。

静态链接过程主要是把可重定位文件依次读入，分析各个文件的文件头，进而依次读入各个文件的节区，并计算各个节区的虚拟内存位置，对一些需要重定位的符号进行处理，设定它们的虚拟内存地址等，并最终产生一个可执行文件或者是动态链接库。这个链接过程是通过 `ld` 来完成的， `ld` 在链接时使用了一个链接脚本（ `linker script` ），该链接脚本处理链接的具体细节。

由于静态符号链接过程非常复杂，特别是计算符号地址的过程，考虑到时间关系，相关细节请参考 ELF 手册。这里主要介绍可重定位文件中的节区（节区表描述的）和可执行文件中段（程序头描述的）的对应关系以及 `gcc` 编译时采用的一些默认链接选项。

### 可执行文件的段：节区重排

下面先来看看可执行文件的节区信息，通过程序头（段表）来查看，为了比较，先把 test.o 的节区表也列出：

    $ readelf -S test.o
    There are 10 section headers, starting at offset 0xb4:

    Section Headers:
      [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
      [ 0]                   NULL            00000000 000000 000000 00      0   0  0
      [ 1] .text             PROGBITS        00000000 000034 000024 00  AX  0   0  4
      [ 2] .rel.text         REL             00000000 0002ec 000008 08      8   1  4
      [ 3] .data             PROGBITS        00000000 000058 000000 00  WA  0   0  4
      [ 4] .bss              NOBITS          00000000 000058 000000 00  WA  0   0  4
      [ 5] .comment          PROGBITS        00000000 000058 000012 00      0   0  1
      [ 6] .note.GNU-stack   PROGBITS        00000000 00006a 000000 00      0   0  1
      [ 7] .shstrtab         STRTAB          00000000 00006a 000049 00      0   0  1
      [ 8] .symtab           SYMTAB          00000000 000244 000090 10      9   7  4
      [ 9] .strtab           STRTAB          00000000 0002d4 000016 00      0   0  1
    Key to Flags:
      W (write), A (alloc), X (execute), M (merge), S (strings)
      I (info), L (link order), G (group), x (unknown)
      O (extra OS processing required) o (OS specific), p (processor specific)
    $ gcc -o test test.o myprintf.o
    $ readelf -l test

    Elf file type is EXEC (Executable file)
    Entry point 0x80482b0
    There are 7 program headers, starting at offset 52

    Program Headers:
      Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
      PHDR           0x000034 0x08048034 0x08048034 0x000e0 0x000e0 R E 0x4
      INTERP         0x000114 0x08048114 0x08048114 0x00013 0x00013 R   0x1
          [Requesting program interpreter: /lib/ld-linux.so.2]
      LOAD           0x000000 0x08048000 0x08048000 0x0047c 0x0047c R E 0x1000
      LOAD           0x00047c 0x0804947c 0x0804947c 0x00104 0x00108 RW  0x1000
      DYNAMIC        0x000490 0x08049490 0x08049490 0x000c8 0x000c8 RW  0x4
      NOTE           0x000128 0x08048128 0x08048128 0x00020 0x00020 R   0x4
      GNU_STACK      0x000000 0x00000000 0x00000000 0x00000 0x00000 RW  0x4

     Section to Segment mapping:
      Segment Sections...
       00
       01     .interp
       02     .interp .note.ABI-tag .hash .dynsym .dynstr .gnu.version .gnu.version_r
              .rel.dyn .rel.plt .init .plt .text .fini .rodata .eh_frame
       03     .ctors .dtors .jcr .dynamic .got .got.plt .data .bss
       04     .dynamic
       05     .note.ABI-tag
       06


可发现， test 和 test.o,myprintf.o 相比，多了很多节区，如 `.interp` 和 `.init` 等。另外，上表也给出了可执行文件的如下几个段 (segment) ：

  * `PHDR`: 给出了程序表自身的大小和位置，不能出现一次以上。
  * `INTERP`: 因为程序中调用了`puts`（在动态链接库中定义），使用了动态链接库，因此需要动态装载器／链接器(`ld-linux.so`)
  * `LOAD`: 包括程序的指令，`.text`等节区都映射在该段，只读(R)
  * `LOAD`: 包括程序的数据，`.data`,`.bss`等节区都映射在该段，可读写(RW)
  * `DYNAMIC`: 动态链接相关的信息，比如包含有引用的动态链接库名字等信息
  * `NOTE`: 给出一些附加信息的位置和大小
  * `GNU_STACK`: 这里为空，应该是和GNU相关的一些信息

这里的段可能包括之前的一个或者多个节区，也就是说经过链接之后原来的节区被重排了，并映射到了不同的段，这些段将告诉系统应该如何把它加载到内存中。

### 链接背后的故事

从上表中，通过比较可执行文件 (test) 中拥有的节区和可重定位文件 (test.o 和 myprintf.o) 中拥有的节区后发现，链接之后多了一些之前没有的节区，这些新的节区来自哪里？它们的作用是什么呢？先来通过 `gcc -v` 看看它的后台链接过程。

把可重定位文件链接成可执行文件：

    $ gcc -v -o test test.o myprintf.o
    Reading specs from /usr/lib/gcc/i486-slackware-linux/4.1.2/specs
    Target: i486-slackware-linux
    Configured with: ../gcc-4.1.2/configure --prefix=/usr --enable-shared
    --enable-languages=ada,c,c++,fortran,java,objc --enable-threads=posix
    --enable-__cxa_atexit --disable-checking --with-gnu-ld --verbose
    --with-arch=i486 --target=i486-slackware-linux --host=i486-slackware-linux
    Thread model: posix
    gcc version 4.1.2
     /usr/libexec/gcc/i486-slackware-linux/4.1.2/collect2 --eh-frame-hdr -m
    elf_i386 -dynamic-linker /lib/ld-linux.so.2 -o test
    /usr/lib/gcc/i486-slackware-linux/4.1.2/../../../crt1.o
    /usr/lib/gcc/i486-slackware-linux/4.1.2/../../../crti.o
    /usr/lib/gcc/i486-slackware-linux/4.1.2/crtbegin.o
    -L/usr/lib/gcc/i486-slackware-linux/4.1.2
    -L/usr/lib/gcc/i486-slackware-linux/4.1.2
    -L/usr/lib/gcc/i486-slackware-linux/4.1.2/../../../../i486-slackware-linux/lib
    -L/usr/lib/gcc/i486-slackware-linux/4.1.2/../../.. test.o myprintf.o -lgcc
    --as-needed -lgcc_s --no-as-needed -lc -lgcc --as-needed -lgcc_s --no-as-needed
    /usr/lib/gcc/i486-slackware-linux/4.1.2/crtend.o
    /usr/lib/gcc/i486-slackware-linux/4.1.2/../../../crtn.o


从上述演示看出， `gcc` 在链接了我们自己的目标文件 test.o 和 myprintf.o 之外，还链接了 crt1.o ， crtbegin.o 等额外的目标文件，难道那些新的节区就来自这些文件？

### 用 ld 完成链接过程

另外 `gcc` 在进行了相关配置 (`./configure`) 后，调用了 `collect2` ，却并没有调用 `ld` ，通过查找 `gcc` 文档中和 `collect2` 相关的部分发现 `collect2` 在后台实际上还是去寻找 `ld` 命令的。为了理解 `gcc` 默认链接的后台细节，这里直接把 `collect2` 替换成 `ld` ，并把一些路径换成绝对路径或者简化，得到如下的 `ld` 命令以及执行的效果。

    $ ld --eh-frame-hdr
    -m elf_i386
    -dynamic-linker /lib/ld-linux.so.2
    -o test
    /usr/lib/crt1.o /usr/lib/crti.o /usr/lib/gcc/i486-slackware-linux/4.1.2/crtbegin.o
    test.o myprintf.o
    -L/usr/lib/gcc/i486-slackware-linux/4.1.2 -L/usr/i486-slackware-linux/lib -L/usr/lib/
    -lgcc --as-needed -lgcc_s --no-as-needed -lc -lgcc --as-needed -lgcc_s --no-as-needed
    /usr/lib/gcc/i486-slackware-linux/4.1.2/crtend.o /usr/lib/crtn.o
    $ ./test
    hello, world!


不出所料，它完美地运行了。下面通过 `ld` 的手册 (`man ld`) 来分析一下这几个参数：

* `--eh-frame-hdr`

  要求创建一个 `.eh_frame_hdr` 节区 ( 貌似目标文件 test 中并没有这个节区，所以不关心它 ) 。

* `-m elf_i386`

  这里指定不同平台上的链接脚本，可以通过 `--verbose` 命令查看脚本的具体内容，如 `ld -m elf_i386 --verbose` ，它实际上被存放在一个文件中 (`/usr/lib/ldscripts` 目录下），我们可以去修改这个脚本，具体如何做？请参考 `ld` 的手册。在后面我们将简要提到链接脚本中是如何预定义变量的，以及这些预定义变量如何在我们的程序中使用。需要提到的是，如果不是交叉编译，那么无须指定该选项。

* -dynamic-linker /lib/ld-linux.so.2

  指定动态装载器 / 链接器，即程序中的 `INTERP` 段中的内容。动态装载器 / 链接器负责链接有可共享库的可执行文件的装载和动态符号链接。

* -o test

  指定输出文件，即可执行文件名的名字

* /usr/lib/crt1.o /usr/lib/crti.o /usr/lib/gcc/i486-slackware-linux/4.1.2/crtbegin.o

  链接到 test 文件开头的一些内容，这里实际上就包含了 `.init` 等节区。 `.init` 节区包含一些可执行代码，在 main 函数之前被调用，以便进行一些初始化操作，在 C++ 中完成构造函数功能。

* test.o myprintf.o

  链接我们自己的可重定位文件

* `-L/usr/lib/gcc/i486-slackware-linux/4.1.2 -L/usr/i486-slackware-linux/lib -L/usr/lib/    -lgcc --as-needed -lgcc_s --no-as-needed -lc -lgcc --as-needed -lgcc_s --no-as-needed`

  链接 libgcc 库和 libc 库，后者定义有我们需要的 puts 函数

* /usr/lib/gcc/i486-slackware-linux/4.1.2/crtend.o /usr/lib/crtn.o

  链接到 test 文件末尾的一些内容，这里实际上包含了 `.fini` 等节区。 `.fini` 节区包含了一些可执行代码，在程序退出时被执行，作一些清理工作，在 C++ 中完成析构造函数功能。我们往往可以通过 `atexit` 来注册那些需要在程序退出时才执行的函数。

### C++ 构造与析构：crtbegin.o 和 crtend.o

对于 crtbegin.o 和 crtend.o 这两个文件，貌似完全是用来支持 C++ 的构造和析构工作的，所以可以不链接到我们的可执行文件中，链接时把它们去掉看看，

    $ ld -m elf_i386 -dynamic-linker /lib/ld-linux.so.2 -o test
      /usr/lib/crt1.o /usr/lib/crti.o test.o myprintf.o
      -L/usr/lib -lc /usr/lib/crtn.o    #后面发现不用链接libgcc，也不用--eh-frame-hdr参数
    $ readelf -l test

    Elf file type is EXEC (Executable file)
    Entry point 0x80482b0
    There are 7 program headers, starting at offset 52

    Program Headers:
      Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
      PHDR           0x000034 0x08048034 0x08048034 0x000e0 0x000e0 R E 0x4
      INTERP         0x000114 0x08048114 0x08048114 0x00013 0x00013 R   0x1
          [Requesting program interpreter: /lib/ld-linux.so.2]
      LOAD           0x000000 0x08048000 0x08048000 0x003ea 0x003ea R E 0x1000
      LOAD           0x0003ec 0x080493ec 0x080493ec 0x000e8 0x000e8 RW  0x1000
      DYNAMIC        0x0003ec 0x080493ec 0x080493ec 0x000c8 0x000c8 RW  0x4
      NOTE           0x000128 0x08048128 0x08048128 0x00020 0x00020 R   0x4
      GNU_STACK      0x000000 0x00000000 0x00000000 0x00000 0x00000 RW  0x4

     Section to Segment mapping:
      Segment Sections...
       00
       01     .interp
       02     .interp .note.ABI-tag .hash .dynsym .dynstr .gnu.version .gnu.version_r
              .rel.dyn .rel.plt .init .plt .text .fini .rodata
       03     .dynamic .got .got.plt .data
       04     .dynamic
       05     .note.ABI-tag
       06
    $ ./test
    hello, world!


完全可以工作，而且发现 `.ctors`( 保存着程序中全局构造函数的指针数组 ), `.dtors` （保存着程序中全局析构函数的指针数组） ,`.jcr` （未知） ,`.eh_frame` 节区都没有了，所以 crtbegin.o 和 crtend.o 应该包含了这些节区。

### 初始化与退出清理：crti.o 和 crtn.o

而对于另外两个文件 crti.o 和 crtn.o ，通过 `readelf -S` 查看后发现它们都有 `.init` 和 `.fini` 节区，如果我们不需要让程序进行一些初始化和清理工作呢？是不是就可以不链接这个两个文件？试试看。

    $ ld  -m elf_i386 -dynamic-linker /lib/ld-linux.so.2 -o test
          /usr/lib/crt1.o test.o myprintf.o -L/usr/lib/ -lc
    /usr/lib/libc_nonshared.a(elf-init.oS): In function `__libc_csu_init&#39;:
    (.text+0x25): undefined reference to `_init&#39;


貌似不行，竟然有人调用了 `__libc_csu_init` 函数，而这个函数引用了 `_init` 。这两个符号都在哪里呢？

    $ readelf -s /usr/lib/crt1.o | grep __libc_csu_init
        18: 00000000     0 NOTYPE  GLOBAL DEFAULT  UND __libc_csu_init
    $ readelf -s /usr/lib/crti.o | grep _init
        17: 00000000     0 FUNC    GLOBAL DEFAULT    5 _init


竟然是 crt1.o 调用了 `__libc_csu_init` 函数，而该函数却引用了我们没有链接的 crti.o 文件中定义的 `_init` 符号。这样的话不链接 crti.o 和 crtn.o 文件就不成了罗？不对吧，要不干脆不用 crt1.o 算了，看看 `gcc` 额外链接进去的最后一个文件 crt1.o 到底干了个啥子？

    $ ld  -m elf_i386 -dynamic-linker /lib/ld-linux.so.2 -o
          test test.o myprintf.o -L/usr/lib/ -lc
    ld: warning: cannot find entry symbol _start; defaulting to 00000000080481a4


这样却说没有找到入口符号 `_start` ，难道 crt1.o 中定义了这个符号？不过它给默认设置了一个地址，只是个警告，说明 test 已经生成，不管怎样先运行看看再说。

    $ ./test
    hello, world!
    Segmentation fault


貌似程序运行完了，不过结束时冒出个段错误？可能是程序结束时有问题，用 gdb 调试看看：

    $ gcc -g -c test.c myprintf.c #产生目标代码, 非交叉编译，不指定-m也可链接，所以下面可去掉-m
    $ ld -dynamic-linker /lib/ld-linux.so.2 -o test
         test.o myprintf.o -L/usr/lib -lc
    ld: warning: cannot find entry symbol _start; defaulting to 00000000080481d8
    $ ./test
    hello, world!
    Segmentation fault
    $ gdb ./test
    ...
    (gdb) l
    1       #include "test.h"
    2
    3       int main()
    4       {
    5               myprintf();
    6               return 0;
    7       }
    (gdb) break 7      #在程序的末尾设置一个断点
    Breakpoint 1 at 0x80481bf: file test.c, line 7.
    (gdb) r            #程序都快结束了都没问题，怎么会到最后出个问题呢？
    Starting program: /mnt/hda8/Temp/c/program/test
    hello, world!

    Breakpoint 1, main () at test.c:7
    7       }
    (gdb) n        #单步执行看看，怎么下面一条指令是0x00000001，肯定是程序退出以后出了问题
    0x00000001 in ?? ()
    (gdb) n        #诶，当然找不到边了，都跑到0x00000001了
    Cannot find bounds of current function
    (gdb) c
    Continuing.

    Program received signal SIGSEGV, Segmentation fault.
    0x00000001 in ?? ()


原来是这么回事，估计是 return 0 返回之后出问题了，看看它的汇编去。

    $ gcc -S test.c #产生汇编代码
    $ cat test.s
    ...
            call    myprintf
            movl    $0, %eax
            addl    $4, %esp
            popl    %ecx
            popl    %ebp
            leal    -4(%ecx), %esp
            ret
    ...


后面就这么几条指令，难不成 ret 返回有问题，不让它 ret 返回，把 return 改成 `_exit` 直接进入内核退出。

    $ vim test.c
    $ cat test.c    #就把return语句修改成_exit了。
    #include "test.h"
    #include <unistd.h> /* _exit */

    int main()
    {
        myprintf();
        _exit(0);
    }
    $ gcc -g -c test.c myprintf.c
    $ ld -dynamic-linker /lib/ld-linux.so.2 -o test test.o myprintf.o -L/usr/lib -lc
    ld: warning: cannot find entry symbol _start; defaulting to 00000000080481d8
    $ ./test    #竟然好了，再看看汇编有什么不同
    hello, world!
    $ gcc -S test.c
    $ cat test.s    #貌似就把ret指令替换成了_exit函数调用，直接进入内核，让内核处理了，那为什么ret有问题呢？
    ...
            call    myprintf
            subl    $12, %esp
            pushl   $0
            call    _exit
    ...
    $ gdb ./test    #把代码改回去（改成return 0;），再调试看看调用main函数返回时的下一条指令地址eip
    ...
    (gdb) l
    warning: Source file is more recent than executable.
    1       #include "test.h"
    2
    3       int main()
    4       {
    5               myprintf();
    6               return 0;
    7       }
    (gdb) break 5
    Breakpoint 1 at 0x80481b5: file test.c, line 5.
    (gdb) break 7
    Breakpoint 2 at 0x80481bc: file test.c, line 7.
    (gdb) r
    Starting program: /mnt/hda8/Temp/c/program/test

    Breakpoint 1, main () at test.c:5
    5               myprintf();
    (gdb) x/8x $esp
    0xbf929510:     0xbf92953c      0x080481a4      0x00000000      0xb7eea84f
    0xbf929520:     0xbf92953c      0xbf929534      0x00000000      0x00000001


发现 0x00000001 刚好是之前调试时看到的程序返回后的位置，即 eip ，说明程序在初始化时，这个 eip 就是错误的。为什么呢？因为根本没有链接进初始化的代码，而是在编译器自己给我们，初始化了程序入口即 00000000080481d8 ，也就是说，没有人调用 main ， main 不知道返回哪里去，所以，我们直接让 main 结束时进入内核调用 `_exit` 而退出则不会有问题

通过上面的演示和解释发现只要把 return 语句修改为 \_exit 语句，程序即使不链接任何额外的目标代码都可以正常运行（原因是不链接那些额外的文件时相当于没有进行初始化操作，如果在程序的最后执行 ret 汇编指令，程序将无法获得正确的 eip ，从而无法进行后续的动作）。但是为什么会有“找不到 \_start 符号”的警告呢？通过 `readelf -s` 查看 crt1.o 发现里头有这个符号，并且 crt1.o 引用了 main 这个符号，是不是意味着会从 `_start` 进入 main 呢？是不是程序入口是 `_start` ，而并非 main 呢？

### C 语言程序真正的入口

先来看看刚才提到的链接器的默认链接脚本 (`ld -m elf_386 --verbose`) ，它告诉我们程序的入口 (entry) 是 `_start` ，而一个可执行文件必须有一个入口地址才能运行，所以这就是说明了为什么 `ld` 一定要提示我们“ _start 找不到”，找不到以后就给默认设置了一个地址。

    $ ld --verbose  | grep ^ENTRY    #非交叉编译，可不用-m参数；ld默认找_start入口，并不是main哦！
    ENTRY(_start)


原来是这样，程序的入口 (entry) 竟然不是 main 函数，而是 `_start` 。那干脆把汇编里头的 main 给改掉算了，看行不行？

先生成汇编 test.s ：

    $ cat test.c
    #include "test.h"
    #include <unistd.h>     /* _exit */

    int main()
    {
        myprintf();
        _exit(0);
    }
    $ gcc -S test.c


然后把汇编中的 `main` 改为 `_start` ，即改程序入口为 `_start` ：

    $ sed -i -e "s#main#_start#g" test.s
    $ gcc -c test.s myprintf.c


重新链接，发现果然没问题了：

    $ ld -dynamic-linker /lib/ld-linux.so.2 -o test test.o myprintf.o -L/usr/lib/ -lc
    $ ./test
    hello, world!


 `_start` 竟然是真正的程序入口，那在有 main 的情况下呢？为什么在 `_start` 之后能够找到 main 呢？这个看看 alert7 大叔的 [Before main 分析 ][6] 吧，这里不再深入介绍。

总之呢，通过修改程序的return语句为`_exit(0)`和修改程序的入口为`_start`，我们的代码不链接`gcc`默认链接的那些额外的文件同样可以工作得很好。并且打破了一个学习C语言以来的常识：main函数作为程序的主函数，是程序的入口，实际上则不然。

### 链接脚本初次接触

再补充一点内容，在 `ld` 的链接脚本中，有一个特别的关键字 `PROVIDE` ，由这个关键字定义的符号是 `ld` 的预定义字符，我们可以在 C 语言函数中扩展它们后直接使用。这些特别的符号可以通过下面的方法获取，

    $ ld --verbose | grep PROVIDE | grep -v HIDDEN
      PROVIDE (__executable_start = 0x08048000); . = 0x08048000 + SIZEOF_HEADERS;
      PROVIDE (__etext = .);
      PROVIDE (_etext = .);
      PROVIDE (etext = .);
      _edata = .; PROVIDE (edata = .);
      _end = .; PROVIDE (end = .);


这里面有几个我们比较关心的，第一个是程序的入口地址 `__executable_start` ，另外三个是 `etext` ， `edata` ， `end` ，分别对应程序的代码段 (text) 、初始化数据 (data) 和未初始化的数据 (bss) （可参考 `man etext` ），如何引用这些变量呢？看看这个例子。

    /* predefinevalue.c */
    #include <stdio.h>

    extern int __executable_start, etext, edata, end;

    int main(void)
    {
        printf ("program entry: 0x%x n", &__executable_start);
        printf ("etext address(text segment): 0x%x n", &etext);
        printf ("edata address(initilized data): 0x%x n", &edata);
        printf ("end address(uninitilized data): 0x%x n", &end);

        return 0;
    }


到这里，程序链接过程的一些细节都介绍得差不多了。在《动态符号链接的细节》中将主要介绍 ELF 文件的动态符号链接过程。

## 参考资料

  * [Linux 汇编语言开发指南][7]
  * [PowerPC 汇编][8]
  * [用于 Power 体系结构的汇编语言][9]
  * [Linux 中 x86 的内联汇编][10]
  * Linux Assembly HOWTO
  * Linux Assembly Language Programming
  * Guide to Assembly Language Programming in Linux
  * [An beginners guide to compiling programs under Linux][11]
  * [gcc manual][12]
  * [A Quick Tour of Compiling, Linking, Loading, and Handling Libraries on Unix][13]
  * [Unix 目标文件初探][14]
  * [Before main()分析][6]
  * [A Process Viewing Its Own /proc/<PID>/map Information][15]
  * UNIX 环境高级编程
  * Linux Kernel Primer
  * [Understanding ELF using readelf and objdump][16]
  * [Study of ELF loading and relocs][17]
  * ELF file format and ABI, [1][18], [2][19],
  * TN05.ELF.Format.Summary.pdf
  * http://www.xfocus.net/articles/200105/174.html
  * 关于 GCC 方面的论文，请查看历年的会议论文集, [2005][20], [2006][21]
  * [The Linux GCC HOW TO][22]
  * [ELF: From The Programmer&#8217;s Perspective][23]
  * [C/C++ 程序编译步骤详解][24]
  * GNU binutils小结
  * [C 语言常见问题集][25]
  * [使用 BFD 操作ELF][26]
  * [bfd document][27]
  * UNIX/LINUX 平台可执行文件格式分析





 [2]: http://tinylab.org
 [3]: /open-c-book/
 [4]: http://weibo.com/tinylaborg
 [5]: /learn-x86-language-courses-on-the-ubuntu-qemu-cs630/
 [6]: http://www.xfocus.net/articles/200109/269.html
 [7]: http://www.ibm.com/developerworks/cn/linux/l-assembly/index.html
 [8]: http://www.ibm.com/developerworks/cn/linux/hardware/ppc/assembly/index.html
 [9]: http://www.ibm.com/developerworks/cn/linux/l-powasm1.html
 [10]: http://www.ibm.com/developerworks/cn/linux/sdk/assemble/inline/index.html
 [11]: http://www.luv.asn.au/overheads/compile.html
 [12]: http://gcc.gnu.org/onlinedocs/gcc-4.2.2/gcc/
 [13]: http://efrw01.frascati.enea.it/Software/Unix/IstrFTU/cern-cnl-2001-003-25-link.html
 [14]: http://www.ibm.com/developerworks/cn/aix/library/au-unixtools.html
 [15]: http://www.linuxforums.org/forum/linux-kernel/51790-process-viewing-its-own-proc-pid-map-information.html
 [16]: http://www.linuxforums.org/misc/understanding_elf_using_readelf_and_objdump.html
 [17]: http://netwinder.osuosl.org/users/p/patb/public_html/elf_relocs.html
 [18]: http://www.x86.org/ftp/manuals/tools/elf.pdf
 [19]: http://www.muppetlabs.com/~breadbox/software/ELF.txt
 [20]: http://www.gccsummit.org/2005/2005-GCC-Summit-Proceedings.pdf
 [21]: http://www.gccsummit.org/2006/2006-GCC-Summit-Proceedings.pdf
 [22]: http://www.faqs.org/docs/Linux-HOWTO/GCC-HOWTO.html
 [23]: http://linux.jinr.ru/usoft/WWW/www_debian.org/Documentation/elf/elf.html
 [24]: http://www.xxlinux.com/linux/article/development/soft/20070424/8267.html
 [25]: http://c-faq-chn.sourceforge.net/ccfaq/index.html
 [26]: http://elfhack.whitecell.org/mydocs/use_bfd.txt
 [27]: http://sourceware.org/binutils/docs/bfd/index.html
