---
layout: post
author: 'Wang Chen'
title: "LWN 758677: 优化巨页（huge page）交换（swapping）的终极之役"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-758677/
description: "LWN 中文翻译，优化巨页交换的终极之役"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[The final step for huge-page swapping](https://lwn.net/Articles/758677/)
> 原创：By corbet @ Jul. 2nd, 2018
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Chumou Guo](https://github.com/simowce)

> For many years, Linux system administrators have gone out of their way to avoid swapping. The advent of nonvolatile memory is changing the equation, though, and swapping is starting to look interesting again — if it can perform well enough. That is not the case in current kernels, but a longstanding project to allow the swapping of transparent huge pages promises to improve that situation considerably. That work is reaching its final stage and might just enter the mainline soon.

多年来，Linux 系统管理员总是在努力避免发生页交换（swapping）。然而，非易失性存储设备（nonvolatile memory ，译者注，最典型的例子譬如 SSD）的出现正在改变这个状况，大家又开始对页交换变得感兴趣起来，并寄希望于页交换的性能可以变得足够的好。可惜在当前的内核中，页交换的性能还无法满足大家的要求，所幸的是目前社区中有一个长期的项目，它致力于实现透明巨页（transparent huge pages，译者注，下文直接使用不再翻译）的页交换并有望大大改善当前页交换的性能表现。这项工作已经进入了最后阶段，可能很快就会完全被合入内核主线。

> The use of huge pages can improve the performance of the system significantly, so the kernel works hard to make them available. The transparent huge pages mechanism collects application data into huge pages behind the scenes, and the memory-management subsystem as a whole works hard to ensure that appropriately sized pages are available. When it comes time to swap out a process's pages, though, all of that work is discarded, and a huge page is split back into hundreds of normal pages to be written out. When swapping was slow and generally avoided, that didn't matter much, but it is a bigger problem if one wants to swap to a fast device and maintain performance.

使用巨页（huge page，译者注，下文直接使用不再翻译）可以显著提高系统的性能，因此内核会尽量使用它们。transparent huge pages 机制在后台将应用程序的数据收集起来并存放到 huge pages 中，为此需要通过整个内存管理子系统的共同努力确保能够提供适当大小的内存页（译者注，这里指的是内核运行名为 khugepaged 的内核线程在后台扫描所有进程占用的内存，在可能的情况下会把 4k 页归并为 huge page）。可是一旦发生页交换，并对进程执行换出（swap out）时，先前的所有成果（指归并后的 huge pages）都不得不被丢弃，一个 huge page 会被分拆成几百个正常大小的页框，然后被逐个写出。过去页交换速度较慢且经常会被禁用，所以这个问题并不突出，但是采用快速设备进行页交换后，这个问题就会被放大，要想继续保持高速性能将会变得非常困难。

> The work so far, which has been underway since 2016, has focused on keeping huge pages together for as long as possible in the swapout process. Before this work began, the splitting of huge pages was one of the first things that was done in the swap-out process. The [first step](https://lwn.net/Articles/702159/) (merged in 4.13) was to delay splitting huge pages until after the swap entries had been allocated. That work alone improved performance considerably, mostly by reducing the number of times the associated locks had to be acquired and released. [Step two](https://lwn.net/Articles/728627/), merged in 4.14, further delayed the splitting until the huge page had actually been written to the swap device, again improving performance through better batching and by writing the entire huge page as a unit. Progress slowed down for a while after those pieces went upstream.

从 2016 年开始至今，相关的改进一直在进行，重点是在页交换过程中尽可能长时间地保持 huge page 的完整性（即不拆分）。该项工作开始之前，内核的换出操作中最先完成的动作之一就包括对 huge page 的分拆。所以改进的 [第一步][1]（随 4.13 版本合入内核主线）就是将对 huge page 的分拆推迟到为换出内容在交换设备上分配好存放空间之后。仅这项改动就对提高性能起到了很大的作用，主要的原因是这么做减少了必须获取和释放相关锁的次数。改进的 [第二步][2]，随 4.14 版本合入内核主线，进一步推迟了拆分，一直推迟到 huge page 被实际写入交换设备之后，通过优化批处理以及将整个 huge page 作为一个整体写出进一步提高了性能。在以上改进合入主线后，相关优化工作暂缓了一段时间。

> Things have picked up again with [the final installment](https://lwn.net/Articles/758107/) of 21 patches, posted by Ying Huang. Swapping out an entire huge page as a unit has already been mostly solved by the previous work, so it requires little effort here. What is a bit trickier, though, is keeping track of swapped huge pages. A whole set of swap entries is required to track both the huge page and its component pages, and they must all be kept in sync. Any event that might result in the splitting of a resident huge page, such as unmapping part of the page, an `madvise()` call, etc., must be caught so that the corresponding swap entries can be updated accordingly. Memory-use accounting for control groups must be updated to take huge-page swapping into account. The bulk of the patch set is dedicated to taking care of this kind of bookkeeping.

最近该项工作又重新启动，[改进工作的最后一步][3] 所涉及的补丁集由 Ying Huang 提交，该补丁集包括了 21 个子补丁改动。前期的工作基本上已经实现了将整个 huge page 作为一个整体进行换出，所以这方面的剩余工作已经不多。但另一方面让人感到棘手的是：如何对已换出的 huge pages 的数据保持跟踪处理。我们需要维护一整套交换数据结构来跟踪 huge page 及组成该 huge page 的基本页，同时还要确保它们的数据保持同步。任何可能导致对已备份的 huge page 内容进行拆分的事件都需要被捕获并相应地更新有关数据结构，这些事件包括，取消了对页的一部分内容的映射，或者发生了对 `madvise()` 的系统调用等等。对控制组（control groups）的内存使用记录进行更新时也需要考虑 huge page 交换所造成的影响。总而言之，补丁集中的大部分修改都是有关以上方面的处理。

> Once this work is done, the other side of the problem is relatively easy to solve. The page-fault handler can recognize a fault in a swapped huge page and try to swap the entire huge page back in as a unit. Such attempts can always fail if a free huge page is not available, of course, in which case the page will be split before being swapped back in. When it works, the operation will again benefit from the batching involved; the total overhead of bringing the entire huge page back into memory will be significantly reduced.

以上这些工作完成后，有关页交换的另一方面问题（指换入（swap-in））也就相对容易解决了。缺页异常（page-fault）处理程序可以识别出当前异常针对的是 huge page，从而尝试将整个 huge page 作为一个整体进行换入。如果无法为 huge page 找到空闲的内存，自然整体换入无法进行，此时 huge page 将被拆分后再换入。但如果可以找到空闲的内存，得益于所采用的批量处理方式；将整个 huge page 的数据从交换设备读入内存的总开销将大大减少。

> It turns out, though, that this may not be the biggest performance benefit from this work. As noted above, the kernel works hard to maximize the use of huge pages in the current workload; that includes coalescing individual pages into huge pages whenever possible. The current swap system undoes that work; if a huge page is swapped out, it will be swapped back in as individual pages. At that point, the kernel will have to restart the process of joining them into a huge page from the beginning. That is a fair amount of extra work for the kernel to do. More to the point, though, there is a limit to the rate at which pages can be coalesced in this way, and the operation may not always succeed. So, often, those small pages will remain separate and system performance will suffer accordingly.

事实证明，该项工作在性能上给我们带来的收益远不止这些。如上所述，内核努力地在当前运行中最大限度地使用 huge page；包括尽一切可能将单个页合并成 huge page。但目前的页交换运行机制使得这些成果付诸东流；一旦一个 huge page 被换出，再将其换入时将被分拆为单个的页。为此，内核将不得不再次尝试从头开始将这些单个的页进行合并。这给内核带来了大量的额外工作。更要命的是，合并操作的处理速度总是有限的，并且不可能每次操作都会成功。其结果就是，通常情况下，分拆后的单个页将无法再次被合并为 huge page，最终导致系统性能变差。

> If, instead, huge pages are swapped back in as huge pages, that work need not be done and the total number of huge pages in the running workload can be expected to increase significantly. Actually, "significantly" understates the impact of this work. In benchmark results posted with the patch, Huang notes that a system with an unmodified kernel ran the test with only 4.5% of the anonymous data being kept in huge pages by the end; with the patch set applied, that number rose to 96.6%. Inter-processor interrupts fell by 96%, and spinlock wait time dropped from 13.9% to 0.1%. The I/O throughput of swapping itself increased over 1000%. Kernel developers will often work long and hard for a 1% performance increase; improvements on this scale are nearly unheard of.

相反，如果能够对 huge page 保持以整体形式（即不分拆）执行换入，则无需考虑以上这些额外的操作，可以预料的是运行系统中的 huge page 的总数将显著（significantly）增加。实际上，我们用 “显著” 这个词都低估了这项工作所带来的性能提升。在提交的补丁里所给出的基准测试结果中，Huang 提醒大家，当基于一个未修改内核的系统运行测试时，最后只有 4.5% 的匿名数据保存在 huge page 中；而应用补丁集后，该数字上升至 96.6%。处理器间中断发生次数下降了 96%，自旋锁的等待时间从 13.9% 下降到只有 0.1%。页交换自身的吞吐量增加了 1000% 以上。要知道内核开发人员常常花费了很大的精力也不过将性能提升了 1%；如此大规模的改进几乎闻所未闻。

> Given that, one might conclude that merging this patch set would be worthwhile. But getting memory-management changes merged is always hard, especially when the patch set is large, as this one is. As Andrew Morton [remarked](https://lwn.net/Articles/758107/): "`It's a tremendously good performance improvement. It's also a tremendously large patchset`". Morton plans to put it into the -mm tree as soon as some conflicts with the [XArray patches](https://lwn.net/Articles/757342/) can be worked out. But what is really needed is some extensive review by other memory-management developers. Until that happens, the world will be stuck with slow huge-page swapping.

鉴于此，人们肯定会认为这个补丁集太值得被合入了。但是，要知道，有关内存管理方面的更改总是很难被主线所接纳，尤其是当补丁集的改动很大时，而这个补丁集正是这种情况。就像 Andrew Morton 所说的：“ 这是一个非常好的性能改进。也是一个非常大的补丁集 ”。Morton 计划将该补丁集先合入 `-mm` 代码仓库，这样可以尽快发现它与另一个 [XArray 补丁集][4] 有可能产生冲突的地方。目前该补丁集最迫切需要的是其他内存管理开发人员的深入审查。在所有这些工作完成之前，大家将不得不继续忍受当前缓慢的 huge page 交换。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://lwn.net/Articles/702159/
[2]: https://lwn.net/Articles/728627/
[3]: https://lwn.net/Articles/758107/
[4]: https://lwn.net/Articles/757342/
