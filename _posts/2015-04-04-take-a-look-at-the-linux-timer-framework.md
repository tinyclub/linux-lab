---
title: 内核探索：浅谈 Linux 下的 Timer 框架
author: Tao HongLiang
layout: post
permalink: /take-a-look-at-the-linux-timer-framework/
views:
  - 169
tags:
  - Clocksource
  - Clock_event_device
  - Linux
  - timer
categories:
  - Device Driver
  - Linux
---

<!-- title: 浅谈 Linux 下的 Timer 框架 -->

<!-- 作者：陶宏亮，taohl04@gmail.com, 65036336 -->

<!-- 时间：2015/3/29 -->

<!-- 分类：Linux,Device Driver -->

<!-- 标签：Linux,Timer,Clocksource,Clock_event_device -->

> by Tao HongLiang of [TinyLab.org][1]
> 2015/03/29


## 前言

![timer][2]

看着图中的计时器，想一想现实中我们是如何计时的？想一想如果计划用 20 分钟来煮一锅粥都有哪些步骤？

  1. 在心里记下时钟上 20 分钟的位置。
  2. 开始煮粥，并按下计时器。
  3. 重复拿当前时间和 20 分钟比较。如果还没到，继续煮粥。
  4. 当当前时间到达目标时间 20 分钟后，告诉自己，粥好了可以吃了。

从上面的例子，我们能得到什么？如果抽象并构建一个时钟模型，我们需要哪些东西呢？我想大概是这样：

![Timer Framework][3]


  1. 一个单调递增的计数器 counter
  2. 一个可设置的比较器 comparer
  3. 当 counter 中的数字增加到等于 comparer 的时候触发中断，告诉你，“粥”好了可以吃了

## Linux 下的 Timer 框架

Linux 下的 Timer 框架和上面的例子大致相似，它把一个 Timer 拆分成两部分：Clocksource 和 Clock&#95;event&#95;device。Clocksource 主要包括 counter 等时钟源信息，Clock&#95;event&#95;device 主要包括：设置 comparer，触发中断，中断处理等任务。

![Liux Timer Framework][4]

### Clocksource

Clocksource 最重要的接口是 read counter func，通过此接口，内核可以读取 counter 中的值。完整的 Clocksource 接口定义见 include/linux/clocksource.h。

### Clock&#95;event&#95;device

Clock&#95;event&#95;device 部分需要实现如下接口

  * 通过 set\_next\_event 来设置下次时钟中断触发的条件。
  * 通过 irq && irq_action 来设置时钟中断触发后要做的事情。

完整的 Clock&#95;event&#95;device 接口定义见 include/linux/clockchips.h

## 实例展示

以 MIPS R4K Timer 为例，看看具体如何实现：

  * [Clock Source][5]

<pre>static cycle_t c0_hpt_read(struct clocksource *cs)
{
    return read_c0_count();
}

static struct clocksource clocksource_mips = {
    .name       = "MIPS",
    .read       = c0_hpt_read,
    .mask       = CLOCKSOURCE_MASK(32),
    .flags      = CLOCK_SOURCE_IS_CONTINUOUS,
};

