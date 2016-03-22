---
title: Shell 编程范例之文件操作
author: Wu Zhangjin
layout: post
album: Shell 编程范例
permalink: /shell-programming-paradigms-of-file-operations/
tags:
  - Bash
  - 编程范例
  - Shell
  - 文件操作
  - 例子
categories:
  - Shell
---

> by falcon of [TinyLab.org][2]
> 2007-11-5


## 前言

这一周我们来探讨文件操作。

在日常学习和工作中，我们总是在不断地和各种文件打交道，这些文件包括普通的文本文件，可以执行的程序文件，带有控制字符的文档、存放各种文件的目录文件、网络套接字文件、设备文件等。这些文件又具有诸如属主、大小、创建和修改日期等各种属性。文件对应文件系统的一些数据块，对应磁盘等存储设备的一片连续空间，对应于显示设备却是一些具有不同形状的字符集。

在这一节，为了把关注点定位在文件本身，我们不会深入探讨文件系统以及存储设备是如何组织文件的（在后续章节再深入探讨），而是探讨我们对它最熟悉的一面，即把文件当成是一序列的字符（一个 byte ）集合看待。因此之前介绍的 [ 《 Shell 编程范例之字符串操作》 ][3] 在这里将会得到广泛的应用，关于普通文件的读写操作我想我们已经用得非常熟练啦，那就是“重定向”，在这里，我们会把这部分独立出来介绍。关于文件在 Linux 下的“数字化”（文件描述符）高度抽象，“一切皆为文件”的哲学在 Shell 编程里也得到了深刻的体现。

下面我们先来介绍文件的各种属性，然后介绍普通文件的一般操作。

## 文件的各种属性

首先，我们通过文件的结构体来看看文件到底有哪些属性：

<pre>struct stat {
dev_t st_dev; /* 设备   */
ino_t st_ino; /* 节点   */
mode_t st_mode; /* 模式   */
nlink_t st_nlink; /* 硬连接 */
uid_t st_uid; /* 用户ID */
gid_t st_gid; /* 组ID   */
dev_t st_rdev; /* 设备类型 */
off_t st_off; /* 文件字节数 */
unsigned long  st_blksize; /* 块大小 */
unsigned long st_blocks; /* 块数   */
time_t st_atime; /* 最后一次访问时间 */
time_t st_mtime; /* 最后一次修改时间 */
time_t st_ctime; /* 最后一次改变时间(指属性) */
};
</pre>

下面逐次来了解这些属性，如果需要查看某个文件的属性，用 stat 命令就可以，会按照上面的结构体把信息列出来。另外， ls 命令在跟上一定的参数后也可以显示文件的相关属性，比如 -l 参数。

### 文件类型

文件类型对应于上面的 st_mode,  文件类型有很多，比如常规文件、符号链接（硬链接、软链接）、管道文件、设备文件 ( 符号设备、块设备 ) 、 socket 文件等，不同的文件类型对应不同的功能和作用。

#### 范例：在命令行简单地区分各类文件

<pre>$ ls -l
total 12
drwxr-xr-x 2 root root 4096 2007-12-07 20:08 directory_file
prw-r--r-- 1 root root    0 2007-12-07 20:18 fifo_pipe
brw-r--r-- 1 root root 3, 1 2007-12-07 21:44 hda1_block_dev_file
crw-r--r-- 1 root root 1, 3 2007-12-07 21:43 null_char_dev_file
-rw-r--r-- 2 root root  506 2007-12-07 21:55 regular_file
-rw-r--r-- 2 root root  506 2007-12-07 21:55 regular_file_hard_link
lrwxrwxrwx 1 root root   12 2007-12-07 20:15 regular_file_soft_link -> regular_file
$ stat directory_file/
  File: `directory_file/'
  Size: 4096            Blocks: 8          IO Block: 4096   directory
Device: 301h/769d       Inode: 521521      Links: 2
Access: (0755/drwxr-xr-x)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2007-12-07 20:08:18.000000000 +0800
Modify: 2007-12-07 20:08:18.000000000 +0800
Change: 2007-12-07 20:08:18.000000000 +0800
$ stat null_char_dev_file
  File: `null_char_dev_file'
  Size: 0               Blocks: 0          IO Block: 4096   character special file
