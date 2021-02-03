# 如何给libvirt 添加一个新API 接口(一)
    作者：高承博  金琦  刘唐
---
layout: post
author: 'Gao Chengbo'
title: "一文介绍了如何给礼拜libvirt添加一个新的命令"
top: false
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /libvirt/
description: "本文介绍了如何给libvirt添加一个新的virsh命令，也介绍了添加一个RPC调用，libvirt需要。"
category:
  - Qemlibvirtu
  - 虚拟化

tags:
  - libvirt
---

>
> By 高承博 金琦 刘唐 of [TinyLab.org](http://tinylab.org)
> 2020/01/01
>

## libvirt 简介
libvirt是用于管理虚拟化平台的开源的API，后台程序和管理工具。它对上层云管平台提供一套API 接口，libvirt也自带了一个virsh 工具可以用来控制虚机的生命周期，创建、删除、修改虚机。
本文中使用的libvirt版本为4.0.0。
    

## libvirt的 API的增添
目前libvirt已经提供了强大的API支持，但由于云上环境比较复杂，有时需要新定义一个libvirt API 接口。由于每添加一个API接口几乎就要添加一个新的RPC 调用的，所以添加的文件非常多。笔者已经添加了好几个新的API 接口，但每次总以为自己能够把所有文件都记住而没有记笔记，但事实证明好脑瓜不如烂笔头。

增添一个cmdHelloWorld 为例，总共包括以下步骤：
1、virsh 命令的添加
2、API 接口的添加
3、RPC 的添加
    
由于添加API的接口的步骤过长，本文我们先给大家介绍如何添加一个新的virsh 命令。

## 增添一个virsh 命令
    所有的virsh 命令的相应函数及其后接的命令行参数都是在virsh-domain.c 中。
    virsh 命令是指virsh 后面跟的第一个命令行参数。本文我们以virsh helloworld为例教大家如何添加一个helloworld命令。

### 增添helloworld 函数cmdHelloWorld
    命令的响应函数是cmdHelloWorld。也就是执行virsh helloworld 后将调用的函数。这个函数由virsh 进程调用，最终调用cmdHelloWorld。cmdHelloWorld 再调用RPC 与计算结点的守护进程libvirtd 交互。
### 增添的命令行参数
virsh helloworld 后我们设置了一下几个命令行参数：
--local：表示与本地的libvirtd 相连。
libvirt 描述命令行参数是用vshCmdOptDef 数组表示，也就是--local 要添加到vshCmdOptDef 数组中。
virsh helloworld --help 要显示的信息添加到vshCmdInfo 数组中。
    
#### 增添的数据结构vshCmdOptDef 和 vshCmdInfo
vshCmdOptDef opts_helloworld[]：表示的是virsh helloworld 后要接的两个命令行参数的描述，本例程中有两个--local 和--ip。因此opts_create[] 数组中应该只有两项。
vshCmdInfo info_helloworld[]: 是virsh helloworld --help 所显示的描述打印。

    static const vshCmdInfo info_helloworld[] = {
      {.name = "help",
      .data = N_("Print Hello World")
      },
      {.name = "desc",
      .data = N_("Print Hello World.")
      },
      {.name = NULL}
    };
    static const vshCmdOptDef opts_helloworld[] = {
      {.name = "local",
      .type = VSH_OT_BOOL,
      .help = N_("print Hello World in local.")
      },
      {.name = NULL}
    };

#### cmdHelloWorld 实现
为了让示例程序最简单化，我们把virsh helloworld 的工作就是打印hello world字符串。

    static bool
    cmdHelloWorld(vshControl *ctl, const vshCmd *cmd)
    {
      bool ret = false;
      char *buffer;

      if (!vshCommandOptBool(cmd, "local"))
        goto cleanup;

      vshPrintExtra(ctl, _("Hello World\n")); 

      ret = true;

    cleanup:

      return ret;
    }
    
#### 把helloworld 命令添加进vshCmdDef domManagementCmds[] 中
virsh 命令的命令行和处理函数都要注册到domManagementCmds[] 中。我们把刚刚添加的数据结构vshCmdOptDef、vshCmdInfo 还有处理函数cmdHelloWorld 添加到domManagementCmds[] 中。

    const vshCmdDef domManagementCmds[] = {
      ...
      {.name = "helloworld",
       .handler = cmdHelloWorld,
       .opts = opts_helloworld,
       .info = info_helloworld,
       .flags = 0
      },
      ...
    }

## 编译调试libvirt 的一些技巧
centos 佩带的libvirt 的src.rpm 包的编译使用的是spec 文件, 执行rpmbuild -ba libvirt.spec 的时候会把配置、编译一气合成。但当我们对自己修改的libvirt 代码配置的时候，最好不要用centos 的spec里的配置，如果按照spec里的配置，在启动我们的libvirtd的时候还要先执行systemctl stop libvirtd 把系统的libvirtd的进程停掉。

所以下面介绍一下我自己的配置和调试libvirt 的技巧。

### 配置、编译和安装过程
配置不加任何参数：

    .configure

编译就不用多说了：

    make -j 50

后面这步很重要，每次编译后，都要重新卸载再进行安装，否则新编译的代码可能不会出现在libvirtd当中。

    make uninstall
    make install

### 手动启动libvirtd
libvirtd 是一个libvirt 的守护进程，libvirt 的API 接口几乎都是通过RPC 调用链接到libvirtd。virsh 命令就像一个client 端，libvirtd 是服务端，virsh 的执行需要依靠libvirtd。所以我们需要把libvirtd 手动的拉起来。

    ./daemon/libvirtd&

### 使用的virsh 文件的路径
使用./tools/.libs/virsh 命令行执行。注意，用gdb 跟踪时使用./tools/.libs/virsh，不要使用./tools/virsh，因为./tools/virsh是个脚本。

## 执行结果
执行结果如下：
![alt figure1](D:\tinylab\tinylab.org\wp-content\uploads\2021\1\libvirt\figure1.png)