int __init init_r4k_clocksource(void)
{
    if (!cpu_has_counter || !mips_hpt_frequency)
        return -ENXIO;

    /* Calculate a somewhat reasonable rating value */
    clocksource_mips.rating = 200 + mips_hpt_frequency / 10000000;

    clocksource_register_hz(&#038;clocksource_mips, mips_hpt_frequency);

    return 0;
}
</pre>

  * [Clock&#95;event&#95;device][6]

<pre>static int mips_next_event(unsigned long delta,
               struct clock_event_device *evt)
{
    unsigned int cnt;
    int res;

    cnt = read_c0_count();
    cnt += delta;
    write_c0_compare(cnt);
    res = ((int)(read_c0_count() - cnt) >= 0) ? -ETIME : 0;
    return res;
}

void mips_set_clock_mode(enum clock_event_mode mode,
                struct clock_event_device *evt)
{
    /* Nothing to do ...  */
}

DEFINE_PER_CPU(struct clock_event_device, mips_clockevent_device);
int cp0_timer_irq_installed;

irqreturn_t c0_compare_interrupt(int irq, void *dev_id)
{
    const int r2 = cpu_has_mips_r2_r6;
    struct clock_event_device *cd;
    int cpu = smp_processor_id();

    /*
     * Suckage alert:
     * Before R2 of the architecture there was no way to see if a
     * performance counter interrupt was pending, so we have to run
     * the performance counter interrupt handler anyway.
     */
    if (handle_perf_irq(r2))
        goto out;

    /*
     * The same applies to performance counter interrupts.  But with the
     * above we now know that the reason we got here must be a timer
     * interrupt.  Being the paranoiacs we are we check anyway.
     */
    if (!r2 || (read_c0_cause() &#038; (1 &lt;&lt; 30))) {
        /* Clear Count/Compare Interrupt */
        write_c0_compare(read_c0_compare());
        cd = &#038;per_cpu(mips_clockevent_device, cpu);
        cd->event_handler(cd);
    }

out:
    return IRQ_HANDLED;
}

struct irqaction c0_compare_irqaction = {
    .handler = c0_compare_interrupt,
    .flags = IRQF_PERCPU | IRQF_TIMER,
    .name = "timer",
};


void mips_event_handler(struct clock_event_device *dev)
{
}

/*
 * FIXME: This doesn't hold for the relocated E9000 compare interrupt.
 */
static int c0_compare_int_pending(void)
{
    /* When cpu_has_mips_r2, this checks Cause.TI instead of Cause.IP7 */
    return (read_c0_cause() >> cp0_compare_irq_shift) &#038; (1ul &lt;&lt; CAUSEB_IP);
}

/*
 * Compare interrupt can be routed and latched outside the core,
 * so wait up to worst case number of cycle counter ticks for timer interrupt
 * changes to propagate to the cause register.
 */
#define COMPARE_INT_SEEN_TICKS 50

int c0_compare_int_usable(void)
{
    unsigned int delta;
    unsigned int cnt;

#ifdef CONFIG_KVM_GUEST
    return 1;
#endif

    /*
     * IP7 already pending?  Try to clear it by acking the timer.
     */
    if (c0_compare_int_pending()) {
        cnt = read_c0_count();
        write_c0_compare(cnt);
        back_to_back_c0_hazard();
        while (read_c0_count() &lt; (cnt  + COMPARE_INT_SEEN_TICKS))
            if (!c0_compare_int_pending())
                break;
        if (c0_compare_int_pending())
            return 0;
    }

    for (delta = 0x10; delta &lt;= 0x400000; delta &lt;&lt;= 1) {
        cnt = read_c0_count();
        cnt += delta;
        write_c0_compare(cnt);
        back_to_back_c0_hazard();
        if ((int)(read_c0_count() - cnt) &lt; 0)
            break;
        /* increase delta if the timer was already expired */
    }

    while ((int)(read_c0_count() - cnt) &lt;= 0)
        ;   /* Wait for expiry  */

    while (read_c0_count() &lt; (cnt + COMPARE_INT_SEEN_TICKS))
        if (c0_compare_int_pending())
            break;
    if (!c0_compare_int_pending())
        return 0;
    cnt = read_c0_count();
    write_c0_compare(cnt);
    back_to_back_c0_hazard();
    while (read_c0_count() &lt; (cnt + COMPARE_INT_SEEN_TICKS))
        if (!c0_compare_int_pending())
            break;
    if (c0_compare_int_pending())
        return 0;

    /*
     * Feels like a real count / compare timer.
     */
    return 1;
}

int r4k_clockevent_init(void)
{
    unsigned int cpu = smp_processor_id();
    struct clock_event_device *cd;
    unsigned int irq;

    if (!cpu_has_counter || !mips_hpt_frequency)
        return -ENXIO;

    if (!c0_compare_int_usable())
        return -ENXIO;

    /*
     * With vectored interrupts things are getting platform specific.
     * get_c0_compare_int is a hook to allow a platform to return the
     * interrupt number of it's liking.
     */
    irq = MIPS_CPU_IRQ_BASE + cp0_compare_irq;
    if (get_c0_compare_int)
        irq = get_c0_compare_int();

    cd = &#038;per_cpu(mips_clockevent_device, cpu);

    cd->name        = "MIPS";
    cd->features        = CLOCK_EVT_FEAT_ONESHOT |
                  CLOCK_EVT_FEAT_C3STOP |
                  CLOCK_EVT_FEAT_PERCPU;

    clockevent_set_clock(cd, mips_hpt_frequency);

    /* Calculate the min / max delta */
    cd->max_delta_ns    = clockevent_delta2ns(0x7fffffff, cd);
    cd->min_delta_ns    = clockevent_delta2ns(0x300, cd);

    cd->rating      = 300;
    cd->irq         = irq;
    cd->cpumask     = cpumask_of(cpu);
    cd->set_next_event  = mips_next_event;
    cd->set_mode        = mips_set_clock_mode;
    cd->event_handler   = mips_event_handler;

    clockevents_register_device(cd);

    if (cp0_timer_irq_installed)
        return 0;

    cp0_timer_irq_installed = 1;

    setup_irq(irq, &#038;c0_compare_irqaction);

    return 0;
}
</pre>





 [1]: http://tinylab.org
 [2]: /wp-content/uploads/2015/03/Linux-timer-framework_pic1.jpg
 [3]: /wp-content/uploads/2015/03/Linux-timer-framework_pic2.jpg
 [4]: /wp-content/uploads/2015/03/Linux-timer-framework_pic3.jpg
 [5]: https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/arch/mips/kernel/csrc-r4k.c
 [6]: https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/arch/mips/kernel/cevt-r4k.c
