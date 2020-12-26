
# EmbedFire i.MX6UL/ULL-EVK-PRO Board

## Usage

The board tested uses nand storage, for mmc, please use imx6ul-mmc-npi.dtb.

    $ sed -i -e "s/imx6ul-nand-npi.dtb/imx6ul-mmc-npi.dtb/g" boards/arm/ebf-imx6ul/Makefile

And the related dtb should be changed in the following sections.

### Compile

    $ make BOARD=arm/ebf-imx6ul
    $ make kernel
    $ make kernel-save
    $ make modules-install

    $ ls boards/arm/ebf-imx6ul/bsp/kernel/v4.19.35/
    imx6ull-nand-npi.dtb  zImage
    $ ls boards/arm/ebf-imx6ul/bsp/root/2020.02/rootfs/lib/modules/
    4.19.35+
    $ rm boards/arm/ebf-imx6ul/bsp/root/2020.02/rootfs/lib/modules/v4.19.35+/{source,build}

### Configure your board

  Please connect the board to your host via usb cable and ethernet cable, then:

    $ minicom -D /dev/ttyUSB0
    ...
    npi login: debian
    Password: temppwd

    debian@npi:~$ ifconfig
    eth1: flags=-28605<UP,BROADCAST,RUNNING,MULTICAST,DYNAMIC>  mtu 1500
            inet 192.168.0.112  netmask 255.255.255.0  broadcast 192.168.0.255
            inet6 fe80::c40b:38ff:fe08:b2d1  prefixlen 64  scopeid 0x20<link>
            ether c6:0b:38:08:b2:d1  txqueuelen 1000  (Ethernet)
            RX packets 14  bytes 2527 (2.4 KiB)
            RX errors 0  dropped 1  overruns 0  frame 0
            TX packets 22  bytes 2978 (2.9 KiB)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0


### Upload zImage and dtb

  Host or Lab:

    $ scp boards/arm/ebf-imx6ul/bsp/kernel/v4.19.35/zImage debian@192.168.0.112:~/
    $ scp boards/arm/ebf-imx6ul/bsp/kernel/v4.19.35/imx6ull-nand-npi.dtb debian@192.168.0.112:~/
    $ scp -r boards/arm/ebf-imx6ul/bsp/root/2020.02/rootfs/lib/modules/4.19.35+ debian@192.168.0.112:~/

  Board:

    $ sudo mkdir /boot/dtbs/4.19.35+
    $ sudo mv ~/imx6ull-nand-npi.dtb /boot/dtbs/4.19.35+/
    $ sudo mv ~/zImage /boot/vmlinuz-4.19.35+

    $ sudo mv ~/4.19.35+ /lib/modules/
    $ sudo update-initramfs -u -k 4.19.35+

### Boot with new images

  Configure via `/boot/uEnv.txt`:

    $ sudo sed -i -e "s/uname_r=.*/uname_r=4.19.35+/g" /boot/uEnv.txt
    $ sudo sed -i -e "s/dtb=.*/dtb=imx6ull-nand-npi.dtb/g" /boot/uEnv.txt
    $ sudo reboot

  Boot directly via Uboot command line (for nand board), Stop after "ubi0: attached mtd2 (name "rootfs"):

    => setenv bootargs "console=ttymxc0,115200 ubi.mtd=1 root=ubi0:rootfs rw rootfstype=ubifs mtdparts=gpmi-nand:8m(uboot),-(rootfs)coherent_pool=1M net.ifnames=0 vt.global_cursor_default=0 quiet"

    => ubifsload 0x80800000 /boot/vmlinuz-4.19.35+
    => ubifsload 0x88000000 /boot/initrd.img-4.19.35+
    => ubifsload 0x83000000 /boot/dtbs/4.19.35+/imx6ull-nand-npi.dtb
    => ubifsls /boot/
              4722198  Fri Dec 25 20:25:35 2020  initrd.img-4.19.35+
    => bootz 0x80800000 0x88000000:4722198 0x83000000

  Boot directly via Uboot command line (for mmc board):

    TODO

## TODO

* Automate the uploading via scp (need allow login with root without password), required by `make boot`
* Document usage for mmc boards
* Enable ethernet in Uboot, for dhcp, tftpboot and nfs
* Enable otg in Linux System and document uploading via otg
* Enable booting with nfs rootfs, easier uploading

## References

* [EBF IMX6ULL Linux](https://github.com/Embedfire/ebf_linux_kernel)
* [EBF IMX6ULL Uboot](https://gitee.com/Embedfire/ebf_linux_uboot)
* [EBF IMX6ULL Document](http://doc.embedfire.com/products/link/zh/latest/linux/ebf_i.mx6ull.html)
