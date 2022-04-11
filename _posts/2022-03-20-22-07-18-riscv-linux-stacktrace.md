---
layout: post
author: 'Jeff Zhao'
title: "RISC-V Linux Stacktrace 详解"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /riscv-stacktrace/
description: "本文详细介绍了 RISC-V Linux 内核的 Stack Tracing 原理并分析了其代码实现。"
category:
  - 开源项目
  - Risc-V
  - StackTrace
tags:
  - Linux
  - RISC-V
  - 函数调用
  - dump_stack
---


> Author:  jeff.zhao <305149519@qq.com>
> Date:    2022/03/20
> Project: [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux)

## 简介

说起内核的 `stack`，我们应该会想到 `dump_stack` 这个内核函数，我们经常会用这个函数来调试自己的驱动，可以快速的厘清内核的函数调用关系，可以通过 `echo l > /proc/sysrq-trigger` 调用 `dump_stack`，我这里是编写了一个内核驱动程序调用 `dump_stack` 的打印(<u>**x86_64**</u>)如下：

```
[ 2635.264457] test dumpstack
[ 2635.264457] CPU: 0 PID: 895 Comm: insmod Tainted: G           O      5.7.19 #1
[ 2635.264457] Hardware name: Red Hat KVM, BIOS 1.13.0-2.module+el8.4.0+534+4680a14e 04/01/2014
[ 2635.264457] Call Trace:
[ 2635.264457]  dump_stack+0x50/0x70
[ 2635.264457]  ? 0xffffffffc0005000
[ 2635.264457]  ofcd_init+0x11/0x1000 [zjp_dump_stack]
[ 2635.264457]  do_one_initcall+0x41/0x1e0
[ 2635.264457]  ? free_vmap_area_noflush+0x8d/0xe0
[ 2635.264457]  ? _cond_resched+0x10/0x20
[ 2635.264457]  ? kmem_cache_alloc_trace+0x33/0x1b0
[ 2635.264457]  do_init_module+0x55/0x200
[ 2635.264457]  load_module+0x22f3/0x24c0
[ 2635.264457]  ? __do_sys_finit_module+0xba/0xe0
[ 2635.264457]  __do_sys_finit_module+0xba/0xe0
[ 2635.264457]  do_syscall_64+0x43/0x140
[ 2635.264457]  entry_SYSCALL_64_after_hwframe+0x44/0xa9
[ 2635.264457] RIP: 0033:0x7fae79c1276d
[ 2635.264457] Code: 00 c3 66 2e 0f 1f 84 00 00 00 00 00 90 f3 0f 1e fa 48 89 f8 48 89 f7 48 89 d6 48 89 ca 4d 89 c2 4d 89 c8 4c 8b 4c 24 08 0f 05 <48> 3d 01 f0 ff ff 73 01 c3 48 8b 0d f3 36 0d 00 f7 d8 64 89 01 48
[ 2635.264457] RSP: 002b:00007ffc65640e98 EFLAGS: 00000246 ORIG_RAX: 0000000000000139
[ 2635.264457] RAX: ffffffffffffffda RBX: 000055b0bff974a0 RCX: 00007fae79c1276d
[ 2635.264457] RDX: 0000000000000000 RSI: 000055b0be325358 RDI: 0000000000000003
[ 2635.264457] RBP: 0000000000000000 R08: 0000000000000000 R09: 00007fae79ce9580
[ 2635.264457] R10: 0000000000000003 R11: 0000000000000246 R12: 000055b0be325358
[ 2635.264457] R13: 0000000000000000 R14: 000055b0bff97480 R15: 0000000000000000
```

从上面的打印我们可以清晰看出，通过系统调用最后在执行 `ofcd_init` 函数(zjp_dump_stack 模块)，通过这个 `dump_stack` 可以很快速清晰了解我们驱动函数的调用关系，那下面我们来看看它是如何实现的？

如果我们想了解这两个函数之前需要先知道 RISC-V 的一些通用寄存器，函数的具体实现暂且放下，先了解一下 RISC-V 的通用寄存器

## 通用寄存器组

