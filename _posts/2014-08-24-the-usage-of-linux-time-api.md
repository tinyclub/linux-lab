---
title: Linux 时钟 API 使用详解：事关实时响应、功耗与调试
author: 泰晓科技
layout: post
permalink: /the-usage-of-linux-time-api/
tags:
  - alarm
  - 非原子上下文
  - 音频
  - 高保真
  - hifi
  - Linux
  - mdelay
  - msleep
  - ndelay
  - Real Time
  - threaded irq handler
  - timer
  - udelay
  - usleep_range
  - workqueue
  - 原子上下文
  - 实时系统
  - 时钟管理
  - 中断处理
categories:
  - 时钟系统
  - 实时性
---

> by falcon of [TinyLab.org][2]
> 2014/08/24


## 前言

Linux时钟管理相关API类型繁多，使用时难免会有很多困惑，比如说：

  * 中断处理时，什么情况下考虑使用Workqueue?
  * 原子上下文到底用哪种延时函数，能睡吗？
  * 非原子上下文是不是就能随便睡？
  * 用workqueue时是单独创建队列，还是挂在系统默认队列上？
  * mdelay()适合用在哪些情况下？
  * msleep()在所有非原子上下文都Ok吗？
  * 什么情况下用timer?
  * alarm呢？
  * usleep_range()是咋回事？

诸如此类，凡此等等，有待深入剖析。

## 背景分析

如果要很好地回答这些问题，那么必须了解很多前提。

首先，必须清楚所开发系统的基本需求。比如说[硬实时系统，延迟要求在us级，几个us~几百个us][3]；而软实时操作系统的延迟要求则低些，在ms级，几百个us~几个ms。

这里不讨论硬实时操作系统，这个要求比较高，工业控制等领域才有要求。在普通的桌面系统和手机系统，只要达到软实时就OK，手机系统可能要求更高。

对于手机而言，由于发热和续航控制的需要，要求支持DVFS和CPU动态Hotplug等，Regulator和Hotplug的基本工作开销可能都在ms级，而且因为频率在变化，自身就具有很大的不确定性，所以手机系统本质上来说是无法达到硬实时的。但是，为了提供良好的用户体验，软实时务必要做到，否则音频（比如Hifi）、视频播放的体验就无法达到要求。

关于音频的具体需求，咱们可以看下这篇文章 [Build A Real Time Audio Studio][4]：

> But in the delicate world of audio engineering, several hundreds of milliseconds is far too long, and even a delay of just tens of milliseconds is undesirable.
>
> Most professional systems will try to reduce audio latency to less than 10 milliseconds – faster than the average seek time on most hard drives. Some systems will get it down as low as 2 or 3ms, enabling them to process vocals and instruments in real-time, play software synthesizers just as they would the physical type, and mix and master recordings with the same near-zero latency as an analogue tape machine.

总结后可得出，音频方面的系统延迟可能要小到2~3ms左右，如果再高，体验就会比较差，Hifi（高保真）的要求可能更高。

这样的延迟标准要求系统在中断处理、原子上下文、甚至非原子上下文都需要特别注意各类Time函数的用法。

  * 中断处理

中断处理分为上下半部分，是为了提高系统响应能力，因为中断在系统中具有最高优先级，呆在里头太久，其他任务就得不到响应。那么中断到底该呆多久，这个当然是越少越好，如果能够比Context Switch小则更好。这意味着，中断处理基本开销应该比任务调度开销要小。

至于Context Switch，我曾经在论文《[LINUX实时抢占补丁的研究与实践](/wp-content/uploads/2015/11/linux-preempt-rt-research-and-practice.pdf)》第106页进行了介绍，在800MHz的Loongson-2F上正文开销大概在30us以内，当然，这个是跑硬实时Preempt-RT Linux的结果，对于普通到Low-Latency Desktop配置，这个会大一些，算上任务选择的开销，这个扩大到50us~100us应该差不多，当然，频率更高的X86处理器，这个时间可能更小，比如10us。

对于硬实时系统，这个时间应该控制在10us内。

  * 原子上下文

类似地，在原子上下文，总的时间也要有类似要求。对于软实时系统，控制在50us~100us以内就差不多。

这些场景下都不能睡眠，所以只能使用“忙等”，比如ndelay, udelay以及mdelay，“忙等”的时间必须控制在实时需求内。经过刚才的考量，mdelay一般是不能使用的，除非是某些上面提到到特定场景，比如DVFS，CPU Hotplug以及Big.Little Switch等。如果在原子上下文要用mdelay，那么务必思考如何把任务延迟到workqueue（当然也有threaded irq handler）去做，或者拆分临界区的大小，缩小原子锁的工作范围。

类似的情景，如果说一个任务的工作时间少于50~100us，而且要用周期性的Workqueue去做，那么直接把函数挂到系统队列里头可能更高效，因为挂到系统队列上会带来额到的Context Switch开销，而放在系统工作队列也不会太延迟其他到任务。

  * 非原子上下文

对于一些非原子操作的场景，因为可以睡眠，可选的API则更多，当然，“忙等”还是一个选项，特别地，因为“忙等”会耗费处理器资源，所以这个并不是所有场景都适用。同时，为了避免睡眠性API带来的调度开销，通常小于Context Switch的情景，还是建议用“忙等”。而大于Context Switch的场景，咱们的选择有很多，它们也有特定的适用领域。

