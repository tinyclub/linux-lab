---
layout: post
author: 'Wu Zhangjin'
title: "嵌入式 Linux 开发平台"
album: "嵌入式 Linux 知识库"
group: translation
permalink: /embedded-linux-development-platforms/
description: "本文介绍了基于各大常见架构的 Linux 开发平台。"
category:
  - 开发板
tags:
  - Linux
  - ARM
  - MIPS
  - PowerPC
  - i386
---

> 书籍：[嵌入式 Linux 知识库](https://gitbook.com/book/tinylab/elinux)
> 原文：[eLinux.org](http://eLinux.org/Development_Platforms "http://eLinux.org/Development_Platforms")
> 翻译：[@lzufalcon](https://github.com/lzufalcon)

## 最受欢迎的设备

-   [Via APC 8750](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/VIA_APC_8750/VIA_APC_8750.html "VIA APC 8750")
-   [Raspberry Pi](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/RaspberryPi/RaspberryPi.html "RaspberryPi") 来自树莓派基金会，采用来自博通的 BCM2835
-   [CraneBoard](http://www.mistralsolutions.com/craneboard) 来自 Mistral Solutions，采用 TI 的 AM3517
-   [AM/DM37x EVM](http://www.mistralsolutions.com/AM37x_EVM) 来自 Mistral Solutions，采用 TI 的 AM/DM35x 处理器
-   [BeagleBoard](http://tinylab.gitbooks.io/elinux/content/zh/hardware_pages/BeagleBoard/BeagleBoard.html "BeagleBoard") 采用 TI OMAP3(Cortex-A8)
-   [Devkit8000](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Devkit8000/Devkit8000.html "Devkit8000") 采用 TI OMAP3530(Cortex-A8) 的开发板
-   [Devkit8500D](http://www.armkits.com/product/devkit8500d.asp) 采用 TI DM3730 ARM Cortex-A8 的开发板
-   [Devkit7000](http://www.armkits.com/product/devkit7000.asp) 采用三星S5PV210 ARM Cortex-A8 的开发板
-   [Hawkboard](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Hawkboard/Hawkboard.html "Hawkboard") 采用 TI OMAP L138（ARM9 和 C674X 浮点 DSP）
-   [Hammer\_Board](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Hammer_Board/Hammer_Board.md "Hammer Board") 采用三星基于 ARM9 的[S3C2410](../.././dev_portals/Development_Platforms/S3C2410/S3C2410.html "S3C2410")
-   [Jetson TK1](http://tinylab.gitbooks.io/elinux/content/zh/hardware_pages/Jetson_TK1/Jetson_TK1.md "Jetson TK1") NVIDIA Tegra K1 4 核 Cortex-A15 CPU + **192-core Kepler GPU** 移动超级计算机。用到 [U-Boot](../.././dev_portals/Development_Platforms/Tegra/Mainline_SW/U-Boot/Tegra/Mainline_SW/U-Boot.html "Tegra/Mainline SW/U-Boot") +  [Nouveau](http://nouveau.freedesktop.org/wiki/) 它是第一个[**100% 完全开源**](http://www.codethink.co.uk/2014/06/12/no-secret-sauce-just-open-source) 的采用 GPU 加速的 Linux 开发板
-   [LeopardBoard](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/LeopardBoard/LeopardBoard.html "LeopardBoard") 采用 TI TMS320DM355
-   [Opensourcemid](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Hardware_Hacking/Opensourcemid/Opensourcemid.html "Opensourcemid") K7 MID OMAP3530 平板，来自 [OpenSourceMID.org](http://www.opensourcemid.org)
-   [OMAP3 EVM](http://www.mistralsolutions.com/products/omap_3evm.php) 来自 Mistral Solutions
-   [Odroid](http://www.linuxfordevices.com/c/a/News/HardKernel-Odroid/##) 采用三星 S5PC100 (Cortex-A8) 的可编程（Hackable）的 Android 手持游戏设备
-   [(beagle 的克隆)](http://www.tenettech.com/devkit_8000_evalaution_kit.html)
-   [Snowball SDK & PDK (Dual Cortex A9 + Mali400)](http://www.igloocommunity.org/)
-   [Lionboard](http://www.lionboard.org/) TI DM368 SODIMM 模块 (ARM9 + 视频核心)
-   [MYD-SAMA5D3X](http://www.myirtech.com/list.asp?id=432) 由 MYIR 设计，采用 Atmel SAMA5D3 (ARM Cortex-A5)
-   [MYD-AM335X](http://www.myirtech.com/list.asp?id=466) 由 MYIR 设计，采用 TI AM335X (ARM Cortex-A8)
-   [MYD-IMX28X](http://www.myirtech.com/list.asp?id=472) 由 MYIR 设计，采用 Freescale i.MX28 (ARM9)
-   [MYD-SAM9X5](http://www.myirtech.com/list.asp?id=424) 由 MYIR 设计，采用 Atmel AT91SAM9G15/G25/G35/X25/X35 (ARM9)
-   [MYD-SAM9X5-V2](http://www.myirtech.com/list.asp?id=444) 由 MYIR 设计，采用 Atmel AT91SAM9G15/G25/G35/X25/X35 (ARM9)


## [ARM](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/ARM_Processor/ARM_Processor.html "ARM Processor")

-   [Forlinx Embedded](http://www.forlinx.net) ARM 系列开发板
    -   [FL2440 采用三星 ARM9 S3C2440](http://www.forlinx.net/?p=28&a=view&r=52%7C)
    -   [FL2416 采用三星 ARM9 S3C2416](http://www.forlinx.net/?p=28&a=view&r=104%7C)
    -   [OK6410-A 采用三星 ARM11 S3C6410](http://www.forlinx.net/?p=27&a=view&r=49%7C)
    -   [OK6410-B 采用三星 ARM11 S3C6410](http://www.forlinx.net/?p=27&a=view&r=50%7C)
    -   [OK210 采用三星 Cortex-A8 S5pv210](http://www.forlinx.net/?p=26&a=view&r=47%7C)
    -   [OK210-A 采用三星 Cortex-A8 S5pv210](http://www.forlinx.net/?p=26&a=view&r=48%7C)
    -   [OK335xD 采用 TI Sitara AM335x](http://www.forlinx.net/?p=26&a=view&r=46%7C)
    -   [OK335xS 采用 TI Sitara AM335x](http://www.forlinx.net/?p=26&a=view&r=99%7C)
    -   [OK335xS-II 采用 TI Sitara AM335x](http://www.forlinx.net/?p=26&a=view&r=110%7C)

-   [GNUBLIN](http://www.gnublin.org) GNUBLIN 开发板
-   [ARM cortex A8 board 1GHz 512M DDR3](http://www.quickembed.com/Tools/Shop/A8/201202/245.html)
    采用三星 S5PV210
-   [Devkit8000](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Devkit8000/Devkit8000.html "Devkit8000") 采用 OMAP3530，来自 [Embest](http://www.armkits.com)
-   [Devkit8500D](http://www.armkits.com/Product/devkit8500d.asp) 采用 TI DM3730
-   [Devkit7000](http://www.armkits.com/product/devkit7000.asp) 采用三星 S5PV210
-   [CraneBoard](http://www.mistralsolutions.com/craneboard) 来自 Mistral Solutions
-   [PandaBoard](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/PandaBoard/PandaBoard.html "PandaBoard")
-   [AM/DM37x EVM](http://www.mistralsolutions.com/AM37x_EVM) 来自 Mistral Solutions
-   [Digi 入门套件](http://www.digi.com/products/embeddedsolutions/softwareservices/digiembeddedlinux.jsp)
-   [SheevaPlug](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/SheevaPlug/SheevaPlug.html "SheevaPlug")
-   [GuruPlug](http://hackaday.com/2010/02/08/guruplug-the-next-generation-of-sheevaplug/)
-   [ARM Integrator](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/ARM_Integrator_Info/ARM_Integrator_Info.html "ARM Integrator Info")
-   [OSK](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/OSK/OSK.html "OSK") - OMAP 入门套件
-   GAO Engineering Inc. - [http://www.gaoengineering.com](http://www.gaoengineering.com)
-   [DaVinci](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/DaVinci/DaVinci.md "DaVinci") DVEVM 评估模块 - [http://www.spectrumdigital.com/](http://www.spectr.htmligital.com/)
-   [ITSY](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/ITSY/ITSY.html "ITSY")
-   [LART 项目](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/LART_Project/LART_Project.html "LART Project")
-   [Hammer\_Board](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Hammer_Board/Hammer_Board.html "Hammer Board")
-   [Simtec Electronics](http://www.simtec.co.uk/)
-   [AT91RM9200 开放评估板](http://wiki.emqbit.com/free-ecb-at91)
-   [BeagleBoard](http://tinylab.gitbooks.io/elinux/content/zh/hardware_pages/BeagleBoard/BeagleBoard.html "BeagleBoard")
-   [ODROID](http://eLinux.org/index.php?title=ODROID&action=edit&redlink=1 "ODROID (page does not exist)") 采用 Samsung Exynos 的[开发板和平板](http://www.hardkernel.com/)
-   [Balloonboard](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Balloonboard/Balloonboard.html "Balloonboard")
-   [KB9202](http://www.kwikbyte.com/KB9202.html)
-   Luminary Micro's **LM3S6965** 是款 ARM Cortex M3 MCU。有一个便宜的开发板，叫做**基于 LM3S6965 的以太网评估套件**，可以从 [Mouser](http://www.mouser.com/) 或者其他渠道买到，大约 69 美金。
-   [TechnologicSystems](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/TechnologicSystems/TechnologicSystems.html "TechnologicSystems")
-   [OMAP3 EVM from Mistral Solutions](http://www.mistralsolutions.com/products/omap_3evm.php)
-   [NaviEngine](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Hardware_Hacking/NaviEngine/NaviEngine.html "NaviEngine") 采用 NEC ARM11MPCore (4 x ARM11)
-   采用 Freescale i.MX 的 [Armadeus APF boards](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Armadeus_APF_boards/Armadeus_APF_boards.html "Armadeus APF boards")
-   Zoom OMAP34x & 36x 开发套件 - [http://omapzoom.org](https://omapzoom.org/)
-   [Tegra2](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Tegra2/Tegra2.html "Tegra2")
-   [Arm11 开发板](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Arm11_development_board/Arm11_development_board.html "Arm11 development board")
-   [Snowball SDK & PDK (Dual Cortex A9 + Mali 400)](http://www.igloocommunity.org/)
-   [Raspberry Pi](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/RaspberryPi/RaspberryPi.htmlBoard "RaspberryPiBoard")
-   [Freescale IMX53QSB](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Freescale_IMX53QSB/Freescale_IMX53QSB.html "Freescale IMX53QSB") [[1]](http://imxcommunity.org/group/imx53quickstartboard)
-   [Calao Atmel AT91 开发板](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Calao_Atmel_AT91_development_board/Calao_Atmel_AT91_development_board.html "Calao Atmel AT91 development board") [[2]](http://www.calao-systems.com/articles.php?lng=fr&pg=5940)
    -   USB A9260
    -   USB A9263
    -   USB A9G20
    -   TNY A9263
    -   TNY A9G20
    -   QIL-A9260
-   友善之臂开发板:
    -   [Mini2440](http://www.hycshop.com/mini2440-c-1_7/) 采用 S3C2440 ARM9 的开发板
    -   [Tiny6410](http://www.hycshop.com/tiny6410-c-1_10/) 采用 S3C6410 ARM11 的开发板
-   [Basi and Dingo DaVinci dm365 开发板](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Basi_and_Dingo_DaVinci_dm365_boards/Basi_and_Dingo_DaVinci_dm365_boards.html "Basi and Dingo DaVinci dm365 boards")
-   [Gumstix Overo](http://gumstix.com)
-   [嵌入式开放模块化架构/EOMA-68](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Embedded_Open_Modular_Architecture/EOMA-68/Embedded_Open_Modular_Architecture/EOMA-68.html "Embedded Open Modular Architecture/EOMA-68")
-   [一系列 OMAP 开发板](http://tinylab.gitbooks.io/elinux/content/zh/hardware_pages/BeagleBoard/BeagleBoard.html#Other_OMAP_boards "BeagleBoard")
-   [Dragonboard](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Dragonboard/Dragonboard.html "Dragonboard")
-   [WandBoard](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/WandBoard/WandBoard.html "WandBoard")
-   [Colibri 评估板](https://www.toradex.com/products/carrier-boards/colibri-evaluation-carrier-board)（采用 Nvidia Tegra T20, T30 and Freescale iMX6, VF50, VF61，来自 Toradex Switzerland 和 Seattle，WA
-   [Apalis 评估板](https://www.toradex.com/products/carrier-boards/apalis-evaluation-board)（采用 Nvidia Tegra T30 and Freescale iMX6，来自 Toradex Switzerland 和 Seattle，WA
-   [Ixora Carrier 开发板](https://www.toradex.com/products/carrier-boards/ixora-carrier-board)（采用 Nvidia Tegra T30 and Freescale iMX6，来自 Toradex Switzerland 和 Seattle，WA
-   [Viola Carrier 开发板](https://www.toradex.com/products/carrier-boards/viola-carrier-board)（采用 Nvidia Tegra T20, T30 and Freescale VF50, VF61, iMX6，来自 Toradex Switzerland 和 Seattle，WA
-   [Iris Carrier 开发板](https://www.toradex.com/products/carrier-boards/iris-carrier-board)（采用 Nvidia Tegra T20 and T30, Freescale iMX6, VF50, VF61 和 Intel/Marvell PXA270, PXA310, PXA320，来自 Toradex Switzerland 和 Seattle, WA
-   [Orchid Carrier 开发板](https://www.toradex.com/products/carrier-boards/orchid-carrier-board)（采用 Intel/Marvell PXA270, PXA310, PXA320, Nvidia Tegra T20 and T30 and Freescale iMX6, VF50, VF61，来自 Toradex Switzerland and Seattle, WA
-   [PengPod](http://pengpod.com/)
-   [A13 OLinuXino-MICRO](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/A13_OLinuXino-MICRO/A13_OLinuXino-MICRO.html "A13 OLinuXino-MICRO") 全志 A13 开发板
-   [Boundary Devices i.MX6 开发板](http://boundarydevices.com/products/)
    -   [Nitrogen6x](http://boundarydevices.com/products/nitrogen6x-board-imx6-arm-cortex-a9-sbc/)
    -   [Nitrogen6 Lite](http://boundarydevices.com/products/nitrogen6_lite/)
    -   [SABRE Lite](http://boundarydevices.com/products/sabre-lite-imx6-sbc/)
-   [SolidRun HummingBoard](http://www.solid-run.com/products/hummingboard/linux-sbc-specifications/), 采用 i.MX6，跟树莓派有相同的规格、连接器和插脚引线
-   MYIR's ARM 开发板
    -   [MYD-AM335X](http://www.myirtech.com/list.asp?id=466) - TI AM335x ARM Cortex-A8 开发板
    -   [MYD-IMX28X](http://www.myirtech.com/list.asp?id=472) - Freescale IMX28X ARM9 开发板
    -   [MYD-SAMA5D3X](http://www.myirtech.com/list.asp?id=432) - Atmel SAMA5D3 ARM Cortex-A5 开发板
    -   [MYD-SAM9X5](http://www.myirtech.com/list.asp?id=424) - Atmel AT91SAM9X5 ARM9 开发板
    -   [MYD-SAM9X5-V2](http://www.myirtech.com/list.asp?id=444) - Atmel AT91SAM9X5 ARM9 开发板
    -   [MYC-SAMA5D3X](http://www.myirtech.com/list.asp?id=456) - Atmel SAMA5D3 ARM Cortex-A5 CPU 模块
    -   [MYC-SAM9X5](http://www.myirtech.com/list.asp?id=458) - Atmel AT91SAM9X5 ARM9 CPU 模块
    -   [MYC-SAM9X5-V2](http://www.myirtech.com/list.asp?id=459) - Atmel AT91SAM9X5 ARM9 CPU 模块
    -   [MYS-SAM9X5](http://www.myirtech.com/list.asp?id=431) - Atmel AT91SAM9X5 ARM9 单板计算机
    -   [MYS-SAM9G45](http://www.myirtech.com/list.asp?id=370) - Atmel AT91SAM9G45 ARM9 单板计算机
    -   [MYD-LPC435X](http://www.myirtech.com/list.asp?id=422) - NXP LPC4350/4357 ARM Cortex-M4/M0 开发板
    -   [MYD-LPC185X](http://www.myirtech.com/list.asp?id=430) - NXP LPC1850/1857 ARM Cortex-M3 开发板
    -   [MYD-LPC1788](http://www.myirtech.com/list.asp?id=422) - NXP LPC1788 ARM Cortex-M3 开发板
-   Atmel Xplained 快速成型板
    -   Atmel [SAMA5D3 Xplained](http://www.atmel.com/tools/ATSAMA5D3-XPLD.aspx)
    -   Atmel [SAMA5D4 Xplained](http://www.atmel.com/tools/ATSAMA5D4-XPLD-ULTRA.aspx)


## [AVR32](http://eLinux.org/Processors#AVR32 "Processors")

-   [ATNGW100](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/ATNGW100/ATNGW100.html "ATNGW100") - [网关套件](http://www.atmel.com/dyn/products/tools_card.asp?tool_id=4102)
-   [AVR 开发套件板](http://www.quickembed.com/Tools/Shop/MCU/201004/89.html)
-   [AVR JTAG 模拟器](http://www.quickembed.com/Tools/Shop/MCU/201002/70.html)


## [Blackfin](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Blackfin/Blackfin.html "Blackfin")

-   [ADI Blackfin 开发板](http://www.quickembed.com/Tools/Shop/DSP/200907/36.html)
-   [ADI 开发板](http://docs.blackfin.uclinux.org/doku.php?id=hw:boards)
-   [ADI 开发板的外置卡片](http://docs.blackfin.uclinux.org/doku.php?id=hw:cards)
-   [其他内容](http://docs.blackfin.uclinux.org/doku.php?id=buy_stuff#other_hardware)
-   [演示视频](http://youtube.com/watch?v=fKyQOntPEFs)
-   [ADI JTAG 模拟器](http://www.quickembed.com/Tools/Shop/DSP/201007/119.html)


## MIPS

-   mips-1 小端 -
    [Flameman/routerboard-rb532](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Flameman/routerboard-rb532/Flameman/routerboard-rb532.html "Flameman/routerboard-rb532")
-   [Ben 微型本](http://en.qi-hardware.com/wiki/Ben_NanoNote)
-   [MIPS Creator CI20](http://tinylab.gitbooks.io/elinux/content/zh/hardware_pages/MIPS_Creator_CI20/MIPS_Creator_CI20.html "MIPS Creator CI20") 开发板
-   [Opendreambox DVB/PVR 机顶盒家族](http://www.opendreambox.org)
-   [MiniEMBWiFi](http://www.omnima.co.uk/store/catalog/MiniEMBWiFi-p-16180.html)


## PowerPC

-   [Walnut (405GP)](http://amcc.com/Embedded/Downloads/download.html?cat=1&family=2)
-   [Dht-Walnut (405GP)](http://www.elinux.org/Flameman/dht-walnut)
-   [Walnut (405GP)](http://www.elinux.org/Flameman/walnut)
-   [Ebony (440GP](http://www.elinux.org/Flameman) 看下 flameman
-   [sandpoint (7410)](http://www.elinux.org/Flameman/sandpoint3)
-   [Kuro Box-HG (MPC4281)](http://www.kurobox.com/mwiki/index.php/Kurobox/Kurobox-HG_Main_Page)
-   [Efika5200 (MPC5200)](http://www.powerdeveloper.org/program/efika/accepted)


## SuperH

-   Sega
    -   Dreamcast(SH7091) - [Linux-SH Dreamcast](http://linux-sh.org/cgi-bin/moin.cgi/Dreamcast) 请注意只支持以 MIL-CD 开头的型号。强烈建议使用 [BBA](http://en.wikipedia.org/wiki/Dreamcast_Broadband_Adapter) 来跟 Dreamcast 通信。
-   Hitachi ULSI Systems
    -   MS7206SE01 (SH72060 Solution Engine)
    -   MS7750SE01 (SH7750(sh4) Solution Engine)
    -   MS7709SE01 (SH7709(sh3) Solution Engine)
-   SuperH, Inc.
    -   MicroDev
-   HP Jornada
    -   525 (SH7709 (sh3))
    -   548 (SH7709A (sh3))
    -   620LX (SH7709 (sh3))
    -   660LX (SH7709 (sh3))
    -   680 (SH7709A (sh3))
    -   690 (SH7709A (sh3))
-   Renesas Technology Corp.
    -   符合 RTS7751R2D CE Linux Forum（CELF）标准的评估版
-   [Renesas Europe/MPC Data Limited](http://www.shlinux.com/)
    -   EDOSK7705 (SH7705 sh3)
    -   EDOSK7760 (SH7760 sh4)
    -   EDOSK7751R (SH7751R sh4)
    -   SH7751R SystemH (SH7751R sh4)
-   [CQ Publishing Co.，Ltd.](http://www.cqpub.co.jp/eda/CqREEK/SH4PCI.HTM)
    -   CQ RISC 评估套件 (CqREEK)/SH4-PCI，安装有 Linux
-   [Kyoto Microcomputer Co., Ltd. (KMC or KμC)](http://www.kmckk.co.jp/eng/)
    -   Solution Platform KZP-01（KZP-01[Mainboard] + KZ-SH4RPCI-01[SH4 CPU 开发板]）
-   [Silicon Linux Co,. Ltd.](http://www.si-linux.com/index.html)
    -   CAT760 (SH7760)
    -   CAT709 (SH7709S)
    -   CAT68701 (SH7708R，CATBUS[为 68000 开发板设计]兼容)
-   [Daisen Electronic Industrial Co., Ltd.](http://dsn-net.net/product/list_shlinux.html)
    -   SH2000 (SH7709A 118MHz)
    -   SH2002 (SH7709S 200MHz)
    -   SH-500 (SH7709S 118MHz)
    -   SH-1000 (SH7709S 133MHz)
    -   SH-2004 (SH7750R 240MHz)
-   [IO-DATA DEVICE, Inc.(网络下载机 [NAS](http://www.iodata.jp/prod/storage/hdd/index_lanhdd.htm)系列)]
    -   LAN-iCN (支持 IODATA 硬盘的 NAS 适配器，采用 "i-connect" 接口)
    -   LAN-iCN2 (支持 IODATA 硬盘的 NAS 适配器，采用 "i-connect" 接口)
    -   LANDISK (SH4-266MHz[FSB133MHz] RAM64MB UDMA133 USB x2 10/100Base-T)
    -   HDL-xxxU (LANDISK 系列 NAS 标准型号)
    -   HDL-xxxUR(LANDISK 采用 RICOH IPSiO G 系列打印监控器，支持 Windows)
    -   HDL-WxxxU(LANDISK 采用与宽体 & 双驱动器支持（重存储（Heavy storage）或 RAID1）
    -   HDL-AV250(LANDISK 支持家庭网络的 DLNA 标准)
    -   LANTank(LANDISK 套件 SuperTank(CHALLENGER) 系列)
    -   基于 HDL-WxxxU 的双驱散装 NAS 套件。LANTank 有一个特性，支持网络媒体服务器(参见 iTunes 等……)
-   [TOWA MECCS CORPORATION](http://www.e-linux.jp/tmm_index.html)
    -   TMM1000 (SH7709)
    -   TMM1100 (SH7727)
    -   TMM1200 (SH7727)
-   [Sophia Systems](http://www.sophia-systems.co.jp/ice/eval_board/index.html)
    -   Sophia SH7709A 评估板
    -   Sophia SH7750 评估版
    -   Sophia SH7751 评估版
-   [MovingEye Inc.](http://www.movingeye.co.jp/mi6/sh4board.html)
    -   A3pci7003 (使用 SH7750/ART-Linux [支持实时扩展的 Linux])
-   [AlphaProject Co., Ltd.](http://www.apnet.co.jp/product/ms104/ms104-sh4.html)
    -   MS104-SH4 (SH7750R/PC104(嵌入式 ISA 总线)，采用 apLinux)
-   [Interface Corporation.](http://www.interface.co.jp/cpu/)
    -   MPC-SH02 (SH7750S: 采用 ATX 主板类型)
    -   PCI-SH02xx (SH7750S: 采用 PCI 卡类型)
-   [TAC Inc.](http://www.tacinc.jp/)
    -   [T-SH7706LAN](http://web.kyoto-inet.or.jp/people/takagaki/T-SH7706/T-SH7706.htm) 也叫 "Mitsuiwa SH3 board" ["SH-MIN"] (SH7706A/128MHz Flash512KB SDRAM 8MB 10BASE-T)
-   [SecureComputing](http://www.securecomputing.com/)/[SnapGear](http://www.snapgear.org/)（比较旧的产品，可以从 ebay 等找下，所有的都支持网络引导并且提供了一个调试头）
    -   [SG530](http://www.snapgear.org/) (SH7751@166MHz RAM16MB FLASH4MB 2x10/100 1xSerial)
    -   [SG550](http://www.snapgear.org/) (SH7751@166MHz RAM16MB FLASH8MB 2x10/100 1xSerial)
    -   [SG570](http://www.snapgear.org/) (SH7751R@240MHz RAM16MB FLASH8MB 3x10/100 1xSerial)
    -   [SG575](http://www.snapgear.org/) (SH7751R@240MHz RAM64MB FLASH16MB 3x10/100 1xSerial)
    -   [SG630](http://www.snapgear.org/) (SH7751@166MHz PCI NIC card RAM16MB FLASH4MB 1x10/100 1xSerial-header)
    -   [SG635](http://www.snapgear.org/) (SH7751R@240MHz PCI NIC card RAM16MB FLASH16MB 1x10/100 1xSerial-header)


## i386 及其兼容平台

-   [CR48](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Hardware_Hacking/CR48/CR48.html "CR48") Google 上网本
-   [Bifferboard](http://bifferos.co.uk/)


## 未分类

-   [http://www.mikrotik.com/](http://www.mikrotik.com/)
-   [http://www.routerboard.com/](http://www.routerboard.com/)
-   [http://www.cuwireless.net/](http://www.cuwireless.net/)
-   [http://leaf.sourceforge.net/](http://leaf.sourceforge.net/)
-   [http://leaf.sourceforge.net/mod.php?mod=userpage&menu=908&page\_id=27](http://leaf.sourceforge.net/mod.php?mod=userpage&menu=908&page_id=27)
-   [http://www.myirtech.com/](http://www.myirtech.com/)
-   [http://www.1st-safety.com/arm/Tiny6410/](http://www.1st-safety.com/arm/Tiny6410/)
-   [StalkerBoard](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/StalkerBoard/StalkerBoard.html "StalkerBoard")
-   [SBC3530](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/SBC3530/SBC3530.html "SBC3530")
-   [SBC8100](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/SBC8100/SBC8100.html "SBC8100")
-   [SFFSDR](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/SFFSDR/SFFSDR.html "SFFSDR")
-   [SOM1808](http://openembed.org/wiki/SOM1808)
-   [MINI2440v2\_developmentboard](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/MINI2440v2_developmentboard/MINI2440v2_developmentboard.html "MINI2440v2 developmentboard")
-   [Launchpad](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Launchpad/Launchpad.html "Launchpad")
-   [Micro2440](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Micro2440/Micro2440.html "Micro2440")
-   [Mini210](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Mini210/Mini210.html "Mini210")
-   [Tiny210](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Development_Platforms/Tiny210/Tiny210.html "Tiny210")


[分类](http://eLinux.org/Special:Categories "Special:Categories"):

-   [硬件](http://eLinux.org/Category:Hardware "Category:Hardware")
-   [开发板](http://eLinux.org/Category:Development_Boards "Category:Development Boards")
