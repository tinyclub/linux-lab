---
layout: post
author: 'Liu Lichao'
title: "自上而下分析 Linux 设备模型"
top: false
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /linux-device-model/
description: "从字符设备开始，自上而下分析 Linux 设备模型核心实现"
category:
  - Linux 内核
  - 设备驱动
  - 字符设备
tags:
  - device model
  - driver
  - 设备模型
---

> By 法海 of [TinyLab.org][1]
> Sep 29, 2020

## 概述

Linux 驱动开发同学入门时最常见的例子就是“字符设备”驱动。几个简单的 API 就能在 Linux 系统中创建字符设备，在 /dev 目录中创建设备节点。

实例：

    //注册字符设备，主设备号为 MEM_MAJOR，对应的操作函数为 memory_fops
    register_chrdev(MEM_MAJOR, "mem", &memory_fops);
    //创建 class
    mem_class = class_create(THIS_MODULE, "mem");
    //创建设备
    device_create(mem_class, NULL, MKDEV(MEM_MAJOR, 0), NULL, “mem”);

改编自：drivers/char/mem.c

上面 API 函数的背后的原理是什么？本篇文章通过分析 Linux 内核设备模型揭示设备管理的本质。

## 字符设备的本质

基于 Linux 下一切皆文件的设计理念，驱动设备也需要有对应的文件节点，在 Linux 系统中设备类型分为字符设备和块设备两类。

字符设备文件有两个要素：设备号、file_operations。其中，设备号是字符设备文件在系统中的唯一标识，file_operations 对应设备文件各种操作方法。

表示字符设备的数据结构 `struct cdev` 就是上述两个要素的超集:

    struct cdev {
        ...
        const struct file_operations *ops;  ---file_operations
        dev_t dev;             ---  字符设备的起始设备号
        unsigned int count;    ---  子设备号个数
    } __randomize_layout;

注意：`struct cdev` 与设备号的关系是一对多，`cdev.dev` 表示字符设备启动设备号，`cdev.count` 表示子设备号的个数。而 `struct device` 与设备号的关系是一对一。 

比如，当系统插入多个键盘时，他们的底层操作方法相同，没必要创建多个 `struct cdev`，但是他们确实存在多个实例。所以，需要创建多个 `struct device`。这种场景可以把 `struct cdev` 看成 `struct device` 实例的代理。

**cdev 与 device 的关系如下图所示：**

![cdev 与 device 关系](/wp-content/uploads/2020/10/device-model/cdev-vs-device.png)

字符设备注册完成后，系统知道了某段设备号范围内对应的设备的操作方法，但是设备还没有创建。

创建设备的工作通过 `device_create` 完成。

创建设备（`device_create`）需要完成哪些工作：
1. 分配 `struct device` 结构，并初始化，特别是初始化设备号
2. 基于 class/parent 信息，在 sysfs 文件系统创建对应目录及属性文件
3. 创建设备节点
   
   两个途径：1）基于 devtmpfs；2）基于向用户态发送 uevent 信息，udev 程序根据 uevent 信息创建设备节点

4. 如果设备有所属的 bus，尝试 probe

很平常的功能，它的复杂性主要体现在数据结构的抽象。

## 数据结构设计：

### kobject

它是设备模型的基类，可以感性理解为内核中的基本对象。一般被更高级的数据结构包含，比如 device/driver 等。

kobject 实现引用计数，sysfs 导出等功能。

### kset

它是 kobject 的集合，同时一个 kset 也是内核对象，所以它也是一个 kobject。

kset 实现聚合同类 kobject 功能。

### ktype

相同属性的 kobject 拥有相同的 ktype。

为相同 type 的 kobject 提供操作函数（比如 release），为相同 type 的 kobject 定义相同的 sysfs 属性文件。

### 图解 kobject/kset/ktype

![图解 kobject/kset/ktype](/wp-content/uploads/2020/10/device-model/kobject.png)

### 场景

上述概念很抽象，所以要在场景中学习。

#### 设备引用计数实现

`get_device` 实现增加某个 device 的引用计数功能。其底层是通过 kobject 实现的。

    get_device
    -> kobject_get
    --> kref_get
    ---> kref.refcount 加 1

`kobject.kref.refcount` 的数值直接代表了 device 的引用计数。

#### device 资源释放

