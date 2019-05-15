---
title: Linux 段错误详解
author: Wu Zhangjin
album: "Debugging+Tracing"
layout: post
permalink: /explore-linux-segmentation-fault/
tags:
  - backtace
  - coredump
  - Segmentation Fault
  - 段错误
  - Linux
categories:
  - catchsegv
  - 调试技巧
  - 稳定性
---

> By Falcon of [TinyLab.org][1]
> 2015/05/12


## 背景

笔者早年写过一篇：《可恶的&#8221;Segmentation faults&#8221;之初级总结篇》，网络转载甚多。多年下来，关于段错误的讨论依旧很热烈，该问题也还是很常见。所以打算在这里再系统地梳理一下该问题的来龙去脉。

## 什么是段错误

下面是来自 Answers.com 的定义：

> A segmentation fault (often shortened to segfault) is a particular error condition that can occur during the operation of computer software. In short, a segmentation fault occurs when a program attempts to access a memory location that it is not allowed to access, or attempts to access a memory location in a way that is not allowed (e.g., attempts to write to a read-only location, or to overwrite part of the operating system). Systems based on processors like the Motorola 68000 tend to refer to these events as Address or Bus errors.
>
> Segmentation is one approach to memory management and protection in the operating system. It has been superseded by paging for most purposes, but much of the terminology of segmentation is still used, &#8220;segmentation fault&#8221; being an example. Some operating systems still have segmentation at some logical level although paging is used as the main memory management policy.
>
> On Unix-like operating systems, a process that accesses invalid memory receives the SIGSEGV signal. On Microsoft Windows, a process that accesses invalid memory receives the STATUS\_ACCESS\_VIOLATION exception.

另外，网上还有个基本上对照的中文解释：

> 所谓的段错误就是指访问的内存超出了系统所给这个程序的内存空间，通常这个值是由 gdtr 来保存的，他是一个 48 位的寄存器，其中的 32 位是保存由它指向的 gdt 表，后 13 位保存相应于 gdt 的下标，最后 3 位包括了程序是否在内存中以及程序的在 cpu 中的运行级别,指向的 gdt 是由以 64 位为一个单位的表，在这张表中就保存着程序运行的代码段以及数据段的起始地址以及与此相应的段限和页面交换还有程序运行级别还有内存粒度等等的信息。一旦一个程序发生了越界访问，cpu 就会产生相应的异常保护，于是 segmentation fault 就出现了

通过上面的解释，段错误应该就是访问了不可访问的内存，这个内存区要么是不存在的，要么是受到系统保护的。

## 段错误日志分析

### 例子

一个典型的例子是 `scanf` 参数使用错误：

        #include <stdio.h>
        
        int main(int argc, char *argv[])
        {
                int i;
        
                scanf("%d\n", i);
        
                return 0;
        }


文件保存为 `segfault-scanf.c`。其中 `&i` 写成了 `i`。

### 段错误信息

    $ make segfault-scanf
    $ ./segfault-scanf
    100
    Segmentation fault (core dumped)


