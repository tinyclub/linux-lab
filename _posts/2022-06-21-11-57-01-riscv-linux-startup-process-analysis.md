---
layout: post
author: 'Nikq'
title: "RISC-V Linux 启动流程分析"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /riscv-linux-startup/
description: "本文在 Porting Linux to a new processor architecture 系列翻译工作的基础上，继续就 RISC-V 处理器架构进行启动流程的分析。"
category:
  - 开源项目
  - Risc-V
tags:
  - RISC-V
  - Linux
  - 启动流程
---

> Author:  通天塔 985400330@qq.com
> Date:    2022/05/15
> Revisor: lzufalcon falcon@tinylab.org
> Project: [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux)

## RISC-V Linux 目录分布

通过文章 [将 Linux 移植到新的处理器架构，第 1 部分：基础](https://tinylab.org/lwn-654783/) 可知，我们进行一个新的处理器架构的移植，需要做到以下 3 点：

1. 确定这是不是一个新的架构移植。
2. 了解我们要移植的硬件。
3. 了解内核的基本概念。

在 RISC-V 已经被移植支持的情况下，我们现在要做的是分析，Linux 内核是如何支持 RISC-V 架构的。

```
- configs/：支持系统的默认配置 (i.e. *_defconfig files)
- include/asm/ ：Linux 源码内部使用的头文件
- include/uapi/asm： 对于要导出到用户空间（例如 libc ）的头文件
- kernel/：通用内核管理
- lib/：优化过的那套函数 (e.g. memcpy(), memset(), etc.)
- mm/：内存管理
```

- configs 文件中主要是一些配置文件，编译时可以选择默认配置进行编译，配置项较多，我们暂时不进行分析。
- include/asm/ 目录下定义了大量头文件，用于内核编译时使用。
- include/uapi/asm 目录下定义了很多结构体以及宏定义，可以供应用层使用，可以更方便的与内核统一使用一些定义好的数据。
- kernel/ 目录下有许多 C 文件，包含 CPU 获取 id，信号，中断，ops，smp，time 等功能。
- lib/ 目录下供 9 个文件，其中 5 个为汇编实现的代码。用于底层基础函数的实现。mm/ 目录下进行内存的管理，包括虚拟内存分配，页错误处理，cache 刷新等。
  
架构相关的 include 目录存在于架构相关文件夹，非架构相关的存在与 `include/asm-gereric` 目录下。

## 内核第一个运行的地方——head.S

```c
kernel_entry*
 start_kernel
    setup_arch*
     trap_init*
        mm_init
            mem_init*
        init_IRQ*
        time_init*
        rest_init
            kernel_thread
            kernel_thread
            cpu_startup_entry
```

内核的整体启动流程如上所示，我们从代码中进行分析，具体内核在启动过程中做了什么。

首先我们找到 head.S 文件。

```
ENTRY(_start_kernel)
        /* Mask all interrupts */
        csrw CSR_IE, zero
        csrw CSR_IP, zero
```

在内核启动时，一开始就关闭了所有中断。[Technical Report UCB/EECS-2016-129](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2016/EECS-2016-129.pdf) 一文中讲了，CSR 的寄存器分布。

关闭中断后，关闭了 FPU 功能，以检测内核空间内非法使用的定位点。后面是通过一系列的宏定义进行一些环境的配置，使得一些功能能够跑起来。

这些宏定义有：

```
ENTRY(_start_kernel)
        关闭所有中断
#ifdef CONFIG_RISCV_M_MODE
        /* 刷新icache */
        /* 复位所有寄存器，除了 ra, a0, a1 */
        /*
        设置一个 PMP 以允许访问所有内存。有些机器可能不会实现 pmp，因此我们设置了一个快速陷阱处理程序来跳过接触任何陷阱上的 pmp。
         */
        /*
        a0 中的 hardtid 稍后才会出现，我们没有固件可以处理它。
         */
#endif /* CONFIG_RISCV_M_MODE */
        /* 加载全局指针 */
        /*
         *关闭 FPU，检测内核空间中非法使用浮点数的情况
         */
#ifdef CONFIG_RISCV_BOOT_SPINWAIT
        /* 彩票系统只需要自旋等待启动方法 */
#ifndef CONFIG_XIP_KERNEL
        /* 选择一个 hart 来运行主启动序列 */
#else
        /* Hart_lottery 在 flash 中包含一个神奇的数字 */
        /* 如果在 RAM 中没有设置 hart_lottery，这是第一次 */
#endif /* CONFIG_XIP */
#endif /* CONFIG_RISCV_BOOT_SPINWAIT */
#ifdef CONFIG_XIP_KERNEL
/*恢复 a- 的复制*/
#endif
#ifndef CONFIG_XIP_KERNEL
        /*为展开的无 ELF 的镜像清除 BSS 段 */
#endif
        /* 保存 hart ID 和 DTB 物理地址*/
        /* 初始化页表并重新定位到虚拟地址 */
#ifdef CONFIG_BUILTIN_DTB
#else
#endif /* CONFIG_BUILTIN_DTB */
#ifdef CONFIG_MMU
#endif /* CONFIG_MMU *
        /* Restore C environment */
#ifdef CONFIG_KASAN
#endif
        /* 启动内核 */
#if CONFIG_RISCV_BOOT_SPINWAIT
        /* 设置陷阱向量永远旋转以帮助调试 */
        /*
这个人没有中彩票，所以我们等待中奖的人在启动过程中走得足够远，它应该继续。
         */
        /* FIXME: 我们应该 WFI，以节省一些能源在这里。*/
#endif /* CONFIG_RISCV_BOOT_SPINWAIT */
END(_start_kernel)
```

## 内核运行的第一个 C 文件——init/main.c

第一个运行的 C 语言函数为 `start_kernel`，在该函数中进行内核的第一个线程的创建。在创建之前，会执行架构相关的函数，从而适配硬件。

```c
kernel_entry*
 start_kernel
    setup_arch*
     trap_init*
        mm_init
            mem_init*
        init_IRQ*
        time_init*
        rest_init
            kernel_thread
            kernel_thread
            cpu_startup_entry
```

### setup_arch()

首先分析 `setup_arch` 这个函数，该函数属于架构相关函数，对应的文件在 `arch/riscv/kernel` 文件下。

#### parse_dtb()

这个函数首先要执行的是解析设备树，这说明 RISC-V 像 arm 一样，使用设备树进行设备驱动的管理，我们查看 x86 架构下的 `setup_arch` 则无设备树相关的配置。设备树解析函数通过 `drivers/of` 目录下的设备树驱动进行解析，并取出设备树中 model 名称。

设备树解析调用的函数是 `parse_dtb`，函数中调用了一个全局变量 `dtb_early_va`，这个变量是在 head.S 中进行的赋值，head.S 中调用该函数时，提前将变量放置于寄存器 a0 中，用于 C 函数的传参。

设备树地址传参代码：

```
#ifdef CONFIG_BUILTIN_DTB
        la a0, __dtb_start
        XIP_FIXUP_OFFSET a0
#else
        mv a0, s1
#endif /* CONFIG_BUILTIN_DTB */
        call setup_vm
```

#### setup_initial_init_mm()

设备树解析完成后，进行了早期内存的初始化，给出了代码段的起始与结束位置，数据段的结束位置，堆地址结束位置。

```
[0.000000] OF: fdt: Ignoring memory range 0x80000000 - 0x80200000
[0.000000] Machine model: riscv-virtio,qemu
[0.000000]start_code=0x80002000,end_code=0x806ae52c,end_data=0x812d2a00,brk=0x81322000
```

通过以上打印信息可知各个段的分配地址。CPU 内部的 RAM 寻址需要预留一些空间，所有 ram 起始地址就从 `0x80000000` 开始，地址空间分配完成之后将 `boot_command_line` 地址传出，供后续使用。

#### early_ioremap_setup()

早期 ioremap 初始化，将 I/O 的物理地址映射到虚拟地址。当 CPU 读取一段物理地址时，它可以读取到映射了 I/O 设备的物理 RAM 区域。ioremap 就是用来把设备内存映射到内核地址空间的。

该函数是一个架构不相关的函数，位于 `mm/early_ioremap.c`，

#### jump_label_init()

架构无关函数，位于 kernel 目录下，初始化 jump-label 子系统，jump-label 用于取消 if 判断分支，通过运行时修改代码，来提高执行的效率。

大家可以阅读这个系列连载的文章：[RISC-V Linux jump_label 详解，第 1 部分：技术背景](https://tinylab.org/riscv-jump-label-part1/)

#### parse_early_param()

架构无关函数，解析早期传入的参数。

#### efi_init()

暂未分析，应该和 UEFI 有关。大家可以看一下这个系列的文章：[RISC-V UEFI 架构支持详解，第 1 部分 - OpenSBI/U-Boot/UEFI 简介](https://tinylab.org/riscv-uefi-part1/)

#### paging_init()

完成系统分页机制的初始化工作，建立页表，从而内核可以完成虚拟内存的映射和转换工作，这一个函数执行完成之后，就可以通过虚拟地址来访问实际的物理地址了。

#### misc_mem_init()

该函数主要工作如下：

* 测试 ram 是否正常
* numa 架构初始化
* 内存模型 sparse 初始化
* 初始化 zone，用于管理物理内存地址区域
* 保留内核崩溃时内核信息导出时所用的内存区域
* 打印内存分配情况 `__memblock_dump_all()`，实际未输出
  
#### init_resources()

初始化内存资源，把系统的 ram 以及其他需要保留的 ram 进行保留

#### sbi_init()

可能与 sbi 有关，大家可以看一下这个系列的文章：[RISC-V OpenSBI 快速上手](https://tinylab.org/riscv-opensbi-quickstart/)

函数相关打印如下，具体作用暂未分析：

```
[    0.000000] SBI specification v0.2 detected
[    0.000000] SBI implementation ID=0x1 Version=0x9
[    0.000000] SBI TIME extension detected
[    0.000000] SBI IPI extension detected
[    0.000000] SBI RFENCE extension detected
[    0.000000] SBI HSM extension detected
```
#### kasan_init()

初始化 kasan 动态监测内存错误的工具，初始化完成之后，可以在内存使用越界或者释放后访问时，产生出错报告，帮助分析内核异常。

#### setup_smp()

配置 SMP 系统，使芯片可以多核运行。

#### riscv_fill_hwcap()

从设备树中读取处理器的 ISA，并写入 ELF 的 hwcap 字段中，以告知应用程序它们正在运行在怎样的处理器上。

打印信息如下：

```
[    0.000000] riscv: ISA extensions acdfimsu
[    0.000000] riscv: ELF capabilities acdfim
```

### trap_init()

未分析到

### mem_init()

`mem_init()` 是架构相关函数，我们分析一下该函数具体做了哪些工作。

```
void __init mem_init(void)
{
#ifdef CONFIG_FLATMEM
	BUG_ON(!mem_map);
#endif /* CONFIG_FLATMEM */

#ifdef CONFIG_SWIOTLB
	if (swiotlb_force == SWIOTLB_FORCE ||
	    max_pfn > PFN_DOWN(dma32_phys_limit))
		swiotlb_init(1);//软件DMA映射，解决部分DMA外设无法访问高地址内存的问题。
	else
		swiotlb_force = SWIOTLB_NO_FORCE;
#endif
	memblock_free_all();//释放空闲页面给伙伴分配器

	print_vm_layout();//打印内存分布情况
}
```

### init_IRQ()

中断初始化是一个架构相关的函数，首先从设备树中取出中断控制器 `interrupt-controller` 这一节点。

通过命令将 qemu 的 DTB 文件导出。

```
sudo qemu-system-riscv64 -M virt,dumpdtb=my.dtb ...
```

并将 dtb 文件反编译成 dts 文件。

```
dtc -I dtb -O dts -o qemu-virt.dts my.dtb
```

初始化 IRQ 的函数调用关系如下：

`init_IRQ() -> irqchip_init() -> of_irq_init()`

在 `of_irq_init()` 中遍历设备树，通过 `__irq_of_table` 进行匹配，匹配成功后进行 irq 初始化。

查看设备树，找到 `interrupt-controller` 的 `compatible` 为 `riscv,cpu-intc`：

```
cpu@0 {
        phandle = <0x07>;
        device_type = "cpu";
        reg = <0x00>;
        status = "okay";
        compatible = "riscv";
        riscv,isa = "rv64imafdcsu";
        mmu-type = "riscv,sv48";

        interrupt-controller {
                #interrupt-cells = <0x01>;
                interrupt-controller;
                compatible = "riscv,cpu-intc";
                phandle = <0x08>;
        };
};
```

通过匹配，最终调用的驱动是 `driver/irqchip/irq-riscv-intc.c`。

```
static int __init riscv_intc_init(struct device_node *node,
                                  struct device_node *parent)
{
        int rc, hartid;
        pr_info("[nfk test] %s-%s-%d\r\n",__FILE__,__FUNCTION__,__LINE__);
        hartid = riscv_of_parent_hartid(node);//获取CPU id
        if (hartid < 0) {
                pr_warn("unable to find hart id for %pOF\n", node);
                return 0;
        }
        else
        {
                pr_info("[nfk test] get hartid=%d\r\n",hartid);
        }

        /*
         * The DT will have one INTC DT node under each CPU (or HART)
         * DT node so riscv_intc_init() function will be called once
         * for each INTC DT node. We only need to do INTC initialization
         * for the INTC DT node belonging to boot CPU (or boot HART).
         */
        if (riscv_hartid_to_cpuid(hartid) != smp_processor_id())
                return 0;
                //每一个 CPU 都会有其 DT NODE，当前我们只需要初始化
                //boot CPU 的 DT NODE

        intc_domain = irq_domain_add_linear(node, BITS_PER_LONG,
                                            &riscv_intc_domain_ops, NULL);//向系统注册一个 irq domain，
        //最终调用 __irq_domain_add（），进行内存申请，domain 回调函数配置，此处仅完成了 irq_domain 的注册，后面的中断映射关系还需要在具体驱动中实现。
        if (!intc_domain) {//intc_domain 就是 interrupt-controller 的软件抽象
                pr_err("unable to add IRQ domain\n");
                return -ENXIO;
        }

        rc = set_handle_irq(&riscv_intc_irq);//配置中断处理函数
        if (rc) {
                pr_err("failed to set irq handler\n");
                return rc;
        }

        cpuhp_setup_state(CPUHP_AP_IRQ_RISCV_STARTING,
                          "irqchip/riscv/intc:starting",
                          riscv_intc_cpu_starting,
                          riscv_intc_cpu_dying);//对热插拔函数进行配置

        pr_info("%d local interrupts mapped\n", BITS_PER_LONG);

        return 0;
}
```

>[    0.000000] riscv-intc: [nfk test] drivers/irqchip/irq-riscv-intc.c-riscv_intc_init-99
[    0.000000] riscv-intc: get hartid=0
[    0.000000] riscv-intc: hartid 0,cpuid 1 not smp processor_id 
[    0.000000] riscv-intc: [nfk test] drivers/irqchip/irq-riscv-intc.c-riscv_intc_init-99
[    0.000000] riscv-intc: get hartid=1
[    0.000000] riscv-intc: hartid 1,cpuid 2 not smp processor_id 
[    0.000000] riscv-intc: [nfk test] drivers/irqchip/irq-riscv-intc.c-riscv_intc_init-99
[    0.000000] riscv-intc: get hartid=2
[    0.000000] riscv-intc: hartid 2,cpuid 3 not smp processor_id 
[    0.000000] riscv-intc: [nfk test] drivers/irqchip/irq-riscv-intc.c-riscv_intc_init-99
[    0.000000] riscv-intc: get hartid=3
[    0.000000] riscv-intc: 64 local interrupts mapped

中断初始化的打印如上所示。

### time_init()

架构相关函数 `time_init()`

```
void __init time_init(void)
{
        struct device_node *cpu;
        u32 prop;
        /*设备树中解析 CPU，并且读取他的 timebase-frequency*/
        cpu = of_find_node_by_path("/cpus");
        if (!cpu || of_property_read_u32(cpu, "timebase-frequency", &prop))
                panic(KERN_WARNING "RISC-V system with no 'timebase-frequency' in DTS\n");
        of_node_put(cpu);//减少引用计数
        riscv_timebase = prop;

        lpj_fine = riscv_timebase / HZ; 
        //遍历设备树，进行时钟初始化，类似于 of_irq_init()，linux-lab-disk 中的虚拟开发板当前匹配为空
        of_clk_init(NULL);

        timer_probe();
}
```

`timer_probe()` 中遍历设备树，通过 `__timer_of_table` 进行匹配，匹配成功后进行初始化 timer。

```
void __init timer_probe(void)
{
        struct device_node *np;
        const struct of_device_id *match;
        of_init_fn_1_ret init_func_ret;
        unsigned timers = 0;
        int ret;
        pr_info("[nfk test] %s-%s-%d\n",__FILE__,__FUNCTION__,__LINE__);
        for_each_matching_node_and_match(np, __timer_of_table, &match) {//遍历设备树，匹配 timer
                if (!of_device_is_available(np))
                        continue;

                pr_info("[nfk test] %s-%s-%d\n",__FILE__,__FUNCTION__,__LINE__);
                init_func_ret = match->data;

                ret = init_func_ret(np);//timer 初始化
                if (ret) {
                        if (ret != -EPROBE_DEFER)
                                pr_err("Failed to initialize '%pOF': %d\n", np,
                                       ret);
                        continue;
                }

                timers++;
        }

        timers += acpi_probe_device_table(timer);//注册 timer

        if (!timers)
                pr_crit("%s: no matching timers found\n", __func__);
        pr_info("[nfk test] %s-%s-%d\n",__FILE__,__FUNCTION__,__LINE__);
}
```

添加调试信息，打印如下：

```
[    0.000000] [nfk test] drivers/clocksource/timer-probe.c-timer_probe-23
[    0.000000] [nfk test] drivers/clocksource/timer-probe.c-timer_probe-28
[    0.000000] [nfk test] drivers/clocksource/timer-probe.c-timer_probe-28
[    0.000000] [nfk test] drivers/clocksource/timer-probe.c-timer_probe-28
[    0.000000] [nfk test] drivers/clocksource/timer-probe.c-timer_probe-28
[    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [3]
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x24e6a1710, max_idle_ns: 440795202120 ns
[    0.000126] sched_clock: 64 bits at 10MHz, resolution 100ns, wraps every 4398046511100ns
[    0.002668] [nfk test] drivers/clocksource/timer-probe.c-timer_probe-46
```

通过以上信息，可知，匹配到了 4 次 timer，通过中间的相关打印信息，找到驱动 `drivers/clocksource/timer-riscv.c`。

```
static int __init riscv_timer_init_dt(struct device_node *n)
{
        int cpuid, hartid, error;
        struct device_node *child;
        struct irq_domain *domain;

        hartid = riscv_of_processor_hartid(n);//获取 node 所在的hartid
        if (hartid < 0) {
                pr_warn("Not valid hartid for node [%pOF] error = [%d]\n",
                        n, hartid);
                return hartid;
        }

        cpuid = riscv_hartid_to_cpuid(hartid);//获取 cpu id
        if (cpuid < 0) {
                pr_warn("Invalid cpuid for hartid [%d]\n", hartid);
                return cpuid;
        }

        if (cpuid != smp_processor_id())
                return 0;//判断是否未 boot cpu

        domain = NULL;
        child = of_get_compatible_child(n, "riscv,cpu-intc");
        if (!child) {//获取中断的 domain
                pr_err("Failed to find INTC node [%pOF]\n", n);
                return -ENODEV;
        }
        domain = irq_find_host(child);
        of_node_put(child);
        if (!domain) {
                pr_err("Failed to find IRQ domain for node [%pOF]\n", n);
                return -ENODEV;
        }

        riscv_clock_event_irq = irq_create_mapping(domain, RV_IRQ_TIMER);//建立中断映射
        if (!riscv_clock_event_irq) {
                pr_err("Failed to map timer interrupt for node [%pOF]\n", n);
                return -ENODEV;
        }

        pr_info("%s: Registering clocksource cpuid [%d] hartid [%d]\n",
               __func__, cpuid, hartid);
        error = clocksource_register_hz(&riscv_clocksource, riscv_timebase);//注册 timer
        if (error) {
                pr_err("RISCV timer register failed [%d] for cpu = [%d]\n",
                       error, cpuid);
                return error;
        }
        sched_clock_register(riscv_sched_clock, 64, riscv_timebase);

        error = request_percpu_irq(riscv_clock_event_irq,
                                    riscv_timer_interrupt,
                                    "riscv-timer", &riscv_clock_event);
                                    //注册中断处理函数
        if (error) {
                pr_err("registering percpu irq failed [%d]\n", error);
                return error;
        }

        error = cpuhp_setup_state(CPUHP_AP_RISCV_TIMER_STARTING,
                         "clockevents/riscv/timer:starting",
                         riscv_timer_starting_cpu, riscv_timer_dying_cpu);//热插拔配置
        if (error)
                pr_err("cpu hp setup state failed for RISCV timer [%d]\n",
                       error);
        return error;
}
```

## 关于设备树匹配函数分析

### 循环匹配函数

以下函数是进行循环匹配的函数。

```
for_each_matching_node_and_match(np, __timer_of_table, &match)
for_each_matching_node_and_match(np, __irqchip_of_table, &match)
```

我们找到他的根本调用，参数描述如下，分别是设备树节点，要扫描的结构体，匹配到的结构体。

```
/**
 * of_find_matching_node_and_match - Find a node based on an of_device_id
 *                                   match table.
 * @from:       The node to start searching from or NULL, the node
 *              you pass will not be searched, only the next one
 *              will; typically, you pass what the previous call
 *              returned. of_node_put() will be called on it
 * @matches:    array of of device match structures to search in
 * @match:      Updated to point at the matches entry which matched
 *
 * Return: A node pointer with refcount incremented, use
 * of_node_put() on it when done.
 */
```

`of_find_matching_node_and_match` 最终调用的设备树匹配函数为 `__of_device_is_compatible`。其中输入参数 matches 就是要进行匹配的结构体。

### 匹配函数入参 table 的由来

搞清楚入参之后，我们找一下 `__timer_of_table` 从何处定义。

```
#define TIMER_OF_DECLARE(name, compat, fn) \
        OF_DECLARE_1_RET(timer, name, compat, fn)

```

下一层宏定义

```
#define OF_DECLARE_1_RET(table, name, compat, fn) \ 
                _OF_DECLARE(table, name, compat, fn, of_init_fn_1_ret)
```

下一层宏定义

```
#define _OF_DECLARE(table, name, compat, fn, fn_type)                   \
        static const struct of_device_id __of_table_##name              \
                __used __section("__" #table "_of_table")               \
                __aligned(__alignof__(struct of_device_id))             \
                 = { .compatible = compat,                              \
                     .data = (fn == (fn_type)NULL) ? fn : fn  }

```

所以我们根据宏定义 `TIMER_OF_DECLARE` 寻找与设备树节点可以匹配的驱动。

我们找到相关的 `TIMER_OF_DECLARE`：

```
// drivers/clocksource/timer-riscv.c

TIMER_OF_DECLARE(riscv_timer, "riscv", riscv_timer_init_dt)
```

根据宏定义展开可得：

```
static const struct of_device_id
__of_table_riscv_timer              \
        __used __section("__timer_of_table")               \
        __aligned(__alignof__(struct of_device_id))             \
                = 
                {
                        .compatible = "riscv",                              \
                        .data = (riscv_timer_init_dt == (of_init_fn_1_ret)NULL) ? riscv_timer_init_dt : riscv_timer_init_dt  
                }
```

这个地方就是 `__of_table_timer` 的由来。

### __of_table_timer 如何被生成为表

我们可以看到，设备树匹配时，是通过 for 循环进行遍历的，也就是说`__of_table_timer` 中有多个结构体供查询。

```
__used __section("__" timer "_of_table")
```

展开为：

```
#define __used			__attribute__((__used__))
#define __section(S)		__attribute__((__section__(#S)))
__attribute__((__used__)) __attribute__((__section__(__timer_of_table")))
```

GNU C 的一大特色就是 `__attribute__` 机制。`__attribute__` 可以设置函数属性（Function Attribute）、变量属性（Variable Attribute）和类型属性（Type Attribute）。

当前使用的 section 关键字可以将变量属性设置为“定义至指定的输入段中”。也就是说 `__of_table_riscv_timer` 这个结构体被定义到了指定的段中。所以最终结果是 `__of_table_timer` 是一个表，这个表代表着一个数据段，这个数据段中存着我们保存的结构体变量。

### 如何查看数据段变量

通过查看 System.map 可以看到数据段的分配，在 `__timer_of_table` 中分配了一个结构体。

分配情况如下：

```
ffffffff80a0df28 T __reservedmem_of_table
ffffffff80a0dff0 t __rmem_of_table_sentinel
ffffffff80a0e0b8 t __of_table_riscv_timer
ffffffff80a0e0b8 T __timer_of_table
ffffffff80a0e180 t __timer_of_table_sentinel
ffffffff80a0e248 T __cpu_method_of_table
ffffffff80a0e260 T __dtb_end
ffffffff80a0e260 T __dtb_start
ffffffff80a0e260 T __irqchip_of_table
ffffffff80a0e260 t __of_table_riscv
```

计算一下大小：`__of_table_riscv_timer=0x80a0e0b8-0x80a0dff0=200 bytes`

```
ubuntu@linux-lab:/labs/linux-lab/build/riscv64/virt/linux/v5.17$ readelf vmlinux -a |grep __timer_of_table
 57868: ffffffff80a0e0b8     0 NOTYPE  GLOBAL DEFAULT    5 __timer_of_table
ubuntu@linux-lab:/labs/linux-lab/build/riscv64/virt/linux/v5.17$ readelf vmlinux -a |grep __of_table_riscv_timer
 40119: ffffffff80a0e0b8   200 OBJECT  LOCAL  DEFAULT    5 __of_table_riscv_timer
 ```

与 vmlinux 中的数据可以匹配上。

实际计算结构体大小也是 200 字节（32+32+128+8=200）;

```
/*
 * Struct used for matching a device
 */
struct of_device_id {
	char	name[32];
	char	type[32];
	char	compatible[128];
	const void *data;
};
```

## 小结

本文对 RISC-V 架构下的 Linux 的启动流程进行了梳理，在梳理过程中遇到了设备树解析方面的问题，在后面也进行了设备树解析流程的深入分析。本文更关注于流程，在深度上存在欠缺，大家可以针对于流程中的某个点进行更深入的分析。

## 延申阅读

- [如何分析 Linux 内核 RISC-V 架构相关代码](https://tinylab.org/riscv-linux-quickstart/)
- [RISC-V UEFI 架构支持详解，第 1 部分 - OpenSBI/U-Boot/UEFI 简介](https://tinylab.org/riscv-uefi-part1/)
- [RISC-V OpenSBI 快速上手](https://tinylab.org/riscv-opensbi-quickstart/)
- [将 Linux 移植到新的处理器架构，第 1 部分：基础](https://tinylab.org/lwn-654783/)
- [RISC-V Linux jump_label 详解，第 1 部分：技术背景](https://tinylab.org/riscv-jump-label-part1/)
