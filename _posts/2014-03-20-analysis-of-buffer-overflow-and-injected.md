---
title: 缓冲区溢出与注入分析
author: Wu Zhangjin
album: C 语言编程透视
layout: post
permalink: /analysis-of-buffer-overflow-and-injected/
tags:
  - 缓冲区溢出，缓冲区注入，C 语言编程透视，内存映像
categories:
  - C
  - X86
---

> by falcon of [TinyLab.org][2]
> 2008-2-13

**【注】这是开源书籍[《C 语言编程透视》][3]第五章，如果您喜欢该书，请关注我们的新浪微博[@泰晓科技][4]。**

## 前言

虽然程序加载以及动态符号链接都已经很理解了，但是这伙却被进程的内存映像给”纠缠&#8221;住。看着看着就一发不可收拾——很有趣。

下面一起来探究“缓冲区溢出和注入”问题（主要是关心程序的内存映像）。

## 进程的内存映像

永远的Hello World，太熟悉了吧，

    #include <stdio.h>
    int main(void)
    {
        printf("Hello Worldn");
        return 0;
    }


如果要用内联汇编(inline assembly)来写呢？

     1  /* shellcode.c */
     2  void main()
     3  {
     4      __asm__ __volatile__("jmp forward;"
     5                   "backward:"
     6                           "popl   %esi;"
     7                           "movl   $4, %eax;"
     8                           "movl   $2, %ebx;"
     9                           "movl   %esi, %ecx;"
    10                           "movl   $12, %edx;"
    11                           "int    $0x80;"    /* system call 1 */
    12                           "movl   $1, %eax;"
    13                           "movl   $0, %ebx;"
    14                           "int    $0x80;"    /* system call 2 */
    15                   "forward:"
    16                           "call   backward;"
    17                           ".string "Hello World\n";");
    18  }


看起来很复杂，实际上就做了一个事情，往终端上写了个Hello World。不过这个非常有意思。先简单分析一下流程：

  * 第4行指令的作用是跳转到第15行(即forward标记处)，接着执行第16行。
  * 第16行调用backward，跳转到第5行，接着执行6到14行。
  * 第6行到第11行负责在终端打印出Hello World字符串（等一下详细介绍）。
  * 第12行到第14行退出程序（等一下详细介绍）。

为了更好的理解上面的代码和后续的分析，先来介绍几个比较重要的内容。

### 常用寄存器初识

X86处理器平台有三个常用寄存器：程序指令指针、程序堆栈指针与程序基指针：

<table>
  <tr class="header">
    <th align="left">
      寄存器
    </th>

    <th align="left">
      名称
    </th>

    <th align="left">
      注释
    </th>
  </tr>

  <tr class="odd">
    <td align="left">
      EIP
    </td>

    <td align="left">
      程序指令指针
    </td>

    <td align="left">
      通常指向下一条指令的位置
    </td>
  </tr>

  <tr class="even">
    <td align="left">
      ESP
    </td>

    <td align="left">
      程序堆栈指针
    </td>

    <td align="left">
      通常指向当前堆栈的当前位置
    </td>
  </tr>

  <tr class="odd">
    <td align="left">
      EBP
    </td>

    <td align="left">
      程序基指针
    </td>

    <td align="left">
      通常指向函数使用的堆栈顶端
    </td>
  </tr>
</table>

当然，上面都是扩展的寄存器，用于32位系统，对应的16系统为ip,sp,bp。

### call,ret指令的作用分析

  * call指令

跳转到某个位置，并在之前把下一条指令的地址(EIP)入栈（为了方便”程序“返回以后能够接着执行）。这样的话就有：

    call backward   ==>   push eip
                          jmp backward


  * ret 指令

通常call指令和ret是配合使用的，前者压入跳转前的下一条指令地址，后者弹出call指令压入的那条指令，从而可以在函数调用结束以后接着执行后面的指令。

    ret                    ==>   pop eip


通常在函数调用后，还需要恢复esp和ebp，恢复esp即恢复当前栈指针，以便释放调用函数时为存储函数的局部变量而自动分配的空间；恢复ebp是从栈中弹出一个数据项（通常函数调用过后的第一条语句就是push ebp），从而恢复当前的函数指针为函数调用者本身。这两个动作可以通过一条leave指令完成。

这三个指令对我们后续的解释会很有帮助。更多关于Intel的指令集，请参考：[Intel 386 Manual][5], x86 Assembly Language FAQ：[part1][6], [part2][7], [part3][8].

### 什么是系统调用（以Linux 2.6.21版本和x86平台为例）

系统调用是用户和内核之间的接口，用户如果想写程序，很多时候直接调用了C库，并没有关心系统调用，而实际上C库也是基于系统调用的。这样应用程序和内核之间就可以通过系统调用联系起来。它们分别处于操作系统的用户空间和内核空间（主要是内存地址空间的隔离）。

    用户空间         应用程序(Applications)
                            |      |
                            |     C库（如glibc）
                            |      |
                           系统调用(System Calls，如sys_read, sys_write, sys_exit)
                                |
    内核空间         内核(Kernel)


系统调用实际上也是一些函数，它们被定义在arch/i386/kernel/sys\_i386.c(老的在arch/i386/kernel/sys.c)文件中，并且通过一张系统调用表组织，该表在内核启动时就已经加载了，这个表的入口在内核源代码的arch/i386/kernel/syscall\_table.S里头（老的在arch/i386/kernel/entry.S）。这样，如果想添加一个新的系统调用，修改上面两个内核中的文件，并重新编译内核就可以。当然，如果要在应用程序中使用它们，还得把它写到include/asm/unistd.h中。

