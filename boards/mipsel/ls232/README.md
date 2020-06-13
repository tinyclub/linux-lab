
# mipsel/ls232 teaching board Usage

Both of boot and network are ok with linux kernel: [https://gitee.com/mipsellab/linux-2.6.32.git](https://gitee.com/mipsellab/linux-2.6.32.git)

## Select me

    $ make B=mipsel/ls232

## Boot me with initrd

    $ make boot

## Boot with different rootfs

    $ make list ROOTDEV
    [/dev/ram0] /dev/nfs

    $ make boot ROOTDEV=/dev/ram0    // default, ramfs
    $ make boot ROOTDEV=/dev/nfs     // nfsroot

## Boot with netdev

    $ make list NETDEV
    [synopgmac]

    $ make boot NETDEV=synopgmac     // default

## Boot with graphic

    $ make boot G=1

## Debug with qemu

  Debug interactively:

    $ make debug

  Debug automatically:

    $ make test DEBUG=1