Device: 301h/769d       Inode: 521240      Links: 1     Device type: 1,3
Access: (0644/crw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2007-12-07 21:43:38.000000000 +0800
Modify: 2007-12-07 21:43:38.000000000 +0800
Change: 2007-12-07 21:43:38.000000000 +0800
</pre>

说明 :  在 ls 命令结果每行的第一个字符我们可以看到，它们之间都不相同，这正好反应了不同文件的类型。 d 表示目录， - 表示普通文件（或者硬链接）， l 表示符号链接， p 表示管道文件， b 和 c 分别表示块设备和字符设备（另外 s 表示 socket 文件）。在 stat 命令的结果中，我们可以在第二行的最后找到说明，从上面的操作可以看出， directory\_file 是目录， stat 命令的结果中用 directory 表示，而 null\_char\_dev\_file 它则用 character special file 说明。

#### 范例：简单比较它们的异同

通常，我们只会用到目录、普通文件、以及符号链接，很少碰到其他类型的文件，不过这些文件还是各有用处的，如果要做嵌入式开发或者进程通信等，你可能会涉及到设备文件、有名管道 (FIFO) 。下面我们通过简单的操作来反应它们之间的区别（具体的原理可能会在下一节《 Shell 编程范例之文件系统》介绍，如果感兴趣，也可以提前到网上找找设备文件的作用、快设备和字符设备的区别、以及驱动程序中如何编写相关设备驱动等）。

对于普通文件：就是一序列字符的集合，所以可以读、写等

<pre>$ echo "hello, world" > regular_file
$ cat regular_file
hello, world
</pre>

目录文件下，我们可以创建新的文件，所以目录文件还有叫法：文件夹，到后面我们会分析目录文件的结构体，它实际上存放了它下面的各个文件的文件名。

<pre>$ cd directory_file
$ touch file1 file2 file3
</pre>

对于有名管道，操作起来比较有意思：如果你要读它，除非有内容，否则阻塞；如果你要写它，除非有人来读，否则阻塞。它常用于进程通信中。你可以打开两个终端 terminal1 和 terminal2 ，试试看：

<pre>terminal1$ cat fifo_pipe   #刚开始阻塞在这里，直到下面的写动作发生，才打印test字符串
terminal2$ echo "test" > fifo_pipe
</pre>

关于块设备，字符设备，上面的两个设备文件对应于 /dev/hda1 和 /dev/null ，如果你用过 u 盘，或者是写过简单的脚本的话，这样的用法你应该用过 :-) 

<pre>$ mount hda1_block_dev_file /mnt   #挂载硬盘的第一个分区到/mnt下（关于挂载的原理，我们在下一节讨论）
$ echo "fewfewfef" > /dev/null  #/dev/null像个黑洞，什么东西丢进去都消失殆尽
</pre>

最后两个文件分别是 regular_file 文件的硬链接和软链接，你去读写它们，他们的内容是相同的，不过你去删除它们，他们去互不相干，硬链接和软链接又有什么不同呢？前者可以说就是原文件，后者呢只是有那么一个 inode ，但没有实际的存储空间，建议用 stat 命令查看它们之间的区别，包括它们的 Blocks,inode 等值，也可以考虑用 diff 比较它们的大小。

<pre>$ ls regular_file*
ls regular_file* -l
-rw-r--r-- 2 root root 204800 2007-12-07 22:30 regular_file
-rw-r--r-- 2 root root 204800 2007-12-07 22:30 regular_file_hard_link
lrwxrwxrwx 1 root root     12 2007-12-07 20:15 regular_file_soft_link -> regular_file
$ rm regular_file      # 删除原文件
$ cat regular_file_hard_link   # 硬链接还在，而且里头的内容还有呢
fefe
$ cat regular_file_soft_link
cat: regular_file_soft_link: No such file or directory
</pre>

虽然软链接文件本身还在，不过因为它本身不存储内容，所以读不到东西拉，这就是软链接和硬链接的区别，该知道则么用它们了吧。

另外，需要注意的是，硬链接不可以跨文件系统，而软链接则可以。另外，也不不允许给目录创建硬链接。

#### 范例：普通文件再分类

文件类型从 Linux 文件系统那么一个级别分了以上那么多类型，不过普通文件还是可以再分的（根据文件内容的”数据结构“分），比如常见的文本文件，可执行的 ELF 文件， odt 文档， jpg 图片格式， swap 分区文件， pdf 文件。除了文本文件外，它们大多是二进制文件，有特定的结构，因此需要有专门的工具来创建和编辑它们。关于各类文件的格式，可以参考相关文档标准。不过如果能够了解 Linux 下可执行的 ELF 文件的工作原理，可能对你非常有用。所以，如果有兴趣，建议阅读一下参考资料中和 ELF 文件相关部分。

