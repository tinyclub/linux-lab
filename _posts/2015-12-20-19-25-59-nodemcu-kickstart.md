---
layout: post
author: 'Wu Zhangjin'
title: "NodeMCU 物联网开发快速上手"
album: "NodeMCU 物联网开发"
group: original
permalink: /nodemcu-kickstart/
description: "NodeMCU 为一款开源 Wifi 物联网模块，本文介绍如何快速上手。"
category:
  - NodeMCU
  - 开源社区
tags:
  - Wifi
  - 物联网
  - OS X
  - Lua
  - Linux
  - Vmware
  - VirtualBox
  - Arduino
  - Noduino
  - ESP8266
  - espressif
  - esptool
  - luatool
---

> By Falcon of TinyLab.org
> 2015-12-20 19:25:59

## 简介

NodeMCU 是一款开源的物联网开发平台，其固件和开发板均开源，自带 WIFI 模块。基于该平台，用几行简单的 Lua 脚本就能开发物联网应用。

其主要特点如下：

* 像 Arduino 一样操作硬件 IO
  提供硬件的高级接口，可以将应用开发者从繁复的硬件配置、寄存器操作中解放出来。用交互式 Lua 脚本，像 Arduino 一样编写硬件代码！

* 用 Nodejs 类似语法写网络应用
  事件驱动型 API 极大的方便了用户进行网络应用开发，使用类似 Nodejs 的方式编写网络代码，并运行于 `5mm*5mm` 大小的 MCU 之上，加快您的物联网开发进度。

* 超低成本的 WIFI 模块
  用于快速原型的开发板，集成了售价低于 10 人民币 WIFI 芯片 ESP8266，为您提供性价比最高的物联网应用开发平台。

基于乐鑫 ESP8266 的 NodeMCU 开发板，具有 GPIO、PWM、I2C、1-Wire、ADC 等功能，结合 NodeMCU 固件为您的原型开发提供最快速的途径。

NodeMCU 最新版为 1.0，如下图：

<img src="/images/boards/nodemcu/nodemcu.jpg" title="NodeMCU" width="300">

其硬件详细配置如下：

* 核心模组为 ESP8266
  * MCU 为 Xtensa L106
  * RAM 50K
  * Flash 512K
* CP2102 USB 串口，即插即用（官方驱动支持 Windows, OS X 和 Linux）
* D1~D10：10 GPIO, 每个都能配置为 PWM, I2C, 1-wire
* FCC 认证的 WIFI 模块，内置 PCB 天线，可作为 AP

该平台自 2014 年问世以来，就受到广大物联网开发者喜爱。虽然该平台有上述诸多特性，但是文档方面还是有所欠缺，所以泰晓科技计划跟 NodeMCU 合作，逐步推出一系列文章，介绍该平台的开发环境搭建、SDK 使用、硬件 DIY 精品案例分享等，从而让更多的开发者快速上手和使用该平台。

作为整个系列的第一篇，咱们主要介绍各平台开发环境搭建，SDK 基本使用和简单案例展示等。

在具体展开之前，大家可以从参考资料浏览下该平台的一些基本资源，在下文基本都会介绍到。

## 购买 NodeMCU

