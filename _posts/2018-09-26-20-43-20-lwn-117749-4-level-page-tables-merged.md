---
layout: post
author: 'Wang Chen'
title: "LWN 117749: 合入四级页表功能"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-117749/
description: "LWN 文章翻译，合入四级页表功能"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[Four-level page tables merged](https://lwn.net/Articles/117749/)
> 原创：By corbet @ Jan. 5, 2005
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Li lingjie](https://github.com/lljgithub)

> As expected, one of the first things to be merged into Linus's BitKeeper repository after the 2.6.10 release was the four-level page table patch. Two weeks ago, we [noted](http://lwn.net/Articles/116810/) that Nick Piggin had posted an alternative patch which changed the organization initially created by Andi Kleen. It was not clear, then, which version of the patch would go in. In the end, Nick's changes to the four-level patch were accepted.

正如我们期望的那样，在 2.6.10 发布之后，首先合并到 Linus 的 BitKeeper 代码库中的补丁中就包含了对四级页表的支持。两周前，我们[注意到](/lwn-116810) Nick Piggin 发布了针对原四级页表补丁的一个替代方案，改进了最初由 Andi Kleen 设计的层级组织方式。一开始，哪个版本的补丁会进入内核主线并不明朗。但最后，显然胜出的是 Nick。

> Thus, in 2.6.11, the page table structure will include a new level, called "PUD," placed immediately below the top-level PGD directory. The new page table structure looks like this:

因此，在 2.6.11 中，页表结构将增加一个名为 “PUD” 的新级别，它位于顶层 PGD 表的下一级。新的页表结构如下所示：

![Four-level page tables](https://static.lwn.net/images/ns/kernel/four-level-pt.png)

> The PGD remains the top-level directory, accessed via the `mm_struct` structure associated with each process. The PUD only exists on architectures which are using four-level tables; that is only x86-64, as of this writing, but other 64-bit architectures will probably use the fourth level in the future as well. The PMD and PTE function as they did in previous kernels; the PMD is absent if the architecture only supports two-level tables.

PGD​​ 仍然是顶级目录，我们可以通过与每个进程相关联的 `mm_struct` 结构体访问它 。PUD 仅存在于使用四级页表的体系架构上；截至撰写本文时，这样的体系架构只有 x86-64，但其他 64 位的架构也可能在未来使用它。PMD 和 PTE 的功能与之前相同; 如果一个体系结构仅支持两级页表，则 PMD 可以被优化掉。

> Each level in the page table hierarchy is indexed with a subset of the bits in the virtual address of interest. Those bits are shown in the table to the right (for a few architectures). In the classic i386 architecture, only the PGD and PTE levels are actually used; the combined twenty bits allow up to 1 million pages (4GB) to be addressed. The i386 PAE mode adds the PMD level, but does not increase the virtual address space (it does expand the amount of physical memory which may be addressed, however). On the x86-64 architecture, four levels are used with a total of 35 bits for the page frame number. Before the patch was merged, the x86-64 architecture could not effectively use the fourth level and was limited to a 512GB virtual address space. Now x86-64 users can have a virtual address space covering 128TB of memory, which really should last them for a little while.

内核使用虚拟地址中的相应比特位（区间）来索引各级页表中的页表项。本段文字下方的表格展示了在一些典型的体系架构上这些比特位的定义（译者注，原文表格是嵌入在本段文字的右面，由于排版的原因，这里放在本段文字的下面）。在经典的 i386 架构上，实际使用的只包括 PGD 和 PTE 两个级别；这两个级别加起来一共使用 20 个比特位，允许索引总共 100 万个物理页（按照一个物理页 4KB 大小计算，也就是可以映射总计 4GB 大小的物理内存）。i386 的 PAE 模式增加了 PMD 级别，该模式采用三级页表后并没有增加虚拟地址的大小（译者注，即每个虚拟地址仍然占 32 个比特），但它确实扩展了物理内存的访问空间（译者注，虽然虚拟地址仍然是 32 位，即可用于索引的比特位总数保持不变，但在 PAE 模式下，PMD 和 PTE 的每个表项的大小，以及每个表项的 Field 字段的大小都扩展了，可以索引更多的 PTE 和 Page，也就可以映射更多的物理页）。在 x86-64 架构上，内核页表使用了四个级别，（其虚拟地址，此时为 64 位系统）为了索引物理页总共使用了 35 个比特位。在四级页表补丁代码合入之前，x86-64 体系结构并无法有效地使用第四级，从而导致其最多访问不超过 512GB 的虚拟地址空间。合入补丁后，x86-64 的用户可以最多访问高达 128TB 的虚拟地址空间，这着实足够大家用一段时间了。

![](/wp-content/uploads/2018/09/lwn-117749.png)

> Those who are curious about how x86-64 uses its expanded address space may want to take a look at [this explanation](https://lwn.net/Articles/117783/) from Andi Kleen.

如果有读者希望了解在 x86-64 上内核是如何使用其扩展的地址空间的，可以读一下 Andi Kleen 的[这个解释](https://lwn.net/Articles/117783/)。

> The merging of this patch demonstrates a few things about the current kernel development model. Prior to 2.6, such a fundamental change could never be applied during a "stable" kernel series; anybody needing the four-level feature would have had to wait a couple more years for 2.8. The new way of kernel development, for better or for worse, does bring new features to users far more quickly than the old method did - and without the need for distributor backports. This patch is also a clear product of the peer review process. Andi's initial version worked fine, and could certainly have been merged into the mainline. The uninvited participation of another developer, however, helped to rework the patch into a less intrusive form which brought minimal changes to code outside the VM core. The end result is an improved kernel which can take full advantage of the hardware on which it runs.

内核加入四级页表补丁的过程还给我们展示了当前内核开发流程上的一些信息。在 2.6 系列之前，在 “稳定”（"stable"）版本的的内核系列中是绝不会加入像页表层级模型修改这类重大的基础性改变的。任何人可能会需要等待几年，直到下一个 “稳定” 版本（譬如 2.8 系列）才可以得到其所需要的四级页表功能。无论是好还是坏，内核开发的新模式确实比旧流程可以更快地将新功能推向用户，并且可以避免那些时常困扰发布包制作人员的反向移植工作。同时该补丁的合入也是一个优秀的同行评审过程的产物。Andi 的初始版本运行良好，当然可以合并到主线。然而，另一位开发人员（译者注，指 Nick）主动参与并对 Andi 的补丁做了进一步的改进，使其兼容性更佳，最终的结果就是给我们带来了一个更好的内核，可以让我们更充分地利用当前硬件的性能。

[1]: http://tinylab.org
