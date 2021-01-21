---
layout: post
author: 'Li Hongyan'
title: "Linux Lab体验首块真实硬件开发板野火i.MX6ULL"
draft: true
# tagline: " 子标题，如果存在的话 "
# album: " 所属文章系列/专辑，如果有的话"
# group: " 默认为 original，也可选 translation, news, resume or jobs, 详见 _data/groups.yml"
license: "cc-by-nc-nd-4.0"
permalink: /linux-lab-n-mx6ull-wifi/
description: " "
category:
  - Linux Lab
  - WIFI
tags:
  - 野火
  - 开发板 
  - 真实开发板
  - ARM
  - IMX6ULL
---
> By alitrack of [TinyLab.org](http://tinylab.org)
> Jan 21, 2021


## 关于野火i.MX6ULL Pro 开发板

首先非常感谢TinyLab提供的由野火i.MX6ULL Pro Linux开发板， 这块开发板是由[泰晓科技技术社区](http://tinylab.org)与[野火电子](https://embedfire.com/)合作适配的首款 Linux Lab 真板，可以直接用 Linux Lab 开展相关实验，大大降低开发板使用门槛，提升 Linux 内核和嵌入式 Linux 技术的学习效率。

**主要配置**：

- CPU：NXP i.MX6ULL Cortex-A7，800M，工业级
- 内存：512M DDR3L
- 存储：8GB eMMC或者（512MB Nand-FLASH)

## 准备工作

- 野火i.MX6ULL Pro(512MB Nand-FLASH) 开发板
- MacOS

  - Docker
  - IP: 192.168.16.194
- 网线（插开发板eth1）
- EDUP EP-N8508GS（免驱无线网卡）
- 4GB 高速SD卡

野火i.MX6ULL Pro 开发板支持SD卡和Wi-Fi，但不同时支持两者，而我刚好有一个很久之前买的Linux免驱mini USB无线网卡，EDUP EP-N8508GS， 本文主要做的尝试就是，

* 烧录Debian镜像至SD卡
* SD卡启动开发板
* 编译更新zImage, dtb 和modules
* EDUP EP-N8508GS当作无线网卡
* EDUP EP-N8508GS当作SoftAP
* 无网线时，Linux Lab如何访问开发板

## 烧录Debian镜像至SD卡

* 下载imx6ul Debian镜像

```
云盘资料：imx6ul Debian镜像百度云链接
链接：https://pan.baidu.com/s/1pqVHVIdY97VApz-rVVa8pQ
提取码：uge1
```

* 烧录到SD卡

  推荐使用[Etcher](https://www.balena.io/etcher), 也可以使用命令行命令`dd`

```bash
#在macOS上执行以下命令

#获得SD卡的信息
$ diskutil list
/dev/disk4 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *4.0 GB     disk4
   1:             Windows_FAT_16 ⁨BOOT⁩                    41.9 MB    disk4s1
   2:                      Linux ⁨⁩                        3.9 GB     disk4s2

#卸载，不然会报Resource busy
$ diskutil unmount /dev/disk4s2

#烧录
$ sudo dd if=~/Downloads/imx6ull-debian-buster-console-armhf-2020-11-26-344M.img of=/dev/disk4s2 bs=1m
```


## SD启动开发版

查好SD卡，并根据文档，调整拨码开关为2-5-8

<img src="wp-content/uploads/2021/01/linux-lab/linux-lab-n-mx6ull-wifi/258.png" alt="调整拨码开关为2-5-8" style="zoom:50%;" />

上电启动。

## 通过串口访问开发板

野火i.MX6ULL Pro带一个USB转串口(mini USB)和一个micro USB（USB OTG）， 第一个需要安装[CH340驱动](http://www.wch.cn/products/CH340.html)并重启macOS。

<img src="wp-content/uploads/2021/01/linux-lab/linux-lab-n-mx6ull-wifi/usb_otg.png" alt="micro USB" style="zoom:50%;" />


<img src="wp-content/uploads/2021/01/linux-lab/linux-lab-n-mx6ull-wifi/usb_serial.png" alt="USB转串口" style="zoom:50%;" />

可以访问串口的终端工具很多，Windows下如MobaXterm、secureCRT、xShell、Putty等，mac下也可以使用putty，当然电脑自带的screen也够用了。

1. 先获得串口名（每台机器，每个USB口返回的结果不相同）

```bash
$ ls /dev|grep cu.
#microUSB
/dev/cu.usbmodem1234fire56783  

#USB转串口
/dev/cu.usbserial-1420
```

2. 通过串口访问开发板

```bash
$ screen -L /dev/cu.usbserial-1420 115200 –L
```

<img src="wp-content/uploads/2021/01/linux-lab/linux-lab-n-mx6ull-wifi/screen.png" alt="screen" style="zoom:50%;" />

野火的Debian镜像不支持EDUP EP-N8508GS ， 下面试试TinyLab提供的[ebf-imx6ull](https://gitee.com/tinylab/linux-lab/tree/master/boards/arm/ebf-imx6ull)

## 编译更新zImage, dtb 和modules

1. 准备工作目录

```bash
$ hdiutil create -type SPARSE -size 60g -fs "Case-sensitive Journaled HFS+" -volname labspace labspace.dmg
$ hdiutil attach -mountpoint ~/Documents/labspace -nobrowse labspace.dmg.sparseimage
$ cd ~/Documents/labspace
```

2. 下载Lab

```bash
$ git clone https://gitee.com/tinylab/cloud-lab.git
$ cd cloud-lab/ && tools/docker/choose linux-lab
```

3. 运行并登录Lab

```bash
$ tools/docker/run linux-lab
$ tools/docker/bash
```

4. 选择arm/ebf-imx6ull

```bash
$ make BOARD=arm/ebf-imx6ull
```

5. 编译与安装

```bash
$ make kernel-build
$ make modules-install
```

6. 登录开发板

```bash
$ BOARD_IP=192.168.16.128  make login
```

默认登录用户名是root，密码是linux-lab，为方便，建议修改root密码。

7. 上传zImage, dtb 和modules

```bash
$ make kernel-upload
$ make dtb-upload
$ make modules-upload
```

8. 重启

```bash
$ make boot
```

至此，SD卡的系统已经更新为Linux-lab的版本。

## 配置EDUP EP-N8508GS 为Wi-Fi

在新的系统下，EDUP EP-N8508GS支持即插即用。

```bash
$ lsusb
Bus 001 Device 004: ID 0bda:8176 Realtek Semiconductor Corp. RTL8188CUS 802.11n WLAN Adapter

$ iwconfig 
wlan0     IEEE 802.11  Mode:Master  Tx-Power=20 dBm   
          Retry short limit:7   RTS thr=2347 B   Fragment thr:off
          Power Management:off
```

使用如下命令配置Wi-Fi

```bash
#connman: WiFi
$ sudo connmanctl
connmanctl> tether wifi off
connmanctl> enable wifi
connmanctl> scan wifi
connmanctl> services
connmanctl> agent on
connmanctl> connect wifi_*_managed_psk
connmanctl> quit
```

检查wlan0的IP信息

```bash
$ ifconfig
wlan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.16.69  netmask 255.255.255.0  broadcast 192.168.16.255
        inet6 fe80::ea4e:6ff:fe20:543  prefixlen 64  scopeid 0x20<link>
        ether e8:4e:06:20:05:43  txqueuelen 1000  (Ethernet)
        RX packets 218  bytes 37973 (37.0 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 301  bytes 41631 (40.6 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

## 配置EDUP EP-N8508GS 为softAP

1. 安装hostapd

```bash
$ sudo apt install hostapd
```

2. 配置hostapd(/etc/hostapd/hostapd.conf)

```
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
```

3. 配置防火墙

   添加 iptables 规则，将 wlan0 的包通过 eth1 转发

```bash
$ sudo iptables –t nat –A POSTROUTING –o eth1 –j MASQUERADE
$ sudo iptables –A FORWARD –m conntrack —ctstate RELATED,ESTABLISHED –j ACCEPT
$ sudo iptables –A FORWARD –i wlan0 –o eth1 –j ACCEPT
$ sudo sh –c "iptables-save > /etc/iptables.ipv4.nat"
```


打开内核 IP 转发(/etc/sysctl.conf)

```
net.ipv4.ip_forward=1
```

1. 修改 /etc/network/interface

```
#auto wlan0
#allow-hotplug wlan0
#iface wlan0 inet dhcp


auto wlan0
allow-hotplug wlan0
iface wlan0 inet static
        address 192.168.0.1
        netmask 255.255.255.0
up iptables-restore < /etc/iptables.ipv4.nat
```

5. 关闭 wpa_supplicant

```bash
$ pkill wpa_supplicant
$ sudo systemctl mask hostapd
```

6. 启动hostapd

```bash
$ sudo systemctl enable hostapd
$ sudo systemctl start hostapd
$ sudo systemctl status hostapd
```

7. 删除autowifi.sh

```bash
$ mv /opt/scripts/boot/autowifi.sh ~/
```

8. 重启wlan0或者开发板

```bash
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
```

9. 用手机尝试连接, 成功

## 无网线时Linux Lab访问开发板的办法

前面我们提到通过IP来访问开发板，如果非常不凑巧，你没有网线或者有线口可以用， 怎么办？[串口虚拟化](http://tinylab.org/serial-port-over-internet/)可以帮你解决这个问题。

1. macOS安装socat

```bash
$ brew install socat
```

2. macOS上串口转TCP

```bash
$ sudo socat tcp-l:54321 /dev/cu.usbserial-1420,clocal=1,nonblock
```

3. Linux Lab上TCP转虚拟串口

```bash
$ sudo socat pty,link=/dev/tty.virt001,waitslave tcp:192.168.1.168:54321
```

4. 登录开发板

```bash
$ BOARD_SERIAL=/dev/tty.virt001 make login
```

## 参考

* [野火i.MX Linux开发实战指南](http://doc.embedfire.com/linux/imx6/base/zh/latest/index.html)
* [Linux Lab ebf-imx6ull board](https://gitee.com/tinylab/linux-lab/tree/master/boards/arm/ebf-imx6ull)
* [Linux Lab](https://gitee.com/tinylab/linux-lab)
* [Raspberry Pi Zero W – Wireless Router](https://github.com/AndreiFAD/Raspberry_Pi_Zero_W-Wireless_Router_with_VPN)
