---
title: 用 kGDB 调试 Linux 内核
author: Wen Pingbo
album: "Debugging"
layout: post
permalink: /kgdb-debugging-kernel/
tags:
  - Debug
  - KGDB
  - KGDBOC
  - Linux
categories:
  - KGDB
  - 稳定性
  - 内核调试与跟踪
---

> by Pingbo Wen of [TinyLab.org][1]
> 2013/08/11

## 简介

这个文档记录了用 kGDB 调试 Linux 内核的全过程，都是在前人工作基础上的一些总结。以下操作都是基于特定板子来进行，但是大部分都能应用于其他平台。

要使用 KGDB 来调试内核，首先需要修改 config 配置文件，打开相应的配置，配置内核启动参数，甚至修改串口驱动添加 poll 支持，然后才能通过串口远程调试内核。

## 配置内核

### 基本配置

在内核配置文件 `.config` 中，需要打开如下选项：

CONFIG_KGDB | 加入KGDB支持
CONFIG_KGDB_SERIAL_CONSOLE | 使KGDB通过串口与主机通信(打开这个选项，默认会打开CONFIG_CONSOLE_POLL和CONFIG_MAGIC_SYSRQ) 
CONFIG_KGDB_KDB | 加入KDB支持
CONFIG_DEBUG_KERNEL | 包含驱动调试信息
CONFIG_DEBUG_INFO | 使内核包含基本调试信息
CONFIG_DEBUG_RODATA=n | 关闭这个，能在只读区域设置断点

### 可选选项

CONFIG_PANIC_TIMEOUT=5 |
CONFIG_BOOTPARAM_SOFTLOCKUP_PANIC_VALUE=1 |
CONFIG_BOOTPARAM_HUNG_TASK_PANIC_VALUE=1 |
CONFIG_S3C2410_WATCHDOG_ATBOOT=0 |
CONFIG_FRAME_POINTER | 使KDB能够打印更多的栈信息
CONFIG_KALLSYMS | 加入符号信息
CONFIG_KDB_KEYBOARD | 如果是通过目标版的键盘与KDB通信，需要把这个打开，且键盘不能是USB接口
CONFIG_KGDB_TESTS |


### 启动参数

打开相应的选项后，需要配置 kernel 启动参数，使 KGDB 和内核能够找到正确的通信接口。如果是使用串口，则需要配置如下选项：

    console=ttySAC3,115200 kgdboc=ttySAC3,115200


如果需要调试内核的启动过程，则需要在 kgdboc 后面加入 kgdbwait 。

在其他板子上，若使用以太网口来和 KGDB 进行通信，则要把 kgdboc 换成 kgdboe(kgdb over ethernet) ）。

配置完后，就可以正常编译，然后把内核下载到目标板上面。

## 串口驱动修改

如果在内核启动的过程中出现如下错误提示：

    kgdb: Unregistered I/O driver, debugger disabled.


则需要根据这一部分，修改串口驱动程序，若能正常进入 kgdb ，则忽略该节，直接进入下一节使用 KGDB 。

在 `drivers/tty/serial/kgdboc.c` 中的 `configure_kgdboc` 函数，会通过 `tty_find_polling_driver(cptr, &tty_line)` 来找寻内核启动参数中指定的串口驱动。然后通过 `kgdboc_get_char()` 和 `kgdboc_put_char()` 来和主机串口正常通信。

可以看到在 config 配置文件的 `CONFIG_CONSOLE_POLL` 就是使能串口与 kgdboc 的接口。如果 `tty_find_polling_driver` 没有找到对应的串口通信接口，则会调用 `kernel/debug/debug_core.c` 中的 `kgdb_unregister_io_module` 进行错误处理。

