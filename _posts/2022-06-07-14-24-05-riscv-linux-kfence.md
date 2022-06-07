---
layout: post
author: 'Peng Weilin'
title: "Linux Kfence 详解"
draft: false
album: "RISC-V Linux"
license: "cc-by-nc-nd-4.0"
permalink: /riscv-linux-kfence/
description: "本文详细分析了一种低开销的内存错误检测机制 Kfence。"
category:
  - Linux 内核
  - Risc-V
tags:
  - 内存管理
  - Kfence
  - Kasan
---

> Author:  pwl999
> Date:    2022/04/28
> Project: [RISC-V Linux 内核剖析](https://gitee.com/tinylab/riscv-linux)

## 1. 原理介绍

Kfence (Kernel Electric Fence) 是 Linux 内核引入的一种低开销的内存错误检测机制，因为是低开销的所以它可以在运行的生产环境中开启，同样由于是低开销所以它的功能相比较 Kasan 会偏弱。

Kfence 的基本原理非常简单，它创建了自己的专有检测内存池 `kfence_pool`。在 `data page` 的两边加上了 `fence page` 电子栅栏，利用 MMU 的特性把 `fence page` 设置成不可访问。如果对 `data page` 的访问越过了 page 边界， 就会立刻触发异常。

![](/wp-content/uploads/2022/03/riscv-linux/kfence/kfence_pool.png)

Kfence 的主要特点如下：

| item     | Kfence                                    | Kasan                  |
| -------- | ----------------------------------------- | ---------------------- |
| 检测密度 | 抽样法，默认每 100ms 提供一个可检测的内存 | 对所有内存访问进行检测 |
| 检测粒度 | 核心的检测粒度为 page                     | 检测粒度为字节         |

### 1.1 slub/slab hook

Kfence 把自己 hook 到 `slub/slab` 的 `malloc()/free()` 流程当中去。但并不是所有的 `slub/slab` 内存都会从 `kfence_pool` 内存池中分配。它规定了两个条件：

- 1、默认每隔 100 ms，开放从 `kfence_pool` 内存池中分配一次数据。分配成功后会把 `kfence_allocation_gate` 加 1，阻止继续从 `kfence_pool` 的分配。`kfence_timer` 定时到期以后，又会重新开放一次分配。这相当于一种 `抽样法`。
- 2、每次分配都会占用 `kfence_pool` 中的一个 `data page`，所以可分配的内存长度最大为 1 page。

![](/wp-content/uploads/2022/03/riscv-linux/kfence/kfence_slub_hook.png)

### 1.2 out-of-bounds (over data page)

从 `kfence_pool` 中成功分配一个内存对象 `obj`，不管 `obj` 的实际大小有多大，都会占据一个 `data page`。

![](/wp-content/uploads/2022/03/riscv-linux/kfence/kfence_outbound_fence.png)

当原本访问 `obj` 的操作溢出到相邻的 `fence page` 时，会立即触发 CPU 异常，通过堆栈回溯揪出异常访问的元凶。

### 1.3 out-of-bounds (in data page)

大部分情况下 `obj` 是小于一个 page 的，对于 `data page` 剩余空间系统使用 `canary pattern` 进行填充。这种操作是为了检测超出了 `obj` 但还在 `data page` 范围内的溢出访问。

![](/wp-content/uploads/2022/03/riscv-linux/kfence/kfence_outbound_canary.png)

这种类型的溢出是不能在溢出发生时立刻触发的，它只能在 `obj` free 时，通过检测 `canary pattern` 被破坏来检测到有 `canary` 区域的溢出访问。但是异常访问的元凶却不能直接抓出来。

### 1.4 use-after-free

在 `obj` 被 free 以后，对应 `data page` 也会被设置成不可访问状态。

![](/wp-content/uploads/2022/03/riscv-linux/kfence/kfence_use_afterfree.png)

这种状态下，如果有操作继续访问 `obj` 会立即触发 CPU 异常，通过堆栈回溯揪出异常访问的元凶。

### 1.5 invalid-free

在 `obj` free 时会判断记录的 malloc 信息，判断是不是一次异常的 free。

## 2. 代码解析

分析以下关键的代码流程：

### 2.1 kfence_protect()

把 `fence page` 设置成不可访问的核心就是通过 MMU 清除掉 PTE 中的 `present` 标志位：

```
kfence_init_pool() → kfence_protect() → kfence_protect_page():
kfence_free() → __kfence_free() → kfence_guarded_free() → kfence_protect() → kfence_protect_page():

linux-5.16.14\arch\riscv\include\asm\kfence.h:

static inline bool kfence_protect_page(unsigned long addr, bool protect)
{
	pte_t *pte = virt_to_kpte(addr);

	if (protect)
		set_pte(pte, __pte(pte_val(*pte) & ~_PAGE_PRESENT));
	else
		set_pte(pte, __pte(pte_val(*pte) | _PAGE_PRESENT));

	flush_tlb_kernel_range(addr, addr + PAGE_SIZE);

	return true;
}
```

### 2.2 kfence_alloc_pool()

在系统启动时保留 Kfence 需要用到的内存 Page，默认保留 255 个 `data page`：

```
start_kernel() → mm_init() → kfence_alloc_pool():

void __init kfence_alloc_pool(void)
{
	if (!kfence_sample_interval)
		return;

	__kfence_pool = memblock_alloc(KFENCE_POOL_SIZE, PAGE_SIZE);

	if (!__kfence_pool)
		pr_err("failed to allocate pool\n");
}

#define KFENCE_POOL_SIZE ((CONFIG_KFENCE_NUM_OBJECTS + 1) * 2 * PAGE_SIZE)

config KFENCE_NUM_OBJECTS
	int "Number of guarded objects available"
	range 1 65535
	default 255
```

### 2.3 kfence_init()

```
void __init kfence_init(void)
{
	/* Setting kfence_sample_interval to 0 on boot disables KFENCE. */
	if (!kfence_sample_interval)
		return;

	stack_hash_seed = (u32)random_get_entropy();
    /* (1) 初始化 kfence pool 内存池 */
	if (!kfence_init_pool()) {
		pr_err("%s failed\n", __func__);
		return;
	}

	if (!IS_ENABLED(CONFIG_KFENCE_STATIC_KEYS))
		static_branch_enable(&kfence_allocation_key);
	WRITE_ONCE(kfence_enabled, true);
    /* (2) 初始化定时释放 guard 的 timer */
	queue_delayed_work(system_unbound_wq, &kfence_timer, 0);
	pr_info("initialized - using %lu bytes for %d objects at 0x%p-0x%p\n", KFENCE_POOL_SIZE,
		CONFIG_KFENCE_NUM_OBJECTS, (void *)__kfence_pool,
		(void *)(__kfence_pool + KFENCE_POOL_SIZE));
}
```

### 2.4 kfence_alloc()

内存分配流程：

```
kmem_cache_alloc() → slab_alloc() → kfence_alloc() → __kfence_alloc() → kfence_guarded_alloc():
```

### 2.5 kfence_free()

内存释放流程：

```
kfence_free() → __kfence_free() → kfence_guarded_free():
```

## 参考文档

1. [Linux内存异常检测工具—kfence](https://www.jianshu.com/p/f967086f9129)
2. [Kernel Electric-Fence (KFENCE)](https://www.kernel.org/doc/html/latest/dev-tools/kfence.html)
3. [Linux Kernel Sanitizers](https://gitee.com/mirrors/KASAN)
4. [Linux开源动态之一种新的内存非法访问检查工具KFence](https://www.cnblogs.com/liuhailong0112/p/14683431.html)
