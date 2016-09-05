--
layout: post
group: original
title: Linux 汇编语言快速上手：4大架构一块学
author: Wu Zhangjin
permalink: /linux-assembly-language-quick-start/
tags:
  - Linux
  - Qemu-User-Static
  - X86
categories:
  - 汇编
  - ARM
  - MIPS
  - PowerPC
  - X86
  - Qemu
---

> By Falcon of [TinyLab.org][1]
> 2015/05/13


## 前言

万事开头难。如果初次接触，可能会觉得汇编语言很难下手。但现如今，学习汇编语言非常方便，本文就此展开。

## 实验环境

早期学习汇编语言困难，有很大一个原因是没有合适的实验环境：

  * 没有钱买开发板
  * 找不到合适的开发板
  * 有了开发板跑起来也没那么容易

现在学汇编语言根本不需要开发板，可以用 `qemu-user-static` 直接运行各种架构的汇编语言。

以 Ubuntu 为例，Windows 和 Mac 下的用户可以先安装 VirtualBox + Ubuntu，再安装这个。

    sudo apt-get install qemu-user-static


接着安装 gcc。

    sudo apt-get install gcc
    sudo apt-get install gcc-arm-linux-gnueabi gcc-aarch64-linux-gnu
    sudo apt-get install gcc-powerpc-linux-gnu gcc-powerpc64le-linux-gnu


因为 Ubuntu 自带的交叉编译工具不全，可以从 emdebian 项目安装更多交叉编译工具。

    sudo -s
    echo deb http://www.emdebian.org/debian/ wheezy main >> /etc/apt/sources.list.d/emdebian.list
    apt-get install emdebian-archive-keyring
    apt-get update
    wget -c http://archive.ubuntu.com/ubuntu/pool/universe/g/gmp4/libgmp3c2_4.3.2+dfsg-2ubuntu1_amd64.deb
    dpkg -i libgmp3c2_4.3.2+dfsg-2ubuntu1_amd64.deb
    apt-get install gcc-4.3-mipsel-linux-gnu

注：在 ubuntu 14.04 以后找不到 libgmp3c2 这个软件包，导致无法正常安装 emdebian 的工具链，所以上面主动下了一个。

## Hello World

同大多数资料一样，我们也从 Hello World 入手。

学习一个东西比较高效的方式是照猫画虎，咱们先直接从 C 语言生成一个汇编语言程序。

### C 语言版本

先写一个 C 语言的 `hello.c`：

        #include <stdio.h>
        
        int main(int argc, char *argv[])
        {
                printf("Hello World\n");
        
                return 0;
        }


### 汇编语言版本

生成汇编语言：

    gcc -S hello.c


默认会生成 hello.s，可以用 `-o hello-x86_64.s` 指定输出文件名称。

    gcc -S hello.c -o hello-x86_64.s


下面类似地，列出所有 4 个平台 32位 和 64位 汇编语言生成办法。

  * X86

        gcc -m32 -S hello.c -o hello-x86.s
        gcc -S hello.c -o hello-x86_64.s


  * MIPS

        mipsel-linux-gnu-gcc -S hello.c hello-mips.s
        mipsel-linux-gnu-gcc -mabi=64 -S hello.c -o hello-mips64.s


  * ARM

        arm-linux-gnueabi-gcc -S hello.c -o hello-arm.s
        aarch64-linux-gnu-gcc -S hello.c -o hello-arm64.s


  * PowerPC

        powerpc-linux-gnu-gcc -S hello.c -o hello-powerpc.s
        powerpc64le-linux-gnu-gcc -S hello.c -o hello-powerpc64.s


我们就这样轻松地获得了所有平台的第一个可以打印 Hello World 的汇编语言程序：hello-xx.s。

大家可以用 `vim` 等编辑工具打开这些文件试读，读不懂也没关系，我们下一节会结合后续的参考资料做进一步分析。

### 编译汇编语言程序

在进一步分析前，我们演示如何把汇编语言编译成可执行文件。

#### 静态编译

如果要直接在当前系统中运行，简便起见，需要把各类库静态编译进去（X86实际不需要，因为主机本身就是X86平台），可以这么做：

  * X86

        gcc -m32 -o hello-x86 hello-x86.s -static
        gcc -o hello-x86_64 hello-x86_64.s -static


  * MIPS

        mipsel-linux-gnu-gcc -o hello-mips hello-mips.s -static


    <!--        mipsel-linux-gnu-gcc -mabi=64 -Wl,-melf64ltsmip -o hello-mips64 hello-mips64.s -static -->

  * ARM

        arm-linux-gnueabi-gcc -o hello-arm hello-arm.s -static
        aarch64-linux-gnu-gcc -o hello-arm64 hello-arm64.s -static


  * PowerPC

        powerpc-linux-gnu-gcc -o hello-powerpc hello-powerpc.s -static


    <!--        powerpc64le-linux-gnu-gcc -o hello-powerpc64 hello-powerpc64.s -static -->