### 段错误分析

    $ catchsegv ./segfault-scanf
    100
    Segmentation fault (core dumped)
    *** Segmentation fault
    Register dump:
    
     RAX: 0000000000000ca0   RBX: 0000000000000040   RCX: 0000000000000010
     RDX: 0000000000000000   RSI: 0000000000000000   RDI: 1999999999999999
     RBP: 00007fffdbdf1010   R8 : 00007fbb45330060   R9 : 0000000000000000
     R10: 0000000000000ca0   R11: 0000000000000000   R12: 0000000000000004
     R13: 0000000000000000   R14: 00007fbb45330640   R15: 000000000000000a
     RSP: 00007fffdbdf0c20
    
     RIP: 00007fbb44fc761a   EFLAGS: 00010212
    
     CS: 0033   FS: 0000   GS: 0000
    
     Trap: 0000000e   Error: 00000006   OldMask: 00000000   CR2: 00000000
    
     FPUCW: 0000037f   FPUSW: 00000000   TAG: 00000000
     RIP: 00000000   RDP: 00000000
    
     ST(0) 0000 0000000000000000   ST(1) 0000 0000000000000000
     ST(2) 0000 0000000000000000   ST(3) 0000 0000000000000000
     ST(4) 0000 0000000000000000   ST(5) 0000 0000000000000000
     ST(6) 0000 0000000000000000   ST(7) 0000 0000000000000000
     mxcsr: 1f80
     XMM0:  00000000000000000000000000000000 XMM1:  00000000000000000000000000000000
     XMM2:  00000000000000000000000000000000 XMM3:  00000000000000000000000000000000
     XMM4:  00000000000000000000000000000000 XMM5:  00000000000000000000000000000000
     XMM6:  00000000000000000000000000000000 XMM7:  00000000000000000000000000000000
     XMM8:  00000000000000000000000000000000 XMM9:  00000000000000000000000000000000
     XMM10: 00000000000000000000000000000000 XMM11: 00000000000000000000000000000000
     XMM12: 00000000000000000000000000000000 XMM13: 00000000000000000000000000000000
     XMM14: 00000000000000000000000000000000 XMM15: 00000000000000000000000000000000
    
    Backtrace:
    /lib/x86_64-linux-gnu/libc.so.6(_IO_vfscanf+0x303a)[0x7fbb44fc761a]
    /lib/x86_64-linux-gnu/libc.so.6(__isoc99_scanf+0x109)[0x7fbb44fce399]
    ??:?(main)[0x400587]
    /lib/x86_64-linux-gnu/libc.so.6(__libc_start_main+0xf5)[0x7fbb44f91ec5]
    ??:?(_start)[0x400499]
    
    Memory map:
    
    00400000-00401000 r-xp 00000000 08:09 2903814 segfault-scanf
    00600000-00601000 r--p 00000000 08:09 2903814 segfault-scanf
    00601000-00602000 rw-p 00001000 08:09 2903814 segfault-scanf
    01b98000-01bbd000 rw-p 00000000 00:00 0 [heap]
    7fbb44d5a000-7fbb44d70000 r-xp 00000000 08:02 1710807 /lib/x86_64-linux-gnu/libgcc_s.so.1
    7fbb44d70000-7fbb44f6f000 ---p 00016000 08:02 1710807 /lib/x86_64-linux-gnu/libgcc_s.so.1
    7fbb44f6f000-7fbb44f70000 rw-p 00015000 08:02 1710807 /lib/x86_64-linux-gnu/libgcc_s.so.1
    7fbb44f70000-7fbb4512b000 r-xp 00000000 08:02 1731685 /lib/x86_64-linux-gnu/libc-2.19.so
    7fbb4512b000-7fbb4532b000 ---p 001bb000 08:02 1731685 /lib/x86_64-linux-gnu/libc-2.19.so
    7fbb4532b000-7fbb4532f000 r--p 001bb000 08:02 1731685 /lib/x86_64-linux-gnu/libc-2.19.so
    7fbb4532f000-7fbb45331000 rw-p 001bf000 08:02 1731685 /lib/x86_64-linux-gnu/libc-2.19.so
    7fbb45331000-7fbb45336000 rw-p 00000000 00:00 0
    7fbb45336000-7fbb4533a000 r-xp 00000000 08:02 1731696 /lib/x86_64-linux-gnu/libSegFault.so
    7fbb4533a000-7fbb45539000 ---p 00004000 08:02 1731696 /lib/x86_64-linux-gnu/libSegFault.so
    7fbb45539000-7fbb4553a000 r--p 00003000 08:02 1731696 /lib/x86_64-linux-gnu/libSegFault.so
    7fbb4553a000-7fbb4553b000 rw-p 00004000 08:02 1731696 /lib/x86_64-linux-gnu/libSegFault.so
    7fbb4553b000-7fbb4555e000 r-xp 00000000 08:02 1731686 /lib/x86_64-linux-gnu/ld-2.19.so
    7fbb45729000-7fbb4572c000 rw-p 00000000 00:00 0
    7fbb4575a000-7fbb4575d000 rw-p 00000000 00:00 0
    7fbb4575d000-7fbb4575e000 r--p 00022000 08:02 1731686 /lib/x86_64-linux-gnu/ld-2.19.so
    7fbb4575e000-7fbb4575f000 rw-p 00023000 08:02 1731686 /lib/x86_64-linux-gnu/ld-2.19.so
    7fbb4575f000-7fbb45760000 rw-p 00000000 00:00 0
    7fffdbdd2000-7fffdbdf3000 rw-p 00000000 00:00 0
    7fffdbdfe000-7fffdbe00000 r-xp 00000000 00:00 0 [vdso]
    ffffffffff600000-ffffffffff601000 r-xp 00000000 00:00 0 [vsyscall]


