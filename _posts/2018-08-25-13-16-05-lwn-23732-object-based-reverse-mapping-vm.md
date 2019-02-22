---
layout: post
author: 'Wang Chen'
title: "LWN 23732: 虚拟内存之基于对象的反向映射技术（object-based reverse-mapping）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-23732/
description: "LWN 文章翻译，虚拟内存之基于对象的反向映射技术"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[The object-based reverse-mapping VM](https://lwn.net/Articles/23732/)
> 原创：By corbet @ Feb. 25, 2003
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Wen Yang](https://github.com/w-simon)

> The reverse-mapping VM (RMAP) was merged into 2.5 to solve a specific problem: there was no easy way for the kernel to find out which page tables referred to a given physical page. Certain activities - swapping being at the top of the list - require making changes to all relevant page tables. You simply can not swap a page to disk until all of the page table entries pointing to it have been invalidated. The 2.4 kernel handles swapping by scanning through the page tables, one process at a time, and invalidating entries for pages that look like suitable victims. If it happens to find all of the page table entries in time, the page can then be evicted to disk.

2.5 版本中合入的反向映射（reverse-mapping，简称 RMAP）主要是为了解决虚拟内存管理中的一个难题：即当给定一个物理页时如何采用最简单的方法找出映射该页的页表。以页交换（swap）为例（这恐怕是内核活动中与之有关的最典型的应用了），swap 需要访问并修改与一个物理页相关的所有页表。在此过程中只有当所有引用该物理页的页表条目都失效后（译者注，指取消其映射关系），内核才可以将它（指该物理页上的内容）交换到磁盘上去。2.4 版本的内核在处理页交换问题时会逐个地扫描每个进程的页表项，一旦找到合适的页表项就使其无效。这么做带来的问题是，只有碰巧及时地找到与一个物理页相关的所有页表条目才可以将该物理页换出（译者注，所谓及时,是指存在以下场景，由于进程运行和扫描过程是异步发生的，且当进程较多时扫描也会需要较长的时间。所以有可能在扫描过程中，已经断开映射关系的物理页又被已扫描过的进程再次映射导致页交换最终无法发生）。

> In 2.5, a new data structure was added to make this process easier. Initially each page in the system (as represented by its `struct page` structure in the system memory map) had a linked list of reverse mapping entries pointing to every page table entry referencing that page. That worked, but it introduced some problems of its own. The reverse mapping entries took up a lot of memory, and quite a bit of time to maintain. Operations which required working with a lot of pages slowed down. And the `fork()` system call, which must add a new reverse mapping entry for every page in the process's address space, slowed significantly. As a result, there has been an ongoing effort to mitigate RMAP's costs.

在 2.5 版本的内核中，引入了新的数据结构设计，使得这个处理过程（译者注，即 RMAP）更加容易。系统中的每个物理页（通过结构体类型 `struct page` 所描述）中新增加了一个链表（译者注，即 `pte_chain`），链表的每一项保存了直接指向映射该物理页面的页表条目的指针。该机制非常高效，但其自身也存在一些问题。链表中保存反向映射信息的节点很多，占用了大量内存，并且维护链表的工作量也很繁重。随着物理页数量的增多操作速度开始变慢。以 `fork()` 系统调用为例，由于需要为进程地址空间中的每个页都添加新的反向映射项，所以执行速度会显著降低。因此，社区一直在努力试图改进 RMAP 的整体效率。

> Now a new technique, as embodied in [this patch](https://lwn.net/Articles/23584/) by Dave McCracken, has been proposed. This approach, called "object-based reverse mapping," is based on the realization that, in some cases at least, there are other paths from a `struct page` to a page table entry. If those paths can be used, the full RMAP overhead is unnecessary and can be cut out.

Dave McCracken 提交的[补丁](https://lwn.net/Articles/23584/)提出了一种新的解决方法。这种被称之为 “基于对象的反向映射” （"object-based reverse mapping"，译者注，下文直接使用 object-based RMAP，不再翻译）的方法至少说明，我们可以找到新的方法，从 `struct page` 找到映射该物理页的页表条目。如果该方法可行的话，将显著解决 RMAP 的巨大开销问题。

> By one reckoning, there are two basic types of user-mode page in a Linux system. ***Anonymous*** pages are just plain memory, the kind a process would get from `malloc()`. Most other pages are ***file-backed*** in some way; this means that, behind the scenes, the contents of that page are associated with a file somewhere in the system. File-backed pages include program code and files mapped in with `mmap()`. For these pages, it is possible to find their page table entries without using RMAP entries. To see how, let us refer to the following low-quality graphic, the result of your editor's nonexistent drawing skills:

总地来说，在 Linux 系统中，用户态下分配的物理页分两种情况。一种叫 ***匿名页（Anonymous pages）***，它们只是普通的内存，进程可以通过 `malloc()` 获得。另一种***基于文件（file-backed）***；即该物理内存页的内容是来自系统中磁盘上的文件，譬如某个可执行程序的指令（译者注，即文本段）或者通过 `mmap()` 所映射的某个文件的内容。对于第二种物理页，可以不用通过使用 RMAP 的链表项就可以查找到其对应的页表条目。为了详细了解其实现，让我们参考下图，图画得实在不怎么样，请多多包涵：

![Cheezy drawing](https://static.lwn.net/images/ns/ormap.png)

> The `struct page` structure for a given page is in the upper left corner. One of the fields of that structure is called `mapping`; it points to an `address_space` structure describing the object which backs up that page. That structure includes the inode for the file, various data structures for managing the pages belonging to the file, and two linked lists (`i_mmap` and `i_mmap_shared`) containing the `vm_area_struct` structures for each process which has a mapping into the file. The `vm_area_struct` (usually called a "VMA") describes how the mapping appears in a particular process's address space; the file `/proc/pid/maps` lists out the VMAs for the process with ID ***`pid`***. The VMA provides the information needed to find out what a given page's virtual address is in that process's address space, and that, in turn, can be used to find the correct page table entry.

图左上角的 page 即给定的物理页，内核用结构体类型 `struct page` 对其进行描述。该结构体的一个成员叫做 `mapping`；是一个指向结构体类型 `address_space` 的指针，`address_space` 类型用于描述该物理页对应的文件对象。其成员包括文件的 inode、用于管理该文件所对应的所有物理页的各种数据结构、以及两个链表（`i_mmap` 和 `i_mmap_shared`），链表上存放的每个元素保存了一个进程映射该文件后所得到的虚拟地址信息，采用结构体类型 `vm_area_struct`（通常简称为 “VMA”）来表示。通过指定进程号（***`pid`***）查看文件 `/proc/pid/maps`，可以列出进程号为 pid 的进程的所有 VMA 。VMA 提供了一个物理页在一个进程的地址空间中所对应的虚拟地址的信息，根据这些信息可以用于查找正确的页表条目。

> So all the object-based RMAP patch does is remove the direct reverse mapping entry (pointing from the page structure directly to the page table entry). When it is necessary to find that entry, the virtual memory subsystem simply takes the longer way around, via the `address_space` and `vm_area_struct` structures. Finding a page table entry this way certainly will take longer than following a direct pointer, but it should come out cheaper when one considers all of the RMAP information that no longer needs to be maintained.

基于以上设计，object-based RMAP 补丁删除了原先采用直接反向映射方式时所需要维护的数据结构（即 page 结构体中保存的指向页表条目的指针（链表），译者注，即前文所述 2.5 版本内核的实现方式）。需要反向映射时，虚拟内存子系统通过 `address_space` 再到 `vm_area_struct` 结构体的方式进行查找，搜索的路径相对较长。虽然以这种方式查找页表项肯定比直接指针方式要花费更长的时间，但是该方案的好处在于，内核不再需要对所有的物理页都维护其反向映射的信息。（译者注，其带来的好处和对比请参考前文介绍 2.5 版本内核中 RMAP 的实现及其弊端。）

> The object-based RMAP patch does not change the handling of anonymous pages, which do not have an associated `address_space` structure.

object-based RMAP 补丁没有更改匿名页的处理方式，因为对于匿名页来说，它没有关联的 `address_space` 结构体。

> Martin Bligh has posted [some initial benchmarks](https://lwn.net/Articles/23740/) showing some moderate improvement in the all-important kernel compilation test. The object-based approach does seem to help with some of the worst RMAP performance regressions. Andrew Morton [pointed out](https://lwn.net/Articles/23742/) a worst-case performance scenario for this approach, but it is not clear how big a problem it would really be. Andrew has included this patch in his [2.5.62-mm3](https://lwn.net/Articles/23567/) tree.

Martin Bligh 发布了[一些初步的基准测试结果](https://lwn.net/Articles/23740/)，对于一些重要的内核编译版本的测试结果显示，情况有了一定的改善。在性能回归测试中可以看到，基于对象的方法确实有助于改进原来最差情况下反向映射的执行效果。Andrew Morton [指出](https://lwn.net/Articles/23742/)了基于这种方法可能会碰到的一种最差的情况，但目前尚不清楚实际运行中它究竟会带来多大的影响。无论如何，Andrew 已在他维护的 [2.5.62-mm3](https://lwn.net/Articles/23567/) 版本中加入了这个补丁。

> Assuming that this patch goes in (it's late in the development process, but that hasn't stopped Linus from taking rather more disruptive VM patches before...), one might wonder if a complete object-based implementation might follow. The answer is "probably not." Anonymous pages tend to be private to individual processes, so there is no long chain of reverse mappings to manage in any case. So even if such pages came to look like file-backed pages (as could happen, say, with a rework of the swapping code), there isn't necessarily much to be gained from the object-based approach.

假定这个补丁会被内核主线所采纳（从目前的开发阶段来看是有点晚，但根据以往的经验，虽然这些补丁在改动上比较激进，但并不排除 Linus 同志仍会将它们继续合入虚拟内存子系统），人们可能会推测后面是否会有一个基于对象技术的更全面的实现。但答案是 “可能不会”。匿名页对于各个进程来说往往是私有的，因此一般情况下不会存在需要管理很多反向映射项的问题。因此，即使可以让这些页（指匿名页）看起来和文件映射页一样工作（这是可能的，例如，通过重新设计页交换部分的代码），但由于匿名页并不能从基于对象的方法上获得好处，所以进一步的统一也没有必要。

[1]: http://tinylab.org
