---
layout: post
author: 'Wang Chen'
title: "LWN 648292: 回写（Writeback）和控制组（control groups）"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-648292/
description: "LWN 文章翻译，回写和控制组"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Writeback and control groups](https://lwn.net/Articles/648292/)
> 原创：By corbet @ Jun. 17, 2015
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Chumou Guo](https://github.com/simowce)

> "Writeback" is the process of writing dirty pages in memory back to permanent storage. It is a tricky job; the kernel must arbitrate the use of limited I/O bandwidth while ensuring that the system is not overwhelmed by dirty pages. Some years ago, writeback was a perennial discussion topic at gatherings of memory-management developers; the kernel did not do as good a job as anybody would have liked. Those problems have, for the most part, been solved in recent years — until one adds control groups into the mix. A solution to that problem is in the works, though, and should be hitting the mainline in the near future.

“回写”（“writeback”）是指将内存中的 “脏” 页（dirty pages）刷新回持久存储（譬如磁盘）的操作。这是一项棘手的工作；为了确保系统中的 “脏” 页不至于太多，内核必须小心地利用有限的磁盘读写带宽（执行 writeback）。有很长一段时间，内核在这方面表现得并不如人意，所以 writeback 也一直是内存子系统开发人员聚会时喜欢讨论的一个话题；近年来，这些问题在很大程度上都得到了解决，但当内核开始支持控制组（control groups，译者注，下文直接使用其简称 cgroups，不再翻译）功能后 writeback 的问题又变得复杂起来。所幸的是，针对 cgroups 执行 writeback 的解决方案正在开发中，相信应该会在不久的将来被合入主线。（译者注，针对 cgroups 的 writeback 改造 [随 4.2 版本合入内核主线][1]。）

> Tejun Heo took some time to discuss the current situation during his LinuxCon Japan talk. The memory-management subsystem will, by default, try to limit dirty pages to a maximum of 15% of the memory on the system. There is a "magical function" called `balance_dirty_pages()` that will, if need be, throttle processes dirtying a lot of pages in order to match the rate at which pages are being dirtied and the rate at which they can be cleaned. It works reasonably well in current kernels, but it only operates globally; it is not equipped to deal with control groups.

2015 年，在由日本承办的 Linux 峰会（LinuxCon）上，Tejun Heo 在他的演讲中花了点时间和大家讨论了一下当前的现状。默认情况下，内存管理子系统会尝试将 “脏” 页的数量限制为不超过系统内存总容量的 15%。必要时，内核通过调用一个名为 `balance_dirty_pages()` 的 “神奇函数”，来抑制（throttle）一个任务不要产生太多的 “脏” 页，从而使得内核清理 “脏” 页（通过 writeback）的速度能跟得上缓存被写入（弄 “脏”）的速度。该机制在当前的内核中运行得相当不错，但它只针对全局域；并不支持 cgroups。

![Tejun Heo](https://static.lwn.net/images/conf/2015/lcj/TejunHeo.jpg)

> On the control group side, the memory controller can regulate the amount of memory that is available to any given group, while the block controller is in charge of regulating I/O bandwidth use. Writeback is clearly related to both memory use and I/O bandwidth, but the control-group mechanism offers no way to enable controllers to work together — so these two controllers don't. The result, Tejun said, is a "really sad situation."

从 cgroup 的角度来看，内存控制器（memory controller，译者注，即 cgroup 概念中的 memory subsystem，下文直接使用不再翻译）可以针对一个特定的组（译者注，这里是指 control group，而不是进程组）调节（regulate）组内进程的内存使用量，而块控制器（block controller，译者注，即 cgroup 概念中的 blkio subsystem，下文直接使用不再翻译）则负责调节一个特定组内的进程对块设备的读写带宽使用。writeback 显然与内存使用和块设备的读写都有关，但 cgroup 的运行机制并不支持同时操作两个子系统。Tejun 说，这个问题 “真的很令人沮丧”。

> The memory controller currently tags pages in memory with owner information so that it knows which control group to charge for each page. The block controller is unable to use that information, though, so it has no way of knowing which control group to charge for writeback I/O traffic. So control groups do not use the system's global throttling mechanism at all; instead, there is a "hacky" mechanism built into the memory controller itself that, according to Tejun, "does not throttle anything effectively." It ignores the global dirty-page watermarks that control throttling and is, he said, "completely broken." There has been talk of fixing the situation for at least five years but nothing has been done, leading to a certain amount of frustration.

memory controller 当前会给内存页作标记用来记录其 “所有者”（owner）的信息（译者注，即建立 `struct page` 和 memory control group 之间的关联，体现在 [`struct page` 中的 `mem_cgroup` 成员][2]），这样它就可以知道每个内存页由哪个 cgroup 负责管理。但是，block controller 却无法利用这些信息，因此它也无法知道当前的 writeback 操作所针对的是哪个 cgroup 以及该依据什么样的原则管理 writeback 的读写量。所以内核并没有针对 cgroup 使用系统全局的抑制（throttling）机制；相反，根据 Tejun 的说法，memory controller 自己内部实现了一个私有的抑制机制，并且正如 Tejun 原话所描述的那样，“该机制压根儿就不能有效地起到抑制的作用。” 由于它没有使用全局定义的、用于限制 “脏页” 量的阈值（the global dirty-page watermarks），他说，“原有的运行机制完全被破坏了”。有关如何解决这个问题的讨论至少已经持续了五年，但遗憾的是进展甚微。

## 解决 control groups 中的 writeback 问题（Fixing writeback in control groups）

> So Tejun set out to deal with the problem. His approach is driven by the idea that control-group features should not need completely new mechanisms for their implementation — writeback control in control groups should use the same mechanism that the system as a whole uses. The global mechanism should just be a degenerate form of the single-group case.

Tejun 决定开​​始着手处理这个问题。他的解决思路是：在处理 cgroup 所面对的问题上应该尽量复用原系统全局域下处理 writeback 的方法，而不是自己再发明一套新的处理机制。全局域下的处理机制可以被看成是 cgroup 特性启用后退化成单个组（single-group）的一种特殊形式（译者注，即系统上所有的进程都在一个组里）。

> There are two structures involved in writeback control in the kernel. `struct backing_dev_info` contains information about a specific device to which dirty pages are being written; it tracks the observed I/O bandwidth of the device and how it is being used. The `bdi_writeback` structure, instead, regulates writeback activity in particular. There is currently a single `bdi_writeback` structure for each `backing_dev_info` structure, and the separation of their roles is somewhat fuzzy. (Both of these structures are defined in [`include/linux/backing-dev.h`](https://lwn.net/Articles/648296/))

内核中的 writeback 控制涉及两个结构体类型。一个是 `struct backing_dev_info`，这个结构体中包含了一个当前 “脏” 页正在被回写的目标磁盘设备的信息；它记录了针对该设备进行读写的带宽状态信息以及使用这些信息（控制 writeback）的方式。另一个是 `struct bdi_writeback`，该结构体专门用于调节实际的 writeback 操作。目前 `backing_dev_info` 和 `bdi_writeback` 这两个结构体类型的运行实例是一一对应的，但说实话它们在角色分工上的界限并不是很清晰。（有关这两个结构体类型的定义具体可以参考 [`include/linux/backing-dev.h`][3]。译者注，所谓两个结构体类型的运行实例是一一对应，代码上体现为 `backing_dev_info` 结构体中内嵌了一个 `bdi_writeback` 的成员。）

> One of the first things Tejun's [control-group writeback support patch set](https://lwn.net/Articles/645708/) does is to move more writeback-specific information from `struct backing_dev_info` into the `bdi_writeback` structure. That structure then goes from a single instance per device to one instance for each control group, allowing for each group to be regulated separately. `balance_dirty_pages()` is changed to use the per-group `bdi_writeback` structure, as are other pieces of the writeback-control mechanism. Tejun described it as being mostly "a giant plumbing job."

Tejun 提交的 [支持针对 control-group 的 writeback 补丁集][4] 中首先做的事就是将更多和 writeback 有关的信息从 `struct backing_dev_info` 中转移到 `bdi_writeback` 结构中来。这样，该结构体（指 `bdi_writeback`）就从每个设备对应一个变为每个 cgroup 对应一个，允许针对单个 group 进行调节。与其他和 writeback 控制机制相关的函数类似，`balance_dirty_pages()` 函数也被改造为使用与某个 cgroup 对应的 `bdi_writeback` 结构。（译者注，参考 4.2 版本中的 [`balance_dirty_pages()` 函数][5]，相比于 4.1 版本，多了一个 `struct bdi_writeback *wb` 的参数，而其他和 writeback 控制有关的代码可以参考 [`fs-writeback.c` 文件][6] 中那些带有 `struct bdi_writeback *` 类型形参的函数。）Tejun 描述称该项改动 “工作量巨大且从上到下涉及了很多层次”。

## 细节 （Details）

> The completion of that plumbing job allows the block bandwidth controller to regulate writeback I/O, but it is missing an important piece: the throttling of processes that are dirtying more memory than can be cleaned within their group's I/O bandwidth limits. Or, more precisely, while the system can throttle processes when the global dirty-page limit is reached, it cannot throttle those that have dirtied too much of the memory that is available to their specific control group. Solving that problem is the subject of [a separate patch set](https://lwn.net/Articles/645707/) adding per-group throttling.

这项繁复的工作完成后，block controller （译者注，原文在这里称其为 block bandwidth controller，这和 block controller 应该是一个意思）就可以对 writeback 进行调节了，但这还不够，还缺少一个重要的部分：就是还需要根据 block control group 的限制对组内的进程抑制（throttle）其写入缓存的速度，避免超过对 “脏” 页的清理速度。或者，更确切地说，系统不可以仅根据全局域所定义的 “脏” 页的限制来抑制进程的写入速度，还得考虑进程所归属的 cgroup 所定义的限制。针对单个 cgroup 的写入抑制由 [另外一个单独的补丁集][7] 来解决。

> This patch set adds a new structure (`struct wb_domain`) for the control of dirty-page throttling. There is one global domain that implements the "15% of total memory" limit that exists in current kernels. Each control group gets its own `wb_domain` structure as well, to enforce limits specific to that group. When the memory-management code computes the number of pages that a process within a specific group is allowed to dirty, it looks at both the global and per-group `wb_domain` structures and uses the more restrictive of the two. A process will never be allowed to exceed the number of dirty pages allowed to its control group, but that limit may be lowered if the system as a whole has a lot of dirty pages.

这个单独的补丁集添加了一个新结构（`struct wb_domain`），用于对 “脏” 页的抑制（throttling）进行控制。当前内核中所定义的全局域的限制是不超过 “总内存的 15%”。每个 cgroup 现在也拥有了一个自己的 `wb_domain` 结构，以定义针对该组的限制。当内存管理代码对特定组中的进程计算允许写入的内存页的个数时，它需要兼顾全局和组级别的 `wb_domain` 所定义的限制，并选择两者中较强的限制作为最终的判断标准。换句话说，一个进程所能写入的缓存页的数量，首先必须保证永远不能超过其所属的 cgroup 所规定的上限，但是，（即使组内还允许有较大的写入空间）当整个系统全局域下的 “脏” 页已经太多的时候，该进程所能允许写入的缓存数也会因此受到更大的限制。

> That is still not a complete solution to the problem, though. The writeback mechanism uses the inode (open file) as its fundamental unit of control, while the memory controller applies limits on a per-page basis. Tejun explained that each makes sense within its own context, but there is a mismatch between the two that makes it harder to make those mechanisms work well together.

完整的解决方案介绍到这里还没有结束。writeback 机制使用 inode（代表一个打开的文件，译者注，后面若不特殊注明，文件和 inode 代表同一个意思）作为其基本控制单元，而 memory controller 则以页框为单位计算限制。Tejun 解释说这两者所关心的对象只在各自的上下文中有意义，而一旦要将两者关联起来考虑则存在一定的不一致性，导致两种机制协同工作起来比较困难。

> The writeback mechanism is designed to focus on a single inode at a time; among other things, writing out all of a single file's dirty pages together tends to improve disk I/O locality. When the I/O bandwidth controller first sees writeback activity for an inode, it assigns "ownership" of the inode to the control group responsible for that activity. Thereafter, all writeback activity for that inode is charged to that control group, regardless of who actually dirtied the pages. Tejun looked into making the accounting more fine-grained but, he said, the result was far too complex and wasn't worth it. In the end, one control group is usually responsible for the majority of writeback traffic to any given file.

writeback 机制在设计上一次只操作一个特定的 inode；这么做的好处之一是，将单个文件的 “脏” 页集中在一起一次性写回磁盘可以起到改善磁盘读写吞吐率的效果（译者注，由于文件系统会优化数据的存放，将一个文件的数据尽量紧挨着存放，所以对同一个文件进行读写时，磁头的移动路径会比较短，即文中所谓的 locality，从而提高了磁盘的读写效率）。读写带宽控制器（I/O bandwidth controller，译者注，即 block controller 的另一个说法）在执行针对某个 inode 的 writeback 时，会固定使用其遇到的第一个 “脏” 页所对应的 cgroup 来负责管理针对该 inode 的所有 “脏” 页的 writeback 活动，即使有些 “脏” 页对应的可能是其他的 cgroup。Tejun 曾经考虑对 inode 进行更细粒度的区分处理，但分析后认为，如此处理太复杂，得不偿失。所以，如果不加以改进的话，通常情况下，对于一个给定的文件来说，总是通过同一个 cgroup 来管理所有的 writeback 活动。

> There is still a problem, though, that the initial assignment of responsibility for any given file might be incorrect. Or the file could move from one control group to another over time. In either case, the result could be that one group finds itself charged for large amounts of writeback created by another group entirely.

但是，这么做是有问题的，譬如，对于一个给定的文件来说，有可能一开始指定使用的 cgroup 就不正确（译者注，考虑一种场景，一个文件对应的缓存页被不同 cgroup （中的任务）先后写入并发生前后覆盖）。还存在一种情况是：随着系统的运行，一个文件（inode）可能会从一个 cgroup 被转移到另一个 cgroup 中去。无论哪种情况，都可能导致 writeback 时本该由多个 cgroup 各自负责管理的 “脏页” 现在都由一个 cgroup 负责。（译者注，有关对以上两段的问题描述，更详细的说明请参考 [Tejun 提交的补丁修改说明][8] 以及正式合入时 [对 `Documentation/cgroups/blkio-controller.txt` 的修改说明][9]。）

> To resolve that issue, Tejun has posted [yet another patch set](https://lwn.net/Articles/645706/) adding "foreign cgroup inode `bdi_writeback` switching." This mechanism watches the ownership of the pages (as tracked by the memory controller) being written back to each inode. Using the [Boyer-Moore majority vote algorithm](https://en.wikipedia.org/wiki/Boyer-Moore_Majority_Vote_Algorithm), it decides which control group is responsible for the most I/O traffic. If most traffic originates in a group other than the owner of that inode, and that pattern holds for a period of time (two seconds, in the current patch), the ownership of the inode will be switched to the new "winner". Over time, that mechanism should ensure that writeback I/O traffic is charged correctly without adding the need to track things on a sub-inode level.

为了解决这个问题，Tejun 提交了[另一个补丁集][10]，可以支持所谓的 “foreign cgroup inode bdi_writeback switching”（译者注，补丁的名字暂不翻译，下文会对其进行解释）。该机制会跟踪（由 memory controller 负责）writeback 活动中和每个文件有关的 “脏” 页，并依次检查这些 “脏” 页所对应的 cgroup。利用 [Boyer-Moore 多数投票算法][11]，它可以找出哪一个 cgroup 产生的 “脏” 页数量最多。如果大多数写出的 “脏” 页都源自另外一个 group，而不是该 inode 当前所使用的 group（译者注，这里所谓的 “另一个 cgroup” 即补丁名称中所谓 foreign cgroup 的含义），并且该 foeign cgroup 所产生的 “脏” 页被持续写出了一定的时间（当前补丁中该时间长度定义为 2 秒），则当前负责该 inode 的 group 将被切换为新的 “胜出者”（即 foreign cgroup）。该机制可以确保在系统持续运行过程中倾向于总是使用正确的 group 来负责该 inode 的 writeback 活动，而这么做并不需要在 inode 之下更细节的级别上添加额外的跟踪操作（译者注，即前文所介绍的对 inode 进行更细粒度的区分处理）。

> As for the status of all this work: Tejun said that it works and is currently slated for the 4.2 merge window. That said, it is still experimental and there are probably some issues to be shaken out. At the time of the talk, only the ext2 filesystem was supported; since then, [ext4 support](https://lwn.net/Articles/648299/) has been posted as well. Each filesystem will require changes to support the new writeback mechanism, but the changes tend to be quite small. Getting those pieces into place should not take too long; then, once this work stabilizes, another longstanding Linux memory-management shortcoming should be no more.

关于以上所有工作（译者注，指本文介绍的三个补丁集）的状态：Tejun 介绍说它们进展顺利，预计可以随 4.2 的合并窗口合入内核主线。但按照他的说法，补丁仍处于试验阶段，可能还有一些问题需要解决。目前（截至大会演讲时），只支持 ext2 文件系统；会议之后，[对 ext4 的支持][12] 也发布了。为了支持新的 writeback 机制，每个文件系统都需要做相应的修改，但改动都非常小。完成这些小修改应该不会花费太长时间；一旦这项工作稳定下来后，将标志着又一个长期困扰 Linux 内存管理的问题将不复存在。（译者注，针对 cgroups 的 writeback 改造 [随 4.2 版本合入内核主线][1]。）

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://kernelnewbies.org/Linux_4.2#cgroup_writeback_support
[2]: https://elixir.bootlin.com/linux/v4.1/source/include/linux/mm_types.h#L179
[3]: https://lwn.net/Articles/648296/
[4]: https://lwn.net/Articles/645708/
[5]: https://elixir.bootlin.com/linux/v4.2/source/mm/page-writeback.c#L1511
[6]: https://elixir.bootlin.com/linux/v4.2/source/fs/fs-writeback.c
[7]: https://lwn.net/Articles/645707/
[8]: https://lwn.net/Articles/645706/
[9]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=3e1534cf4a2a8278e811e7c84a79da1a02347b8b
[10]: https://lwn.net/Articles/645706/
[11]: https://en.wikipedia.org/wiki/Boyer-Moore_Majority_Vote_Algorithm
[12]: https://lwn.net/Articles/648299/
