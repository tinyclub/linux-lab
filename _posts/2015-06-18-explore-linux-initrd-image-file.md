---
title: Linux 下的 initrd 映像文件初探
author: Wu Zhangjin
layout: post
permalink: /explore-linux-initrd-image-file/
tags:
  - initramfs
  - initrd
  - Linux
categories:
  - File Systems
  - Linux
---

> by falcon of [TinyLab.org][2]
> 2008/04/19


## 简介

如果自己制作过嵌入式 Linux 文件系统，那么应该比较了解 initrd 映像文件是个什么东西了？initrd 即 initial RAM disk，在内核解压之后，在真正的 root filesystem 被启动之前，它被加载到内存中，做一些系统初始化的操作，比如加载内核模块，挂载新的 Root 文件系统等。

initrd 本身是一个文件，内核启动时可以把它展开成一个文件系统。

在 2.6 版本的内核以前，initrd 基于一种特殊的 Loop设备，在展开成一个文件系统前需要通过一种 Loop 设备挂载起来，因为涉及到挂载操作，所以会涉及到一些操作权限。不过在 2.6 版本内核之后出现了 initramfs，它和 initrd 实现同样的功能，但是它基于一种 cpio 档，无须挂载就可以展开成一个文件系统，因此省去了各种相关的权限，在自动化方面更方便了。

initrd 的一个特别有趣的应用是Live CD，比如 Knoppix，它通过 initrd 启动一个初始化的文件系统，然后再通过一个 Cloop 设备挂载一个特别的压缩文件，展开为一个新的 Root 文件系统，这样一个 700M 左右的光盘就能够装下几个 G 的东西，包含大部分的软件和相应的内核模块，进而支持各种各样的功能。

## initrd/initramfs 制作

下面简单介绍一下这两种初始化文件系统(initrd 和 initramfs)的制作过程。

先准备一个测试的目录。

<pre>$ cd /tmp
$ mkdir initrd
$ mkdir initrd/loop initrd/cpio
</pre>

### initrd (via a loop device)

首先通过 dd 命令产生一个指定大小的文件。先来计算一下大小，比如要产生一个 1M 大小的文件，那么可以设置该文件的数据块大小为 1024kbyte，然后弄上 1024 块。

<pre>$ dd if=/dev/zero of=ramdisk bs=1024 count=1024
$ ls -lh ramdisk
-rw-r--r-- 1 falcon falcon 1.0M 2008-04-19 14:59 ramdisk
$ file ramdisk
ramdisk: data
</pre>

得到这样一个文件以后就可以把这个文件系统格式化为 ext3 或者是 ext2 的文件系统。

<pre>$ mkfs.ext2 ramdisk
$ file ramdisk
ramdisk: Linux rev 1.0 ext2 filesystem data
</pre>

如果想往这个文件系统里头添加内容（比如用 busybox 自动的创建一些内容，或者参照 Linux 的根文件系统，从头开始手动制作一个）那么就需要先通过 Loop 设备挂载一下。

不过挂载时需要 Root 用户才行，所以如果你没有 Root 用户的权限，做这个工作就不方便了，从这里就可以看出之后要介绍的 initramfs 的好处了。

<pre>$ mount ramdisk /mnt/ -o loop
mount: only root can do that
$ sudo mount ramdisk /mnt/ -o loop
$ ls /mnt/
lost+found
$ mount | grep ramdisk
/tmp/initrd/loop/ramdisk on /mnt type ext2 (rw,loop=/dev/loop0)
</pre>

挂载以后只有一个 `lost+found` 目录，如果要做成一个完整的 initrd，还得做一些工作，创建相应的目录和文件，详细内容可参考该书：[Optimizing Embedded Systems using Busybox][3]。

制作完文件系统以后就可以进行“打包”操作，制作成一个可以使用的 initrd 文件。

<pre>// 确保各项操作已经写入磁盘
$ sync
// 卸载已经挂载的ramdisk
$ sudo umount /mnt
// “打包”成initrd文件，如果是解压，那么使用gunzip命令，后面直接跟上要解压的文件即可
$ gzip -9 ramdisk
$ file ramdisk.gz
ramdisk.gz: gzip compressed data, was "ramdisk", from Unix, last modified: Sat Apr 19 17:05:24 2008, max compression
</pre>

