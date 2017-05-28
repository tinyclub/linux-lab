---
layout: post
author: 'Zhong Bin'
title: "嵌入式 Linux 电源管理"
album: "嵌入式 Linux 知识库"
group: translation
permalink: /embedded-linux-power-management/
description: "介绍了 Linux 电源管理相关的网站、国际会议、标准、文档和开源项目、工具等。"
category:
  - 电源管理
tags:
  - Linux
  - Powertop
  - PM Qos
  - OMAP
  - ACPI
  - 时钟
  - DVFS
---

> 书籍：[嵌入式 Linux 知识库](https://gitbook.com/book/tinylab/elinux)
> 原文：[eLinux.org](http://elinux.org/Power_Management)
> 翻译：[@zhongbin](https://github.com/qkhhyga)
> 校订：[@lzufalcon](https://github.com/lzufalcon)

## 简介

本文介绍 Linux 电源管理相关信息。电源管理因手持或者移动产品大量出现而存在，并且消费者越来越关心他们的产品续航体验。


## 电源管理技术与项目网页

-   [http://www.lesswatts.org/index.php](http://www.01.org) - LessWatts.org （注：该域名已失效，大部分项目都已经转到 01.org）
    -   LessWatts.org 是一个关于如何节省 Linux 系统功耗的网站。
    -   LessWatts 正在创立一个以节省 Linux 功耗为主题的社区，带领开发者、用户、还有系统管理员一起分享节能软件，节能优化以及一些节能的方法和策略。
    -   LessWatts 也提供了 [powertop](https://01.org/powertop) 工具，用于帮助指出一些系统中耗电的地方。

-   [OMAP 电源管理](http://eLinux.org/OMAP_Power_Management "OMAP Power Management")
    -   [TI](http://eLinux.org/Texas_Instruments "Texas Instruments") OMAP 系列处理器上的电源管理。


## Linux 电源管理迷你峰会


### 峰会记录

-   [2010 波士顿 Linux 电源管理迷你峰会记录](http://lwn.net/Articles/400465/)
-   [2009 蒙特利尔 Linux 电源管理迷你峰会记录](http://lwn.net/Articles/345007/)
-   [2008 渥太华 Linux 电源管理迷你峰会记录](http://lwn.net/Articles/292447/)


## CE Linux 论坛的需求标准

见链接: [2006 年 CE Linux 论坛的电源管理需求](http://www.elinux.org/CELF_PM_Requirements_2006)


## 资料文档

-   [设备电源管理规范](http://eLinux.org/Device_Power_Management_Specification "Device Power Management Specification")

-   [动态电源管理规范](http://eLinux.org/Dynamic_Power_Management_Specification "Dynamic Power Management Specification")

-   ACPI 的电源状态和 OMAP 的电源状态之间的映射关系： [ACPI 和 OMAP2 的映射关系](http://eLinux.org/images/0/02/Acpi-to-omap2-mapping.pdf "Acpi-to-omap2-mapping.pdf")

以下是与嵌入式相关的各种电源管理特性的概述：

-   每一微安都是神圣的 - Linux 内核中的动态电压和电流控制接口 - Liam Girdwood [幻灯片](http://www.celinux.org/elc08_presentations/regulator-api-celf.pdf)和[视频](http://free-electrons.com/pub/video/2008/elc/elc2008-liam-girdwood-every-microamp-is-sacred.ogg)

-   PM QoS 以及在嵌入式应用中如何使用 - Mark Gross [幻灯片](http://www.celinux.org/elc08_presentations/elc2008_pm_qos_slides.pdf)和[视频](http://free-electrons.com/pub/video/2008/elc/elc2008-mark-gross-power-management.ogg)

-   嵌入式电源管理模块 - Kevin Hilman  [幻灯片](http://www.celinux.org/elc08_presentations/PM_Building_Blocks1.pdf)和[视频](http://free-electrons.com/pub/video/2008/fosdem/fosdem2008-kevin-hilman-power-management.ogg)

-   在消费类电子设备上实现 Linux 系统挂起到磁盘的目标 - Vitaly Wool [幻灯片](http://tree.celinuxforum.org/CelfPubWiki/ELCEurope2007Presentations?action=AttachFile&do=view&target=std.pdf)

-   Linux 时钟管理框架 - Siarhei Yermalayeu [幻灯片](http://tree.celinuxforum.org/CelfPubWiki/ELCEurope2007Presentations?action=AttachFile&do=view&target=ELC_2007_Linux_clock_fmw.pdf)

-   OMAP3 先进的电源管理，Peter de Schrijver，FOSDEM 2009 [视频](http://free-electrons.com/pub/video/2009/fosdem/fosdem2009-schrijver-advanced-pm-omap3.ogv)

-   把 Linux 电源管理和产品质量联系起来，Eugeny Mints，ELCE 2008 [视频](http://free-electrons.com/pub/video/2008/elce/elce2008-mints-linux-pm-production-quality.ogv)

-   ARM11 的电源管理，Mischa Jonker，ELCE 2008 [幻灯片](http://tree.celinuxforum.org/CelfPubWiki/ELCEurope2008Presentations?action=AttachFile&do=get&target=MischaJonker_ARM11_power_management_CELF_ELC_2008.pdf)和[视频](http://free-electrons.com/pub/video/2008/elce/elce2008-jonker-power-management-arm11.ogv)。

-   [电源管理规范](http://eLinux.org/Power_Management_Specification "Power Management Specification")

-   [静态电源管理规范](http://eLinux.org/Static_Power_Management_Specification "Static Power Management Specification")


## 开源项目/邮件列表

-   [Linux-pm](https://lists.osdl.org/mailman/listinfo/linux-pm) 邮件列表 (和[存档](http://lists.osdl.org/pipermail/linux-pm/)列表 )。
-   在 sourceforge 上的开源项目： [动态电源管理](http://dynamicpower.sourceforge.net)。


[分类](http://eLinux.org/Special:Categories "Special:Categories")：

-   [电源管理](http://eLinux.org/Category:Power_Management "Category:Power Management")
