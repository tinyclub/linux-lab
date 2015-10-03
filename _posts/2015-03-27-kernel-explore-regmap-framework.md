---
title: 内核探索：Regmap 框架：简化慢速 I/O 接口优化性能
author: Wen Pingbo
layout: post
permalink: /kernel-explore-regmap-framework/
tags:
  - I2C
  - Linux
  - regmap
  - regmap_bus
  - regmap_config
  - regmap_ops
  - 内核探索
categories:
  - 性能优化
  - I/O 体系结构
---

> by WEN Pingbo of [TinyLab.org][1]
> 2015/03/23


## 简介

Regmap 机制是在 Linux 3.1 加入进来的特性。主要目的是减少慢速 I/O 驱动上的重复逻辑，提供一种通用的接口来操作底层硬件上的寄存器。其实这就是内核做的一次重构。Regmap 除了能做到统一的 I/O 接口，还可以在驱动和硬件 IC 之间做一层缓存，从而能减少底层 I/O 的操作次数。

## 使用对比

在了解 Regmap 的实现细节前，我们先来对比一下，传统操作寄存器的方式，与 Regmap 之间的差异。

### 传统方式

我们以一个 I2C 设备为例。读写一个寄存器，肯定需要用到 `i2c_transfer` 这样的 I2C 函数。为了方便，一般的驱动中，会在这之上再写一个 Wrapper，然后通过调用这个 Wrapper 来读写寄存器。比如如下这个读取寄存器的函数：

<pre>static int xxx_i2c_read_reg(struct i2c_client *client, u8 reg, u8 *val)
{
    struct i2c_msg msg[] = {
        {
            .addr = client->addr,
            .flags = 0,
            .len = 1,
            .buf = &#038;reg,
        },
        {
            .addr = client->addr,
            .flags = I2C_M_RD,
            .len = 1,
            .buf = val,
        },
    };

    return i2c_transfer(client->adapter, msg, 2);
}
</pre>

### Regmap方式

而如果 regmap 的方式来实现，对于上面这种读寄存器操作，其实现如下：

<pre>// first step: define regmap_config
static const struct regmap_config xxx_regmap_config = {
    .reg_bits = 10,
    .val_bits = 14,

    .max_register = 40,
    .cache_type = REGCACHE_RBTREE,

    .volatile_reg = false,
    .readable_reg = false,
};

// second step: initialize regmap in driver loading
regmap = regmap_init_i2c(i2c_client, &#038;xxx_regmap_config);

// third step: register operations
regmap_read(regmap, XXX_REG, &#038;value);
</pre>

代码中，做的第一步就是定义 IC 的一些寄存器信息。比如：位宽，地址位宽，寄存器总数等。然后在驱动加载的时候，初始化 Regmap，这样就可以正常调用 Regmap 的 API 了。

可以看到，为了让慢速 I/O 能够专注于自身的逻辑，内核把 SPI, I2C 等总线操作方式全部封装在 Regmap 里，这样驱动若要做 I/O 操作，直接调用 Regmap 的函数就可以了。

## 实现细节

整个 Regmap 是分为 3 层，其拓扑结构如下：

![Linux Regmap][2]

这里通过其中 3 个核心结构体来分别说明。

### regmap_config

`struct regmap_config` 结构体代表一个设备的寄存器配置信息，在做 Regmap 初始化时，驱动就需要把这个结构体传给 Regmap。这个结构体的定义在 `include/linux/regmap.h`，其中包含该设备的寄存器数量，寄存器位宽，缓存类型，读写属性等。

这一层是直接和驱动对接的。Regmap 根据传进来的 regmap_config 初始化对应的缓存和总线操作接口，驱动就可以正常调用 `regmap_write` 和 `regmap_read` 函数。

### regmap_ops

`struct regmap_ops` 是用来定义一个缓存类型的，具体定义如下：

<pre>struct regcache_ops {
    const char *name;
    enum regcache_type type;
    int (*init)(struct regmap *map);
    int (*exit)(struct regmap *map);
#ifdef CONFIG_DEBUG_FS
    void (*debugfs_init)(struct regmap *map);
#endif
    int (*read)(struct regmap *map, unsigned int reg, unsigned int *value);
    int (*write)(struct regmap *map, unsigned int reg, unsigned int value);
    int (*sync)(struct regmap *map, unsigned int min, unsigned int max);
    int (*drop)(struct regmap *map, unsigned int min, unsigned int max);
};
</pre>

在最新 Linux 4.0 版本中，已经有 3 种缓存类型，分别是数组（flat）、LZO 压缩和红黑树（rbtree）。数组好理解，是最简单的缓存类型，当设备寄存器很少时，可以用这种类型来缓存寄存器值。LZO(Lempel–Ziv–Oberhumer) 是 Linux 中经常用到的一种压缩算法，Linux 编译后就会用这个算法来压缩。这个算法有 3 个特性：压缩快，解压不需要额外内存，压缩比可以自动调节。在这里，你可以理解为一个数组缓存，套了一层压缩，来节约内存。当设备寄存器数量中等时，可以考虑这种缓存类型。而最后一类红黑树，它的特性就是索引快，所以当设备寄存器数量比较大，或者对寄存器操作延时要求低时，就可以用这种缓存类型。

缓存的类型是在 Regmap 初始化时，由 `.cache_type = REGCACHE_RBTREE` 来指定的。对于 `regmap_read` 来说，会先判断当前缓存是否有值，然后再检查是否需要 bypass，若没有，则可以直接从缓存里面取值，调用 `regcache_read` 来获取值，若需要从硬件上读取，则调用具体协议的读写函数，若是 I2C，调用 `i2c_transfer`。写的过程也是大同小异。

### regmap_bus

前面说的都是 Regmap 所做的封装，而真正进行 I/O 操作就是这最后一层。`struct regmap_bus` 定义了一个总线上的读写函数，这一层就像之前对 `i2c_transfer` 所做的封装一样。其定义如下：

<pre>struct regmap_bus {
    bool fast_io;
    regmap_hw_write write;
    regmap_hw_gather_write gather_write;
    regmap_hw_async_write async_write;
    regmap_hw_reg_write reg_write;
    regmap_hw_read read;
    regmap_hw_reg_read reg_read;
    regmap_hw_free_context free_context;
    regmap_hw_async_alloc async_alloc;
    u8 read_flag_mask;
    enum regmap_endian reg_format_endian_default;
    enum regmap_endian val_format_endian_default;
};
</pre>

在 Lernel 4.0 中，已经支持了 I2C、SPI、AC97、MMIO 和 SPMI 五种总线类型。相信在未来，有更多的总线会加进来。其实添加一个总线也不是很难，只需 4 个函数就可以了：`xxx_read`、`xxx_write`、`xxx_init` 和 `xxx_deinit`。具体可以看源码，这里就不多说了，留个任务在这吧。

## Reference

  1. [regmap: Generic I2C and SPI register map library][3]
  2. [include/linux/regmap.h][4]
  3. [drivers/base/regmap][5]





 [1]: http://tinylab.org
 [2]: /wp-content/uploads/2015/03/regmap-1.jpg
 [3]: http://lwn.net/Articles/451789/
 [4]: http://lxr.free-electrons.com/source/include/linux/regmap.h
 [5]: http://lxr.free-electrons.com/source/drivers/base/regmap
