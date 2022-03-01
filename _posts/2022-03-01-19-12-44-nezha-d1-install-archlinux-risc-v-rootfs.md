---
layout: post
author: 'Your Name'
title: "Nezha D1 安装 ArchLinux RISC V rootfs"
draft: true
# tagline: " 子标题，如果存在的话 "
# album: " 所属文章系列/专辑，如果有的话"
# group: " 默认为 original，也可选 translation, news, resume or jobs, 详见 _data/groups.yml"
license: "cc-by-nc-nd-4.0"
permalink: /Nezha-D1 install ArchLinux-RISC-V rootfs/
description: " 文章摘要 "
category:
  - category1
  - category2
tags:
  - NeZha-D1
  - Archlinux-RISC-V
---

> By taotieren of [TinyLab.org][1]
> Mar 01, 2022


# 哪吒 D1 通过 TF 卡运行 Arch Linux RISC-V rootfs

## 制作 RVBoards 的 Debian RISC-V TF 启动卡

1. 详细资料参考这里 ：[「RVBoards-哪吒」D1 Debian系统镜像和安装方法](https://rvboards.org/forum/cn/topic/61/rvboards-%E5%93%AA%E5%90%92-d1-debian%E7%B3%BB%E7%BB%9F%E9%95%9C%E5%83%8F%E5%92%8C%E5%AE%89%E8%A3%85%E6%96%B9%E6%B3%95/2)
2. 补充下这里面没提到的坑
   - 根据 [内核无法访挂载rootfs](https://fedoraproject.org/wiki/Architectures/RISC-V/Allwinner/zh-cn#.E5.86.85.E6.A0.B8.E6.97.A0.E6.B3.95.E8.AE.BF.E6.8C.82.E8.BD.BDrootfs) 这里的介绍

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

说明您使用的SD卡存在GPT分区表残留，导致内核不知道如何找到rootfs。(似乎您忘记了在烧写前使用 **wipefs** 清理 GPT 备份分区表) 解决的办法如下：

- 将出问题的SD卡插入PC，通过 gdisk 清除残余的分区表，过程如下：

```bash
# sdX 表示 TF/SD 卡磁盘号，此处以 sdf 为例
$ sudo gdisk  /dev/sdf
GPT fdisk (gdisk) version 1.0.5

Caution: invalid main GPT header, but valid backup; regenerating main header
from backup!

Warning: Invalid CRC on main header data; loaded backup partition table.
Warning! Main and backup partition tables differ! Use the 'c' and 'e' options
on the recovery & transformation menu to examine the two tables.

Warning! Main partition table CRC mismatch! Loaded backup partition table
instead of main partition table!

Warning! One or more CRCs don't match. You should repair the disk!
Main header: ERROR
Backup header: OK
Main partition table: ERROR
Backup partition table: OK

Partition table scan:
  MBR: MBR only
  BSD: not present
  APM: not present
  GPT: damaged

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

- 还可以通过 wipefs 擦除 TF 卡的分区信息

```bash
# sdX 表示 TF/SD 卡磁盘号
sudo wipefs -a /dev/sdX
sudo dd if=Fedora-riscv64-d1-developer-xfce-with-esp-Rawhide-latest-sda.raw of=/dev/sdX status=progress bs=4M
```

3. 如果在 win 10 上通过 全志的 TF 卡制作启动盘工具请使用 [PhoenixCardv4.2.7.7z](https://www.aw-ol.com/downloads/resources/42) 2021/07/14 08:56:40 更新的版本，否则会出现 启动卡无法格式化，无法制作成功等糟心的问题。

4. 可选操作：扩展根文件系统分区尺寸：

   插入读卡器到linux系统下，执行以下操作来扩展根文件系统分区尺寸：(sdX的X表示你实际的读卡器盘符字母)

   ```bash
   sudo e2fsck -f /dev/sdX7
   sudo resize2fs -p /dev/sdX7

   ```



## 启动 Debian RISC-V TF卡

1. 使用 USB2TTL 串口工具链接 D1 的 debug 口，插入 TF 到 D1 的 TF 卡座，
2. 使用 minicom 连接串口

```bash
# 注意连接 如果出现键盘输入信息，串口接收不到的情况，请关闭 minicom 的硬件流控。
# 关闭 minicom 硬件流控
$ sudo minicom -s
            +------[设置]---------+
            | 文件名和路径            |
            | 文件传输协定            |
            | 串口设置              |
            | 调制解调器和拨接          |
            | 屏幕和键盘             |
            | 保存设置为 dfl         |
            | 另存设置为…            |
            | 离开本画面             |
            | 离开 Minicom        |
            +-------------------+
#选择 串口设置

                                                                               -----------+

    +-----------------------------------------------------------------------+      |
    | A - 串行设备               : /dev/modem                                   | |
    | B - 锁文件位置              : /var/run                                     ||
    | C - 拨入程序               :                                              | |
    | D - 拨出程序               :                                              | |
    | E - Bps/Par/Bits       : 115200 8N1                                   |     |
    | F - 硬件流控制              : 否                                            |
    | G - 软件流控制              : 否                                            |
    | H -     RS485 Enable      : No                                        |
    | I -   RS485 Rts On Send   : No                                        |       |
    | J -  RS485 Rts After Send : No                                        |
    | K -  RS485 Rx During Tx   : No                                        |
    | L -  RS485 Terminate Bus  : No                                        |       |
    | M - RS485 Delay Rts Before: 0                                         |
    | N - RS485 Delay Rts After : 0                                         |          |
    |                                                                       |               |
    |    变更设置？                                                              |       |
    +-----------------------------------------------------------------------+             |

                                                                                                    |
# 按 F 切换硬件流控，选择为关闭，按回车间确认，放回到主界面保存设置。

# 连接 D1 串口
$ minicom -c on -b 115200 -D /dev/ttyUSB0
```



3. 使用 Type-C 数据线连接 OTG 接口，minicom 会输出相应启动信息
4. 不出意外的话会进入 Debian RISC-V 的系统
5.  Debian RISC-V 系统默认用户名：`root` 密码：`rvboards`

## 替换 Arch Linux  RISC-V rootfs

1. 国外的 [sunxi-linux Nezha](https://linux-sunxi.org/Allwinner_Nezha) 介绍如何移植主线内核
2. 肥猫的 [Arch Linux RISC-V](https://archriscv.felixc.at/) 项目
3.  下载 arch risc-v rootfs 系统

```bash
# 将 archriscv-20210601.tar.zst 下载到 ~/ 下
$ wget -c https://archriscv.felixc.at/images/archriscv-20210601.tar.zst
```

4. 将 D1 断电，拔出 TF 卡，通过读卡器挂载到电脑上
5. 备份 Debian RISC-V 的 rootfs

```bash
# 此处以 sde5 为例，根据实际情况找到 rootfs 磁盘
$ mount /dev/sde5 /mnt
$ cd /mnt
# 备份当前 Debian RISC-V rootfs
$ tar -zcvf . ~/debian-riscv-`date -s`.tar.xz
# 删除 Debian RISC-V rootfs
$ sudo rm -rf .
# 将 archriscv-20210601.tar.zst 解压到 /mnt 下
# Arch Linux 用户
$ sudo bsdtar -xvf ~/archriscv-20210601.tar.zst -C /mnt/
# 非 Arch Linux 用户，依赖 zstd 库，没有的此库的用户自行安装
sudo tar -I zstd -xvf ~/archriscv-20210601.tar.zst -C /mnt/
```

6. 启动 Arch Linux  RISC-V 虚拟机，Arch Linux RISC-V 的默认` root` 密码为 `sifive`

```bash
$ sudo systemd-nspawn -D /mnt/ --machine archriscv -a -U
# Arch Linux RISC-V 的默认 root 密码为 sifive
```

7. 配置 Arch Linux RISC-V 的静态 IP 地址

```bash
# 此处以默认网卡为 eth0 为例，实际通过  `ip addr` 获取网卡信息
# 查看网络状态
sudo systemctl status systemd-networkd
# 通过 cat 配置静态 IP 文件
cat > /etc/systemd/network/10-static-eth0.network << EOF
[Match]
Name=eth0

[Network]
Address=192.168.1.199/24
Gateway=192.168.1.1
DNS=192.168.1.1 223.5.5.5 114.114.114.114
EOF
# 把服务加入开机自启
sudo systemctl reenable systemd-networkd
# 重启系统
sudo reboot
# 查看 IP
ip addr //  或者 ifconfig
# 如果静态 IP 重启后变成动态 IP，可以审查是否因为 `networkmanager` 引起，如果是请执行下面命令卸载
sudo pacman -Rsn `pacman -Qsq networkmanager` network-manager-applet
```

8. 配置 `/etc/fstab`

```bash
# 使得根目录是 rw 的（这能避免一些 SEGV）
/dev/mmcblk0p5  /       ext4    rw      0       1
```

9. 修改镜像源

   如果是是 `SSL` 连接错误，如下：

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

```bash

# 将 https 替换成 http
sed -i 's_https_http_g' /etc/pacman.conf
```

如果是下载速度慢可以换其他镜像站：

```bash
sed -i 's_archriscv.felixc.at_mirrors.wsyu.edu.cn/archriscv_g' /etc/pacman.conf
```



10. 退出 Arch Linux  RISC-V 虚拟机

```bash
Ctrl + D
# 或
exit
```

11. 卸载 `/mnt` 分区

```bash
sudo umount -R /mnt
```

12. 安全弹出 TF 卡，插入 D1 TF 卡座，OTG 接口供电，不出意外是能进入 archlinux risc-v 的 rootfs

## 参考连接

- [在 RISC-V 板子（哪吒 D1）上安装 Arch Linux    ](https://blog.zenithal.me/2021/08/28/%E5%9C%A8-RISC-V-%E6%9D%BF%E5%AD%90%EF%BC%88%E5%93%AA%E5%90%92-D1%EF%BC%89%E4%B8%8A%E5%AE%89%E8%A3%85-Arch-Linux/)

- [Allwinner Nezha](https://linux-sunxi.org/Allwinner_Nezha)

- [Arch Linux RISC-V](https://archriscv.felixc.at/)

- [Debian by PerfXLab](https://d1.docs.aw-ol.com/strong/strong_4debian/)

- [「RVBoards-哪吒」D1 Debian系统镜像和安装方法](https://rvboards.org/forum/cn/topic/61/rvboards-%E5%93%AA%E5%90%92-d1-debian%E7%B3%BB%E7%BB%9F%E9%95%9C%E5%83%8F%E5%92%8C%E5%AE%89%E8%A3%85%E6%96%B9%E6%B3%95)

- [在哪吒上启动Fedora的最简说明](https://fedoraproject.org/wiki/Architectures/RISC-V/Allwinner/zh-cn#.E4.BF.AE.E5.A4.8DSD.E5.8D.A1.E4.B8.AD.E7.9A.84.E5.90.AF.E5.8A.A8.E5.9B.BA.E4.BB.B6)



# Arch Linux 生命不息，折腾不止！


[1]: http://tinylab.org
