---
layout: post
author: 'Wang Chen'
title: "LWN 717656: 主动（proactive）内存规整（compaction）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-717656/
description: "LWN 文章翻译，主动内存规整"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[Proactive compaction](https://lwn.net/Articles/717656/)
> 原创：By corbet @ Mar. 21, 2017
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Wen Yang](https://github.com/w-simon)

> One of the goals of memory compaction, Vlastimil Babka said at the beginning of his memory-management track session at the 2017 Linux Storage, Filesystem, and Memory-Management Summit, is to make higher-order pages available. These pages — suitably aligned groups of physically contiguous pages — have many uses, including supporting the transparent huge pages feature. Compaction is mostly done on demand in the kernel now; he would like to do more of it ahead of time instead.

在 2017 年度的 Linux 存储、文件系统和内存管理峰会（Linux Storage, Filesystem, and Memory-Management Summit）的内存管理分会场上，作为主持人的 Vlastimil Babka 在会议的一开始便介绍了内存规整的目的之一就是为了支持 “高阶” （higher-order）内存的分配。所谓 “高阶” 内存，是指物理地址上适当对齐并连续的一组页框，它们有许多用途，包括支持 “透明巨页”（transparent huge pages，简称 THP）功能。当前内核主要是在分配内存的过程中执行内存规整；而他（Vlastimil Babka）的想法是想看看内核是否可以在内存被申请之前提前做一些更多的规整方面的工作。

> The scheme he has in mind involves doing compaction in the background, outside of the context of any specific process. The `kswapd` thread would be woken from the memory-allocation slow path, and would be expected to reclaim a certain number of single pages. It would then wake the separate `kcompactd` thread with a desired size for the higher-order pages. This thread would do compaction until a page of the desired order is available, or until the entire memory zone has been scanned. That may not be enough, though, since, at the end, it will have created only a single higher-order page.

他所想到的一种方案是在后台执行规整，而无需依赖于任何特定的进程上下文（译者注，所谓不依赖于进程上下文即本文要介绍的主动规整（Proactive compaction），这里 “主动” 的含义具体是指在后台任务中增加更多的自主判断来尝试执行更多的内存规整，而不是仅仅在进程运行过程中根据内存分配函数被调用时所传入的有限信息执行规整）。当前内核在内存分配函数的慢路径（slow path，译者注，即函数 [`__alloc_pages_slowpath()`](https://elixir.bootlin.com/linux/v4.10/source/mm/page_alloc.c#L3519)）中会唤醒 `kswapd` 线程，尝试回收（reclaim）一定数量的单个页框。`kswapd` 则会唤醒另一个 `kcompactd` 线程（译者注，相关代码可以参考 [这里](https://elixir.bootlin.com/linux/v4.10/source/mm/vmscan.c#L3353)；`kcompactd` 在 4.6 版本引入，本文发表的时间，内核已经进化到 4.10），并在唤醒该线程的同时指定了期望分配的 “高阶” 内存的大小（译者注，即调用 `wakeup_kcompactd()` 函数时指定的 `alloc_order` 参数）。此线程在执行规整操作中，会一直扫描整个内存域（zone），直到获取足够的页框可以拼凑出给定大小的高阶内存块。但问题是按照目前的做法，`kcompactd` 最多只会创建一个 “高阶” 的内存块，一旦满足给定的要求就会暂停操作，而这往往无法满足更多的内存分配请求。

> He asked the crowd for ideas on how to make this scheme better. Michal Hocko suggested adding a configuration option; the administrator could set a watermark and a time period. The compaction thread would then check each period and try to ensure that the desired number of pages are available. But Babka objected that this behavior doesn't really seem like something that administrators can be expected to configure properly. They are focused on parameters like transparent huge page allocation rates or network throughput and will be hard put to translate that to desired numbers of free pages. It would be better, he said, to have the system tune itself if possible.

![Vlastimil Babka](https://static.lwn.net/images/conf/2017/lsfmm/VlastimilBabka-sm.jpg)

他（Vlastimil Babka）询问与会人员，针对当前的机制是否有好的改进建议。Michal Hocko 提出可以添加一个配置选项；通过这个配置选项系统管理员可以设置一个空闲内存的水位线（watermark）和一个检查周期。然后，`kcompactd` 可以周期性地检查并确保空闲的页框在配置的范围内（译者注：不低于设置的水位线）。但 Babka 对此表示反对，因为他认为对于系统管理员来说，要正确地对这些值进行配置，要求太高。作为系统管理员，他们更关心像透明巨页的分配成功率或者网络吞吐量这些值，但要让他们将这些参数转换为所需的空闲页框数量则不是那么容易。Babka 相信在这一点上还是让系统可以自动进行调节会更好。

> What would be the inputs to an auto-tuning solution? The first would be recent demand for pages of each order. Even better would be future demand, of course, but, in its absence, the best that can be done is to assume that future behavior will not differ too much from the recent past. It might also be desirable to track the importance of each request; transparent huge pages are an opportunistic optimization, while higher-order pages for the SLUB allocator can be hard to do without. The other useful input would be the success rate of recent compaction attempts; if compaction isn't working, there is no point in continuing to try it. Mel Gorman suggested also tracking the number of compaction requests that come in while the compaction itself is running.

那么我们可以利用哪些运行参数来帮助我们进行自动调节呢？第一个参考量可以是最近请求分配的每个 order 级别的内存块数量。当然，最好是能预期未来的内存分配请求量，但是，这一般很难做到，所以最好的情况下是假设未来的内存需求与最近刚刚发生的情况不会有太大的差别。另外我们有必要跟踪统计那些和某些重要功能实现相关的内存分配请求；譬如和透明巨页创建有关的请求，这或许有助于我们寻找一些优化它的机会，对那些用于 SLUB 分配器的高阶内存分配请求也很有必要重点关注，否则很难对其做出进一步的优化。另一个有用的参考量是最近以来尝试规整的成功率；换句话说，如果我们发现当前规整不起作用，则继续尝试也是没有意义的。除了以上两点之外，Mel Gorman 还建议跟踪在一次规整正在运行的同时又发生其他规整请求的数量。

> Andrea Arcangeli pointed out that it will be necessary to protect large pages created by compaction from normal allocation requests. Otherwise, the kernel might work to put together a higher-order page, only to have it immediately broken up again in response to a single-page allocation. When compaction is done directly from an allocation request this problem does not arise, since the resulting large page would be used right away. The proactive approach is promising, he said, but the protection problem needs to be addressed for it to work.

Andrea Arcangeli 指出，有必要确保规整后生成的较大的连续页框内存块不会被其他正常的内存分配请求所破坏。否则，可能在内核（通过规整）生成 “高阶” 内存块之后，恰好又来了一个单页框（order 等于 0）的内存分配请求，而导致刚刚得到的 “高阶” 内存块被拆分开。在内存分配请求函数中直接触发执行规整时不会遇到这个问题，因为内存分配中会立即分配刚生成的大内存块。他认为，主动（proactive）规整肯定是有用的，但只有先解决了如何对规整后的内存块进行保护这个问题才能使其真正发挥作用。

> The proactive compaction feature is a work in progress, Babka said; [an RFC patch](https://lwn.net/Articles/717756/) was sent out recently. It tries to track the number of allocations that would have succeeded with more `kcompactd` activity. Essentially, those are situations where there are enough free pages in the system, but they are too fragmented to use. The patches are not currently tracking the importance of allocation requests; perhaps the GFP flags could be used for that purpose. There is also no long-term averaging of demand. For now, it simply runs until there are enough high-order pages available.

Babka 说，主动规整（proactive compaction）功能正在开发中。最近刚提交了一个 [RFC 补丁](https://lwn.net/Articles/717756/)。补丁中试图检验一下在更积极地运行 `kcompactd` 后内存分配的问题是否有所改善。这里所提到的问题具体指的是表面上空闲页框足够，但由于它们太过分散而导致无法满足 “高阶” 内存分配的情况。补丁目前还没有考虑对一些重点分配请求类型（译者注，即上文提到的针对透明巨页和 SLUB 分配器相关的 “高阶” 内存分配请求）进行跟踪统计；如果要做的话或许可以考虑利用内存分配请求函数接口中的 GFP 选项参数。目前也没有统计长期运行后内存分配请求数量的平均值。总之，当前的做法只是简单地执行规整，直到发现已经有足够的 “高阶” 页框可用即可。

> One remaining problem is evaluating the value of this work. The existing artificial benchmarks, he said, are reaching their limits in this area.

遗留的一个问题是有关如何检验主动规整后的效果。Babka 提出，现有的人工基准测试方法已经很难满足当前的评估要求。

> Concerns were raised that background compaction might increase a system's power usage. Hocko said that this kind of worry was why he had suggested a configuration knob for this feature. Babka replied that power consumption should not be a big problem; compaction responds to actual demand on the system, so it should not be active when the system is otherwise mostly idle.

有人担心在后台运行规整可能会增加系统的能耗。Hocko 说正是基于这种担心，他才提出为这个功能增加一个配置选项。Babka 回答说，能耗应该不是一个大问题；后台规整任务的运行会基于系统的实际运行情况，因此当系统大部分空闲时，它会直接进入休眠。

> As the session came to a close, Arcangeli suggested that perhaps subsystems with large-page needs could register with the compaction code and indicate how many pages they would like to have available. Babka said that he would like to go as far as he can without the addition of any sort of tuning knobs, though. Johannes Weiner said there would be value in an on/off switch, since any sort of proactive work risks wasting resources in some environments. Any more tuning than that should be avoided, though, he said. It was generally agreed that this feature looked valuable, but that it should start as simple as possible with the idea that more complexity could be added later if needed.

在会议即将结束前，Arcangeli 建议，如果一个子系统需要分配大内存，可以向规整模块注册自己所需要的页框数（供规整算法参考）。但 Babka 表示，他还是希望尽可能地避免增加类似的调节措施。Johannes Weiner 说，为后台任务增加一个开关还是有必要的，因为只要是主动的操作，都有可能会在某些条件下过度运行导致资源的浪费。但他同时也表示，除了开关，其他的调节参数都应该被避免。与会代表们普遍看好这个功能（Proactive compaction），但都认为在实现上，初期应该尽可能保持简单，如果有必要可以在以后添加更多的复杂功能。

[1]: http://tinylab.org