上述日志包含了寄存器、回调以及内存映像信息。其中回调部分的 `_IO_vfscanf` 即指出了 `scanf` 的问题。不过咋一看不明显，可以用 `gdb` 单步跟踪进行确认。

关于寄存器我们最关心的信息：

    Trap: 0000000e   Error: 00000006


从 `arch/x86/include/asm/traps.h` 和 `arch/x86/kernel/traps.c` 找到 `SIGSEGV` 的类型有：

    /* Interrupts/Exceptions */
    enum {
            ...
            X86_TRAP_OF,            /*  4, Overflow */
            X86_TRAP_BR,            /*  5, Bound Range Exceeded */
            X86_TRAP_TS,            /* 10, Invalid TSS */
            X86_TRAP_GP,            /* 13, General Protection Fault */
            X86_TRAP_PF,            /* 14, Page Fault */
            ...
    }


Trap 为 0xe，即 14，也就是 Page Fault。

而 `arch/x86/mm/fault.c` 则详细解释了错误码（Error）：

    /*
     * Page fault error code bits:
     *
     *   bit 0 ==    0: no page found       1: protection fault
     *   bit 1 ==    0: read access         1: write access
     *   bit 2 ==    0: kernel-mode access  1: user-mode access
     *   bit 3 ==                           1: use of reserved bit detected
     *   bit 4 ==                           1: fault was an instruction fetch
     */
    enum x86_pf_error_code {
    
            PF_PROT         =               1 << 0,
            PF_WRITE        =               1 << 1,
            PF_USER         =               1 << 2,
            PF_RSVD         =               1 << 3,
            PF_INSTR        =               1 << 4,
    };


上面的错误码：6，二进制为 110 即：

  * 1: user-mode access
  * 1: write access
  * 0: no page found

也可以用 [在线查看工具][2]，例如，输入错误码 6 即可获得：

> The cause was a user-mode write resulting in no page being found.

## 常见段错误举例

这里列举一下常见的段错误例子。

### scanf 参数：把 &i 写为 i

    int i;
    scanf("%d", i);


**分析**：i 被定义后，数值是不确定的，而 scanf 把 i 的值当作参数传入 scanf，而 scanf 则会把 i 当成了地址，把用户输入的内容存入该处。而该地址因为随机，可能根本就不存在或者不合法。

### sprintf/printf 参数：%d/%c 写成 %s

    int i = 10;
    printf("%s", i);


**分析**：打印字串时，实际上是打印某个地址开始的所有字符，而这里把整数作为参数传递过去，这个整数被当成了一个地址，然后 printf 从这个地址开始打印字符，直到某个位置上的值为 \0。如果这个整数代表的地址不存在或者不可访问，自然也是访问了不该访问的内存 —— segmentation fault。

### 数组访问越界

    char test[1];
    printf("%c", test[1000000000]);


**注**：也可能报告为 Bus Error，可能存在对未对齐的地址读或写。

### 写只读内存

    char *ptr = "test";
    strcpy(ptr, "TEST");


**分析**：ptr 被定义成了 "test"，是一个只读的内存段，不能直接写入，要写入需要用 malloc 从堆中分配或者定义成一个字符串数组。

### 堆栈溢出

    void main()
    {
        main();
    }


**分析**：上面实际上是一个死循环的递归调用，会造成堆栈溢出。

### pthread_create() 失败后 pthread_join()

    #define THREAD_MAX_NUM
    pthread_t thread[THREAD_MAX_NUM];


