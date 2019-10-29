---
layout: post
draft: false
author: 'Wang Chen'
title: "LWN 178253: 内核中的 “优先级继承（Priority Inheritance）”"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-178253/
description: "LWN 中文翻译，内核中的 “优先级继承（Priority Inheritance）”"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - realtime
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Priority inheritance in the kernel](https://lwn.net/Articles/178253/)
> 原创：By Jonathan Corbet @ Apr. 3, 2006
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Lingjie Li](https://github.com/lljgithub)

> Imagine a system with two processes running, one at high priority and the other at a much lower priority. These processes share resources which are protected by locks. At some point, the low-priority process manages to run and obtains a lock for one of those resources. If the high-priority process then attempts to obtain the same lock, it will have to wait. Essentially, the low-priority process has trumped the high-priority process, at least for as long as it holds the contended lock.

想象一个系统中当前运行着两个进程，一个优先级高一些，另一个优先级低一些。这两个进程都会访问同一份受锁保护的资源（译者注，即一段被锁保护的临界区）。假设低优先级的进程先获得了锁。则当高优先级进程再尝试获取相同的锁时，就必须等待。也就是说，除非低优先级的进程放弃了那把锁，否则高优先级的进程是无法继续运行的。

> Now imagine a third process, one which uses a lot of processor time, and which has a priority between the other two. If that process starts to crank, it will push the low-priority process out of the CPU indefinitely. As a result, the third process can keep the highest-priority process out of the CPU indefinitely.

假设此时出现第三个进程，它是一个计算密集型的进程，并且其优先级处于以上两个进程之间。如果该进程抢占了处理器，则低优先级的进程将被无限期地挂起。最终我们看到的现象是，第三个进程（中优先级）将高优先级的那个进程无限期地排斥在处理器之外（无法运行）。

> This situation, called "priority inversion," tends to be followed by system failure, upset users, and unemployed engineers. There are a number of approaches to avoiding priority inversion, including lockless designs, carefully thought-out locking scenarios, and a technique known as priority inheritance. The priority inheritance method is simple in concept: when a process holds a lock, it should run at (at least) the priority of the highest-priority process waiting for the lock. When a lock is taken by a low-priority process, the priority of that process might need to be boosted until the lock is released.

我们称上面的这种现象叫 “优先级反转（priority inversion）”，这往往会导致系统运行异常，用户可能会感到莫名其妙（译者注，因为表现出来的现象是优先级控制似乎失去了作用，优先级高的任务反而争抢不过优先级低的任务），可怜的工程师甚至可能会为此丢了饭碗。有许多种方法可以避免 “优先级反转”，包括无锁设计，充分考虑清楚上锁的所有情况，以及采用被称之为 “优先级继承（priority inheritance）” 的技术。“优先级继承” 这种方法的理念其实很简单：当一个进程持有锁时，它的优先级（至少）应该和等待该锁的进程中优先级最高的那个进程的优先级一样高（译者注，这样别的进程就很难抢占它（除非别的进程的优先级比等待该锁的所有进程的优先级都要高），从而使得该持有锁的进程可以不受打扰地快速处理完临界区并释放掉锁）。所以，当一个低优先级的进程获取了一把锁时，内核可能需要提升该进程的优先级，直到该锁被它释放掉。

> There are a number of approaches to priority inheritance. In effect, the kernel performs a very simple form of it by not allowing kernel code to be preempted while holding a spinlock. In some systems, each lock has a priority associated with it; whenever a process takes a lock, its priority is raised to the lock's priority. In others, a high-priority process will have its priority "inherited" by another process which holds a needed lock. Most priority inheritance schemes have shown a tendency to complicate and slow down the locking code, and they can be used to paper over poor application designs. So they are unpopular in many circles. Linus was [reasonably clear](https://lwn.net/Articles/178258/) about how he felt on the subject last December:

有许多种实现 “优先级继承” 的方法。当前（Linux）内核采用的是一种最简单的形式，就是在获取 “自旋锁（spinlock）” 的同时禁止了任务抢占。有些操作系统中，每个锁具有自己的优先级属性；只要某个进程获取了这把锁，其优先级就会被提升到和锁的优先级相同。在其他的一些操作系统中，采取的方式是当一个高优先级的进程尝试获取锁失败时其优先级将会被占有相同锁的其他进程所 “继承”。绝大多数 “优先级继承” 的实现方案都倾向于使得和锁有关的处理逻辑变得复杂而低效，这些方案或许可以拿来用于发表论文但在工程实践中却并不实用。所以在很多情况下（这些方案）并不受业界的欢迎。在这个问题上，去年 12 月 Linus 表达了 [非常明确][1] 的看法：

> 	"Friends don't let friends use priority inheritance".
> 	Just don't do it. If you really need it, your system is broken anyway.

	“作为朋友我奉劝你不要使用优先级继承”。
	别这么做就好了。只要你用了，你的系统总有一天会出问题。

> Faced with this sort of opposition, many developers would quietly shelve their priority inheritance designs and go back to working on accounting code. The kernel development community, however, happens to have a member who has a track record of getting code merged in spite of this sort of objection: Ingo Molnar. History may well repeat itself, as Ingo (working with Thomas Gleixner) has posted [a priority-inheriting futex implementation](https://lwn.net/Articles/177111/) with a request that it be merged into the mainline. This approach, says Ingo, provides a useful functionality to user space (it is not meant to provide priority-inheriting kernel mutual exclusion primitives) while avoiding the pitfalls which have hit other implementations.

面对这些反对意见，许多开发人员悄悄搁置了他们在 “优先级继承” 上的设计并转而去开始研究那些相对容易解决的问题。然而，内核开发社区还就是存在这样的一个人，这个人的履历告诉我们，他向来不会因为有人反对就停止向内核提交代码，这个人就是：Ingo Molnar。类似的历史可能会再次重演，因为 Ingo（与 Thomas Gleixner 合作）发布了 [一个针对 futex 的优先级继承实现][2]（译者注，Futex 是 Fast Userspace muTexes 的缩写，提供了一种用户态和内核态混合作用下的互斥锁机制，该补丁下文简称为 PI-futex），并提请将其合并入主线中。Ingo 说，这种方法为用户空间提供了一种有用的功能（并不是为内核态的互斥锁原语提供优先级继承机制），同时避免了其他实现中所遇到的问题（译者注，指上文提到的实现上的复杂和运行上的低效）。

> The PI-futex patch adds a couple of new operations to the `futex()` system call: `FUTEX_LOCK_PI` and `FUTEX_UNLOCK_PI`. In the uncontended case, a PI-futex can be taken without involving the kernel at all, just like an ordinary futex. When there is contention, instead, the `FUTEX_LOCK_PI` operation is requested from the kernel. The requesting process is put into a special queue, and, if necessary, that process lends its priority to the process actually holding the contended futex. The priority inheritance is chained, so that, if the holding process is blocked on a second futex, the boosted priority will propagate to the holder of that second futex. As soon as a futex is released, any associated priority boost is removed.

PI-futex 补丁为 `futex()` 系统调用添加了两个新的操作选项：`FUTEX_LOCK_PI` 和 `FUTEX_UNLOCK_PI`。在不发生竞争的条件下，可以在不涉及切换到内核态的情况下（译者注，即在用户态直接）获取 PI-futex，就像普通的 futex 一样。相反，当存在争用时，会向内核发起 `FUTEX_LOCK_PI` 请求。发起请求的进程会被放入一个特殊队列，必要的话，内核会按照该进程的优先级提升实际持有 futex 的进程。“优先级继承” 的实现具备可传递性，也就是说，如果拥有锁的进程因为另一个 futex 而被阻塞，则其所被提升的优先级将被传递到第二个 futex 的持有者身上。一旦一个所有者释放了 futex，其本身被提升的优先级则会被恢复。

> As with regular futexes, the kernel only needs to know about a PI-futex while it is being contended. So the number of futexes in the system can become quite large without serious overhead on the kernel side.

与以往常规的 futex 一样，内核只会在某个 PI-futex 被争用时才会介入。因此，即使系统中的 futex 数量变得很巨大，但对内核来说开销也不会很严重。

> Within the kernel, the PI-futex type is implemented by way of a new primitive called an `rt_mutex`. The `rt_mutex` is superficially similar to regular mutexes, with the addition of the priority inheritance capability. They are, however, an entirely different type, with no code shared with the mutex implementation. The API will be familiar to mutex users, however; in brief, it is:

内核中，PI-futex 类型通过一个被称为 `rt_mutex` 的新结构体类型实现。看上去，除了增加了 “优先级继承” 能力外，该 `rt_mutex` 似乎和常规的 `mutex` 类型差别不大。但实际上，它们是完全不同的类型，新的 `rt_mutex` 完全是另起炉灶重新开发的，没有借鉴现有的 `mutex` 的代码。除此之外，新的互斥锁的编程接口和旧的 `mutex` 的接口非常类似，概括起来，包括以下函数：

```
#include <linux/rtmutex.h>

void rt_mutex_init(struct rt_mutex *lock);
void rt_mutex_destroy(struct rt_mutex *lock);

void rt_mutex_lock(struct rt_mutex *lock);
int rt_mutex_lock_interruptible(struct rt_mutex *lock, 
				int detect_deadlock);
int rt_mutex_timed_lock(struct rt_mutex *lock,
			struct hrtimer_sleeper *timeout,
			int detect_deadlock);
int rt_mutex_trylock(struct rt_mutex *lock);
void rt_mutex_unlock(struct rt_mutex *lock);
int rt_mutex_is_locked(struct rt_mutex *lock);
```

> The alert reader may have noticed that this looks much like the realtime mutex type found in the realtime preemption patch. Ingo once said that the realtime patches would slowly trickle into the mainline, and that is what appears to be happening here. With this patch set, the PI-futex code is the only user of the new `rt_mutex` type, but that could certainly change over time.

敏感的读者可能已经注意到，这个 `rt_mutex` 看上去很像 “实时抢占补丁（realtime preemption patch）” 中的实时互斥锁（realtime mutex）类型。Ingo 曾经说过，他会逐步地将实时补丁中的内容合入主线，这件事似乎正在发生。虽然在这个补丁集中，PI-futex 代码是新的 `rt_mutex` 的唯一用户，但这肯定会随着时间而改变。

> The PI-futex patch also includes a new, priority-sorted list type which could find users elsewhere in the kernel.

PI-futex 补丁还包括一个新的按优先级排序的链表类型，这在内核中或许也能找到潜在的用户。

> There has been relatively little discussion of this patch so far; it has been included in recent -mm trees. It is too late for 2.6.17, but, if no real opposition develops, the PI-futex code might just find its way into a subsequent kernel.

到目前为止，对该补丁的讨论还相对较少；它已被包含在最新的 -mm 代码仓库中。如果要想将这个补丁随 2.6.17 合入内核主线，看上去时间有点紧张，如果没有反对意见，PI-futex 代码很有可能会随着后继版本合入内核。（译者注，PI-futex 补丁最终 [随 2.6.18 版本合入内核主线][3]。）

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://lwn.net/Articles/178258/
[2]: https://lwn.net/Articles/177111/
[3]: https://kernelnewbies.org/Linux_2_6_18#Lightweight_user_space_priority_inheritance_.28PI.29