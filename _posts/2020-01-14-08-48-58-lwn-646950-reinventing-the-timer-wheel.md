---
layout: post
draft: false
top: false
author: 'Wang Chen'
title: "LWN 646950: 重新设计 “时间轮（timer wheel）”"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-646950/
description: "LWN 中文翻译，重新设计 timer wheel"
category:
  - 时钟系统
  - LWN
tags:
  - Linux
  - timer
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Reinventing the timer wheel](https://lwn.net/Articles/646950/)
> 原创：By Jonathan Corbet @ Jun. 3, 2015
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Wen Yang](https://github.com/w-simon)

> The kernel's "timer wheel" data structure has served it well for some time; it has changed little since it was described in [this article](https://lwn.net/Articles/152436/) in 2005. There are, however, some shortcomings in its original design that have become more costly over time, and the timer wheel has not adapted well to other changes in the scheduler code. So, after many years, this venerable data structure may soon be replaced with a variant that runs more efficiently, but loses some accuracy in timekeeping in the process.

内核中的 “定时器轮（timer wheel，译者注，即针对低精度定时器的设计方案，下文直接使用，不再翻译）” 已经存在有很长一段时间了。自从 2005 年 LWN 发表了 [这篇文章][1] 对其介绍以来，其代码就几乎没有发生过什么变化。然而随着时间的推移，其最初设计中所存在的一些弊端愈发明显，真可谓疲态尽显，已有跟不上其他调度代码演进的节奏。这么多年过去了，这个古老的数据结构终于首次迎来了另一种效率更高的设计改进，虽然这个新的方案在计时上会存在那么一点点精度上的损失。

> The kernel maintains two types of timers with two distinct use cases. The high-resolution timer ("hrtimer") mechanism provides accurate timers for work that needs to be done in the near future; hrtimer use is relatively rare, but, when hrtimers are used, they almost always run to completion. "Timeouts," instead, are normally used to alert the kernel to an expected event that has failed to arrive — a missing network packet or I/O completion interrupt, for example. The accuracy requirements for these timers are less stringent (it doesn't matter if an I/O timeout comes a few milliseconds late), and, importantly, these timers are usually canceled before they expire. The timer wheel is used for the latter variety of timers.

内核维护着两种类型的定时器，分别适用于不同的场景。高分辨率定时器（high-resolution timer，简称 “hrtimer”）提供准确的定时，确保在将来很近的某个时刻某个操作得以执行；相对来说，对 hrtimer 的使用比较少，但是，hrtimers 这类定时器一旦启动，几乎总是会到期。相反，另一种称之为 “Timeouts” 的定时器常用于辅助内核等待一些大概率不会到期的事件，例如，等待网络数据丢包发生或者等待读写完成超时。这类定时器的精度要求并不那么严格（譬如对于设备读写来说，超时延迟几毫秒并不会造成什么严重的问题），更重要的是，这类定时器通常在它们到期之前就会被取消。timer wheel 的设计所针对的正是第二类定时器。

> Here is the 2005 diagram showing the design of the timer wheel:

让我们再来看一下 2005 年那篇介绍 timer wheel 文章中的一张图：

![Timer wheel diagram](/wp-content/uploads/2020/01/lwn-646950/lwn-152436.png)

> This data structure is indexed by the kernel's low-resolution "jiffies" clock; one jiffy corresponds to something between 1ms and 10ms, depending on how the kernel is configured. Once every jiffy, the kernel processes any expired timers. That is done by taking the lowest eight bits of the `jiffies` variable and using them to index into the rightmost array in the above diagram; the result will be a linked list of timer events that expire at the current time.

对这个数据结构中数据的操作基于内核中低精度的固定节拍（“jiffies”）时钟中断；一个时钟节拍周期从 1 ms 到 10 ms 不等，具体取决于内核的配置。每次时钟节拍发生时，内核扫描并处理所有过期的定时器。具体方法是通过读取 `jiffies` 这个内核全局变量的低 8 位并使用该值作为索引找到上图中最右边数组（译者注，即数据结构中的 `tv1`）中的某一项；这些数组项元素含有一个链表，该链表保存了所有对应当前时刻已经到期的定时器事件（译者注，上图中红色椭圆状对象，类型为 `struct timer_list`）。

> Every 256 jiffies (in most configurations) the kernel will hit the end of that array; at that point it is necessary to perform a "cascade" operation. Each entry in the next higher array contains 256 jiffies worth of events; the timer code will select the correct entry (by using the next six bits of the `jiffies` value as an index), collect all of the timer entries found there, and distribute them across the 256 entries of the first array according to their expiration times. When the second level is exhausted, it is refilled by cascading down entries from the third level, and so on.

（大多数配置下）每经过 256 个时钟节拍，内核将到达 `tv1` 数组的末尾；此时，有必要执行 “借位展开” （"cascade"，下文直接使用不再翻译）操作。从右往左数更高一级的数组（译者注，即上图中的 `tv2`）中的每一项对应 256 个时钟节拍；timer wheel 的代码通过使用 `jiffies` 值的第 9 到第 14 位（共六个比特位）中存放的值作为索引来选择 tv2 数组中的相应条目，将该数组项中链表上的定时器事件对象（译者注，`tv2` 以上级别数组项中的链表在上图中并未画出），根据它们的到期时间，“cascade” 到 `tv1` 数组的 256 个条目中。随着时间的推移，当 `tv2` 数组项也被全部遍历一遍时，再通过级联的第三级 `tv3` 数组的条目来重新填充，依此类推。（更多有关旧的 timer wheel 设计的详细介绍，包括 “cascade” 的行为等等，请参考另一篇 [LWN 译文][1]）

> There are a number of advantages to this data structure, including the ability to immediately locate expired entries and quick addition and removal of events. But it has some downsides as well. The cascade operation can be expensive, and the time required is, to a first approximation, unpredictable; that can lead to unwanted latencies elsewhere in the system. The cascade operation is not particularly cache-friendly. There is also no way to quickly determine when the next timer expiration will happen; that requires searching through the wheel to actually find that event. The presence of [deferrable timers](https://lwn.net/Articles/228143/), which do not have to expire in any sort of timely manner, makes the identification of the next event that actually does have to expire at the requested time harder yet. For these reasons and more, developers have talked about replacing the timer wheel for years.

这种数据结构设计有许多优点，包括能够立即定位到期的数组项以及快速添加和删除定时器事件。但它也有一些缺点。“cascade” 操作有可能会非常费时（译者注：这取决于 “cascade” 中需要展开的项目的多少），并且本质上，其耗费的时间也是不可预期的；这可能会导致系统中其他处理出现不必要的延迟（译者注：“cascade” 操作过程中会关中断）。“cascade” 操作对缓存（cache）也不是很友好（译者注，重新展开操作会导致缓存内容被强制刷新，失去缓存的意义）。此外该设计并无有效方法快速确定下一个最近到期的定时器事件，而只能遍历所有的数组。面对类似 [“可延迟的定时器（deferrable timers）”][2]（译者注，下文直接使用不再翻译））这类需求，由于此类定时器并不需要及时地到期，使得确定下一个时刻真正会到期的事件更加困难。或多或少基于以上这些原因，这些年来开发人员已经多次讨论过替换当前 timer wheel 的方案。

## 新的 timer wheel（The new timer wheel）

> Thomas Gleixner has now posted [a first draft](https://lwn.net/Articles/646056/) of a reinvented timer wheel. It does away with the costly cascade operations (almost all the time) and handles deferrable timers in a much more straightforward manner. These gains come from the realization that not all timers have to be handled with the same level of accuracy.

Thomas Gleixner 针对当前的 timer wheel 发布了一个重新设计的 [初稿][3]。（在大部分情况下）它可以消除耗时的 “cascade” 操作，并能以更加简单的方式处理 “deferrable timers”。之所以能达到以上改进效果，是基于一个认识，即 “并非所有定时器应用场景都必须要满足同等的精度要求”。（译者注，实际合入的补丁代码在本文的基础上做了一定的调整，具体的内容请参考 [实际合入补丁的代码以及代码中的注释][5]）

> At a superficial level, the new data structure is quite similar to the old. There is still a hierarchy of arrays containing lists of timer events. In this case, though, the arrays are all the same size (32 entries), and there are eight levels of them. The lowest array contains events with single-jiffy resolution as before, so any new timeout expiring less than 32 jiffies in the future will be placed in this array.

乍一看，新的数据结构与旧的设计非常类似。它仍然将定时器事件以链表的形式存放在分级的数组项中。但是，在新的设计里，数组的大小都相同（每一级数组都包含 32 项），并且级数扩展为八级。最低级别的数组项所包含的定时器事件的精度和过去（即上图中的 `tv1`）一样（每个单位间隔为一个时钟节拍），也就是说第一个级别中记录的都是从现在开始超时时间长度小于 32 个时钟节拍的定时器事件。

> The next array is a little different, though; each entry represents eight jiffies worth of future timer events. Since there are 32 entries in this level as well, it can represent events up to 256 jiffies into the future. Entries in the third level each hold 64 jiffies worth of events; in the fourth level, they hold 512 jiffies worth, and so on. So each level covers a time period eight times longer than the level below it. The numbers are different from the old implementation, but the concept is the same, so far.

但第二级的单位时长和第一级不同；第二级数组每一项的单位时长为为八个时钟节拍。由于此级别的数组大小是 32，因此它可以表示从现在开始到未来最多 256 个时钟节拍的定时长度。第三级数组的单位长度是 64 个时钟节拍；第四级的是 512 个时钟节拍，依次类推。也就是说每个级别的单位时间长度都是它上一个级别（译者注，上一个级别指的是级别低的那个）的八倍。除了这些值与旧的实现不同外，到目前介绍为止，看上去基本思路（译者注，指分级的思路和目前旧的 timer wheel 设计相比）并没有什么大的差别。

> The old timer wheel would, each jiffy, run any expiring timers found in the appropriate entry in the highest-resolution array. It would then cascade entries downward if need be, spreading out the timer events among the higher-resolution entries of each lower-level array. The new code also runs the timers from the highest-resolution array in the same way, but the handling of the remaining arrays is different. Every eight jiffies, the appropriate entry in the second-level array will be checked, and any events found there will be expired. The same thing happens in the third level every 64 jiffies, in the fourth level every 512 jiffies, and so on.

旧的 timer wheel 代码里，每个时钟节拍，都会根据 jiffies 的值计算索引并基于该索引在最高分辨率数组（`tv1`）找到对应的数组项，并运行该项中记录的所有到期的定时器事件。如果需要，它将对高级别的数组执行 “cascade” 操作，将高级别的数组项中记录的定时器事件向下级数组展开。新代码也同样会在时钟节拍中以相同的方式执行最高分辨率数组中存放的定时器事件，但对其余级别数组的处理方式则和原先不同。（在新的设计中）每过八个时钟节拍，将检查二级数组中的相应项，对该项中存在的所有定时器事件都执行到期处理。每 64 个时钟节拍，对第三级数组执行同样的操作，每 512 个时钟节拍应用于第四级数组，依此类推。

> The end result is that the timer events in the higher-level arrays will be expired in place, rather than being cascaded downward. This approach, obviously, saves all the effort of performing the cascade. But it also means that any timeout that is more than 31 jiffies in the future will be run with lower accuracy. For example, a timeout that is 36 jiffies in the future will be put in the next higher eight-jiffy slot — 40 jiffies in the future. So that event will expire four jiffies later than requested. As timeouts are placed further into the future, the accuracy of their expiration will decline accordingly. The seventh level in this scheme will hold timeouts that are at least 1,048,576 jiffies in the future with 262,144-jiffy resolution. On a 1000HZ system, that corresponds to timeouts at least 17 minutes in the future; they will expire with a resolution of four minutes.

这么做的结果是，二级（包括二级）以上的数组中的定时器事件将在特定的时刻（译者注，指每隔 8 个时钟节拍的整数倍）到期并直接触发超时操作，不再向下级 “cascade”。显然，这么做节省了执行 “cascade” 所花费的工作。但也意味着未来超过 31 个 时钟节拍的定时器的到期精度变低了。举个例子来说，（由于超过第 31 个时钟节拍后）是按每 8 个时钟节拍为步长触发超时处理操作，所以原本应该在 36 个时钟节拍就触发超时的动作会被延迟到第 40 个时钟节拍（译者注，8 的整数倍）才被处理。这造成了该事件比实际要求的晚了四个时钟节拍才到期。随着定时器的超时时间向未来进一步延长，其到期的准确性将相应下降。按照这种设计，对于存放的定时器是在未来至少 1,048,576 个时钟节拍后才到期的事件的第七级数组，其分辨率将降低为 262,144 个时钟节拍。这意味着，假设某个系统的时钟频率为 1000 HZ 的话，当某个定时器设置的超时时间是 17 分钟的话，实际到期时间会比期望的时间要晚足足有 4 分钟。

> The old implementation was not subject to this loss of accuracy; even timeouts days in the future would expire at "exactly" the right time, for a one-jiffy value of "exactly." So one could argue that the replacement timer wheel does not work as well. But, first, one should remember that (1) almost all timeouts are set for the near future, (2) almost all timeouts are canceled before expiration, and (3) timeouts indicate that something went wrong and do not need to be delivered with a high degree of accuracy. So sacrificing some of that accuracy for higher timer-wheel performance would appear to be a good tradeoff.

目前的老方法不会在精度上存在损失；即使以天为单位设置时间仍能够准点到期，误差不超过一个时钟节拍。因此人们可能会说换成现在这样子岂不是更差了吗？但是，请注意（1）几乎所有针对 “Timeouts” 类型的超时时间所设置的时长都很短，（2）几乎所有的超时都会在到期之前被取消，（3）超时意味着出现了异常而在此情况下我们根本无需保证高度的准确性。因此（在这种场景下），通过牺牲一定的准确性以获得更高的性能似乎是一笔不错的交易。

> Thomas's patch also dispenses with the [timer slack](https://lwn.net/Articles/369549/) mechanism. Timer slack allows the expiration of timeouts to be deferred; it is intended to cause timeouts to be executed together and reduce the number of times the system wakes up. The new timer wheel batches things naturally for anything but the shortest of timeouts, so there is arguably no longer a need for a separate "slack" mechanism.

Thomas 的补丁间接实现了 [宽松定时器（timer slack）][4]（译者注，下文直接使用，不再翻译）的效果。“Timer slack” 机制采用的方法是通过推迟触发某些超时事件，从而尽量将多个超时事件累积在一起执行，达到减少系统被中断唤醒次数的目的。新的 timer wheel 设计正好也会将定时器超时处理以批处理的方式运行，因此采用该改进方案后或许就不再需要单独的 “Timer slack” 机制了。（译者注，4.8 版本合入 Thomas 的补丁后移除了有关 “Timer slack” 的逻辑。）

> Deferrable timers are a bit different though; they can be deferred indefinitely if need be. They usually correspond to some sort of cleanup work that must be done eventually, but with no particular urgency. If the CPU is running in the tickless mode, those timeouts should be deferred for as long as it takes to avoid interrupting the running application. In Thomas's patch, deferrable timers are stored in a separate, parallel timer wheel; this gets them out of the way and eases the task of figuring out when the next timer interrupt should be scheduled.

但对于 “可推迟定时器（Deferrable timers）” 还有点不同；必要的话，它们可以被无限期地推迟。它们通常对应于某种最终必须完成，但也不是特别紧迫的清理工作。如果 CPU 以 “动态时钟节拍（tickless，译者注，更好的说法是 “dynamic tick”）” 模式运行，则我们应该尽可能地推迟触发这些超时事件，这样可以避免中断正在运行的应用程序。在 Thomas 的补丁中，“Deferrable timers” 由另一个独立的 timer wheel 结构维护；这样可以避免相互影响，并且可以轻松确定何时应该安排下一个定时器中断。

> The new timer wheel code maintains a bitmap with a bit corresponding to each entry in the timer arrays; if there are timeouts stored in that entry, that bit is set. Finding the first array entry with an outstanding timeout is thus a simple matter of finding the first set bit in the bitmap — a fast operation. Then, since the expiration time of each array entry is known, the time of the next expiring timeout can be calculated without actually needing to look at the timeout entry. Placing deferrable timeouts in their own array makes it easy to simply avoid looking at them when checking for this next expiring timeout, speeding the operation further.

新的 timer wheel 代码中维护了一个位图，其每一个比特位对应于 timer wheel 数组中的每一项；如果某个数组项中含有定时器事件，则对应该项的比特位被设置。这么做的目的是为了方便快速定位最近的未超时定时器事件，具体的方法是只要在位图中找到第一个设置了的比特位即可，这个操作相当快。然后，由于每个数组项对应的到期时间是已知的，因此可以通过计算得到下一个到期的定时器的时间，而无需具体查看超时事件项本身。将 “Deferrable timers” 的超时时间放在它们自己独立的数组中的好处是：可以在检查下一个到期超时事件时避免查找它们，从而进一步加快操作速度。

> This code is all new and untried; Thomas warns that "it might eat your disk, kill your cat and make your kids miss the bus." That would suggest that it is certainly not considered to be 4.2 material. But, with some time and testing, it could likely be ready for a development cycle shortly after that. Then the kernel will, at last, have a shiny, new, faster timer wheel.

这个补丁是全新的且未经过充分的试用；Thomas 警告说 “它可能会导致你的磁盘被耗尽，心爱的猫被饿死（译者注，错过了喂食的时间？）或者让你的孩子错过校车。” 总而言之该补丁目前的状态看上去还不足以被合入 4.2 版本。但是，经过一段时间的测试，它可能就会被完善。相信内核最终会拥有一个全新的，更快的 timer wheel。（译者注，该补丁最终随 4.8 版本合入内核主线。）

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: /lwn-152436/
[2]: https://lwn.net/Articles/228143/
[3]: https://lwn.net/Articles/646056/
[4]: https://lwn.net/Articles/369549/
[5]: https://elixir.bootlin.com/linux/v4.8/source/kernel/time/timer.c#L62