| 寄存器  | ABI 名字 | 描述                                                         | Saver  |
| ------- | -------- | ------------------------------------------------------------ | ------ |
| x0      | zero     | 硬件连线0                                                    | -      |
| x1      | ra       | 返回地址                                                     | Caller |
| x2      | sp       | 栈指针                                                       | Callee |
| x3      | gp       | 全局指针                                                     | -      |
| x4      | tp       | 线程指针                                                     | -      |
| x5-x7   | t0-t2    | 临时寄存器                                                   | Caller |
| x8      | s0/fp    | 保存的寄存器/帧指针                                          | Callee |
| x9      | s1       | 保存寄存器 保存原进程中的关键数据， 避免在函数调用过程中被破坏 | Callee |
| x10-x11 | a0-a1    | 函数参数/返回值                                              | Caller |
| x12-x17 | a2-a7    | 函数参数                                                     | Caller |
| x18-x27 | s2-s11   | 保存寄存器                                                   | Callee |
| x28-x31 | t3-t6    | 临时寄存器                                                   | Caller |

![RISC-V Instructions](/wp-content/uploads/2022/03/riscv-linux/images/riscv_stacktrace/riscv_instructions.jpg)

### 函数调用时保留的寄存器

被调用函数一般不会使用这些寄存器，即便使用也会提前保存好原值，可以信任。这些寄存器有：sp, gp, tp 和 s0-s11 寄存器。

### 函数调用时不保存的寄存器

有可能被调用函数使用更改，需要 caller 在调用前对自己用到的寄存器进行保存。这些寄存器有：参数与返回地址寄存器 a0-a7，返回地址寄存器 ra，临时寄存器 t0-t6，我们在栈回溯的时候必须知道 sp、pc、ra 这三个，当然如果我们在编译内核的时候打开了 `CONFIG_FRAME_POINTER` , 我们可以知道每个函数帧的地址 fp 更方便，废话说来这么多，我们直接看代码到底是如何实现的吧

## RISC-V 实现分析

查看内核代码 `dump_stack`，简化 `dump_stack` 函数如下：

```
dump_stack
  --> __dump_stack
```

可以看到主要是两个关键的函数

```
static void __dump_stack(void)
{
	dump_stack_print_info(KERN_DEFAULT);
	show_stack(NULL, NULL);
}
```

我们来看一下这两个函数

### **dump_stack_print_info**

```
void dump_stack_print_info(const char *log_lvl)
{
	printk("%sCPU: %d PID: %d Comm: %.20s %s%s %s %.*s\n",
	       log_lvl, raw_smp_processor_id(), current->pid, current->comm,
	       kexec_crash_loaded() ? "Kdump: loaded " : "",
	       print_tainted(),
	       init_utsname()->release,
	       (int)strcspn(init_utsname()->version, " "),
	       init_utsname()->version);

	if (dump_stack_arch_desc_str[0] != '\0')
		printk("%sHardware name: %s\n",
		       log_lvl, dump_stack_arch_desc_str);

	print_worker_info(log_lvl, current);
}
```

这一部分主要是打印 print info 的信息，其中关键的部分就是这个代码

```
	printk("%sCPU: %d PID: %d Comm: %.20s %s%s %s %.*s\n",
	       log_lvl, raw_smp_processor_id(), current->pid, current->comm,
	       kexec_crash_loaded() ? "Kdump: loaded " : "",
	       print_tainted(),
	       init_utsname()->release,
	       (int)strcspn(init_utsname()->version, " "),
	       init_utsname()->version);
```

current 是当前的 task，分别会打印 `log_level, CPU id, pid, command, kernel taint state, kernel version`, 其中 `print_tainted` 函数

 ```
const struct taint_flag taint_flags[TAINT_FLAGS_COUNT] = {
	[ TAINT_PROPRIETARY_MODULE ]	= { 'P', 'G', true },
	[ TAINT_FORCED_MODULE ]		= { 'F', ' ', true },
	[ TAINT_CPU_OUT_OF_SPEC ]	= { 'S', ' ', false },
	[ TAINT_FORCED_RMMOD ]		= { 'R', ' ', false },
	[ TAINT_MACHINE_CHECK ]		= { 'M', ' ', false },
	[ TAINT_BAD_PAGE ]		= { 'B', ' ', false },
	[ TAINT_USER ]			= { 'U', ' ', false },
	[ TAINT_DIE ]			= { 'D', ' ', false },
	[ TAINT_OVERRIDDEN_ACPI_TABLE ]	= { 'A', ' ', false },
	[ TAINT_WARN ]			= { 'W', ' ', false },
	[ TAINT_CRAP ]			= { 'C', ' ', true },
	[ TAINT_FIRMWARE_WORKAROUND ]	= { 'I', ' ', false },
	[ TAINT_OOT_MODULE ]		= { 'O', ' ', true },
	[ TAINT_UNSIGNED_MODULE ]	= { 'E', ' ', true },
	[ TAINT_SOFTLOCKUP ]		= { 'L', ' ', false },
	[ TAINT_LIVEPATCH ]		= { 'K', ' ', true },
	[ TAINT_AUX ]			= { 'X', ' ', true },
	[ TAINT_RANDSTRUCT ]		= { 'T', ' ', true },
};
 ```

