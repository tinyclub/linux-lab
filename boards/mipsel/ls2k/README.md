
# mipsel/ls2k board Usage

Both of boot and network are ok with loongnix linux kernel: [git://cgit.loongnix.org/kernel/linux-3.10.git](http://cgit.loongnix.org/cgit/linux-3.10/)

## Select me

    $ make B=mipsel/ls2k

## Boot me with initrd

    $ make boot

## Boot with different rootfs

    $ make boot ROOTDEV=?
    make boot ROOTDEV=?
    Makefile:523: *** Kernel Supported ROOTDEV list: /dev/sda /dev/ram0 /dev/nfs.  Stop.

    $ make boot ROOTDEV=/dev/ram0    // default, ramfs
    $ make boot ROOTDEV=/dev/sda     // harddisk
    $ make boot ROOTDEV=/dev/nfs     // nfsroot


## Boot with different netdev

    $ make boot NETDEV=?
    Makefile:2398: *** Kernel Supported NETDEV list: synopgmac rtl8139 e1000.  Stop.

    $ make boot NETDEV=synopgmac     // default
    $ make boot NETDEV=rtl8139
    $ make boot NETDEV=e1000

## Boot with graphic

    $ make boot G=1

## Debug with qemu

  Debug interactively:

    $ make debug

  Debug automatically:

    $ make test DEBUG=1
