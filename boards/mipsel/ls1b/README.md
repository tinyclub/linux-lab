
# mipsel/ls1b board Usage

Both of boot and network are ok with mainline linux kernel.

## Select me

    $ make B=mipsel/ls1b

## Boot me with initrd

    $ make boot

## Boot with nfsroot

    $ make boot ROOTDEV=/dev/nfs

## Debug with qemu

    $ make debug         // interactively

    $ make test DEBUG=1  // automatically