如果要在C语言中使用某个系统调用，需要包含头文件/usr/include/asm/unistd.h，里头有各个系统调用的声明以及系统调用号（对应于调用表的入口，即在调用表中的索引，为方便查找调用表而设立的）。如果是自己定义的新系统调用，可能还要在开头用宏_syscall(type, name, type1, name1&#8230;)来声明好参数。

如果要在汇编语言中使用，需要用到int 0&#215;80调用，这个是系统调用的中断入口。涉及到传送参数的寄存器有这么几个，eax是系统调用号（可以到/usr/include/asm-i386/unistd.h或者直接到arch/i386/kernel/syscall_table.S查到），其他寄存器如ebx，ecx，edx，esi，edi一次存放系统调用的参数。而系统调用的返回值存放在eax寄存器中。

下面我们就很容易解释前面的shellcode.c程序流程的2,3两部分了。因为都用了int 0&#215;80中断，所以都用到了系统调用。

第3部分很简单，用到的系统调用号是1，通过查表(查/usr/include/asm-i386/unistd.h或arch/i386/kernel/syscall\_table.S)可以发现这里是sys\_exit调用，再从/usr/include/unistd.h文件看这个系统调用的声明，发现参数ebx是程序退出状态。

第2部分比较有趣，而且复杂一点。我们依次来看各个寄存器，首先根据eax为4确定(同样查表)系统调用为sys_write，而查看它的声明（从/usr/include/unistd.h），我们找到了参数依次为文件描述符、字符串指针和字符串长度。

  * 第一个参数是ebx，正好是2，即标准错误输出，默认为终端。
  * 第二个参数是ecx，而ecx的内容来自esi，esi来自刚弹出栈的值（见第6行`popl %esi;`），而之前刚好有call指令引起了最近一次压栈操作，入栈的内容刚好是call指令的下一条指令的地址，即`.string`所在行的地址，这样ecx刚好引用了&#8221;Hello Worldn&#8221;字符串的地址。
  * 第三个参数是edx，刚好是12，即&#8221;Hello Worldn&#8221;字符串的长度（包括一个空字符）。这样，shellcode.c的执行流程就很清楚了，第4,5,15,16行指令的巧妙之处也就容易理解了（把`.string`存放在call指令之后，并用popl指令把eip弹出当作字符串的入口）。

### 什么是ELF文件

这里的ELF不是“精灵”，而是Executable and Linking Format文件，是Linux下用来做目标文件、可执行文件和共享库的一种文件格式，它有专门的标准，例如：[X86 ELF format and ABI][9]，[中文版][10]。

下面简单描述ELF的格式。

ELF文件主要有三种，分别是：

  * 可重定位的目标文件，在编译时用gcc的-c参数时产生。
  * 可执行文件，这类文件就是我们后面要讨论的可以执行的文件。
  * 共享库，这里主要是动态共享库，而静态共享库则是可重定位的目标文件通过ar命令组织的。

ELF文件的大体结构：

    ELF Header               #程序头，有该文件的Magic number(参考man magic)，类型等
    Program Header Table     #对可执行文件和共享库有效，它描述下面各个节(section)组成的段
    Section1
    Section2
    Section3
    .....
    Program Section Table   #仅对可重定位目标文件和静态库有效，用于描述各个Section的重定位信息等。


对于可执行文件，文件最后的Program Section Table(节区表)和一些非重定位的Section，比如.comment,.note.XXX.debug等信息都可以删除掉，不过如果用strip，objcopy等工具删除掉以后，就不可恢复了。因为这些信息对程序的运行一般没有任何用处。

ELF文件的主要节区(section)有.data,.text,.bss,.interp等，而主要段(segment)有LOAD,INTERP等。它们之间(节区和段)的主要对应关系如下：

<table>
  <tr class="header">
    <th align="left">
      Section
    </th>

    <th align="left">
      解释
    </th>

    <th align="left">
      实例
    </th>
  </tr>

  <tr class="odd">
    <td align="left">
      .data
    </td>

    <td align="left">
      初始化的数据
    </td>

    <td align="left">
      比如int a=10
    </td>
  </tr>

  <tr class="even">
    <td align="left">
      .bss
    </td>

    <td align="left">
      未初始化的数据
    </td>

    <td align="left">
      比如char sum[100];这个在程序执行之前，内核将初始化为0
    </td>
  </tr>

  <tr class="odd">
    <td align="left">
      .text
    </td>

    <td align="left">
      程序代码正文
    </td>

    <td align="left">
      即可执行指令集
    </td>
  </tr>

  <tr class="even">
    <td align="left">
      .interp
    </td>

    <td align="left">
      描述程序需要的解释器（动态连接和装载程序） 存
    </td>

    <td align="left">
      有解释器的全路径，如/lib/ld-linux.so
    </td>
  </tr>
</table>

而程序在执行以后，.data, .bss,.text等一些节区会被Program header table映射到LOAD段，.interp则被映射到了INTERP段。

对于ELF文件的分析，建议使用file, size, readelf，objdump，strip，objcopy，gdb，nm等工具。

这里简单地演示这几个工具：

    $ gcc -g -o shellcode shellcode.c  #如果要用gdb调试，编译时加上-g是必须的
    shellcode.c: In function ‘main’:
    shellcode.c:3: warning: return type of ‘main’ is not ‘int’
    f$ file shellcode  #file命令查看文件类型，想了解工作原理，可man magic,man file
    shellcode: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV),
    dynamically linked (uses shared libs), not stripped
    $ readelf -l shellcode  #列出ELF文件前面的program head table，后面是它描
                           #述了各个段(segment)和节区(section)的关系,即各个段包含哪些节区。
    Elf file type is EXEC (Executable file)
    Entry point 0x8048280
    There are 7 program headers, starting at offset 52

    Program Headers:
      Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
      PHDR           0x000034 0x08048034 0x08048034 0x000e0 0x000e0 R E 0x4
      INTERP         0x000114 0x08048114 0x08048114 0x00013 0x00013 R   0x1
          [Requesting program interpreter: /lib/ld-linux.so.2]
      LOAD           0x000000 0x08048000 0x08048000 0x0044c 0x0044c R E 0x1000
      LOAD           0x00044c 0x0804944c 0x0804944c 0x00100 0x00104 RW  0x1000
      DYNAMIC        0x000460 0x08049460 0x08049460 0x000c8 0x000c8 RW  0x4
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
    $ size shellcode   #可用size命令查看各个段（对应后面将分析的进程内存映像）的大小
       text    data     bss     dec     hex filename
        815     256       4    1075     433 shellcode
    $ strip -R .note.ABI-tag shellcode #可用strip来给可执行文件“减肥”，删除无用信息
    $ size shellcode               #“减肥”后效果“明显”，对于嵌入式系统应该有很大的作用
       text    data     bss     dec     hex filename
        783     256       4    1043     413 shellcode
    $ objdump -s -j .interp shellcode #这个主要工作是反编译，不过用来查看各个节区也很厉害

    shellcode:     file format elf32-i386

    Contents of section .interp:
     8048114 2f6c6962 2f6c642d 6c696e75 782e736f  /lib/ld-linux.so
     8048124 2e3200                               .2.


补充：如果要删除可执行文件的program section table，可以用[A Whirlwind Tutorial on Creating Really Teensy ELF Executables for Linux][11]一文的作者写的[elf kicker][12]工具链中的sstrip工具。

### 程序执行基本过程

在命令行下，敲入程序的名字或者是全路径，然后按下回车就可以启动程序，这个具体是怎么工作的呢？

首先要再认识一下我们的命令行，命令行是内核和用户之间的接口，它本身也是一个程序。在Linux系统启动以后会为每个终端用户建立一个进程执行一个Shell解释程序，这个程序解释并执行用户输入的命令，以实现用户和内核之间的接口。这类解释程序有哪些呢？目前Linux下比较常用的有/bin/bash。那么该程序接收并执行命令的过程是怎么样的呢？

先简单描述一下这个过程：

  * 读取用户由键盘输入的命令行。
  * 分析命令，以命令名作为文件名，并将其它参数改为系统调用execve()内部处理所要求的形式。
  * 终端进程调用fork()建立一个子进程。
  * 终端进程本身用系统调用wait4()来等待子进程完成（如果是后台命令，则不等待）。当子进程运行 时调用execve()，子进程根据文件名（即命令名）到目录中查找有关文件（这是命令解释程序构成的文件），将它调入内存，执行这个程序（解释这条命令）。
  * 如果命令末尾有&号（后台命令符号），则终端进程不用系统调用wait4( )等待，立即发提示符，让用户输入下一个命令，转1)。如果命令末尾没有&号，则终端进程要一直等待，当子进程（即运行命令的进程）完成处理后终止，向父进程（终端进程）报告，此时终端进程醒来，在做必要的判别等工作后，终端进程发提示符，让用户输入新的命令，重复上述处理过程。

现在用strace来跟踪一下程序执行过程中用到的系统调用。

    $ strace -f -o strace.out test
    $ cat strace.out | grep (.*) | sed -e "s#[0-9]* ([a-zA-Z0-9_]*)(.*).*#1#g"
    execve
    brk
    access
    open
    fstat64
    mmap2
    close
    open
    read
    fstat64
    mmap2
    mmap2
    mmap2
    mmap2
    close
    mmap2
    set_thread_area
    mprotect
    munmap
    brk
    brk
    open
    fstat64
    mmap2
    close
    close
    close
    exit_group


相关的系统调用基本体现了上面的执行过程，需要注意的是，里头还涉及到内存映射(mmap2)等。

下面再罗嗦一些比较有意思的内容，参考《深入理解Linux内核》的&#8221;程序的执行&#8221;(P681)。

Linux支持很多不同的可执行文件格式，这些不同的格式是如何解释的呢？平时我们在命令行下敲入一个命令就完了，也没有去管这些细节。实际上Linux下有一个`struct linux_binfmt`结构来管理不同的可执行文件类型，这个结构中有对应的可执行文件的处理函数。大概的过程如下：

  * 在用户态执行了execve后，引发int 0&#215;80中断，进入内核态，执行内核态的相应函数do\_sys\_execve，该函数又调用do\_execve函数。do\_execve函数读入可执行文件，检查权限，如果没问题，继续读入可执行文件需要的相关信息（struct linux_binprm描述的）。

  * 接着执行search\_binary\_handler，根据可执行文件的类型（由上一步的最后确定），在linux\_binfmt结构链表(formats，这个链表可以通过register\_binfmt和unregister\_binfmt注册和删除某些可执行文件的信息，因此注册新的可执行文件成为可能，后面再介绍)上查找，找到相应的结构，然后执行相应的load\_binary()函数开始加载可执行文件。在该链表的最后一个元素总是对解释脚本(interpreted script)的可执行文件格式进行描述的一个对象。这种格式只定义了load\_binary方法，其相应的load\_script()函数检查这种可执行文件是否以两个#!字符开始，如果是，这个函数就以另一个可执行文件的路径名作为参数解释第一行的其余部分，并把脚本文件名作为参数传递以执行这个脚本（实际上脚本程序把自身的内容当作一个参数传递给了解释程序(如/bin/bash)，而这个解释程序通常在脚本文件的开头用#!标记，如果没有标记，那么默认解释程序为当前SHELL）。

  * 对于ELF类型文件，其处理函数是load\_elf\_binary，它先读入ELF文件的头部，根据头部信息读入各种数据，再次扫描程序段描述表(program header table)，找到类型为PT\_LOAD的段（即.text,.data,.bss等节区），将其映射(elf\_map)到内存的固定地址上，如果没有动态连接器的描述段，把返回的入口地址设置成应用程序入口。完成这个功能的是start\_thread,它不启动一个线程，而只是用来修改了pt\_regs中保存的PC等寄存器的值，使其指向加载的应用程序的入口。当内核操作结束，返回用户态时接着就执行应用程序本身了。

  * 如果应用程序使用了动态连接库，内核除了加载指定的可执行文件外，还要把控制权交给动态连接器(ld-linux.so)以便处理动态连接的程序。内核搜寻段表（Program Header Table），找到标记为PT\_INTERP段中所对应的动态连接器的名称，并使用load\_elf\_interp()加载其映像，并把返回的入口地址设置成load\_elf\_interp()的返回值，即动态链接器的入口。当execve系统调用退出时，动态连接器接着运行，它检查应用程序对共享链接库的依赖性，并在需要时对其加载，对程序的外部引用进行重定位（具体过程见〈shell编程范例之进程操作〉）。然后把控制权交给应用程序，从ELF文件头部中定义的程序进入点（用readelf -h可以出看到，Entry point address即是）开始执行。（不过对于非LIB\_BIND_NOW的共享库装载是在有外部引用请求时才执行的）。

