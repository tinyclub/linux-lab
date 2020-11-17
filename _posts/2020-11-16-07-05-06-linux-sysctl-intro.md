---
layout: post
author: 'Wu Daemon'
title: "一文读懂 Linux 内核运行时参数配置"
draft: true
top: false
license: "cc-by-nc-nd-4.0"
permalink: /linux-sysctl-intro/
description: ""
category:
  - Linux 内核接口
  - 调试和优化
tags:
  - Linux
  - Sysctl
  - procfs
  - dropcaches
  - vm
  - 内存管理
---

> By Wu Daemon of [TinyLab.org](http://tinylab.org)
> 2020/11/16

## Linux 内核运行时配置简介

Linux 内核的子系统有各种配置参数，比如内存管理中内存回收的水位信息，CPU 调度中的各种调度器配置信息，文件回写中 dirty page 的配置等。

无需修改内核源码，用户就可以通过 sysctl 命令在运行时设置这些参数。

具体的配置参数可以查看内核文档目录 `Documentation/sysctl/` 下的各个文件。

## sysctl 命令配置举例

比如，设置内存子系统的 `dropcaches` 参数，可使用：

    $ systcl -w vm.drop_caches=1

## sysctl 命令使用了哪些接口

使用 strace 追踪 sysctl 命令的系统调用可发现该命令最终是访问 `/proc/sys/drop_caches` 这个文件。

```
wu@ubuntu:~$ sudo strace sysctl -w vm.drop_caches=1
execve("/sbin/sysctl", ["sysctl", "-w", "vm.drop_caches=1"], [/* 16 vars */]) = 0
brk(NULL)                               = 0x2016000
...
stat("/proc/sys/vm/drop_caches", {st_mode=S_IFREG|0200, st_size=0, ...}) = 0
open("/proc/sys/vm/drop_caches", O_WRONLY|O_CREAT|O_TRUNC, 0666) = 3
fstat(3, {st_mode=S_IFREG|0200, st_size=0, ...}) = 0
write(3, "1\n", 2)                      = 2
close(3)                                = 0
fstat(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 1), ...}) = 0
write(1, "vm.drop_caches = 1\n", 19vm.drop_caches = 1
)    = 19
close(1)                                = 0
close(2)                                = 0
exit_group(0)                           = ?
+++ exited with 0 +++
```

由此就可知，systcl 命令是通过 `/proc/sys/` 目录下的各个接口文件实现配置的。该目录下包含以下子目录：

```
wu@ubuntu:/proc/sys$ tree -L 1
.
├── abi
├── debug
├── dev      # 设备相关信息
├── fs       # 特定的文件系统，比如 fd，inode，dentry，quota tuning
├── kernel   # tuning 全局参数，比如 cpu 调度，printk，softirq，hung_task，numa，watchdog等
├── net      # 网络子系统相关参数，比如 ipv4，ipv6，icmp，igmp 等
└── vm       # tuning 内存管理相关参数，buffer 和 cache 的管理
```

## sysctl 接口暨 procfs 工作流程

那么在内核中各子系统是如何导出这些参数到 procfs，并允许用户通过 echo, cat 等工具操作这些节点来设置参数的呢？

在 `kernel/sysctl.c` 中定义了某个子系统下的某个参数的相关 `ctl_table`，比如 `vm.dropcaches`。

* 先设置 vm 目录的参数，访问权限为 555，并设置 child 属性为 `vm_table`。
* `vm_table` 结构体数组包含了 VM 子系统的参数，比如 `dropcaches` 参数，设置了该节点的访问权限为 644；data 属性值为 `sysctl_drop_caches`，该变量在 `fs/drop_caches.c` 中定义；
* 该节点的读写处理函数 `drop_caches_sysctl_hander`，在 `fs/drop_caches.c` 中实现，通过 `dointvec_minmax` 来读出数据 。
* 最后填充好 `ctl_table` 结构体后在 `sysctl_init` 入口函数注册这些结构体数组。

相关代码如下：

```
/* The default sysctl tables: */
static struct ctl_table sysctl_base_table[] = {
    {
        .procname   = "kernel",      //  /proc/sys/kernel
        .mode       = 0555,
        .child      = kern_table,
    },
    {
        .procname   = "vm",          //  /proc/sys/vm
        .mode       = 0555,
        .child      = vm_table,
    },
    {
        .procname   = "fs",          //  /proc/sys/fs
        .mode       = 0555,
        .child      = fs_table,
    },
    {
        .procname   = "debug",       //  /proc/sys/debug
        .mode       = 0555,
        .child      = debug_table,
    },
    {
        .procname   = "dev",         //  /proc/sys/dev
        .mode       = 0555,
        .child      = dev_table,
    },
    { }
};

static struct ctl_table vm_table[] = {
    ...
    {
        .procname   = "drop_caches",
        .data       = &sysctl_drop_caches,
        .maxlen     = sizeof(int),  //    vm.drop_caches 变量4各字节
        .mode       = 0644,         //    /proc/sys/vm/drop_caches访问权限"644"
        .proc_handler   = drop_caches_sysctl_handler, //     handler
        .extra1     = &one,
        .extra2     = &four,
    },
    ...
};

int __init sysctl_init(void)
{
    struct ctl_table_header *hdr;

    // 注册 ctl_table
    hdr = register_sysctl_table(sysctl_base_table);
    kmemleak_not_leak(hdr);

    return 0;
}

int drop_caches_sysctl_handler(struct ctl_table *table, int write,
    void __user *buffer, size_t *length, loff_t *ppos)
{
    int ret;

    ret = proc_dointvec_minmax(table, write, buffer, length, ppos);
    if (ret)
        return ret;
    if (write) {               // 如果是写数据
        static int stfu;

        if (sysctl_drop_caches & 1) { // 如果 drop_caches=1 则清 pagecache
            iterate_supers(drop_pagecache_sb, NULL);
            count_vm_event(DROP_PAGECACHE);
        }
        if (sysctl_drop_caches & 2) { // 如果 drop_caches=2 则清 pagecache 和 slab
            drop_slab();
            count_vm_event(DROP_SLAB);
        }
        if (!stfu) {
            pr_info("%s (%d): drop_caches: %d\n",
                current->comm, task_pid_nr(current),
                sysctl_drop_caches);
        }
        stfu |= sysctl_drop_caches & 4;
    }
    return 0;
}

```

通过上述分析，大致梳理了 sysctl 接口在 kernel 中运行的大致流程。

## 如何新增一个 sysctl 接口

接下来，学以致用，我们可以在 `/proc/sys` 这个根目录下写一个 `my_sysctl` 的节点，首先定义并填充 `ctl_table` 结构体，并通过 `register_sysctl_table` 注册到系统。

```
#include <linux/kernel.h>
#include <linux/mutex.h>
#include <linux/sysctl.h>

static int data;
static struct ctl_table_header * my_ctl_header;

int my_sysctl_callback(struct ctl_table *table, int write,void __user *buffer, size_t *lenp, loff_t *ppos)
{
        int rc = proc_dointvec(table, write, buffer, lenp, ppos);

        if (write) {
            printk("write operation,cur data=%d\n",*((unsigned int*)table->data));
        }
}

/* The default sysctl tables: */
static struct ctl_table my_sysctl_table[] = {
 {
     .procname   = "my_sysctl",
     .mode       = 0644,
     .data       = &data,
     .maxlen         = sizeof(unsigned int),
     .proc_handler   = my_sysctl_callback,
  },
  {

  },
};

static int __init sysctl_test_init(void)
{
    printk("sysctl test init...\n");

    my_ctl_header = register_sysctl_table(my_sysctl_table);

    return 0;
}

static void __exit sysctl_test_exit(void)
{
    printk("sysctl test exit...\n");

    unregister_sysctl_table(my_ctl_header);
}
```

通过 qemu 进入目标文件系统，使用 insmod 注册驱动，在 `/proc/sys` 目录下出现 `my_sysctl` 节点，此时就可以通过 `cat/echo` 命令向该节点读写数据，也可以直接通过 systcl 设置该参数。

```
/mnt # insmod sysctl_test.ko
[   89.904485] sysctl test init...

/mnt # sysctl my_sysctl
my_sysctl = 0

/mnt # sysctl -w  my_sysctl=2
[  151.278213] write operation,cur data=2

/mnt # sysctl my_sysctl
my_sysctl = 2
/mnt # cat /proc/sys/my_sysctl
2
```

为简便起见，大家也可以直接用 Linux Lab 来快速开展实验，具体可以参考 [Linux Lab 文档的 4.1.2 节](https://gitee.com/tinylab/linux-lab#412-%E4%BD%BF%E7%94%A8%E5%86%85%E6%A0%B8%E6%A8%A1%E5%9D%97)。
