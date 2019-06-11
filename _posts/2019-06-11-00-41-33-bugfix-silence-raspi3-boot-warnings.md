---
layout: post
author: 'Wu Zhangjin'
title: "bugfix: 消除 qemu/raspi3 启动过程的一堆警告"
draft: true
license: "cc-by-sa-4.0"
album: "Debugging+Tracing"
permalink: /bugfix-silence-raspi3-boot-warnings/
description: "Linux Lab 已经支持 aarch64/raspi3，但是启动过程有一些警告，这里介绍如何临时关闭这些 warnings。"
category:
  - Linux Lab
  - 调试技巧
tags:
  - qemu
  - raspi3
  - objdump
  - addr2line
  - git blame
  - calltrace
  - WARN_ON
---

> By Falcon of [TinyLab.org][1]
> Jun 11, 2019

前段时间为 [Linux Lab](/linux-lab) 添加了 aarch64/raspi3 开发板支持，不过有非常多的关于 clock 和 uart 相关的 warnings，影响使用，所以需要想办法消除。

每条 warning 都有 backtrace，所以正好可以用 [如何快速定位 Linux Panic 出错的代码行](http://tinylab.org/find-out-the-code-line-of-kernel-panic-address/) 中的方法定位到出问题的代码，然后关闭掉这些 warning。

恰好前段时间，我们把定位问题的方法进行了脚本化，避免每次都要一步一步去执行，很浪费时间。

这个脚本是：[tools/kernel/calltrace-helper.sh](https://github.com/tinyclub/linux-lab/blob/master/tools/kernel/calltrace-helper.sh)，在这之上，为 Linux Lab 添加了一个 `calltrace` 目标，给这个目标传递一个 `lastcall` 参数即可快速获得相应的结果。

下面介绍具体过程。

首先，需要确保打开相应的内核调试支持。

    $ make f f=debug

这条命令会打开 Linux Lab 的内核调试 feature，其实也是简单的打开 "feature/linux/core/debug/config" 中列举的内核配置选项。

接着，让配置生效并重新编译内核生成支持调试并且带符号版本的内核。

    $ make kernel-olddefconfig
    $ make kernel

之后，启动内核，获取内核启动过程中 warnings 的 backtrace。

    $ make boot | tee raspi3.boot.log

查看日志发现有类似这样的 calltrace：

    ...
    Call trace:
    uart_get_baud_rate+0xe8/0x180
    pl011_set_termios+0x60/0x348
    uart_change_speed.isra.3+0x4c/0x100
    uart_set_termios+0x7c/0x158
    tty_set_termios+0x164/0x1e8
    set_termios+0x2d4/0x3d0
    tty_mode_ioctl+0x5bc/0x608
    n_tty_ioctl_helper+0x54/0x168
    n_tty_ioctl+0x54/0x1d0
    tty_ioctl+0x214/0xae0
    do_vfs_ioctl+0xb0/0x840
    ksys_ioctl+0x50/0x98
    __arm64_sys_ioctl+0x28/0x38
     el0_svc_common.constprop.0+0x8c/0x110
    el0_svc_handler+0x70/0x90
    el0_svc+0x8/0xc

上面是其中一笔警告，以这笔为例接下来介绍如何“一键”定位，首先找到 `lastcall`，这里是 "uart_get_baud_rate+0xe8/0x180"，然后：

    $ make calltrace lastcall=uart_get_baud_rate+0xe8/0x180 | tee uart.warning.log

另外一笔：

    $ make calltrace lastcall=clk_core_enable+0xc8/0x2a0 | tee clk.warning.log

结果大概是这个样子：

    func: uart_get_baud_rate addr: ffffff80103c3f00
    offset: 0xe8 len: 0x180
    prefix: ffffff real: 80103c3f00
    start: ffffff80103c3f00 stop: ffffff80103C4080 err: ffffff80103C3FE8

    [ addr2line ]:

    /labs/linux-lab/linux-stable/drivers/tty/serial/serial_core.c:470 (discriminator 1)

    [   objdump ]:

    	for (try = 0; try < 2; try++) {
    ffffff80103c3fe4:	34000234 	cbz	w20, ffffff80103c4028 <uart_get_baud_rate+0x128>
    /labs/linux-lab/linux-stable/drivers/tty/serial/serial_core.c:470 (discriminator 1)
    							max - 1, max - 1);
    		}
    	}
    	/* Should never happen */
    	WARN_ON(1);
    ffffff80103c3fe8:	d4210000 	brk	#0x800
    /labs/linux-lab/linux-stable/drivers/tty/serial/serial_core.c:471 (discriminator 1)
    	return 0;
    ffffff80103c3fec:	52800000 	mov	w0, #0x0                   	// #0
    /labs/linux-lab/linux-stable/drivers/tty/serial/serial_core.c:472
    }
    ffffff80103c3ff0:	a94153f3 	ldp	x19, x20, [sp, #16]
    ffffff80103c3ff4:	a9425bf5 	ldp	x21, x22, [sp, #32]
    ffffff80103c3ff8:	a94363f7 	ldp	x23, x24, [sp, #48]

    [      gdb  ]:

    Reading symbols from /labs/linux-lab/output/aarch64/linux-v5.1-raspi3/vmlinux...done.
    0xffffff80103c3fe8 is in uart_get_baud_rate (/labs/linux-lab/linux-stable/drivers/tty/serial/serial_core.c:470).
    465					tty_termios_encode_baud_rate(termios,
    466								max - 1, max - 1);
    467			}
    468		}
    469		/* Should never happen */
    470		WARN_ON(1);
    471		return 0;
    472	}
    473
    474	EXPORT_SYMBOL(uart_get_baud_rate);

    [ git blame ]:

    /labs/linux-lab/linux-stable /labs/linux-lab
    16ae2a87 drivers/serial/serial_core.c (Alan Cox 2010-01-04 16:26:21 +0000 470) WARN_ON(1);

    commit 16ae2a877bf4179737921235e85ceffd7b79354f
    Author: Alan Cox <alan@linux.intel.com>
    Date:   Mon Jan 4 16:26:21 2010 +0000

        serial: Fix crash if the minimum rate of the device is > 9600 baud

        In that situation if the old rate is invalid and the new rate is invalid
        and the chip cannot do 9600 baud we report zero, which makes all the
        drivers explode.

        Instead force the rate based on min/max

        Signed-off-by: Alan Cox <alan@linux.intel.com>
        Signed-off-by: Greg Kroah-Hartman <gregkh@suse.de>

    diff --git a/drivers/serial/serial_core.c b/drivers/serial/serial_core.c
    index fa4f170..7f28307 100644
    --- a/drivers/serial/serial_core.c
    +++ b/drivers/serial/serial_core.c
    @@ -385,13 +385,20 @@ static void uart_shutdown(struct uart_state *state)
     		}

     		/*
    -		 * As a last resort, if the quotient is zero,
    -		 * default to 9600 bps
    +		 * As a last resort, if the range cannot be met then clip to
    +		 * the nearest chip supported rate.
     		 */
    -		if (!hung_up)
    -			tty_termios_encode_baud_rate(termios, 9600, 9600);
    +		if (!hung_up) {
    +			if (baud <= min)
    +				tty_termios_encode_baud_rate(termios,
    +							min + 1, min + 1);
    +			else
    +				tty_termios_encode_baud_rate(termios,
    +							max - 1, max - 1);
    +		}
     	}
    -
    +	/* Should never happen */
    +	WARN_ON(1);
     	return 0;
     }