#### 动态编译

静态编译的缺点是把所有用到的库都默认编译进了可执行文件，会导致编译出来的可执行文件占用较多磁盘，而且在运行时占用更多内存。

所以可以考虑用动态编译。动态编译与静态编译的区别是，动态编译需要有动态库装载和链接器：`ld.so` 或者 `ld-linux.so`，这个工具的路径默认在 `/lib` 下。例如：

    $ ldd hello-x86
    linux-gate.so.1 =>  (0xf76ea000)
    libc.so.6 => /lib/i386-linux-gnu/libc.so.6 (0xf7508000)
    /lib/ld-linux.so.2 (0xf76eb000)
    $ mipsel-linux-gnu-readelf -l hello-mips | grep interpreter
      [Requesting program interpreter: /lib/ld.so.1]


所以，除了 x86 以外，对于相关库都安装在非标准路径下，所以动态编译或者运行时，其他架构需要明确指定库的路径。先通过如下命令获取 `ld.so` 的安装路径：

    $ dpkg -L libc6-mipsel-cross | grep ld.so
    /usr/mipsel-linux-gnu/lib/ld.so.1


发现所有库都安装在 `/usr/ARCH-linux-gnu[eabixx]/lib/` 下面，所以，可以这么执行：

    $ LD_LIBRARY_PATH=/usr/mipsel-linux-gnu/lib/
    $ qemu-mipsel $LD_LIBRARY_PATH/ld.so.1 --library-path $LD_LIBRARY_PATH ./hello-mips

    或者

    $ qemu-mipsel -E LD_LIBRARY_PATH=$LD_LIBRARY_PATH $LD_LIBRARY_PATH/ld.so.1 ./hello-mips


通过上面的方法在 x86 下执行其他架构的程序确实不方便，不过比买开发板划算多了吧。何况咱们还可以写个脚本来替代上面的一长串的命令。

实际上咱们可以更简化一些，可以在编译时指定 `ld.so` 的全路径：

    $ mipsel-linux-gnueabi-gcc -Wl,--dynamic-linker=/usr/mipsel-linux-gnueabi/lib/ld.so.1 -o hello hello.c
    $ readelf -l hello | grep interpreter
      [Requesting program interpreter: /usr/arm-linux-gnueabi/lib/ld-linux.so.3]
    $ qemu-mipsel -E LD_LIBRARY_PATH=$LD_LIBRARY_PATH ./hello-mips


不过这种方法也不是那么靠谱。

可选的办法是，用 `debootstrap` 安装一个完整的支持其他架构的文件系统，然后把 `/usr/bin/qemu-XXX-static` 拷贝到目标文件系统的 `/usr/bin` 下，然后 `chroot` 过去使用。这里不做进一步介绍了。

### 汇编语言分析

上面介绍了如何快速获得一个可以打印 Hello World 的汇编语言程序。不过咋一看，简直是天书。

作为快速上手，咱们也没有过多篇幅来介绍太多的背景，因为涉及的背景实在太多。会涉及到：

  * [ELF][2] 可执行文件格式以及各类 Sections
  * [函数调用约定 ABI][3]，包括参数传递，栈操作，返回地址处理等
  * [各种 gas 伪指令][4]
  * [库函数的动态链接][5]

这些内容是不可能在几百文字里头描述清楚的，所以干脆跳过交给同学们自己参考后续资料后再回过头来阅读。咱们进入下一节，看看更简单的实现。

## 进阶学习

如果是简单打印 Hello World，咱们其实可以不用调用库函数，可以直接调用系统调用 `sys_write`。`sys_write` 是一个标准的 Posix 系统调用，各平台都支持。参数完全一致，不过各平台的系统调用号可能有差异：

    ssize_t write(int fd, const void *buf, size_t count);


系统调用号基本都定义在：`arch/ARCH/include/asm/unistd.h`。例如：

    $ grep __NR_write -ur arch/mips/include/asm/
    arch/mips/include/asm/unistd.h:#define __NR_write           (__NR_Linux +   4)


而 _\_NR\_Linux 为 4000：

     $ grep __NR_Linux -ur arch/mips/include/asm/ -m 1
     arch/mips/include/asm/unistd.h:#define __NR_Linux          4000


所以，在 MIPS 上，系统调用号为 4004，具体看后面的例子。