虽然各类普通文件都有专属的操作工具，但是我们还是可以直接读、写它们，这里先提到这么几个工具，回头讨论细节。

od ：以八进制或者其他格式“导出”文件内容。 strings ：读出文件中的字符 ( 可打印的字符 ) gcc,gdb,readelf,objdump 等： ELF 文件分析、处理工具（ gcc 编译器、 gdb 调试器、 readelf 分析 elf 文件， objdump 反编译工具）

这里补充一个非常重要的命令， file ，这个命令用来查看各类文件的属性。和 stat 命令相比，它可以进一步识别普通文件，即 stat 命令显示的 regular file 。因为 regular file 可以有各种不同的结构，因此在操作系统的支持下得到不同的解释，执行不同的动作。虽然， Linux 下，文件也会加上特定的后缀以便用户能够方便地识别文件的类型，但是 Linux 操作系统根据文件头识别各类文件，而不是文件后缀，这样，在解释相应的文件时就更不容易出错。下面我们简单介绍 file 命令的用法。

<pre>$ file ./
./: directory
$ file /etc/profile
/etc/profile: ASCII English text
$ file /lib/libc-2.5.so
/lib/libc-2.5.so: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), not stripped
$ file /bin/test
/bin/test: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically linked (uses shared libs), stripped
$ file /dev/hda
/dev/hda: block special (3/0)
$ file /dev/console
/dev/console: character special (5/1)
$ cp /etc/profile .
$ tar zcf profile.tar.gz profile
$ file profile.tar.gz
profile.tar.gz: gzip compressed data, from Unix, last modified: Tue Jan  4 18:53:53 2000
$ mkfifo fifo_test
$ file fifo_test
fifo_test: fifo (named pipe)
</pre>

更多用法见 file 命令的手册，关于 file 命令的实现原理，请参考 magic 的手册（看看 /etc/file/magic 文件，了解什么是文件的 magic number 等）。

### 文件属主

 Linux 作为一个多用户系统，为多用户使用同一个系统提供了极大的方便，比如对于系统上的文件，它通过属主来区分不同的用户，以便分配它们对不同文件的操作权限。为了更方便地管理，文件属主包括该文件所属用户，以及该文件所属的用户组，因为用户可以属于多个组。我们先来简单介绍 Linux 下用户和组的管理。

 Linux 下提供了一组命令用于管理用户和组，比如用户创建它们的 useradd 和 groupadd ，用户删除它们的 userdel 和 groupdel ，另外， passwd 命令用于修改用户密码。当然， Linux 还提供了两个相应的配置，即 /etc/passwd 和 /etc/group ，另外，有些系统还把密码单独放到了配置文件 /etc/shadow 中。关于它们的详细用法请参考后面的资料，在这里我们不介绍了，仅介绍文件和用户之间的一些关系。

#### 范例：修改文件的属主

<pre>$ chown 用户名:组名 文件名
</pre>

如果要递归地修改某个目录下所有文件的属主，可以添加 -R 选项。

在本节开头我们列的文件结构体中，可以看到仅仅有用户 ID 和组 ID 的信息，但 ls -l 的结果却显示了用户名和组名信息，这个是怎么实现的呢？下面先看看 -n 的结果：

#### 范例：查看文件的属主

<pre>$ ls -n regular_file
-rw-r--r-- 1 0 0 115 2007-12-07 23:45 regular_file
$ ls -l regular_file
-rw-r--r-- 1 root root 115 2007-12-07 23:45 regular_file
</pre>

#### 范例：分析文件属主实现的背后原理

可以看到， ls -n 显示了用户 ID 和组 ID ，而 ls -l 显示了它们的名字。还记得上面提到的两个配置文件 /etc/passwd 和 /etc/group 文件么？它们分别存放了用户 ID 和用户名，组 ID 和组名的对应关系，因此很容易想到 ls -l 命令在实现时是如何通过文件结构体的 ID 信息找到它们对应的名字信息的。如果想对 ls -l 命令的实现有更进一步的了解，可以用 strace 跟踪看看它是否读取了 /etc/passwd 和 /etc/group 这个两个文件。

<pre>$ strace -f -o strace.log ls -l regular_file
$ cat strace.log | egrep "passwd|group|shadow"
2989  open("/etc/passwd", O_RDONLY)     = 3
2989  open("/etc/group", O_RDONLY)      = 3
</pre>

