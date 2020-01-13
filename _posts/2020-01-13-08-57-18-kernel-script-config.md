---
layout: post
author: 'Wu Zhangjin'
title: "通过命令行工具修改内核配置"
draft: false
top: true
license: "cc-by-nc-nd-4.0"
permalink: /kernel-script-config/
description: "大家可能都比较习惯了通过交互式的方式配置内核选项，这里介绍一款命令行的非交互式配置工具。"
category:
  - 内核配置与编译
tags:
  - scripts/config
  - Linux
  - defconfig
  - menuconfig
  - 命令行配置
---

> By Falcon of [TinyLab.org][1]
> Aug 05, 2019

配置 Linux 内核时通常都用 `defconfig` 和 `menuconfig`。

`defconfig` 使用默认配置文件加载配置，`menuconfig` 可以灵活选择和调整某个配置，但是每次都要加载界面，然后翻来翻去找需要的配置，如果提前知道某个配置的名字（可通过 `Kconfig` 代码查看），那么可以用命令行工具来快速修改配置。

这个工具是：`scripts/config`

  * `--file` 指定要配置的文件，默认为 build 目录下的 `.config`
  * `--enable/--disable/--module/--set-str/--set-var/--undefine/--state`，从字面意思就很好理解，用起来也很方便。

更多用法如下：

    $ linux-stable/scripts/config --help
    commands:
	--enable|-e option   Enable option
	--disable|-d option  Disable option
	--module|-m option   Turn option into a module
	--set-str option string
	                     Set option to "string"
	--set-val option value
	                     Set option to value
	--undefine|-u option Undefine option
	--state|-s option    Print state of option (n,y,m,undef)

	--enable-after|-E beforeopt option
                             Enable option directly after other option
	--disable-after|-D beforeopt option
                             Disable option directly after other option
	--module-after|-M beforeopt option
                             Turn option into module directly after other option

	commands can be repeated multiple times

    options:
	--file config-file   .config file to change (default .config)
	--keep-case|-k       Keep next symbols' case (dont' upper-case it)


因为这个是非交互式的，所以很适合做自动化配置和测试，方便灵活批量地调整配置。

以 `FTRACE` 为例，在 Linux Lab 根目录下对内核 output 下的 `.config` 进行配置：

**开启 FTRACE**

    $ linux-stable/scripts/config --file output/aarch64/linux-v5.1-raspi3/.config -e FTRACE
    $ grep FTRACE -ur output/aarch64/linux-v5.1-raspi3/.config
    CONFIG_FTRACE=y

**关闭 FTRACE**

    $ linux-stable/scripts/config --file output/aarch64/linux-v5.1-raspi3/.config -d FTRACE
    $ grep FTRACE -ur output/aarch64/linux-v5.1-raspi3/.config
    # CONFIG_FTRACE is not set

在用 `scripts/config` 配置完以后，需要再执行 `make kernel-olddefconfig` 才能让配置实际生效。

另外需要注意的是，`scripts/config` 并不做依赖检查，如果目标选项依赖的其他选项是禁用的，那么将无法成功开启目标选项。这个时候，需要通过 `make menuconfig` 查找该选项的 depends 项，然后按照依赖顺序依次通过 `scripts/config` 开启才行。

[1]: http://tinylab.org
