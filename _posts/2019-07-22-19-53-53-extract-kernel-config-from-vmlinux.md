---
layout: post
author: 'Wu Zhangjin'
title: "探索从 vmlinux 中抓取 Linux 内核 config 文件"
draft: false
license: "cc-by-nc-nd-4.0"
album: "Debugging+Tracing"
permalink: /extract-kernel-config-from-vmlinux/
description: "如果编译 Linux 内核时打开了 CONFIG_IKCONFIG 选项，那么没有原始的 .config 文件，我们也可以从 vmlinux 中抓取出来，方法是 scripts/extract-ikconfig"
category:
  - 内核配置与编译
  - 内核调试与跟踪
tags:
  - extract-ikconfig
  - vmlinux
  - /proc/config.gz
  - Linux
  - CONFIG_IKCONFIG
  - Shell
---

> By Falcon of [TinyLab.org][1]
> Jul 18, 2019

## 背景简介

最近两周在忙活 [Linux Lab](/linux-lab) V0.2 RC1，其中一个很重要的目标是添加国产龙芯处理器支持。

在添加龙芯 ls2k 平台的过程中，来自龙芯的张老师已经准备了 vmlinux 和 dtb，还需要添加配置文件和源代码，但源码中默认的配置编译完无法启动，所以需要找一个可复用的内核配置文件。

在张老师准备的内核 vmlinux 中，确实有一个 `/proc/config.gz`，说明内核配置文件已经编译到内核了，但是由于内核没有配置 nfs，尝试了几次没 dump 出来。

当然，其实也可以用 `zcat /proc/config.gz` 打印到控制台，然后再复制出来，这个时候要把控制台的 scrollback lines 设置大一些，但是没那么方便。

## 极速体验

这里讨论另外一个方法，这是张老师分享的一个小技巧，那就是直接用 Linux 内核源码下的小工具：`script/extract-ikconfig`。

    $ cd /path/to/linux-kernel
    $ scripts/extract-ikconfig /path/to/vmlinux

执行完的结果跟 zcat 一致，需要保存到文件，可以这样：

    $ scripts/extract-ikconfig /path/to/vmlinux > kconfig

需要注意的是，这个前提是配置内核时要开启 `CONFIG_IKCONFIG` 选项。而如果要拿到 `/proc/config.gz`，还得打开 `CONFIG_IKCONFIG_PROC`。

## 原理分析

大概的原理我们来剖析一下。

**Makefile**

  初始化 `KCONFIG_CONFIG`：

    KCONFIG_CONFIG ?= .config

**kernel/Makefile**

  把 `.config` 用 gzip 压缩了一份，放到了 `kernel/config_data.gz`：

    $(obj)/configs.o: $(obj)/config_data.gz

    targets += config_data.gz
    $(obj)/config_data.gz: $(KCONFIG_CONFIG) FORCE
    	$(call if_changed,gzip)

**kernel/configs.c**

  把 `kernel/config_data.gz` 放到 `.rodata` section，并在前后加了字符串标记：`IKCFG_ST` 和 `IKCFG_ED`：

    /*
     * "IKCFG_ST" and "IKCFG_ED" are used to extract the config data from
     * a binary kernel image or a module. See scripts/extract-ikconfig.
     */
    asm (
    "       .pushsection .rodata, \"a\"             \n"
    "       .ascii \"IKCFG_ST\"                     \n"
    "       .global kernel_config_data              \n"
    "kernel_config_data:                            \n"
    "       .incbin \"kernel/config_data.gz\"       \n"
    "       .global kernel_config_data_end          \n"
    "kernel_config_data_end:                        \n"
    "       .ascii \"IKCFG_ED\"                     \n"
    "       .popsection                             \n"
    );

**scripts/extract-ikconfig**

  通过 `grep -abo` 去找到 kconfig data 的位置。`-abo` 的意思是：`-a` 把二进制文件当 text 处理，`-b` 打印字节偏移，`-o` 只打印要匹配的字符串：

    dump_config()
    {
            if      pos=`tr "$cf1\n$cf2" "\n$cf2=" &lt; "$1" | grep -abo "^$cf2"`
            then
                    pos=${pos%%:*}
                    tail -c+$(($pos+8)) "$1" | zcat &gt; $tmp1 2&gt; /dev/null
                    if      [ $? != 1 ]
                    then    # exit status must be 0 or 2 (trailing garbage warning)
                            cat $tmp1
                            exit 0
                    fi
            fi
    }

  这个脚本写得有点晦涩，大体意思是先找到 "IKCFG_ST"，算出 kconfig data 位置，再用 tail 取出来。


## 换个思路

我们自己换个更清晰的思路。

先看看 vmlinux 和 `kernel/config_data.gz` 的布局：

    "IKCFG_ST           .....         IKCFG_ED"             --> vmlinux
             ^ kernel/config_data.gz ^                      --> kernel/config_data.gz

首先，找出 `IKCFG_ST` 和 `IKCFG_ED` 的位置。然后换算出 `kernel/config_data.gz` 的前后位置：

    $ egrep -abo "IKCFG_ST|IKCFG_ED" boards/loongson/ls2k/bsp/kernel/v3.10/vmlinux 
    14508864:IKCFG_ST
    14529536:IKCFG_ED

`kernel/config_data.gz` 的起始地址需要加上 "IKCFG_ST" 的长度，即 `+8`：`$((14508864+8))`，而结束地址刚好是 "IKCFG_ED" 的地址 `-1`：`$((14529536-1))`，总的 size 是：

    $ echo $(((14529536-1) - (14508864+8) + 1))
    20664

这样，我们就可以用 `dd` 命令截取出来：

    $ dd if=boards/loongson/ls2k/bsp/kernel/v3.10/vmlinux bs=1 skip=$((14508864+8)) count=20664 of=kconfig.gz
    $ file kconfig.gz
    kconfig.gz: gzip compressed data, max compression, from Unix
    $ zcat kconfig.gz

完美！逻辑上更清晰，基于这个逻辑改写了一个自己的 `extract-ikconfig`，见 Linux Lab 下的 [tools/kernel/extract-ikconfig](https://gitee.com/tinylab/linux-lab/blob/next/tools/kernel/extract-ikconfig)。

## 小结

小技巧，大道理！

上述探索涉及到内联汇编，涉及到如何把一个文件嵌入到内核执行文件中，涉及到如何解析二进制文件并截取想要的内容。

回到这个技巧本身，也不失为 Debugging 的一个必备技能，内核配置文件对于复现问题，找到问题现场必不可少！

再来总结一下：

- 编译内核时，打开 `CONFIG_IKCONFIG` 和 `CONFIG_IKCONFIG_PROC`。
- 从 Runtime 内核中抓取：`zcat /proc/config.gz`，如果找不到了 vmlinux，这个不失为一个好方法。
- 从静态内核 vmlinux 中抓取：`scripts/extract-ikconfig /path/to/vmlinux`。

[1]: http://tinylab.org
