---
layout: post
draft: true
author: 'Wang Chen'
title: "LWN 391222: 重写（rewrite）OOM Killer"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-391222/
description: "LWN 中文翻译，重写 OOM Killer"
category:
  - 内存子系统
  - LWN
tags:
  - Linux
  - memory
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Another OOM killer rewrite](https://lwn.net/Articles/391222/)
> 原创：By Jonathan Corbet @ Jun. 7, 2010
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Hua Su](https://github.com/zlsh007)

> Nobody likes the out-of-memory (OOM) killer. Its job is to lurk out of sight until that unfortunate day when the system runs out of memory and cannot get work done; the OOM killer must then choose a process to sacrifice in the name of continued operation. It's a distasteful job, one which many think should not be necessary. But, despite the OOM killer's lack of popularity, we still keep it around; think of it as the kernel equivalent of lawyers, tax collectors, or Best Buy clerks. Every now and then, they are useful.

没有人喜欢 “内存不足杀手”（out-of-memory killer，或简称 OOM Killer，译者注：内核内存管理子系统特性之一，具体功能见下文的解释。下文对其直接使用英文简称，不再翻译）。我们平时很难觉察到它的存在，只有当系统内存严重不足乃至接近无法完成工作时，OOM Killer 才会出现并选择一个进程，将其杀死（以释放内存），使得系统能够继续运行。OOM Killer 这个内核特性并不讨人喜欢，许多人甚至认为没必要启用它。但是，尽管该特性不受欢迎，我们仍然保留了该项功能，它在内核中担任的角色就好比是我们生活中的律师，税务员或者零售店的售货员。偶尔也会很有用。

> The OOM killer's reputation is not helped by the fact that it is seen as often choosing the wrong victim. The fact that a running system was saved is a small consolation if that system's useful processes were killed and work was lost. Over the years, numerous developers have tried to improve the set of heuristics used by the OOM killer, with a certain amount of apparent success; complaints about poor choices are less common than they once were. Still, the OOM killer is not perfect, encouraging new rounds of developers to tilt at that particular windmill.

人们之所以不喜欢 OOM Killer，是因为该特性在工作时经常会选择错误的 “牺牲者”（译者注，指被杀死的进程）。如果一个系统中被终止的进程是有用的并且由于这些进程被终止导致了工作成果被丢失，那么即使系统被挽救下来，其结果同样不被人们所接受。多年来，许多开发人员试图改进 OOM Killer 所使用的选择 “牺牲者” 的方法，取得了一定的成功；抱怨选择不当的案例不像以前那么多了。尽管如此，OOM Killer 这个功能的实现并不完美，继续激励着开发者们为了改进该项特性而发起新一轮的挑战。

> For some months now, the task of improving the OOM killer has fallen to David Rientjes, who has posted several versions of his [OOM killer rewrite patch set](http://lwn.net/Articles/391206/). This version, he hopes, will be deemed suitable for merging into 2.6.36. It has already run the review gauntlet several times, but it's still not clear what its ultimate fate will be.

近几个月以来，对 OOM Killer 特性进行改进的任务落在了 David Rientjes 的肩上，针对由他发起的 [重写（rewrite）OOM Killer 补丁集][13]，他已经提交了好几个版本。他希望最新提交的这个版本可以被合入内核的 2.6.36 版本。这次提交的补丁版本已经经历了多轮交叉审阅，但最终是否会被内核主线所接受，目前还不清楚（译者注，[该补丁集随 2.6.36 合入了内核主线][10]）。

> Much of this patch set is dedicated to relatively straightforward fixes and improvements which are not especially controversial. One change opens up the kernel's final memory reserves to processes which are either exiting or are about to receive a fatal signal; that should allow them to clean up and get out of the way, freeing memory quickly. Another prevents the killing of processes which are in a separate memory allocation domain from the process which hit the OOM condition; killing those processes is unfair and unlikely to improve the situation. If the OOM condition is the result of a mempolicy-imposed constraint, only processes which might release pages on that policy's chosen nodes are considered as targets.

该补丁集中的大部分修复和改进都相对简单，所以没什么可争议的。改动之一是允许从内核最后保留的那部分内存中为那些即将退出或者接收到终止信号（译者注，即 SIGKILL）的进程分配内存；以便它们尽快完成退出并被清理，从而释放出更多的内存（译者注，具体修改参考代码提交 [“oom: give current access to memory reserves if it has been killed”][1]）。另一处修改是：对于那些和触发 OOM 的进程不在同一个内存分配域（memory allocation domain）的进程，我们要避免杀死它们；杀死这些进程是不公平的，而且也不太可能改善内存紧张的状况。如果 OOM 的发生是源于某个 [“内存策略（memory policy，或简称 mempolicy”][2] 约束，则只有杀死那些会在该策略所选择的节点（node）上释放内存页框的进程才可能对解决问题有帮助（译者注，具体修改参考代码提交 [“oom: select task from tasklist for mempolicy ooms”][3]；另外类似的，补丁还会避免杀死和触发 OOM 的进程不共享同一个 cpuset 的进程，具体修改参考代码提交 [“oom: filter tasks not sharing the same cpuset”][4]）。

> Another interesting change has to do with the killing of child processes. The current OOM killer, upon picking a target for its unwelcome attention, will target one of that target's child processes if any exist. Killing the parent is likely to take out all the children anyway, so cleaning up the children - or, at least, those with their own address spaces - first may resolve the problem with less pain. The updated OOM killer does the same, but in a more targeted fashion: it attempts to pick the child which currently has the highest "badness" score, thus, hopefully, improving the chances of freeing some real memory quickly.

另一个有趣的改动与终止子进程的操作有关。当前（译者注，指 2.6.35 及以前的内核版本） OOM Killer 一旦在选中操作的进程对象后（译者注，选择操作对应的函数为 [`select_bad_process()`][12]），会继续在该进程的子进程列表中寻找最终要杀死的对象（译者注，内核会按照子进程链表的顺序进行搜索直到找到一个满足要求的为止，如果找不到合适的子进程才会最终选择父进程，即触发 OOM 操作的进程本身，具体参考 [`oom_kill_process()`][5]）。杀死父进程可能会导致其所有的子进程都被终止，所以优先清理子进程（即子进程自己地址空间所对应的物理内存页框）对系统的整体运行的影响会小一些。补丁中改进后的 OOM Killer 在这一点上的总体思路不变，但具体操作上更具备针对性：它会试图挑选目前评分最 “差（badness）” 的子进程，从而尽快释放更多的内存（译者注，有关 “评分”的概念参考本文下面章节的介绍；有关本节的具体修改参考代码提交 [“oom: sacrifice child with highest badness score for parent”][6]）。

> Yet another change affects behavior when memory is exhausted in the low memory zone. This zone, present on 32-bit systems with 1GB or more of memory, is needed in places where the kernel must be able to keep a direct pointer to it. It is also used for DMA I/O at times. When this memory is gone, David says, killing processes is unlikely to replenish it and may cause real harm. So, instead of invoking the OOM killer, low-memory allocation requests will simply fail unless the `__GFP_NOFAIL` flag is present.

补丁的另一处改动涉及针对低端内存区域（low memory zone）内存耗尽时的处理行为。对于一个内存容量大于等于 1GB 的 32 位系统，内核会采用线性映射的方式直接访问该区域（指 low memory zone）所对应的物理内存（无需页表转换），同时 “直接内存访问（Direct Memory Access，简称 DMA）” 也会利用该区域的内存 。David 说，当该区域中的内存耗尽时，简单地挑选并杀死进程不太可能缓解内存的紧张状态反而可能造成更大的伤害。因此，如果无法满足对低端内存区域的分配请求，除非分配请求中明确给出 `__GFP_NOFAIL` 标志才会启用 OOM Killer，否则一概简单地返回分配失败（译者注，具体修改参考代码提交 [“oom: avoid oom killer for lowmem allocations”][7]）。

> A new heuristic which has been added is the "forkbomb penalty." If a process has a large number of children (where the default value of "large" is 1000) with less than one second of run time, it is considered to be a fork bomb. Once that happens, the scoring is changed to make that process much more likely to be chosen by the OOM killer. The "kill the worst child" policy still applies in this situation, so the immediate result is likely to be a fork bomb with 999 children instead. Even in this case, picking off the children one at a time is seen as being better than killing a potentially important server process.

补丁中增加了一个新的对 forkbomb 情况的处理。如果一个父进程会在很短的时间内（譬如一秒钟内）派生非常多的子进程（譬如 1000 个），那么我们就称这个父进程为 forkbomb。一旦遇到这种情况，我们就需要改变选择的标准，让 OOM Killer 更倾向于选择这个 forkbomb 进程并杀死它。但 “优先终止子进程” 的策略在这种场景中依然适用，所以处理的结果也很可能是依然保留那个 forkbomb 父进程和它的 999 个子进程。因为在这种场景下，只终止一个子进程或许也比杀死一个很可能是服务器角色的进程要好。（译者注，针对本段介绍的内容，译者未在合入内核主线的实际提交中找到对应的补丁修改，欢迎读者不吝指正。）

> The most controversial part of the patch is a complete rewrite of the `badness()` function which assigns a score to each process in the system. This function contains the bulk of the heuristics used to decide which process is most deserving of the OOM killer's services; over time, it has accumulated a number of tests which try to identify the process whose demise would release the greatest amount of memory while causing the least amount of user distress.

补丁中最有争议的部分是有关对 `badness()` 函数的重写（译者注，具体修改参考代码提交 [“oom: badness heuristic rewrite”][8]），该函数用于为系统中的一个进程打分（译者注，分数的高低决定是否要选择该进程作为 OOM Killer 杀死的对象）。此函数包含了大量的经验公式，用于确定哪个进程最值得被 OOM Killer 杀死；长久以来，该函数中累积了很多判断逻辑，目标都集中在试图选择并终止一个进程后，既能够最大量地释放内存，又尽可能地不会对用户的使用造成影响。

> In David's patch set, the old `badness()` heuristics are almost entirely gone. Instead, the calculation turns into a simple question of what percentage of the available memory is being used by the process. If the system as a whole is short of memory, then "available memory" is the sum of all RAM and swap space available to the system. If, instead, the OOM situation is caused by exhausting the memory allowed to a given cpuset/control group, then "available memory" is the total amount allocated to that control group. A similar calculation is made if limits imposed by a memory policy have been exceeded. In each case, the memory use of the process is deemed to be the sum of its resident set (the number of RAM pages it is using) and its swap usage.

在 David 的补丁集中，旧的 `badness()` 函数中的逻辑几乎完全被移除了，代之以简单地计算该进程 “所使用的内存” 占​ “可用内存” 的百分比。如果内存不足是系统级别的，我们所谓的 “可用内存” 指的是整个系统可用的所有内存和交换空间的总和。如果内存不足是由于内存使用超出了某个 cpuset 或者 控制组（control croup） 的限制所引起的，则 “可用内存” 指的是分配给该控制组的内存总量。如果内存不足是由于超出了内存策略（memory policy）所施加的限制，则同样对 “可用内存” 值进行类似的计算（译者注，以上对 “可用内存” 的计算请参考补丁代码中的 [`constrained_alloc()`][9] 函数）。无论何种情况，进程 “所使用的内存” 都被认为是其驻留集（resident set，即该进程当前正在使用的内存页框的总数）和该进程所占用的交换空间的大小之和。

> This calculation produces a percent-times-ten number as a result; a process which is using every byte of the memory available to it will have a score of 1000, while a process using no memory at all will get a score of zero. There are very few heuristic tweaks to this score, but the code does still subtract a small amount (30) from the score of root-owned processes on the notion that they are slightly more valuable than user-owned processes.

最终计算的结果会对以上计算所得的百分比值乘上十倍；一个使用了所有可用内存的进程的得分为 1000，而完全不占用内存的进程的得分为零。代码中对该分值存在少许的微调，如果一个进程为 root 用户所拥有，则其分值会被减去一些（30），因为相比普通用户所拥有的进程来说，它更不应该被杀死。

> One other tweak which is applied is to add the value stored in each process's `oom_score_adj` variable, which can be adjusted via `/proc`. This knob allows the adjustment of each process's attractiveness to the OOM killer in user space; setting it to -1000 will disable OOM kills entirely, while setting to +1000 is the equivalent of painting a large target on the associated process. One of the reasons why this patch is controversial is that this variable differs in name and semantics from the `oom_adj` value implemented by the current OOM killer; it is, in other words, an ABI change. David has implemented a mapping function between the two values to try to mitigate the pain; `oom_adj` is deprecated and marked for removal in 2012.

还有一种调整的方法是通过修改 `/proc` 文件系统下每个进程的 `oom_score_adj` 属性（译者注，假设某个进程的 PID 为 2196，则该属性对应的文件是 `/proc/2196/oom_score_adj`）。我们可以通过在用户空间调整该值进而影响 OOM Killer 对进程的选择；将其设置为 -1000 则 OOM Killer 将不再选择该进程，而设置为 +1000 相当于通知 OOM Killer 优先选择该进程。针对这个补丁有争议的原因之一就是这个变量的名称和语义与当前 OOM Killer 中已实现的另一个调节属性 `oom_adj` 不同；换句话说，这导致了 “应用程序二进制接口”（Application Binary Interface，简称 ABI）层面上的变化。David 通过在两个值之间建立对应关系，试图减少这个改变对使用者所造成的麻烦；`oom_adj` 已不推荐使用，并将于 2012 年完全从内核中删除（译者注，具体修改参考代码提交 [“oom: deprecate oom_adj tunable”][11]）。

> Opposition to this change goes beyond the ABI issue, though. Understanding why is not always easy; one reviewer's [response](https://lwn.net/Articles/391226/) consists solely of the word "nack." The objections seem to relate to the way the patch replaces `badness()` wholesale rather than evolving it in a new direction, along with concerns that the new algorithm will lead to worse results. It is true that no hard evidence has been posted to justify the inclusion of this change, but getting hard evidence in this case is, well, hard. There is no simple benchmark which can quantify the OOM killer's choices. So we're left with [answers](https://lwn.net/Articles/391227/) like:

但是，对该补丁的反对意见绝不仅限于这个简单的 ABI 修改。理解那些反对的原因并不总是那么容易；譬如一位审阅者给出的 [意见][14] 就仅包含一个单词 “nack”（译者注，“nack” 本身并不是一个正式的英文单词，这里可能是借用了网络通讯命令中的 NACK 命令，表达消极接受，或更倾向于不接受的意思）。看起来意见和补丁替换 `badness()` 函数的方式有关，修改完全重写了该函数而没有采取逐步演进的方式，同时有担心，新的算法将导致更糟糕的结果。的确，在补丁提交过程中并没有提供确凿的证据可以证明此项改变是否合理，但要知道，针对 OOM 问题，要想获得确凿的证据确实很难。没有简单的基准可以量化 OOM Killer 的选择结果。所以针对以上问题，[David 的回答][15] 仅仅是：

>     I have repeatedly said that the oom killer no longer kills KDE when run on my desktop in the presence of a memory hogging task that was written specifically to oom the machine. That's a better result than the current implementation...

    正如我反复所提到的，在我的台式机上运行一个专门编写的测试程序，该程序会大量地消耗内存，我们发现此时 OOM Killer 将不会杀死 KDE。这的确比目前的运行效果要更好 ...

> Memory management patches tend to be hard to merge, and the OOM killer rewrite has certainly been no exception. In this case, it is starting to look like some sort of intervention from a higher authority will be required to get a decision made. As it happens, Andrew Morton [seems poised](https://lwn.net/Articles/391228/) to carry out just this sort of intervention, saying:

通常情况下，内存管理相关的补丁要想合入并没有那么容易，而这个 “OOM Killer rewrite” 补丁肯定也不例外。当前这种情况下，看起来需要某种来自更高决策层的干预来帮助我们做出决定。事实上，Andrew Morton 似乎已经准备 [出面][16] 最终敲定这件事情，他说：

>     The unsubstantiated "nack"s are of no use and I shall just be ignoring them and making my own decisions. If you have specific objections then let's hear them. In detail, please - don't refer to previous conversations because that's all too confusing - there is benefit in starting again.

    没有事实根据的 “nack” 是没用的，我将忽略这些意见并做出自己的决定。如果你们有明确的反对意见，请务必让我知道。但请特别注意的是不要再涉及先前的讨论，这只会使事情变得更加复杂，让我们重新开始只会有好处。

> So, depending on what Andrew concludes, there might just be a new OOM killer in store for 2.6.36. For most users, this new feature is probably about as exciting as getting a new toilet cleaner as a birthday present. But, if it eventually helps a system of theirs survive an OOM situation in good form, they may yet come to appreciate it.

所以，根据 Andrew 的结论，2.6.36 将引入新的 OOM Killer。对于大多数用户来说，这个新功能的引入可能味同鸡肋，并不能引起大家的兴趣。但是，只要它最终能够帮助大家更好地应对 OOM，或许人们对它的态度还是会有所转变。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=7b98c2e402eaa1f2beec18b1bde17f74948a19db
[2]: https://elixir.bootlin.com/linux/v2.6.36/source/Documentation/vm/numa_memory_policy.txt
[3]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=6f48d0ebd907ae419387f27b602ee98870cfa7bb
[4]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=6cf86ac6f36b638459a9a6c2576d5e655d41d451
[5]: https://elixir.bootlin.com/linux/v2.6.35/source/mm/oom_kill.c#L438
[6]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=5e9d834a0e0c0485dfa487281ab9650fc37a3bb5
[7]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=03668b3ceb0c7a95e09f1b6169f5270ffc1a19f6
[8]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=a63d83f427fbce97a6cea0db2e64b0eb8435cd10
[9]: https://elixir.bootlin.com/linux/v2.6.36/source/mm/oom_kill.c#L225
[10]: https://kernelnewbies.org/Linux_2_6_36#OOM_rewrite
[11]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=51b1bd2ace1595b72956224deda349efa880b693
[12]: https://elixir.bootlin.com/linux/v2.6.35/source/mm/oom_kill.c#L247
[13]: https://lwn.net/Articles/391206/
[14]: https://lwn.net/Articles/391226/
[15]: https://lwn.net/Articles/391227/
[16]: https://lwn.net/Articles/391228/
