---
layout: post
draft: true
author: 'Wang Chen'
title: "LWN 517465: 为 “巨页”（huge page）增加一个 “零页”（zero page）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-517465/
description: "LWN，中文翻译，为 “巨页”（huge page）增加一个 “零页”（zero page）"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Adding a huge zero page](https://lwn.net/Articles/517465/)
> 原创：By Jonathan Corbet @ Sept. 26, 2012
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Shaolin Deng](https://github.com/ShaolinDeng)

The [transparent huge pages](https://lwn.net/Articles/423584/) feature allows applications to take advantage of the larger page sizes supported by most contemporary processors without the need for explicit configuration by administrators, developers, or users. It is mostly a performance-enhancing feature: huge pages reduce the pressure on the system's translation lookaside buffer (TLB), making memory accesses faster. It can also save a bit of memory, though, as the result of the elimination of a layer of page tables. But, as it turns out, transparent huge pages can actually increase the memory usage of an application significantly under certain conditions. The good news is that a solution is at hand; it is as easy as a page full of zeroes.

[透明巨页](/lwn-423584/)（Transparent Huge Pages，简称 THP，下文直接使用英文简称，不再翻译）功能允许内核为应用程序启用当代大多数处理器所支持的更大的内存页框，而无需系统管理员，开发人员，或者用户进行明确的指定或者配置。该特性主要是用于提升内核的性能：“巨页”（huge page，或称 “大页”。译者注，下文直接使用不再翻译）减小了系统 “转换后援缓冲区（Translation Lookaside Buffer，简称 TLB）” 的压力，使内存访问速度更快。同时也可以节省一些内存，因为使用它可以少用一层页表。但是，在实际使用中人们发现，THP 在某些条件下会导致应用程序的内存使用量显著增加。但好消息是，我们现在已经有了应对的方案；该方案非常简单，就和当年我们处理普通小页时采用的 “零页” 一样。

Transparent huge pages are mainly used for anonymous pages — pages that are not backed by a specific file on disk. These are the pages forming the data areas of processes. When an anonymous memory area is created or extended, no actual pages of memory are allocated (whether transparent huge pages are enabled or not). That is because a typical program will never touch many of the pages that are part of its address space; allocating pages before there is a demonstrated need would waste a considerable amount of time and memory. So the kernel will wait until the process tries to access a specific page, generating a page fault, before allocating memory for that page.

THP 主要用于匿名页（anonymous pages），即那些不对应于磁盘上特定文件内容的内存页框。这些页框构成了进程的数据区（译者注，包括了栈区，通过 `malloc()` 扩展的堆区，以及通过 `mmap()` 扩展的共享内存区）。当我们创建或扩展一个匿名内存区时，内核并不会立即分配实际的页框（无论是否启用了 THP 功能）。那是因为典型的程序并不会同时访问其地址空间中的多个页框（译者注，局部性原理）；在有明确的访问动作之前就分配页框只会浪费大量的时间和内存。因此，内核将一直等待，直到该进程尝试访问特定页并触发缺页异常时，才会为该页实际分配物理内存（即页框）。

But, even then, there is an optimization that can be made. New anonymous pages must be filled with zeroes; to do anything else would be to risk exposing whatever data was left in the page by its previous user. Programs often depend on the initialization of their memory; since they know that memory starts zero-filled, there is no need to initialize that memory themselves. As it turns out, a lot of those pages may never be written to; they stay zero-filled for the life of the process that owns them. Once that is understood, it does not take long to see that there is an opportunity to save a lot of memory by sharing those zero-filled pages. One zero-filled page looks a lot like another, so there is little value in making too many of them.

但是，即便内核针对匿名页的访问已经做了很多性能优化，改进的地方依然存在。内核总是会用零值对新创建的匿名页进行填充；这么做是为了避免泄露先前使用该页框的用户所留下的任何数据。程序通常会依赖于这个内存初始化假设；因为它们知道新分配的内存一开始都被填充为零，所以不需要自己再对其进行初始化。事实证明，这其中的许多页框可能永远也不会被写入；也就是说它们在其归属的进程的生命周期中会始终保持零字节填充的状态。一旦理解了这一点，很自然地我们就会发现可以通过共享零字节填充的页框（译者注，即先前我们所谓的“零页”，下文直接称之为 “zero page”））来节省大量内存。一个 zero page 对所有人看起来都是一样的，为其创建多份拷贝并没有什么意义。

So, if a process instantiates a new (non-huge) page by trying to read from it, the kernel still will not allocate a new memory page. Instead, it maps a special page, called simply the "zero page," into the process's address space instead. Thus, all unwritten anonymous pages, across all processes in the system, are, in fact, sharing one special page. Needless to say, the zero page is always mapped read-only; it would not do to have some process changing the value of zero for everybody else. Whenever a process attempts to write to the zero page, it will generate a write-protection fault; the kernel will then (finally) get around to allocating a real page of memory and substitute it into the process's address space at the right spot.

因此，如果一个进程以只读方式创建一个新的页（译者注，这里还未涉及 huge page，仍然是指原先内核中支持的小页，譬如，针对 x86 平台，指的是 4KB 大小的页框），内核并不会立即分配新的内存页框。而是将一个特殊的页框（即 zero page ）映射到进程的地址空间中。这样，系统中所有进程中的所有还未执行写入操作的匿名页实际上都共享这个特殊的页框。不用说，zero page 始终以只读方式映射；任何进程一旦要改变初始的零值，则原先建立的与 zero page 的映射关系就会被断开。也就是说，只要进程尝试对 zero page 执行写入，就会触发写保护异常（write-protection fault）；导致内核（最终）真正分配一个内存页框并在进程地址空间中将原先映射的 zero page 替换掉。

This behavior is easy to observe. As Kirill Shutemov [described](https://lwn.net/Articles/515526/), a process executing a bit of code like this:

我们很容易就能观察到内核的这种行为。正如 Kirill Shutemov [所描述的那样][1]，假如一个进程执行如下代码：

```
    posix_memalign((void **)&p, 2 * MB, 200 * MB);
    for (i = 0; i < 200 * MB; i+= 4096)
        assert(p[i] == 0);
    pause();
```

will have a surprisingly small resident set at the time of the `pause()` call. It has just worked through 200MB of memory, but that memory is all represented by a single zero page. The system works as intended.

我们会惊讶地发现在调用 `pause()` 时该进程在主存中所占用的空间（[Resident Set Size，简称 RSS][2]）相当地小。虽然代码显示其访问了 200MB 大小的内存空间，但由于这么大的虚拟内存地址空间背后只映射了一个 zero page。所以正如上节我们所介绍的，内核实际为其分配的物理内存其实很小。

Or, it does until the transparent huge pages feature is enabled; then that process will show the full 200MB of allocated memory. A growth of memory usage by two orders of magnitude is not the sort of result users are typically looking for when they enable a performance-enhancing feature. So, Kirill says, some sites are finding themselves forced to disable transparent huge pages in self defense.

但是一旦启用 THP 功能，情况则发生变化；同样的进程显示其分配了整整 200MB 的物理内存。开启增强性能的功能反而导致内存使用量增长了两个数量级（译者注，参考上文 [Kirill 的描述][1]，具体对比数据是：不
启用 THP 的内存消耗是 大约 400KB，而启用 THP 后是 200MB），这绝不是用户所期望看到的结果。据 Kirill 介绍，甚至发现有些客户为了避免该问题而不得不干脆禁用了 THP 特性。

The problem is simple enough: there is no huge zero page. The transparent huge pages feature tries to use huge pages whenever possible; when a process faults in a new page, the kernel will try to put a huge page there. Since there is no huge zero page, the kernel will simply allocate a real zero page instead. This behavior leads to correct execution, but it also causes the allocation of a lot of memory that would otherwise not have been needed. Transparent huge page support, in other words, has turned off another important optimization that has been part of the kernel's memory management subsystem for many years.

原因很简单：目前内核中并没有针对 huge page 的 zero page（译者注，也称 huge zero page，下文直接使用不再翻译）。THP 功能会尽可能尝试使用 huge page；因此每次进程执行缺页异常处理时，内核都会尝试分配一个 huge page。由于内核不支持 huge zero page，内核将直接分配一个真正的填充了全零字节 的 huge page。这种行为本身并没有错，但却导致大量内存被分配，而这实际上是不必要的。换句话说，我们启用了 THP 功能，却把原本存在的另一个优化特性（zero page，已经在内核内存管理子系统中存在了多年）给弄丢了。

Once the problem is understood, the solution isn't that hard. Kirill's patch adds a special, zero-filled huge page to function as the huge zero page. Only one such page is needed, since the transparent huge pages feature only uses one size of huge page. With this page in place and used for read faults, the expansion of memory use simply goes away.

一旦理解了问题的症结，解决的方法其实并不复杂。Kirill 的补丁添加了一个特殊的，预先填充为全零的 huge page，即前文我们所述的 huge zero page。因为 THP 功能只使用一种类型的 huge page，所以我们只需要一个这样的页。在缺页异常处理中使用该 huge zero page 后，内存使用量变大的问题就解决了。（译者注，Kirill 的补丁集最终随 3.8 版本合入内核主线，具体的修改可以参考 [这里][3]。）

As always, there are complications: the page is large enough that it would be nice to avoid allocating it if transparent huge pages are not in use. So there's a lazy allocation scheme; Kirill also added a reference count so that the huge zero page can be returned if there is no longer a need for it. That reference counting slows a read-faulting benchmark by 1%, so it's not clear that it is worthwhile; in the end, the developers might conclude that it's better to just keep the zero huge page around once it has been allocated and not pay the reference counting cost. This is, after all, a situation that [has come about before](https://lwn.net/Articles/340370/) with the (small) zero page.

当然事情不会就如此简单：由于这个 huge zero page 还是挺大的（2MB），所以如果没有启用 THP  功能，最好不要为它分配内存。因此引入了一个延迟分配（lazy allocation）的方案（译者注，参考提交的补丁修改 [“thp: lazy huge zero page allocation”][4]）；Kirill 还为 huge zero page 添加了引用计数，以便在不再需要时可以将该 huge zero page 释放掉（译者注，参考提交的补丁修改 [“thp: implement refcounting for huge zero page”][5]）。在缺页异常处理的基准测试中，加入引用计数后发现会使运行速度降低 1%，导致大家对是否需要使用引用计数产生了怀疑；基于以上考虑，开发人员可能会得出这样的结论：为了避免引用计数带来的开销，一旦分配了 huge zero page 最好就不要释放掉。类似的情况在以前处理（小）zero page 时 [也出现过][6]（译者注，small zero page 在缺页异常中处理经历过的反复包括 2.6.24 中的 [“remove ZERO_PAGE”][7] 和 2.6.32 中的 [“mm: reinstate ZERO_PAGE”][8]）。

There have not been a lot of comments on this patch; the implementation is relatively straightforward and, presumably, does not need a lot in the way of changes. Given the obvious and measurable benefits from the addition of a huge zero page, it should be added to the kernel sometime in the fairly near future; the 3.8 development cycle seems like a reasonable target.

目前为止针对该补丁还没有很多的评论；由于在实现上相对简单，想必应该不会再有什么太大的变化。鉴于增加一个 huge zero page 可以为内核带来的好处很明显，相信该补丁应该会在不久的将来被合入内核主线；目前看来合理的合入时间点应该会是在 3.8 版本的开发周期期间（译者注，该补丁集最终 [随 3.8 版本合入内核主线][3]）。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://lwn.net/Articles/515526/
[2]: https://en.wikipedia.org/wiki/Resident_set_size
[3]: https://kernelnewbies.org/Linux_3.8#Huge_Pages_support_a_zero_page
[4]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=78ca0e679203bbf74f8febd9725a1c8dd083d073
[5]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=97ae17497e996ff09bf97b6db3b33f7fd4029092
[6]: https://lwn.net/Articles/340370/
[7]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=557ed1fa2620dc119adb86b34c614e152a629a80
[8]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=a13ea5b759645a0779edc6dbfec9abfd83220844
