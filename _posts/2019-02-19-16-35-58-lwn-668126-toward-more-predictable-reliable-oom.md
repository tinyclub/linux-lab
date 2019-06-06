---
layout: post
draft: true
author: 'Wang Chen'
title: "LWN 668126: 更加可靠（reliable）和更可预期（predictable）的 OOM 处理机制"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-668126/
description: "LWN 中文翻译，更加可靠和更可预期的 OOM 处理机制x"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Toward more predictable and reliable out-of-memory handling](https://lwn.net/Articles/668126/)
> 原创：By Jonathan Corbet @ Dec. 16, 2015
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Shaowei Wang](https://github.com/shaoweiaaron)

> The kernel's out-of-memory (OOM) behavior has been a topic of discussion almost since the inception of the linux-kernel mailing list. Opinions abound on how the kernel should account for memory, whether it should allow memory to be overcommitted, what it means to be out of memory, and what should be done when that situation comes about. There seems to be general agreement on only one thing: OOM situations are bad, and the kernel's handling of OOM situations is even worse. Over the years, numerous developers have tried to improve the situation; the latest attempt can be seen in two patch sets from Michal Hocko.

自有 Linux 内核（linux-kernel）邮件列表以来，有关内核中 “内存不足（Out-Of-Memory，简称 OOM）” 的行为一直是讨论的话题之一。关于内核应如何分配内存，是否应该允许内存被超额使用（overcommitted），内存不足意味着什么以及在出现这种情况时应该采取什么措施的意见比比皆是。目前看来似乎大家只对一件事情达成了一致意见，那就是：出现 OOM 是一种很糟糕的状态，而内核针对 OOM 的处理能力则更加糟糕。多年来，许多开发人员都在试图改变这种状况；其中最新的尝试来自 Michal Hocko，他提交了如下两个补丁集。

## OOM 检测（OOM detection）

（译者注，“OOM detection” 补丁集最终随 4.7 版本合入内核主线，具体补丁修改可以参考 [mm, oom: rework oom detection][1]。）

> The [first patch set](https://lwn.net/Articles/667939/) tries to answer a question that one might think would be obvious: how do we know when the system is out of memory? The problem is that a running system is highly dynamic. The lack of a free page to allocate at the moment does not mean that such pages could not be created; given the high cost of invoking the OOM killer, it is best not to declare an OOM situation if the kernel might be able to scrounge some memory from somewhere. Current kernels, though, are a bit unpredictable regarding when they give up and, in some cases, might wait too long.

第一个补丁集试图解答一个在大部分人看来可能不是问题的问题：我们该如何知道系统何时会发生内存不足？但问题是正在运行的系统状态处于随时变化之中。在实际收到分配内存请求的那一刻找不到空闲的页框并不意味着最终分配就无法完成（译者注，内核会尝试通过直接或间接回收的方式回收一些内存来尽量满足本次分配请求），考虑到使用 “内存不足杀手（Out-Of-Memory Killer，或简称 OOM Killer）” 代价有点高，如果能有别的方法回收一些内存，就最好不要触发它（译者注，OOM Killer 是内核内存管理子系统特性之一，触发该特性会在内存不足的状况下，通过一定的算法挑选出合适的进程，并将其杀死后释放和回收其内存，从而缓解内存紧张的局势。下文直接使用该英文简称，不再翻译）。但是，当前的内核运行 OOM Killer 所花费的时间有点不可预期，在某些情况下可能会等待太长的时间。

> If there are no pages to satisfy an allocation request, the kernel will perform direct reclaim to try to free some memory. In some cases, direct reclaim will be successful; that happens, for example, if it finds clean pages that can be immediately repurposed. In other cases, though, reclaiming pages requires writing them back to backing store; those pages will not be available for what is, from a computer's perspective, a long time. Still, they should become available eventually, so the kernel is justifiably reluctant to declare an OOM situation for as long as reclaimable pages exist.

如果没有足够的页框满足分配请求，内核将执行直接回收（direct reclaim）以尝试释放一些内存。有时直接回收会成功；例如，如果能找到可以立即使用的空闲页，回收就会成功。但在其他情况下，回收过程需要将一些页框上的内容回写（writeback）到二级存储上（以腾出空闲的内存页框）；从处理器的角度来看，这些页框很长一段时间内都不可用（译者注，writeback 涉及磁盘读写，速度慢得多）。当然，最终这些页框会变成可分配状态，因此只要还存在可回收的页框，内核就有充分的理由不启动 OOM Killer。

> The problem is that there are no real bounds on how long it might take for "reclaimable" pages to actually be reclaimed, for a number of reasons. Additionally, the allocator can conceivably find itself endlessly retrying if a single page is reclaimed, even if that page cannot be used for the current allocation request. As a result, the kernel can find itself hung up in allocation attempts that do not succeed, but which do not push the system into OOM handling.

问题在于，由于多种原因，我们并不知道内核需要花费多长的时间才可以完成对这些理论上 “可回收” 的内存页框的实际回收动作。一种可以预见的情况是，在回收单个页框时，分配器会进入无休止的重试，而那个回收的页框也无法被用于当前的分配请求。最终的结果是分配尝试一直无法成功，这导致了内核被挂起，而且还无法触发 OOM 的处理（译者注，以上描述参考补丁 [mm, oom: rework oom detection][1] 对 `zone_reclaimable` 行为的介绍）。

> Michal's patch defines a new heuristic for deciding when the system is truly out of memory. When an allocation attempt initially fails, the logic is similar to what is done in current kernels: a retry will be attempted (after an I/O wait) if there is a memory zone in the system where the sum of free and reclaimable pages is at least as large as the allocation request. If the retries continue to fail, though, a couple of changes come into play.

Michal 的补丁定义了一种新的试探（heuristic）算法，用于决策系统何时真正进入内存不足状态。当初次分配尝试失败时，处理逻辑仍旧和当前内核类似：只要系统中还有一个内存域（zone）其空闲页和可回收页的数量之和满足内存分配请求的要求，则内核在进行一段时间的读写等待后会发起重试。但是，如果重试仍然失败，那么在新的补丁中，内核行为将与现在有所不同。

> The first of those is that there is an upper bound of sixteen retries; after that, the kernel gives up and goes into OOM-handling mode. That may bring about an OOM situation sooner than current kernels (which can loop indefinitely) will, but, as Michal [put it](https://lwn.net/Articles/668133/): "`OOM killer would be more appropriate than looping without any progress for unbounded amount of time.`" Beyond that, the kernel's count of the number of reclaimable pages is discounted more heavily after each unsuccessful retry; after eight retries, that number will be cut in half. That makes it increasingly unlikely that the estimate of reclaimable pages will motivate the kernel to keep retrying.

首先，补丁中定义了重试的上限（最多 16 次）；一旦重试次数达到最大值（仍然失败），内核将放弃重试并进入 OOM 处理模式。比起当前的内核（重试次数不限），这么做或许会更快地触发 OOM 处理，但是，正如 Michal [所解释的那样][4]：“`启动 OOM Killer 总比没有任何进展地无限尝试下去要好吧。`” 此外，每次重试失败后，内核会快速减少可回收页框数量的估算值；八次重试后，这个数值将减少一半。这种对可回收页框数量的估算方法使得内核（在多次失败后）趋向于放弃重试。

> The result of these changes is that the kernel will go into OOM handling in a more predictable manner when memory gets tight. Users will still curse the results, but the system as a whole should more reliably survive OOM situations.

以上更改的效果是，当内存变得紧张时，内核将以更加可预期（predictable）的方式进入 OOM 处理。虽然最终仍然无法避免用户的进程被杀死，但我们在 OOM 状态下挽救整个系统的行为将变得更加可靠。

## OOM 收割机（The OOM reaper）

（译者注，“OOM reaper” 补丁集最终 [随 4.6 版本合入内核主线][3]，具体补丁修改可以参考 [mm, oom: introduce oom reaper][2]。）

> At least, that should be the case if the OOM killer is actually able to free pages when the kernel invokes it. As [has been seen](https://lwn.net/Articles/627419/) in recent years, it is not that hard to create a situation where the OOM killer is unable to make any progress, usually because the targeted process is blocked on a lock and the OOM situation itself prevents that lock from being released. If an OOM-killed process cannot run, it cannot exit and, thus, it cannot free its memory; as a result, the entire OOM-killing mechanism fails.

如果 OOM Killer 被内核激活后的确释放了内存，那么应该说这番努力还算没有白费。但正如近年来 [所看到的][5]，经常出现 OOM Killer 不成功的情况，这通常是因为那些 “目标进程”（ targeted process，译者注，即被 OOM Killer 选中并杀死的进程）因为等待锁而被阻塞，而在 OOM 状态下这些锁又无法被释放。如果一个被 OOM Killer 所选中杀死的进程得不到运行，它就无法退出，也就无法释放其内存；结果，导致整个 OOM Killer 机制失效。

> The observation (credited to Mel Gorman and Oleg Nesterov) at the core of Michal's [OOM reaper patch set](https://lwn.net/Articles/666024/) is that it is not necessary to wait for the targeted process to die before stripping it of much of its memory. That process has received a SIGKILL signal, meaning it will not run again in user mode. That, in turn, means that it will no longer access any of its anonymous pages. Those pages can be reclaimed immediately without changing the end result.

Michal 的 [内存不足收割机（OOM reaper，译者注，reaper，取其回收内存如同收割庄稼的意思，下文直接使用英文不再翻译）补丁集][6] 的核心思想（感谢 Mel Gorman 和 Oleg Nesterov 为该补丁的思路做出的贡献）是：没有必要等待 “目标进程” 结束后再回收其大部分的内存。该进程已收到 SIGKILL 信号，这意味着它不会在用户模式下再次运行。也就是说，它也不会再访问其名下的任何匿名页（anonymous pages）。所以我们可以立即回收这些页框，这对最终的结果并不会造成什么影响。

> The OOM reaper is implemented as a separate thread; this is done because the reaper must be able to run when it is called upon to do its work. Other kernel execution mechanisms, such as workqueues, might themselves be blocked by the OOM situation, so they cannot be counted upon. If this patch is merged, the `oom_reaper` thread will sit unused on the majority of Linux systems out there, but it will be certain to be available on the systems where it is needed.

OOM reaper 作为一个单独的线程实现；这样做是因为 reaper 必须能够不受干扰地在需要时立即开始运行并完成其工作。其他内核运行机制，例如工作队列（workqueues），在 OOM 状态下本身可能就会被阻塞，因此在此并不适用。内核加入该补丁后，在绝大多数 Linux 系统上 `oom_reaper` 线程大部分时间都处于空闲状态，只有当需要时才会被唤醒。

> The reaper is not without its rough edges. It must still take the `mmap_sem` lock to free the pages, meaning that it could be blocked if `mmap_sem` is held elsewhere. Still, Michal says that the probability of trouble "`is reduced considerably`" compared to current kernels. One other potential problem is that, if the targeted process is dumping core at the time it is killed, removing its pages may corrupt the dump. This tradeoff is worthwhile, though, Michal says, since keeping the system running is more important in such situations.

收割机上没有粗糙的割刀那就不是收割机了（译者注，此句为双关语，言下之意就是 OOM reaper 机制也同样存在一些问题，见下文的介绍）。它仍然必须获取 `mmap_sem` 锁来释放页，这意味着如果 `mmap_sem` 被他人抢占，则该 reaper 线程也同样会被阻塞。尽管如此，Michal 表示，与当前的内核相比，这个麻烦发生的可能性 “`已经大大地被降低了`”。另一个潜在的问题是，“目标进程” 在退出的过程中会对内核进行转储（dump core），如果恰好在此时回收其内存页可能会破坏该操作。但权衡下来这么做还是值得的，Michal 说，因为在这种情况下保持系统运行更为重要。

> Memory-management patches are notoriously difficult to get merged into the kernel. With regard to the OOM detection patch, Michal said the work "`has been sitting and waiting for the fundamental objections for quite some time and there were none`". He would like to see it merged in 4.6 or thereafter. Objections to the OOM reaper have also been hard to find, but there has been no talk yet as to when that patch might head for the mainline. Once these patches get there, the OOM-handling subsystem may work a little better, but it seems unlikely that users will appreciate it any more than they do now.

众所周知，内存管理相关的补丁很难被内核主线所接纳。对于 “OOM detection” 补丁，Michal 表示，“`已经等待了很长一段时间了，但始终没有收到什么大的反对意见`”。他希望看到它被合入 4.6 版本或者后继的版本。人们也很难找到对 “OOM reaper” 补丁的反对意见，但目前还没有人讨论这个补丁什么时候可以进入主线。一旦这些补丁被合入，OOM 处理子系统的表现应该会变得更好，但要让用户比现在更喜欢它（译者注，“它” 指的是 OOM Killer 及其造成的结果）那是不太可能的事情。（译者注，“OOM reaper” 补丁集最终 [随 4.6 版本合入内核主线][3]，而 “OOM detection” 补丁集则最终随 4.7 版本合入内核主线。）

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=0a0337e0d1d134465778a16f5cbea95086e8e9e0
[2]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=aac453635549699c13a84ea1456d5b0e574ef855
[3]: https://kernelnewbies.org/Linux_4.6#Improve_the_reliability_of_the_Out_Of_Memory_task_killer
[4]: https://lwn.net/Articles/668133/
[5]: https://lwn.net/Articles/627419/
[6]: https://lwn.net/Articles/666024/