泰晓为 NodeMCU 的国内代理，购买地址为：[泰晓开源小店](http://weidian.com/?userid=335178200)。

也可在手机端扫码进微店直接购买：

<img src="/images/weidian/tinylab-shop.jpg" title="泰晓开源小店" width="300">

如果需要周边配件，可以从 [NodeMCU 官方淘宝店](https://shop72165205.world.taobao.com/) 购买。

## 选择开发系统

NodeMCU 目前支持的开发主机系统类型涵盖 Windows，Linux 和 Mac OS X，也支持通过 VMware 虚拟机搭建的 Linux 环境。

需要提到的是，如果用虚拟机的话，请优先用 VMware 而不是 VirtualBox。虽然用 VirtualBox 也能够通过[串口虚拟化](http://www.tinylab.org/serial-port-over-internet/) 进行 Lua 开发，但是由于 VirtualBox 无法虚拟 uhci 的 cp210x，所以 VirtualBox 中的 Linux 上就无法直接烧录固件，会很不方便。

下面是我们推荐的优选开发环境：

* 纯 Linux（首推 Lubuntu）
* 在 Mac OS X 上安装 VMware，在 VMware 中运行 Linux（首推 Lubuntu）
* 在 Windows 上安装 VMware，在 VMware 中运行 Linux（首推 Lubuntu）

本文主要介绍上述三种，实际上核心还是 Linux 开发环境，后面两个只要额外安装 VMware 并在主机上也安装上 USB 串口驱动即可。

如果大家手头没有 Linux 环境，那么建议通过 VMware 来安装 Linux，这样更安全可靠，避免搞坏原来的系统。

VMware 可以从官方[下载](https://www.vmware.com/products/fusion)，安装好以后再从 Ubuntu 官方下载 [Lubuntu 14.04 ISO](http://cdimage.ubuntu.com/releases/14.04/release/)，之后启动 VMware 来安装 Lubuntu。安装时先创建/Add 一个 Lubuntu（Create a custom virtual machine -> Linux -> Ubuntu 64bit），之后通过设置/Settings 选择 Startup Disk 从 CD/DVD 启动安装，选择刚下载的 ISO，安装成功后，再通过 Startup Disk 选回从 Hard Disk(SCSI) 启动即可。

至于纯 Windows 或者纯 Mac OS X 环境，都不推荐，因为在 Linux 下，一条命令就可以安装所需的大部分工具，而在 Windows 和 Mac OS X 会浪费掉大量的时间去不同地方找不同工具，然后再花费更多倍的时间去解决各类软件编译和安装问题，事倍功半。而且 OS X 对于基本的开发环境，往往还存在收费服务，实在是不友好，珍惜生命，远离它们！

但是如果真地厚爱它们，大家还是可以通过参考后续资料，尤其是 Noduino/Noduino SDK 相关部分，很详细地介绍到了 Windows 和 Mac OS X 的开发环境，另外，参考资料中的其他软件或者工具基本都有提供 README.md 对各自的安装做了说明，请予以参考。

## 安装串口驱动

在选定开发系统后，接下来就是要安装串口驱动，打通开发主机与 NodeMCU 板子的通信，以便烧录固件、执行命令或者上传 Lua 程序。

因为 NodeMCU 1.0 采用了 cp2102 USB 串口，其驱动完美支持 Windows，Linux，OS X 和 VMWare，所以各个平台下载 [CP210x](http://www.silabs.com/products/mcu/Pages/USBtoUARTBridgeVCPDrivers.aspx) 安装上即可。

对于 VMware + Linux，除了在开发主机上安装好串口驱动外，需要在插入 USB 串口以后，根据提示，允许 VMware 控制该 USB 串口，也可以通过设置/Settings 的 `USB & Bluetooth` 来进行设置。

安装好再确认下串口驱动是否正常加载：

    $ dmesg
    [13784.667753] usb 2-2.2: new full-speed USB device number 8 using uhci_hcd
    [13784.775474] usb 2-2.2: New USB device found, idVendor=10c4, idProduct=ea60
    [13784.775477] usb 2-2.2: New USB device strings: Mfr=1, Product=2, SerialNumber=3
    [13784.775479] usb 2-2.2: Product: CP2102 USB to UART Bridge Controller
    [13784.775481] usb 2-2.2: Manufacturer: Silicon Labs
    [13784.775482] usb 2-2.2: SerialNumber: 0001
    [13784.935711] cp210x 2-2.2:1.0: cp210x converter detected
    [13785.019977] usb 2-2.2: reset full-speed USB device number 8 using uhci_hcd
    [13785.225496] usb 2-2.2: cp210x converter now attached to ttyUSB0

    $ ls -l /dev/ttyUSB0
    crw-rw---- 1 root dialout 188, 0 12月 21 21:55 /dev/ttyUSB0

接着需要安装一个串口通信工具，在 Linux 下推荐 minicom。

    $ sudo apt-get install minicom

使用 minicom 之前，需要明确 NodeMCU 1.0 的串口属性。

NodeMCU 1.0 的启动时波特率为 74880，但是启动后就切到了 9600，如果直接用 9600，则开头会看到一串乱码之后恢复正常。而刷固件时可以通过 esptool 自己设置波特率，NodeMCU 1.0 那边会根据用户设置自动配置波特率，比如说设置成 115200，921600 都可以。

串口设备在不同系统下名字有些差异，在 Linux 下为 `/dev/ttyUSBn`，在 Mac OS X 下为 `/dev/cu.SLAB_USBtoUART` 和 `/dev/tty.SLAB_USBtoUART`，Windows 下为 `COMn`。

其他配置为常见的：`8N1`，即 Bits：8；Parity：None；Stop Bits：1。另外，Hardware Flow Control 和 Software Flow Control 均为 No。

## 下载并烧录最新固件

从 [NodeMCU Firmware Release](https://github.com/nodemcu/nodemcu-firmware/releases/) 下载最新固件，以 float 为例（注：integer 不支持 float，但节省了 11 KB）：

    $ wget -c https://github.com/nodemcu/nodemcu-firmware/releases/download/0.9.6-dev_20150704/nodemcu_float_0.9.6-dev_20150704.bin

接着咱们把烧录工具 esptool.py 下载下来。同时安装其他必要工具。

    $ sudo apt-get install git python python-serial python-setuptools
    $ git clone https://github.com/themadinventor/esptool.git
    $ cd esptool
    $ python setup.py install

在烧录固件之前需要通过如下操作进入 NodeMCU 的固件烧录模式：

* 按住 FLASH 按键（这里不松开）
* 按下 RST 按键并松开
* 松开 FLASH 按键

接着通过 esptool.py 烧录固件：

    $ sudo esptool.py --port /dev/ttyUSB0 write_flash -fm dio -fs 32m -ff 40m 0x00000 nodemcu_float_0.9.6-dev_20150704.bin

烧录完以后记得按下 RST 重启进入新固件。

esptool.py 烧写时默认的通信波特率为 115200，为了加速烧写速度，可以通过 `--baud 921600` 设置为 921600。

需要提到的是，如果不想保留固件中原有的各类 Lua 程序，可以在启动后格式化文件系统（`file.format()`，见后文），也可以在烧录前刷掉整个固件：

    $ sudo esptool.py --port /dev/ttyUSB0 erase_flash

当文件系统被破坏或者某个 Lua 程序出错以后导致系统不断重启时，擦除整个 Flash 几乎是必要的（实际也可以擦除文件系统所在的区块或者重写该区块），当然，还有一些另类的办法，后面会补充。

## 基本操作演示

烧录完以后按下 RST 按钮重启 NodeMCU，再启动 minicom 就可以进入 Lua 交互式命令行：

    $ minicom -D /dev/ttyUSB0

    > print('Hello, NodeMCU 1.0')
    Hello, NodeMCU 1.0

    > gpio.mode(0, gpio.OUTPUT)
    > gpio.write(0, gpio.LOW)
    > gpio.write(0, gpio.HIGH)

    > file.format()

    > node.restart()

上面几条命令分别完成：

* 打印了一串字符串
* 开/关了靠近 USB 口的 LED（靠近 Wifi 模块的 LED 的 pin 为 4）
* 格式化文件系统
* 最后重启了 NodeMCU

如果嫌不够酷，可以参考 [NodeMCU API 手册](http://nodemcu.github.io) 可以做更多有趣的操作。

接下来，创建一个初始化程序：`init.lua`，它在 NodeMCU 启动后自动执行。

咱们通过该程序在 NodeMCU 启动后立即点亮 LED：

    > file.open('init.lua','w')
    > file.writeline('gpio.mode(0,gpio.OUTPUT)')
    > file.writeline('gpio.write(0,gpio.LOW)')
    > file.close()
    > node.restart()

`init.lua` 是 NodeMCU 启动时默认执行的第一个程序，有点类似 Linux 上的 init 程序。通过它还可以加载其他程序来完成特定的功能。

咱们再做一个复杂一点的操作，在 `init.lua` 里头调用（dofile）一个 `user.lua` 来点亮 LED：

    > file.open('init.lua','w')
    > file.writeline('dofile("user.lua")')
    > file.close()
    > file.open('user.lua','w')
    > file.writeline('gpio.mode(0,gpio.OUTPUT)')
    > file.writeline('gpio.write(0,gpio.LOW)')
    > file.close()
    > node.restart()

读出 `init.lua` 看下效果：

    > file.open('init.lua','r')
    > print(file.readline())
    dofile("user.lua")

    > file.close()

当 `user.lua` 脚本出错时可能导致系统不停地重启，这个时候除了擦除整个 Flash 外，还可以通过 `init.lua` 做个简单的容错处理：

    if gpio.read(2) == 1:
        file.format()
    else
        dofile('user.lua')
    end

一旦系统出错，只要拉低 GPIO 2 就可以格式化文件系统。

暂时先到这里吧，后面会逐步介绍更多实例。

## 上传 Lua 程序

上面演示的是命令行操作，这里再介绍如何把在主机端写好的 Lua 程序上传到 NodeMCU 上。

测试过两个工具都可以用来上传 Lua 程序，分别是：

* [luatool.py](https://github.com/4refr0nt/luatool.git)：可用于命令行传送 Lua 脚本，无须复杂的图形化工具支持，同时支持通过串口和 Telnet 上传
* [nodemcu.py](https://github.com/md5crypt/nodemcu.py.git)：同上

下载上述工具：

    $ git clone https://github.com/4refr0nt/luatool.git
    $ git clone https://github.com/md5crypt/nodemcu.py.git

两个都可以进行文件传输，第二个还可以作为串口终端，两个都依赖 pySerial，第二个还需要安装 clipboard：

    $ easy_install clipboard

在上传前咱们写一个简单的 `init.lua` 脚本，该脚本用于点亮另外一个 LED：

    print('Hello, NodeMCU 1.0')

    gpio.mode(4, gpio.OUTPUT)
    gpio.write(4, gpio.LOW)

### luatool.py

通过 `luatool.py` 传送，传送完立马重启：

    $ cd luatool/luatool/
    $ sudo ./luatool.py -p /dev/ttyUSB0 -b 9600 -f init.lua -r

查看帮助，可以看到更多用法：

    $ sudo ./luatool.py -h
    Usage: luatool.py [-h] [-p PORT] [-b BAUD] [-f SRC] [-t DEST] [-c] [-r] [-d]
                      [-v] [-a] [-l] [-w] [-i] [--delete DELETE] [--ip IP]

    ESP8266 Lua script uploader.

    optional arguments:
      -h, --help            show this help message and exit
      -p PORT, --port PORT  Device name, default /dev/ttyUSB0
      -b BAUD, --baud BAUD  Baudrate, default 9600
      -f SRC, --src SRC     Source file on computer, default main.lua
      -t DEST, --dest DEST  Destination file on MCU, default to source file name
      -c, --compile         Compile lua to lc after upload
      -r, --restart         Restart MCU after upload
      -d, --dofile          Run the Lua script after upload
      -v, --verbose         Show progress messages.
      -a, --append          Append source file to destination file.
      -l, --list            List files on device
      -w, --wipe            Delete all lua/lc files on device.
      -i, --id              Query the modules chip id.
      --delete DELETE       Delete a lua/lc file from device.
      --ip IP               Connect to a telnet server on the device (--ip
                            IP[:port])

### nodemcu.py

通过 `nodemcu.py` 上传：

    $ cd nodemcu.py/
    $ python ./nodemcu.py /dev/ttyUSB0 9600
    > :file init.lua init.lua
    > node.restart()

查看帮助，更多用法：

    > :help
    :help
    :uart [boudrate]          - dynamic boudrate change
    :load src                 - evaluate file content
    :file dst src             - write local file src to dst
    :paste [file]             - evaluate clipboard content
                                or write it to file if given
    :cross-compile dst [file] - compile file or clipboard using
                                luac-cross and save to dst
    :execute [file]           - cross-compile and execute clipboard or
                                file content without saving to flash
    :soft-compile dst [file]  - compile file or clipboard on device
                                and save do dst. This call should handle
                                lager files than file.compile

## Lua 程序示例

这里仅仅展示几则基本的 Lua 程序，方便大家快速上手。更多例子请参考 NodeMCU Firmware 下的 Lua examples：

* [lua_examples](https://github.com/nodemcu/nodemcu-firmware/tree/master/lua_examples)
* [examples](https://github.com/nodemcu/nodemcu-firmware/tree/master/examples)

也可以在后面下载的 nodemcu-firmware/examples，nodemcu-firmware/lua_examples 找到这些例子：

### 启动后不断闪烁 LED

上面其实已经演示了 LED 的基本操作，这里再介绍一个 timer module 的 API：tmr.alarm()：

> tmr.alarm(id, interval, repeat, function do())
>
> id: 0~6, alarmer id. Interval: alarm time, unit: millisecond
> repeat: 0 - one time alarm, 1 - repeat
> function do(): callback function for alarm timed out

咱们基于它实现一个 `blink.lua`:

    print('Blink Demo')

    lighton=0
    led=0

    gpio.write(led, gpio.HIGH)

    tmr.alarm(0,1000,1,function()
    if lighton==0 then
        lighton=1
        gpio.mode(led, gpio.OUTPUT)
        gpio.write(led, gpio.LOW)
    else
        lighton=0
        gpio.write(led, gpio.HIGH)
    end
    end)

    gpio.mode(led, gpio.INPUT)

上传 `blink.lua` 并立即执行：

    $ sudo ./luatool.py -p /dev/ttyUSB0 -b 9600 -f blink.lua -d

### 远程控制 LED 闪烁

对于物联网来讲，远程控制很关键。咱们这里演示如何通过 Wifi 开启一个服务端口 8888 用于控制 LED，`remote_led.lua`：

    -- 开启 Wifi 并获得 NodeMCU IP 地址
    -- ssid 和 pwd 分别为自家路由器的 SSID 和访问密码
    local ssid="SSID"
    local pwd="password"

    ip=wifi.sta.getip()
    print(ip)

    if not ip then
        wifi.setmode(wifi.STATION)
        wifi.sta.config(ssid,pwd)
        print(wifi.sta.getip())
    end

    -- 开启一个 8888 的端口
    -- 并通过 node.input() 调用 Lua 解释器控制 LED
    srv=net.createServer(net.TCP)
    srv:listen(8888,function(conn)
        conn:on("receive",function(conn,payload)
        node.input("gpio.mode(0, gpio.OUTPUT)")
        node.input("gpio.write(0, gpio.LOW)")
        end)
    end)

上传 Lua 程序到服务器执行：

    $ sudo ./luatool.py -p /dev/ttyUSB0 -b 9600 -f remote_led.lua -d

查看 NodeMCU 获取的 IP 地址：

    $ sudo minicom -D /dev/ttyUSB0
    > print(wifi.sta.getip())
    192.168.0.104	255.255.255.0	192.168.0.1

并测试：

    $ sudo apt-get install lynx
    $ lynx 192.168.0.104:8888

### 开启一个 Telnet 服务

先从 NodeMCU.com 下载该例子，`telnetd.lua`：

    -- a simple telnet server
    s=net.createServer(net.TCP,180)
    s:listen(2323,function(c)
        function s_output(str)
          if(c~=nil)
            then c:send(str)
          end
        end
        node.output(s_output, 0)
        -- re-direct output to function s_ouput.
        c:on("receive",function(c,l)
          node.input(l)
          --like pcall(loadstring(l)), support multiple separate lines
        end)
        c:on("disconnection",function(c)
          node.output(nil)
          --unregist redirect output function, output goes to serial
        end)
        print("Welcome to NodeMCU world.")
    end)

上传并执行：

    $ sudo ./luatool.py -p /dev/ttyUSB1 -b 9600 -f telnetd.lua -d

通过 telnet 连接：

    $ sudo apt-get install telnet
    $ telnet 192.168.0.104 2323
    Trying 192.168.0.104...
    Connected to 192.168.0.104.
    Escape character is '^]'.
    Welcome to NodeMCU world.

    > print('Hello, NodeMCU Telnet')
    Hello, NodeMCU Telnet
    >

有了 telnet 服务，咱就可以不依赖串口而是直接通过 Wifi 上传 Lua 脚本了：

    $ cat test.lua
    print('Upload via telnet service')
    $ sudo ./luatool.py --ip 192.168.0.104:2323 -f test.lua -d -v

## 下载编译工具链

社区已经有编译好的工具链并有同学已经打包到 github，下载、安装和配置如下：

    $ git clone https://github.com/icamgo/xtensa-toolchain.git
    $ cd xtensa-toolchain && ./gen.py
    $ echo "export PATH=$PWD/xtensa-lx106-elf/bin:$PWD/bin:\$PATH" >> ~/.bashrc
    $ . ~/.bashrc

之后就可以使用 `xtensa-lx106-elf-gcc` 编译器了。

## 编译 NodeMCU Firmware

### 采用泰晓科技的仓库

NodeMCU 的官方仓库，在使用预编译的 Xtensa 工具链编译时有很多问题，泰晓科技进行了一一修复，可直接编译和烧录：

    $ git clone https://github.com/tinyclub/nodemcu-firmware.git
    $ make -j5
    $ sudo make flash

如果串口地址不是默认的 `/dev/ttyUSB0`，那么可以这样配置：

    $ sudo COMPORT=/dev/ttyUSB1 make flash

### 编译 NodeMCU 官方源

如果一定要用官方源，详细步骤如下：

在编译 NodeMCU Firmware 时需要额外下载一个 xtensa 头文件目录以及一个 libhal 库，否则编译时会出现如下错误：

> fatal error: xtensa/corebits.h: No such file or directory
>
> xtensa-toolchain/xtensa-lx106-elf/bin/../lib/gcc/xtensa-lx106-elf/4.8.2/../../../../xtensa-lx106-elf/bin/ld: cannot find -lhal
collect2: error: ld returned 1 exit status

可以依次下载 NodeMCU Firmware，ESP8266_RTOS_SDK（含 xtensa 头文件）以及 libhal.a：

    $ git clone https://github.com/nodemcu/nodemcu-firmware.git
    $ git clone https://github.com/espressif/ESP8266_RTOS_SDK.git
    $ wget -c https://github.com/esp8266/esp8266-wiki/raw/master/libs/libhal.a

然后把这些头文件和库放到正确的位置：

    $ cp -r ESP8266_RTOS_SDK/extra_include/xtensa/ nodemcu-firmware/app/user/
    $ cp libhal.a nodemcu-firmware/sdk/esp_iot_sdk_v1.4.0/lib/libhal.a

编译：

    $ cd nodemcu-firmware/
    $ make

之后是烧录，但是默认烧录（make flash）后无法正常启动，需要命令行中额外传递 `-fm dio -fs 32m -ff 40m` 参数：

    $ sudo esptool.py --port /dev/ttyUSB0 write_flash -fm dio -fs 32m -ff 40m 0x00000 ./bin/0x00000.bin 0x10000 ./bin/0x10000.bin

执行上述命令前记得依次：按下 FLASH，按下 RST，松开 RST，松开 FLASH，以便进入烧录模式。

### 制作单一文件的固件

NodeMCU [发布](https://github.com/nodemcu/nodemcu-firmware/releases/)时是单一文件的固件，这个是怎么制作的呢？

实际上它是通过 `.travis.yml` 配置在线编译服务：<http://www.travis-ci.org/> 实现的，该服务可以作为 github 的插件配置并把编译好的内容发布回 github。

在 `.travis.yml` 文件中，可以看到 `srec_cat` 命令，这个就是用来打包的：

    $ cat .travis.yml | grep srec_cat
    - srec_cat -output ${file_name_float} -binary 0x00000.bin -binary -fill 0xff 0x00000 0x10000 0x10000.bin -binary -offset 0x10000
    - srec_cat -output ${file_name_integer} -binary 0x00000.bin -binary -fill 0xff 0x00000 0x10000 0x10000.bin -binary -offset 0x10000

上述两条命令分别是用来打包支持 float 和仅支持 integer 的固件包，咱们可以自己用上述命令制作一个：

    $ sudo apt-get install srecord
    $ cd bin
    $ srec_cat -output nodemcu_firmware.bin -binary 0x00000.bin -binary -fill 0xff 0x00000 0x10000 0x10000.bin -binary -offset 0x10000

编译完的 nodemcu_firmware.bin 就跟从 NodeMCU 官方下载的一样可以直接一条命令烧录：

    $ sudo esptool.py --port /dev/ttyUSB0 write_flash -fm dio -fs 32m -ff 40m 0x00000 nodemcu_firmware.bin

### 精细配置

为了更精细地控制 NodeMCU 固件的大小，可以配置是否支持浮点，也可以配置所需的模块。

上面看到有 float 和 integer 之分：

    $ cat .travis.yml | grep EXTRA_
    - make EXTRA_CCFLAGS="-DBUILD_DATE='\"'$BUILD_DATE'\"'" all
    - make EXTRA_CCFLAGS="-DLUA_NUMBER_INTEGRAL -DBUILD_DATE='\"'$BUILD_DATE'\"'"

要编译成仅支持 integer 可以在编译时定义宏 `LUA_NUMBER_INTEGRAL` 或者在 `app/include/user_config.h` 打开如下定义：

    #define LUA_NUMBER_INTEGRAL

上面默认是没定义的，即默认编译出来是支持 float 的，但是 integer 比 float 的固件小 11k 左右，可以节省一些空间来存放用户的 Lua 程序。

另外，通过 `app/include/user_modules.h` 可以仅仅打开所需的模块，例如要去掉 MQTT：

    // #define LUA_USE_MODULES_MQTT

### 在线编译

如果不想搭建编译环境，也可以在线编译。

* <https://travis-ci.org/>
  如果需要修改代码，可以用该方案。只需要把修改提交到自己的 github 仓库，并通过 github 配置好 `.travis.yml` 即可。

* <http://nodemcu-build.com>
  该方案适合直接采用 NodeMCU 源，并且不做修改的情况，它提供了 Web 界面可以简单方便地选择所需模块。

## 制作 Xtensa 交叉编译器

虽然有现成的工具链可用，但是如果还是想浪费时间从头编译一套也无妨。

社区有开发一套 esp-open-sdk，集成了 crosstool-NG, gcc-xtensa, newlib-xtensa 和 lx106-hal 等工具，借助它可以自助编译一套 Xtensa 工具链。

下载后的 README.md 针对各平台有较详细的说明，咱们只介绍 Ubuntu 14.04 下如何编译。由于编译过程需要下载大量软件包，编译过程会相当慢，需要有足够耐心。

    $ sudo apt-get install make unrar autoconf automake libtool gcc g++ gperf flex bison texinfo gawk ncurses-dev libexpat-dev python python-serial sed git
    $ git clone https://github.com/pfalcon/esp-open-sdk.git
    $ cd esp-open-sdk
    $ make

同样配置好 PATH 环境变量后就可使用：

    $ echo "export PATH=$PWD/xtensa-lx106-elf/bin:$PWD/esptool/:\$PATH" >> ~/.bashrc
    $ . ~/.bashrc

## 使用 Noduino SDK

前面所有的内容都在介绍 NodeMCU 官方的 Lua SDK，其实 ESP8266 官方也有提供 SDK，第三方也有提供，这里再介绍一个基于 ESP8266 官方但是做了更好封装的 Noduino SDK：

下载 Noduino SDK：

    $ git clone git://github.com/icamgo/noduino-sdk.git

下载工具链（包括 esptool 和 xtensa-toolchain）和 ESP8266 官方的 RTOS SDK：

    $ cd noduino-sdk
    $ git submodule init
    Submodule 'rtos/esp32' (git://github.com/espressif/esp32_rtos_sdk.git) registered for path 'rtos/esp32'
    Submodule 'rtos/esp8266' (git://github.com/espressif/esp8266_rtos_sdk.git) registered for path 'rtos/esp8266'
    Submodule 'toolchain' (git://github.com/icamgo/xtensa-toolchain.git) registered for path 'toolchain'
    $ git submodule update
    $ cd toolchain
    $ ./gen.py

实例演示：

    $ cd ../example/blink/
    $ make && make flash

## 使用 Arduino IDE

Noduino 封装为了 Arduino IDE 可用的简易包，不同于可独立使用的 Noduino SDK，该包需要集成进 Arduino IDE 使用，这个对于习惯 Arduino 或者喜欢 IDE 环境的同学是福音。

先从 arduino.cc 下载并安装 Arduino IDE，安装后进入：

    $ cd /PATH/TO/arduino
    $ cd hardware
    $ mkdir esp8266com
    $ cd esp8266com
    $ git clone git://github.com/icamgo/Noduino.git esp8266

    # fetch the toolchain of esp8266
    $ cd esp8266
    $ git submodule init
    $ git submodule update
    $ cd tools/xtensa-toolchain
    $ ./gen.py

之后启动或者重启 Arduino，在菜单 Tools 里头选择 Board 为 NodeMCU 1.0，并确认串口正确，默认为 `/dev/ttyUSB0`，比如说 `/dev/ttyUSB1`。

接着通过菜单 File 中的 Examples 找到 esp8266 的 Blink。

最后，按下 Arduino IDE 的“上传”按钮编译和烧录 Blink 到板子上，效果跟上面的 Lua 例子一样，会闪烁 LED 。

## 参考资料

* ESP8266 资源
  * [ESP8266 介绍](http://wiki.jackslab.org/ESP8266)：ESP8266 为其核心模块

* NodeMCU 资源
  * [网站](http://www.nodemcu.com)
  * [论坛](http://bbs.nodemcu.com/)
  * [源码仓库](https://github.com/nodemcu)
    * [硬件设计 1.0](https://github.com/nodemcu/nodemcu-devkit-v1.0)
    * [硬件设计 0.9](https://github.com/nodemcu/nodemcu-devkit)
    * [软件源码](https://github.com/nodemcu/nodemcu-firmware)
  * [最新固件下载](https://github.com/nodemcu/nodemcu-firmware/releases/)
  * [API 手册](http://nodemcu.github.io/)

* Noduino/Noduino SDK 文档
  * Nodunio：集成进 Arduino IDE
    * [Getting Started with Noduino on Windows](http://wiki.jackslab.org/Getting_Started_with_Noduino_on_Windows)
    * [Getting Started with Noduino on Linux](http://wiki.jackslab.org/Getting_Started_with_Noduino_on_Linux)
    * [Getting Started with Noduino on Mac OS X](http://wiki.jackslab.org/Getting_Started_with_Noduino_on_Mac_OS_X)
  * Noduino SDK：独立 SDK，自带编译工具
    * [Getting Started with Noduino SDK on Windows](http://wiki.jackslab.org/Getting_Started_with_Noduino_SDK_on_Windows)
    * [Getting Started with Noduino SDK on Linux](http://wiki.jackslab.org/Getting_Started_with_Noduino_SDK_on_Linux)
    * [Getting Started with Noduino SDK on Mac OS X](http://wiki.jackslab.org/Getting_Started_with_Noduino_SDK_on_Mac_OS_X)

* 其他资源
  * 语言
    * C
    * [eLua](http://www.eluaproject.net/)：NodeMCU Firmware 默认支持 eLua
    * [MicroPython](https://learn.adafruit.com/building-and-running-micropython-on-the-esp8266/flash-firmware)
  * SDK
    * [NodeMCU Firmware](https://github.com/nodemcu/nodemcu-firmware)：NodeMCU 官方提供的固件，支持 Lua 编程
    * [Nodunio](http://www.noduino.org)：NodeMCU 合作伙伴提供的纯 C SDK，可集成进 Arduino IDE
    * [ESP8266 SDK](https://github.com/espressif)：ESP8266 官方厂商提供的 SDK，其他都基于这个但是在这个基础上做了封装，更便于使用
  * IDE
    * [Arduino IDE](https://www.arduino.cc/en/Main/Software)：支持 Windows，Linux 和 OS X
  * 文件系统
    * [spiffs](https://github.com/pellepl/spiffs)
    * [mkspiffs](https://github.com/igrr/mkspiffs)
  * 编译器
    * [xtensa-lx106-elf-gcc](https://github.com/icamgo/xtensa-toolchain)：预先编译好的 Xtensa 交叉编译器，支持多个平台
    * [esp-open-sdk](https://github.com/pfalcon/esp-open-sdk)：集成了 crosstool-NG 的编译器制作环境
  * USB 串口驱动
    * [CP210x](http://www.silabs.com/products/mcu/Pages/USBtoUARTBridgeVCPDrivers.aspx)：支持 Windows，Linux，OS X 和 VMWare
    * [串口虚拟化](http://www.tinylab.org/serial-port-over-internet/)：允许在 VirtualBox 中通过虚拟串口上传 Lua 脚本
  * 固件烧录
    * [NodeMCU Flasher](https://github.com/nodemcu/nodemcu-flasher)：NodeMCU 官方采用 .net 编写的图形下载界面，支持 Windows
    * [esptool.py](https://github.com/themadinventor/esptool.git)：Python 版本，推荐在 OS X 和 Linux 环境下使用，可用于命令行烧写固件
    * [esptool](https://github.com/igrr/esptool-ck/)：C 语言版，编译好的版本在 [Release](https://github.com/igrr/esptool-ck/releases/)
    * [ESPlorer](https://github.com/4refr0nt/ESPlorer.git)：JAVA 写的，支持 Windows，Linux，Solaris 和 Mac OS X，来自 luatool 的作者
  * 文件传送
    * [luatool.py](https://github.com/4refr0nt/luatool.git)：可用于命令行传送 Lua 脚本，无须图形化工具支持
    * [nodemcu.py](https://github.com/md5crypt/nodemcu.py.git)：同上
  * 云服务
    * [YeeLink](http://www.yeelink.net/)
      * [接入案例](http://bbs.nodemcu.com/t/nodemcu/104)
