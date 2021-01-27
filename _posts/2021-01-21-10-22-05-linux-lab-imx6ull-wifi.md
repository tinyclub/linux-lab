---
layout: post
author: 'Li Hongyan'
title: "Linux Lab 真板开发日志（3）：macOS 环境之 SD 卡、无线网卡、虚拟串口"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /linux-lab-imx6ull-part3/
description: "本文详细介绍了如何在 macOS 下通过 Linux Lab 来开发首块适配的 i.MX6ULL Pro 真实硬件开发板，内容包括使用 SD 卡启动并分别通过无线网卡和虚拟串口通信。"
category:
  - Linux Lab
  - WIFI
tags:
  - 野火
  - 开发板
  - 真实开发板
  - ARM
  - i.MX6ULL
  - IMX6ULL
  - Linux Lab 真板
  - 串口虚拟化
  - macOS
---

> By alitrack of [TinyLab.org](http://tinylab.org)
> Jan 21, 2021

## 关于 i.MX6ULL Pro 开发板

首先非常感谢泰晓科技提供的 “i.MX6ULL Pro” Linux 开发板，这块开发板由 [泰晓科技技术社区](http://tinylab.org) 与 [野火电子](https://embedfire.com/) 合作适配，是首款 Linux Lab 真板，可以直接用 Linux Lab 开展相关实验，大大降低开发板使用门槛，提升 Linux 内核和嵌入式 Linux 技术的学习效率。

**主要配置**：

- CPU：NXP i.MX6ULL Cortex-A7，800M，工业级
- 内存：512M DDR3L
- 存储：8GB eMMC 或者（512MB Nand-FLASH)

## 准备工作

- i.MX6ULL Pro 开发板
- macOS
  - Docker
- 网线（插开发板eth1）
- EDUP EP-N8508GS（免驱无线网卡）
- 4GB 高速SD卡

i.MX6ULL Pro 开发板可以直接从 [泰晓科技自营店](https://shop155917374.taobao.com/) 选购。

该开发板支持 SD 卡和 Wi-Fi，但不同时支持两者，而笔者刚好有一个很久之前买的 Linux 免驱 mini USB 无线网卡：EDUP EP-N8508GS，本文主要做的尝试就是：

* 烧录 Debian 镜像至 SD 卡
* SD 卡启动开发板
* 编译更新 zImage, dtb 和 modules
* EDUP EP-N8508GS 当作无线网卡
* EDUP EP-N8508GS 当作 SoftAP 热点
* 无网线时，Linux Lab 如何访问开发板

## 烧录 Debian 镜像至 SD 卡

* 下载 i.MX6ULL Debian 镜像

> 云盘资料：i.MX6ULL Debian 镜像百度云链接
> 链接：https://pan.baidu.com/s/1pqVHVIdY97VApz-rVVa8pQ
> 提取码：uge1

* 烧录到 SD 卡

    推荐使用 [Etcher](https://www.balena.io/etcher), 也可以使用命令行命令 `dd`。

    以下命令在 macOS 上执行，首先获得 SD 卡的信息：

        $ diskutil list
        /dev/disk4 (external, physical):
           #:                       TYPE NAME                    SIZE       IDENTIFIER
           0:     FDisk_partition_scheme                        *4.0 GB     disk4
           1:             Windows_FAT_16 ⁨BOOT⁩                    41.9 MB    disk4s1
           2:                      Linux ⁨⁩                        3.9 GB     disk4s2

    接着卸载，不然会报 Resource busy：

        $ diskutil unmount /dev/disk4s2

    然后烧录：

        $ sudo dd if=~/Downloads/imx6ull-debian-buster-console-armhf-2020-11-26-344M.img of=/dev/disk4s2 bs=1m

## 通过 SD 启动开发版

插好 SD 卡，并根据文档，调整拨码开关为 **2-5-8**，然后上电启动。

<img src="/wp-content/uploads/2021/01/linux-lab/linux-lab-n-mx6ull-wifi/258.png" alt="调整拨码开关为2-5-8" style="zoom:50%;" />

## 通过串口访问开发板

i.MX6ULL Pro 带一个 USB 转串口（mini USB）和一个 micro USB（USB OTG）， 第一个需要安装 [CH340驱动](http://www.wch.cn/products/CH340.html) 并重启 macOS。

<img src="/wp-content/uploads/2021/01/linux-lab/linux-lab-n-mx6ull-wifi/usb_otg.png" alt="micro USB" style="zoom:50%;" />

<img src="/wp-content/uploads/2021/01/linux-lab/linux-lab-n-mx6ull-wifi/usb_serial.png" alt="USB转串口" style="zoom:50%;" />

可以访问串口的终端工具很多，Windows 下如 MobaXterm、secureCRT、xShell、Putty 等，macOS 下也可以使用 putty，当然电脑自带的 screen 也够用了。

* 先获得串口名（每台机器，每个 USB 口返回的结果不相同）

    microUSB：

        $ ls /dev | grep cu.
        /dev/cu.usbmodem1234fire56783

    USB转串口：

        $ ls /dev | grep cu.
        /dev/cu.usbserial-1420

* 通过串口访问开发板

        $ screen -L /dev/cu.usbserial-1420 115200 -L

<img src="/wp-content/uploads/2021/01/linux-lab/linux-lab-n-mx6ull-wifi/screen.png" alt="screen" style="zoom:50%;" />

自带的 Debian 镜像不支持 EDUP EP-N8508GS ， 下面试试 TinyLab 提供的 [ebf-imx6ull](https://gitee.com/tinylab/linux-lab/tree/master/boards/arm/ebf-imx6ull)。

## 编译更新 zImage, dtb 和 modules

1. 准备工作目录

        $ hdiutil create -type SPARSE -size 60g -fs "Case-sensitive Journaled HFS+" -volname labspace labspace.dmg
        $ hdiutil attach -mountpoint ~/Documents/labspace -nobrowse labspace.dmg.sparseimage
        $ cd ~/Documents/labspace

2. 下载 Lab

        $ git clone https://gitee.com/tinylab/cloud-lab.git
        $ cd cloud-lab/ && tools/docker/choose linux-lab

3. 运行并登录 Lab

        $ tools/docker/run linux-lab
        $ tools/docker/bash

4. 选择 arm/ebf-imx6ull

        $ make BOARD=arm/ebf-imx6ull

5. 编译与安装

        $ make kernel-build
        $ make modules-install

6. 登录开发板

        $ BOARD_IP=192.168.16.128 make login
        ...
        npi login: debian
        Password: temppwd    <== default password, will be changed to linux-lab

7. 允许 root 登陆并更改 root 密码

    为方便起见，需要允许 root ssh 登录并把密码改为统一的 `linux-lab`。

        debian@npi:~$ sudo -s
        root@npi:/home/debian# passwd root
        New password: linux-lab
        Retype new passwd: linux-lab

        root@npi:/home/debian# sudo sed -i -e "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
        root@npi:/home/debian# sudo service sshd restart


8. 上传 zImage, dtb 和 modules

        $ make kernel-upload
        $ make dtb-upload
        $ make modules-upload

9. 切换并用新镜像重新启动开发板

        $ make boot

至此，SD 卡的系统已经更新为 Linux-lab 的版本。

## 配置 EDUP EP-N8508GS 为 Wi-Fi 网卡

在新的系统下，EDUP EP-N8508GS 支持即插即用。

    $ lsusb
    Bus 001 Device 004: ID 0bda:8176 Realtek Semiconductor Corp. RTL8188CUS 802.11n WLAN Adapter

    $ iwconfig
    wlan0     IEEE 802.11  Mode:Master  Tx-Power=20 dBm
              Retry short limit:7   RTS thr=2347 B   Fragment thr:off
              Power Management:off

使用如下命令配置 Wi-Fi：

    $ sudo connmanctl
    connmanctl> tether wifi off
    connmanctl> enable wifi
    connmanctl> scan wifi
    connmanctl> services
    connmanctl> agent on
    connmanctl> connect wifi_*_managed_psk
    connmanctl> quit

检查 wlan0 的 IP 信息：

    $ ifconfig
    wlan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
            inet 192.168.16.69  netmask 255.255.255.0  broadcast 192.168.16.255
            inet6 fe80::ea4e:6ff:fe20:543  prefixlen 64  scopeid 0x20<link>
            ether e8:4e:06:20:05:43  txqueuelen 1000  (Ethernet)
            RX packets 218  bytes 37973 (37.0 KiB)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 301  bytes 41631 (40.6 KiB)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

## 配置 EDUP EP-N8508GS 为 softAP 热点

1. 安装 hostapd

        $ sudo apt install -y hostapd

2. 配置 hostapd

        $ vim /etc/hostapd/hostapd.conf
        interface=wlan0
        hw_mode=g
        channel=1
        wmm_enabled=0
        macaddr_acl=0
        auth_algs=1
        ignore_broadcast_ssid=0
        wpa=2
        wpa_key_mgmt=WPA-PSK
        wpa_pairwise=TKIP
        rsn_pairwise=CCMP
        ssid=alitrack
        wpa_passphrase=12345678910
        ieee80211n=1

3. 配置防火墙

    添加 iptables 规则，将 wlan0 的包通过 eth1 转发：

        $ sudo iptables –t nat –A POSTROUTING –o eth1 –j MASQUERADE
        $ sudo iptables –A FORWARD –m conntrack —ctstate RELATED,ESTABLISHED –j ACCEPT
        $ sudo iptables –A FORWARD –i wlan0 –o eth1 –j ACCEPT
        $ sudo sh –c "iptables-save > /etc/iptables.ipv4.nat"


    打开内核 IP 转发：

        $ vim /etc/sysctl.conf
        net.ipv4.ip_forward=1

4. 配置网络

        $ vim /etc/network/interface

        #auto wlan0
        #allow-hotplug wlan0
        #iface wlan0 inet dhcp


        auto wlan0
        allow-hotplug wlan0
        iface wlan0 inet static
                address 192.168.0.1
                netmask 255.255.255.0
        up iptables-restore < /etc/iptables.ipv4.nat

5. 关闭 wpa_supplicant

        $ pkill wpa_supplicant
        $ sudo systemctl mask hostapd

6. 启动 hostapd

        $ sudo systemctl enable hostapd
        $ sudo systemctl start hostapd
        $ sudo systemctl status hostapd

7. 删除 autowifi.sh

        $ mv /opt/scripts/boot/autowifi.sh ~/

8. 重启 wlan0 或者开发板

        $ sudo ifdown wlan0
        $ sudo ifup wlan0
        $ ifconfig
        wlan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
                inet 192.168.0.1  netmask 255.255.255.0  broadcast 192.168.0.255
                inet6 fe80::ea4e:6ff:fe20:543  prefixlen 64  scopeid 0x20<link>
                ether e8:4e:06:20:05:43  txqueuelen 1000  (Ethernet)
                RX packets 788  bytes 116163 (113.4 KiB)
                RX errors 0  dropped 0  overruns 0  frame 0
                TX packets 860  bytes 484140 (472.7 KiB)
                TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

9. 用手机尝试连接, 成功

## 无网线时，如何通过 Linux Lab 访问开发板

前面我们提到通过 IP 来访问开发板，如果非常不凑巧，你既没有无线也无网线可以用，怎么办？

很不凑巧，macOS 下，Docker 内目前无法直接访问串口，需要通过泰晓科技撰写的 [串口虚拟化](http://tinylab.org/serial-port-over-internet/) 来解决这个问题。

1. macOS 安装 socat

        $ brew install socat

2. macOS 上串口转 TCP

        $ sudo socat tcp-l:54321 /dev/cu.usbserial-1420,clocal=1,nonblock

3. Linux Lab 上 TCP 转虚拟串口

        $ sudo socat pty,link=/dev/tty.virt001,waitslave tcp:192.168.1.168:54321

4. 登录开发板

        $ BOARD_SERIAL=/dev/tty.virt001 make login

## 小技巧

为了避免每次在命令行输入 `BOARD_IP` 和 `BOARD_SERIAL`，可以把它们配置到 `.labinit` 中。

    $ vim .labinit
    BOARD_IP := 192.168.16.128
    BOARD_SERIAL := /dev/tty.virt001

## 参考

* [野火i.MX Linux开发实战指南](http://doc.embedfire.com/linux/imx6/base/zh/latest/index.html)
* [Linux Lab ebf-imx6ull board](https://gitee.com/tinylab/linux-lab/tree/master/boards/arm/ebf-imx6ull)
* [Linux Lab](https://gitee.com/tinylab/linux-lab)
* [Raspberry Pi Zero W – Wireless Router](https://github.com/AndreiFAD/Raspberry_Pi_Zero_W-Wireless_Router_with_VPN)
