---
title: Mac OS X 上的 Time Machine 是如何工作的
author: Peng Jingwen
description: 如果要问我究竟为什么喜欢 Mac OS X，那么 Time Machine 一定是一个重要的原因。Time Machine 不仅可以完完整整地将我的电脑备份出来，而且可以记录数据的各个版本，有了这个贴心小棉袄，我几乎不会为丢失任何重要数据而担心，甚至在关键时刻它还可以救我一命。本文要研究一下酷炫的 Time Machine 究竟是如何工作的。
layout: post
permalink: /how-time-machine-works-on-mac-os-x/
tags:
  - Time Machine
categories:
  - OS X
---

[<img class="alignnone size-medium wp-image-588" src="https://prettyxw.com/wp-content/uploads/2015/05/Time-Machine-600x356.png" alt="Time-Machine" />][1]


## 前言

如果要问我究竟为什么喜欢 Mac OS X，那么 Time Machine 一定是一个重要的原因。Time Machine 不仅可以完完整整地将我的电脑备份出来，而且可以记录数据的各个版本，有了这个贴心小棉袄，我几乎不会为丢失任何重要数据而担心，甚至在关键时刻它还可以救我一命。

本文要研究一下酷炫的 Time Machine 究竟是如何工作的。

## 工作原理

总体来说，Time Machine 使用了两种方法来实现感知文件变化和备份文件。

  * 文件系统事件存储 &#8211; 快速查找文件变化
  * 硬链接 &#8211; 实现全盘增量备份

### 文件系统事件存储（File System Event Store）

首先，需要说明一个背景知识，HFS+（HFS Plus）文件系统，也叫 Mac OS Extended。从字面就可以看出 HFS+ 是 HFS 的升级版，除了有支持存储更大的文件、支持使用 Unicode 命名文件等这类的提升，更重要的升级是 HFS+ 有很强大的日志功能。日志功能可以保证计算机上的文件系统的完整性，以防出现意外关机或电源故障等情况，启用日志功能的 HFS+ 文件系统会在 `/.fseventsd` 目录下记录整个文件系统的变化日志，被称为文件系统事件存储，每一处文件系统的变化被称为一个事件。为了避免占用过多的硬盘空间，日志系统并不会对每个文件都产生日志，它只会记录相关的目录变化。通过这种方式，就可以感知文件系统的变化情况，比如 Spotlight 可以快速发现文件的增删改，进而对相关的文件进行重新索引。但是有些时候日志可能会出现不完整，当日志所占用的空间过大，系统就会自动清理掉老的日志，比如安装升级系统或者进行大量的文件读写操作。另外，如果计算机出现了异常关机，这些日志文件也会被认为不可信，系统将会重新建立事件存储。

每次 Time Machine 备份时，首先检查事件存储的标记，如果上次备份的标记在系统中可以匹配，则开始通过事件存储进行相关文件的查找定位，进而快速完成备份。但是如果标记不匹配，就会对整个硬盘的文件进行一一比对，此时会出现漫长的 “Preparing&#8230;”，等待比对结束后再进行相关文件的备份操作。

### 硬链接（Hard Links）

硬链接是什么东西这里就不解释了，应该算是基础概念了，而 Time Machine 正是利用了硬链接做到了全盘的增量备份。当进行首次备份时，它会将硬盘上的所有文件全部复制到备份盘中，这个过程会相当漫长。之后每次备份时，Time Machine 只需要复制那些变化过的文件，而其他文件全部使用创建硬链接的方式来备份。

原理如下图：

![Hard-Links-Example][2]

首先有文件 A 和文件 B，此时备份，A 和 B 都被复制。之后，文件 A 被删除，创建了文件 C，在进行备份时，只需要复制文件 C，然后创建文件 B 的硬链接即可。

这样一来，当备份盘空间不足时，Time Machine 既可以轻而易举的删除老备份，又丝毫不会影响到新备份。然而这样做会有另外一个问题，那就是需要创建非常非常多的硬链接，可能会让备份变的非常缓慢，而且会占用额外的存储空间。实际上，从 Mac OS X 10.5 Leopard 开始，文件系统已经开始支持目录级别的硬链接。因此备份时，如果某个目录内的文件没有发生变化，那么直接对该目录创建硬链接即可，对于那些万年不变的系统目录来说，这个功能简直不能再好用。当然目录级别的硬链接很危险，系统自带的 ln 命令并不可以直接对目录创建硬链接，需要写 C 程序调用 link 函数实现。

下面是一个小例子：

<pre>// directory_link.c

#include &lt;unistd.h&gt;
#include &lt;stdio.h&gt;

int main(int argc, char* argv[]) {
    if (argc != 3) {
        fprintf(stderr,"Use: directory_link &lt;source_dir&gt; &lt;target_dir&gt;\n");
        return 1;
    }
    int ret = link(argv[1],argv[2]);
    if (ret != 0) {
        fprintf(stderr, "Link failed!\n");
    }
    return ret;
}</pre>

<pre>$ clang directory_link.c -o directory_link
$ mkdir test
$ mkdir test_link
$ ./directory_link test test_link/test</pre>

## 备份文件的组织结构

Time Machine 的备份文件会以目录的形式组织，其中包括每一个时间点的所有硬盘数据，通常有两种备份形式，一种是本地备份（Local Backups），另一种是网络备份（Network Backups）。本地备份可以存储在 Mac 的内部硬盘上，也可以存储在外置硬盘，而网络备份通常以稀疏磁盘映像（Sparse Bundle Disk Image）的形式存储在网络磁盘上，通常可以是通过 afp（Apple Filing Protocol）协议远程挂载的磁盘。可以参考[《将 Linux 作为 Time Capsule 使用》][3]搭建自己的备份服务器。

以下图为例说明组织结构：

![Time-Machine-Disk][4]

  * 在备份磁盘的根目录有名为 “Backups.backupdb” 的文件夹，所有的备份文件均放置于此
  * 每台 Mac 在 “Backups.backupdb” 目录下会有单独的文件夹来隔离存放数据
  * 在每台 Mac 的目录下存放着以备份时间点命名的文件夹，存放每个时间点的数据
  * 在每台 Mac 的目录下还有一个名为 “Latest” 的软链接，指向最新的备份时间点目录
  * 在备份时间点目录下可以看到所有被备份的硬盘和数据





 [1]: https://prettyxw.com/wp-content/uploads/2015/05/Time-Machine.png
 [2]: https://prettyxw.com/wp-content/uploads/2015/05/Hard-Links-Example-494x600.jpg
 [3]: https://prettyxw.com/article/2014/03/25/how-to-use-linux-as-time-capsule/
 [4]: https://prettyxw.com/wp-content/uploads/2015/05/Time-Machine-Disk-600x219.png
