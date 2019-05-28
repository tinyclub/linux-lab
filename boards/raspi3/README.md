
# Raspi3 Usage

Rapsi3 almost works, but:

* reboot fails with kernel hang
* usb not work (qemu not support)
* network is based on usb, not work, nfs boot not work

## Boot with graphic

  Note: login console is there, but not accept input currently.

    $ make boot V=1 G=1

## Boot with serial

    $ make boot V=1        // with pl011, by default

## Boot debian

   It is able to boot externl kernel, dtb, initrd and sdcard rootfs image from debian, please refer to [Raspi3 debian][4]:

    $ mkdir debian
    $ cd debian
    $ wget -c https://people.debian.org/~stapelberg/raspberrypi3/2018-01-08/2018-01-08-raspberry-pi-3-buster-PREVIEW.img.xz
    $ xz -d 2018-01-08-raspberry-pi-3-buster-PREVIEW.img.xz

    $ fdisk -l 2018*.img
    Disk 2018-01-08-raspberry-pi-3-buster-PREVIEW.img: 1.1 GiB, 1153433600 bytes, 2252800 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0xac8dad98

    Device                                        Boot  Start     End Sectors  Size Id Type
    2018-01-08-raspberry-pi-3-buster-PREVIEW.img1        2048  614399  612352  299M  c W95 FAT32 (LBA)
    2018-01-08-raspberry-pi-3-buster-PREVIEW.img2      614400 2252799 1638400  800M 83 Linux

    $ sudo mkdir /mnt/debian
    $ sudo mount -o offset=$((2048*512)) /mnt/debian/

    $ sudo cp /mnt/debian/vmlinuz-4.14.0-3-arm64 .
    $ sudo cp /mnt/debian/initrd.img-4.14.0-3-arm64 .
    $ sudo cp /mnt/debian/bcm2837-rpi-3-b.dtb .

    $ make boot KIMAGE=$PWD/debian/vmlinuz-4.14.0-3-arm64 INITRD=$PWD/debian/initrd.img-4.14.0-3-arm64 DTB=$PWD/debian/bcm2837-rpi-3-b.dtb \
	ROOTDEV=/dev/mmcblk0p2 ROOTFS=$PWD/debian/2018-01-08-raspberry-pi-3-buster-PREVIEW.img V=1

    rpi3 login: root
    password:                    <------ input raspberry as passwd

    root@rpi3:~# cat /etc/issue
    Debian GNU/Linux buster/sid \n \l

    root@rpi3:~# uname -a
    Linux rpi3 4.14.0-3-arm64 #1 SMP Debian 4.14.12-2 (2018-01-06) aarch64 GNU/Linux

# Boot ubuntu

  Here introduces how to download and boot ubuntu from docker image, the following steps are done in host system, except the one explicitly said in Linux Lab.

  Check official arm64 ubuntu image:

    $ docker search arm64v8 | grep ubuntu
    arm64v8/ubuntu Ubuntu is a Debian-based Linux operating system  25
  Download and extract the rootfs out to `prebuilt/fullroot/tmp`:

    $ cd $(path-to)/linux-lab
    $ tools/rootfs/docker/extract.sh arm64v8/ubuntu aarch64
    LOG: Pulling arm64v8/ubuntu
    Using default tag: latest
    latest: Pulling from arm64v8/ubuntu
    745b76626a20: Pulling fs layer
    6ce7a8922cb8: Download complete
    565a1332f5cd: Download complete
    ...
    LOG: Running arm64v8/ubuntu
    LOG: Creating temporary rootdir: ...linux-lab/prebuilt/fullroot/tmp/arm64v8-ubuntu
    LOG: Extract docker image to ...linux-lab/prebuilt/fullroot/tmp/arm64v8-ubuntu
    [sudo] password for falcon:
    LOG: Removing docker container
    8c15a9d30b402e46f63227b6286d54c6afdd80d9193c2ee28684395830fef042
    LOG: Chroot into new rootfs
    Linux ubuntu 4.4.0-148-generic #174-Ubuntu SMP Tue May 7 12:20:14 UTC 2019 aarch64 aarch64 aarch64 GNU/Linux
    Ubuntu 18.04.2 LTS \n \l


  Or pull it and then extract:

    $ docker pull arm64v8/ubuntu
    $ PULL=0 tools/rootfs/docker/extract.sh arm64v8/ubuntu aarch64

  Use it with docker:

    $ sudo apt-get install qemu-user-static
    $ $ docker run -it -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static arm64v8/ubuntu
    root@bceb61278159:/# uname -a
    Linux bceb61278159 4.4.0-148-generic #174-Ubuntu SMP Tue May 7 12:20:14 UTC 2019 aarch64 aarch64 aarch64 GNU/Linux
    root@bceb61278159:/# cat /etc/issue
    Ubuntu 18.04.2 LTS \n \l

  Use it with chroot:

    $ tools/rootfs/docker/chroot.sh arm64v8/ubuntu
    LOG: Chroot into ...linux-lab/prebuilt/fullroot/tmp/arm64v8-ubuntu
    root@ubuntu:/#

  Boot it in Linux Lab, please launch it at fist:

    $ make boot ROOTFS=$PWD/prebuilt/fullroot/tmp/arm64v8-ubuntu



# Boot buildroot

  Buildroot is able to compile a whole system for raspi3, include kernel image, dtb, initrd and sdcard image, just configure, build and boot:

    $ find buildroot/ -name "*pi3*defconfig"
    buildroot/configs/raspberrypi3_defconfig
    buildroot/configs/raspberrypi3_qt5we_defconfig
    buildroot/configs/raspberrypi3_64_defconfig

    $ make root-defconfig RCFG=raspberrypi3_64_defconfig V=1
    $ make root-menuconfig
    $ make root

    $ make boot KIMAGE=$PWD/output/aarch64/buildroot-2019.02.2-cortex-a53/images/Image DTB=$PWD/output/aarch64/buildroot-2019.02.2-cortex-a53/images/bcm2710-rpi-3-b.dtb INITRD=$PWD/output/aarch64/buildroot-2019.02.2-cortex-a53/images/rootfs.cpio.gz V=1

## References

* [Qemu raspi3 support][1]
* [Raspi3 hardware spec][2]
* [Raspi3 linux kernel][3]
* [Raspi3 debian][6]
* [Raspbian][5]
* [Ubuntu rootfs][10]
* [Ubuntu docker image][11]
* [Debian rootfs][12]
* [Debian docker image][13]
* [Reproducible, snapshot-based Debian rootfs builder][14]

[1]: https://github.com/bztsrc/qemu-raspi3
[2]: https://www.raspberrypi.org/magpi/raspberry-pi-3-specs-benchmarks/
[3]: https://github.com/raspberrypi/linux
[4]: https://translatedcode.wordpress.com/2018/04/25/debian-on-qemus-raspberry-pi-3-model/
[5]: https://www.raspberrypi.org/downloads/
[6]: https://wiki.debian.org/RaspberryPi3
[7]: https://github.com/Debian/raspi3-image-spec
[8]: https://people.debian.org/~stapelberg/
[9]: https://people.debian.org/~gwolf/raspberrypi3/
[10]: https://partner-images.canonical.com/core/
[11]: https://hub.docker.com/r/arm64v8/ubuntu
[12]: https://github.com/debuerreotype/docker-debian-artifacts/tree/dist-arm64v8
[13]: https://hub.docker.com/r/arm64v8/debian
[14]: https://github.com/debuerreotype/debuerreotype
