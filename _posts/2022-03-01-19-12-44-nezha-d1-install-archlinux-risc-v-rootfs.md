---
layout: post
author: 'taotieren'
title: "为哪吒  D1 开发板安装 ArchLinux RISC-V rootfs"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /nezha-d1-archlinux/
description: "本文详细介绍了如何为 哪吒 D1 开发板安装 ArchLinux RISC-V rootfs，并详细解答了如何修复相关的问题。大家也可以参考本文在 D1 上运行 Debian。"
category:
  - Risc-V
  - Arch Linux
tags:
  - NeZha
  - 哪吒
  - D1
  - ArchLinux
  - Debian
  - RISC-V
---

> By taotieren of [TinyLab.org][1]
> Mar 01, 2022

## 简介

哪吒 D1 是目前市面上性能最强的国产 RISC-V 芯片，本文介绍如何通过 TF 卡运行 ArchLinux RISC-V rootfs。

目前在 RISC-V 上运行 ArchLinux 还要走一点弯路，需要先制作 Debian 的启动盘，之后把文件系统部分替换为 ArchLinux，其他部分还需要共享 Debian 提供的支持。

## 制作 RVBoards 的 Debian RISC-V TF 启动卡

那接下来，先制作 Debian RISC-V TF 启动卡，请参考：[「RVBoards-哪吒」D1 Debian系统镜像和安装方法](https://rvboards.org/forum/cn/topic/61/rvboards-%E5%93%AA%E5%90%92-d1-debian%E7%B3%BB%E7%BB%9F%E9%95%9C%E5%83%8F%E5%92%8C%E5%AE%89%E8%A3%85%E6%96%B9%E6%B3%95/2)

另外，上面没提到的坑也需要修复一下。

### 修复可能残留的分区表导致的 rootfs 挂载失败问题

根据 [内核无法访挂载 rootfs](https://fedoraproject.org/wiki/Architectures/RISC-V/Allwinner/zh-cn#.E5.86.85.E6.A0.B8.E6.97.A0.E6.B3.95.E8.AE.BF.E6.8C.82.E8.BD.BDrootfs) 这里的介绍，如果出现下面的错误日志，说明您使用的 SD 卡存在 GPT 分区表残留，导致内核不知道如何找到 rootfs (似乎您忘记了在烧写前使用 **wipefs** 清理 GPT 备份分区表) ：

```bash
[    9.015501] md: Waiting for all devices to be available before autodetect
[    9.039910] md: If you don't use raid, use raid=noautodetect
[    9.064235] md: Autodetecting RAID arrays.
[    9.085291] md: autorun ...
[    9.104713] md: ... autorun DONE.
[    9.126379] List of all partitions:
[    9.146691] b300        15558144 mmcblk0
[    9.146697]  driver: mmcblk
[    9.186490]   b301         1048576 mmcblk0p1 1676bb7b-c349-4f5b-a48a-0f77d0cb680b
[    9.186495]
[    9.228663]   b302              32 mmcblk0p2 de35d1f7-9081-4f33-8952-3bc51a4b10c6
[    9.228668]
[    9.270932]   b303           16384 mmcblk0p3 47aae416-9ac3-47dc-a4f4-8023251eaefc
[    9.270937]
[    9.313210]   b304        14491119 mmcblk0p4 b93e5544-034f-41b7-b64d-1d7c2a5cfe58
[    9.313214]
[    9.355206] No filesystem could mount root, tried:
[    9.355212]  ext4
[    9.376478]
[    9.411420] Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(179,4)
[    9.436391] CPU: 0 PID: 1 Comm: swapper Not tainted 5.4.61 #3
[    9.458151] Call Trace:
[    9.475929] [<ffffffe0000d6598>] walk_stackframe+0x0/0xc4
[    9.496999] [<ffffffe0000d6838>] show_stack+0x3c/0x46
[    9.517441] [<ffffffe000bb19f6>] dump_stack+0x24/0x2c
[    9.537749] [<ffffffe0000e1f0a>] panic+0x100/0x32a
[    9.557557] [<ffffffe000001522>] 0xffffffe000001522
[    9.577224] [<ffffffe0000015e2>] 0xffffffe0000015e2
[    9.596711] [<ffffffe00000173c>] 0xffffffe00000173c
[    9.616044] [<ffffffe00000105e>] 0xffffffe00000105e
[    9.635113] [<ffffffe000bc6e5a>] kernel_init+0x1c/0x100
[    9.654494] [<ffffffe0000d4838>] ret_from_exception+0x0/0xc
[    9.674194] ---[ end Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(179,4) ]---
```

解决的办法是，将出问题的 SD 卡插入 PC，通过 gdisk 清除残余的分区表，过程如下：

```bash
$ sudo gdisk  /dev/sdf   # sdX 表示 TF/SD 卡磁盘号，此处以 sdf 为例
...

Found valid MBR and corrupt GPT. Which do you want to use? (Using the
GPT MAY permit recovery of GPT data.)
 1 - MBR
 2 - GPT
 3 - Create blank GPT

Your answer: 1

Command (? for help): p
Disk /dev/sdf: 62333952 sectors, 29.7 GiB
Model: Multi-Reader  -3
Sector size (logical/physical): 512/512 bytes
Disk identifier (GUID): 632BFA1B-F09D-42A8-82F4-5FAB32E41DC2
Partition table holds up to 128 entries
Main partition table begins at sector 2 and ends at sector 33
First usable sector is 34, last usable sector is 62333918
Partitions will be aligned on 2048-sector boundaries
Total free space is 37084093 sectors (17.7 GiB)

Number  Start (sector)    End (sector)  Size       Code  Name
   2           69632          319487   122.0 MiB   0700  Microsoft basic data
   3          319488         1320959   489.0 MiB   8300  Linux filesystem
   4         1320960        25319423   11.4 GiB    8300  Linux filesystem

Command (? for help): w

Final checks complete. About to write GPT data. THIS WILL OVERWRITE EXISTING
PARTITIONS!!

Do you want to proceed? (Y/N): y
OK; writing new GUID partition table (GPT) to /dev/sdf.
Warning: The kernel is still using the old partition table.
The new table will be used at the next reboot or after you
run partprobe(8) or kpartx(8)
The operation has completed successfully.
```

可进一步通过 `wipefs` 擦除 TF 卡的分区信息

```bash
$ sudo wipefs -a /dev/sdX  # sdX 表示 TF/SD 卡磁盘号
$ sudo dd if=Fedora-riscv64-d1-developer-xfce-with-esp-Rawhide-latest-sda.raw of=/dev/sdX status=progress bs=4M
```

### 修复潜在的启动卡无法格式化问题

如果在 win10 上通过全志的 TF 卡制作启动盘工具，请使用 [PhoenixCardv4.2.7.7z](https://www.aw-ol.com/downloads/resources/42) 在 `2021/07/14 08:56:40` 更新的版本，否则会出现**启动卡无法格式化**，**无法制作成功**等糟心的问题。

### 可选操作：扩展根文件系统分区尺寸

插入读卡器到 Linux 系统下，执行以下操作来扩展根文件系统分区尺寸：（sdX 的 X 表示你实际的读卡器盘符字母）

```bash
$ sudo e2fsck -f /dev/sdX7
$ sudo resize2fs -p /dev/sdX7
```

## 启动 Debian RISC-V TF卡

制作完成后，接下来启动 Debian RISC-V TF 卡。

首先使用 USB2TTL 串口工具链接 D1 的 debug 口，插入 TF 到 D1 的 TF 卡座，然后使用 minicom 连接串口。

连接之前，请确认关闭 minicom 的硬件流控，具体操作如下：

```
$ sudo minicom -s
           +-----[设置]---------+
           | 文件名和路径       |
           | 文件传输协定       |
           | 串口设置           |
           | 调制解调器和拨接   |
           | 屏幕和键盘         |
           | 保存设置为 dfl     |
           | 另存设置为…        |
           | 离开本画面         |
           | 离开 Minicom       |
           +--------------------+
```

选择 “串口设置”，设定效果如下：

    +-----------------------------------------------------------------------+
    | A - 串行设备               : /dev/modem                               |
    | B - 锁文件位置              : /var/run                                |
    | C - 拨入程序               :                                          |
    | D - 拨出程序               :                                          |
    | E - Bps/Par/Bits       : 115200 8N1                                   |
    | F - 硬件流控制              : 否                                      |
    | G - 软件流控制              : 否                                      |
    | H -     RS485 Enable      : No                                        |
    | I -   RS485 Rts On Send   : No                                        |
    | J -  RS485 Rts After Send : No                                        |
    | K -  RS485 Rx During Tx   : No                                        |
    | L -  RS485 Terminate Bus  : No                                        |
    | M - RS485 Delay Rts Before: 0                                         |
    | N - RS485 Delay Rts After : 0                                         |
    |                                                                       |
    |    变更设置？                                                         |
    +-----------------------------------------------------------------------+

**说明**：按 F 切换硬件流控，选择为关闭，按回车间确认，放回到主界面保存设置。

确认无误后，再次连接 D1 串口：

```
$ minicom -c on -b 115200 -D /dev/ttyUSB0
```

然后使用 Type-C 数据线连接 OTG 接口，minicom 会输出相应启动信息。

不出意外的话会进入 Debian RISC-V 的系统。

Debian RISC-V 系统默认用户名：`root` 密码：`rvboards`

## 备份 Debian RISC-V 的 rootfs

后面需要把 Debian 替换为 ArchLinux，这里先做一下备份，方便后面使用。

将 D1 断电，拔出 TF 卡，通过读卡器挂载到自己的开发主机上，然后备份好 Debian RISC-V 的 rootfs。

此处以 sde5 为例，根据实际情况找到 rootfs 磁盘：

```bash
$ mount /dev/sde5 /mnt
$ cd /mnt
```

备份当前 Debian RISC-V rootfs：

```
$ tar -zcvf . ~/debian-riscv-`date -s`.tar.xz
```

删除 Debian RISC-V rootfs（**注意**：请确保当前在刚挂载的 /mnt 目录下）：

```
$ pwd
/mnt
$ sudo rm -rf .
```

## 替换为 ArchLinux RISC-V rootfs

接下来回到主题，我们把 Debian rootfs 替换为 ArchLinux。

### 下载 ArchLinux risc-v rootfs 系统

将 archriscv-20210601.tar.zst 下载到 ~/ 下：

```bash
$ wget -c https://archriscv.felixc.at/images/archriscv-20210601.tar.zst
```

### 解压 ArchLinux RISC-V rootfs

将 archriscv-20210601.tar.zst 解压到上面准备好的 /mnt 下：

ArchLinux 系统用户可以这么操作：

```
$ sudo bsdtar -xvf ~/archriscv-20210601.tar.zst -C /mnt/
```

非 ArchLinux 系统用户，依赖 zstd 库，没有此库的用户自行安装：

```
sudo tar -I zstd -xvf ~/archriscv-20210601.tar.zst -C /mnt/
```

## 配置 ArchLinux RISC-V rootfs

### 通过虚拟机启动 ArchLinux RISC-V rootfs

```bash
$ sudo systemd-nspawn -D /mnt/ --machine archriscv -a -U
```

ArchLinux RISC-V 的默认` root` 密码为 `sifive`。


**说明**: `systemd-nspawn` 来自包 systemd-container。

### 配置 ArchLinux RISC-V 的静态 IP 地址

此处以默认网卡为 eth0 为例，实际通过  `ip addr` 获取网卡信息：

首先查看网络状态：

```bash
$ sudo systemctl status systemd-networkd
```

通过 cat 配置静态 IP 文件：

```
$ sudo cat > /etc/systemd/network/10-static-eth0.network << EOF
[Match]
Name=eth0

[Network]
Address=192.168.1.199/24
Gateway=192.168.1.1
DNS=192.168.1.1 223.5.5.5 114.114.114.114
EOF
```

把服务加入开机自启：

```
sudo systemctl reenable systemd-networkd
```

重启系统：

```
sudo reboot
```

查看 IP：

```
$ ip addr # 或者 ifconfig
```

如果静态 IP 重启后变成动态 IP，可以审查是否因为 `networkmanager` 引起，如果是请执行下面命令卸载：

```
sudo pacman -Rsn `pacman -Qsq networkmanager` network-manager-applet
```

### 配置 /etc/fstab

这里主要是使得根目录是 rw 的（这能避免一些 SEGV）：

```bash
/dev/mmcblk0p5  /       ext4    rw      0       1
```

### 修改镜像源

如果存在类似下面的 `SSL` 连接错误：

```bash
pacman -Syyus
.ac.cn/archriscv_archriscv.felixc.at_g' /etc/pacman.conf  cat /etc/pacman.conf
:: Synchronizing package databases...
error: failed retrieving file 'core.db' from archriscv.felixc.at : SSL certificate problem: certificate is not yet valid
error: failed to update core (download library error)
error: failed retrieving file 'extra.db' from archriscv.felixc.at : SSL certificate problem: certificate is not yet valid
error: failed to update extra (download library error)
error: failed retrieving file 'community.db' from archriscv.felixc.at : SSL certificate problem: certificate is not yet valid
error: failed to update community (download library error)
error: failed to syn
```

请将 https 替换成 http：

```bash
$ sudo sed -i 's_https_http_g' /etc/pacman.conf
```

如果是下载速度慢可以换其他镜像站：

```bash
$ sudo sed -i 's_archriscv.felixc.at_mirrors.wsyu.edu.cn/archriscv_g' /etc/pacman.conf
```

### 退出 ArchLinux RISC-V 虚拟机

按下 `Ctrl + D` 或输入：

```bash
exit
```

### 卸载 `/mnt` 分区

```bash
sudo umount -R /mnt
```

## 正式使用 ArchLinux RISC-V rootfs

安全弹出 TF 卡，插入 D1 TF 卡座，OTG 接口供电，不出意外是能进入 ArchLinux risc-v 的 rootfs。

请注意，ArchLinux RISC-V 的默认` root` 密码为 `sifive`。

## 参考连接

- [在 RISC-V 板子（哪吒 D1）上安装 Arch Linux    ](https://blog.zenithal.me/2021/08/28/%E5%9C%A8-RISC-V-%E6%9D%BF%E5%AD%90%EF%BC%88%E5%93%AA%E5%90%92-D1%EF%BC%89%E4%B8%8A%E5%AE%89%E8%A3%85-Arch-Linux/)
- [Allwinner Nezha](https://linux-sunxi.org/Allwinner_Nezha)
- [Arch Linux RISC-V](https://archriscv.felixc.at/)
- [Debian by PerfXLab](https://d1.docs.aw-ol.com/strong/strong_4debian/)
- [「RVBoards-哪吒」D1 Debian系统镜像和安装方法](https://rvboards.org/forum/cn/topic/61/rvboards-%E5%93%AA%E5%90%92-d1-debian%E7%B3%BB%E7%BB%9F%E9%95%9C%E5%83%8F%E5%92%8C%E5%AE%89%E8%A3%85%E6%96%B9%E6%B3%95)
- [在哪吒上启动Fedora的最简说明](https://fedoraproject.org/wiki/Architectures/RISC-V/Allwinner/zh-cn#.E4.BF.AE.E5.A4.8DSD.E5.8D.A1.E4.B8.AD.E7.9A.84.E5.90.AF.E5.8A.A8.E5.9B.BA.E4.BB.B6)

**ArchLinux 生命不息，折腾不止！**


[1]: https://tinylab.org