说明： strace 是一个非常有用的工具，可以用来跟踪系统调用和信号。如同 gdb 等其他强大的工具一样，它基于系统的 ptrace 系统调用实现，所以如果你感兴趣，可以好好研究一下这个工具。

实际上，把属主和权限分开介绍不太好，因为只有它们两者结合才使得多用户系统成为可能，否则无法隔离不同用户对某个文件的操作，所以下面来介绍文件操作权限。

### 文件权限

从 ls -l 命令的结果的第一列的后 9 个字符中，我们可以看到类似这样的信息 rwxr-xr-x ，它们对应于文件结构体的 st\_mode 部分（ st\_mode 包含文件类型信息和文件权限信息两部分）。这类信息可以分成三部分，即 rwx,r-x,r-x, 分别对应该文件所属用户，所属组，其他组对该文件的操作权限，如果有 rwx 中任何一个表示可读、可写、可执行，如果为 - 表示没有这个权限。对应的，可以用八进制来表示它，比如 rwxr-xr-x 就可表示成二进制 111101101 ，对应的八进制则为 755 。正是因为这样，我们要修改文件的操作权限时，也可以有多种方式来实现，它们都可通过 chmod 命令来修改。

#### 范例：给文件添加读、写、可执行权限

比如，把 regular_file 的文件权限修改为所有用户都可读、可写、可执行，即 rwxrwxrwx ，也可表示为 111111111 ，翻译成八进制，则为 777 。这样就可以通过两种方式修改这个权限。

<pre>$ chmod a+rwx regular_file
</pre>

或

<pre>$ chmod 777 regular_file
</pre>

说明： a 指所用用户，如果只想给用户本身可读可写可执行权限，那么可以把 a 换成 u ；而 + 就是添加权限，相反的，如果想去掉某个权限，用 - ，而 rwx 则对应可读、可写、可执行。更多用法见 chmod 命令的帮助。

实际上除了这些权限外，还有两个涉及到安全方面的权限，即 setuid/setgid 和只读控制等。

如果设置了文件（程序或者命令）的 setuid/setgid 权限，那么用户将可用 root 身份去执行该文件，因此，这将可能带来安全隐患；如果设置了文件的只读权限，那么用户将仅仅对该文件将有可读权限，这为避免诸如 rm -rf 的“可恶”操作带来一定的庇佑。

#### 范例：授权普通用户执行root所属命令

默认情况下，系统是不允许普通用户执行passwd命令的，通过setuid/setgid，可以授权普通用户执行它。

<pre>$ ls -l /usr/bin/passwd
-rwx--x--x 1 root root 36092 2007-06-19 14:59 /usr/bin/passwd
$ su      #切换到root用户，给程序或者命令添加“粘着位”
$ chmod +s /usr/bin/passwd
$ ls -l /usr/bin/passwd
-rws--s--x 1 root root 36092 2007-06-19 14:59 /usr/bin/passwd
$ exit
$ passwd #普通用户通过执行该命令，修改自己的密码
</pre>

说明：

> setuid 和setgid位是让普通用户可以以root用户的角色运行只有root帐号才能运行的程序或命令。

虽然这在一定程度上为管理提供了方便，比如上面的操作让普通用户可以修改自己的帐号，而不是要 root 帐号去为每个用户做这些工作。关于 setuid/setgid 的更多详细解释，请参考最后推荐的资料。

#### 范例：给重要文件加锁

只读权限示例：给重要文件加锁(添加不可修改位[immutable]))，以避免各种误操作带来的灾难性后果（例如: rm -rf）

<pre>$ chattr +i regular_file
$ lsattr regular_file
----i-------- regular_file
$ rm regular_file      #加了immutable位以后，你无法对文件进行任何“破坏性”的活动啦
rm: remove write-protected regular file `regular_file'? y
rm: cannot remove `regular_file': Operation not permitted
$ chattr -i regular_file #如果想对它进行常规操作，那么可以把这个位去掉
$ rm regular_file
</pre>

说明： chattr 可以用设置文件的特殊权限，更多用法请参考 chattr 的帮助。

### 文件大小

