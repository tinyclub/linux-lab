
# mips64el/loongson3-virt board Usage

Both of boot and network are ok with latest qemu v6.2.0.

## Select me

    $ make B=mips64el/loongson3-virt

## Boot me with initrd

    $ make boot

## Boot with different rootfs

    $ make list ROOTDEV
    [/dev/ram0] /dev/nfs

    $ make boot ROOTDEV=/dev/ram0    // initrd
    $ make boot ROOTDEV=/dev/nfs     // nfsroot

## Debug with qemu

  Debug interactively:

    $ make debug

  Debug automatically:

    $ make test DEBUG=1
