
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

## Import zipped kernel source

  Sometimes, if the git repository is broken, this method may work.

  Download the zip package of the release-1903 branch from <https://gitee.com/tinylab/loongson-linux-v3.10/tree/release-1903/>.

    $ cd /path/to/linux-lab/src/
    $ ls tinylab-loongson-linux-v3.10-release-1903.zip

  Decompress the zip package and rename it to `loongnix-linux-3.10`:

    $ unzip tinylab-loongson-linux-v3.10-release-1903.zip
    $ mv loongson-linux-3.10 loongnix-linux-3.10

  Enter into the kernel source directory, init it as a git repository:

    $ cd loonginx-linux-3.10
    $ git init
    $ git add .
    $ git commit -m "Init loongson linux v3.10"

  Update the commit setting:

    $ sed -i -e "s/04b98684/master/g" boards/mips64el/ls3a7a/Makefile

  Ignore the kernel download step:

    $ make source kernel -t

  That's all.
