
# i386/pc Usage

## Linux v2.6.21.5

This is based on buildroot/target/device/x86/i686/linux-2.6.21.5.config, with nfs and network feature support.

At first, set ARCH to i386 for all kernel versions <= v2.6.23:

    $ make board-config ARCH=i386 LINUX=v2.6.21.5

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
