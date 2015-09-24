---
title: Linux 系统调用
author: Wen Pingbo
layout: post
permalink: /linux-system-calls/
views:
  - 442
tags:
  - syscall
  - vdso
  - vsyscall
categories:
  - Debug, Trace and Profile
  - Linux
  - Reliability, Availability, Serviceability
---

> by Pingbo Wen of [TinyLab.org][1]
> 2013/09/12

系统调用是系统内核提供给用户态程序的一系列 API ，这样应用程序就可以通过[系统调用][10]来请求操作系统内核管理的资源。本文尝试分析在 Linux 下是如何使用 linux 内核给我们提供的 API ，并分析其实现过程。

## 一、用户态

不管我们是打开一个文件，接收一个 socket 包，还是获取当前进程信息，都需要调用内核给我们提供的 API 。这里，我们可以通过 strace 这个工具，来跟踪一个程序调用的系统函数。比如下面是命令 "strace whoami" 的输出结果：

    execve("/usr/bin/whoami", ["whoami"], [/* 65 vars */]) = 0
    brk(0)                                  = 0x100f000
    access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)
    mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f8398cb2000
    ...
    open("/usr/lib/locale/locale-archive", O_RDONLY|O_CLOEXEC) = 3
    fstat(3, {st_mode=S_IFREG|0644, st_size=7212544, ...}) = 0
    mmap(NULL, 7212544, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f8397ff2000
    close(3)                                = 0
    geteuid()                               = 1000
    ...
    open("/etc/passwd", O_RDONLY|O_CLOEXEC) = 3
    lseek(3, 0, SEEK_CUR)                   = 0
    ...

我们发现 whoami 首先调用 getuid 来获取当前有效用户 ID ，然后打开 "/etc/passwd" 文件，利用之前获取到的用户 ID 来获取对应的用户名，最后打印到当前终端上。

在这个过程中，就调用了 execve, open, geteuid, read, write 等系统调用。一个系统调用就意味着一次用户态到内核态的切换，并且每一个系统调用都会和一个内核中的函数相对应。这里我们就以 geteuid 这个系统调用为例，来跟踪整个系统调用关系。

首先，我们先自己实现一个调用 geteuid 的小程序，代码如下：

    #include <sys/types.h>

    int main(void)
    {
        printf("current uid: %dn", geteuid());
        return 0;
    }

编译执行后，我这里得到的结果是 1000 ，也就是当前用户 id 为 1000 。

然后，通过查看 /usr/include/unistd.h 头文件，我们知道 geteuid 的实现在 libc 中。那么我们可以先反汇编一下 libc 这个库，这里写了一个脚本来从一个共享库中反汇编指定的函数，脚本如下：

    #file: dfunc

    ########################
    # Global function
    ########################
    error()
    {
        echo "$1"
        exit 1
    }

    show_usage()
    {
        echo "This is a script to disassemble specified function in a shared library."
        echo "Author: WEN Pingbo wengpingbo@gmail.com"
        echo "Date: 2013/09/11"
        echo "Usage: ./dfunc [-f function name] [-l library path] [-c shift number]"
        echo "Note: sometimes, you should using -c to disassemble more bytes because of alignments."
    }

    ########################
    # Global function
    ########################

    # default value
    func_name="fexecve"
    target="/lib/x86_64-linux-gnu/libc-2.15.so"
    caliberation="0"

    if [ -n "$1" ] && [ "$1" == "-h" ];then
        show_usage
        exit 0
    fi

    # parse the argument
    arg_ok="0"
    while [ -n "$1" ]
    do
    if [ "$1" == "-f" ];then
        shift
        arg_ok="1"
        if [ -n "$1" ];then
            func_name="$1"
            shift
        fi
    fi

    if [ "$1" == "-l" ];then
        shift
        arg_ok="1"
        if [ -n "$1" ];then
            target="$1"
            shift
        fi
    fi

    if [ "$1" == "-c" ];then
        shift
        arg_ok="1"
        if [ -n "$1" ];then
            caliberation="$1"
            shift
        fi
    fi

    [ "$arg_ok" == "0" ] && shift
    arg_ok="0"
    done

    offset=`readelf -s "$target" | grep " "$func_name"" | awk '{print $3}'`

    [ -z "$offset" ] && error ""$func_name" not found..."

    offset=$(($offset + $caliberation))

    # convert dec to hex
    offset=`echo "obase=16; ibase=10; "$offset"" | bc`

    begin=`nm -D "$target" | grep " "$func_name"$" | awk '{print $1}'`
    end=`echo "obase=16; ibase=16; ${begin^^} + ${offset^^}" | bc`

    objdump -d --start-address=0x"$begin" --stop-address=0x"$end" "$target"

运行这个脚本：

我们发现这个函数的反汇编指令很简单：

    syscall
    retq

先把 0x6b 放到寄存器 eax 中，然后就执行一个 syscall 的指令。最后是返回指令。

syscall 是什么指令？这里的 syscall 指令就是在 x86 架构下，专门为系统调用准备的指令（ SYSCALL/SYSENTER and SYSRET/SYSEXIT ）。

那 0x6b 又是什么？这是系统调用号，用来区分其他的系统调用。现在我们只是看到了反汇编的代码，而这些系统调用的真真实现可以在 [glibc][2] 的源码中找到。其实在 glibc 中并没有去实现系统调用，而是对不同系统内核的系统调用的 wrapper 。在 sysdeps/unix/sysv/linux/syscalls.list 下，就列出了 linux 下面所有的系统调用，部分如下：

    getegid     -   getegid     Ei: __getegid   getegid
    geteuid     -   geteuid     Ei: __geteuid   geteuid
    getpgid     -   getpgid     i:i __getpgid   getpgid

这个文件指定了每一个系统调用对应的内部实现函数名，以及对应的文件名。在编译 glibc 的时候， syscalls.list 文件会被 sysdep/unix/make-syscalls.sh 脚本处理，这个脚本会利用 sysdeps/unix/syscall-template.S 这个模板文件，来生成每一个系统调用 [wrapper][3] 的汇编代码，最后生成我们刚才反汇编的那样的代码。

现在我们知道 geteuid() 函数最后调用的是一个 syscall 指令。那么我们能不能跳过 glibc 的 wrapper ，直接调用 linux 内核的系统调用呢？在以前的老版本内核中，确实提供了 `_syscall` ， `_syscall0` 等宏，但是现在已经没有了。只保留了 glibc 中给我们提供的 syscall 函数，其函数声明在 /usr/include/unistd.h 文件中，原型如下：

我们可以通过 syscall 来实现和之前一样的效果，代码如下：

    #include <unistd.h>
    #include <sys/syscall.h>   /* For SYS_xxx definitions */

    int main(void)
    {
        printf("current uid: %dn", syscall(107));
        return 0;
    }

这里， 107 就是我们刚才在反汇编代码中看到的 0x6b 。而这些系统调用也在头文件 `/usr/include/asm/unistd_64.h` 中找到，如果我们包含文件，我们可以通过 `syscall(__NR_geteuid)` 来实现和之前一样的效果，但是更直观一点。

如果我们想完全跳过 glibc ，我们可以写一个汇编代码：

    section .text
    global _start

    _start:
        mov rax,107
        syscall ;invoke geteuid()
        mov rdi,0 ;return value
        mov rax,60 ; _exit syscall
        syscall

我们可以通过如下命令，来编译执行：

    ld -s -o test test.o
    strace ./test

由于并没有调用输出函数，所以我们只能通过 strace 来跟踪具体的系统调用，运行后，输出如下：

    geteuid()                               = 1000
    _exit(0)                                = ?

可以看到，通过 syscall 调用了 geteuid 系统调用，并返回了正确的结果。

要注意的是，这里的实现是 64 位的版本， 32 位的 linux 系统调用号和 64 位的是不一样的，具体可以通过 `/usr/include/asm/unistd_32.h` 来获取具体的系统调用号。并且 32 位下面是用 int 0x80 软件中断来实现系统调用的分发，而 64 位是通过 syscall 指令来实现的。

## 二、内核态

现在，我们已经知道了用户态程序是如何调用 linux 内核提供的系统调用，但是真真的实现却是在 kernel 中。所以现在我们要进入 kernel 源码，来分析具体系统调用实现，最后我们还要往 kernel 中添加我们自己的系统调用。

这里还是以 geteuid 为例。

以前的 linux kernel 的系统调用是在 `arch/$(arch)/kernel/syscall_table.S` 文件定义的，但是在 3.2 以后，就已经改变了，相关 patch 可以到 [lkml.org][4] 中找到 。 x86 下最新的 syscall 定义在 arch/x86/syscalls 中。其中的 `syscall_64.tbl` 就是 64 位下所有的系统调用表，部分如下：

    106 common  setgid          sys_setgid
    107 common  geteuid         sys_geteuid
    108 common  getegid         sys_getegid
    109 common  setpgid         sys_setpgid
    110 common  getppid         sys_getppid

我们可以发现 geteuid 的系统调用号和之前是一致的。而在编译的时候，就会通过 syscallhdr.sh 和 syscalltbl.sh 两个脚本读入对应的系统调用表，来生成 unistd_64.h 和其他头文件。而这些文件，就是我们刚才在系统里看到的。

通过 syscall_64.tbl 文件，我们发现 geteuid 对应的内核函数是 sys_geteuid 。而这个函数的实现是在 kernel/sys.c 文件中，源码如下：

    {
        /* Only we change this so SMP safe */
        return from_kuid_munged(current_user_ns(), current_euid());
    }

其中 SYSCALL_DEFINE0 是一个宏， 0 代表这个函数不带参数。这些宏的定义在 include/linux/syscalls.h 文件中。

知道了一个系统调用的实现，我们就可以利用 kernel 给我们提供的 `SYSCALL_DEFINE` 宏来添加我们自己的函数，并把我们自定义的函数添加到 syscall_64.tbl 文件中就可以了。这里，实现了一个很简单的函数，每次调用，都会返回一个字符串。源码如下：

    {
        char tmp[] = "strings from kernel";
        if(copy_to_user(str, tmp, 19))
            return -EFAULT;

        return 0;
    }

这里函数 mysyscall 带一个参数，注意参数的声明，中间有一个逗号。

然后在 syscall_64.tbl 中添加自己的函数：

    314 common    mysyscall           sys_mysyscall

现在，我们可以编译我们定制的内核，并加载这个内核。然后我们可以在系统中写一个程序，来调用我们自己写的系统调用。源码如下：

    #include <unistd.h>
    #include <sys/syscall.h>   /* For SYS_xxx definitions */
    #include <stdio.h>

    int main(void)
    {
        char str[19];
        syscall(314, str);
        printf("str: %sn", str);
        return 0;
    }

运行这个程序，你应该会看到 "str: strings from kernel" 。

## 三、系统调用加速

现在，我们应该很清楚一个系统调用是怎样从用户程序传递到内核中的。但是，我们知道，从用户态陷入到内核态是一个比较昂贵的切换，如果一个系统中，同时有很多系统调用，这将会严重拖慢整个系统。系统调用的设计初衷就是做为一个系统门卫，只让用户态程序访问它应该访问的资源。但是，有一些系统调用是无害的 ( 比如，获取时间 ) ，如果能够让这些系统调用存在于用户态，那就会极大的减少用户态到内核态的切换，从而提高系统性能。

 Linux kernel 中，有 vdso 和 vsyscall 的机制，用来加速特定的系统调用。两者的基本原理都是把一些特定的系统调用放到一个专门的 page 中，然后把这个 page 映射到用户程序空间，这样用户态程序就可以不用切换到内核态就可以调用这些函数。

如果你用 ldd 查看任意一个动态链接程序的库依赖，你将会发发现每一个程序都会依赖一个 `linux-{vdso, gate}.so.1` 的库，但是这个库却没有任何文件与之想关联。比如，下面是 "ldd /bin/true" 的输出：

    libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f01864b2000)
    /lib64/ld-linux-x86-64.so.2 (0x00007f0186894000)

