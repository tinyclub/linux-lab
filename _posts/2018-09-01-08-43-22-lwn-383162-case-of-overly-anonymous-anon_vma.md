---
layout: post
author: 'Wang Chen'
title: "LWN 383162: 案例分析，复杂设计下的匿名页反向映射处理"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-383162/
description: "LWN 文章翻译，案例分析，复杂设计下的匿名页反向映射处理"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

> 原文：[The case of the overly anonymous anon_vma](https://lwn.net/Articles/383162/)
> 原创：By corbet @ Apr. 13, 2010
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [Wen Yang](https://github.com/w-simon)

> During the stabilization phase of the kernel development cycle, the -rc releases typically happen about once every week. [2.6.34-rc4](http://lwn.net/Articles/383198/) is a clear exception to that rule, coming nearly two weeks after the preceding -rc3 release. The holdup in this case was a nasty regression which occupied a number of kernel developers nearly full time for days. The hunt for this bug is a classic story of what can happen when the code gets too complex.

在内核开发周期的集成阶段，“-rc” 版本通常每周发布一次。但在上一个 “-rc3” 版本发布后经过了将近整整两周的时间，新版本 2.6.34-rc4 才姗姗来迟。背后的具体原因是为了定位一个令人头痛的 bug，以及 bug 解决后执行了一次全面的回归测试，这耗费了众多内核开发人员的大量时间。整个过程称得上是一个经典的案例，它告诉我们，当代码过于复杂时究竟会发生些什么。下面就给大家介绍一下这个故事。

> Sending email to linux-kernel can be an intimidating prospect for a number of reasons, one of which being that one never knows when a massive thread - involving hundreds of messages copied back to the original sender - might result. Borislav Petkov's [2.6.34-rc3 bug report](https://lwn.net/Articles/383163/) was one such posting. In this case, though, the ensuing thread was in no way inflammatory; it represents, instead, some of the most intensive head-scratching which has been seen on the list for a while.

给 linux-kernel （译者注：内核开发的邮件列表）发送电子邮件的结果可能会超出预期，原因有很多，其中一个原因是说不定就会收到海量的（数百封）的邮件回复。Borislav Petkov 发送的的[有关 2.6.34-rc3 版本测试的错误报告](https://lwn.net/Articles/383163/)就是这样一个帖子。当然这些回复绝对不是针对他个人的，这只是说明社区的确碰到了一个非常令人头痛的问题。

> The bug, as reported by Borislav, was a null pointer dereference which would happen reasonably reliably after hibernating (and restarting) the system. It was quickly recognized as being the same as [another bug report](https://bugzilla.kernel.org/show_bug.cgi?id=15680) filed the same day by Steinar H. Gunderson, though this one did not involve hibernation. The common thread was null pointer dereferences provoked by memory pressure. The offending patch was [identified by Linus](https://lwn.net/Articles/383165/) almost immediately; it's worth taking a look at what that patch did.

Borislav 报告的这个错误是有关一个空指针异常，该异常在系统休眠（并重新启动）后必现。很快它被认定与 Steinar H. Gunderson 在同一天提交的另一份错误报告是同一件事情，尽管另一份报告并未涉及系统休眠。这两个错误报告相同的部分都涉及在内存紧张时会导致空指针异常。Linus 几乎立即就[发现了](https://lwn.net/Articles/383165/)导致问题的补丁; 我们一起来看看那个补丁做了什么。

> Way back in 2004, LWN [covered the addition of the anon_vma code](http://lwn.net/Articles/75198/); this patch was controversial at the time because the upcoming 2.6.7 kernel was still expected to be an old-style "stable, no new features" release. This patch, a 40-part series which fundamentally reworked the virtual memory subsystem, was not seen as stable material, despite Linus's [attempt](http://lwn.net/Articles/86718/) to characterize it as an "implementation detail." Still, over time, this code has proved solid and has not been changed significantly since - until now.

早在 2004 年，LWN 就[介绍了有关内核增加 `anon_vma` 的事](/lwn-75198)；这个补丁在当时是有争议的，因为当时准备合入该补丁的内核版本 2.6.7 按计划其发布目标是 “稳定，不引入新功能”。尽管 Linus [试图](http://lwn.net/Articles/86718/) 将该补丁描述为 “只是实现细节上的改变” ，但实际情况是该补丁集包含了 40 个补丁修改，从根本上改造了虚拟内存子系统，对内核的稳定有很大的影响。不过，随着时间的推移，这段代码已经被证明是可靠的，并且从那以后也一直没有大的改变。

> The problem solved by anon_vma was that of locating all `vm_area_struct` (VMA) structures which reference a given anonymous (heap or stack memory) page. Anonymous pages are not normally shared between processes, but every call to `fork()` will cause all such pages to be shared between the parent and the new child; that sharing will only be broken when one of the processes writes to the page, causing a copy-on-write (COW) operation to take place. Many pages are never written, so the kernel must be able to locate multiple VMAs which reference a given anonymous page. Otherwise, it would not be able to unmap the page, meaning that the page could not be swapped out.

引入 anon_vma 的目的是根据给定的匿名页（anonymous page，譬如堆或栈）找到映射它的所有 `vm_area_struct`（VMA）结构。匿名页通常不在进程之间共享，但是调用 `fork()` 时会导致所有这些物理页在父子进程之间共享；这种共享关系会在其中一个进程对页执行写操作，即所谓的写时复制（copy-on-write，简称 COW）发生时才会被解除。由于许多物理页从不会被写入（译者注，即共享关系对这些物理页始终存在），因此内核必须能够找到映射这些匿名页的多个 VMA。否则，它将无法取消（unmap）这些 VMA 对物理页的映射，这也意味着该页无法被换出（swap out）。

> The reverse mapping solution originally used in 2.6 proved to be far too expensive, necessitating a rewrite. This rewrite introduced the `anon_vma` structure, which heads up a linked list of all VMAs which might reference a given page. So a `fork()` also causes every VMA in the child process which contains anonymous pages to be added to a the list maintained in the parent's `anon_vma` structure. The `mapping` pointer in `struct page` points to the `anon_vma` structure, allowing the kernel to traverse the list and find all of the relevant VMA structures.

内核 2.6 系列早期使用的反向映射（reverse mapping）技术被证明代价太过昂贵，需要重新设计。正是在这次重新设计中引入了 `anon_vma` 结构，该结构使用了一个链表保存了所有可能映射某个物理页的 VMA。因此调用 `fork()` 后会导致每个子进程的 VMA 以链表的方式被添加到父进程维护的 `anon_vma` 结构中。通过物理页所对应的 `struct page` 结构体中的 `mapping` 指针所指向的 `anon_vma` 结构体，内核可以遍历该链表，找到所有相关的 VMA 结构。

> This diagram, from the 2004 article, shows how this data structure looks:

下面这张图来自 2004 年的文章，展示了整个数据结构：

![anonvma](https://static.lwn.net/images/ns/anonvma2.png)
 
> This solution scaled far better than its predecessor, but eventually the world caught up. So Rik van Riel set out to make things faster, writing [this patch](http://git.kernel.org/?p=linux/kernel/git/torvalds/linux-2.6.git;a=commitdiff;h=5beb49305251e5669852ed541e8e2f2f7696c53e), which was merged for 2.6.34. Rik describes the problem this way:
 
> 	In a workload with 1000 child processes and a VMA with 1000 anonymous pages per process that get COWed, this leads to a system with a million anonymous pages in the same anon_vma, each of which is mapped in just one of the 1000 processes. However, the current rmap code needs to walk them all, leading to O(N) scanning complexity for each page.

这个解决方案在扩展性上远远超过上个版本（译者注，指 2.6 早期所使用的反向映射技术），但随着硬件和应用的发展，其不足之处开始逐渐显现。这导致 Rik van Riel 开始着手解决其性能问题，编写了[这个补丁](http://git.kernel.org/?p=linux/kernel/git/torvalds/linux-2.6.git;a=commitdiff;h=5beb49305251e5669852ed541e8e2f2f7696c53e)，并将其合入了 2.6.34。下面是 Rik 描述这个问题的原话：

	假设一个父进程其 VMA 映射了 1000 个物理页，而该父进程派生（fork）了 1000 个子进程，当这 1000 个子进程对每个匿名页都发生了写入操作（COWed），这将导致系统中存在一百万个匿名页，并且这一百万个匿名页全都指向同一个 anon_vma（译者注，在该场景下这个 anon_vma 所管理的 VMA 链表上实际会有 1001 项（包括父进程），具体参考上图），当我们从任一个匿名页出发寻找其对应的进程（即 VMA）时会发现遍历的这个链表很长但实际对应它的只有一项，也就是说整个搜索算法的时间复杂度是 O（N）的。

> Essentially, by organizing all anonymous pages which originated in the same parent under the same `anon_vma` structure, the kernel created a monster data structure which it had to traverse every time it needed to reverse-map a page. That led to the kernel scanning large numbers of VMAs which could not possibly reference the page, all while holding locks. The result, says Rik, was "catastrophic failure" when running the AIM benchmark.

该问题的本质，是源于将所有的匿名页（包括父进程自己创建的和由其子进程通过 COW 派生而来的）都组织在同一个 `anon_vma` 结构下，最终导致了一个巨大的数据结构，当每次需要对一个物理页执行反向映射时，内核不得不遍历该结构。特别地，内核是在拥有锁的条件下扫描这个巨大的 VMA 链表（译者注，这将导致内核出现长时间的阻塞行为），而其中的大部分 VMA 实际上并没有映射该物理页。按照 Rik 的说法，其结果就是在运行 AIM 基准测试时出现 “灾难性现象”。

> Rik's solution was to create an `anon_vma` structure for each process and to link those together instead of the VMA structures. This linking is done with a new structure called `anon_vma_chain`:

Rik 的解决方案是为每个进程创建一个 `anon_vma` 结构，并将它们链接在一起而不是把链接所有的 VMA 结构。这个链接是通过一个名为 `anon_vma_chain` 的新结构体类型完成的：

	struct anon_vma_chain {
		struct vm_area_struct *vma;
		struct anon_vma *anon_vma;
		struct list_head same_vma;
		struct list_head same_anon_vma;
	};

> Each `anon_vma_chain` entry (AVC) maintains two lists: all `anon_vma` structures relevant to a given vma (`same_vma`), and all VMAs which fall within the area covered by a given `anon_vma` structure (`same_anon_vma`). It gets complicated, so some diagrams might help. Initially, we have a single process with one anonymous VMA:

每个 `anon_vma_chain` 节点（简称 AVC）用于维护两个链表：一个保存了某个 vma 相关的所有 `anon_vma` 结构（通过结构体类型中的 `same_vma` 维护），另一个保存了与某个 `anon_vma` 结构所对应的所有 VMA（通过结构体类型中的 `same_anon_vma` 维护）。该数据结构设计得比较复杂，因此需要一些图来帮助我们理解。假设一开始，我们只有一个进程，该进程有一个 VMA 映射了匿名页（译者注，处于简单考虑，图上省略了匿名页、进程以及页表等信息）：

![AV Chain](https://static.lwn.net/images/ns/kernel/avchain1.png)

> Here, "AV" is the `anon_vma` structure, and "AVC" is the `anon_vma_chain` structure seen above. The AVC links to both the `anon_vma` and VMA structures through direct pointers. The (blue) linked list pointer is the `same_anon_vma` list, while the (red) pointer is the `same_vma` list. So far, so simple.

这里，“AV” 代表了 `anon_vma` 结构，“AVC” 是上面看到的 `anon_vma_chain` 结构。AVC 保存了相应的指针直接指向 `anon_vma` 和 VMA 结构（译者注，指上文 `struct anon_vma_chain` 中的 `anon_vma` 和 `vma`）。（蓝色）线条代表 `same_anon_vma` 所维护的链表，而（红色）线条则是 `same_vma` 维护的链表。到目前为止，就这么简单（译者注，当前情况下，`same_anon_vma` 和 `same_vma` 所维护的链表中都只有一项元素）。

> Imagine now that this process forks, causing the VMA to be copied in the child; initially we have a lonely new VMA like this:

假设，该进程执行 fork 操作，导致其 VMA 被复制给子进程；此时我们得到了一个新的 VMA 结构体，但还没有和其他对象建立联系：

![AV Chain](https://static.lwn.net/images/ns/kernel/avchain2.png)

> The kernel needs to link this VMA to the parent's `anon_vma` structure; that requires the addition of a new `anon_vma_chain`:

内核需要将此 VMA 加入到父进程的 `anon_vma` 结构所对应的 VMA 列表中；这需要添加一个新的 `anon_vma_chain`，如下图所示（译者注，在新的设计中，`anon_vma` 不直接管理 VMA 链表，而是通过 `anon_vma_chain` 链表间接管理 VMA 对象）：

![AV Chain](https://static.lwn.net/images/ns/kernel/avchain3.png)

> Note that the new AVC has been added to the blue list of all VMAs referencing a given anon_vma structure. The new VMA also needs its own anon_vma, though:

请注意上图中蓝色环部分，这个双向链表上目前有两个 AVC 对象和 AV 对应（译者注，每个 AVC 都指向一个 VMA 对象，分别代表了父进程和子进程对 AV 所代表的物理页的映射）。除此之外，新的 VMA 也需要自己的 `anon_vma`，所以该图继续发展如下：

![AV Chain](https://static.lwn.net/images/ns/kernel/avchain4.png)

> Now there's yet another `anon_vma_chain` structure linking in the new `anon_vma`. The new red list has been expanded to contain all of the AVCs which reference relevant `anon_vma` structures. As your editor said, it gets complicated; the diagram for the 1000-child scenario which motivated this patch will be left as an exercise for the reader.

加入新的 `anon_vma` 后需要同时增加一个 `anon_vma_chain` 结构并扩展 `same_vma` 链表将所有和子进程的 VMA 相关的 AV 对象加入到红色环中。正如前文所述，该设计使数据结构变得复杂；感兴趣的读者可以作为练习自己尝试画一下，当存在 1000 个子进程时数据结构会是一个什么样子。

> When the `fork()` happens, all of the anonymous pages in the area point back to the parent's `anon_vma` structure. Whenever the child writes to a page and causes a copy-on-write, though, the new page will map back to the child's `anon_vma` structure instead. Now, reverse-mapping that page can be done immediately, with no need to scan through any other processes in the hierarchy. That makes the lock contention go away, making benchmarkers happy.

当 `fork()` 发生时，所有匿名页都指向父进程的 `anon_vma` 结构。但是，只要子进程对页执行写操作并导致 COW 发生，新的物理页就会指向子进程的 `anon_vma` 结构。现在，反向映射该页面（指子进程 COW 后创建的新页）的速度变得很快，无需扫描层次结构中的任何其他进程。相应地，这使得对锁的竞争压力变小了，基准测试也不再会有问题。

> The only problem is that embarrassing oops issue. Linus, Rik, Borislav, and others chased after it, trying no end of changes. For a while, it seemed that a bug causing excessive reuse of `anon_vma` structures when VMAs were merged could be the problem, but fixing the bug did not fix this oops. Sometimes, changing VMA boundaries with `mprotect()` could cause the wrong `anon_vma` to be used, but fixing that one didn't help either. The reordering of chains when they were copied was also noted as a problem...but it wasn't ***the*** problem.

现在唯一的问题是令人尴尬的系统崩溃 bug。Linus, Rik, Borislav 和其他人尝试了各种方法试图找到其原因。有一段时间，发现错误可能是来自于在合并 VMA 时会导致过度重用 `anon_vma` 结构，但修复这个错误并没有解决这个问题。后来，发现使用 `mprotect()` 更改 VMA 边界可能会导致使用错误的 `anon_vma`，但修复这个错误后对那个问题仍然无济于事。再后来还怀疑复制后的重新排序也可能导致该问题 ...... 总而言之，所有能想到的问题都解决了，但始终没有找到***这个***问题的答案。

> Linus was clearly beginning to [wonder](https://lwn.net/Articles/383170/) when it might all end: "Three independent bugs found and fixed, and still no joy?" He repeatedly considered just reverting the change outright, but he was reluctant to do so; the solution seemed so tantalizingly close. Eventually he [developed another hypothesis](https://lwn.net/Articles/383171/) which seemed plausible. An anonymous page shared between parent and child would initially point to the parent's `anon_vma`:

Linus 显然开始[怀疑](https://lwn.net/Articles/383170/)这事情何时才会了结：“虽然我们发现并修复了三个毫无关系的错误，可是为什么一点也感觉不到快乐呢？” 他反复考虑是否需要彻底回退版本，但他实在不情愿这么做；离最终的解决似乎总是只有一步之遥。最终，他[提出了另一个看似合理的假设](https://lwn.net/Articles/383171/)。考虑如下场景，最初父进程和子进程之间共享的匿名页指向父进程的 `anon_vma`：

![AV Chain](https://static.lwn.net/images/ns/kernel/avchain5.png)

> But, if both processes were to unmap the page (as could happen during system hibernation, for example), then the child referenced it first, it could end up pointing to the child's `anon_vma` instead:

但是，如果两个进程都取消了对该页的映射（例如，发生了系统休眠，译者注，导致该页被换出），此后子进程恢复运行并先引用该部分内存（译者注，即发生了页换入），则该物理页最终指向了子进程的 `anon_vma`：

![AV Chain](https://static.lwn.net/images/ns/kernel/avchain6.png)

> If the parent mapped the page later, then the child unmapped it (by exiting, perhaps), the parent would be left with an anonymous page pointing to the child's `anon_vma` - which no longer exists:

如果稍后父进程再次映射了该页，而子进程又取消了对该物理页的映射（可能是由于子进程退出等原因），则此后父进程所映射的匿名页指向了一个不存在的 `anon_vma`（译者注，由于子进程退出，相关结构体 AV 和 AVC 也被释放） ：

![AV Chain](https://static.lwn.net/images/ns/kernel/avchain7.png)

> Needless to say, that is a situation which is unlikely to lead to anything good in the near future.

毋庸置疑，程序运行到现在这种状况天知道后面还会发生什么。

> The fix is straightforward; when linking an existing page to an `anon_vma` structure, the kernel needs to pick the one which is highest in the process hierarchy; that guarantees that the `anon_vma` will not go away prematurely. [Early testing](https://lwn.net/Articles/383172/) suggests that the problem has indeed been fixed. In the process, three other problems have been fixed and Linus has come to understand a tricky bit of code which, if he has his way, will soon gain some improved documentation. In other words, it would appear to be an outcome worth waiting for.

修复很简单; 当将一个物理页关联到一个 `anon_vma` 结构体时，内核应该选择进程派生层次中层次最高的那个（译者注，以上面的例子为例，即父进程的 AV）；这保证了 `anon_vma` 不会过早被删除。 [早期测试](https://lwn.net/Articles/383172/)表明问题确实已经得到了解决。在整个过程中，不仅顺带解决了其他三个问题，Linus 还亲自理解和分析了一些棘手的代码，如果按照他的方式，将很快改进一些相关文档。换句话说，这一番折腾还是值得的。

[1]: http://tinylab.org
