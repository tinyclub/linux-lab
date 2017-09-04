
# Linux Lab

This project aims to make a Qemu-based Linux development Lab to easier the learning and development of the [Linux Kernel](http://www.kernel.org).

A full Chinese document is added: [Using Linux Lab to do embedded linux development](http://tinylab.org/using-linux-lab-to-do-embedded-linux-development/).

For Linux 0.11, please try our [Linux 0.11 Lab](http://github.com/tinyclub/linux-0.11-lab).

[![Docker Qemu Linux Lab](doc/docker.jpg)](http://showdesk.io/2017-03-11-14-16-15-linux-lab-usage-00-01-02/)

## Homepage

See: <http://tinylab.org/linux-lab/>

## Download the lab

Download cloud lab framework, pull images and checkout linux-lab repository:

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab/ && tools/docker/choose linux-lab

Run the target lab:

    $ tools/docker/run linux-lab

Re-login the lab via web browser:

    $ tools/docker/vnc linux-lab

For Ubuntu 12.04, please install the new kernel at first, otherwise, docker will not work:

    $ sudo apt-get install linux-generic-lts-trusty

## Quickstart

Login the VNC page via `tools/docker/vnc` with the password printed in the
console, and then open the 'Linux Lab' desktop shortcut on the desktop to
launch into the Lab, and issue the following command to boot the prebuilt
kernel and rootfs on the default `versatilepb` board:

    $ make boot

## Usage

### Available boards

List builtin boards:

    $ make list
    [ pc ]:
          ARCH     = x86
          CPU     ?= i686
          LINUX   ?= 4.6
          ROOTDEV ?= /dev/ram0
    [ g3beige ]:
          ARCH     = powerpc
          CPU     ?= generic
          LINUX   ?= 4.6
          ROOTDEV ?= /dev/ram0
    [ vexpress-a9 ]:
          ARCH     = arm
          CPU     ?= cortex-a9
          LINUX   ?= 4.6
          ROOTDEV ?= /dev/mmcblk0
    [ malta ]:
          ARCH     = mips
          CPU     ?= mips32r2
          LINUX   ?= 4.6
          ROOTDEV ?= /dev/ram0
    [ versatilepb ]:
          ARCH     = arm
          CPU     ?= arm926t
          LINUX   ?= 4.6
          ROOTDEV ?= /dev/ram0

    [ virt ]:
          ARCH     = arm64
          CPU     ?= cortex-a57
          LINUX   ?= v4.5.5
          ROOTDEV ?= /dev/ram0

Check the board specific configuration:

    $ cat boards/versatilepb/Makefile

### Download sources

Download prebuilt images and the kernel, buildroot source code:

    $ make core-source -j3

Download one by one:

    $ make prebuilt-images
    $ make kernel-source
    $ make root-source

### Checkout target versions

Checkout the target version of kernel and builroot:

    $ make checkout

Checkout them one by one:

    $ make kernel-checkout
    $ make root-checkout

### Patching

Apply available patches in `boards/<BOARD>/patch/linux` and `patch/linux/`:

    $ make kernel-patch

### Default Configuration

Configure kernel and buildroot with defconfig:

    $ make config

Configure one by one:

    $ make kernel-defconfig
    $ make root-defconfig

### Manual Configuration

    $ make kernel-menuconfig
    $ make root-menuconfig

### Building

Build kernel and buildroot together:

    $ make build

Build them one by one:

    $ make kernel
    $ make root

Build internel kernel modules:

    $ make modules
    $ make modules-install
    $ make root-rebuild && make boot

List available modules in `modules/` and `boards/<BOARD>/modules/`:

    $ make modules-list
        1 ldt

Build external kernel modules:

    $ make modules m=ldt
    $ make modules-install m=ldt
    $ make root-rebuild && make boot

### Booting

Boot with serial port (nographic) by default, exit with 'CTRL+a x', 'poweroff' or 'pkill qemu':

    $ make boot

Boot with graphic:

    $ make boot G=1

Boot with curses graphic (friendly for ssh login):

    $ make boot G=2

Boot with prebuilt kernel and rootfs (if no new available, simple use `make boot`):

    $ make boot PBK=1 PBD=1 PBR=1

Boot with new kernel, dtb and rootfs if exists (if new available, simple use `make boot`):

    $ make boot PBK=0 PBD=0 PBR=0

Boot without Uboot (only `versatilepb` and `vexpress-a9` boards tested):

    $ make boot U=0

Boot with different rootfs:

    $ make boot ROOTDEV=/dev/ram
    $ make boot ROOTDEV=/dev/nfs
    $ make boot ROOTDEV=/dev/sda
    $ make boot ROOTDEV=/dev/mmcblk0

### Using Uboot

Choose one of the tested boards: `versatilepb` and `vexpress-a9`.

    $ make BOARD=vexpress-a9

Download Uboot:

    $ make uboot-source

Patching with necessary changes, `BOOTDEV` and `ROOTDEV` available, use `tftp` by default:

    $ make uboot-patch

Use `sdcard` or `flash`:

    $ make uboot-patch BOOTDEV=sdcard
    $ make uboot-patch BOOTDEV=flash

Building:

    $ make uboot

Boot with `BOOTDEV` and `ROOTDEV`, use `tftp` by default:

    $ make boot U=1

Use `sdcard` or `flash`:

    $ make boot U=1 BOOTDEV=sdcard
    $ make boot U=1 BOOTDEV=flash

### Debugging

Compile the kernel with `CONFIG_DEBUG_INFO=y` and debug it directly:

    $ make BOARD=malta debug

Or debug it in two steps:

    $ make BOARD=malta boot DEBUG=1

Open a new terminal:

    $ make env | grep KERNEL_OUTPUT
    /labs/linux-lab/output/mipsel/linux-4.6-malta/

    $ mipsel-linux-gnu-gdb output/mipsel/linux-4.6-malta/vmlinux
    (gdb) target remote :1234
    (gdb) b kernel_entry
    (gdb) b start_kernel
    (gdb) b do_fork
    (gdb) c
    (gdb) c
    (gdb) c
    (gdb) bt

Note: some commands have been already added in `.gdbinit`, you can customize it for yourself.

### Testing

Simply boot and poweroff:

    $ make test

Don't poweroff after testing:

    $ make test TEST_FINISH=echo

Run guest test case:

    $ make test TEST_CASE=/tools/ftrace/trace.sh

Reboot the guest system for several times:

    $ make test TEST_REBOOT=2

Test a feature of a specified linux version on a specified board:

    $ make feature-test FEATURE=kft LINUX=v2.6.36 BOARD=malta TEST=auto

Test a kernel module:

    $ make module-test m=oops_test

Test a kernel module and make some targets before testing:

    $ make module-test m=oops_test TEST=kernel-checkout,kernel-patch

### Save images and configs

Save all of the configs and rootfs/kernel/dtb images:

    $ make save

Save configs to `boards/<BOARD>/`:

    $ make kconfig-save
    $ make rconfig-save

Save images to `prebuilt/`:

    $ make root-save
    $ make kernel-save

### Choose a new board

By default, the default board: 'versatilepb' is used, we can configure, build
and boot for a specific board with 'BOARD', for example:

    $ make BOARD=malta
    $ make root-defconfig
    $ make root
    $ make kernel-checkout
    $ make kernel-patch
    $ make kernel-defconfig
    $ make kernel
    $ make boot U=0

### Files transfering

To transfer files between Qemu Board and Host, three methods are supported by
default:

### Install files to rootfs

Simply put the files with a relative path in `system/`, install and rebuild the rootfs:

    $ cd system/
    $ mkdir system/root/
    $ touch system/root/new_file
    $ make root-install
    $ make root-rebuild
    $ make boot G=1

### Share with NFS

Boot the board with `ROOTDEV=/dev/nfs`,

Boot/Qemu Board:

    $ make boot ROOTDEV=/dev/nfs

Host:

    $ make env | grep ROOTDIR
    ROOTDIR = /linux-lab/prebuilt/root/mipsel/mips32r2/rootfs

### Transfer via tftp

Using tftp server of host from the Qemu board with the `tftp` command.

Host:

    $ ifconfig br0
    inet addr:172.17.0.3  Bcast:172.17.255.255  Mask:255.255.0.0
    $ cd tftpboot/
    $ ls tftpboot
    kft.patch kft.log

Qemu Board:

    $ ls
    kft_data.log
    $ tftp -g -r kft.patch 172.17.0.3
    $ tftp -p -r kft.log -l kft_data.log 172.17.0.3

Note: while put file from Qemu board to host, must create an empty file in host firstly. Buggy?

### Share with 9p virtio (tested on vexpress-a9 and virt board)

Reconfigure the kernel with:

    CONFIG_NET_9P=y
    CONFIG_NET_9P_VIRTIO=y
    CONFIG_9P_FS=y

Docker host:

    $ modprobe 9pnet_virtio
    $ lsmod | grep 9p
    9pnet_virtio           17519  0
    9pnet                  72068  1 9pnet_virtio

Host:

    $ make BOARD=vexpress-a9

    $ make root-install PBR=1
    $ make root-rebuild PBR=1

    $ touch hostshare/test     # Create a file in host

    $ make boot U=0 ROOTDEV=/dev/ram0 PBR=1 SHARE=1

Qemu Board:

    $ ls /hostshare/       # Access the file in guest
    test
    $ touch /hostshare/guest-test   # Create a file in guest

## More

Buildroot has provided many examples about buildroot and kernel configuration:

* buildroot: `configs/qemu_ARCH_BOARD_defconfig`
* kernel: `board/qemu/ARCH-BOARD/linux-VERSION.config`

To add a new ARCH, BOARD and linux VERSION test, please based on it.

## Notes

### Note1

Different qemu version uses different kernel VERSION, so, to find the suitable
kernel version, we can checkout different git tags.

### Note2

If nfs or tftpboot not work, please run `modprobe nfsd` in host side and
restart the net services via `/configs/tools/restart-net-servers.sh` and please
make sure not use `tools/docker/trun`.

### Note3

To use the tools under `tools` without sudo, please make sure add your account
to the docker group and reboot your system to take effect:

    $ sudo usermod -aG docker $USER

### Note4

To optimize docker images download speed, please edit `DOCKER_OPTS` in `/etc/default/docker` via referring to `tools/docker/install`.