**分析**：用 pthread\_create() 创建了各个线程，然后用 pthread\_join() 来等待线程的结束。刚开始直接等待，在创建线程都成功时，pthread\_join() 能顺利等到各个线程结束，但是一旦创建线程失败，用 pthread\_join() 来等待那个本不存在的线程时自然会存在未知内存的情况，从而导致段错误的发生。解决办法是：在创建线程之前，先初始化线程数组，在等待线程结束时，判断线程是否为初始值，如果是的话，说明线程并没有创建成功，所以就不能等拉。

### 小结

综上所有例子，

  * 定义了指针后记得初始化，在使用时记得判断是否为 NULL
  * 在使用数组时记得初始化，使用时要检查数组下标是否越界，数组元素是否存在等
  * 在变量处理时变量的格式控制是否合理等

其他的就需要根据经验不断积累，更多例子会不断追加到上述列表中。

另外，也务必掌握一些基本的分析和调试手段，即使在遇到新的这类问题时也知道如何应对。

## 分析和调试手段

分析方法除了最简便的 `catchsegv` 外，还有诸多办法，它们的应用场景各异。

### catchsegv 原理

该工具就是用来扑获段错误的，它通过动态加载器（ld-linux.so）的预加载机制（PRELOAD）把一个事先写好的库（/lib/libSegFault.so）加载上，用于捕捉断错误的出错信息。

### gdb 调试

    gdb ./segfault-scanf
    ...
    Reading symbols from ./segfault-scanf...done.
    (gdb) r
    Starting program: segfault-scanf
    100

    Program received signal SIGSEGV, Segmentation fault.
    0x00007ffff7a6b61a in _IO_vfscanf_internal (s=<optimized out>,
        format=<optimized out>, argptr=argptr@entry=0x7fffffffddc8,
        errp=errp@entry=0x0) at vfscanf.c:1857
    1857    vfscanf.c: No such file or directory.
    (gdb) bt
    #0  0x00007ffff7a6b61a in _IO_vfscanf_internal (s=<optimized out>,
        format=<optimized out>, argptr=argptr@entry=0x7fffffffddc8,
        errp=errp@entry=0x0) at vfscanf.c:1857
    #1  0x00007ffff7a72399 in __isoc99_scanf (format=<optimized out>)
        at isoc99_scanf.c:37
    #2  0x0000000000400580 in main ()