如果想要这个 initrd 映像文件能够正常工作，那么得确保文件系统里头的基本工具都有了，并且确保内核已经编译了相关的支持，比如 Loop 设备的内核支持：

<pre>Device Drivers > Block Devices > Loopback Device Support.
</pre>

以及其他的选项，比如 ext2 文件系统支持等，就可以考虑测试 ramdisk.gz 能不能用了，在 grub 下面可以考虑使用 `initrd /path/to/ramdisk.gz` 来测试它，而在 lilo 下则通过 initrd 变量来指定 `initrd = /path/to/ramdisk.gz`。

### initramfs (via a cpio archive)

这种方式仅仅需要把一个符合 Linux 标准的 Root 文件系统所在目录中的文件加到一个 cpio 档里头，然后“打包”即可。

首先，参考后续资料创建一个文件系统。

<pre>$ cd /tmp/initrd/cpio
// 在这个目录下创建一个符合 Linux标准的 Root 文件系统
$ .... do what you should to do ...
</pre>

之后是把这个目录下的内容加到一个 cpio 档里头。

<pre>$ find . | cpio -c -o > ../ramdisk
$ file ../ramdisk
../ramdisk: ASCII cpio archive (pre-SVR4 or odc)
</pre>

&#8220;打包&#8221;（压缩）一下。

<pre>$ sync
$ cd ../
$ gzip -9 ramdisk
$ file ramdisk.gz
ramdisk.gz: gzip compressed data, was "ramdisk", from Unix, last modified: Sat Apr 19 17:37:25 2008, max compression
</pre>

到这里，这个 ramdisk.gz 在 2.6 的内核之后也应该可以类似上面的一样使用了，不过别忘记了加上相应的内核选项，比如(initramfs)初始化文件系统支持。

下面来看看如何对 ubuntu 8.04 中的 initrd 文件“解包”吧。

看当前内核使用的 initrd：

<pre>$ ls /boot/initrd.img-`uname -r`
/boot/initrd.img-2.6.24-12-generic
$ file /boot/initrd.img-2.6.24-12-generic
/boot/initrd.img-2.6.24-12-generic: gzip compressed data, from Unix, last modified: Thu Apr  3 18:35:25 2008
</pre>

“解压”该文件：

<pre>$ mkdir /tmp/initrd/current
$ cp /boot/initrd.img-2.6.24-12-generic /tmp/initrd/current/
$ cd /tmp/initrd/current/
$ mv initrd.img-2.6.24-12-generic initrd.img-2.6.24-12-generic.gz
$ gunzip initrd.img-2.6.24-12-generic.gz
$ file initrd.img-2.6.24-12-generic
initrd.img-2.6.24-12-generic: ASCII cpio archive (SVR4 with no CRC)
</pre>

现在展开 cpio 档，并查看里头的内容。

<pre>$ cpio -i &lt; ./initrd.img-2.6.24-12-generic
$ ls
bin  conf  etc  init  initrd.img-2.6.24-12-generic  lib  modules  sbin  scripts  usr  var
</pre>

这样就可以看看 Linux 中的 initrd 文件里头的庐山真面目了。如果有兴趣，可以考虑往里头加点自己的东西，然后通过上面介绍的方法，把它重新“打包”成 initrd 文件，并让 Linux 系统把你"hack"的 initrd 文件加载起来。

## 参考资料

  * man boot-scripts (或 man 7 boot)
  * [initrd][4]
  * Linux initial RAM disk (initrd) overview
  * [Loop device][5]
  * [Cloop][6]
  * [Knoppix][7]
  * [busybox][8]





 [2]: http://tinylab.org
 [3]: /optimizing-embedded-systems-using-busybox/
 [4]: http://en.wikipedia.org/wiki/Initrd
 [5]: http://en.wikipedia.org/wiki/Loop_device
 [6]: http://en.wikipedia.org/wiki/Cloop
 [7]: http://www.knoppix.org/
 [8]: http://www.busybox.net/
