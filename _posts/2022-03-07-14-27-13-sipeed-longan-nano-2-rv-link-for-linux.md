---
layout: post
author: 'taotieren'
title: "在 Linux 下制作 rv-link 调试器"
draft: false
license: "cc-by-nc-nd-4.0"
album: 'RISC-V Linux'
permalink: /rv-link-debugger/
description: "本文介绍了如何在 Linux 下，基于 Sipeed RV debugger plus JTAG+UART BL702 调试器，制作 rv-link 调试器"
category:
  - risc-v
  - sipeed
  - longan-nano
  - rv-link
  - linux
tags:
  - rv-link
  - longan-nano
---

> By taotieren of [TinyLab.org][1]
> Mar 07, 2022

## 序 -- 起因

某天在群里看到有人发 [sipeed2022_spring_competition](https://github.com/sipeed/sipeed2022_spring_competition) 的活动宣传图，如下：

>
> ~~矽速2022春季AIoT挑战赛~~
>
> ~~矽速(Sipeed)2022春季**AIoT挑战赛**，**万元大奖**等你来拿 ～~
> ~~赛题信息：https://github.com/sipeed/sipeed2022_spring_competition~~
> ~~转发比赛信息到1000人以上相关技术QQ群,500人专业微信群，或专业论坛，~~
> 即可到矽速官方店领取 BL702 JTAG+UART 调试小板一块～
> ~~（截图给客服，仅限第一次转发到该群有效, sipeed.taobao.com）~~
>

重点是可以白嫖一块 **BL702 JTAG+UART 调试小板** ，对于电子行业的用户来说这是无法拒绝的诱惑；而且还是调试工具。

于是白嫖了这块 [Sipeed RV debugger plus JTAG+UART BL702 调试器](https://item.taobao.com/item.htm?spm=a1z10.5-c-s.w4002-21410578033.17.30f959d6FDBot5&id=648095486021)(有需要的朋友，也可以去白嫖)，在他们官方的店铺看到了 [Sipeed Longan Nano RISC-V GD32VF103CBT6 单片机 带壳开发板](https://item.taobao.com/item.htm?spm=a1z10.1-c-s.w4004-24053782153.40.5f7652b1O61KAJ&id=601743142093)，没忍住，于是就有这篇 Linux 下制作 [rv-link](https://gitee.com/zoomdy/RV-LINK) 的调试器的文章。


## 准备 -- 初步了解

sipeed 官网关于**Longan nano**开发板的相关信息、RV-LINK 介绍信息和 PIO 插件信息。如下：

| 资源                                                         | 连接                                                         | 详情                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Longan nano wiki                                             | https://wiki.sipeed.com/hardware/zh/longan/Nano/Longan_nano.html | Longan Nano是基于兆易创新(GigaDevice)的GD32VF103CBT6(RISC-V架构)芯片设计的极简开发板。开发板将芯片所有IO引出，设计小巧精致，板载Type-C、LCD、SD卡、JTAG等接口，方便广大学生、工程师、极客爱好者们接触学习最新一代的 RISC-V处理器。 |
| GD32VF103CBT6 ，基于[芯来科技](http://www.nucleisys.com/).的Bumblebee内核 | http://dl.sipeed.com/LONGAN/Nano/DOC/                        | 支持 `RV32IMAC` 指令集及`ECLIC` 快速中断功能。内核功耗仅传统 `Cortex-M3` 的1/3. |
| Longan nano 开发工具                                         | https://dl.sipeed.com/LONGAN/Nano/Tools/                     | 注：Windows 平台                                             |
| Longan nano 相关手册                                         | https://dl.sipeed.com/shareURL/LONGAN/Nano/DOC               | 有中英文版本                                                 |
| Longan nano 引脚图和规格书                                   | https://dl.sipeed.com/shareURL/LONGAN/Nano/Spec              | 相关引脚信息                                                 |
| HDK 屏幕资料                                                 | https://dl.sipeed.com/shareURL/LONGAN/Nano/HDK               | 0.96 inch 80*160 IPS LCD                                     |
| Blink 闪灯程序                                               | https://wiki.sipeed.com/soft/longan/zh/get_started/blink.html | 在 vscode 使用 pio 插件开发，使用 jlink/sipeed-rv-debugger 工具调试，使用 gd32-dfu （仅供 windows）上位机下载调试，使用 zadig 替换驱动信息。 |
| RV-LINK 原始仓库（几年没更新了）                             | https://gitee.com/zoomdy/RV-LINK                             | 用 RISC-V 开发板实现的 RISC-V 仿真器。与其它仿真器不同的是：RV-LINK 通过 USB 串口直接与 GDB 交互，不需要 OpenOCD 之类的中介。 |
| rv-link 第三方仓库（进行了大量功能新增和优化）               | https://github.com/michahoiting/rv-link                      | This project aims to improve the original RV-LINK firmware with the following features:  Support for a newly designed hardware board with specific features, called *RVL-Probe* Support for JTAG over SPI + DMA; Additional diagnostics of the JTAG interface; Support for a second USB to serial adapter; A *CAN bus* logger; Easy updating of the RV-Link firmware; Support of running RV-Link on other host platforms (e.g. Linux PC+FT323 / Raspberry Pi); Additional `mon` commands; Additional NVM configurable items. |
| vscode 的 pio(PlatformIO) 插件                               | https://platformio.org/platformio-ide                        | 打开 VSCode -> 点击左侧扩展 -> 搜索 PlatformIO -> 点击安装插件 -> 等待安装完成 -> 重启 VSCODE |
| gd32-dfu-utils                                               | https://github.com/riscv-mcu/gd32-dfu-utils                  | Dfu-utils GD32 fork. Dfu-util - Device Firmware Upgrade Utilities |
| gd32-dfu-utils AUR 包                                        | https://aur.archlinux.org/packages/gd32-dfu-utils            | AUR 的 gd32-dfu-utils  包，做了处理避免和 dfu-utils 包冲突   |
| rv-link-udev-git AUR 包                                      | https://aur.archlinux.org/packages/rv-link-udev-git          | AUR 的 rv-link 的 udev 文件（驱动文件）                      |
| RV-Debugger-BL702                                            | https://github.com/sipeed/RV-Debugger-BL702                  | RV-Debugger-BL702 源码，RV-Debugger-BL702 is an opensource project that implement a JTAG+UART debugger with BL702C-A0. |
| python-bflb-mcu-tool                                         | https://aur.archlinux.org/packages/python-bflb-mcu-tool      | BOUFFALOLAB MCU TOOL                                         |
| python-bflb-iot-tool                                         | https://aur.archlinux.org/packages/python-bflb-iot-tool      | BOUFFALOLAB IOT TOOL                                         |
| python-bflb-crypto-plus                                      | https://aur.archlinux.org/packages/python-bflb-crypto-plus   | PyCryptoPlus is an extension to the Python Crypto module (www.pycrypto.org). |
| Bouffalo Lab Dev Cube For Ubuntu                             | https://dev.bouffalolab.com/media/upload/download/BouffaloLabDevCube-1.6.8-linux-x86.tar.gz | Dev Cube是博流提供的芯片集成开发工具，包含IOT程序下载、MCU程序下载和RF性能测试三大功能。工具提供程序固件启动时的时钟，电源，Flash参数等配置，并可根据用户需求对程序进行加密和签名，生成应用程序启动信息文件。工具还可烧写用户资源文件，分区表文件以及 EFUSE配置文件等。工具可对Flash进行擦、改、写 |
| bflb-mcu-tool                                                | https://pypi.org/project/bflb-mcu-tool                       | BOUFFALOLAB MCU TOOL                                         |


根据上面相关信息，大致有点了解后，应该知道如何安装 `git` 、 `vscode` 和 `pio` 插件 。以下默认已经安装。

## 编译 RV-LINK -- 踩踩坑

### RV-LINK 原始仓库进行编译

-   克隆 `RV-LINK` 源码

```bash
git clone https://gitee.com/zoomdy/RV-LINK.git
```

-   运行 `vscode` ，左侧找到 `pio`，单击后，选择 `打开本地工程`，选择上面 `RV-LINK` 所在位置
-   左下角单击 `编译图标[✔]` ，不出意外的话会有如下报错：

```bash
KeyError: "Invalid board option 'build.ldscript'":
File "~/.platformio/penv/lib/site-packages/platformio/builder/main.py", line 179:
env.SConscript(item, exports="env")
File "~/.platformio/packages/tool-scons/scons-local-4.3.0/SCons/Script/SConscript.py", line 597:
return _SConscript(self.fs, *files, **subst_kw)
File "~/.platformio/packages/tool-scons/scons-local-4.3.0/SCons/Script/SConscript.py", line 285:
exec(compile(scriptdata, scriptname, 'exec'), call_stack[-1].globals)
File "~/RV-LINK-master/RV-LINK-master/build.py", line 65:
LDSCRIPT_PATH = join(PROJ_DIR, "src", "link", "gd32vf103c-start", "RISCV", "gcc", board.get("build.ldscript"))
File "~/.platformio/penv/lib/site-packages/platformio/platform/board.py", line 46:
raise KeyError("Invalid board option '%s'" % path)
```

原因是 `build.ldscript` 参数发生变化，需要在工程目录下 `plateformio.ini` 进行如下修改：

```bash
; PlatformIO Project Configuration File
;
;   Build options: build flags, source filter, extra scripting
;   Upload options: custom port, speed and extra flags
;   Library options: dependencies, extra library storages
;
; Please visit documentation for the other options and examples
; http://docs.platformio.org/page/projectconf.html

[env:sipeed-longan-nano]
; platform = gd32v
platform = https://github.com/sipeed/platform-gd32v.git
;framework = gd32vf103-sdk
board = sipeed-longan-nano
monitor_speed = 115200
upload_protocol = dfu
debug_tool = sipeed-rv-debugger
board_build.ldscript = GD32VF103xB.lds
build_flags =
    -DGD32VF103C_START
    -DUSE_STDPERIPH_DRIVER
    -DUSE_USB_FS
    -DLINK_LONGAN_NANO
    -DTARGET_GD32VF103
    -DAPP_GDB_SERVER
    -DRVL_ASSERT_EN
    -MMD

extra_scripts =
    pre:build.py
src_filter =
    +<*>-<.git/>-<.svn/>-<example/>-<examples/>-<test/>-<tests/>
    -<app/riscv-prober>
    -<app/test-usb-serial/>
    -<link/gd32vf103c-start/rvl-link.c>
    -<link/gd32vf103c-start/rvl-button.c>
    -<link/gd32vf103c-start/rvl-led.c>
    -<link/gd32vf103c-start/rvl-jtag.c>
    -<link/gd32vf103c-start/gd32vf103c_start.c>
    -<link/gd32vf103c-start/rvl-jtag-inline.h>
    -<link/rvl-link-stub.c>
    -<link/gd32vf103c-start/RISCV/gcc/>
    +<link/gd32vf103c-start/RISCV/gcc/init.c>
    +<link/gd32vf103c-start/RISCV/gcc/handlers.c>
    +<link/gd32vf103c-start/RISCV/gcc/entry.S>
    +<link/gd32vf103c-start/RISCV/gcc/start.S>
    -<link/gd32vf103c-start/RISCV/stubs>
    +<link/gd32vf103c-start/RISCV/stubs/sbrk.c>
    -<link/gd32vf103c-start/GD32VF103_standard_peripheral/>
    +<link/gd32vf103c-start/GD32VF103_standard_peripheral/system_gd32vf103.c>
    +<link/gd32vf103c-start/GD32VF103_standard_peripheral/Source/gd32vf103_gpio.c>
    +<link/gd32vf103c-start/GD32VF103_standard_peripheral/Source/gd32vf103_rcu.c>
    +<link/gd32vf103c-start/GD32VF103_standard_peripheral/Source/gd32vf103_timer.c>
    +<link/gd32vf103c-start/GD32VF103_standard_peripheral/Source/gd32vf103_eclic.c>
    +<link/gd32vf103c-start/GD32VF103_standard_peripheral/Source/gd32vf103_exti.c>
    +<link/gd32vf103c-start/GD32VF103_standard_peripheral/Source/gd32vf103_pmu.c>

```



-   再次编译即可生成固件。
-   由于此 `RV-LINK` 停更两年以上，可以选择自己二次开发或使用第三方开发的其他 `RV-LINK`

### `rv-link` 第三方仓库编译

-   克隆 `rv-link` 源码

```bash
git clone https://github.com/michahoiting/rv-link.git
```

-   运行 `vscode` ，左侧找到 `pio`，单击后，选择 `打开本地工程`，选择上面 `RV-LINK` 所在位置
-   左下角单击 `编译图标[✔]` ，不出意外的话编译通过

## 烧录固件 -- gd32-dfu-utils

### 打包 gd32-dfu-utils

发现 linux 没有 gd32 的 dfu 刷固件工具，于是打包了 gd32-dfu-utils 来给 arch 系用户使用，打包的 `PKGBUILD` 文件内容如下

```bash
# Maintainer: taotieren <admin@taotieren.com>

pkgname=gd32-dfu-utils
pkgver=0.9
pkgrel=2
epoch=
pkgdesc="Dfu-utils GD32 fork. Dfu-util - Device Firmware Upgrade Utilities"
arch=('x86_64')
url="https://github.com/riscv-mcu/gd32-dfu-utils"
license=('GPLv2')
groups=()
depends=('libusb')
makedepends=()
checkdepends=()
optdepends=(
  'python: dfuse-pack tool support'
  'python-intelhex: Intel HEX file format support'
)
provides=("GD32-dfu-util")
conflicts=()
replaces=()
backup=()
options=('!strip')
install=
changelog=
source=("${pkgname}-${pkgver}.tar.gz::${url}/archive/refs/tags/v${pkgver}.tar.gz")
noextract=()
sha256sums=('6312461aab3650b0be8648a7afb9bbf2e63328defe80b25b6c2c85973b39f8f5')
#validpgpkeys=()

build() {
    cd "${srcdir}/${pkgname}-${pkgver}"
    ./autogen.sh
    ./configure --prefix=/usr
    make
}

package() {
    cd $pkgname-$pkgver
    make DESTDIR="$pkgdir" install
    install -Dm755 dfuse-pack.py "$pkgdir"/usr/bin/dfuse-pack
    install -Dm644 doc/40-dfuse.rules "$pkgdir"/usr/lib/udev/rules.d/40-gd32-dfuse.rules
    cd "$pkgdir"/usr/bin/
    for var in *; do mv "$var" "gd32-${var}"; done
    rm -rf "$pkgdir"/usr/share
}

```

-   `for var in *; do mv "$var" "gd32-${var}"; done` 将 `dfu` 的工具重命名成 `gb32-`开头，避免和 `dfu` 工具冲突，正常来说需要打 `patch` 暂时还没写，后续和 `gd32-dfu-utils` 维护者沟通下，是他那边修改还是我这边打包的时候打 `patch`

-   已经上传到 AUR 仓库 [gd32-dfu-utils](https://aur.archlinux.org/packages/gd32-dfu-utils)

### 命令行刷机操作

- 准备操作
- 按住 BOOT0 按钮，然后按下 RESET 按钮，释放 RESET 按钮，最后释放 BOOT0 按钮，进入 DFU 模式

通过 lsusb 或者 GD32 的 PID:VID 信息：

```bash
$ lsusb |grep GD
Bus 003 Device 052: ID 28e9:0189 GDMicroelectronics GD32 DFU Bootloader (Longan Nano)
```

命令行刷写固件，用法和 dfu 一致，其他 dfu 用户可以看 dfu 的帮助文档或其他用户的分享：

```bash
$ gd32-dfu-util -d 28e9:0189 -a 0 --dfuse-address 0x08000000:leave -D rvlink_fw_sipeed-longan-nano.hex
dfu-util 0.9

Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
Copyright 2010-2016 Tormod Volden and Stefan Schmidt
This program is Free Software and has ABSOLUTELY NO WARRANTY
Please report bugs to http://sourceforge.net/p/dfu-util/tickets/

gd32-dfu-util: Invalid DFU suffix signature
gd32-dfu-util: A valid DFU suffix will be required in a future dfu-util release!!!
Opening DFU capable USB device...
ID 28e9:0189
Run-time device DFU version 011a
Claiming USB DFU Interface...
Setting Alternate Setting #0 ...
Determining device status: state = dfuIDLE, status = 0
dfuIDLE, continuing
DFU mode device DFU version 011a
Device returned transfer size 2048
GD32 flash memory access detected
Device model: GD32VF103CB
Memory segment (0x08000000 - 0801ffff)(rew)
Erase size 1024, page count 128
Downloading to address = 0x08000000, size = 141046
gd32-dfu-util: Last page at 0x080226f5 is not writeable
```

通过 lsusb 确认刷入的固件是否别识别：

```bash
$ lsusb |grep GD
Bus 003 Device 053: ID 28e9:018a GDMicroelectronics Longan Nano
```

### 其他的可能的坑

Ubuntu 等系统需要将 `$USER` 加到 串口组(`uucp`) 里面（新版本一般是 `uucp` ，旧版本可能是其他的，使用 `ls -lsh /dev/ttyUSB*` 查看设备所在组。如果在 Linux 下调试时遇到串口不通或者提示没权限，把用户加入串口设备组里面，后重启电脑试试。示例：

查看 串口设备组：

```bash
$ ls -lash /dev/ttyS0
  0 crwxrwxrwx 1 root uucp 4, 64 Feb 15 19:09 /dev/ttyS0
```

将用户“taotieren”加入到“uucp”组中：

```bash
$ sudo gpasswd -a `whoami` uucp
[sudo] taotieren 的密码：
$ groups `whoami`
wheel uucp vboxusers taotieren
$ reboot
```

如果添加 uucp 后还是不能使用，尝试安装 uucp 软件包，以 Arch 为例，其他 Linux 根据设备组确认：

```bash
$ yay -Syu uucp
```



## 固件烧录 -- RV-Debugger-BL702

### `Bouffalo Lab Dev Cube`

我这边在 Arch 下运行有一些坑（内置的软件版本过低，和 Arch 最新的包不兼容），无法运行。

### 打包 bflb-mcu-tool

在 Bouffalo 官网找到 bflb-mcu-tool 的 python 源码包，编写 `PKGBUILD` 进行打包操作

```bash
# Maintainer: taotieren <admin@taotieren.com>

pkgname=python-bflb-mcu-tool
_name=${pkgname#python-}
pkgver=1.6.8
pkgrel=1
epoch=
pkgdesc="BOUFFALOLAB MCU TOOL"
arch=('any')
url="https://pypi.org/project/bflb-mcu-tool"
license=('unkown')
groups=()
depends=('python' )
makedepends=('python-build' 'python-installer' 'python-wheel')
checkdepends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=()
options=('!strip')
install=
changelog=
source=("${_name}-${pkgver}.tar.gz::https://files.pythonhosted.org/packages/a5/57/ab4a45ca3e7736c415f28502db6d897256332521025a52872b534d288207/$_name-$pkgver.tar.gz")
noextract=()
sha256sums=('675f24619aded8f1313bde5c0cb2da5100e519c7ec5234b3b2481b66e5aa8bcc')
#validpgpkeys=()

build() {
    cd "${srcdir}/${_name}-${pkgver}"
    python -m build --wheel --no-isolation
}

package() {
    cd "${srcdir}/${_name}-${pkgver}"
    python -m installer --destdir="${pkgdir}" dist/*.whl
}
```

-   上传到 AUR 仓库：[python-bflb-mcu-tool](https://aur.archlinux.org/packages/python-bflb-mcu-tool)

-   安装 python-bflb-mcu-tool

    ```bash
    yay -S python-bflb-mcu-tool
    ```

-   博流还有其他 python 包，也一并打包了，需要的话可以自行安装。

    ```bash
    # BOUFFALOLAB IOT TOOL
    yay -S python-bflb-iot-tool
    # PyCryptoPlus is an extension to the Python Crypto module (www.pycrypto.org).
    yay -S python-bflb-crypto-plus
    ```

### bflb-mcu-tool  固件烧录操作

- Windows

设备管理器确认 bl702 实际串口号：

```bash
.\bflb_mcu_tool.exe --chipname=bl702 --port=COM9 --xtal=32M --firmware="main.bin"
```

- Linux

通过 `lsusb` 获取 bl702 的 usb 信息，确认 bl702 实际串口号。

通过软件包安装后可以直接使用 `bflb_mcu_tool` ，如果是手动编译或者其他方式，自己设置运行路径即可。

建议参考前面的 AUR 中 python 编译和打包的操作，先将其打包成 whl 包，再用 python 安装 whl 包。

```bash
$ bflb_mcu_tool --chipname=bl702 --port=ttyUSB1 --xtal=32M --firmware="main.bin"
```

## 安装驱动 -- rv-link-udev

### 安装 `rv-link` 里面的 `99-rvlink-jtag.rules`

手动安装 99-rvlink-jtag.rules 到系统的 `/etc/udev/rules.d/99-rvlink-jtag.rules`，如果打包的话安装至 `/usr/lib/udev/rules.d/99-rvlink-jtag.rules`。

```bash
$ sudo install -Dm0644 "rv-link/drivers/udev/rules.d/99-rvlink-jtag.rules" "/usr/lib/udev/rules.d/99-rvlink-jtag.rules"
$ sudo install -Dm0644 "rv-link/drivers/udev/rules.d/99-rvlink-jtag.rules" "/etc/udev/rules.d/99-rvlink-jtag.rules"
```
### 打包 `99-rvlink-jtag.rules`

将 `99-rvlink-jtag.rules` 打包到 AUR 仓库，编写相应的 `PKGBUILD`

```bash
# Maintainer: taotieren <admin@taotieren.com>

pkgname=rv-link-udev-git
pkgver=0.2.1.r95.g04f3781
pkgrel=1
pkgdesc="A JTAG emulator/debugger for RISC-V micro-controllers that runs on a RISC-V development board (Sipeed Longan Nano for example)."
arch=('any')
url="https://github.com/michahoiting/rv-link"
license=('MulanPSL')
provides=(${pkgname%-git})
conflicts=()
#replaces=(${pkgname})
depends=('libusb')
makedepends=('git')
backup=()
options=('!strip')
#install=${pkgname}.install
source=("${pkgname%-git}::git+${url}.git")
sha256sums=('SKIP')

pkgver() {
    cd "${srcdir}/${pkgname%-git}"
    git describe --long --tags | sed 's/^v//g' | sed 's/\([^-]*-g\)/r\1/;s/-/./g'
}

package() {
    install -Dm0644 "${srcdir}/${pkgname%-git}/drivers/udev/rules.d/99-rvlink-jtag.rules" "${pkgdir}/usr/lib/udev/rules.d/99-rvlink-jtag.rules"
}

```

-   上传至 AUR 仓库：[rv-link-udev-git](https://aur.archlinux.org/packages/rv-link-udev-git)

-   通过 AUR 工具安装 `99-rvlink-jtag.rules`

    ```bash
    yay -Syu rv-link-udev-git
    ```


## 总结 -- 填坑至始

1.   完成 Sipeed `Longan Nano` RISC-V GD32VF103CBT6
     -   `rv-link` 固件的编译
     -   `rv-link` 固件的烧录
     -   `rv-link` 驱动文件安装
2.   完成 Sipeed `RV-Debugger-BL702`
     -   `bflb-mcu-tool` 的 `python` 打包
     -   `bflb-mcu-tool` 烧录固件

3.   剩下的就是填坑之路。