对于内核态的函数调用过程，没有办法通过strace（它只能跟踪到系统调用层）来做的，因此要想跟踪内核中各个系统调用的执行细节，需要用其他工具。比如可以通过给内核打一个[KFT(Kernel Function Tracing)][13]的补丁来跟踪内核具体调用了哪些函数。当然，也可以通过ctags/cscope/LXR等工具分析内核的源代码。

Linux允许自己注册我们自己定义的可执行格式，主要接口是/procy/sys/fs/binfmt_misc/register，可以往里头写入特定格式的字符串来实现。该字符串格式如下： :name:type:offset:string:mask:interpreter:

  * name 新格式的标示符
  * type 识别类型（M表示魔数，E表示扩展）
  * offset 魔数(magic number,请参考man magic和man file)在文件中的启始偏移量
  * string 以魔数或者以扩展名匹配的字节序列
  * mask 用来屏蔽掉string的一些位
  * interpreter 程序解释器的完整路径名

### Linux下程序的内存映像

Linux下是如何给进程分配内存（这里仅讨论虚拟内存的分配）的呢？可以从/proc/ <pid>/maps文件中看到个大概。这里的pid是进程号。

/proc下有一个文件比较特殊，是self，它链接到当前进程的进程号，例如：

    $ ls /proc/self -l
    lrwxrwxrwx 1 root root 64 2000-01-10 18:26 /proc/self -> 11291/
    $ ls /proc/self -l
    lrwxrwxrwx 1 root root 64 2000-01-10 18:26 /proc/self -> 11292/


看到没？每次都不一样，这样我们通过cat /proc/self/maps就可以看到cat程序执行时的内存映像了。

    $ cat -n /proc/self/maps
         1  08048000-0804c000 r-xp 00000000 03:01 273716     /bin/cat
         2  0804c000-0804d000 rw-p 00003000 03:01 273716     /bin/cat
         3  0804d000-0806e000 rw-p 0804d000 00:00 0          [heap]
         4  b7b90000-b7d90000 r--p 00000000 03:01 87528      /usr/lib/locale/locale-archive
         5  b7d90000-b7d91000 rw-p b7d90000 00:00 0
         6  b7d91000-b7ecd000 r-xp 00000000 03:01 466875     /lib/libc-2.5.so
         7  b7ecd000-b7ece000 r--p 0013c000 03:01 466875     /lib/libc-2.5.so
         8  b7ece000-b7ed0000 rw-p 0013d000 03:01 466875     /lib/libc-2.5.so
         9  b7ed0000-b7ed4000 rw-p b7ed0000 00:00 0
        10  b7eeb000-b7f06000 r-xp 00000000 03:01 402817     /lib/ld-2.5.so
        11  b7f06000-b7f08000 rw-p 0001b000 03:01 402817     /lib/ld-2.5.so
        12  bfbe3000-bfbf8000 rw-p bfbe3000 00:00 0          [stack]
        13  ffffe000-fffff000 r-xp 00000000 00:00 0          [vdso]


编号是原文件里头没有的，为了说明方便，用-n参数加上去的。我们从中可以得到如下信息：

  * 第1,2行对应的内存区是我们的程序（包括指令，数据等）
  * 第3到12行对应的内存区是堆栈段，里头也映像了程序引用的动态连接库
  * 第13行是内核空间

总结一下：

  * 前两部分是用户空间，可以从0&#215;00000000到0xbfffffff(在测试的2.6.21.5-smp上只到bfbf8000)，而内核空间从0xC0000000到0xffffffff，分别是3G和1G，所以对于每一个进程来说，共占用4G的虚拟内存空间
  * 从程序本身占用的内存，到堆栈段（动态获取内存或者是函数运行过程中用来存储局部变量、参数的空间，前者是heap，后者是stack），再到内核空间，地址是从低到高的
  * 栈顶并非0xC0000000下的一个固定数值

结合相关资料，可以得到这么一个比较详细的进程内存映像表(以Linux 2.6.21.5-smp为例)：

    地址                            内核空间
    0xC0000000
                          (program flie)程序名           execve的第一个参数
                          (environment)环境变量          execve的第三个参数，main的第三个参数
                          (arguments)参数                execve的第二个参数，main的形参
                          (stack)栈                      自动变量以及每次函数调用时所需保存的信息都
                               |                         存放在此，包括函数返回地址、调用者的
                               |                         环境信息等，函数的参数，局部变量都存放在此
                              |/
                              ...
                          (heap)堆                       主要在这里进行动态存储分配，比如malloc,new等

                          .bss(uninitilized data)        没有初始化的数据（全局变量哦）
                          .data(initilized global data)  已经初始化的全局数据（全局变量）
                          .text(Executable Instructions) 通常是可执行指令
    0x08048000
    0x00000000


