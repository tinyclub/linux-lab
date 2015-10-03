---
title: '社区版龙芯 Linux'
tagline: '社区维护，支持龙芯 2F 系列，已进入官方 Linux'
author: Wu Zhangjin
layout: page
permalink: /linux-loongson-community/
description: 用于维护龙芯 2F 系列机型的 Linux 支持。
update: 2015-10-1
categories:
  - 开源项目
  - 开源社区
tags:
  - 龙芯
  - Linux
  - 社区版
---

The Linux Kernel For Loongson Maintained by Community.

因该项目的原主页已无法访问，这里将作为社区版龙芯 Linux 的临时主页。

## Introduction (项目简介)

This project is launched to maintain the latest [Linux][1] for [Loongson][2], the objective is making the loongson machines be friendly supported.

Linux-Loongson-Community here means it is a community project and welcome contribution from everybody.

### The mainline Linux kernel (maintained by Linus)

  * This project mainly focus on MIPS (exactly, Loongson), but the mainline linux focus on lots of architectures (X86, PowerPC, MIPS, ARM, Sh, Sparc&#8230;).
  * Most of the stable patchset in this project will be pushed into [linux-MIPS][3] firstly and at last go into the mainline linux.
  * So, if you need the newest or the full loongson specific support, please come here.

###  maintained by Lemote

  * This project is developed & maintained by the people from community and therefore can get/apply more support from the community, such as bug report, bug fixes and so forth.
  * This project try to update with the mainline linux as soon as possible and try to upstream the stable patchsets in this project to the mainline, then people can get the mostly stable support from mainline.
  * Most of the basic BSP in this project is originally contributed by Lemote and some latest patchsets from the Lemote will also be applied into this project.

So, this project will function as a bridge between the Loongson companies and the upstream communities.

## Mailing list (邮件列表)

  * loongson-dev [AT] googlegroups [DOT] com

## Maintainers (维护人员)

  * Current maintainer
    
      * Alexandre Oliva `<lxoliva [AT] fsfla [DOT] org>`

  * Old maintainers
    
      * Zhang Le `<r0bertz [AT] gentoo [DOT] org>`
      * Wu Zhangjin `<wuzhangjin [AT] gmail [DOT] com>`

## Source (内核源代码)

### Git repository (Git仓库)

  * Git repo of this project
    
      * [git://dev.lemote.com/linux-loongson-community.git][4] (git protocol, for anonymous)
      * ssh://dev.lemote.com/linux-loongson-community.git (ssh protocol, for maintainers)
      * <https://github.com/tinyclub/linux-loongson-community.git> (github backup)

  * Related git repo
    
      * [git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git][5] (mainline linux, maintained by Linus)
      * [git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git][6] (stable linux)
      * [git://git.linux-mips.org/pub/scm/ralf/linux.git][7] (linux-mips)
      * git://git.linux-mips.org/pub/scm/ralf/upstream-linus.git (linux-mips upstream for Linus)

### Download (下载)

Download methods:

  * [Browser source code][4], download them via the Tags or Branch commits.

  * Clone, pull or fetch one branch of the git repository (use `master` branch as an example)
    
        $ git clone git://dev.lemote.com/linux-loongson-community.git -b master
        

## Supported Machines (支持的机器型号)

  * Lemote FuLoong-2E Box
  * Lemote Loongson-2F family of machines
    
      * FuLoong-2F Box
      * YeeLoong netbook(8.9, 10) 
      * U-NAS, HiLoong
      * All-in-one PC
      * MengLoong netbook

  * DEXXON Gdium netbook
    
      * Basic support has been provided by this project! Almost works except sound, PM (2010-11-20)
      * To get full support, you may need to get the kernel from git://git.opensde.net/users/amery/linux-2.6.29-gdium or http://repo.or.cz/w/linux-2.6/linux-mips/linux-gdium.git

## Compile (内核编译)

### Config (配置)

  * default config files
    
      * FuLoong-2E Box: arch/mips/configs/fuloong2e_defconfig
      * Lemote 2F family of machines: arch/mips/configs/lemote2f_*defconfig
      * Dexxon Gdium netbook: arch/mips/configs/gdium_*defconfig

  * Config Options
    
      * CONFIG\_LEMOTE\_YEELOONG2F: YeeLoong platform specific drivers (backlight, suspend, battery, sensors, hotkey/input&#8230;)
      * CONFIG\_LEMOTE\_LYNLOONG2F: LynLoong platform specific drivers (backlight, suspend drivers)
      * CONFIG\_LOONGSON2\_CPUFREQ: Loongson-2F cpu frequency scaling driver(The conservative governor is Preferred)
      * CONFIG\_CS5536\_MFGPT: external CS5536 MFGPT Timer (used in Lemote 2F family of machines, before 2.6.37)
      * CONFIG\_R4K\_TIMER\_FOR\_CPUFREQ: R4K Timer enhancement for CPUFreq (From 2.6.37)
      * CONFIG\_FB\_SM7XX: SM712 Video Card Driver used in YeeLoong netbook
      * CONFIG_RTL8187B: RTL8187B Wifi Driver used in YeeLoong netbook
      * CONFIG\_LOONGSON\_SUSPEND, CONFIG_SUSPEND: Suspend support of Lemote-2F machines
      * CONFIG\_HIBERNATION, CONFIG\_PM\_STD\_PARTITION=&#8221;/dev/hda3&#8243;, Hibernation support, /dev/hda3 is the swap partition of your machine, you can pass &#8220;resume=/dev/hdaX&#8221; or &#8220;resume=/dev/sdaX&#8221; to override it.

### Local-Compile (本地编译)

Please make sure your compiler support: `-mfix-loongson2f-nop` and `-mfix-loongson2f-jump` at first, then compile it as following:

<pre>$ make menuconfig
$ make -j2
$ make modules_install
$ make install
</pre>

### Cross-Compile (交叉编译)

  * Exisiting cross-compiler
    
    Please download one from <http://dev.lemote.com/files/resource/toolchain/cross-compile>, decompress it and configure the PATH and LIBRARY_PATH environment in /etc/profile or .bashrc.

  * Build Cross-Compiler for Loongson from scratch
    
      * [English Doc 32bit][8]
      * [English Doc 64bit][9]
      * [English Doc Multilb 64bit][10]
      * [Chinese Doc][11]

  * Compile
    
        $ make menuconfig ARCH=mips
        $ make CROSS_COMPILE=<prefix>- ARCH=mips -j<N>
        $ make modules_install INSTALL_MOD_PATH=/path/to/modules_install_directory
        $ make install INSTALL_PATH=/path/to/kernel_image_install_directory
        

### Boot (引导)

  * Dexxon Gdium Netbook
    
    You must set the al and karg variables of PMON to boot the kernel, al is used to indicate the path to the kernel image, karg is used to pass the kernel command line parameters.
    
    After power on the netbook, enter into the PMON command line via pressing `c` or `<DEL>`, then, you can get help via the `h *` command, please get details from the [PMON user manual][12].

  * For the other machines
    
    Except the above method, you can also edit the config file(/boot/boot.cfg) of PMON, here is an example:
    
        # /boot/boot.cfg
        default 0
        showmenu 1
        
        title Fedora MIPS/N32
                kernel (wd0,1)/boot/vmlinuz-2.6.31-0.167.rc5.fc11.mips64el
                args console=tty root=/dev/sda2
        
    
    The above configuration means:
    
      * `default 0` means if there are lots of config entries in the boot.cfg, the default entry is the first one. 
      * `showmenu 1` menas the menu will be shown.
      * `title` indicates the Title of the entry shown in the menu, here is &#8220;Fedora MIPS/N32&#8243;. 
      * `kernel` indicates the path to the kernel image file, (wd0, 1) here indicates the /dev/sda2, so, it means vmlinuz-2.6.31-0.167.rc5.fc11.mips64el is stored in the /dev/sda2 partition and put into the /boot directory. If you have stored the kernel image in /dev/sda4, please use (wd0,3) instead. 
      * `args` indicates the kernel command line arguments. root=/dev/sda2 means the partition stored the root file system is /dev/sda2.
    
    Please get more information from the \[PMON manual\](http://dev.lemote.com/files/document/pmon/PMON%E6%89%8B%E5%86%8Cv0.1.pdf PMON).

## BIOS & Bootloader (BIOS和引导器)

### PMON

PMON is the current BIOS & Bootloader pre-installed on the loongson family of machines.

### Grub

[Grub][13] itself is only a bootloader, which has been ported to YeeLoong for the Gnewsense project. but perhaps you can make it work in the other distributions.

[Grub 1.98][14] is available for YeeLoong, but currently, it can only be loaded from PMON.

### Linux + Kexec

Kexec support(Only 32bit currently) is added for Loongson in the tiny36 branch of this project, with the kernel support and the user-space [kexec-tools][15], we can load another kernel image, then, Linux itself work as a bootloader.

To use it, please read the [Linux for Loongson is ready as bootloader][16] thread in the linux-dev google group.

## GNU/Linux distribution (龙芯Linux发行版)

### Rescue & Recovery system (急救与还原系统)

Rescue system is always needed when you have broken the whole system, you can load it via tftp protocol or from a u-disk to get a basic system.

  * [Rescue for YeeLoong][17] 
  * [Rescue for FuLoong][18] 

Recovery system(support all of Loongson-2F machines made by Lemote) will help to format your broken system and re-install a basic system there (be careful!).

### Gnewsense (Recommend)

Gnewsense is a 100% free/libre GNU/Linux distribution developed by FSF. Installation guide is available here: <http://wiki.gnewsense.org/Projects/GNewSenseToMIPS>

### Debian 6.0 (Recommend)

This Debian 6.0 is not that one from the official debian, but improved from it, which is developed by [Liu Shiwei][19].

Why this one? it is newer and better than the one from Lemote and also from the official debian, which provides feature-rich kernel, accelerated video driver&#8230;

Please get it here: http://www.anheng.com.cn/loongson/install/, download the latest compressed system, decompress it to one of the partitions and config /boot/boot.cfg then boot it.

To install debian on your Gdium, please refer to http://vm-kernel.org/blog/2009/03/20/how-to-install-debian-lenny-on-gdium/

Change the default language to your preferable one:

    $ dpkg-reconfigure locales
    

## Doc (开发文档)

### Loongson Developers Manual (龙芯开发者手册)

  * From Lemote
    
      * [The porting & development manual of Linux for Loongson, Chinese][20]
      * [PMON development manual][12] 

### Git Documentation (Git使用文档)

  * [Git User Manual][21]

### Loongson User Manual (龙芯处理器用户手册)

  * Loongson-2E Manual
    
      * [Chinese][22]
      * [English][23]

  * Loongson-2F Manual
    
      * [Chinese][24]
      * [English][25]

  * Loongson-2 built-in Northbridge Manual
    
      * [Chinese][26]
      * [English Version(Bonito64 Specification)][27] 

### CS5536 Datasheet (南桥cs5536规格书)

  * [AMD GeodeTM CS5536 Companion Device Data Book][28]

## TODO (待做工作)

### Linux-Mainline

<http://kernelnewbies.org/KernelProjects>

### Linux-MIPS

<http://www.linux-mips.org/wiki/Todo_List>

More:

  * Maintain the Hibernation support for MIPS
    
      * arch/mips/power/

  * Maintain the Ftrace support for MIPS
    
      * arch/mips/kernel/{ftrace.c, mcount.S}
      * The latest development status: Add SMP support: http://patchwork.linux-mips.org/patch/1552/

  * Maintain the Compressed-kernel support for MIPS
    
      * arch/mips/boot/compressed/
      * Add the checksum support to ensure the compressed kernel is not broken, add the checksum of the vmlinux into the vmlinuz, calculate the checksum after decompressing it and compare it with the recorded checksum.
      * Upstream the [high-resolution sched_clock][29]

### Linux-Loongson

  * Add the Loongson specific delay implementation 
      * Based on the principle of arch/mips/cavium-octeon/csrc-octeon.c, it may be possible to add a more precise delay() implementation.
      * And perhaps we need to define a read\_current\_timer() and the related macro: ARCH\_HAS\_READ\_CURRENT\_TIMER to speed up the calculation of loops\_per\_jiffy for delay().
  * Add the Loongson-2F specific prefetch macro 
      * There is no prefetch instruction in Loongson-2F, but we can try to emulate one with the help of &#8220;load $0, addr&#8221; to pre-fetch the content from memory to cache.
  * Fix the NOP issue of Loongson2F in kernel space 
      * Heihaier have contributed the primary patch, please get more information from loongson-dev google group: Dynamic fix loongson2f nop in kernel
  * Maintain the latest linux(>=2.6.34) for Loongson 
      * arch/mips/oprofile/ (loongson2 oprofile support) 
      * arch/mips/kernel/cpufreq/ (loongson2 cpu freqency scaling support)
      * arch/mips/loongson/common/pm.c (loongson2 Suspend support) 
      * arch/mips/pci/{fixup-fuloong2e.c, fixup-lemote2f.c, ops-loongson2.c} (Loongson2 pci support) 
      * arch/mips/loongson/{fuloong-2e, lemote-2f}/ (loongson family of machines support) 
      * arch/mips/include/asm/mach-loongson/ (loongson platform specific header files)
  * Upstream the left YeeLoong platform specific drivers 
      * drivers/platform/mips/ or http://patchwork.linux-mips.org/project/linux-mips/list/?q=YeeLoong
  * Add Genirq threading support for the platform drivers 
      * Convert the irq handlers under drivers/platform/mips to irq threads. please refer to: 
  * Maintain the Silicon Motion Driver (SM712 video card driver) 
      * drivers/staging/sm7xx/, please refer to the TODO file
  * Power Management stuff 
      * Upstream the new cpufreq driver and the R4K for cpufreq support.
  * Clean up the CS5536 support 
      * based on arch/mips/loongson/common/cs5536/ and include/linux/cs5535.h, `grep CS553[56] -ur {drivers,sound}/`
      * Use the common drivers instead of the Loongson specific drivers
      * Move the basic CS5536 support under MFD_SUPPORT (Compare the source code of for Loongson & X86 and abstract it)
  * Add new LynLoong machine support
  * Add new Loongson-2G, Loongson-3A family of machines support

## FAQ (常见问题)

Although this project only care about the linux kernel for loongson machines, but without a good X Window and related driver, people will get a bad experience of the machine, the same to the network support, so, we will give you the latest information of them too.

### X window

  * How to use a light weight login manager
    
    There are lots of light weight login managers, but slim may be a good choice, to use it instead of gdm, you just need to install it and replace the gdm with it.
    
        $ sudo apt-get install slim
        $ sudo dpkg-reconfigure slim
        
    
    To login automatically with slim, you just need to edit /etc/slim.conf and add the following lines:
    
        default_user <your login user name>
        focus_password yes
        auto_login yes
        

  * How to make the X window work on my YeeLoong netbook?
    
    You need to install a suitable Xorg-server and the related silicon motion driver or the generic fbdev driver. in the default official debian 6.0, that Xrog-server and the fbdev module works on YeeLoong netbook, but do not have a good performance, If you need the fastest X window for your YeeLoong, the debian 6.0 maintained by LiuShiwei are recommended.

### Network (网络支持)

To get a better network support, please install the latest NetworkManager tool into your system.

  * My RTL8187B wifi can not survive from hibernation, how to fix it?
    
    Please use kernel >= 2.6.36.

  * How to enable my RTL8187 Wifi when booting?
    
    You can append the following line into /etc/rc.local:
    
        $ echo 1 > /sys/class/rfkill/rfkill0/state
        

  * How to make a 3G card work on my YeeLoong netbook?
    
    Please refer to [how to use 3G card on YeeLoong netbook][30].

  * How to fix the data corruption problem? (Please refer to &#8220;Fuloong 6005 linux-community-kernel corrupt data&#8221;)
    
        $ ethtool -K eth0 rx off
        $ ethtool -K eth1 rx off
        
    
    The root cause may be the hardware offload support of the network card may not be well supported in Linux, so, disable it as a temp solution.

### Camera (摄像头支持)

  * How to make camera work?
    
    Please install `v4l*` and `webcam*` packages, and then, enable it with Fn+ESC, at last, test it with the following command:
    
        $ mplayer tv://dev/video0
        
    
    If works, you will see your head.

### Audio (音频支持)

  * does YeeLoong support audio mixing （混音，同时播放多首歌曲）?
    
    Yes, but it only support software audio mixing and need an extra [config][31] for the ALSA audio output of cs5535audio card.
    
    Firstly, install the config:
    
        $ cp /path/to/cs5535audio.conf /usr/share/alsa/cards/
        
    
    Then test it:
    
        // on one terminal
        $ mplayer -ao alsa file1.mp3
        // on another
        $ mplayer -ao alsa fil2.mp3
        // You may get two different songs
        

  * does Loongson support ALSA audio output?
    
    Yes, but please install the kernel >= 2.6.33.3, or 2.6.32, 2.6.31

### Video (视频支持)

  * [ffmpeg optimization Loongson][32]

### Power Management (功耗管理)

All of the Lemote machines support Hibernation if with the suitable kernel(>=2.6.36) and the right config, but only Loongson (>=2F) family of machines(Currently, Only YeeLoong) support Suspend.

  * Kernel config
    
      * CPUFreq (动态变频) 
          * CONFIG\_LOONGSON2\_CPUFREQ: Loongson-2F cpu frequency scaling driver(The conservative governor is Preferred) 
          * CONFIG\_R4K\_TIMER\_FOR\_CPUFREQ: R4K Timer enhancement for CPUFreq (From 2.6.37) 
      * Hibernation (休眠) 
          * Please enable CONFIG\_HIBERNATION and config CONFIG\_PM\_STD\_PARTITION=&#8221;/dev/hdaX&#8221; 
          * /dev/hdaX is the swap partition of your machine, you can pass &#8220;resume=/dev/hdaY&#8221; or &#8220;resume=/dev/sdaY&#8221; to override it.
      * Suspend support (挂起) 
          * Please enable CONFIG\_LOONGSON\_SUSPEND, CONFIG_SUSPEND, this is only for Loongson2F.
      * Usage 
          * Command line interface $ cat /sys/power/state mem disk suspend $ echo disk > /sys/power/state # Hibernation, power off, resume it via powering on it $ echo suspend > /sys/power/state # Suspend, suspend all except memory, resume it via pressing any key(except the Fn) on your keyboard
      * GUI tools gnome-power-manager or kpowersave are recommended.

  * Bugs & Workarounds
    
      * Will RTL8187B Wifi Driver survive after resuming from Hibernation? Yes, but please use kernel >= 2.6.36.
    
      * How can we make dynamic CPU Frequency work normally? Please use kernel >= 2.6.35.

### Hotkey (热键支持)

  * How to make the hotkey (Function key) work on YeeLoong netbook.

You need to ensure the yeeloong platform driver(CONFIG\_LEMOTE\_YEELOONG2F) is enabled and also the related user-space applications are installed. for the official debian system, if the yeeloong platform driver is enabled, it should work.

  * Which hotkey does YeeLoong netbook support?
    
      * Fn+ESC Turn on/off camera input
      * Fn+F1 Sleep buttion, report the SLEEP event to user-space, you can configure the action of the sleep button via kpowersave, gnome-power-manager or the other power manager.
      * Fn+F2 Turn on/off LCD output
      * Fn+F3 Swith CRT/LCD output
      * Fn+F4 Turn on/off Mute
      * Fn+F5 Turn on/off Wifi
      * Fn+F6 Turn on/off touchpad (Supported by the EC ROM directly)
      * Fn+Up/Down Increase/decrease the brightness of the backlight of the LCD
      * Fn+Left/Right Increse/decrease the volume of sound output

  * Is there a tool to test hotkey support?
    
    Yes, please download the [hotkey.py][33] and test it as below:
    
        $ sudo apt-get install python-pyosd
        $ python hotkey.py  // You can press `Fn+{ESC,F1~F5, ^/V, </>}` and take a look at the command line output
        

### Sensors (传感器支持)

  * How to get the information of the fan, battery, cpu of YeeLoong netbook?
    
    You also need to enable the yeeloong platform driver(CONFIG\_LEMOTE\_YEELOONG2F) and install the lm-sensors(or the other related tools, for example, sensors-applet) in your system, then you can get the information via the following command.
    
        $ sensors
        yeeloong-virtual-0
        Adapter: Virtual device
        Voltage:            +12.46 V
        Fan RPM:            4403 RPM
        CPU Temperature:     +51.0°C  (high = +60.0°C)                  
        Battery Temperature: +23.0°C                                    
        Current:             +0.00 A
        

### Serial Port (串口)

  * Is there a serial port on YeeLoong netbook?

Yes, but there is no existing J2 header, you need to solder one yourself, here is the [HOWTO][34].

### Develop (开发)

  * Which tools are needed to do basic C programming on Loongson machines?

Because Loongson machines use the standard GNU/Linux systems, you can use almost all of the tools you can used in the linux system of the other machines, the most important tools include GNU toolchains: gcc, gdb, binutils &#8230;., and the latest gcc >= 4.4 is recommended for the loongson specific support is only available in this version, to enable the loongson specific support, for loongson2f, please use the option -march=loongson2f, for loongson2e, please use -march=loongson2e.

And again, please remember to use the latest binutils for it provides two new options to workaround the hardware bug of loongson2f, to get more information about it, please access [this page][35].

  * Does Loongson have oprofile support?

Yes, but you need to get a suitable kernel(>=2.6.33 with CONFIG_OPROFILE=y) which support oprofile and also the user-space oprofile >= 0.9.7 is needed.




 [1]: http://www.kernel.org
 [2]: http://www.loongson.cn/
 [3]: http://www.linux-mips.org
 [4]: http://dev.lemote.com/cgit/linux-loongson-community.git/
 [5]: https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git
 [6]: https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/
 [7]: http://git.linux-mips.org/pub/scm/ralf/
 [8]: http://www.linuxfromscratch.org/clfs/view/1.0.0/mips/
 [9]: http://www.linuxfromscratch.org/clfs/view/1.0.0/mips64-64/
 [10]: http://www.linuxfromscratch.org/clfs/view/1.0.0/mips64/
 [11]: http://www.heiher.info/916.html
 [12]: http://dev.lemote.com/files/document/pmon/PMON%E6%89%8B%E5%86%8Cv0.1.pdf
 [13]: http://www.gnu.org/software/grub/grub-2.en.html
 [14]: http://lists.gnu.org/archive/html/grub-devel/2010-03/msg00017.html
 [15]: http://horms.net/projects/kexec/
 [16]: https://groups.google.com/forum/#!msg/loongson-dev/zp1e6h7KyHI/U8dU4y333t0J
 [17]: http://dev.lemote.com/files/resource/download/rescue/rescue-yl
 [18]: http://dev.lemote.com/files/resource/download/rescue/rescue-fl
 [19]: http://www.bjlx.org.cn/
 [20]: http://dev.lemote.com/files/document/kernel/Linux%E5%86%85%E6%A0%B8%E7%A7%BB%E6%A4%8D%E5%BC%80%E5%8F%91%E6%89%8B%E5%86%8Cv0.1.pdf
 [21]: http://www.kernel.org/pub/software/scm/git/docs/user-manual.html
 [22]: http://dev.lemote.com/files/resource/documents/Loongson/ls2e/godson2e.user.manual.pdf
 [23]: http://dev.lemote.com/files/resource/documents/Loongson/ls2e/godson2e-user-manual-V0.6.pdf
 [24]: http://www.loongson.cn/uploadfile/file/20080821113149.pdf
 [25]: http://dev.lemote.com/files/resource/documents/Loongson/ls2f/Loongson2FUserGuide.pdf
 [26]: http://dev.lemote.com/files/resource/documents/Loongson/ls2e/godson2e.north.bridge.manual.pdf
 [27]: http://dev.lemote.com/files/resource/documents/Loongson/ls2e/bonito64-spec.pdf
 [28]: http://www.linuxmedialabs.com/LMLCD/LMLGEOMG/AMDG_CS5536.pdf
 [29]: http://patchwork.linux-mips.org/project/linux-mips/list/?q=sched_clock
 [30]: http://www.bjlx.org.cn/node/752
 [31]: /wp-content/uploads/linux-loongson/cs5535audio.conf
 [32]: http://www.bjlx.org.cn/node/769
 [33]: /wp-content/uploads/linux-loongson/hotkey.py
 [34]: http://groups.google.com/group/loongson-dev/browse_thread/thread/98f505ef7c8256df?hl=en
 [35]: http://groups.google.com.hk/group/loongson-dev/browse_thread/thread/d9103283141c00fb