普通文件是文件内容的大小，而目录作为一个特殊的文件，它存放的内容是以目录结构体组织的各类文件信息，所以目录的大小一般都是固定的，它存放的文件个数自然也就有上限，即少于它的大小除以文件名的长度。设备文件的文件大小则对应设备的主、次设备号，而有名管道文件因为特殊的读写性质，所以大小常是 0 。硬链接（目录文件不能创建硬链接）实质上是原文件的一个完整的拷比，因此，它的大小就是原文件的大小。而软链接只是一个 inode ，存放了一个指向原文件的指针，因此它的大小仅仅是原文件名的字节数。下面我们通过演示增加记忆。

#### 范例：查看普通文件和链接文件

原文件，链接文件文件大小的示例：

<pre>$ echo -n "abcde" > regular_file   #往regular_file写入5字节
$ ls -l regular_file*
-rw-r--r-- 2 root root  5 2007-12-08 15:28 regular_file
-rw-r--r-- 2 root root  5 2007-12-08 15:28 regular_file_hard_file
lrwxrwxrwx 1 root root 12 2007-12-07 20:15 regular_file_soft_link -> regular_file
lrwxrwxrwx 1 root root 22 2007-12-08 15:21 regular_file_soft_link_link -> regular_file_soft_link
$ i="regular_file"
$ j="regular_file_soft_link"
$ echo ${#i} ${#j}   #可以参考，软链接存放的刚好是它们指向的原文件的文件名的字节数
12 22
</pre>

#### 范例：查看设备文件

设备号对应的文件大小：主、次设备号

<pre>$ ls -l hda1_block_dev_file
brw-r--r-- 1 root root 3, 1 2007-12-07 21:44 hda1_block_dev_file
$ ls -l null_char_dev_file
crw-r--r-- 1 root root 1, 3 2007-12-07 21:43 null_char_dev_file
</pre>

补充：主 (major) 、次 (minor) 设备号的作用有不同。当一个设备文件被打开时，内核会根据主设备号（ major number ）去查找在内核中已经以主设备号注册的驱动（可以 cat /proc/devices 查看已经注册的驱动号和主设备号的对应情况），而次设备号（ minor number ）则是通过内核传递给了驱动本身（参考《 The Linux Primer 》第十章）。因此，对于内核而言，通过主设备号就可以找到对应的驱动去识别某个设备，而对于驱动而言，为了能够更复杂地访问设备，比如访问设备的不同部分（如硬件通过分区分成不同部分，而出现 hda1,hda2,hda3 等），比如产生不同要求的随机数（如 /dev/random 和 /dev/urandom 等）。

#### 范例：查看目录

目录文件的大小，为什么是这样呢？看看下面的目录结构体的大小，目录文件的Block中存放的该目录下所有文件名的入口。

<pre>$ ls -ld directory_file/
drwxr-xr-x 2 root root 4096 2007-12-07 23:14 directory_file/
</pre>

目录的结构体如下：

<pre>struct dirent {
long d_ino;
off_t d_off;
unsigned short d_reclen;
char d_name[NAME_MAX+1]; /* 文件名称 */
}
</pre>

### 文件访问、更新、修改时间

文件的时间属性可以记录用户对文件的操作信息，在系统管理、判断文件版本信息等情况下将为管理员提供参考。因此，在阅读文件时，建议用 cat 等阅读工具，不要用编辑工具 vim 去阅读，因为即使你没有做任何修改操作，一旦你执行了保存命令，你将修改文件的时间戳信息。

### 文件名

文件名并没有存放在文件结构体里，而是存放在它所在的目录结构体中。所以，在目录的同一级别中，文件名必须是唯一的。

## 文件的基本操作

对于文件，常见的操作包括创建、删除、修改、读、写等。关于各种操作对应的“背后动作”我们将在下一章《 Shell 编程范例之文件系统操作》详细分析。

### 范例：创建文件

socket文件是一类特殊的文件，可以通过C语言创建，这里不做介绍（暂时不知道是否可以用命令直接创建），其他文件我们将通过命令创建。

<pre>$ touch regular_file      #创建普通文件
$ mkdir directory_file     #创建目录文件，目录文件里头可以包含更多文件
$ ln regular_file regular_file_hard_link  #硬链接，是原文件的一个完整拷比
$ ln -s regular_file regular_file_soft_link  #类似一个文件指针，指向原文件
$ mkfifo fifo_pipe   #或者通过 "mknod fifo_pipe p" 来创建，FIFO满足先进先出的特点
$ mknod hda1_block_dev_file b 3 1  #块设备
$ mknod null_char_dev_file c 1 3   #字符设备
</pre>

创建一个文件实际上是在文件系统中添加了一个节点（ inode) ，该节点信息将保存到文件系统的节点表中。更形象地说，就是在一颗树上长了一颗新的叶子（文件）或者枝条（目录文件，上面还可以长叶子的那种），这些可以通过 tree 命令或者 ls 命令形象地呈现出来。文件系统从日常使用的角度，完全可以当成一颗倒立的树来看，因为它们太像了，太容易记忆啦。