光看没有任何概念，我们用gdb来看看刚才那个简单的程序。

    $ gcc -g -o shellcode shellcode.c   #要用gdb调试，在编译时需要加-g参数
    $ gdb ./shellcode
    (gdb) set args arg1 arg2 arg3 arg4  #为了测试，设置几个参数
    (gdb) l                             #浏览代码
    1 /* shellcode.c */
    2 void main()
    3 {
    4     __asm__ __volatile__("jmp forward;"
    5     "backward:"
    6        "popl   %esi;"
    7        "movl   $4, %eax;"
    8        "movl   $2, %ebx;"
    9        "movl   %esi, %ecx;"
    10               "movl   $12, %edx;"
    (gdb) break 4               #在汇编入口设置一个断点，让程序运行后停到这里
    Breakpoint 1 at 0x8048332: file shellcode.c, line 4.
    (gdb) r                     #运行程序
    Starting program: /mnt/hda8/Temp/c/program/shellcode arg1 arg2 arg3 arg4

    Breakpoint 1, main () at shellcode.c:4
    4     __asm__ __volatile__("jmp forward;"
    (gdb) print $esp            #打印当前堆栈指针值，用于查找整个栈的栈顶
    $1 = (void *) 0xbffe1584
    (gdb) x/100s $esp+4000      #改变后面的4000，不断往更大的空间找
    (gdb) x/1s 0xbffe1fd9       #在 0xbffe1fd9 找到了程序名，这里是该次运行时的栈顶
    0xbffe1fd9:      "/mnt/hda8/Temp/c/program/shellcode"
    (gdb) x/10s 0xbffe17b7      #其他环境变量信息
    0xbffe17b7:      "CPLUS_INCLUDE_PATH=/usr/lib/qt/include"
    0xbffe17de:      "MANPATH=/usr/local/man:/usr/man:/usr/X11R6/man:/usr/lib/java/man:/usr/share/texmf/man"
    0xbffe1834:      "HOSTNAME=falcon.lzu.edu.cn"
    0xbffe184f:      "TERM=xterm"
    0xbffe185a:      "SSH_CLIENT=219.246.50.235 3099 22"
    0xbffe187c:      "QTDIR=/usr/lib/qt"
    0xbffe188e:      "SSH_TTY=/dev/pts/0"
    0xbffe18a1:      "USER=falcon"
    ...
    (gdb) x/5s 0xbffe1780    #一些传递给main函数的参数，包括文件名和其他参数
    0xbffe1780:      "/mnt/hda8/Temp/c/program/shellcode"
    0xbffe17a3:      "arg1"
    0xbffe17a8:      "arg2"
    0xbffe17ad:      "arg3"
    0xbffe17b2:      "arg4"
    (gdb) print init  #打印init函数的地址，这个是/usr/lib/crti.o里头的函数，做一些初始化操作
    $2 = {<text variable, no debug info>} 0xb7e73d00 <init>
    (gdb) print fini   #也在/usr/lib/crti.o中定义，在程序结束时做一些处理工作
    $3 = {<text variable, no debug info>} 0xb7f4a380 <fini>
    (gdb) print _start #在/usr/lib/crt1.o，这个才是程序的入口，必须的，ld会检查这个
    $4 = {<text variable, no debug info>} 0x8048280 <__libc_start_main@plt+20>
    (gdb) print main   #这里是我们的main函数
    $5 = {void ()} 0x8048324 <main>


补充：在进程的内存映像中可能看到诸如init,fini,_start等函数（或者是入口），这些东西并不是我们自己写的啊？为什么会跑到我们的代码里头呢？实际上这些东西是链接的时候gcc默认给连接进去的，主要用来做一些进程的初始化和终止的动作。更多相关的细节可以参考资料[如何获取当前进程之静态影像文件][14]和&#8221;The Linux Kernel Primer&#8221;, P234, Figure 4.11，如果想了解链接(ld)的具体过程，可以看看本节参考《Unix环境高级编程编程》第7章 &#8220;UnIx进程的环境&#8221;, P127和P13，[ELF: From The Programmer&#8217;s Perspective][15]，[GNU-ld连接脚本 Linker Scripts][16]。

上面的操作对堆栈的操作比较少，下面我们用一个例子来演示栈在内存中的情况。

### 栈在内存中的组织

这一节主要介绍一个函数被调用时，参数是如何传递的，局部变量是如何存储的，它们对应的栈的位置和变化情况，从而加深对栈的理解。在操作时发现和参考资料的结果不太一样（参考资料中没有edi和esi相关信息，再第二部分的一个小程序里头也没有），可能是gcc版本的问题或者是它对不同源代码的处理不同。我的版本是4.1.2(可以通过gcc &#8211;version查看)。

先来一段简单的程序，这个程序除了做一个加法操作外，还复制了一些字符串。

    /* testshellcode.c */
    #include <stdio.h>      /* printf */
    #include <string.h>     /* memset, memcpy */

    #define BUF_SIZE 8

    #ifndef STR_SRC
    # define STR_SRC "AAAAAAA"
    #endif

    int func(int a, int b, int c)
    {
        int sum = 0;
        char buffer[BUF_SIZE];

        sum = a + b + c;

        memset(buffer, &#39;&#39;, BUF_SIZE);
        memcpy(buffer, STR_SRC, sizeof(STR_SRC)-1);

        return sum;
    }

    int main()
    {
        int sum;

        sum = func(1, 2, 3);

        printf("sum = %dn", sum);

        return 0;
    }


上面这个代码没有什么问题，编译执行一下：

    $ make testshellcode
    cc     testshellcode.c   -o testshellcode
    $ ./testshellcode
    sum = 6


下面调试一下，看看在调用func后的栈的内容。

    $ gcc -g -o testshellcode testshellcode.c  #为了调试，需要在编译时加-g选项
    $ gdb ./testshellcode   #启动gdb调试
    ...
    (gdb) set logging on    #如果要记录调试过程中的信息，可以把日志记录功能打开
    Copying output to gdb.txt.
    (gdb) l main            #列出源代码
    20
    21              return sum;
    22      }
    23
    24      int main()
    25      {
    26              int sum;
    27
    28              sum = func(1, 2, 3);
    29
    (gdb) break 28   #在调用func函数之前让程序停一下，以便记录当时的ebp(基指针)
    Breakpoint 1 at 0x80483ac: file testshellcode.c, line 28.
    (gdb) break func #设置断点在函数入口，以便逐步记录栈信息
    Breakpoint 2 at 0x804835c: file testshellcode.c, line 13.
    (gdb) disassemble main   #反编译main函数，以便记录调用func后的下一条指令地址
    Dump of assembler code for function main:
    0x0804839b <main+0>:    lea    0x4(%esp),%ecx
    0x0804839f <main+4>:    and    $0xfffffff0,%esp
    0x080483a2 <main+7>:    pushl  0xfffffffc(%ecx)
    0x080483a5 <main+10>:   push   %ebp
    0x080483a6 <main+11>:   mov    %esp,%ebp
    0x080483a8 <main+13>:   push   %ecx
    0x080483a9 <main+14>:   sub    $0x14,%esp
    0x080483ac <main+17>:   push   $0x3
    0x080483ae <main+19>:   push   $0x2
    0x080483b0 <main+21>:   push   $0x1
    0x080483b2 <main+23>:   call   0x8048354 <func>
    0x080483b7 <main+28>:   add    $0xc,%esp
    0x080483ba <main+31>:   mov    %eax,0xfffffff8(%ebp)
    0x080483bd <main+34>:   sub    $0x8,%esp
    0x080483c0 <main+37>:   pushl  0xfffffff8(%ebp)
    0x080483c3 <main+40>:   push   $0x80484c0
    0x080483c8 <main+45>:   call   0x80482a0 <printf@plt>
    0x080483cd <main+50>:   add    $0x10,%esp
    0x080483d0 <main+53>:   mov    $0x0,%eax
    0x080483d5 <main+58>:   mov    0xfffffffc(%ebp),%ecx
    0x080483d8 <main+61>:   leave
    0x080483d9 <main+62>:   lea    0xfffffffc(%ecx),%esp
    0x080483dc <main+65>:   ret
    End of assembler dump.
    (gdb) r        #运行程序
    Starting program: /mnt/hda8/Temp/c/program/testshellcode

    Breakpoint 1, main () at testshellcode.c:28
    28              sum = func(1, 2, 3);
    (gdb) print $ebp  #打印调用func函数之前的基地址，即Previous frame pointer。
    $1 = (void *) 0xbf84fdd8
    (gdb) n           #执行call指令并跳转到func函数的入口

    Breakpoint 2, func (a=1, b=2, c=3) at testshellcode.c:13
    13              int sum = 0;
    (gdb) n
    16              sum = a + b + c;
    (gdb) x/11x $esp  #打印当前栈的内容，可以看出，地址从低到高，注意标记有蓝色和红色的值
                     #它们分别是前一个栈基地址(ebp)和call调用之后的下一条指令的指针(eip)
    0xbf84fd94:     0x00000000      0x00000000      0x080482e0      0x00000000
    0xbf84fda4:     0xb7f2bce0      0x00000000      0xbf84fdd8      0x080483b7
    0xbf84fdb4:     0x00000001      0x00000002      0x00000003
    (gdb) n       #执行sum = a + b + c，后，比较栈内容第一行，第4列，由0变为6
    18              memset(buffer, &#39;&#39;, BUF_SIZE);
    (gdb) x/11x $esp
    0xbf84fd94:     0x00000000      0x00000000      0x080482e0      0x00000006
    0xbf84fda4:     0xb7f2bce0      0x00000000      0xbf84fdd8      0x080483b7
    0xbf84fdb4:     0x00000001      0x00000002      0x00000003
    (gdb) n
    19              memcpy(buffer, STR_SRC, sizeof(STR_SRC)-1);
    (gdb) x/11x $esp #缓冲区初始化以后变成了0
    0xbf84fd94:     0x00000000      0x00000000      0x00000000      0x00000006
    0xbf84fda4:     0xb7f2bce0      0x00000000      0xbf84fdd8      0x080483b7
    0xbf84fdb4:     0x00000001      0x00000002      0x00000003
    (gdb) n
    21              return sum;
    (gdb) x/11x $esp #进行copy以后，这两列的值变了，大小刚好是7个字节，最后一个字节为&#39;&#39;
    0xbf84fd94:     0x00000000      0x41414141      0x00414141      0x00000006
    0xbf84fda4:     0xb7f2bce0      0x00000000      0xbf84fdd8      0x080483b7
    0xbf84fdb4:     0x00000001      0x00000002      0x00000003
    (gdb) c
    Continuing.
    sum = 6

    Program exited normally.
    (gdb) quit


从上面的操作过程，我们可以得出大概的栈分布(func函数结束之前)如下：

<table>
  <tr class="header">
    <th align="left">
      地址
    </th>

    <th align="left">
      值(hex)
    </th>

    <th align="left">
      符号或者寄存器
    </th>

    <th align="left">
      注释
    </th>
  </tr>

  <tr class="odd">
    <td align="left">
      低地址
    </td>

    <td align="left">
    </td>

    <td align="left">
    </td>

    <td align="left">
      栈顶方向
    </td>
  </tr>

  <tr class="even">
    <td align="left">
      0xbf84fd98
    </td>

    <td align="left">
      0&#215;41414141
    </td>

    <td align="left">
      buf[0]
    </td>

    <td align="left">
      可以看出little endian(小端，重要的数据在前面)
    </td>
  </tr>

  <tr class="odd">
    <td align="left">
      0xbf84fd9c
    </td>

    <td align="left">
      0&#215;00414141
    </td>

    <td align="left">
      buf[1]
    </td>

    <td align="left">
    </td>
  </tr>

  <tr class="even">
    <td align="left">
      0xbf84fda0
    </td>

    <td align="left">
      0&#215;00000006
    </td>

    <td align="left">
      sum
    </td>

    <td align="left">
      可见这上面都是func函数里头的局部变量
    </td>
  </tr>

  <tr class="odd">
    <td align="left">
      0xbf84fda4
    </td>

    <td align="left">
      0xb7f2bce0
    </td>

    <td align="left">
      esi
    </td>

    <td align="left">
      源索引指针，可以通过产生中间代码查看，貌似没什么作用
    </td>
  </tr>

  <tr class="even">
    <td align="left">
      0xbf84fda8
    </td>

    <td align="left">
      0&#215;00000000
    </td>

    <td align="left">
      edi
    </td>

    <td align="left">
      目的索引指针
    </td>
  </tr>

  <tr class="odd">
    <td align="left">
      0xbf84fdac
    </td>

    <td align="left">
      0xbf84fdd8
    </td>

    <td align="left">
      ebp
    </td>

    <td align="left">
      调用func之前的栈的基地址，以便调用函数结束之后恢复
    </td>
  </tr>

  <tr class="even">
    <td align="left">
      0xbf84fdb0
    </td>

    <td align="left">
      0x080483b7
    </td>

    <td align="left">
      eip
    </td>

    <td align="left">
      调用func之前的指令指针，以便调用函数结束之后继续执行
    </td>
  </tr>

  <tr class="odd">
    <td align="left">
      0xbf84fdb4
    </td>

    <td align="left">
      0&#215;00000001
    </td>

    <td align="left">
      a
    </td>

    <td align="left">
      第一个参数
    </td>
  </tr>

  <tr class="even">
    <td align="left">
      0xbf84fdb8
    </td>

    <td align="left">
      0&#215;00000002
    </td>

    <td align="left">
      b
    </td>

    <td align="left">
      第二个参数
    </td>
  </tr>

  <tr class="odd">
    <td align="left">
      0xbf84fdbc
    </td>

    <td align="left">
      0&#215;00000003
    </td>

    <td align="left">
      c
    </td>

    <td align="left">
      第三个参数，可见参数是从最后一个开始压栈的
    </td>
  </tr>

  <tr class="even">
    <td align="left">
      高地址
    </td>

    <td align="left">
    </td>

    <td align="left">
    </td>

    <td align="left">
      栈底方向
    </td>
  </tr>
</table>

先说明一下edi和esi的由来（在上面的调试过程中我们并没有看到），是通过产生中间汇编代码分析得出的。

    $ gcc -S testshellcode.c


在产生的testshellcode.s代码里头的func部分看到push ebp之后就push了edi和esi。但是搜索了一下代码，发现就这个函数里头引用了这两个寄存器，所以保存它们没什么用，删除以后编译产生目标代码后证明是没用的。

    $ cat testshellcode.s
    ...
    func:
            pushl   %ebp
            movl    %esp, %ebp
            pushl   %edi
            pushl   %esi
    ...
            popl    %esi
            popl    %edi
            popl    %ebp
    ...


下面就不管这两部分（edi和esi）了，主要来分析和函数相关的这几部分在栈内的分布：

  * 函数局部变量，在靠近栈顶一端
  * 调用函数之前的栈的基地址（ebp, Previous Frame Pointer），在中间靠近栈顶方向
  * 调用函数指令的下一条指令地址 （eip），在中间靠近栈底的方向
  * 函数参数，在靠近栈底的一端，最后一个参数最先入栈

到这里，函数调用时的相关内容在栈内的分布就比较清楚了，在具体分析缓冲区溢出问题之前，我们再来看一个和函数关系很大的问题，即函数返回值的存储问题：函数的返回值存放在寄存器eax中。

先来看这段代码：

    /**
     * test_return.c -- the return of a function is stored in register eax
     */

    #include <stdio.h>

    int func()
    {
            __asm__ ("movl $1, %eax");
    }

    int main()
    {
            printf("the return of func: %dn", func());

            return 0;
    }


编译运行后，可以看到返回值为1，刚好是我们在func函数中mov到eax中的“立即数”1，因此很容易理解返回值存储在eax中的事实，如果还有疑虑，可以再看看汇编代码。在函数返回之后，eax中的值当作了printf的参数压入了栈中，而在源代码中我们正是把func的结果作为printf的第二个参数的。

    $ make test_return
    cc     test_return.c   -o test_return
    $ ./test_return
    the return of func: 1
    $ gcc -S test_return.c
    $ cat test_return.s
    ...
            call    func
            subl    $8, %esp
            pushl   %eax      #printf的第二个参数，把func的返回值压入了栈底
            pushl   $.LC0     #printf的第一个参数the return of func: %dn
            call    printf
    ...


对于系统调用，返回值也存储在eax寄存器中。

## 缓冲区溢出

### 实例分析：字符串复制

先来看一段简短的代码。

    /* testshellcode.c */
    #include <stdio.h>      /* printf */
    #include <string.h>     /* memset, memcpy */

    #define BUF_SIZE 8

    #ifdef STR1
    # define STR_SRC "AAAAAAA1"
    #endif

    #ifndef STR_SRC
    # define STR_SRC "AAAAAAA"
    #endif

    int func(int a, int b, int c)
    {
            int sum = 0;
            char buffer[BUF_SIZE];

            sum = a + b + c;

            memset(buffer, &#39;&#39;, BUF_SIZE);
            memcpy(buffer, STR_SRC, sizeof(STR_SRC)-1);

            return sum;
    }

    int main()
    {
            int sum;

            sum = func(1, 2, 3);

            printf("sum = %dn", sum);

            return 0;
    }


编译一下看看结果：

    $ gcc -DSTR1 -o testshellcode testshellcode.c  #通过-D定义宏STR1，从而采用第一个STR_SRC的值，即"AAAAAAA1"
    $ ./testshellcode
    sum = 1


不知道你有没有发现异常呢？上面用红色标记的地方，本来sum为1+2+3即6，但是实际返回的竟然是1。到底是什么原因呢？大家应该有所了解了，因为我们在复制字符串AAAAAAA1到buf的时候超出buf本来的大小。buf本来的大小是BUF_SIZE，8个字节，而我们要复制的内容是12个字节，所以超出了四个字节。根据第一小节的分析，我们用栈的变化情况来表示一下这个复制过程(即执行memcpy的过程)。

    memcpy(buffer, STR_SRC, sizeof(STR_SRC)-1);

    （低地址）
    复制之前     ====> 复制之后
    0x00000000       0x41414141      #char buf[8]
    0x00000000       0x00414141
    0x00000006       0x00000001      #int sum
    （高地址）


下面通过gdb调试来确认一下(只摘录了一些片断)。

    $ gcc -DSTR1 -g -o testshellcode testshellcode.c
    $ gdb ./testshellcode
    ...
    (gdb) l
    21
    22              memset(buffer, &#39;&#39;, BUF_SIZE);
    23              memcpy(buffer, STR_SRC, sizeof(STR_SRC)-1);
    24
    25              return sum;
    ...
    (gdb) break 23
    Breakpoint 1 at 0x804837f: file testshellcode.c, line 23.
    (gdb) break 25
    Breakpoint 2 at 0x8048393: file testshellcode.c, line 25.
    (gdb) r
    Starting program: /mnt/hda8/Temp/c/program/testshellcode

    Breakpoint 1, func (a=1, b=2, c=3) at testshellcode.c:23
    23              memcpy(buffer, STR_SRC, sizeof(STR_SRC)-1);
    (gdb) x/3x $esp+4
    0xbfec6bd8:     0x00000000      0x00000000      0x00000006
    (gdb) n

    Breakpoint 2, func (a=1, b=2, c=3) at testshellcode.c:25
    25              return sum;
    (gdb) x/3x $esp+4
    0xbfec6bd8:     0x41414141      0x00414141      0x00000001


可以看出，因为C语言没有对数组的边界进行限制。我们可以往数组中存入预定义长度的字符串，从而导致缓冲区溢出。

### 缓冲区溢出后果

溢出之后的问题是导致覆盖栈的其他内容，从而可能改变程序原来的行为。

如果这类问题被“黑客”利用那将产生非常可怕的后果，小则让非法用户获取了系统权限，把你的服务器当成“僵尸”，用来对其他机器进行攻击，严重的则可能被人删除数据（所以备份很重要）。即使不被黑客利用，这类问题如果放在医疗领域，那将非常危险，可能那个被覆盖的数字刚好是用来控制治疗癌症的辐射量的，一旦出错，那可能导致置人死地，当然，如果在航天领域，那可能就是好多个0的money甚至航天员的损失，呵呵，“缓冲区溢出，后果很严重！”

### 缓冲区溢出应对策略

那这个怎么办呢？貌似[Linux下缓冲区溢出攻击的原理及对策][17]提到有一个libsafe库，可以至少用来检测程序中出现的类似超出数组边界的问题。对于上面那个具体问题，为了保护sum不被修改，有一个小技巧，可以让求和操作在字符串复制操作之后来做，以便求和操作把溢出的部分给重写。这个呆伙在下面一块看效果吧。继续看看缓冲区的溢出吧。

先来看看这个代码，还是testshellcode.c的改进。

    /* testshellcode.c */
    #include <stdio.h>      /* printf */
    #include <string.h> /* memset, memcpy */
    #define BUF_SIZE 8

    #ifdef STR1
    # define STR_SRC "AAAAAAAa1"
    #endif
    #ifdef STR2
    # define STR_SRC "AAAAAAAa1BBBBBBBB"
    #endif
    #ifdef STR3
    # define STR_SRC "AAAAAAAa1BBBBBBBBCCCC"
    #endif
    #ifdef STR4
    # define STR_SRC "AAAAAAAa1BBBBBBBBCCCCDDDD"
    #endif

    #ifndef STR_SRC
    # define STR_SRC "AAAAAAA"
    #endif

    int func(int a, int b, int c)
    {
            int sum = 0;
            char buffer[BUF_SIZE] = "";

            memset(buffer, &#39;&#39;, BUF_SIZE);
            memcpy(buffer, STR_SRC, sizeof(STR_SRC)-1);

            sum = a + b + c;     //把求和操作放在复制操作之后可以在一定情况下“保护”求和结果

            return sum;
    }

    int main()
    {
            int sum;

            sum = func(1, 2, 3);

            printf("sum = %dn", sum);

            return 0;
    }


看看运行情况：

`$ gcc -D STR2 -o testshellcode testshellcode.c   #再多复制8个字节，结果和STR1时一样                         #原因是edi,esi这两个没什么用的，覆盖了也没关系 $ ./testshellcode       #看到没？这种情况下，让整数操作在字符串复制之后做可以“保护‘整数结果 sum = 6 $ gcc -D STR3 -o testshellcode testshellcode.c  #再多复制4个字节，现在就会把ebp给覆盖                                                #了，这样当main函数再要用ebp访问数据                                               #时就会出现访问非法内存而导致段错误。 $ ./testshellcode Segmentation fault` 如果感兴趣，自己还可以用gdb类似之前一样来查看复制字符串以后栈的变化情况。

### 如何保护ebp不被修改

下面来做一个比较有趣的事情：如何设法保护我们的ebp不被修改。

首先要明确ebp这个寄存器的作用和“行为”，它是栈基地址，并且发现在调用任何一个函数时，这个ebp总是在第一条指令被压入栈中，并在最后一条指令(ret)之前被弹出。类似这样：

    func:                        #函数
           pushl %ebp            #第一条指令
           ...
           popl %ebp             #倒数第二条指令
           ret


还记得之前（第一部分）提到的函数的返回值是存储在eax寄存器中的么？如果我们在一个函数中仅仅做放这两条指令：

    popl %eax
    pushl %eax


那不就刚好有：

    func:                        #函数
           pushl %ebp            #第一条指令
           popl %eax             #把刚压入栈中的ebp弹出存放到eax中
           pushl %eax            #又把ebp压入栈
           popl %ebp             #倒数第二条指令
           ret


这样我们没有改变栈的状态，却获得了ebp的值，如果在调用任何一个函数之前，获取这个ebp，并且在任何一条字符串复制语句（可能导致缓冲区溢出的语句）之后重新设置一下ebp的值，那么就可以保护ebp啦。具体怎么实现呢？看这个代码。

    /* testshellcode.c */
    #include <stdio.h>      /* printf */
    #include <string.h> /* memset, memcpy */
    #define BUF_SIZE 8

    #ifdef STR1
    # define STR_SRC "AAAAAAAa1"
    #endif
    #ifdef STR2
    # define STR_SRC "AAAAAAAa1BBBBBBBB"
    #endif
    #ifdef STR3
    # define STR_SRC "AAAAAAAa1BBBBBBBBCCCC"
    #endif
    #ifdef STR4
    # define STR_SRC "AAAAAAAa1BBBBBBBBCCCCDDDD"
    #endif

    #ifndef STR_SRC
    # define STR_SRC "AAAAAAA"
    #endif

    unsigned long get_ebp()
    {
            __asm__ ("popl %eax;"
                                    "pushl %eax;");
    }

    int func(int a, int b, int c, unsigned long ebp)
    {
            int sum = 0;
            char buffer[BUF_SIZE] = "";

            sum = a + b + c;
            memset(buffer, &#39;&#39;, BUF_SIZE);
            memcpy(buffer, STR_SRC, sizeof(STR_SRC)-1);
            *(unsigned long *)(buffer+20) = ebp;
            return sum;
    }

    int main()
    {
            int sum, ebp;

            ebp = get_ebp();
            sum = func(1, 2, 3, ebp);

            printf("sum = %dn", sum);

            return 0;
    }


这段代码和之前的代码的不同有：

  * 给func函数增加了一个参数ebp，（其实可以用全局变量替代的）
  * 利用了刚介绍的原理定义了一个函数get_ebp以便获取老的ebp
  * 在main函数中调用func之前调用了get_ebp，并把它作为func的最后一个参数
  * 在func函数中调用memcpy函数（可能发生缓冲区溢出的地方）之后添加了一条恢复设置ebp的语句，这条语句先把buffer+20这个地址（存放ebp的地址，你可以类似第一部分提到的用gdb来查看）强制转换为指向一个unsigned long型的整数（4个字节），然后把它指向的内容修改为老的ebp。

看看效果：

    $ gcc -D STR3 -o testshellcode testshellcode.c
    $ ./testshellcode         #现在没有段错误了吧，因为ebp得到了“保护” sum = 6`


### 如何保护eip不被修改？

如果我们复制更多的字节过去了，比如再多复制四个字节进去，那么eip就被覆盖了。

    $ gcc -D STR4 -o testshellcode testshellcode.c
    $ ./testshellcode
    Segmentation fault


同样会出现段错误，因为下一条指令的位置都被改写了，func返回后都不知道要访问哪个”非法“地址啦。呵呵，如果是一个合法地址呢？

如果在缓冲区溢出时，eip被覆盖了，并且被修改为了一条合法地址，那么问题就非常”有趣“了。如果这个地址刚好是调用func的那个地址，那么整个程序就成了死循环，如果这个地址指向的位置刚好有一段关机代码，那么系统正在运行的所有服务都将被关掉，如果那个地方是一段更恶意的代码，那就？你可以尽情想像哦。如果是黑客故意利用这个，那么那些代码貌似就叫做[shellcode][18]了。

有没有保护eip的办法呢？呵呵，应该是有的吧。不知道gas有没有类似masm汇编器中offset的伪操作指令（查找了一下，貌似没有），如果有的话在函数调用之前设置一个标号，在后面某个位置获取，再加上一个可能的偏移（包括call指令的长度和一些push指令等），应该可以算出来，不过貌似比较麻烦（或许你灵感大作，找到好办法了！），这里直接通过gdb反汇编求得它相对main的偏移算出来得了。求出来以后用它来”保护“栈中的值。

看看这个代码：

    /* testshellcode.c */
    #include <stdio.h>      /* printf */
    #include <string.h> /* memset, memcpy */
    #define BUF_SIZE 8

    #ifdef STR1
    # define STR_SRC "AAAAAAAa1"
    #endif
    #ifdef STR2
    # define STR_SRC "AAAAAAAa1BBBBBBBB"
    #endif
    #ifdef STR3
    # define STR_SRC "AAAAAAAa1BBBBBBBBCCCC"
    #endif
    #ifdef STR4
    # define STR_SRC "AAAAAAAa1BBBBBBBBCCCCDDDD"
    #endif

    #ifndef STR_SRC
    # define STR_SRC "AAAAAAA"
    #endif

    int main();
    #define OFFSET  40

    unsigned long get_ebp()
    {
            __asm__ ("popl %eax;"
                                    "pushl %eax;");
    }

    int func(int a, int b, int c, unsigned long ebp)
    {
            int sum = 0;
            char buffer[BUF_SIZE] = "";

            memset(buffer, &#39;&#39;, BUF_SIZE);
            memcpy(buffer, STR_SRC, sizeof(STR_SRC)-1);

            sum = a + b + c;

            *(unsigned long *)(buffer+20) = ebp;
            *(unsigned long *)(buffer+24) = (unsigned long)main+OFFSET;
            return sum;
    }

    int main()
    {
            int sum, ebp;

            ebp = get_ebp();
            sum = func(1, 2, 3, ebp);

            printf("sum = %dn", sum);

            return 0;
    }


看看效果：

    $ gcc -D STR4 -o testshellcode testshellcode.c
    $ ./testshellcode
    sum = 6


这样，EIP也得到了“保护”（这个方法很糟糕的，呵呵）。

类似地，如果再多复制一些内容呢？那么栈后面的内容都将被覆盖，即传递给func函数的参数都将被覆盖，因此上面的方法，包括所谓的对sum和ebp等值的保护都没有任何意义了（如果再对后面的参数进行进一步的保护呢？或许有点意义，呵呵）。在这里，之所以提出类似这样的保护方法，实际上只是为了讨论一些有趣的细节并加深对缓冲区溢出这一问题的理解（或许有一些实际的价值哦，算是抛砖引玉吧）。

### 缓冲区溢出检测

要确实解决这类问题，从主观上讲，还得程序员来做相关的工作，比如限制将要复制的字符串的长度，保证它不超过当初申请的缓冲区的大小。

例如，在上面的代码中，我们在memcpy之前，可以加入一个判断，并且可以对缓冲区溢出进行很好的检查。如果能够设计一些比较好的测试实例把这些判断覆盖到，那么相关的问题就可以得到比较不错的检查了。

    /* testshellcode.c */
    #include <stdio.h>      /* printf */
    #include <string.h> /* memset, memcpy */
    #include <stdlib.h>     /* exit */
    #define BUF_SIZE 8

    #ifdef STR4
    # define STR_SRC "AAAAAAAa1BBBBBBBBCCCCDDDD"
    #endif

    #ifndef STR_SRC
    # define STR_SRC "AAAAAAA"
    #endif

    int func(int a, int b, int c)
    {
            int sum = 0;
            char buffer[BUF_SIZE] = "";

            memset(buffer, &#39;&#39;, BUF_SIZE);
            if ( sizeof(STR_SRC)-1 > BUF_SIZE ) {
                    printf("buffer overflow!n");
                    exit(-1);
            }
            memcpy(buffer, STR_SRC, sizeof(STR_SRC)-1);

            sum = a + b + c;

            return sum;
    }

    int main()
    {
            int sum;

            sum = func(1, 2, 3);

            printf("sum = %dn", sum);

            return 0;
    }


现在的效果如下：

    $ gcc -DSTR4 -g -o testshellcode testshellcode.c
    $ ./testshellcode      #如果存在溢出，那么就会得到阻止并退出，从而阻止可能的破坏
    buffer overflow!
    $ gcc -g -o testshellcode testshellcode.c
    $ ./testshellcode
    sum = 6


当然，如果能够在C标准里头加入对数组操作的限制可能会更好，或者在编译器中扩展对可能引起缓冲区溢出的语法检查。

## 缓冲区注入实例

最后给出一个利用上述缓冲区溢出来进行缓冲区注入的例子。也就是通过往某个缓冲区注入一些代码，并把eip修改为这些代码的入口从而达到破坏目标程序行为的目的。

这个例子来自[Linux下缓冲区溢出攻击的原理及对策][17]，这里主要利用上面介绍的知识对它进行了比较详细的分析。

### 准备：把C语言函数转换为字符串序列

首先回到第一部分，看看那个shellcode.c程序。我们想获取它的汇编代码，并以十六进制字节的形式输出，以便把这些指令当字符串存放起来，从而作为缓冲区注入时的输入字符串。下面通过gdb获取这些内容。

    $ gcc -g -o shellcode shellcode.c
    $ gdb ./shellcode
    GNU gdb 6.6
    ...
    (gdb) disassemble main
    Dump of assembler code for function main:
    ...
    0x08048331 <main+13>:   push   %ecx
    0x08048332 <main+14>:   jmp    0x8048354 <forward>
    0x08048334 <main+16>:   pop    %esi
    0x08048335 <main+17>:   mov    $0x4,%eax
    0x0804833a <main+22>:   mov    $0x2,%ebx
    0x0804833f <main+27>:   mov    %esi,%ecx
    0x08048341 <main+29>:   mov    $0xc,%edx
    0x08048346 <main+34>:   int    $0x80
    0x08048348 <main+36>:   mov    $0x1,%eax
    0x0804834d <main+41>:   mov    $0x0,%ebx
    0x08048352 <main+46>:   int    $0x80
    0x08048354 <forward+0>: call   0x8048334 <main+16>
    0x08048359 <forward+5>: dec    %eax
    0x0804835a <forward+6>: gs
    0x0804835b <forward+7>: insb   (%dx),%es:(%edi)
    0x0804835c <forward+8>: insb   (%dx),%es:(%edi)
    0x0804835d <forward+9>: outsl  %ds:(%esi),(%dx)
    0x0804835e <forward+10>:        and    %dl,0x6f(%edi)
    0x08048361 <forward+13>:        jb     0x80483cf <__libc_csu_init+79>
    0x08048363 <forward+15>:        or     %fs:(%eax),%al
    ...
    End of assembler dump.
    (gdb) set logging on   #开启日志功能，记录操作结果
    Copying output to gdb.txt.
    (gdb) x/52bx main+14  #以十六进制单字节（字符）方式打印出shellcode的核心代码
    0x8048332 <main+14>:    0xeb    0x20    0x5e    0xb8    0x04    0x00    0x00   0x00
    0x804833a <main+22>:    0xbb    0x02    0x00    0x00    0x00    0x89    0xf1   0xba
    0x8048342 <main+30>:    0x0c    0x00    0x00    0x00    0xcd    0x80    0xb8   0x01
    0x804834a <main+38>:    0x00    0x00    0x00    0xbb    0x00    0x00    0x00   0x00
    0x8048352 <main+46>:    0xcd    0x80    0xe8    0xdb    0xff    0xff    0xff   0x48
    0x804835a <forward+6>:  0x65    0x6c    0x6c    0x6f    0x20    0x57    0x6f   0x72
    0x8048362 <forward+14>: 0x6c    0x64    0x0a    0x00
    (gdb) quit
    $ cat gdb.txt | sed -e "s/^.*://g;s/t/\/g;s/^/"/g;s/$/"/g"  #把日志里头的内容处理一下，得到这样一个字符串
    "xebx20x5exb8x04x00x00x00"
    "xbbx02x00x00x00x89xf1xba"
    "x0cx00x00x00xcdx80xb8x01"
    "x00x00x00xbbx00x00x00x00"
    "xcdx80xe8xdbxffxffxffx48"
    "x65x6cx6cx6fx20x57x6fx72"
    "x6cx64x0ax00"


### 注入：在C语言中执行字符串化的代码

得到上面的字符串以后我们就可以设计一段下面的代码啦。

    /* testshellcode.c */
    char shellcode[]="xebx20x5exb8x04x00x00x00"
    "xbbx02x00x00x00x89xf1xba"
    "x0cx00x00x00xcdx80xb8x01"
    "x00x00x00xbbx00x00x00x00"
    "xcdx80xe8xdbxffxffxffx48"
    "x65x6cx6cx6fx20x57x6fx72"
    "x6cx64x0ax00";

    void callshellcode(void)
    {
       int *ret;
       ret = (int *)&ret + 2;
       (*ret) = (int)shellcode;
    }

    int main()
    {
            callshellcode();

            return 0;
    }


运行看看，

    $ gcc -o testshellcode testshellcode.c
    $ ./testshellcode
    Hello World


竟然打印出了Hello World，实际上，如果只是为了让shellcode执行，有更简单的办法，直接把shellcode这个字符串入口强制转换为一个函数入口，并调用就可以，具体见这段代码。

    char shellcode[]="xebx20x5exb8x04x00x00x00"
    "xbbx02x00x00x00x89xf1xba"
    "x0cx00x00x00xcdx80xb8x01"
    "x00x00x00xbbx00x00x00x00"
    "xcdx80xe8xdbxffxffxffx48"
    "x65x6cx6cx6fx20x57x6fx72"
    "x6cx64x0ax00";

    typedef void (* func)();            //定义一个指向函数的指针func，而函数的返回值和参数均为void

    int main()
    {
            (* (func)shellcode)();

            return 0;
    }


### 注入原理分析

这里不那样做，为什么也能够执行到shellcode呢？仔细分析一下callshellcode里头的代码就可以得到原因了。

    int *ret;


这里定义了一个指向整数的指针，ret占用4个字节（可以用sizeof(int *)算出）。

    ret = (int *)&ret + 2;


这里把ret修改为它本身所在的地址再加上两个单位。 首先需要求出ret本身所在的位置，因为ret是函数的一个局部变量，它在栈中偏栈顶的地方。 然后呢？再增加两个单位，这个单位是sizeof(int)，即4个字节。这样，新的ret就是ret所在的位置加上8个字节，即往栈底方向偏移8个字节的位置。对于我们之前分析的shellcode，那里应该是edi，但实际上这里并不是edi，可能是gcc在编译程序时有不同的处理，这里实际上刚好是eip，即执行这条语句之后ret的值变成了eip所在的位置。

    (*ret) = (int)shellcode;


由于之前ret已经被修改为了eip所在的位置，这样对(*ret)赋值就会修改eip的值，即下一条指令的地址，这里把eip修改为了shellcode的入口。因此，当函数返回时直接去执行shellcode里头的代码，并打印了Hello World。

用gdb调试一下看看相关变量的值的情况。这里主要关心ret本身。ret本身是一个地址，首先它所在的位置变成了EIP所在的位置(把它自己所在的位置加上2*4以后赋于自己)，然后，EIP又指向了shellcode处的代码。

    $ gcc -g -o testshellcode testshellcode.c
    $ gdb ./testshellcode
    ...
    (gdb) l
    8       void callshellcode(void)
    9       {
    10         int *ret;
    11         ret = (int *)&ret + 2;
    12         (*ret) = (int)shellcode;
    13      }
    14
    15      int main()
    16      {
    17              callshellcode();
    (gdb) break 17
    Breakpoint 1 at 0x804834d: file testshell.c, line 17.
    (gdb) break 11
    Breakpoint 2 at 0x804832a: file testshell.c, line 11.
    (gdb) break 12
    Breakpoint 3 at 0x8048333: file testshell.c, line 12.
    (gdb) break 13
    Breakpoint 4 at 0x804833d: file testshell.c, line 13.
    (gdb) r
    Starting program: /mnt/hda8/Temp/c/program/testshell

    Breakpoint 1, main () at testshell.c:17
    17              callshellcode();
    (gdb) print $ebp       #打印ebp寄存器里的值
    $1 = (void *) 0xbfcfd2c8
    (gdb) disassemble main
    ...
    0x0804834d <main+14>:   call   0x8048324 <callshellcode>
    0x08048352 <main+19>:   mov    $0x0,%eax
    ...
    (gdb) n

    Breakpoint 2, callshellcode () at testshell.c:11
    11         ret = (int *)&ret + 2;
    (gdb) x/6x $esp
    0xbfcfd2ac:     0x08048389      0xb7f4eff4      0xbfcfd36c      0xbfcfd2d8
    0xbfcfd2bc:     0xbfcfd2c8      0x08048352
    (gdb) print &ret #分别打印ret所在地址和ret，刚好在ebp之上，发现这里并没有
           #之前的testshellcode代码中的edi和esi，可能是gcc在汇编时处理不一样
    $2 = (int **) 0xbfcfd2b8
    (gdb) print ret
    $3 = (int *) 0xbfcfd2d8 #这里的ret是个随机值
    (gdb) n

    Breakpoint 3, callshellcode () at testshell.c:12
    12         (*ret) = (int)shellcode;
    (gdb) print ret   #执行完ret = (int *)&ret + 2;后，ret变成了自己地址加上2*4，
                 #刚好是eip所在的位置。
    $5 = (int *) 0xbfcfd2c0
    (gdb) x/6x $esp
    0xbfcfd2ac:     0x08048389      0xb7f4eff4      0xbfcfd36c      0xbfcfd2c0
    0xbfcfd2bc:     0xbfcfd2c8      0x08048352
    (gdb) x/4x *ret  #此时*ret刚好为eip，0x8048352
    0x8048352 <main+19>:    0x000000b8      0x8d5d5900      0x90c3fc61      0x89559090
    (gdb) n

    Breakpoint 4, callshellcode () at testshell.c:13
    13      }
    (gdb) x/6x $esp #现在eip被修改为了shellcode的入口
    0xbfcfd2ac:     0x08048389      0xb7f4eff4      0xbfcfd36c      0xbfcfd2c0
    0xbfcfd2bc:     0xbfcfd2c8      0x8049560
    (gdb) x/4x *ret  #现在修改了(*ret)的值，即修改了eip的值，使eip指向了shellcode
    0x8049560 <shellcode>:  0xb85e20eb      0x00000004      0x000002bb      0xbaf18900


上面的过程很难弄，呵呵。主要是指针不大好理解，如果直接把它当地址绘出下面的图可能会容易理解一些。

callshellcode栈的初始分布：

    ret=(int *)&ret+2=0xbfcfd2bc+2*4=0xbfcfd2c0
    0xbfcfd2b8      ret(随机值)                     0xbfcfd2c0
    0xbfcfd2bc      ebp(这里不关心)
    0xbfcfd2c0      eip(0x08048352)         eip(0x8049560 )

    (*ret) = (int)shellcode;即eip=0x8049560


总之，最后体现为函数调用的下一条指令指针（eip）被修改为一段注入代码的入口，从而使得函数返回时执行了注入代码。

### 缓冲区注入与防范

这个程序里头的注入代码和被注入程序竟然是一个程序，傻瓜才自己攻击自己（不过有些黑客有可能利用程序中一些空闲空间注入代码哦），真正的缓冲区注入程序是分开的，比如作为被注入程序的一个字符串参数。而在被注入程序中刚好没有做字符串长度的限制，从而让这段字符串中的一部分修改了eip，另外一部分作为注入代码运行了，从而实现了注入的目的。不过这会涉及到一些技巧，即如何刚好用注入代码的入口地址来修改eip（即新的eip能够指向注入代码）？如果eip的位置和缓冲区的位置之间的距离是确定，那么就比较好处理了，但从上面的两个例子中我们发现，有一个编译后有edi和esi，而另外一个则没有，另外，缓冲区的位置，以及被注入程序有多少个参数我们都无法预知，因此，如何计算eip所在的位置呢？这也会很难确定。还有，为了防止缓冲区溢出带来的注入问题，现在的操作系统采取了一些办法，比如让esp随机变化（比如和系统时钟关联起来），所以这些措施将导致注入更加困难。如果有兴趣，你可以接着看看最后的几篇参考资料并进行更深入的研究。

需要提到的是，因为很多程序可能使用strcpy来进行字符串的复制，在实际编写缓冲区注入代码时，会采取一定的办法（指令替换），把代码中可能包含的&#92;0字节去掉，从而防止strcpy中断对注入代码的复制，进而可以复制完整的注入代码。具体的技巧可以参考[Linux下缓冲区溢出攻击的原理及对策][17]，[Shellcode技术杂谈][18]，[virus-writing-HOWTO][19]。

## 后记

实际上缓冲区溢出应该是语法和逻辑方面的双重问题，由于语法上的不严格（对数组边界没有检查）导致逻辑上可能出现严重缺陷（程序执行行为被改变）。另外，这类问题是对程序运行过程中的程序映像的栈区进行注入。实际上除此之外，程序在安全方面还有很多类似的问题。比如，虽然程序映像的正文区受到系统保护（只读），但是如果内存（硬件本身，内存条）出现故障，在程序运行的过程中，程序映像的正文区的某些字节就可能被修改了，也可能发生非常严重的后果，因此程序运行过程的正文区检查等可能的手段需要被引入。

## 参考资料

  * Playing with ptrace
      * [how ptrace can be used to trace system calls and change system call arguments][20]
      * [setting breakpoints and injecting code into running programs][21]
      * [fix the problem of ORIG_EAX not defined][22]
  * [《缓冲区溢出攻击—— 检测、剖析与预防》第五章][23]
  * [Linux下缓冲区溢出攻击的原理及对策][17]
  * [Linux 汇编语言开发指南][24]
  * [Shellcode技术杂谈][18]





 [2]: http://tinylab.org
 [3]: /open-c-book/
 [4]: http://weibo.com/tinylaborg
 [5]: http://www.x86.org/intel.doc/386manuals.htm
 [6]: http://www.faqs.org/faqs/assembly-language/x86/general/part1/
 [7]: http://www.faqs.org/faqs/assembly-language/x86/general/part2/
 [8]: http://www.faqs.org/faqs/assembly-language/x86/general/part3/
 [9]: http://www.x86.org/ftp/manuals/tools/elf.pdf
 [10]: http://www.xfocus.net/articles/200105/174.html
 [11]: http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
 [12]: http://www.muppetlabs.com/~breadbox/software/elfkickers.html
 [13]: http://dslab.lzu.edu.cn:8080/members/zhangwei/doc/KFT-HOWTO
 [14]: http://edu.stuccess.com/KnowCenter/Unix/13/hellguard_unix_faq/00000089.htm
 [15]: http://linux.jinr.ru/usoft/WWW/www_debian.org/Documentation/elf/elf.html
 [16]: http://womking.bokee.com/5967668.html
 [17]: http://www.ibm.com/developerworks/cn/linux/l-overflow/index.html
 [18]: http://janxin.bokee.com/4067220.html
 [19]: http://virus.bartolich.at/virus-writing-HOWTO/_html/
 [20]: http://www.linuxjournal.com/article/6100
 [21]: http://www.linuxjournal.com/node/6210/print
 [22]: http://www.ecos.sourceware.org/ml/libc-hacker/1998-05/msg00277.html
 [23]: http://book.csdn.net/bookfiles/228/index.html
 [24]: http://www.ibm.com/developerworks/cn/linux/l-assembly/index.html
