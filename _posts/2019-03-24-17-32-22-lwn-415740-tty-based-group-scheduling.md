---
layout: post
draft: true
author: 'Wang Chen'
title: "LWN 415740: 基于 TTY 的组调度"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-415740/
description: "LWN 文章翻译，基于 TTY 的组调度"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - schedule
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[TTY-based group scheduling](https://lwn.net/Articles/415740/)
> 原创：By Jonathan Corbet @ Nov. 17, 2010
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Xiaojie Yuan](https://github.com/llseek)

> As long as we have desktop systems, there will almost certainly be concerns about desktop interactivity. Many complex schemes for improving interactivity have come and gone over the years; most of them seem to leave at least a subset of users unsatisfied. Miracle cures are hard to come by, but it seems that a recent patch has come close, at least for some users. Interestingly, it is a conceptually simple solution that may not need to be in the kernel at all.

对于桌面系统（desktop system）来说，交互性能（interactivity）是一个必须要重视的问题。多年以来，为了改进交互性能，提出了各种各样复杂的方案；但它们中的绝大部分总不能够让所有的用户都感到满意。在这个问题上很难找到一个非常完美的解决方案，但最近出现的一个补丁似乎有助于改进这个问题，至少对于某些用户来说是这样。有趣的是，从设计思想上来看，该方案并不复杂，甚至完全可以不在内核中实现（译者注，指下文即将介绍的可以通过编写用户态的应用来实现）。

> The core idea behind the completely fair scheduler is its complete fairness: if there are N processes competing for the CPU, each with equal priority, than each will get 1/N of the available CPU time. This policy replaced the rather complicated "interactivity" heuristics found in the O(1) scheduler; it yields better desktop response in most situations. There are places where this approach falls down, though. If a user is running ten instances of the compiler with `make -j 10` along with one video playback application, each process will get a "fair" 9% of the CPU. That 9% may not be enough to provide the video experience that the user was hoping for. So it is not surprising that many users see "fairness" differently; wouldn't be nice if the compilation job as a whole got 50%, while the video application got the other half?

完全公平调度器（completely fair scheduler）背后的核心思想是所谓的 “完全公平”（complete fairness）：简单来说，就是如果有 N 个进程竞争 CPU，且每个进程具有相同的优先级，那么每个进程将享有整个 CPU 处理时间的 N 分之一。该策略取代了 “O(1)” 调度器中需要实现的用于确定 “交互式进程” 的算法（该算法相当复杂）；在大多数情况下（采用完全公平调度器后）桌面的交互响应效果会更好。但是，在某些情况下仍然存在一些不足。譬如，假设一个用户运行 `make -j 10` 命令启动十个进程实例执行编译工作，同时运行另一个进程执行视频播放程序，由于基于 “公平” 的原则，每个进程将获得 9% 的 CPU 执行时间。而可怜的 9% 是无法满足用户所期望的流畅视频体验的。毫不奇怪，不同的用户看待所谓 “公平性” 的角度会有所不同；因此，如果使得整个编译工作只占用一半的处理器时间，而视频应用享用另一半，效果或许会更好。

> The kernel has been able to implement that kind of fairness for years though a feature known as [group scheduling](https://lwn.net/Articles/240474/). A set of processes placed within a group will each get a fair share of the CPU time allocated to the group as a whole, but groups will, themselves, compete for a fair share of the CPU. So, if the video player were to be placed in one group and the compilation in another, each group would get half of the available processor time. The various processes doing the compilation would then get a fair share of their group's half; they will compete with each other, but not with the video player. This arrangement will ensure that the video player gets enough CPU time to keep up with the stream and any interactivity requirements.

两年前（相对于本文写作的时间）内核中加入的 [“组调度（group scheduling）”][1] 功能已经能够支持上述这种公平性。组与组之间会公平地竞争 CPU，而一个组内的所有进程则将公平地分享分配给这个组的 CPU 时间。因此，如果将视频播放器进程置于一个组中，同时将所有的编译进程放在另一个组中，则每个组将各获得一半的处理器时间。然后，所有的编译进程再一起平分分配给它们所在组的那百分之五十的 CPU 份额；编译进程之间将在组内（“公平地”）相互竞争，而不会独立地与视频播放器进程（“公平地”）竞争。这种安排将确保视频播放器获得足够的 CPU 时间来处理视频流以及其他任何有关交互性操作的要求。

> Groups are thus a nice feature, but they have not seen heavy use since they were merged for the 2.6.24 release. The reasons for that are clear: groups require administrative work and root privileges to set up; most users do not know how to tweak the knobs and would really rather not learn. What has been missing all these years is a way to make group scheduling "just work" for ordinary users. That is the goal of [Mike Galbraith's per-TTY task groups patch](https://lwn.net/Articles/415742/).

可见，对任务调度进行分组是一个很好的功能，但该功能自从被合入 2.6.24 版本后并没有被广泛地使用。原因很明显：分组需要一些管理事务工作以及相应的 root 权限；大多数用户并不清楚如何对其进行设置，当然也可能是真的不想花精力去学习怎么操作。这些年来所一直缺少的正是提供一种方法，能够让普通用户无需额外的操作就可以 “自动” 对任务实现分组调度（译者注，即文中所谓的 “just work”）。而这正是 Mike Galbraith 开发 [基于 TTY 对任务进行分组（per-TTY task groups）补丁][2] 的目的。

> In short, this patch automatically creates a group attached to each TTY in the system. All processes with a given TTY as their controlling terminal will be placed in the appropriate group; the group scheduling code can then share time between groups of processes as determined by their controlling terminals. A compilation job is typically started by typing "`make`" in a terminal emulator window; that job will have a different controlling TTY than the video player, which may not have a controlling terminal at all. So the end result is that per-TTY grouping automatically separates tasks run in terminals from those run via the window system.

简而言之，该补丁会为系统中的每个 [TTY][10] 自动创建一个组。所有以该 TTY 作为其控制终端的进程将被放置在这个组中；然后，组调度代码就会合理地安排这些进程组之间的处理器时间。一个编译作业（job）通常通过在终端仿真器（terminal emulator）窗口中键入 “`make`” 命令来启动；该作业所关联的 TTY 必定和视频播放器进程所关联的 TTY 不同，视频播放器进程甚至可能根本就没有关联的控制终端。因此，最终的结果就是基于该补丁可以自动将那些运行于终端中的任务和运行于窗口系统（window system）的任务区分开来。

> This behavior [makes Linus happy](https://lwn.net/Articles/415748/); Linus, after all, is just the sort of person who might try to sneak in a quick video while waiting for a highly-parallel kernel compilation. He said:

> 	So I think this is firmly one of those "real improvement" patches. Good job. Group scheduling goes from "useful for some specific server loads" to "that's a killer feature".

[Linus 十分喜欢这个功能][3]；要知道，在日常工作中 Linus 就经常在后台启动多进程执行内核编译，并在等待结果的同时会在前台看一会视频。他说：

	我认为这才是那种 “真正解决问题” 的补丁。这项改进太好了。（它使得）组调度这项特性从 “只针对某些特定的服务器应用场景” 变成了 “一个杀手级的功能（killer feature）”。

> Others have also reported significant improvements in desktop response, so this feature looks like one which has a better-than-average chance of getting into the mainline in the next merge window. There are, however, a few voices of dissent, most of whom think that the TTY is the wrong marker to use when placing processes in group.

其他人也报告了（添加该补丁后）在桌面响应方面的重大性能提升，看起来该功能有很大的机会会在下一个合并窗口中进入内核主线。但也存在一些不同意见，其中大多数人认为在对进程分组时，以 TTY 作为分组的判断依据是错误的。

> Most outspoken - as he often is - is Lennart Poettering, who [asserted](https://lwn.net/Articles/415750/) that "`Binding something like this to TTYs is just backwards`"; he would rather see something which is based on sessions. And, he said, all of this could better be done in user space. Linus was, to put it politely, [unimpressed](https://lwn.net/Articles/415751/), but Lennart [came back](https://lwn.net/Articles/415753/) with a few lines of bash scripting which achieves the same result as Mike's patch - with no kernel patching required at all. It turns out that working with control groups is not necessarily that hard.

最直言不讳的人，要数 Lennart Poettering 了（和他打过交道的都知道），他 [认为][4] “`基于 TTY 进行分组在设计上完全是一种倒退`”；他更倾向于在设计上基于 “会话（sessions）”。他还说，同样的功能完全可以在用户空间中完成。Linus 显然 [不为所动][5]（译者注，作者在这里比较委婉，但从邮件上看事实是 Linus 又爆了粗口），但是（更顽强的） Lennart [继续给出回应][6] 并且给出了几行 bash 脚本代码实现了与 Mike 的补丁完全相同的功能，而这并不需要任何内核代码的修改。这表明，利用控制组（control groups）实现该功能并不难。

> Linus, however, [still likes the kernel version](https://lwn.net/Articles/415754/), mainly because it can be made to "just work" with no user intervention required at all:

> 	Put another way: if we find a better way to do something, we should _not_ say "well, if users want it, they can do this <technical thing here>". If it really is a better way to do something, we should just do it. Requiring user setup is _not_ a feature.

然而，Linus [仍然觉得应该在内核态实现该功能][7]，主要是因为这么做可以 “just work” （译者注：参考前文对 “just work” 的解释，这里不再翻译）而且根本不需要用户干预：

	从另一个方面来说：如果我们找到一种更好的方法来做某事，我们就不应该说 “好吧，如果用户想要，他们可以自己做（技术上的事）。如果它真的是一种更好的实现方式，我们就直接做好了。要求用户自己去配置不是我们应该追求的目标。

> In other words, an improvement that just comes with a new kernel is likely to be available to more users than something which requires each user to make a (one-time) manual change.

也就是说，如果内核中的一个新功能是很多用户都需要的，那就不要让每个用户都自己配置一次。

> Lennart [isn't buying it](https://lwn.net/Articles/415756/). A real user-space solution, he says, would not come in the form of a requirement that users edit their `.bashrc` files; it, too, would be in a form that "just works." It should come as little surprise that the form he envisions is systemd; it seems that future plans involve systemd taking over session management, at which time per-session group scheduling will be easy to achieve. He believes that this solution will be more flexible; it will be able to group processes in ways which make more sense for "normal desktop users" than TTY-based grouping. It also will not require a kernel upgrade to take effect.

可是 Lennart [仍然表示不认同][8]。他说，最终的用户态解决方案并不需要每个用户都去编辑 `.bashrc` 文件。也可以采用 “just works” 的方式提供。他设想的方式是基于 [systemd][11]（译者注，Lennart 正是 systemd 的主要开发者之一 :-)）；因为将来 systemd 或许会接管会话管理，那样基于会话实现组调度将很容易实现。他认为这种解决方案会更灵活；对于 “普通桌面用户” 来说以这种方式对进程进行分组，比基于 TTY 的分组方式更好。而且这么做也不需要对内核进行升级。

> Another idea which has been raised is to add a "run in separate group" option to desktop application launchers, giving users an easy way to control how the partitioning is done.

另一个想法建议在桌面应用启动器中添加一个 “启用分组运行” 的选项，为用户提供一种简单的方法来控制是否启用该特性。

> Linus [seems to be holding his line](https://lwn.net/Articles/415759/) on the kernel version of the patch:

> 	Anyway, I find it depressing that now that this is solved, people come out of the woodwork and say "hey you could do this". Where were you guys a year ago or more?
	
> 	Tough. I found out that I can solve it using cgroups, I asked people to comment and help, and I think the kernel approach is wonderful and _way_ simpler than the scripts I've seen. Yes, I'm biased ("kernels are easy - user space maintenance is a big pain").

但 Linus 看上去 [仍然十分坚持][9] 在内核中实现该特性 ：

	令人沮丧的是，问题都已经解决了，却突然冒出来许多人说 “嘿，你可以这么做”。以前你们跑哪去了呢？
	
	够了。当初我发现可以使用 cgroup 解决问题的时候，我请求大家发表意见和提供帮助（但没有人给出好的建议），我现在认为在内核中实现比我见过的采用脚本设置的方法更好，更简单。是的，或许我是有点偏见（“内核修改很容易，而在用户空间进行维护只会带来更大的痛苦”）。

> The next merge window is not due until January, though; that is a fair amount of time for people to demonstrate other approaches. If a solution based in user space turns out to be more flexible and effective in the long run, it may yet prevail. That is especially true because merging Mike's patch does not in any way inhibit user-space solutions; if a systemd-based approach shows better results, that may be what the distributors decide to enable. One way or the other, it seems like better interactive response is coming in the near future.

下一个合并窗口要等到一月份；所以大家还是有相当长的时间来提出其他的方法。如果能提出一个基于用户空间的，从长远来看更加灵活和有效的解决方案，那么它仍然有可能被采纳。这么说是因为合并 Mike 的补丁并不会妨碍用户空间解决方案的实现；如果基于 systemd 的方法效果更好，那么发布包的制作者（译者注，譬如 Redhat 等）完全可以自己决定怎么做。总之，在不久的将来我们会享受到更好的交互式响应。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: /lwn-240474
[2]: https://lwn.net/Articles/415742/
[3]: https://lwn.net/Articles/415748/
[4]: https://lwn.net/Articles/415750/
[5]: https://lwn.net/Articles/415751/
[6]: https://lwn.net/Articles/415753/
[7]: https://lwn.net/Articles/415754/
[8]: https://lwn.net/Articles/415756/
[9]: https://lwn.net/Articles/415759/
[10]: https://en.wikipedia.org/wiki/Computer_terminal#Text_terminals
[11]: https://en.wikipedia.org/wiki/Systemd
