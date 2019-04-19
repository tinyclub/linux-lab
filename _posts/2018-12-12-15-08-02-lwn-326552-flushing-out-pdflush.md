---
layout: post
author: 'Wang Chen'
title: "LWN 326552: 一种替代 pdflush 的新方案"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-326552/
description: "LWN 文章翻译，一种替代 pdflush 的新方案"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Flushing out pdflush](https://lwn.net/Articles/326552/)
> 原创：By Goldwyn Rodrigues @ Apr. 1, 2009
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Xiaojie Yuan](https://github.com/llseek)

> The kernel page cache contains in-memory copies of data blocks belonging to files kept in persistent storage. Pages which are written to by a processor, but not yet written to disk, are accumulated in cache and are known as "dirty" pages. The amount of dirty memory is listed in `/proc/meminfo`. Pages in the cache are flushed to disk after an interval of 30 seconds. Pdflush is a set of kernel threads which are responsible for writing the dirty pages to disk, either explicitly in response to a `sync()` call, or implicitly in cases when the page cache runs out of pages, if the pages have been in memory for too long, or there are too many dirty pages in the page cache (as specified by `/proc/sys/vm/dirty_ratio`).

内核的页缓存（page cache，译者注，下文直接使用，不再翻译）将存放在持久存储设备（译者注：指掉电不丢失数据的设备，譬如磁盘）上的文件的数据块内容以副本的方式保存在内存中。写入操作过程中并不会将数据直接写入磁盘，而是先缓存在内存页上，我们称这些（缓存了数据但还未同步到磁盘上的）内存页为 “脏”（“dirty”） 页。“脏” 页的数量可以通过查看 `/proc/meminfo` 获取。每隔 30 秒，内核会将缓存中的 “脏” 页 “刷新”（flush，有时也称为 “同步”（synronization））到磁盘。pdflush 就是这样的一组用于刷新 “脏” 页的内核线程，刷新会发生在两种情况下，一种是通过显式地调用 `sync()` 函数，另一种是内核在检测出 page cache 的页框不足时被隐式触发，造成 “不足” 的原因可能是由于某些 “脏” 页在 page cache 中存留的时间太长，或者 page cache 中的 “脏” 页太多（多还是少的具体衡量标准可以通过 `/proc/sys/vm/dirty_ratio` 指定）。

> At a given point of time, there are between two and eight pdflush threads running in the system. The number of pdflush threads is determined by the load on the page cache; new pdflush threads are spawned if none of the existing pdflush threads have been idle for more than one second, and there is more work in the pdflush work queue. On the other hand, if the last active pdflush thread has been asleep for more than one second, one thread is terminated. Termination of threads happens until only a minimum number of pdflush threads remain. The current number of running pdflush threads is reflected by `/proc/sys/vm/nr_pdflush_threads`.

pdflush 线程的个数，在系统运行过程中最少两个，最多八个不等，具体随 page cache 的运行负载变化而变化；当系统繁忙时，如果等待超过一秒种都找不到可用的空闲 pdflush 线程，则内核就会创建一个新的 pdflush 线程。反之，如果最近一个进入睡眠的线程的睡眠时间超过了一秒钟，则内核会选择并终止一个 pdflush 线程。但内核不会将所有的 pdflush 线程都销毁掉，而是会维持一个下限（译者注：即 `MIN_PDFLUSH_THREADS`，反之也不会无限增多，最大值为 `MAX_PDFLUSH_THREADS`，具体可以参考 [pdflush 线程执行函数 `__pdflush()` 以及相关的注释][17]）。当前运行的 pdflush 线程数可以通过 `/proc/sys/vm/nr_pdflush_threads` 获得。

> A number of pdflush-related issues have come to light over time. Pdflush threads are common to all block devices, but it is thought that they would perform better if they concentrated on a single disk spindle. Contention between pdflush threads is avoided through the use of the `BDI_pdflush` flag on the `backing_dev_info` structure, but this interlock can also limit writeback performance. Another issue with pdflush is request starvation. There is a fixed number of I/O requests available for each queue in the system. If the limit is exceeded, any application requesting I/O will block waiting for a new slot. Since pdflush works on several queues, it cannot block on a single queue. So, it sets the `wbc->nonblocking` writeback information flag. If other applications continue to write on the device, pdflush will not succeed in allocating request slots. This may lead to starvation of access to the queue, if pdflush repeatedly finds the queue congested.

随着时间的推移，pdflush 机制逐渐暴露出一些问题。首先，pdflush 线程对系统中的所有磁盘是共享的，当然如果系统中只有一个磁盘那么该机制的表现还是不错的。内核通过在 `backing_dev_info` 结构体上设置 `BDI_pdflush` 标志用于避免 pdflush 线程之间的竞争，但是这种互斥机制会限制 “回写”（writeback，译者注：含义同前文的 “刷新” 或者 “同步”，文章中常混用，但在代码中一般使用 “writeback”。下文直接使用，不再翻译）的性能。另一个是有关 pdflush 的请求饥饿（request starvation）问题。系统中每个块设备的 I/O 请求队列可容纳的请求个数是有限的（译者注，即 `struct request_queue`  中存放 `struct request` 的个数存在最大值 `BLKDEV_MAX_RQ`，缺省为 128）。如果达到上限，任何请求 I/O 的任务将会被阻塞。由于一个 pdflush 线程有可能要同时操作多个块设备的队列，因此为了避免在其中的某一个队列上阻塞（译者注，这会导致另一个设备有请求也无法得到处理），所以 pdflush 设置 `wbc->nonblocking` 标志为 1（译者注，设置这个标志位的效果是一旦 pdflush 发现某个设备上发生拥塞则不等待，并在稍后再尝试，即采用所谓的拥塞回避策略（congestion avoidance））。但这样会造成另一个问题，就是一旦某个应用程序持续地在一个设备上执行写操作（拥塞发生），则 pdflush 将无法成功申请 I/O 请求（回避的结果）。这就造成了拥塞条件下的所谓 pdflush 请求饥饿（request starvation）问题。

> Jens Axboe in his [patch set](http://lwn.net/Articles/324833/) proposes a new idea of using flusher threads per backing device info (BDI), as a replacement for pdflush threads. Unlike pdflush threads, per-BDI flusher threads focus on a single disk spindle. With per-BDI flushing, when the `request_queue` is congested, blocking happens on request allocation, avoiding request starvation and providing better fairness.

Jens Axboe 在他的 [补丁][1] 中提出了一种新的方法，即为每个磁盘设备（译者注，内核术语中称其为 Backing Device Info，简称 BDI，下文直接使用缩略语 BDI 或者意译为磁盘）使用一个自己的刷新线程 flusher（译者注，为了和原先的 pdflush 区别，新补丁中称刷新线程为 flusher，下文翻译也直接使用该名词，不再翻译），代替原先的 pdflush 共享线程的方式。与 pdflush 机制不同的是，每个 BDI 的 flusher 刷新线程专注于自己负责的单个磁盘。当磁盘设备的 I/O 请求队列 `request_queue` 发生拥塞时，flusher 线程会在请求分配时阻塞，这么做既避免了请求饥饿（request starvation）问题也能够提供更好的公平性。（译者注，Jens 的新 Per-BDI flusher 补丁随 2.6.32 版本合入内核主线，下文在注释代码时，凡是涉及旧的 pdflush 的代码引用 2.6.31 的版本，而有关 flusher 的代码则引用 2.6.32 的版本，特此提前说明。）

> With pdflush, The dirty inode list is stored by the super block of the filesystem. Since the per-BDI flusher needs to be aware of the dirty pages to be written by its assigned device, this list is now stored by the BDI. Calls to flush dirty inodes on the superblock result in flushing the inodes from the list of dirty inodes on the backing device for all devices listed for the filesystem.

pdflush 方式下，“脏” 的 inode 链表由文件系统的超级块（super block）负责维护（译者注，参考[`struct super_block` 结构体的成员 `s_dirty`][2]）。由于在补丁中每个 BDI 的 flusher 需要知道自己负责的磁盘设备所涉及的 “脏” 页，因此该列表由 BDI 自己维护（译者注，参考[`struct bdi_writeback` 的成员 `b_dirty`][3]）。当系统发起对超级块上的 “脏” inode 进行刷新的调用时内核会遍历文件系统所关联的所有设备，对每个设备再遍历 “脏” inode 的链表，最终对链表上的每一个 “脏” inode 进行刷新。

> As with pdflush, per-BDI writeback is controlled through the `writeback_control` data structure, which instructs the writeback code what to do, and how to perform the writeback. The important fields of this structure are:

> - `sync_mode`: defines the way synchronization should be performed with respect to inode locking. If set to `WB_SYNC_NONE`, the writeback will skip locked inodes, where as if set to `WB_SYNC_ALL` will wait for locked inodes to be unlocked to perform the writeback.
> - `nr_to_write`: the number of pages to write. This value is decremented as the pages are written.
> - `older_than_this`: If not NULL, all inodes older than the jiffies recorded in this field are flushed. This field takes precedence over `nr_to_write`.

与 pdflush 一样，和每个 BDI 的 writeback 操作相关的控制信息由 `writeback_control` 这个结构体负责维护，writeback 逻辑根据该结构体中存放的信息执行具体的操作，包括操作的内容，以及操作的方式。这个结构体的重要成员如下所示：（译者注，`writeback_control` 这个结构体的具体定义参考[这里][4]。）

- `sync_mode`：定义遇到锁定的 inode 时的同步行为。如果设置为 `WB_SYNC_NONE`，则 writeback 时将跳过（skip）锁定的 inode，否则如果设置为 `WB_SYNC_ALL` 则一直等待，直到 inode 被解锁后再执行 writeback。
- `nr_to_write`：需要 writeback 的页框数。writeback 后该值会递减。
- `older_than_this`：该字段用于定义一个阈值，单位是 jiffies。如果指定了该值（即该字段不是 NULL），则只对那些存在时间大于这个阈值的 “脏” inode 进行 writeback。具体执行时对该字段的判断优先于 `nr_to_write` （译者注，所谓 “优先” 是指代码会先根据 `older_than_this` 对需要 writeback 的 inode 进行过滤（`queue_io()` -> `move_expired_inodes()`），然后再根据 `nr_to_write` 执行 writeback，具体代码逻辑参考 [`writeback_inodes_wb()` 函数][5]）。

> The `struct bdi_writeback` keeps all information required for flushing the dirty pages:

`struct bdi_writeback` 保存了用于刷新 “脏” 页所需的所有信息：

```
	struct bdi_writeback {
		struct backing_dev_info *bdi;
		unsigned int nr;
		struct task_struct	*task;
		wait_queue_head_t	wait;
		struct list_head	b_dirty;
		struct list_head	b_io;
		struct list_head	b_more_io;
		
		unsigned long		nr_pages;
		struct super_block	*sb;
	};
```

> The `bdi_writeback` structure is initialized when the device is registered through `bdi_register()`. The fields of the bdi_writeback are:

> - `bdi`: the `backing_device_info` associated with this `bdi_writeback`,
> - `task`: contains the pointer to the default flusher thread which is responsible for spawning threads for performing the flushing work,
> - `wait`: a wait queue for synchronizing with the flusher threads,
> - `b_dirty`: list of all the dirty inodes on this BDI to be flushed,
> - `b_io`: inodes parked for I/O,
> - `b_more_io`: more inodes parked for I/O; all inodes queued for flushing are inserted in this list, before being moved to `b_io`,
> - `nr_pages`: total number of pages to be flushed, and
> - `sb`: the pointer to the superblock of the filesystem which resides on this BDI.

内核中首先对 `bdi_writeback` 结构体进行初始化，然后将其传入 `bdi_register()` 函数来注册一个设备（译者注，具体的情况是，参考 [一个注册的例子][6]，考虑到 `bdi_writeback` 结构体是内嵌在 `backing_device_info` 结构体中的，所以原文中所谓对 `bdi_writeback` 的初始化和将其传入 `bdi_register()` 都是伴随对 `backing_device_info` 的初始化（通过调用 [`bdi_init()`][7]）和对 `backing_device_info` 的注册（通过调用 `bdi_register()`）完成的）。`bdi_writeback` 的成员字段包括：

- `bdi`：与此 `bdi_writeback` 关联的 `backing_device_info`，
- `task`：是一个指针，指向缺省的 flusher 线程（译者注，即执行 [`bdi_forker_task()`][8] 的线程），该线程负责生成其他具体执行刷新工作的线程（译者注，具体执行 writeback 的 Per-BDI flusher 线程的执行函数是 [`bdi_start_fn()`][9]），
- `wait`：用于同步 flusher 线程的的等待队列，
- `b_dirty`：一个链表，存放了该 BDI 上所有的 “脏” inode，
- `b_io`：一个链表，存放了等待被 writeback 的 inode，
- `b_more_io`：另一个存放等待被 writeback 的 inode 的链表，该链表上的 inode 对象来自 `b_io`，由于某种原因在上一轮处理中未能被及时 wrieback，所以从 `b_io` 中被移出来缓存在这里等待下一次被移回 `b_io` 继续处理，
- `nr_pages`：需要刷新的总页（page）数，
- `sb`：是一个指针，指向存放在此 BDI 上的文件系统的超级块。

> `nr_pages` and `sb` are parameters passed asynchronously to the the BDI flush thread, and are not fixed through the life of the `bdi_writeback`. This is done to facilitate devices with multiple filesystem, hence multiple `super_blocks`. With multiple `super_blocks` on a single device, a sync can be requested for a single filesystem on the device.

`nr_pages` 和 `sb` 用于异步地给 BDI 刷新线程传递参数，其值在 `bdi_writeback` 的生命周期内并不固定。这样做是为了方便操作某些场景下一个磁盘设备上存在多个文件系统，也就是说这个设备对应了多个 `super_block`。对于这种在单个设备上存在多个 `super_block` 的情况，可以对该设备指定某个文件系统进行同步。

> The `bdi_writeback_task()` function waits for the `dirty_writeback_interval`, which by default is 5 seconds, and initiates `wb_do_writeback(wb)` periodically. If there are no pages written for five minutes, the flusher thread exits (with a grace period of `dirty_writeback_interval`). If a writeback work is later required (after exit), new flusher threads are spawned by the default writeback thread.

在 `bdi_writeback_task()` 函数中每隔时长 `dirty_writeback_interval`（默认情况下为 5 秒）就发起一次 `wb_do_writeback(wb)` 调用。如果任务空闲达到五分钟，则 flusher 线程退出（宽限期为 `dirty_writeback_interval`）。如果在线程退出后又收到 writeback 请求，则缺省的 flusher 线程会创建新的 flusher 线程（译者注，具体 `bdi_writeback_task()` 函数代码参考[这里][10]）。

> Writeback flushes are done in two ways:

> - pdflush style: This is initiated in response to an explicit writeback request, for example syncing inode pages of a `super_block`. `wb_start_writeback()` is called with the superblock information and the number of pages to be flushed. The function tries to acquire the `bdi_writeback` structure associated with the BDI. If successful, it stores the superblock pointer and the number of pages to be flushed in the `bdi_writeback` structure and wakes up the flusher thread to perform the actual writeout for the superblock. This is different from how pdflush performs writeouts: pdflush attempts to grab the device from the writeout path, blocking the writeouts from other processes.
> - kupdated style: If there is no explicit writeback requests, the thread wakes up periodically to flush dirty data. The first time one of the inode's pages stored in the BDI is dirtied, the dirtying-time is recorded in the inode's address space. The periodic writeback code walks through the superblock's inode list, writing back dirty pages of the inodes older than a specified point in time. This is run once per `dirty_writeback_interval`, which defaults to five seconds.

触发执行 writeback 有两种方式：

- 类似 pdflush 的方式：即通过明确发起的请求触发执行 writeback，例如我们指定一个 `super_block` ，请求同步该文件系统上所有 “脏” inode 的物理页。我们可以调用 `wb_start_writeback()`，传入对应的超级块对象和要刷新的页数。该函数会尝试获取与 BDI 关联的 `bdi_writeback`结构。如果成功，它用传入的参数修改 `bdi_writeback` 结构的 `sb` 和 `nr_pages` 成员，然后唤醒 flusher 线程以 “异步” 方式执行实际的刷新动作。注意这一点和以往 pdflush 方式有所不同：pdflush 是以 “同步” 的方式在当前任务中试图独占设备，这样会阻止来自其他任务对该设备的写出（writeout）操作（译者注：这里提及的 `wb_start_writeback()` 函数在最终合入主线时被另一个[`bdi_start_writeback()`][11] 所代替而且被封装为另一个函数 [`writeback_inodes_sb()`][12] 为外部模块所调用）。
- 类似 kupdated 的方式（译者注，kupdated 是内核在采用 pdflush 机制之前执行周期刷新的一个后台任务）：即当系统没有明确发起 writeback 请求时，flusher 线程也会定期被唤醒以刷新 “脏” 数据。对于存储在 BDI 中的每个 inode 所涉及的页框第一次被弄 “脏”时，其修改时间就被记录在 inode 的地址空间（address space）中。定期 writeback 逻辑会遍历超级块的 inode 列表，将 inode 名下比较旧的 “脏” 页写回磁盘。轮询的周期由 `dirty_writeback_interval` 的值确定，默认为五秒一次。（译者注，这部分逻辑可以参考 `bdi_start_fn()` ，即 flusher 线程的执行函数中调用的 [`bdi_writeback_task()`][13]。）

> After review of the [first attempt](http://lwn.net/Articles/322920/), Jens added functionality of having multiple flusher threads per device based on the suggestions of Andrew Morton. Dave Chinner suggested that filesystems would like to have a flusher thread per allocation group. In the patch set (second iteration) which followed, Jens added a new interface in the superblock to return the `bdi_writeback` structure associated with the inode:

该补丁的 [第一个版本][14] 经审查后，Jens 采纳了 Andrew Morton 的建议，允许为每个设备创建多个 flusher 线程。Dave Chinner 建议为文件系统的每个分配组（allocation group）都指定一个 flusher 线程。在随后补丁的第二次迭代修改中，Jens 在 超级块中添加了一个新接口，可以返回与 inode 关联的 `bdi_writeback` 结构：

    struct bdi_writeback *(*inode_get_wb) (struct inode *);

> If `inode_get_wb` is NULL, the default `bdi_writeback` of the BDI is returned, which means there is only one `bdi_writeback` thread for the BDI. The maximum number of threads that can be started per BDI is 32.

如果 `inode_get_wb` 为 NULL，则返回 BDI 的默认 `bdi_writeback`，表明该 BDI 只有一个 `bdi_writeback` 线程。每个 BDI 可以启动的最大线程数为 32。

> Initial experiments conducted by Jens found an 8% increase in performance on a simple SATA drive running [Flexible File System Benchmark (ffsb)](http://sourceforge.net/projects/ffsb/). File layout was smoother as compared to the vanilla kernel as reported by `vmstat`, with a uniform distribution of buffers written out. With a ten-disk btrfs filesystem, per-BDI flushing performed 25% faster. The writeback is tracked by Jens's block layer git tree (git://git.kernel.dk/linux-2.6-block.git) under the "writeback" branch. There have been no comments on the second iteration so far, but per-BDI flusher threads is still not ready enough to go into the 2.6.30 tree.

Jens 通过初步的实验发现，（采用新补丁后）基于简单的 SATA 磁盘系统运行 “灵活文件系统基准测试”（[Flexible File System Benchmark (ffsb)][15]），整体性能提高了 8%。运行 vmstat 可以发现应用补丁后的结果和 vanilla 内核（即主线内核）相比，文件存放更均匀，同时缓存的刷新呈均匀分布状态。在一个使用了十个磁盘 的 btrfs 文件系统上，采用新补丁后的刷新执行速度提高了 25%。补丁的代码修改存放在 Jens 的 git 代码仓库（git://git.kernel.dk/linux-2.6-block.git）的 “writeback” 分支上。到目前为止，对其第二次提交的修改社区暂时还没有给出任何评论，但要说这个补丁已经可以合入 2.6.30 版本还为时尚早。（译者注，Jens 的 Per-BDI flusher 补丁最终 [随 2.6.32 版本合入内核主线][16]。）

> Acknowledgments: Thanks to Jens Axboe for reviewing and explaining certain aspects of the patch set.

致谢：感谢 Jens Axboe 审阅和解释了补丁的相关内容。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://lwn.net/Articles/324833/
[2]: https://elixir.bootlin.com/linux/v2.6.31/source/include/linux/fs.h#L1339
[3]: https://elixir.bootlin.com/linux/v2.6.32/source/include/linux/backing-dev.h#L55
[4]: https://elixir.bootlin.com/linux/v2.6.32/source/include/linux/writeback.h#L29
[5]: https://elixir.bootlin.com/linux/v2.6.32/source/fs/fs-writeback.c#L613
[6]: https://elixir.bootlin.com/linux/v2.6.32/source/fs/ubifs/super.c#L1958
[7]: https://elixir.bootlin.com/linux/v2.6.32/source/mm/backing-dev.c#L651
[8]: https://elixir.bootlin.com/linux/v2.6.32/source/mm/backing-dev.c#L380
[9]: https://elixir.bootlin.com/linux/v2.6.32/source/mm/backing-dev.c#283
[10]: https://elixir.bootlin.com/linux/v2.6.32/source/fs/fs-writeback.c#L933
[11]: https://elixir.bootlin.com/linux/v2.6.32/source/fs/fs-writeback.c#L253
[12]: https://elixir.bootlin.com/linux/v2.6.32/source/fs/fs-writeback.c#L1202
[13]: https://elixir.bootlin.com/linux/v2.6.32/source/fs/fs-writeback.c#L933
[14]: https://lwn.net/Articles/322920/
[15]: https://sourceforge.net/projects/ffsb/
[16]: https://kernelnewbies.org/Linux_2_6_32#Per-backing-device_based_writeback
[17]: https://elixir.bootlin.com/linux/v2.6.31/source/mm/pdflush.c#L66