如上面的打印 `CPU: 0 PID: 895 Comm: insmod Tainted: G O 5.7.19 #1` 代表是一个 oot（out of tree）和是一个所有权(模块有作者信息等)的模块，这一块不是本文的重点不再详细说明。

### **show_stack**

```
void show_stack(struct task_struct *task, unsigned long *sp)
{
	pr_cont("Call Trace:\n");
	walk_stackframe(task, NULL, print_trace_address, NULL);
}
```

可以发现主要是有两个函数 `walk_stackframe`  和  `print_trace_address`，  下面我们具体看一下。

#### **walk_stackframe**

```
void notrace walk_stackframe(struct task_struct *task,
	struct pt_regs *regs, bool (*fn)(unsigned long, void *), void *arg)
{
	unsigned long sp, pc;
	unsigned long *ksp;

	/*
	* 获取当前 stack 的 sp 和 pc 寄存器的值
	*/
	if (regs) {
		sp = user_stack_pointer(regs);
		pc = instruction_pointer(regs);
	} else if (task == NULL || task == current) {
		sp = sp_in_global;
		pc = (unsigned long)walk_stackframe;
	} else {
		/* task blocked in __switch_to */
		sp = task->thread.sp;
		pc = task->thread.ra;
	}

/*
* 这里是 stack 8字节对齐
* 
*/
	if (unlikely(sp & 0x7))
		return;

/*
* 从当前的 sp 回溯整个进程 stack 的函数栈，并打印出来
* kstack_end 判断是否到达栈低 
* __kernel_text_address 判断 pc 指针是否合法，属于 text 区域
* fn(pc, arg) 将当前的函数帧地址打印出来
* sp - 4 ---> ra
*/
	ksp = (unsigned long *)sp;
	while (!kstack_end(ksp)) {
		if (__kernel_text_address(pc) && unlikely(fn(pc, arg)))
			break;
		pc = (*ksp++) - 0x4;
	}
}
```

看上面这个函数大概也就明白了，就是遍历整个内核进程栈将函数帧打印出来，那具体是如何打印的又是如何将地址转化成函数名的呢？我们继续看一下这个函数

#### **print_trace_address**

```
static bool print_trace_address(unsigned long pc, void *arg)
{
	print_ip_sym(pc);
	return false;
}
```

**print_ip_sym**

```
static inline void print_ip_sym(unsigned long ip)
{
	printk("[<%px>] %pS\n", (void *) ip, (void *) ip);
}
```

这个函数就是调用 `printk` ，把 `%pS`  作为格式化参数传递给  `printk` ，`printk`  将对应地址的函数名打印出来，这部分工作内核已经为我们做好了，我们直接使用就可以了，当然在内核 **walk_stackframe** 有两种实现，还有一种是打开了 fp 功能的，原理类似在这里就不再赘述了。

## 小结

通过分析 `dump_stack` 的代码的主要是基于如下两条代码：

```
	printk("%sCPU: %d PID: %d Comm: %.20s %s%s %s %.*s\n",
	       log_lvl, raw_smp_processor_id(), current->pid, current->comm,
	       kexec_crash_loaded() ? "Kdump: loaded " : "",
	       print_tainted(),
	       init_utsname()->release,
	       (int)strcspn(init_utsname()->version, " "),
	       init_utsname()->version);
	       
	printk("[<%px>] %pS\n", (void *) ip, (void *) ip);       
	       
```

基于上面的两个关键代码，在不同架构的实现基本就是通过不同的通用寄存器将栈回溯出来并打印。

## 参考

* [函数调用保留的寄存器](https://suda-morris.github.io/blog/cs/risc-v.html#函数调用时保留的寄存器)
* [维基百科](https://en.wikichip.org/wiki/risc-v/registers)
* [L03.ws_solutions.pdf](https://6004.mit.edu/web/_static/silvina-test/resources/lectures/L03.ws_solutions.pdf)
* [dump_stack 实现分析](http://kernel.meizu.com/2017/03/18-40-19-dump_stack.html)
