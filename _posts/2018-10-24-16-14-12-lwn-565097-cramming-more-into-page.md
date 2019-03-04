---
layout: post
author: 'Wang Chen'
title: "LWN 565097: 对 `struct page` 的进一步改进"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-565097/
description: "LWN 文章翻译，对 `struct page` 的进一步改进"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[Cramming more into struct page](https://lwn.net/Articles/565097/)
> 原创：By corbet @ Aug. 28, 2013
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Wen Yang](https://github.com/w-simon)

> As a general rule, kernel developers prefer data structures that are designed for readability and maintainability. When one understands the data structures used by a piece of code, an understanding of the code itself is usually not far away. So it might come as a surprise that one of the kernel's most heavily-used data structures is also among its least comprehensible. That data structure is `struct page`, which represents a page of physical memory. A recent patch set making `struct page` even more complicated provides an excuse for a quick overview of how this structure is used.

一般说来，内核开发人员更喜欢可读性和可维护性比较好的数据结构。当人们理解了代码所使用的数据结构后，对代码本身一般也就理解得差不多了。但令人惊讶的是，内核中使用最频繁的数据结构之一，即 `struct page`（用于描述一个物理内存页），其定义也是最不容易理解的。最近的一个补丁（对该结构体做了进一步修改）使其定义愈加复杂，为了方便大家理解，本文特地给大家介绍一下有关该结构体的使用。

> On most Linux systems, a page of physical memory contains 4096 bytes; that means that a typical system contains millions of pages. Management of those pages requires the maintenance of a `page` structure for each of those physical pages. That puts a lot of pressure on the size of `struct page`; expanding it by a single byte will cause the kernel's memory use to grow by (possibly many) megabytes. That creates a situation where almost any trick is justified if it can avoid making `struct page` bigger.

在大多数 Linux 系统上，一个物理页的大小定义为 4096 个字节；这意味着一个典型的系统上的内存可以划分为数百万个这样的物理页。内核管理这些物理页时采用每个物理页对应一个 `struct page` 结构体类型的实例。所以这个结构体类型的大小必须受到严格控制；因为对其每扩展一个字节都将导致内核的内存使用量以 MB 为单位增长。为此，内核代码中使用了各种技巧来避免这个结构体变大。

> Enter Joonsoo Kim, who has posted a patch set aimed at squeezing more information into `struct page` without making it any bigger. In particular, he is concerned about the space occupied by `struct slab`, which is used by the slab memory allocator (one of three allocators that can be configured into the kernel, the others being called SLUB and SLOB). A slab can be thought of as one or more contiguous pages containing an array of structures, each of which can be allocated separately; for example, the `kmalloc-64` slab holds 64-byte chunks used to satisfy `kmalloc()` calls requesting between 32 and 64 bytes of space. The associated `slab` structures are also used in great quantity; `/proc/slabinfo` on your editor's system shows over 28,000 active slabs for the ext4 inode cache alone. A reduction in that space use would be welcome; Joonsoo thinks this can be done — by folding the contents of `struct slab` into the `page` structure representing the memory containing the slab itself.

Joonsoo Kim 发布了一个补丁集，旨在以不增加 `struct page` 大小的前提下使其包含更多的信息。他之所以要对 `struct page` 进行修改的的原因却是因为担心另外一个结构体类型 `struct slab` 太大会占用太多的空间。 slab 内存分配器会使用 `struct slab` 这个结构体类型（slab 内存分配器，即 slab memory allocator，内核支持的三种内存分配器中的一种，其他两种分别是 SLUB 和 SLOB，可以通过配置进行选择）。一个 slab 由一个或者多个连续的物理页组成，每个 slab 所对应的内存空间被划分为一个数组，数组的成员是特定类型和大小的内存对象（译者注，这里所说的内存对象即 slab object，下文直接使用该名词，不再翻译；另外，每个 slab 对应一个 `struct slab`，用于管理一个 slab 中的 slab object），每个 slab object 可以单独分配；例如，`kmalloc-64` 是一种 slab，存放的 slab object 是大小为 64 个字节的内存块，当我们通过 `kmalloc()` 系统调用申请大小在 32 到 64 字节之间的内存块时，slab 内存分配器就会在 `kmalloc-64` 这种 slab 中寻找空闲的 slab object 并返回。内核中会分配数目巨大的 slab；通过查看笔者系统上的 `/proc/slabinfo`，可以发现光是用于 ext4 文件 inode 缓存的 slab （译者注，即 `ext4_inode_cache` 这种 slab）就有超过 28000 个。缩小 `struct slab` 的大小对节省内核内存绝对是一件好事；Joonsoo 认为一种可行的方法就是将 `struct slab` 结构体中的一些内容挪到存放 slab 的物理页所对应的 `struct page` 结构体中去。

> ## What's in struct page

## `struct page` 介绍

> Joonsoo's patch is perhaps best understood by stepping through `struct page` and noting the changes that are made to accommodate the extra data. The full definition of this structure can be found in `<linux/mm_types.h>` for the curious. The first field appears simple enough:

要想理解清楚 Joonsoo 的补丁改动，最好的方法是仔细地研究 `struct page` 结构体的定义以及补丁中所做的修改。该结构体类型的完整定义在 `<linux/mm_types.h>` 中（译者注，作者写作本文时的内核版本应该是 3.10，而且请注意作者在本文中列举的代码是 **“未合入”** Joonsoo 的补丁的代码。Joonsoo 的补丁随 3.13 合入，具体的修改请参考提交 “[slab: use struct page for slab management](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=8456a648cf44f14365f1f44de90a3da2526a4776)”。读者在理解下文的介绍时也可以直接参照对比 3.10 和 3.13 版本中的 `<linux/mm_types.h>` 文件）。第一个字段看起来很简单：

	unsigned long flags;

> This field holds flags describing the state of the page: dirty, locked, under writeback, etc. In truth, though, this field is not as simple as it seems; even the question of whether the kernel is running out of room for page flags is hard to answer. See [this article](https://lwn.net/Articles/335768/) for some details on how the flags field is used.

这个字段包含描述页状态的各种标志，譬如：页内容是否已经被修改（dirty），页是否被锁定（locked），页是否正在被写回到磁盘（writeback）等等。实际上，这个字段并不像看上去那么简单；甚至要准确回答内核是否已经用完页标志这个问题也很困难。更多详细讨论请参阅[这篇文章](/lwn-335768)。

> Following `flags` is:

紧接着 `flags` 的是以下字段：

	struct address_space *mapping;

> For pages that are in the page cache (a large portion of the pages on most systems), `mapping` points to the information needed to access the file that backs up the page. If, however, the page is an anonymous page (user-space memory backed by swap), then `mapping` will point to an `anon_vma` structure, allowing the kernel to quickly find the page tables that refer to this page; see [this article](https://lwn.net/Articles/75198/) for a diagram and details. To avoid confusion between the two types of page, anonymous pages will have the least-significant bit set in `mapping`; since the pointer itself is always aligned to at least a word boundary, that bit would otherwise be clear.

对页缓存（page cache）中的物理页（大多数系统上的大部分物理页都属于这种情况），字段 `mapping` 指向内核的相应数据结构（译者注，即该物理页所映射的文件所对应的 `struct inode` 的 `i_mapping` 字段，其类型为 `struct address_space`），并可经由此结构访问该物理页映射的文件本身。如果该物理页是匿名页（anonymous page，可以交换（swap）的用户空间内存），则 `mapping` 指向的是一个 `anon_vma` 结构，内核可以利用该结构快速查找引用该物理页的页表；具体请参阅[这篇文章](/lwn-75198)。为区分这两种情况，当 `mapping` 指向匿名页时其指针值的最低位设置为 1; 如果是指向 `struct address_space`，则由于该情形下指针值本身总是与至少一个字（WORD）边界对齐，所以其最低位一定是 0。

> This is the first place where Joonsoo's patch makes a change. The `mapping` field is not currently used for kernel-space memory, so he is able to use it as a pointer to the first free object in the slab, eliminating the need to keep it in `struct slab`.

Joonsoo 在这里引入了补丁的第一处修改。由于 `mapping` 字段当前并未用于内核空间的内存页，所以我们可以使用它保存 slab 中第一个空闲的 slab object 的地址，而原来该值保存在 `struct slab` 中。（译者注：对于内核态申请的物理内存页（这里指用于 slab 的内存页）, 肯定不是匿名页也没有映射文件（page cache），所以其对应的 `struct page` 的 `mapping` 字段自然就没有被使用，可以借给 slab 用。）

> Next is where things start to get complicated:

接下来的修改开始变得复杂：

	struct {
	    	union {
			pgoff_t index;
			void *freelist;
			bool pfmemalloc;
		};
	
		union {
			unsigned long counters;
			struct {
				union {
					atomic_t _mapcount;
					struct { /* SLUB */
						unsigned inuse:16;
						unsigned objects:15;
						unsigned frozen:1;
					};
					int units;
				};
				atomic_t _count;
			};
		};
	};



> (Note that this piece has been somewhat simplified through the removal of some `#ifdefs` and a fair number of comments). In the first union, `index` is used with page-cache pages to hold the offset into the associated file. If, instead, the page is managed by the SLUB or SLOB allocators, `freelist` points to a list of free objects. The slab allocator does not use `freelist`, but Joonsoo's patch makes slab use it the same way the other allocators do. The `pfmemalloc` member, instead, acts like a page flag; it is set on a free page if memory is tight and the page should only be used as part of an effort to free more pages.

（请注意，以上引用的代码已经经过简化，删除了一些 `#ifdef` 和相当多的注释）。在第一个联合体（union）结构中，`index` 字段用于标识一个页缓存（page cache）的物理页在其所映射的文件中的偏移量值（译者注，offset，以页为单位）。`freelist` 字段是当该物理页由 SLUB 或 SLOB 分配器使用时保存指向空闲对象的指针。slab 分配器原先并不使用 `freelist`，但是 Joonsoo 的补丁复用该字段，所以现在 slab 和其他分配器（指 SLUB 和 SLOB）一样使用它。最后一个字段 `pfmemalloc`，作为一个标志；用于在系统内存紧张时将一个空闲的物理页标识并保留为仅可被用于释放其他物理页（译者注，系统释放内存时也是需要使用一定量的内存的）。

> In the second union, both `counters` and the innermost anonymous `struct` are used by the SLUB allocator, while `units` is used by the SLOB allocator. The `_mapcount` and `_count` fields are both usage counts for the page; `_mapcount` is the number of page-table entries pointing to the page, while `_count` is a general reference count. There are a number of subtleties around the use of these fields, though, especially `_mapcount`, which helps with the management of compound pages as well. Here, Joonsoo adds another field to the second union:

在第二个联合体（unicon）中，`counters` 和最内层的匿名结构体（译者注，即本文引用代码中加 `/* SLUB */` 注释的结构体）由 SLUB 内存分配器使用，`units` 字段由 SLOB 内存分配器使用。`_mapcount` 字段和 `_count` 字段都是用来为 `struct page` 存放一些计数值；其中 `_mapcount` 存放的是和该物理页有关的页表条目的数目，而 `_count` 则用来做一般引用计数。围绕这些字段的使用存在许多细微之处，特别是 `_mapcount`，该字段还和处理复合页（compound pages）有关。在第二个联合体（union）中，Joonsoo 增加了一个新字段：

	unsigned int active;	/* SLAB */

> It is the count of active objects, again taken from `struct slab`.

它用来记录 slab 中当前已使用（active）的 slab object 的个数，也是从原 `struct slab` 中提取出来的。

> Next we have:

接下来是  `struct page` 中 涉及 Joonsoo 修改的第三部分：

	union {
		struct list_head lru;
		struct {
			struct page *next;
			int pages;
			int pobjects;
		};
		struct list_head list;
		struct slab *slab_page; 
	};

> For anonymous and page-cache pages, `lru` holds the page's position in one of the least-frequently-used lists. The anonymous structure is used by SLUB, while `list` is used by SLOB. The slab allocator uses `slab_page` to refer back to the containing `slab` structure. Joonsoo's patch complicates things here in an interesting way: he overlays an `rcu_head` structure over `lru` to manage the freeing of the associated slab using read-copy-update. Arguably that structure should be added to the containing union, but the current code just uses `lru` and casts instead. This trick will also involve moving `slab_page` to somewhere else in the structure, but the current patch set does not contain that change.

对于匿名页（anonymous page）和高速缓存页（page-cache page），`lru` 字段用于将其 `struct page` 结构体加入该页所归属的 LRU 链表中（译者注： LRU 链表 即 least-frequently-used lists，包括活动链表和非活动链表两个链表，用于页框回收）。`lru` 下面的那个匿名 `struct` 结构是被 SLUB 所使用，而该联合体的第三个成员 `list` 则由 SLOB 使用。slab 分配器使用第四个成员 `slab_page` 字段来指向包含该物理页的 slab 结构。Joonsoo 的补丁修改使用了编程技巧使得代码看起来有点复杂：他在 `lru` 所在的联合体（union）中新增了一个 `rcu_head` 字段（译者注，因为是在同一个 union 中且 `lru` 的 类型 `struct list_head` 和 `rcu_head` 的类型 `struct rcu_head` 大小相同，所以两者复用相同大小的内存，即原文中所谓的 overlay），该新增字段用于利用 RCU（read-copy-update） 机制释放相关 slab。这么做是否合适暂不讨论，但补丁这么做只是利用 `lru` （译者注，即利用 `lru` 这块内存调用 `call_rcu()`，具体参考[`slab_destroy()`](https://elixir.bootlin.com/linux/v3.13/source/mm/slab.c#L1970)），同时避免了类型强制转换。Joonsoo 原本还打算将该联合体中的 `slab_page` 字段移到别处去，但目前来看，当前的补丁中还未对此进行修改。

> The next piece is:

下一处比较复杂的代码如下（译者注，此处修改和 Joonsoo 的补丁并无关系，本文介绍它只是因为这里又是一个复杂的联合体）：

	union {
		unsigned long private;
	#if USE_SPLIT_PTLOCKS
		spinlock_t ptl;
	#endif
		struct kmem_cache *slab_cache;
		struct page *first_page;
	};

> The `private` field essentially belongs to whatever kernel subsystem has allocated the page; it sees a number of uses throughout the kernel. Filesystems, in particular, make heavy use of it. The `ptl` field is used if the page is used by the kernel to hold page tables; it allows the page table lock to be split into multiple locks if the number of CPUs justifies it. In most configurations, a system containing four or more processors will split the locks in this way. `slab_cache` is used as a back pointer by slab and SLUB, while `first_page` is used within compound pages to point to the first page in the set.

`private` 字段的用途是方便那些分配了该物理页的内核子系统在其对应的 `struct page` 上存放一些私有的数据；内核中有不少像这样的使用场景。特别地，文件系统就大量使用该字段。`ptl` 是一个自旋锁，当一个物理页被内核用于存放页表时可以利用该自旋锁确保内核互斥地访问该物理页上的页表；如果 CPU 的数量满足要求（译者注，参考宏 `USE_SPLIT_PTLOCKS` 的[定义](https://elixir.bootlin.com/linux/v3.10/source/include/linux/mm_types.h#L26)），内核允许使用物理页自己的自旋锁（译者注，即 `struct page` 的 `ptl`）来代替单一的全局页表锁（译者注，即 [`struct mm_struct` 的 `page_table_lock`](https://elixir.bootlin.com/linux/v3.10/source/include/linux/mm_types.h#L345)，从而利用多核性能提高并发性，这就是所谓的 “split” 的概念）。在大多数配置中，如果一个系统包含四个或更多处理器则可以启用该特性。 `slab_cache` 被 slab 和 SLUB 用于反向指针，而 `first_page` 用于在管理复合页（compound pages）时指向集合中的第一个页。

> After this union, one finds:

在这个联合体后面是如下代码：

	#if defined(WANT_PAGE_VIRTUAL)
		void *virtual;
	#endif /* WANT_PAGE_VIRTUAL */

> This field, if it exists at all, contains the kernel virtual address for the page. It is not useful in many situations because that address is easily calculated when it is needed. For systems where high memory is in use (generally 32-bit systems with 1GB or more of memory), `virtual` holds the address of high-memory pages that have been temporarily mapped into the kernel with `kmap()`. Following `private` are a couple of optional fields used when various debugging options are turned on.

该字段（指 `virtual` 指针变量），如果存在的话，将包含该物理页的内核虚拟地址。在许多情况下该字段并没用什么实际的用处，因为在需要时可以很容易地计算出该地址值。对于使用高端内存（high memory）的系统（通常指的是具有 1GB 或更多内存的 32 位系统），`virtual` 保存了使用 `kmap()` 临时映射到内核的高端内存页的地址。在 `private` 字段再往后是一些可选字段，用于各种功能调试。

> With the changes described above, Joonsoo's patch moves much of the information previously kept in `struct slab` into the `page` structure. The remaining fields are eliminated in other ways, leaving `struct slab` with nothing to hold and, thus, no further reason to exist. These structures are not huge, but, given that there can be tens of thousands of them (or more) in a running system, the memory savings from their elimination can be significant. Concentrating activity on `struct page` may also have beneficial cache effects, improving performance overall. So the patches may well be worthwhile, even at the cost of complicating an already complex situation.

通过上述更改，Joonsoo 的补丁将先前保存在 `struct slab` 中的大部分信息移到 `struct page` 中。剩下的字段以其他方式被移除后，使得 `struct slab` 已经失去了存在的价值。像 `struct slab` 这样的结构体类型并不大，但是，考虑到在运行的系统中可能存在数万（乃至更多）个这样的结构体实例，因此取消它们还是可以节省大量内存的。将这些信息集中保存在 `struct page` 上还有一个好处就是可以利用高速缓存对 它们进行访问，从而提高整体性能。所以这个补丁还是很有价值的，虽然它把已经很复杂的 `struct page` 结构体变得更复杂了。

> And the situation is indeed complex: `struct page` is a complicated structure with a number of subtle rules regarding its use. The saving grace, perhaps, is that it is so heavily used that any kind of misunderstanding about the rules will lead quickly to serious problems. Still, trying to put more information into this structure is not a task for the faint of heart. Whether Joonsoo will succeed remains to be seen, but he clearly is not the first to eye `struct page` as a place to stash some useful memory management information.

以上内容确实很复杂：`struct page` 不仅定义上晦涩难懂，而且使用上还需要注意许多微妙的规则。或许，其带来的唯一的“好处”（译者注，原文称其为 `saving grace` ，但明显是反语）就是，该结构体在内核中被如此大量地使用，以至于任何对它操作上的忽视都会迅速导致非常严重的后果（译者注，意思就是强调对它的使用我们一定要小心、小心、再小心）。任何试图对该结构体的定义进行修改的人都需要具备一定的勇气。Joonsoo 是否会成功还有待观察，但很显然，他早已不是第一个试图吃螃蟹的人了。

[1]: http://tinylab.org
