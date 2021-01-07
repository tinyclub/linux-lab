
# EmbedFire i.MX6UL/ULL-EVK-PRO Board

This board uses NXP i.MX6ULL Cortex-A7 CPU, it is about 800M, you can buy it
from: [TinyLab.org's Taobao Shop](https://shop155917374.taobao.com/).

## Introduction

The board tested uses nand storage, for mmc, please use imx6ull-mmc-npi.dtb.

    $ sed -i -e "s/nand/mmc/g" boards/arm/ebf-imx6ull/Makefile

The kernel version tested is 4.19.35.

And the related dtb should be changed in the following sections.

## Switch to this board

    $ make BOARD=arm/ebf-imx6ull

## Compile and install

    $ make kernel-build
    $ make modules-install

## Configure your board

Please connect the board to your host via usb cable and ethernet cable, then login:

    $ make login
    ...
    npi login: debian
    Password: temppwd    <== default password, will be changed to linux-lab

    debian@npi:~$ ifconfig
    eth1: flags=-28605<UP,BROADCAST,RUNNING,MULTICAST,DYNAMIC>  mtu 1500
            inet 192.168.0.112  netmask 255.255.255.0  broadcast 192.168.0.255
            inet6 fe80::c40b:38ff:fe08:b2d1  prefixlen 64  scopeid 0x20<link>
            ether c6:0b:38:08:b2:d1  txqueuelen 1000  (Ethernet)
            RX packets 14  bytes 2527 (2.4 KiB)
            RX errors 0  dropped 1  overruns 0  frame 0
            TX packets 22  bytes 2978 (2.9 KiB)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0


Update login prompt in board:

    debian@npi:~$ sudo sed -i -e "s/temppwd/linux-lab/g" /etc/{issue,issue.net}

As we can see, the board ip is `192.168.0.112`, now, let's allow ssh login as `root` to easier images uploading:

    debian@npi:~$ sudo -s
    root@npi:/home/debian# passwd root
    New password: linux-lab
    Retype new passwd: linux-lab

    root@npi:/home/debian# sudo sed -i -e "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
    root@npi:/home/debian# sudo service sshd restart

Change password for default 'debian' user too:

    root@npi:/home/debian# passwd debian
    New password: linux-lab
    Retype new passwd: linux-lab

## Upload zImage, dtb and modules

Simply upload with following commands:

    $ make kernel-upload
    $ make dtb-upload
    $ make modules-upload

Or upload them with detailed commands:

    $ export board_ip=192.168.0.112
    $ export kernel_version=4.19.35+
    $ export dtb=imx6ull-nand-npi.dtb

    $ ls build/arm/linux-v4.19.35-ebf-imx6ull/arch/arm/boot/
    compressed  dts  Image  zImage
    $ ls build/arm/linux-v4.19.35-ebf-imx6ull/arch/arm/boot/dts/
    imx6ull-nand-npi.dtb
    $ ls boards/arm/ebf-imx6ull/bsp/root/2020.02/rootfs/lib/modules/
    4.19.35+

    $ scp build/arm/linux-v4.19.35-ebf-imx6ull/arch/arm/boot/zImage root@$board_ip:/boot/vmlinuz-$kernel_version
    $ ssh root@$board_ip "mkdir -p /boot/dtbs/$kernel_version/"
    $ scp build/arm/linux-v4.19.35-ebf-imx6ull/arch/arm/boot/dts/$dtb root@$board_ip:/boot/dtbs/$kernel_version/

    $ rm boards/arm/ebf-imx6ull/bsp/root/2020.02/rootfs/lib/modules/4.19.35+/{source,build}
    $ scp -r root/2020.02/rootfs/lib/modules/$kernel_version root@$board_ip:/lib/modules/

    $ ssh root@$board_ip "update-initramfs -u -k $kernel_version"

## Reboot with new images

Simply run these commands in Lab side:

    $ make boot

    Or

    $ make boot-config
    $ make reboot
    $ make login

Or run these commands in boards:

    debian@npi$ export dtb=imx6ull-nand-npi.dtb
    debian@npi$ export kernel_version=4.19.35+

    debian@npi$ sudo sed -i -e "s/uname_r=.*/uname_r=$kernel_version/g" /boot/uEnv.txt
    debian@npi$ sudo sed -i -e "s/dtb=.*/dtb=$dtb/g" /boot/uEnv.txt
    debian@npi$ sudo reboot

## Compile a kernel module and upload it

    $ make modules m=hello
    $ make modules-install m=hello
    $ make modules-upload

## Use kernel module in board

Lab:

    $ make login

Board:

    debian@npi$ sudo modprobe hello
    debian@npi$ lsmod | grep hello
    hello                  16384  0

    debian@npi$ dmesg | grep hello
    [ 7337.555712] hello: loading out-of-tree module taints kernel.
    [ 7337.569959] hello module init

## Load and boot new images with Uboot

If the board can not boot with our images, please fix up it with Uboot.

For the nand board, press the power button and stop it after "ubi0: attached mtd2 (name "rootfs"):

    $ make login
    ...
    ubi0: attached mtd2 ...
    =>

Then, load normal images and boot manually like this:

    => setenv bootargs "console=ttymxc0,115200 ubi.mtd=1 root=ubi0:rootfs rw rootfstype=ubifs mtdparts=gpmi-nand:8m(uboot),-(rootfs)coherent_pool=1M net.ifnames=0 vt.global_cursor_default=0 quiet"

    => ubifsload 0x80800000 /boot/vmlinuz-4.19.35+
    => ubifsload 0x88000000 /boot/initrd.img-4.19.35+
    => ubifsload 0x83000000 /boot/dtbs/4.19.35+/imx6ull-nand-npi.dtb
    => ubifsls /boot/
              4722198  Fri Dec 25 20:25:35 2020  initrd.img-4.19.35+
    => bootz 0x80800000 0x88000000:4722198 0x83000000

mmc board use different type of file system, the bootargs and load commands are different, you can refer to the boot logs.

## TODO

* Document usage for mmc boards
* Enable ethernet in Uboot, for dhcp, tftpboot and nfs
* Enable otg in Linux System and document uploading via otg
* Enable booting with nfs rootfs, easier uploading

## References

* [EBF IMX6ULL Linux](https://github.com/Embedfire/ebf_linux_kernel)
* [EBF IMX6ULL Uboot](https://gitee.com/Embedfire/ebf_linux_uboot)
* [EBF IMX6ULL Document](http://doc.embedfire.com/products/link/zh/latest/linux/ebf_i.mx6ull.html)