有的板子的串口驱动并没有加入对 kgdboc 通信的支持，例如 Samsung 的串口驱动需要在 `drivers/tty/serial/samsung.c` 中手动添加。   添加与 kgdboc 通信的接口，只需添加一个发送函数和接收函数，然后在驱动操作结构体中加入对应的函数就可以了。具体的 PATCH 如下：

    drivers/tty/serial/samsung.c | 22 ++++++++++++++++++++++
    1 files changed, 22 insertions(+), 0 deletions(-)

    diff --git a/drivers/tty/serial/samsung.c b/drivers/tty/serial/samsung.c
    index ff6a4f8..5ceb7d7 100755
    --- a/drivers/tty/serial/samsung.c
    +++ b/drivers/tty/serial/samsung.c
    @@ -893,7 +893,29 @@ static struct console s3c24xx_serial_console;
    #define S3C24XX_SERIAL_CONSOLE NULL
    #endif

    +#ifdef CONFIG_CONSOLE_POLL
    +static void s3c24xx_serial_poll_put_char(struct uart_port *port, unsigned char c)
    +{
    +    while (!(rd_regl(port, S3C2410_UTRSTAT) & S3C2410_UTRSTAT_TXE))
    +       ;
    +
    +    wr_regl(port, S3C2410_UTXH, c);
    +}
    +
    +static int s3c24xx_serial_poll_get_char(struct uart_port *port)
    +{
    +    while (!(rd_regl(port, S3C2410_UTRSTAT) & S3C2410_UTRSTAT_RXDR))
    +        ;
    +
    +    return rd_regl(port, S3C2410_URXH);
    +}
    +#endif
    +
    static struct uart_ops s3c24xx_serial_ops = {
    +#ifdef CONFIG_CONSOLE_POLL
    +    .poll_get_char = s3c24xx_serial_poll_get_char,
    +    .poll_put_char = s3c24xx_serial_poll_put_char,
    +#endif
         .pm = s3c24xx_serial_pm,
         .tx_empty = s3c24xx_serial_tx_empty,
         .get_mctrl = s3c24xx_serial_get_mctrl,
    --
    1.7.5.4


加入这个 patch ，重新编译内核，之后就能正常进入 kgdb 

## gdb 远程调试

如果在内核启动参数中加入了 kgdbwait ，则内核会在完成基本的初始化之后，停留在 kgdb 的调试陷阱中，等待主机的 gdb 的远程连接。

由于大部分的板子只有一个调试串口，所以你需要把之前与串口通信的 minicom 退出来，然后在内核源码的目录下，执行以下命令：

    $ arm-linux-gnueabi-gcc vmlinux
    (gdb) target remote /dev/ttyUSB0
    (gdb) set detach-on-fork on
    (gdb) b panic()
    (gdb) c


当然，你也可以 agent-proxy 来复用一个串口，通过虚拟出两个 TCP 端口。这时候， gdb 就需要用 target remote 命令连接 kgdb ，例如：

    (gdb) target remote localhost:5551


agent-proxy 可这样下载：

    git clone git://git.kernel.org/pub/scm/utils/kernel/kgdb/agent-proxy.git

具体用法，请看该 repo 下的 README 。

在用 gdb 来调试内核的时候，由于内核在初始化的时候，会创建很多子线程。而默认 gdb 会接管所有的线程，如果你从一个线程切换到另外一个线程， gdb 会马上把原先的线程暂停。但是这样很容易导致 kernel 死掉，所以需要设置一下 gdb 。一般用 gdb 进行多线程调试，需要注意两个参数： `follow-fork-mode` 和 `detach-on-fork`。

  * detach-on-fork 参数，指示 GDB 在 fork 之后是否断开（detach）某个进程的调试，或者都交由 GDB 控制： `set detach-on-fork [on|off]`

      * on: 断开调试 `follow-fork-mode` 指定的进程。
      * off: gdb将控制父进程和子进程。

  * follow-fork-mode 指定的进程将被调试，另一个进程置于暂停（suspended）状态。follow-fork-mode 的用法为：`set follow-fork-mode [parent|child]`

      * parent: fork之后继续调试父进程，子进程不受影响。 
      * child: fork之后调试子进程，父进程不受影响。

## 参考资料

  * [gdb user mannual](http://sourceware.org/gdb/current/onlinedocs/gdb/)
  * [gdb internal](http://www.sourceware.org/gdb/onlinedocs/gdbint.html)
  * [kgdb/kdb official website](https://kgdb.wiki.kernel.org/)
  * [kernel debug usage](http://www.kernel.org/doc/htmldocs/kgdb.html)
  * [kdb in elinux.org](http://elinux.org/KDB)
  * [multi-threads debug in gdb](http://www.ibm.com/developerworks/cn/linux/l-cn-gdbmp/)
  * [KGDB.info](http://www.kgdb.info/)


 [1]: http://tinylab.org
