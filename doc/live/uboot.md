
# ** Learning Uboot in Linux Lab **

- Author: Wu Zhangjin / Falcon
- Time  : 2017/09/09 2:00 ~ 3:00
- Video : <http://t.cn/RpLlvTD>
- Doc   :
    + <http://tinylab.org/tech-live-learning-uboot-in-linux-lab>
    + <https://github.com/tinyclub/linux-lab>
    + <http://tinylab.org/linux-lab>
    + <http://tinylab.cloud:6080>
    + <http://showdesk.io>
    + README.md

## Introduction

1. Linux Lab
     - Docker, one image everywhere
     - Qemu emulated boards: ARM, MIPS, PowerPc, X86
     - Uboot, Linux, Buildroot, C, Assembly, Shell
     - Online available: noVNC(webVNC) and Gateone(webssh)

2. U-boot
     - <http://tinylab.org/firmware-and-bootloaders>
         - Lilo, Grub, Kexecboot
     - LK: <https://github.com/littlekernel/lk>

## Quick Start

1. Choose a board: vexpress-a9
    - `make BOARD=vexpress-a9`
    - `boards/vexpress-a9/Makefile`
2. Boot with Uboot
    - `make boot`
    - `-kernel /path/to/u-boot`
    - `prebuilt/`: prebuilt uboot, kernel/dtb and rootfs
3. Boot without Uboot
    - `make boot U=0`
    - `-kernel /path/to/linux/*Image`
    - How Qemu pass arguments to Linux?
        - `-append 'root=/dev/ram0 ...'`

## Hacking Uboot: part1

1. Download
    - `make uboot-source`
2. Patch
    - `make uboot-patch`
3. Configure
    - `make uboot-defconfig`
    - `make uboot-menuconfig`
4. Compile
    - make uboot
5. Boot to CLI
    - Hit any key to stop autoboot and enter into CLI
6. Load and Run Linux
    - `bootcmd`
    - `run bootcmd`

## Hacking Uboot: part2

1. Using Uboot CLI
    - env: `print`
    - cmd: `help`

2. Pass arguments to Kernel (from Uboot)
    - `bootargs`
    - `setenv bootargs ...`

3. Loading Linux/dtb/rootfs
    - tftp: `/etc/default/tftpd-hpa`, `./tftpboot/`
    - flash: `./tftpboot/pflash.img`
    - sdcard: `./tftpboot/sd.img`

4. Pass arguments to Uboot (from Qemu)
    - `env import addr size`
    - flash: The last 1M partition

5. Booting as we want
    - `BOOTDEV`: tftp, flash, sd
    - `ROOTDEV`: `/dev/ram0`, `/dev/mmcblk0`, `/dev/nfs`
    - `make boot BOOTDEV=tftp ROOTDEV=/dev/nfs`
