---
title: 进程的内存映像
author: Wu Zhangjin
album: C 语言编程透视
layout: post
permalink: /process-memory-image/
tags:
  - 进程
  - 内存映像
categories:
  - C 语言
  - 进程管理
---

> by falcon of [TinyLab.org][2]
> 2008-6-1

**【注】这是开源书籍[《C 语言编程透视》][3]第六章，如果您喜欢该书，请关注我们的新浪微博[@泰晓科技][4]。**

## 前言

在阅读APUE的第14章时，看到一个“打印不同类型的数据所存放的位置”的例子，它非常清晰地从程序内部反应了“进程的内存映像”，通过结合它与《GCC编译的背后》和《缓冲区溢出与注入》的相关内容，可以更好地辅助理解相关的内容。

## 进程内存映像表

首先回顾一下《缓冲区溢出与注入》中提到的&#8221;进程内存映像表&#8221;，并把共享内存的大概位置加入该表：

    地址                            内核空间
    0xC0000000
                          (program flie)程序名           execve的第一个参数
                          (environment)环境变量          execve的第三个参数，main的第三个参数
                          (arguments)参数                execve的第二个参数，main的形参
                          (stack)栈                      自动变量以及每次函数调用时所需保存的信息都
                               |                         存放在此，包括函数返回地址、调用者的
                               |                         环境信息等，函数的参数，局部变量都存放在此
                          (shared memory)共享内存        共享内存的大概位置
                              |/
                              ...
                          (heap)堆                       主要在这里进行动态存储分配，比如malloc,new等。

                          .bss(uninitilized data)        没有初始化的数据（全局变量哦）
                          .data(initilized global data)  已经初始化的全局数据（全局变量）
                          .text(Executable Instructions) 通常是可执行指令
    0x08048000
    0x00000000


## 在程序内部打印内存分布信息

为了能够反应上述内存分布情况，这里在APUE的程序14-11的基础上，添加了一个已经初始化的全局变量（存放在已经初始化的数据段内），并打印了它以及main函数(处在代码正文部分)的位置。

    /**
     * showmemory.c -- print the position of different types of data in a program in the memory
     */

    #include <sys/types.h>
    #include <sys/ipc.h>
    #include <sys/shm.h>
    #include <stdio.h>
    #include <stdlib.h>

    #define ARRAY_SIZE 4000
    #define MALLOC_SIZE 100000
    #define SHM_SIZE 100000
    #define SHM_MODE (SHM_R | SHM_W)    /* user read/write */

    int init_global_variable = 5;    /* initialized global variable */
    char array[ARRAY_SIZE];        /* uninitialized data = bss */

    int main(void)
    {
        int shmid;
        char *ptr, *shmptr;

        printf("main: the address of the main function is %xn", main);
        printf("data: data segment is from %xn", &init_global_variable);
        printf("bss: array[] from %x to %xn", &array[0], &array[ARRAY_SIZE]);
        printf("stack: around %xn", &shmid);   
       
        /* shmid is a local variable, which is stored in the stack, hence, you
         * can get the address of the stack via it*/

        if ( (ptr = malloc(MALLOC_SIZE)) == NULL) {
            printf("malloc error!n");
            exit(-1);
        }
        printf("heap: malloced from %x to %xn", ptr, ptr+MALLOC_SIZE);

        if ( (shmid = shmget(IPC_PRIVATE, SHM_SIZE, SHM_MODE)) < 0) {
            printf("shmget error!n");
            exit(-1);
        }

        if ( (shmptr = shmat(shmid, 0, 0)) == (void *) -1) {
            printf("shmat error!n");
            exit(-1);
        }
        printf("shared memory: attached from %x to %xn", shmptr, shmptr+SHM_SIZE);

        if (shmctl(shmid, IPC_RMID, 0) < 0) {
            printf("shmctl error!n");
            exit(-1);
        }

        exit(0);
    }


该程序的运行结果如下：

    $  make showmemory
    cc     showmemory.c   -o showmemory
    $ ./showmemory
    main: the address of the main function is 804846c
    data: data segment is from 80498e8
    bss: array[] from 8049920 to 804a8c0
    stack: around bfe3e224
    heap: malloced from 804b008 to 80636a8
    shared memory: attached from b7da7000 to b7dbf6a0


上述运行结果反应了几个重要部分数据的大概分布情况，比如data段(那个初始化过的全局变量就位于这里)、bss段、stack、heap，以及shared memory和main（代码段）的内存分布情况。

## 在程序内部获取完整内存分布信息