比如说，大于Context Switch的，用usleep\_range()就可以，不过usleep\_range(min, max)要求指定一个动态到范围，比如参数（1000,2000）表示系统可以对齐到1ms到2ms之间的任何一个点唤醒，如果这个期间刚好有一个系统timer起来，那么就不需要产生额外到timer中断。但是如果这个范围很短，就很容易产生一个timer中断。

因为默认的HZ通常是100~250~1000不等，也就是说jiffy或者是调度timer的最基本周期是在10ms~4ms~1ms不等。所以，如果说HZ=250，那么范围小于4ms的话，是不一定刚好可以共享系统timer中断的。为了尽量使用idle唤醒对齐，这个范围在给定时应该在满足基本需要的情况下尽量可以宽一些，下限是必须等到某个操作（假设datasheet规定的写寄存器时序需要1ms的等待）生效，而上限则可以视整个操作的工作时间，比如说如果是LCD点亮屏幕的操作，整体上要求控制在100ms（人眼感觉卡顿到经验时间），所以，如果有25组寄存器，除掉其他的开销，假设50ms，那我们有50ms来初始化LCD相关寄存器，则每组寄存器到操作应该控制在1ms~2ms，则usleep_range(1000,2000)就可以。

因为usleep\_range()的调度是基于hrtimer的，所以在指定范围内基本可以满足要求，即使指定usleep\_range()，延迟也会很小，这个精度是由硬件时钟精度决定的，一个G频率刚好在ns级。如果精度要求不是很高，或者说，容许动态睡眠的范围更大，则可以用msleep()。因为msleep()是基于普通timer调度，则会有1000ms/HZ的调度延迟，以250为例，这个延迟在4ms左右，考虑到有4ms的延迟，那么10ms内的睡眠用msleep()就没有太大意义。10ms甚至20ms以上并且是不精确到睡眠才建议使用msleep()，如果是精确的，还得用usleep_range()。

但是msleep()也有它的局限性，在内核线程中太长时间使用会导致系统 hung task detector 误以为该任务为一个D状态的任务，而D状态任务通常是“有害”的，也就是说系统可能处于一个不可中断（不接收信号，也杀不死）的状态，如果这个状态持续时间过长，则会导致系统无法响应。通常这类情况有长时间等磁盘I/O操作，比如说访问NFS服务，服务器刚好挂掉了，或者一个线程死循环了。所以，如果是正常的线程，那么不要用msleep()睡太长时间。那这个时间应该是多少呢？个人认为1s是恰当的，因为1s内我们敲击 `ps -ef` 命令看到它到可能性都较小，而且对于上层某些交互也是可以接受的。当然，是否会考虑用msleep()的interruptible变体呢？这个并不推荐，因为这个会导致任务随时被其他不可预知的信号中断而无法睡眠到期望的时间就返回了，不确定性大大的增加了。

那超过1s该怎么处理呢？用timer吧，就是说，可以把任务挂到timer上，我们可以走开，不在原地等，而是让定时器叫醒我们，当然，这个也是有精度损失的，损失也在jiffy范围内。类似地，可以用delayed workqueue。

再者，如果要在系统进入深度睡眠后（Suspend2RAM）后能调用我们的线程，那么这时可以用alarm，当然，用alarm是不节能环保的，请慎用，确实需要时才考虑。

## 使用详解

通过上面的分析，并参考后续资料，我们不难得到基本的结论：

  * 原子上下文（不可睡眠）

      * ndelay ns级
      * udelay us级，< 1ms
      * mdelay ms级，> 1ms, < 1000ms/HZ (1 jiffy)

  * 非原子上下文（可睡眠）

      * udelay < 10us ~ 100us
      * mdelay > 1ms, < 1000ms/HZ (1 jiffy) **确实有需要才用**
      * usleep_range(min, max) > 100us, < ~20ms **min~max为动态范围，min!=max**
      * msleep > 20ms, < 1000ms? **如果 >1s，请创建timer或者delayed workqueue**
      * delayed workqueue > 1 jiffy (1000ms/HZ) **如开销小(<10us~100us)，直接挂到系统队列**
      * timer > 1 jiffy (1000ms/HZ) **idle(浅睡)状态使用**
      * alarm > 5s, Suspend（深睡）状态使用 **非迫不得已，不要用alarm**

## 参考资料

  * [Documentation/timers/timers-howto.txt][5]
  * [hrtimer and context switch overhead &#8212; udelay to &#8220;usleep&#8221;?][6]
  * [Context Switch Overheads for Linux on ARM Platforms][7]
  * [Linux下timer延时的使用][8]
  * [ICT Loongson-2 V0.3 FPU V0.1, Linux 3.12.24-rt38][3]
  * [Research and Practice on Preempt-RT Patch of Linux][9]





 [2]: http://tinylab.org
 [3]: https://www.osadl.org/Latency-plot-of-system-in-rack-2-slot.qa-latencyplot-r2s4.0.html
 [4]: http://www.linuxtoday.com/infrastructure/2009072900535MMSW
 [5]: https://www.kernel.org/doc/Documentation/timers/timers-howto.txt
 [6]: http://help.lockergnome.com/linux/hrtimer-context-switch-overhead-udelay-usleep--ftopict522054.html
 [7]: http://www.docin.com/p-65705331.html
 [8]: http://blog.csdn.net/hzpeterchen/article/details/8090385
 [9]: /wp-content/uploads/2015/11/linux-preempt-rt-research-and-practice.pdf
