---
layout: post
author: 'Wu Zhangjin'
title: "为 a.out 举行一个特殊的告别仪式"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /goodbye-a.out/
description: "Linux v5.1 启动了告别 a.out 的第一步，已经无法通过内核配置简单启用 a.out，另外 a.out 的 coredump 代码已经全部被移除。这么一个 Linux 最早支持的执行文件格式即将退出历史舞台，令人感叹。"
category:
  - 程序执行
tags:
  - a.out
  - coff
  - elf
---

> By Falcon of [TinyLab.org][1]
> Aug 18, 2019

## v5.1 开始剔除 a.out 格式

在 [Linux 发布 5.1, Linux Lab 同步支持](http://tinylab.org//linux-5.1/) 一文中，首次得知了 Linux 移除 a.out 格式的消息，这个消息着实令人感叹，因为 a.out 伴随 Linux 的诞生至今在 Linux 中有将近 ~28 年的历史，而 a.out 本身则要追溯到更早的 Unix 时代。

下面是 v5.1 中两笔剔除 a.out 的动作：

    $ git log --oneline v5.0..v5.1 | grep "a\.out"
    eac6165 x86: Deprecate a.out support
    08300f4 a.out: remove core dumping support

第 2 笔是 Linus 亲自改的，理由是 a.out 的 core dumping 功能年久失修了，而更进一步，因为 ELF 自 1994 年进入 Linux 1.0 以来，已经 ~25 年了，而且现在基本上找不到能产生 a.out 格式的编译器，所以 Borislav Petkov 直接在 x86 上把 `HAVE_AOUT` “干掉”，因此没法打开配置了。

## a.out 核心代码还在

当然，大佬们做事还留有一点余地：

> Linux supports ELF binaries for ~25 years now.  a.out coredumping has
> bitrotten quite significantly and would need some fixing to get it into
> shape again but considering how even the toolchains cannot create a.out
> executables in its default configuration, let's deprecate a.out support
> and remove it a couple of releases later, instead.

这意味着目前的 a.out 代码核心还在，想要用，把上面第 1 条变更 Revert 掉即可配置，可能涉及冲突要修复，如果嫌麻烦，对照 `git show eac6165`，简单加回 `HAVE_AOUT` 即可：

    $ git revert eac6165

笔者试着恢复以后，确实可以进行 a.out 的配置了。

## 准备一个支持 a.out 的内核

可以用 [Linux Lab](https://gitee.com/tinylab/linux-lab) 来快速验证。

    $ git clone https://gitee.com/tinylab/cloud-lab
    $ cd cloud-lab
    $ tools/docker/run linux-lab

上面的命令正常会拉起来一个浏览器，并自动登陆进一个 LXDE 桌面，进去后，打开控制台，即可参考 README.md 依次完成下述动作。

选择 `i386/pc` 作为测试板子：

    $ make BOARD=i386/pc

并开始内核的下载、检出、配置、编译和运行：

    $ make kernel-download
    $ make kernel-checkout
    $ make kernel-defconfig
    $ make kernel-menuconfig

上述命令会启动配置，在配置里头打开：

> Executable file formats --->
>
>   Kernel support for a.out and ECOFF binaries

接着完成编译并通过 nfsroot 启动：

    $ make kernel
    $ make boot ROOTDEV=/dev/nfs

通过 nfsroot 启动主要是方便后面在 qemu guest 和 qemu host 之间共享文件。这里也可以用 9pnet：

    $ make boot SHARE=1

用 nfsroot 的话，共享目录 host 为 `boards/i386/pc/bsp/root/2019.02.2/rootfs`，guest 为根目录。

用 9pnet 的话，共享目录 host 为 `hostshare`，guest 为 `/hostshare`。也可以自行通过 `SHARE_DIR` 指定位置：

    $ make boot SHARE=1 SHARE_DIR=$PWD/hostshare

## 尝试运行 a.out 格式

不过未来两三个版本以后，a.out 可能很快就被完全移除掉。

**在 a.out 彻底被删除之前，来举行一个告别仪式吧**：那就是尝试在 Linux v5.1 上跑一个真正的 a.out 格式的可执行文件。

既然 Linus 都说已经没有工具链默认能够生成 a.out 可执行文件，那怎么办呢？

### 你所看到的 a.out 并不是 a.out 格式

大家可能会说，gcc 默认编译生成的不就是 a.out 么？非也，此 a.out 非彼 a.out。

gcc 默认生成的 a.out 的实际格式是 ELF：

    $ echo 'int main(void){ return 0; }' | gcc -x c - -
    $ file a.out
    a.out: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/l, for GNU/Linux 2.6.32, BuildID[sha1]=baede5e2d5c16ba4b13a0e9d355acad2d237f6a7, not stripped

为什么 gcc 默认把 ELF 格式的可执行文件也默认取名为 a.out 呢？这个主要是历史沿革。

a.out 作为最早的可执行文件格式，其本意是 Assembler Output 的缩写。

虽然，现如今，汇编完还加入了链接环节，甚至还有动态链接环节，伴随着地是可执行文件格式从 a.out, COFF 到 ELF 一路演化下来，但是长久以来，这个 a.out 的默认名字却保留了下来。

### gcc 不行，试试 objcopy 格式转换

既然现在的 gcc 默认不支持生成 a.out 格式，那尝试用 objcopy 转换看看，发现也不成功。

    $ objcopy -O a.out-i386-linux a.out a.out-elf
    objcopy: a.out-elf: can not represent section `.interp' in a.out object file format
    objcopy:a.out-elf[.interp]: Nonrepresentable section on output

既然不支持 `.interp`，那用一个不需要库函数的程序试试，[Linux Lab](https://gitee.com/tinylab/linux-lab) 在 [examples/assembly/x86](https://gitee.com/tinylab/linux-lab/tree/master/examples/assembly/x86) 下提供了这样一个汇编程序。

    $ cd (linux-lab)/examples/assembly/x86
    $ make
    $ objcopy -O a.out-i386-linux x86-hello x86-hello-a.out$ file x86-hello-a.out
    x86-hello-a.out: Linux/i386 demand-paged executable (ZMAGIC)

不幸地是，转换成功了，但是并不能执行。

    $ ./x86-hello-a.out
    ./x86-hello-a.out: line 1: syntax error: unterminated quoted string

这说明 ZMAGIC a.out 不知道哪天开始已经失效了。那 QMAGIC 呢，可是，目前没找到合适的方法强制转换为 QMAGIC 类型，欢迎读者们反馈补充。

关于 ZMAGIC 和 QMAGIC 的说明如下，摘自 [A.OUT Manual page](https://nxmnpg.lemoda.net/5/a.out)：

> OMAGIC
>  	The text and data segments immediately follow the header and are contiguous. The kernel loads both text and data segments into writable memory.
> NMAGIC
>  	As with OMAGIC, text and data segments immediately follow the header and are contiguous. However, the kernel loads the text into read-only memory and loads the data into writable memory at the next page boundary after the text.
> ZMAGIC
>  	The kernel loads individual pages on demand from the binary. The header, text segment and data segment are all padded by the link editor to a multiple of the page size. Pages that the kernel loads from the text segment are read-only, while pages from the data segment are writable.

### 试试 Linux 0.11

暂时还不该放弃努力，因为 a.out 是 Linux 一早就支持的格式，那为什么不试试 Linux 0.11，正好 [Linux 0.11 Lab](https://gitee.com/tinylab/linux-0.11-lab) 还提供了一个可以在 Linux 0.11 上运行的编译器。

#### 准备 Linux 0.11 Lab

Linux 0.11 Lab 可以直接在 Linux Lab 下跑，可以在 Linux Lab 中把它也 clone 到 `/labs` 目录下：

    $ cd /labs
    $ git clone https://gitee.com/tinylab/linux-0.11-lab

#### 准备 Hello.s

接着先准备好一个可以在 Linux 0.11 编译的程序，可以直接用标准的 hello.c，也可以用汇编，这里直接复用上面的 `examples/assembly/x86/x86-hello.s`，把它复制到 Linux 0.11 的磁盘中，并稍作改动即可：

    $ make mount-hd

    $ sudo cp ../linux-lab/examples/assembly/x86/x86-hello.s rootfs/_hda/usr/root/

    $ sudo diff -Nubr ../linux-lab/examples/assembly/x86/x86-hello.s rootfs/_hda/usr/root/x86-hello.s
    --- ../linux-lab/examples/assembly/x86/x86-hello.s	2019-04-27 03:02:26.685203102 +0000
    +++ rootfs/_hda/usr/root/x86-hello.s	2019-08-17 21:28:25.000000000 +0000
    @@ -1,12 +1,12 @@
     .data                   # section declaration
     msg:
    -    .string "Hello, world!\n"
    +    .ascii "Hello, world!\n"
         len = . - msg   # length of our dear string
     .text                   # section declaration
                             # we must export the entry point to the ELF linker or
    -    .global _start      # loader. They conventionally recognize _start as their
    +    .globl _main        # loader. They conventionally recognize _start as their
                             # entry point. Use ld -e foo to override the default.
    -_start:
    +_main:
     # write our string to stdout
         movl    $len,%edx   # third argument: message length
         movl    $msg,%ecx   # second argument: pointer to message to write

    $ sync
    $ make umount-hd

主要老版本 gcc 不支持 `.string`，需要用 `.ascii` 替换，另外默认入口需要改为 `_main`，而不再是 `_start`。

#### 在 Linux 0.11 中编译 Hello.s

之后进入 Linux 0.11 Lab 并启动 Linux 0.11，这里选择从硬盘加载文件系统，其他文件系统不带编译器：

    $ cd linux-0.11-lab
    $ make boot-hd

启动以后，编译并验证一下：

    $ gcc x86-hello.s
    $ ./a.out
    Hello, world!

如果需要编辑，记得通过 `mkdir /tmp` 创建一个 `/tmp` 目录，然后就可以用 vi 直接在 Linux 0.11 编辑代码了。

### 在 Linux Lab 中运行 QMAGIC a.out

之后，重新把磁盘挂起，通过 9pnet 指定相应目录为共享目录，这样就可以直接在 Linux 中运行了。

    $ make mount-hd
    $ ls rootfs/_hda/usr/root/
    a.out x86-hello.s

    $ sudo file rootfs/_hda/usr/root/a.out
    rootfs/_hda/usr/root/a.out: a.out little-endian 32-bit demand paged pure executable not stripped

    $ cd ../linux-lab
    $ make boot SHARE=1 SHARE_DIR=$PWD/../linux-0.11-lab/rootfs/_hda/usr/root/
    ...
    # /hostshare/a.out
    fd_offset is not page aligned. Please convert program: a.out
    Hello, world!

### 试试从 a.out 到 ELF 的转换

虽然上面的 ELF 转换成 ZMAGIC a.out，无法正常运行，但是反过来呢？试着从 QMAGIC a.out 转换为 ELF，竟然可以运行成功：

    $ objcopy -O elf32-i386 a.out elf-hello
    $ file ./elf-hello
    elf-hello: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), statically linked, not stripped
    $ sudo ./elf-hello
    Hello, world!

补充一下，用 `objcopy --info` 可以列出支持的所有格式：

    $ objcopy --info
           a.out-i386-linux pei-i386 pei-x86-64 elf64-l1om elf64-k1om
      i386 a.out-i386-linux pei-i386 pei-x86-64 ---------- ----------
      l1om ---------------- -------- ---------- elf64-l1om ----------
      k1om ---------------- -------- ---------- ---------- elf64-k1om
     iamcu ---------------- -------- ---------- ---------- ----------
    plugin ---------------- -------- ---------- ---------- ----------

需要补充一点，上面如果直接运行 `./elf-hello`，会出现段错误，留待后续分解吧。

## 小结

到这里为止，经过诸多努力，终于在 a.out 彻底被从官方 Linux 剔除之前，完成了一次运行的尝试。

在这个基础上，未来，就有机会更深度地分析 a.out，COFF 到 ELF 三种格式以及它们的演进历程。

[1]: http://tinylab.org