`put_device` 表示减少某个 device 的引用计数。

    put_device
    -> kobject_put
    --> kref_put
    ---> kref.refcount 减 1
    ----> if (0 == refcount) 
            调用 release 接口

`release` 函数指针是 `kobject_release`。

    kobject_releae
    -> kobject_cleanup
    --> kobject_del   //delete sysfs entry
    ---> ktype->release  //执行 kobject.ktype.release 函数，此处对应 device_release, device_release 完成 device 层的资源释放，同时检查 device 所属 device_type/class 是否有需要释放的资源

#### sysfs_ops 操作 

一个 kobject 对应 sysfs 的一个目录，kobject API 实现中天然包含与 sysfs 文件系统的同步。自然而然，包含 kobject 的<font color='red'>高级数据结构</font>也会在 sysfs 中暴露自己的数据。比如 `struct device` 包含 `struct kobject`，所以在 sysfs 文件系统中有一个目录对应此 `struct device`， 而目录下的文件属于此 `struct kobject` 的属性文件。

创建 device 的过程如下：

    device_create
    -> device_add
    --> kobject_add           //kobject_add 调用 create_dir 创建目录
    ---> device_create_file   //在 kobject_add 好的 dir 中创建设备属性文件

读写这些属性文件需要依赖文件所属的 `kobject.ktype.sysfs_ops` 函数接口集。

sysfs 文件操作进阶阅读：