<pre>$ tree 当前目录
</pre>

或者

<pre>$ ls 当前目录
</pre>

### 范例：删除文件

删除文件最直接的印象是这个文件再也不存在啦，这同样可以通过 ls 或者 tree 命令呈现出来，就像树木被砍掉一个分支或者摘掉一片叶子一样。实际上，这些文件删除之后，并不是立即消失了，而是仅仅做了删除标记，因此，如果删除之后，没有相关的磁盘写操作把相应的磁盘空间“覆盖”，那么原理上是可以恢复的（虽然如此，但是这样的工作往往是很麻烦的，所以在删除一些重要数据时，请务必三思而后行，比如做好备份工作），相应的做法可以参考资料 [18] 到 [21] 。

具体删除文件的命令有 rm ，如果要删除空目录，可以用 rmdir 命令。例如：

<pre>$ rm regular_file
$ rmdir directory_file
$ rm -r directory_file_not_empty
</pre>

 rm 有两个非常重要的参数，一个是 -f ，这个命令是非常“野蛮的”（关于 rm -rf 的那些钟爱者轻强烈建议您阅读 <unix haters> 的相应章节），它估计给很多 linux user 带来了痛苦，另外一个是 -i ，这个命令是非常“温柔的”，它估计让很多用户感觉烦躁不已过。用哪个还是根据您的“心情”吧，如果做好了充分的备份工作，或者采取了一些有效避免灾难性后果的动作的话，您在做这些工作的时候就可以放心一些啦。

### 范例：复制文件

文件的复制通常是指文件内容的“临时”复制。通过这一节开头的介绍，我们应该了解到，文件的硬链接和软链接在某种意义上说也是“文件的复制”，前者同步复制文件内容，后者在读写的情况下同步“复制”文件内容。例如：

用 cp 命令常规地复制文件（复制目录需要 -r 选项）

<pre>$ cp regular_file regular_file_copy
$ cp -r diretory_file directory_file_copy
</pre>

创建硬链接 (link 和 copy 不同之处是后者是同步更新，前者则不然，复制之后两者不再相关 ) 

<pre>$ ln regular_file regular_file_hard_link
</pre>

创建软链接

<pre>$ ln -s regular_file regluar_file_soft_link
</pre>

### 范例：修改文件名

修改文件名实际上仅仅修改了文件名标识符。我们可以通过 mv 命令来实现修改文件名操作（即重命名）。

<pre>$ mv regular_file regular_file_new_name
</pre>

### 范例：编辑文件

编辑文件实际上是操作文件的内容，对应普通文本文件的编辑，这里主要涉及到文件内容的读、写、追加、删除等。这些工作通常会通过专门的编辑器来做，这类编辑器有命令行下的 vim 、 emacs 和图形界面下的 gedit,kedit 等。如果是一些特定的文件，会有专门的编辑和处理工具，比如图像处理软件 gimp ，文档编辑软件 OpenOffice 等。这些工具一般都会有专门的教程。关于 vim 的用法，建议阅读这篇帖子： VIM 高级命令集锦

下面主要简单介绍 Linux 下通过重定向来实现文件的这些常规的编辑操作。

创建一个文件并写入 abcde 

<pre>$ echo "abcde" > new_regular_file
</pre>

再往上面的文件中追加一行 abcde

<pre>$ echo "abcde" >> new_regular_file
</pre>

按行读一个文件

<pre>$ while read LINE; do echo $LINE; done < test.sh
</pre>

提示：如果要把包含重定向的字符串变量当作命令来执行，请使用 eval 命令，否则无法解释重定向。例如，

<pre>$ redirect="echo \"abcde\" >test_redirect_file"
$ $redirect   #这里会把>当作字符 > 打印出来，而不会当作 重定向 解释
"abcde" >test_redirect_file
$ eval $redirect    #这样才会把 > 解释成 重定向
$ cat test_redirect_file
abcde
</pre>

### 范例：压缩／解压缩文件

压缩和解压缩文件在一定意义上来说是为了方便文件内容的传输，不过也可能有一些特定的用途，比如内核和文件系统的映像文件等（更多相关的知识请参考[资料][22]）。