### coredump 分析

    $ ulimit -c 1024
    $ gdb segfault-scanf ./core
    Reading symbols from segfault-scanf...done.
    [New LWP 16913]
    Core was generated by `./segfault-scanf'.
    Program terminated with signal SIGSEGV, Segmentation fault.
    #0  0x00007fd2d24ec61a in _IO_vfscanf_internal (s=<optimized out>,
        format=<optimized out>, argptr=argptr@entry=0x7fff14dfa668,
        errp=errp@entry=0x0) at vfscanf.c:1857
    1857    vfscanf.c: No such file or directory.


### 程序内捕获 SIGSEGV 信号并启动 gdb 

    #include <stdio.h>
    #include <stdlib.h>
    #include <signal.h>
    #include <string.h>
    
    void dump(int signo)
    {
            char buf[1024];
            char cmd[1024];
            FILE *fh;
    
            snprintf(buf, sizeof(buf), "/proc/%d/cmdline", getpid());
            if(!(fh = fopen(buf, "r")))
                    exit(0);
            if(!fgets(buf, sizeof(buf), fh))
                    exit(0);
            fclose(fh);
            if(buf[strlen(buf) - 1] == '\n')
                    buf[strlen(buf) - 1] = '\0';
            snprintf(cmd, sizeof(cmd), "gdb %s %d", buf, getpid());
            system(cmd);
    
            exit(0);
    }
    
    int main(int argc, char *argv[])
    {
            int i;
    
            signal(SIGSEGV, &dump);
            scanf("%d\n", i);
    
            return 0;
    }


用法如下：

    $ gcc -g -rdynamic -o segfault-scanf segfault-scanf.c
    $ sudo ./segfault-scanf
    100
    (gdb) bt
    #0  0x00007fb743e065cc in __libc_waitpid (pid=16988,
        stat_loc=stat_loc@entry=0x7fffb51d8fe0, options=options@entry=0)
        at ../sysdeps/unix/sysv/linux/waitpid.c:31
    #1  0x00007fb743d8b1d2 in do_system (line=<optimized out>)
        at ../sysdeps/posix/system.c:148
    #2  0x0000000000400ba1 in dump (signo=11) at segfault-scanf.c:21
    #3  <signal handler called>
    #4  0x00007fb743d9c61a in _IO_vfscanf_internal (s=<optimized out>,
        format=<optimized out>, argptr=argptr@entry=0x7fffb51da318,
        errp=errp@entry=0x0) at vfscanf.c:1857
    #5  0x00007fb743da3399 in __isoc99_scanf (format=<optimized out>)
        at isoc99_scanf.c:37
    #6  0x0000000000400bdd in main (argc=1, argv=0x7fffb51da508)
        at segfault-scanf.c:31


### 程序内捕获 SIGSEGV 信号并调用 backtrace 获取回调

    #include <stdio.h>
    #include <stdlib.h>
    #include <signal.h>
    #include <string.h>
    
    void dump(int signo)
    {
            void *array[10];
            size_t size;
            char **strings;
            size_t i;
    
            size = backtrace (array, 10);
            strings = backtrace_symbols (array, size);
    
            printf ("Obtained %zd stack frames.\n", size);
    
            for (i = 0; i < size; i++)
                    printf ("%s\n", strings[i]);
    
            free (strings);
    
            exit(0);
    }
    
    int main(int argc, char *argv[])
    {
            int i;
    
            signal(SIGSEGV, &dump);
            scanf("%d\n", i);
    
            return 0;
    }


用法如下：

    $ ./segfault-scanf
    100
    Obtained 7 stack frames.
    ./segfault-scanf() [0x40077e]
    /lib/x86_64-linux-gnu/libc.so.6(+0x36c30) [0x7f249fa43c30]
    /lib/x86_64-linux-gnu/libc.so.6(_IO_vfscanf+0x303a) [0x7f249fa6461a]
    /lib/x86_64-linux-gnu/libc.so.6(__isoc99_scanf+0x109) [0x7f249fa6b399]
    ./segfault-scanf-call-backtrace() [0x400837]
    /lib/x86_64-linux-gnu/libc.so.6(__libc_start_main+0xf5) [0x7f249fa2eec5]
    ./segfault-scanf-call-backtrace() [0x400699]


除此之外，还可以通过 `dmesg` 查看内核信息并通过 `objdump` 或者 `addr2line` 把 IP 地址转化为代码行，不过用法没有 `catchsegv` 来得简单。`dmesg` 获取的内核信息由 `arch/x86/mm/fault.c: show_signal_msg()` 打印。

## 总结

段错误是 Linux 下 C 语言开发常见的 Bug，本文从原理、案例、分析和调试方法等各个方面进行了详细分析，希望有所帮助。

如果希望了解更多，推荐阅读如下参考资料。

## 参考资料

  * [Segmentation Fault in Linux —— 原因与避免][3]
  * [Linux环境下段错误的产生原因及调试方法小结][4]
  * [段错误bug的调试][5]
  * [Segmentation fault][6]
  * [Segmentation fault到底是何方妖孽][7]
  * [linux内核之trap.c文件分析][8]
  * [linux内核中断、异常][9]
  * [linux下X86架构IDT解析][10]
  * [Segmentation fault error decoder][2]
  * [Understanding a Kernel Oops!][11]





 [1]: http://tinylab.org
 [2]: http://rgeissert.blogspot.hk/p/segmentation-fault-error.html
 [3]: http://www.cnblogs.com/no7dw/archive/2013/02/20/2918372.html
 [4]: http://www.cnblogs.com/panfeng412/archive/2011/11/06/2237857.html
 [5]: http://www.cnblogs.com/joeblackzqq/archive/2011/04/11/2012318.html
 [6]: http://en.wikipedia.org/wiki/Segmentation_fault
 [7]: http://blog.chinaunix.net/uid-23069658-id-3959636.html
 [8]: http://www.programgo.com/article/6924888628/
 [9]: http://blog.csdn.net/bullbat/article/details/7097213
 [10]: http://blog.chinaunix.net/uid-27717694-id-3942170.html
 [11]: http://www.opensourceforu.com/2011/01/understanding-a-kernel-oops/