这个 calltrace-helper.sh 不仅把 addr2line, gdb 和 objdump 的结果全部展示出来了，也直接调用 git blame 把出错位置的相关代码修改记录 dump 出来了，这个对于接下来分析问题很有帮助。

后面分析是 qemu 没有支持 BCM2835 CPRMAN 相关的 clock 管理模块，导致相关代码执行不正确，但是并没有影响 raspi3 的基本功能使用，所以直接注释掉相应的 warnings 部分即可。

    $ cd boards/aarch64/raspi3/patch/linux/v5.1/0000-qemu/
    $ cat 0000-qemu-keep-quiet-for-the-clk-and-baurdrate-warning.patch
    diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
    index 96053a9..5615649 100644
    --- a/drivers/clk/clk.c
    +++ b/drivers/clk/clk.c
    @@ -886,8 +886,7 @@ static int clk_core_enable(struct clk_core *core)
     	if (!core)
     		return 0;

    -	if (WARN(core->prepare_count == 0,
    -	    "Enabling unprepared %s\n", core->name))
    +	if (core->prepare_count == 0)
     		return -ESHUTDOWN;

     	if (core->enable_count == 0) {
    diff --git a/drivers/tty/serial/serial_core.c b/drivers/tty/serial/serial_core.c
    index 351843f..b414235 100644
    --- a/drivers/tty/serial/serial_core.c
    +++ b/drivers/tty/serial/serial_core.c
    @@ -467,7 +467,7 @@ static void uart_shutdown(struct tty_struct *tty, struct uart_state *state)
     		}
     	}
     	/* Should never happen */
    -	WARN_ON(1);
    +	// WARN_ON(1);
     	return 0;
     }


回过头来，对于 warning 而言，如果只是找到出错的代码行，实际上不需要这么复杂，因为 `WARN_ON` 本身已经打印了代码所在文件和行了:

    [    2.324287] WARNING: CPU: 3 PID: 45 at drivers/clk/clk.c:890 clk_core_enable+0xc8/0x2a0
    [    4.872552] WARNING: CPU: 1 PID: 1 at drivers/tty/serial/serial_core.c:470 uart_get_baud_rate+0xe8/0x180

`WARN_ON` 的打印方法类似 `BUG()`：

    printk("BUG: failure at %s:%d/%s()!\n", __FILE__, __LINE__, __func__); \

在预处理的时候就已经把文件名和代码所在行的信息加进去了，这个方法也可以用到日常调试中。查看预处理结果可以这样：

    $ make kernel-run drivers/tty/serial/serial_core.i

当然，对于代码本身没法获取类似信息或者没法预测类似情况的异常，这里的 `calltrace-helper.sh` 就非常有帮助。除了在 Linux Lab 中学习如何使用，也可以直接把 `calltrace-helper.sh` 用到日常开发调试中。

[1]: http://tinylab.org