这里仅介绍几种常见的压缩和解压缩方法：

tar, 这在某种意义上来不是文件的压缩，仅仅是“把一堆东西放在一起，当成一个文件来看”。

<pre>$ tar -cf file.tar file   #压缩
$ tar -xf file.tar    #解压
</pre>

gz

<pre>$ gzip  -9 file
$ gunzip file
</pre>

tar.gz

<pre>$ tar -zcf file.tar.gz file
$ tar -zxf file.tar.gz
</pre>

bz2

<pre>$ bzip2 file
$ bunzip2 file
</pre>

tar.bz2

<pre>$ tar -jcf file.tar.bz2 file
$ tar -jxf file.tar.bz2
</pre>

通过上面的演示，我们应该已经非常清楚 tar 命令， bzip2/bunzip2,gzip/gunzip 命令的角色了吧？如果还不清楚，多操作和比较一些上面的命令，并查看它们的手册： man tar... 

### 范例：文件搜索（文件定位）

文件搜索是指在某个目录层次中找出具有某些属性的文件在文件系统中的位置，这个位置如果扩展到整个网络，那么可以表示为一个 URL 地址，对于本地的地址，可以表示为 file://+ 本地路径。本地路径在 Linux 系统下是以 / 开头，例如，每个用户的家目录可以表示为： file:///home/ 。下面仅仅介绍本地文件搜索的一些办法。

find 命令提供了一种“及时的”搜索办法，它根据用户的请求，在指定的目录层次中遍历所有文件直到找到需要的文件为止。而 updatedb+locate 提供了一种“快速的”的搜索策略， updatedb 更新并产生一个本地文件数据库，而 locate 通过文件名检索这个数据库以便快速找到相应的文件。前者支持通过各种文件属性进行搜索，并且提供了一个接口 (-exec 选项 ) 用于处理搜索后的文件。因此为“单条命令”脚本的爱好者提供了极大的方便，不过对于根据文件名的搜索而言， updatedb+locate 的方式在搜索效率上会有明显提高。下面简单介绍这两种方法：

find 命令基本使用演示

<pre>$ find ./ -name "*.c" -o -name "*.h"  #找出所有的C语言文件，-o是或者
$ find ./ \( -name "*.c" -o -name "*.h" \) -exec mv '{}' ./c_files/ \;     #把找到的文件移到c_files下，这种用法非常有趣
</pre>

上面的用法可以用 xargs 命令替代

<pre>$ find ./ -name "*.c" -o -name "*.h" | xargs -i mv '{}' ./c_files/     #如果要对文件做更复杂的操作，可以考虑把mv改写为你自己的处理命令，例如，我需要修
</pre>

改所有的文件名后缀为大写。

<pre>$ find ./ -name "*.c" -o -name "*.h" | xargs -i ./toupper.sh '{}' ./c_files/
</pre>

toupper.sh 就是我们需要实现的转换小写为大写的一个处理文件，具体实现如下：

<pre>$ cat toupper.sh
#!/bin/bash

