---
title: 内核探索：Linux BogoMips 探秘
author: Tao HongLiang
layout: post
permalink: /explore-linux-bogomips/
tags:
  - BogoMIPS
  - 龙芯
  - HZ
  - Linux
  - loops_per_jiffy
categories:
  - 时钟系统
---

<!-- title: Linux BogoMips 探秘 -->

<!-- 作者：陶宏亮，taohl04@gmail.com, 65036336 -->

<!-- 时间：2015/4/12 -->

<!-- 分类：Linux -->

<!-- 标签：Linux,BogoMIPS,HZ,loops_per_jiffy,龙芯 -->

> By Tao Hongliang of [TinyLab.org][1]
> 2015/04/12


## 背景

今天和往常一样，在实验室和一群攻城师同事们没日没夜的码着代码。突然，一个同学问了一句： /proc/cpuinfo （**龙芯平台**） 里的 BogoMIPS 和 CPU 的频率是什么关系？ 一石激起千层浪，一时间各种奇葩的答案层出不穷，最终也没个定论。本攻城师决定直捣黄龙一探究竟，给迷茫的小伙伴们一个交代。

## BogoMIPS 的由来

BogoMIPS 是 Linus 本人的独创，Bogo 意思是“假的，伪造的”，MIPS 意思是“Millions of Instructions Per Second”，如果系统启动时，计算出 BogoMIPS 为 100，可记为 100万条伪指令每秒。 </br>

之所以叫伪指令，是因为在计算 BogoMIPS 的值时，CPU 一直在单一的执行 NOP （空操作），而不是随机执行指令集中的任意指令，所以不能以此作为 CPU 的性能指标。

## BogoMIPS 的计算

现在就让我们走进代码，看看他是怎么计算的。笔者是在 v3.13.0 版本的 Linux kernel 源码中做的实验。这一部分变动很少，其他相似版本应该无差别。 </br>

**首先**，在文件 `arch/mips/kernel/proc.c` 中给出了 BogoMIPS 的计算方式：

<pre>seq_printf(m, "BogoMIPS\t\t: %u.%02u\n",
    cpu_data[n].udelay_val / (500000/HZ),
    (cpu_data[n].udelay_val / (5000/HZ)) % 100);
</pre>

其中 HZ 是在内核配置的时候就确定好的常量，那在这个公式里就只剩 udelay_val 的值是未知的了。*小提醒：这里是一个经典的用整型来表达浮点类型的例子，小伙伴们可以学习下。* </br>

**然后**，在文件 `arch/mips/include/asm/bugs.h`中给出了 udelay_val 的计算方式：

<pre>cpu_data[cpu].udelay_val = loops_per_jiffy;
</pre>

**最后**，在文件`init/calibrate.c`中，我们能找到 loops_per_jiffy 的计算方式：

<pre>#define LPS_PREC 8

static unsigned long calibrate_delay_converge(void)
{
    /* First stage - slowly accelerate to find initial bounds */
    unsigned long lpj, lpj_base, ticks, loopadd, loopadd_base, chop_limit;
    int trials = 0, band = 0, trial_in_band = 0;

    lpj = (1<<12);

    /* wait for "start of" clock tick */
    /* 这里很聪明的选择了一个计算 loops 的起始时间，即，一个 tick 刚开始的时候 */
    ticks = jiffies;
    while (ticks == jiffies)
        ; /* nothing */
    /* Go .. */
    ticks = jiffies;

    /* 这里用逐渐逼近的方式计算在一个jiffy的时间段内，循环调用 __delay（NOP 循环）,
     * 最后累计 delay 了多少。loops_per_jiffy 就是多少了。
     */
    do {
        if (++trial_in_band == (1<<band)) {
            ++band;
            trial_in_band = 0;
        }
        __delay(lpj * band);
        trials += band;
    } while (ticks == jiffies);
    /*
     * We overshot, so retreat to a clear underestimate. Then estimate
     * the largest likely undershoot. This defines our chop bounds.
     */
    trials -= band;
    loopadd_base = lpj * band;
    lpj_base = lpj * trials;

    /* 接下来，再对上面算出来的 loops_per_jiffy 的值进行微调，确保其准确 */
recalibrate:
    lpj = lpj_base;
    loopadd = loopadd_base;

    /*
     * Do a binary approximation to get lpj set to
     * equal one clock (up to LPS_PREC bits)
     */
    chop_limit = lpj >> LPS_PREC;
    while (loopadd > chop_limit) {
        lpj += loopadd;
        ticks = jiffies;
        while (ticks == jiffies)
            ; /* nothing */
        ticks = jiffies;
        __delay(lpj);
        if (jiffies != ticks)   /* longer than 1 tick */
            lpj -= loopadd;
        loopadd >>= 1;
    }
    /*
     * If we incremented every single time possible, presume we've
     * massively underestimated initially, and retry with a higher
     * start, and larger range. (Only seen on x86_64, due to SMIs)
     */
    if (lpj + loopadd * 2 == lpj_base + loopadd_base * 2) {
        lpj_base = lpj;
        loopadd_base <<= 2;
        goto recalibrate;
    }

    return lpj;
}
</pre>

这下我们搞清楚了 loops_per_jiffy 的实质。详细计算方式，可以参考上面代码中给出的中文注释。

<pre>BogoMIPS = loops_per_jiffy ÷ (500000 / HZ)   --->   BogoMIPS = (loops_per_jiffy * HZ) ÷ 500000
</pre>

HZ 是什么，HZ 就是每秒的滴答数，即每秒的 jiffy 数。那么，loops_per_jiffy * HZ = loops_per_second

<pre>BogoMIPS = loops_per_second ÷ 500000  --->   BogoMIPS = (loops_per_second * 2) ÷ 1000000
</pre>

自此，BogoMIPS 的计算探秘结束。

## BogoMIPS 和 CPU 频率的关系

看了上面 BogoMIPS 的计算方式，我们发现并没有一个直接的公式可以让 BogoMIPS 和 CPU 频率之间相互转换。但至少可以推断出**对于同一款处理器**：

  * CPU 频率越快，loops_per_second 的值必然越大，那么 BogoMIPS 的值将会越大；
  * CPU 频率越低，则 BogoMIPS 的值将越小；
  * CPU 变频的时候，BogoMIPS 会随着 CPU 频率升高而升高，降低而降低。

引用 维基百科上已有的数据，可以进一步的对于 BogoMIPS 和 CPU 频率之间的关系，有更深的感性认识：

![Linux BogoMips][2]





 [1]: http://tinylab.org
 [2]: /wp-content/uploads/2015/04/Linux-BogoMips-1.jpg
