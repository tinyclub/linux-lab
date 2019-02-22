---
layout: post
author: 'Wang Chen'
title: "LWN 753267: 针对页表遍历方式进行改造的讨论"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-753267/
description: "LWN 文章翻译，针对页表遍历方式进行改造的讨论"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[Reworking page-table traversal](https://lwn.net/Articles/753267/)
> 原创：By corbet @ May 4, 2018
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Fan Xin](https://github.com/fan-xin)

> A system's page tables are organized into a tree that is as many as five levels deep. In many ways those levels are all similar, but the kernel treats them all as being different, with the result that page-table manipulations include a fair amount of repetitive code. During the memory-management track of the 2018 Linux Storage, Filesystem, and Memory-Management Summit, Kirill Shutemov proposed reworking how page tables are maintained. The idea was popular, but the implementation is likely to be tricky.

现在内核所支持的页表模型已经深达五级。在很多方面，这些级别的页表都是相似的，但内核还是将它们区别对待，导致目前页表操作中存在相当数量的重复代码。2018 年 “Linux 存储，文件系统和内存管理峰会”（“Linux Storage, Filesystem, and Memory-Management Summit”，简称 LSFMM）上，在有关内存管理主题的讨论期间，Kirill Shutemov 建议重新设计有关页表的操作方式。他的这个想法受到社区的欢迎，但具体实现起来可能会有点棘手。

> On a system with five-level page tables (which few of us have at this point, since Shutemov just added the fifth level), a traversal of the tree starts at the page global directory (PGD). From there, it proceeds to the P4D, the page upper directory (PUD), the page middle directory (PMD), and finally to the PTE level that contains information about individual 4KB pages. If the kernel wants to unmap a range of page-table entries, it may have to make changes at multiple levels. In the code, that means that a call to [`unmap_page_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L1496) will start in the PGD, then call [`zap_p4d_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L1477) to do the work at the P4D level. The calls trickle down through [`zap_pud_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L1448) and [`zap_pmd_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L1411) before ending up in [`zap_pte_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L1281). All of the levels in this traversal (except the final one) look quite similar, but each is coded separately. There is a similar cascade of functions for most common page-table operations. Some clever coding ensures that the unneeded layers are compiled out when the kernel is built for a system with shallower page tables.

在一个具备五级页表的系统上（当前可能接触类似系统的人还不多，因为 Shutemov 刚刚为内核增加了对第五级的支持），对页表层级树的遍历从 PGD 开始（译者注，本译文缺省大家已经了解五级页表中 PGD 等缩写的含义，为行文流畅，不再将这些缩写翻译为中文，如果读者不了解的可以参阅 [LWN 717293: 五级页表](/lwn-717293)），往下依次进入 P4D，PUD，PMD，最后到达 PTE，PTE 页表中包含每个 4KB 物理页的相关信息（即页表项，Page Table Entry）。如果内核想要取消某些页表项对物理内存的映射关系（unmap），则可能不得不遍历多个级别的页表并做出相应更改。实际代码中，对应前文介绍的逐级遍历页表层级树的概念，会从 PGD 级别开始，依次调用[`unmap_page_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L1496)，[`zap_p4d_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L1477)，[`zap_pud_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L1448)和[`zap_pmd_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L1411)，最后到达[`zap_pte_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L1281)。所有级别的遍历函数（最后一个级别除外）看起来都非常相似，且都是单独编写的。除了 unmap 这样的操作之外，对大多数常见的其他页表操作，都存在类似的逐级遍历情况（译者注，譬如 [`copy_page_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L1198)，[`remap_pfn_range()`](https://elixir.bootlin.com/linux/latest/source/mm/memory.c#L2095) 等）。在这些函数中内核会通过一些编译技巧将当前系统不使用的页表级别屏蔽掉。

![Kirill Shutemov](https://static.lwn.net/images/conf/2018/lsfmm/KirillShutemov2-sm.jpg)

> Shutemov would like to replace this boilerplate with something a bit more compact. He is proposing representing a pointer into the page tables (at any level) with a structure like:

Shutemov 想用更紧凑的方式代替当前的代码。他建议新定义如下的结构体类型，当该结构体类型应用于每一级页表时，其中的指针用于指向对应级别的实际页表：

    struct pt_ptr {
        unsigned long *ptr;
	int lvl;
    };

> Using this structure, page-table manipulations would be handled by a single function that would call itself recursively to work down the levels. Recursion is generally frowned upon in the kernel because it can eat up stack space, but in this case it is strictly bounded by the depth of the page tables. That one function would replace the five that exist now, but it would naturally become somewhat more complex.

基于该结构，对各级页表的操作用一个函数就可以处理了，该函数可以递归调用自身以处理各个级别的页表。当然递归方式通常在内核中不太受欢迎，因为它可能会耗尽内核有限的栈空间，但对于当前的问题，我们不用担心，因为递归的层数严格受页表树的深度的限制。基于该方法，使用一个函数就可以取代现有的五个函数，但问题是它会使得内核的设计变得更加复杂。

> He asked: would this change be worth it? Michal Hocko asked just how many years of work would be required to get this change done. Among other things, it would have to touch every architecture in the system. If it proves impossible to create some sort of a compatibility layer that would let architectures opt into the new scheme, an all-architecture flag day would be required. Given that, Hocko said that he wasn't sure it would be worth the trouble.

他（指 Shutemov）在讨论中询问大家：引入这种改进是否有必要？Michal Hocko 首先对完成该项改进所需要的时间和工作量提出了疑问。对其他部分的影响暂不考虑，但该改动至少会涉及到内核所支持的每一种体系架构。如果最终证明我们无法创建某种兼容的方式使得所有的架构都能够方便地迁移到这个新方案上，那么我们就必须给予每个架构合理的移植时间，并预估一个确保所有架构都完成移植的最终日期。鉴于此，Hocko 认为他不确定引入该改动是否值得。

> Laura Abbott asked what problems would be solved by the new mechanism. One is that it would deal more gracefully with pages of different sizes. Some architectures (POWER, for example) can support multiple page sizes simultaneously; this scheme would make that feature easier to use and manage. Current code has to deal with a number of special cases involving the top-level table; those would mostly go away in the new scheme. And, presumably, the resulting code would be cleaner.

Laura Abbott 想知道该新机制究竟可以解决哪些问题。Shutemov 的回答是，第一，它可以更优雅地处理不同大小的物理页。某些体系架构（例如，POWER）可以同时支持多种不同大小的页；采用该方案后将方便对这种特性的使用和管理。另外，当前的代码不得不处理大量涉及顶级页表的特殊情况；采用新方案后将不用考虑这些特殊情况。当然，据推测，最终的代码也会更简洁。

> It was also said in jest that this mechanism would simplify the work when processors using six-level page tables show up. The subsequent discussion suggested that this is no joking matter; it seems that such designs are already under consideration. When such hardware does appear, Shutemov said, there will be no time to radically rework page-table manipulations to support it, so there will be no alternative to adding a sixth layer of functions instead. In an effort to avoid that, he is going to try to push this work forward on the x86 architecture and see how it goes.

也有人开玩笑说，有朝一日，当使用六级页表的处理器出现时，这种机制或许将简化内核的支持开发工作（译者注。显然这些人觉得支持六级页表的机器的出现还遥遥无期）。但随后的讨论表明社区在对待这件事情上还是挺认真的；看上去相关的设计考虑也已提上了日程。Shutemov 说，（如果不提前做好准备，）一旦这样的硬件出现，我们将没有充分的时间从根本上改造操作页表的机制，而不得不继续沿用当前的编码方式来支持新增加的第六级页表。为了避免这种情况，他计划在 x86 架构上尝试推进这项工作，并时刻关注其进展。

[1]: http://tinylab.org
