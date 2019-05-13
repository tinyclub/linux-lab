
# Linux Lab

This project aims to create a Qemu-based Linux development Lab to easier the learning, development and testing of [Linux Kernel](http://www.kernel.org).

For Linux 0.11, please try our [Linux 0.11 Lab](http://github.com/tinyclub/linux-0.11-lab).

[![Docker Qemu Linux Lab](doc/linux-lab.jpg)](http://showdesk.io/2017-03-11-14-16-15-linux-lab-usage-00-01-02/)

## Why

About 9 years ago, a tinylinux proposal: [Work on Tiny Linux Kernel](https://elinux.org/Work_on_Tiny_Linux_Kernel) accepted by embedded
linux foundation, therefore I have worked on this project for serveral months.

During the project cycle, several scripts written to verify if the adding tiny features (e.g. [gc-sections](https://lwn.net/images/conf/rtlws-2011/proc/Yong.pdf))
breaks the other kernel features on the main cpu architectures.

These scripts uses qemu-system-ARCH as the cpu/board emulator, basic boot+function tests have been done for ftrace+perf, accordingly, defconfigs,
rootfs, test scripts have been prepared, at that time, all of them were simply put in a directory, without a design or holistic consideration.

They have slept in my harddisk for several years without any attention, untill one day, docker and novnc came to my world, at first, [Linux 0.11 Lab](http://github.com/tinyclub/linux-0.11-lab) was born, after that, Linux Lab was designed to unify all of the above scripts, defconfigs, rootfs and test scripts.

Now, Linux Lab becomes an intergrated Linux learning, development and testing environment, it supports:

* Boards

  Qemu based, 4 main Architectures, 6 popular Boards, more available, one `make boot` target for all boards, qemu options are hidden.

* Components

  Uboot, Linux / Modules, Buildroot, Qemu, all of them are configurable, patchable, compilable, buildable, Linux v5.1 supported.

* Prebuilt

  all of above components have been prebuilt for instant using, see [prebuilt](https://github.com/tinyclub/prebuilt), qemu v2.12.0 prebuilt for arm/arm64.

* Rootfs

  Buildtin ramfs, harddisk, mmc, nfs rootfs booting support, configurable via ROOTDEV/ROOTDIR, Ubuntu 18.04 for ARM available as docker image: tinylab/armv32-ubuntu.

* Docker

  Environment (cross toolchains) available in one command in serveral minutes, 4 main architectures have builtin support, external ones configurable via `make toolchain`.

* Browser

  usable via modern web browsers, once installed in a internet server, available everywhere via novnc or web ssh.

* Network

  Builtin bridge networking support, every board support network.

* Boot

  Support serial port, curses (ssh friendly) and graphic booting.

* Testing

  Support automatic testing via `make test` target.

* Debugging

  debuggable via `make debug` target.

Continue reading for more features and usage.

## Homepage

See: <http://tinylab.org/linux-lab/>

## Demonstration

Basic:

* [Basic Usage](http://showdesk.io/7977891c1d24e38dffbea1b8550ffbb8)
* [Learning Uboot](http://showterm.io/11f5ae44b211b56a5d267)
* [Learning Assembly](http://showterm.io/0f0c2a6e754702a429269)
* [Boot ARM Ubuntu 18.04 on Vexpress-a9 board](http://showterm.io/c351abb6b1967859b7061)
* [Boot Linux v5.1 on ARM64/Virt board](http://showterm.io/9275515b44d208d9559aa)

More:

* [Learning RLK4.0 Book (Chinese)](https://v.qq.com/x/page/y0543o6zlh5.html)
* [Developing Embedded Linux (Chinese)](http://tinylab.org/using-linux-lab-to-do-embedded-linux-development/).

## Install docker

Docker is required by Linux Lab, please install it at first:

* Linux and Mac OSX: [Docker CE](https://store.docker.com/search?type=edition&offering=community)
* Windows: [Docker Toolbox](https://www.docker.com/docker-toolbox)

Notes:

In order to run docker without password, please make sure your user is added in the docker group:

    $ sudo usermod -aG docker $USER

In order to speedup docker images downloading, please configure a local docker mirror in `/etc/default/docker`, for example:

    $ grep registry-mirror /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --registry-mirror=https://docker.mirrors.ustc.edu.cn"
    $ service docker restart

In order to avoid network ip address conflict, please try following changes and restart docker:

    $ grep bip /etc/default/docker
    DOCKER_OPTS="$DOCKER_OPTS --bip=10.66.0.10/16"
    $ service docker restart

If the above changes not work, try something as following:

    $ grep dockerd /lib/systemd/system/docker.service
    ExecStart=/usr/bin/dockerd -H fd:// --bip=10.66.0.10/16 --registry-mirror=https://docker.mirrors.ustc.edu.cn
    $ service docker restart

For Ubuntu 12.04, please install the new kernel at first, otherwise, docker will not work:

    $ sudo apt-get install linux-generic-lts-trusty

## Choose a working directory

If installed via Docker Toolbox, please enter into the `/mnt/sda1` directory of the `default` system on Virtualbox, otherwise, after poweroff, the data will be lost for the default `/root` directory is only mounted in DRAM.

    $ cd /mnt/sda1

For Linux or Mac OSX, please simply choose one directory in `~/Downloads` or `~/Documents`.

    $ cd ~/Documents

## Download the lab

Use Ubuntu system as an example:

Download cloud lab framework, pull images and checkout linux-lab repository:

    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab/ && tools/docker/choose linux-lab

## Run and login the lab

Launch the lab and login with the user and password printed in the console:

    $ tools/docker/run linux-lab

Re-login the lab via web browser:

    $ tools/docker/vnc linux-lab

## Quickstart: Boot a board

Issue the following command to boot the prebuilt kernel and rootfs on the
default `versatilepb` board:

    $ make boot

## Usage

### Available boards

List builtin boards:

    $ make list
    [ g3beige ]:
          ARCH     = powerpc
          CPU     ?= generic
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/ram0
    [ malta ]:
          ARCH     = mips
          CPU     ?= mips32r2
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/ram0
    [ pc ]:
          ARCH     = x86
          CPU     ?= x86_64
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/ram0
    [ versatilepb ]:
          ARCH     = arm
          CPU     ?= arm926t
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/ram0
    [ vexpress-a9 ]:
          ARCH     = arm
          CPU     ?= cortex-a9
          LINUX   ?= v5.1
          ROOTDEV ?= /dev/ram0
    [ virt ]:
          ARCH     = arm64
          CPU     ?= cortex-a57
          LINUX   ?= v5.1
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

Build all internel kernel modules:

    $ make modules
    $ make modules-install
    $ make root-rebuild && make boot

Build one kernel module:

    $ make module M=$PWD/linux-stable/fs/minix/

List available modules in `modules/` and `boards/<BOARD>/modules/`:

    $ make modules-list
        1 ldt

Build external kernel modules:

    $ make modules m=ldt
    $ make modules-install m=ldt
    $ make root-rebuild && make boot

Switch compiler version if exists, for example:

    $ tools/gcc/switch.sh arm 4.3

### Booting

Boot with serial port (nographic) by default, exit with 'CTRL+a x', 'poweroff' or 'pkill qemu':

    $ make boot

Boot with graphic:

    $ make boot G=1

Boot with curses graphic (friendly to ssh login, not work for all boards, exit with 'ESC+2 quit'):

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

Boot with extra kernel command line:

    $ make boot ROOTDEV=/dev/nfs XKCLI="init=/bin/bash"

### Using Uboot

Choose one of the tested boards: `versatilepb` and `vexpress-a9`.

    $ make BOARD=vexpress-a9

Download Uboot:

    $ make uboot-source

Checkout the specified version:

    $ make uboot-checkout

Patching with necessary changes, `BOOTDEV` and `ROOTDEV` available, use `tftp` by default:

    $ make uboot-patch

Use `tftp`, `sdcard` or `flash` explicitly:

    $ make uboot-patch BOOTDEV=tftp
    $ make uboot-patch BOOTDEV=sdcard
    $ make uboot-patch BOOTDEV=flash

Configure:

    $ make uboot-defconfig
    $ make uboot-menuconfig

Building:

    $ make uboot

Boot with `BOOTDEV` and `ROOTDEV`, use `tftp` by default:

    $ make boot U=1

Use `tftp`, `sdcard` or `flash` explicitly:

    $ make boot U=1 BOOTDEV=tftp
    $ make boot U=1 BOOTDEV=sdcard
    $ make boot U=1 BOOTDEV=flash

We can also change `ROOTDEV` during boot, for example:

    $ make boot U=1 BOOTDEV=flash ROOTDEV=/dev/nfs

Save uboot images and configs:

    $ make uboot-save
    $ make uconfig-save

### Using external qemu

Builtin qemu may not work with the newest linux kernel, so, we need compile and
add external prebuilt qemu, this has been tested on vexpress-a9 and virt board.

At first, build qemu-system-ARCH:

    $ make B=vexpress-a9

    $ make emulator-download
    $ make emulator-patch
    $ make emulator-defconfig
    $ make emulator
    $ make emulator-save

qemu-ARCH-static and qemu-system-ARCH can not be compiled together. to build
qemu-ARCH-static, please enable `QEMU_US=1` in board specific Makefile and
rebuild it.

If QEMU and QTOOL specified, the one in prebuilt will be used in advance.

While porting to newer kernel, Linux 5.0 hangs during boot on qemu 2.5, after
compiling a newer qemu 2.12.0, no hang exists. please take notice such issue in
the future kernel upgrade.

### Using external toolchain

The pace of Linux mainline is very fast, builtin toolchains can not keep up, to
reduce the maintaining pressure, external toolchain feature is added. for
example, ARM64/virt, CCVER and CCPATH has been added for it.

Download, decompress and enable the external toolchain:

    $ make toolchain

If not external toolchain there, the builtin will be used back.

### Using external rootfs

Builtin rootfs is minimal, is not enough for complex application development, which requires modern Linux distributions.

Such a type of rootfs has been introduced and has been released as docker
image, ubuntu 18.04 is added for arm32v7 at first, more later.

Run it via docker directly:

    $ docker run -it tinylab/arm32v7-ubuntu

Extract it out and run in Linux Lab:

    $ tools/rootfs/docker/extract.sh tinylab/arm32v7-ubuntu arm
    $ make boot B=vexpress-a9 U=0 V=1 MEM=1024M ROOTDEV=/dev/nfs ROOTDIR=$PWD/prebuilt/fullroot/tmp/tinylab-arm32v7-ubuntu

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

Run guest test cases (need install new `system/` via `make r-i`):

    $ make test TEST_BEGIN=date TEST_END=date TEST_FINISH=echo TEST_CASE='"ls /root","echo hello world"'

Reboot the guest system for several times:

    $ make test TEST_REBOOT=2

Test a feature of a specified linux version on a specified board:

    $ make test FEATURE=kft LINUX=v2.6.36 BOARD=malta TEST=prepare

Test a kernel module:

    $ make test m=oops_test

Test multiple kernel modules:

    $ make test m=oops_test,kmemleak_test

Run test cases while testing kernel modules:

    $ make test m=oops,kmemleak TEST_BEGIN=date TEST_END=date TEST_FINISH=echo TEST_CASE='"ls /root","echo hello world"'

Test a kernel module and make some targets before testing:

    $ make test m=oops_test TEST=kernel-checkout,kernel-patch

Test everything in one command (from download to poweroff):

    $ make test TEST=kernel-full,root-full

Test everything in one command (with uboot while support, e.g. vexpress-a9):

    $ make test TEST=kernel-full,root-full,uboot-full

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

If using `board`, it only works on-the-fly, the setting will not be saved, this
is helpful to run multiple boards at the same and not to disrupt each other:

    $ make board=malta root-defconfig
    $ make board=malta root
    $ make board=malta kernel-checkout
    $ make board=malta kernel-patch
    $ make board=malta kernel-defconfig
    $ make board=malta kernel
    $ make board=malta boot U=0

This allows to run multi boards in different terminals or background at the
same time.

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

## Plugins

The 'Plugin' feature is supported by Linux Lab, to allow boards being added and maintained in standalone git repositories. Standalone repository is very important to ensure Linux Lab itself not grow up big and big while more and more boards being added in.

Book examples or the boards with a whole new cpu architecture benefit from such feature a lot, for book examples may use many boards and a new cpu architecture may need require lots of new packages (such as cross toolchains and the architecture specific qemu system tool).

Here maintains the available plugins:

- [C-Sky Linux](https://github.com/tinyclub/csky)
- [RLK4.0 Book Examples](https://github.com/tinyclub/rlk4.0)

## More

### Add a new board

#### Chooose a board supported by qemu

list the boards, use arm as an example:

    $ qemu-system-arm -M ?

#### Create the board directory

Use `vexpress-a9` as an example:

    $ mkdir boards/vexpress-a9/

#### Clone a Makefile from an existing board

Use `versatilepb` as an example:

    $ cp boards/versatilebp/Makefile boards/vexpress-a9/Makefile

#### Configure the variables from scratch

Comment everything, add minimal ones and then others.

Please refer to `doc/qemu/qemu-doc.html` or the online one `http://qemu.weilnetz.de/qemu-doc.html`.

#### At the same time, prepare the configs

We need to prepare the configs for linux, buildroot and even uboot.

Buildroot has provided many examples about buildroot and kernel configuration:

* buildroot: `buildroot/configs/qemu_ARCH_BOARD_defconfig`
* kernel: `buildroot/board/qemu/ARCH-BOARD/linux-VERSION.config`

Uboot has also provided many default configs:

* uboot: `u-boot/configs/vexpress_ca9x4_defconfig`

Kernel itself also:

* kernel: `linux-stable/arch/arm/configs/vexpress_defconfig`

Edit the configs and Makefile untill they match our requirements.

#### Save the images and configs

    $ make root-save
    $ make kernel-save
    $ make uboot-save

    $ make rconfig-save
    $ make kconfig-save
    $ make uconfig-save

#### Upload everything

At last, upload the images to the `prebuilt/` repository and the new board directory to the `linux-lab` repository.

* prebuilt: <https://github.com/tinyclub/prebuilt>
* linux-lab: <https://github.com/tinyclub/linux-lab>

### Learning Assembly

Linux Lab has added many assembly examples in `examples/assembly`:

    $ cd examples/assembly
    $ ls
    aarch64  arm  mips64el	mipsel	powerpc  powerpc64  README.md  x86  x86_64
    $ make -s -C aarch64/
    Hello, ARM64!


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

### Note5

We assume the docker network is `10.66.0.0/16`, if not, we'd better change it.

    $ cat /etc/default/docker | grep bip
    DOCKER_OPTS="$DOCKER_OPTS --bip=10.66.0.10/16"

    $ cat /lib/systemd/system/docker.service | grep bip
    ExecStart=/usr/bin/dockerd -H fd:// --bip=10.66.0.10/16