不过，这些结果还是没有精确和完整地反应所有相关信息，如果要想在程序内完整反应这些信息，结合《GCC编译的背后》，就不难想到，我们还可以通过扩展一些已经链接到可执行文件中的外部符号来获取它们。这些外部符号全部定义在可执行文件的符号表中，可以通过`nm/readelf -s/objdump -t`等查看到，例如：

    $ nm showmemory
    080497e4 d _DYNAMIC
    080498b0 d _GLOBAL_OFFSET_TABLE_
    080486c8 R _IO_stdin_used
             w _Jv_RegisterClasses
    080497d4 d __CTOR_END__
    080497d0 d __CTOR_LIST__
    080497dc d __DTOR_END__
    080497d8 d __DTOR_LIST__
    080487cc r __FRAME_END__
    080497e0 d __JCR_END__
    080497e0 d __JCR_LIST__
    080498ec A __bss_start
    080498dc D __data_start
    08048680 t __do_global_ctors_aux
    08048414 t __do_global_dtors_aux
    080498e0 D __dso_handle
             w __gmon_start__
    0804867a T __i686.get_pc_thunk.bx
    080497d0 d __init_array_end
    080497d0 d __init_array_start
    08048610 T __libc_csu_fini
    08048620 T __libc_csu_init
             U __libc_start_main@@GLIBC_2.0
    080498ec A _edata
    0804a8c0 A _end
    080486a8 T _fini
    080486c4 R _fp_hw
    08048328 T _init
    080483f0 T _start
    08049920 B array
    08049900 b completed.1
    080498dc W data_start
             U exit@@GLIBC_2.0
    08048444 t frame_dummy
    080498e8 D init_global_variable
    0804846c T main
             U malloc@@GLIBC_2.0
    080498e4 d p.0
             U printf@@GLIBC_2.0
             U shmat@@GLIBC_2.0
             U shmctl@@GLIBC_2.2
             U shmget@@GLIBC_2.0


第三列的符号在我们的程序中被扩展以后就可以直接引用，这些符号基本上就已经完整地覆盖了相关的信息了，这样就可以得到一个更完整的程序，从而完全反应上面提到的内存分布表的信息。

    /**
     * showmemory.c -- print the position of different types of data in a program in the memory
     */

    #include <sys/types.h>
    #include <sys/ipc.h>
    #include <sys/shm.h>
    #include <stdio.h>
    #include <stdlib.h>

    #define ARRAY_SIZE 4000
    #define MALLOC_SIZE 100000
    #define SHM_SIZE 100000
    #define SHM_MODE (SHM_R | SHM_W)        /* user read/write */

                                            /* declare the address relative variables */
    extern char _start, __data_start, __bss_start, etext, edata, end;
    extern char **environ;

    char array[ARRAY_SIZE];         /* uninitialized data = bss */

    int main(int argc, char *argv[])
    {
        int shmid;
        char *ptr, *shmptr;

        printf("===== memory map =====n");
        printf(".text:t0x%x->0x%x (_start, code text)n", &_start, &etext);
        printf(".data:t0x%x->0x%x (__data_start, initilized data)n", &__data_start, &edata);
        printf(".bss: t0x%x->0x%x (__bss_start, uninitilized data)n", &__bss_start, &end);

        /* shmid is a local variable, which is stored in the stack, hence, you
         * can get the address of the stack via it*/

        if ( (ptr = malloc(MALLOC_SIZE)) == NULL) {
            printf("malloc error!n");
            exit(-1);
        }

        printf("heap: t0x%x->0x%x (address of the malloc space)n", ptr, ptr+MALLOC_SIZE);

        if ( (shmid = shmget(IPC_PRIVATE, SHM_SIZE, SHM_MODE)) < 0) {
            printf("shmget error!n");
            exit(-1);
        }

        if ( (shmptr = shmat(shmid, 0, 0)) == (void *) -1) {
            printf("shmat error!n");
            exit(-1);
        }
        printf("shm  :t0x%x->0x%x (address of shared memory)n", shmptr, shmptr+SHM_SIZE);

        if (shmctl(shmid, IPC_RMID, 0) < 0) {
            printf("shmctl error!n");
            exit(-1);
        }

        printf("stack:t <--0x%x--> (address of local variables)n", &shmid);   
        printf("arg:  t0x%x (address of arguments)n", argv);
        printf("env:  t0x%x (address of environment variables)n", environ);

        exit(0);
    }


运行结果：

    $ make showmemory
    $ ./showmemory
    ===== memory map =====
    .text:    0x8048440->0x8048754 (_start, code text)
    .data:    0x8049a3c->0x8049a48 (__data_start, initilized data)
    .bss:     0x8049a48->0x804aa20 (__bss_start, uninitilized data)
    heap:     0x804b008->0x80636a8 (address of the malloc space)
    shm  :    0xb7db6000->0xb7dce6a0 (address of shared memory)
    stack:     <--0xbff85b64--> (address of local variables)
    arg:      0xbff85bf4 (address of arguments)
    env:      0xbff85bfc (address of environment variables)


## 后记

上述程序完整地勾勒出了进程的内存分布的各个重要部分，这样就可以从程序内部获取跟程序相关的所有数据了，一个非常典型的例子是，在程序运行的过程中检查代码正文部分是否被恶意篡改。

如果想更深地理解相关内容，那么你可以试着利用readelf, objdump等来分析ELF可执行文件格式的结构，并利用gdb来了解程序运行过程中的内存变化情况。

## 参考资料

  * GCC 编译的背后(第二部分：汇编和链接)
  * 缓冲区溢出与注入分析
  * APUE 第 14 章，程序 14-11

 [2]: http://tinylab.org
 [3]: /open-c-book/
 [4]: http://weibo.com/tinylaborg
