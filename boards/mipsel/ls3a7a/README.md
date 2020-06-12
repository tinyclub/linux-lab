
# mipsel/ls3a7a board Usage

Both of boot and network are ok with loongnix linux kernel: [git://cgit.loongnix.org/kernel/linux-3.10.git](http://cgit.loongnix.org/cgit/linux-3.10/)

## Select me

    $ make B=mipsel/ls3a7a

## Boot me with initrd

    $ make boot

## Boot with different rootfs

    $ make list ROOTDEV
    /dev/sda [/dev/ram0] /dev/nfs

    $ make boot ROOTDEV=/dev/ram0    // initrd
    $ make boot ROOTDEV=/dev/nfs     // nfsroot
    $ make boot ROOTDEV=/dev/sda     // harddisk

## Boot with different netdev

    $ make list NETDEV
    [synopgmac] rtl8139

    $ make boot NETDEV=synopgmac     // default
    $ make boot NETDEV=rtl8139

## Boot with graphic

    $ make boot G=1

## Debug with qemu

  Debug interactively:

    $ make debug

  Debug automatically:

    $ make test DEBUG=1