下面来看看简化后的例子，例子全部摘自后文的参考资料。

### X86

    .data                   # section declaration
    msg:
        .string "Hello, world!\n"
        len = . - msg   # length of our dear string
    .text                   # section declaration
                            # we must export the entry point to the ELF linker or
        .global _start      # loader. They conventionally recognize _start as their
                            # entry point. Use ld -e foo to override the default.
    _start:
    # write our string to stdout
        movl    $len,%edx   # third argument: message length
        movl    $msg,%ecx   # second argument: pointer to message to write
        movl    $1,%ebx     # first argument: file handle (stdout)
        movl    $4,%eax     # system call number (sys_write)
        int     $0x80       # call kernel
    # and exit
        movl    $0,%ebx     # first argument: exit code
        movl    $1,%eax     # system call number (sys_exit)
        int     $0x80       # call kernel


编译和链接：

    $ as -o ia32-hello.o ia32-hello.s
    $ ld -o ia32-hello ia32-hello.o


### MIPS

    # File: hello.s -- "hello, world!" in MIPS Assembly Programming
    # by falcon <wuzhangjin@gmail.com>, 2008/05/21
    # refer to:
    #    [*] http://www.tldp.org/HOWTO/Assembly-HOWTO/mips.html
    #    [*] MIPS Assembly Language Programmer’s Guide
    #    [*] See MIPS Run Linux(second version)
    # compile:
    #       $ as -o hello.o hello.s
    #       $ ld -e main -o hello hello.o
    
    # data section
    .rdata
    hello: .asciiz "hello, world!\n"
    length: .word . - hello            # length = current address - the string address
    
    # text section
    .text
    .globl main
    main:
        # if compiled with gcc-4.2.3 in 2.6.18-6-qemu the following three statements are needed
    
        .set noreorder
        .cpload $t9
        .set reorder
    
                # there is no need to include regdef.h in gcc-4.2.3 in 2.6.18-6-qemu
                # but you should use $a0, not a0, of course, you can use $4 directly
    
                # print "hello, world!" with the sys_write system call,
                # -- ssize_t write(int fd, const void *buf, size_t count);
        li $a0, 1    # first argumen: the standard output, 1
        la $a1, hello    # second argument: the string addr
        lw $a2, length  # third argument: the string length
        li $v0, 4004    # sys_write: system call number, defined as __NR_write in /usr/include/asm/unistd.h
        syscall        # causes a system call trap.
    
                # exit from this program via calling the sys_exit system call
        move $a0, $0    # or "li $a0, 0", set the normal exit status as 0
                # you can print the exit status with "echo $?" after executing this program
        li $v0, 4001    # 4001 is __NR_exit defined in /usr/include/asm/unistd.h
        syscall


编译和链接：

    $ mipsel-linux-gnu-as -o mipsel-hello.o mipsel-hello.s
    $ mipsel-linux-gnu-ld -o mipsel-hello mipsel-hello.o


### ARM

#### ARM32

    .data
    
    msg:
        .ascii      "Hello, ARM!\n"
    len = . - msg
    
    
    .text
    
    .globl _start
    _start:
        /* syscall write(int fd, const void *buf, size_t count) */
        mov     %r0, $1     /* fd -> stdout */
        ldr     %r1, =msg   /* buf -> msg */
        ldr     %r2, =len   /* count -> len(msg) */
        mov     %r7, $4     /* write is syscall #4 */
        swi     $0          /* invoke syscall */
    
        /* syscall exit(int status) */
        mov     %r0, $0     /* status -> 0 */
        mov     %r7, $1     /* exit is syscall #1 */
        swi     $0          /* invoke syscall */
    
    
    编译和链接：
    
        $ arm-linux-gnueabi-as -o arm-hello.o arm-hello.s
        $ arm-linux-gnueabi-ld -o arm-hello arm-hello.o
    
    
    #### ARM64
    
    .text //code section
    .globl _start
    _start:
        mov x0, 0     // stdout has file descriptor 0
        ldr x1, =msg  // buffer to write
        mov x2, len   // size of buffer
        mov x8, 64    // sys_write() is at index 64 in kernel functions table
        svc #0        // generate kernel call sys_write(stdout, msg, len);
    
        mov x0, 123 // exit code
        mov x8, 93  // sys_exit() is at index 93 in kernel functions table
        svc #0      // generate kernel call sys_exit(123);
    
    .data //data section
    msg:
        .ascii      "Hello, ARM!\n"
    len = . - msg


编译和链接：

    aarch64-linux-gnu-as -o aarch64-hello.o aarch64-hello.s
    aarch64-linux-gnu-ld -o aarch64-hello aarch64-hello.o