这里的 linux-vdso.so.1 就是之前所说的 vdso 机制。这个库是内核虚拟的，然后映射到所有用户态进程。你也可以通过查看 /proc/self/maps 查看具体的内存映射，下面是 "cat /proc/self/maps" 的输出：

    0060a000-0060b000 r--p 0000a000 08:03 22020229                           /bin/cat
    0060b000-0060c000 rw-p 0000b000 08:03 22020229                           /bin/cat
    02267000-02288000 rw-p 00000000 00:00 0                                  [heap]
    ...
    7fff31ccc000-7fff31ced000 rw-p 00000000 00:00 0                          [stack]
    7fff31df2000-7fff31df3000 r-xp 00000000 00:00 0                          [vdso]
    ffffffffff600000-ffffffffff601000 r-xp 00000000 00:00 0                  [vsyscall]

这里，你可以看到 vdso 和 vsyscall 的内存映射。需要指出的是 vdso 和 vsyscall 的最大的区别是 vdso 映射到用户态的内存地址是随机的，而 vsyscall 确实固定的。你可以通过运行多次 "cat /proc/self/maps" 来比较它们的地址。

由于 vsyscall 的地址是固定的，这就给内核留下一个巨大的内存溢出漏洞。所以在最新的内核， vsyscall 已经逐渐废除，但是你还是能在很多系统中，看到两者的共存，这只是为了向后兼容罢了。并且最新的内核中， vsyscall 中已经没有任何指令了，取代的是内核的一个 trap ，当以前的老程序调用 vsyscall 里的内容时，会被导向到正常的系统调用。这也是为什么在读取 [vsyscall][5] 的时候，发现里面是空的。

vdso 的具体实现在 arch/x86/vdso 中，其中的 vdso.lds.S 就定义了具体加速的系统调用。你甚至可以往 vdso 添加自定义的函数，具体添加方法见[这里][6] 。

## 参考资料

  * [System Call][10]

[10]: http://en.wikipedia.org/wiki/System_calls

  * [Glibc Wrapper][2]

[2]: https://sourceware.org/glibc/wiki/SyscallWrappers

  * [Syscall][3]

[3]: http://www.ibm.com/developerworks/library/l-system-calls/

  * [Kernel Syscalltbl][4]

[4]: https://lkml.org/lkml/2011/11/17/388

  * [vsyscall vs vdso][5]

[5]: http://lwn.net/Articles/446528/

  * [Customize vdso][6]

[6]: http://www.linuxjournal.com/content/creating-vdso-colonels-other-chicken

 [1]: http://tinylab.org