# the {} will be expended to the current line and becomen the first argument of this script
FROM=$1
BASENAME=${FROM##*/}

BASE=${BASENAME%.*}
SUFFIX=${BASENAME##*.}

TOSUFFIX="$(echo $SUFFIX | tr '[a-z]' '[A-Z]')"
TO=$2/$BASE.$TOSUFFIX
COM="mv $FROM $TO"
echo $COM
eval $COM
</pre>

updatedb+locate 基本使用演示

<pre>$ updatedb #更新库
$ locate find*.gz #查找包含find字符串的所有gz压缩包
</pre>

实际上，除了上面两种命令外， Linux 下还有命令查找工具： which 和 whereis ，前者用于返回某个命令的全路径，而后者用于返回某个命令、源文件、 man 文件的路径。例如，我们需要查找 find 命令的绝对路径：

<pre>$ which find
/usr/bin/find
$ whereis find
find: /usr/bin/find /usr/X11R6/bin/find /usr/bin/X11/find /usr/X11/bin/find /usr/man/man1/find.1.gz /usr/share/man/man1/find.1.gz /usr/X11/man/man1/find.1.gz
</pre>

需要提到的是，如果想根据文件的内容搜索文件，那么 find 和 updatedb+locate 以及 which,whereis 都无能为例啦，可选的方法是 grep ， sed 等命令，前者在加上 -r 参数以后可以在指定目录下文件中搜索指定的文件内容，后者再使用 -i 参数后，可以对文件内容进行替换。它们的基本   用法在前面的章节中我们已经详细介绍了，所以这里就不叙述。

值得强调的是，这些命令对文件的操作是非常有意义的。它们在某个程度上把文件   系统结构给抽象了，使得对整个文件系统的操作简化为对单个文件的操作，而单个文件如果仅仅考虑文本部分，那么最终却转化成了我们之前的字符串操作，即我们   上一节讨论过的内容。为了更清楚的了解文件的组织结构，文件之间的关系，在下一节我们将深入探讨文件系统。

## 参考资料

  * [从文件 I/O 看 Linux 的虚拟文件系统][4]
  * [Linux 文件系统剖析][5]
  * [《Linux 核心》第九章 文件系统][6]
  * [Linux Device Drivers, 3rd Edition][7]
  * [技巧：Linux I/O 重定向的一些小技巧][8]
  * Intel 平台下 Linux 中 ELF 文件动态链接的加载、解析及实例分析: [part1][9], [part2][10]
  * [Shell 脚本调试技术][11]
  * [ELF 文件格式及程序加载执行过程总汇][12]
  * [Linux 下 C 语言编程——文件的操作][13]
  * ["Linux 下 C 语言编程" 的 文件操作 部分][14]
  * [Filesystem Hierarchy Standard][15]
  * [学会恢复 Linux系统里被删除的 Ext3文件][16]
  * [使用 mc 恢复被删除文件][17]
  * [linux ext3 误删除及恢复原理][18]
  * [Linux 压缩／解压缩方式大全][19]
  * [Everything is a byte][20]

## 后记

  * 考虑到文件和文件系统的重要性，我们将把它分成三个小节来介绍：文件、文件系统、程序与进程。在文件这一部分，我们主要介绍文件的基本属性和常规操作，在 文件系统那部分，将深入探讨Linux 文件系统的各个部分（包括Linux 文件系统的结构、具体某个文件系统的大体结构分析、底层驱动的工作原理），在程序与进程一节将专门讨论可执行文件的相关内容（包括不同的程序类型、加载执 行过程、不同进程之间的交互[命令管道和无名管道、信号通信]、对进程的控制等）。
  * 有必要讨论清楚 目录大小 的含义，另外，最好把一些常规的文件操作全部考虑到，包括文件的读、写、执行、删除、修改、复制、压缩／解压缩等。
  * 下午刚从上海回来，比赛结果很“糟糕”，不过到现在已经不重要了，关键是通过决赛发现了很多不足，发现了设计在系统开发中的关键角色，并且发现了上海是个美丽的城市，上交也是个美丽的大学。回来就开始整理这个因为比赛落下了两周的blog。
  * 12 月 15 日，添加文件搜索部分内容。





 [2]: http://tinylab.org
 [3]: /shell-programming-paradigm-of-string-manipulation/
 [4]: http://www.ibm.com/developerworks/cn/linux/l-cn-vfs/
 [5]: http://www.ibm.com/developerworks/cn/linux/l-linux-filesystem/index.html?ca=drs-cn
 [6]: http://man.chinaunix.net/tech/lyceum/linuxK/fs/filesystem.html
 [7]: http://lwn.net/Kernel/LDD3/
 [8]: http://www.ibm.com/developerworks/cn/linux/l-iotips/index.html
 [9]: http://www.ibm.com/developerworks/cn/linux/l-elf/part1/index.html
 [10]: http://www.ibm.com/developerworks/cn/linux/l-elf/part2/index.html
 [11]: http://www.ibm.com/developerworks/cn/linux/l-cn-Shell-debug/index.html
 [12]: http://www.linuxsir.org/bbs/thread206356.html
 [13]: http://fanqiang.chinaunix.net/a4/b2/20010508/113315.html
 [14]: http://www.mwjx.com/aboutfish/private/book/linux_c.txt
 [15]: http://www.pathname.com/fhs/pub/fhs-2.3.html#INTRODUCTION
 [16]: http://tech.ccidnet.com/art/237/20070720/1150559_1.html
 [17]: http://bbs.tech.ccidnet.com/read.php?tid=48372
 [18]: http://www.linuxdiyf.com/viewarticle.php?id=30866
 [19]: http://www.cnblogs.com/eoiioe/archive/2008/09/20/1294681.html
 [20]: http://www.reteam.org/papers/e56.pdf
