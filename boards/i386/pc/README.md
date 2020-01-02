
# i386/pc Usage

The Linux kernel versions used by several famous Linux books are added:

|  Books        | Versions         | Authors
|---------------|------------------|-----------------
|  LDD3         | v2.6.10          | Jonathan Corbet, Alessandro Rubini, and Greg Kroah-Hartman
|  LKD3         | v2.6.34.9        | Robert Love
|  ULK3         | v2.6.11.12       | Marco Cesati, Daniel P. Bovet
|  PLKA         | v2.6.24.7        | Wolfgang Mauerer

Books' fullname and their resources:

* LDD3: [Linux Device Drivers, Third Edition](https://lwn.net/Kernel/LDD3/)
    * [Original Examples](http://examples.oreilly.com/9780596005900/)
    * [Latest Examples](https://github.com/martinezjavier/ldd3)
* LKD3: Linux Kernel Development (3rd Edition)
* ULK3: Understanding the Linux Kernel, 3rd Edition
* PLKA: Professional Linux Kernel Architecture

## Linux v2.6.34.9

    $ make board-config LINUX=v2.6.34.9
    $ make boot

## Linux v2.6.24.7

    $ make board-config LINUX=v2.6.24.7
    $ make boot

## Linux v2.6.21.6

This is based on buildroot/target/device/x86/i686/linux-2.6.21.5.config, with nfs and network feature support.

At first, switch kernel to v2.6.21.5.

    $ make board-config LINUX=v2.6.21.5

Second, Create a missing /dev/null device:

    $ make boot ROOTDEV=/dev/nfs XKCLI=init=/bin/sh
    /bin/sh: can't access tty; job control turned off
    / # mknod dev/null c 1 3
    / # sync
    / # reboot -f

Third, boot it normally:

    $ make boot ROOTDEV=/dev/nfs
    Welcome to Linux Lab
    linux-lab login: root
    #
    # uname -a
    Linux linux-lab 2.6.21.5-dirty #4 Sat Dec 28 17:36:27 UTC 2019 i686 GNU/Linux

## Linux v2.6.12.6

For this old kernel version, please make sure apply the prepared patchset:

    $ make board-config LINUX=v2.6.12.6
    $ make kernel-checkout
    $ make kernel-patch
    $ make kernel-defconfig
    $ make kernel
    $ make boot
    $ make boot ROOTDEV=/dev/nfs
    $ make boot ROOTDEV=/dev/hda

Note: the second patch for mm/page_alloc.c is not the last solution, it is just a workaround for booting.

## Linux v2.6.11.12

There is no valid 2.6.11 tags currently, the commit id for v2.6.11.12 is added in Makefile manually:

    $ make board-config LINUX=v2.6.11.12
    $ make kernel-checkout
    $ make kernel-patch
    $ make kernel-defconfig
    $ make kernel
    $ make boot
    $ make boot ROOTDEV=/dev/nfs
    $ make boot ROOTDEV=/dev/hda

## Linux v2.6.10

There is no v2.6.10 in linux-stable tree, need to download it from the other repository. this is implemented by such lines:

    KERNEL_GIT[LINUX_v2.6.10] = https://gitee.com/tinylab/tglx-linux-history
    KERNEL_SRC[LINUX_v2.6.10] = tglx-linux-history

FIXME: with v2.6.10, only <=80M memory works, otherwise, panic.