* [sysfs 读写流程简析](http://tinylab.org/sysfs-read-write/)

#### kset 集合

图解 kobject/kset/ktype 中可以看到 device/driver 都属于某个 kset，kset 自身也是一个内核对象，所以它也是一个 kobject。所以，它在 sysfs 文件系统中也表现为一个目录。

本文开篇字符设备示例代码创建了 mem class，class 就是归类的意思，同一类设备属于同一个 class。比如有很多设备属于 mem class，它们的 kobj.kset = mem_class.kset。

**实例：**

`sys/class/mem` 目录就是 mem class。有一些其它 kobject(device) 属于此 class(即, kset)。

    /sys/class/mem # ls
    full     kmsg     null     random   zero
    kmem     mem      port     urandom

## 中场总结

通过上述描述，我们知道了 `struct cdev`，`struct device` 在内核中的角色位置，也知道了设备模型的基本数据结构。

但是，设备管理还有一个问题：设备与驱动如何匹配？

下面我们着重分析这个问题。

## 驱动与设备

### 驱动开发三部曲

1. 根据硬件修改 dts 文件
2. 配置内核选中对应驱动，或新增内核驱动模块
3. 编译测试

这背后的本质是什么？

### 常见概念

总线、驱动、设备在现实世界中存在。比如 PCIE 总线，USB 总线，I2C 总线。
内核中都有其对应的抽象实现。比如 pci_bus_type, usb_bus_type。

随着 SOC 的流行，一颗 CPU 集成多个控制器，控制器地址固定，于是内核抽象出了 platform 总线来挂载 SOC 内部的各类控制器。

简单图示：

![总线](/wp-content/uploads/2020/10/device-model/Bus.png)

分层结构：

![分层结构](/wp-content/uploads/2020/10/device-model/layers.png)

上面的分层结构设计主要还是基于面向对象的思想，提取最大相同元素为底层数据结构。

### 实例解析

#### platform bus 注册

总线作为管理媒介，必须先注册。platform_bus 在 platform_bus_init 函数中注册。

    platform_bus_init
    -> device_register(&platform_bus)
    -> bus_register(&platform_bus_type)

注：上面的 platform_bus 是一个 device，platform_bus_type 才是真正的 bus。

可以看到先注册 platform_bus 设备，再注册 platform bus（platform_bus_type）。
其中 platform_bus 设备对应 /sys/devices/platform 目录，作为所有 platform_device 的父设备。

**Bus 的本质：**

1. <font color='red'>父亲。</font>platform_bus 设备表示所有 platform device 的父设备。
2. <font color='red'>桥梁。</font>platform_bus_type 承担 platform_bus 总线下设备与驱动的匹配工作。

#### platform device 注册

dts 描述设备硬件组成，被编译成内核可识别的二进制文件。系统启动初期，解析设备树，将设备树描述的设备注册到系统，调用栈如下：

    [    0.768872] [<ffffffff807dc558>] of_device_add+0x58/0x78
    [    0.774181] [<ffffffff807dca9c>] of_platform_device_create_pdata+0x8c/0xa8
    [    0.781056] [<ffffffff807dcbb8>] of_platform_bus_create+0x100/0x1c8
    [    0.787322] [<ffffffff807dccf8>] of_platform_populate+0x78/0xd8
    [    0.793242] [<ffffffff80200498>] do_one_initcall+0x98/0x1c0

重要信息：

1. <font color='red'>这里注册的 platform_device 都属于 platform bus</font>

        of_platform_device_create_pdata
        -> platform_device->dev.bus = &platform_bus_type;

2. <font color='red'>这里注册的 platform_device 会加入到 platform bus 下的设备链表中</font>
   
        of_device_add
        -> device_add
        --> bus_add_device
        ---> klist_add_tail(&dev->p->knode_bus, &bus->p->klist_devices)

#### platform driver 注册

driver 的注册都在具体的驱动模块中实现。只需要一个 platform_driver_register API 函数。

    platform_driver_register(&at91_twi_driver);


重要信息：

1. 驱动注册后，<font color='red'>驱动信息会加入到 platform bus 下的驱动链表中</font>

#### 驱动初始化

设备/驱动均已注册，现在万事具备，只欠东风。谁来调用驱动初始化函数？

驱动最重要的函数是 probe，调用流程如下：

    [    1.343296] [<ffffffff807c0168>] ls_i2c_probe+0x38/0x440
    [    1.348604] [<ffffffff804fa848>] driver_probe_device+0xc8/0x270
    [    1.354528] [<ffffffff804f853c>] bus_for_each_drv+0x64/0xc8
    [    1.360091] [<ffffffff804fac0c>] device_attach+0xac/0xd0
    [    1.365410] [<ffffffff804f8b88>] bus_probe_device+0xa0/0xe0
    [    1.370975] [<ffffffff804f7a2c>] device_add+0x554/0x7c0
    [    1.376197] [<ffffffff807dcaac>] of_platform_device_create_pdata+0x8c/0xa8
    [    1.383071] [<ffffffff807dcbc8>] of_platform_bus_create+0x100/0x1c8
    [    1.389338] [<ffffffff807dcc28>] of_platform_bus_create+0x160/0x1c8
    [    1.395604] [<ffffffff807dcd08>] of_platform_populate+0x78/0xd8
    [    1.401522] [<ffffffff80200498>] do_one_initcall+0x98/0x1c0

可见驱动初始化流程被融合到了设备/驱动注册流程中。

上面的例子是注册设备完成后，通过 `device_attach` 函数扫描总线上注册的驱动是否与当前设备匹配，如果匹配就执行驱动初始化函数。
还有一种情况是注册驱动完成后，通过 `driver_attach` 函数扫描总线上注册的设备是否与当前驱动匹配，如果匹配就执行驱动初始化函数。

**Bus 桥梁作用的体现：**

集合：

`bus->p->klist_devices` 收集总线下设备。

`bus->p->klist_drivers` 收集总线下驱动。

匹配：

`bus->match` 函数会检查设备与驱动是否匹配，不同总线判断方法不同。比如 PCIE 总线是判断 PCIE 设备的 ID 与 PCIE 驱动支持的 id_table 是否匹配，platform 总线是判断 platform_device 的 compatible 字段是否与 platform_driver 的 compatible 匹配。

## 总结

至此，我们看到了设备的本质，设备通过设备号在系统中标识唯一的自己，通过设备号与字符设备数据结构关联，字符设备提供文件操作函数。

在驱动开发中，内核基于硬件世界的概念，抽象出了总线/设备/驱动的概念，设备/驱动都依附在总线上，设备注册或驱动注册完成后主动检查现存的驱动/设备与自己是否匹配，如果匹配就执行驱动的初始化函数。

驱动与设备都是拟人化的概念，在其背后还有 kobj/kset/ktype 等基础数据结构，实现了某些公共功能的抽象，比如引用计数，资源释放等。

设备管理细节很多，不是几篇文章可以涵盖住的，因为解析代码太没意思了，本篇文章主要目的是把设备管理背后的 kobj/kset/ktype 引出来，再稍微说一下设备/驱动 API 背后的原理。希望能对初学者做出方向指导。

[1]: http://tinylab.org
