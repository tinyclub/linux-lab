---
layout: post
draft: false
author: 'Wang Chen'
title: "LWN 418884: 针对 “组调度”（Group scheduling）的不同分组方案"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-418884/
description: "LWN 文章翻译，针对 “组调度”（Group scheduling）的不同分组方案"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - schedule
---

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

> 原文：[Group scheduling and alternatives](https://lwn.net/Articles/418884/)
> 原创：By Jonathan Corbet @ Dec. 6, 2010
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [Xiaojie Yuan](https://github.com/llseek)

> The [TTY-based group scheduling](https://lwn.net/Articles/415740/) patch set has received a lot of discussion on LWN and elsewhere; some distributors are rushing out kernels with this code added, despite the fact that it has not yet been merged into the mainline. That patch has evolved slightly since it was last discussed here. There have also been some interesting conversations about alternatives; this article will attempt to bring things up to date.

大家已经围绕 [基于 TTY 的组调度][1] 这个补丁集进行了充分的讨论，包括在 LWN 和其他地方；尽管事实上它还没有被合入主线，但是一些发布包提供商已经迫不及待地在他们的内核中添加了这个补丁。自从上次在 LWN 上给大家介绍过以后，这个补丁又有了些许进化。同时也出现了一些其他的备选方案；本文将给大家介绍一下最新的进展情况。

> The main change to the TTY-based group scheduling patch set is that it is, in fact, no longer TTY-based. The identity of the controlling terminal was chosen as a heuristic which could be used to group together tasks which should compete with each other for CPU time, but other choices are possible. An obvious possibility is the session ID. This ID is used to identify distinct process groups; a process starts a new session with the `setsid()` system call. Since sessions are already used to group together related processes, it makes sense to use the session ID as the key when grouping processes for scheduling. More recent versions of the patch do exactly that. The session-based group scheduling mechanism appears to be stabilizing; chances are good that it will be merged in the 2.6.38 merge window.

基于 TTY 的组调度补丁集的最主要的变化是它目前已经不再基于 TTY。过去以任务（译者注，本文中有时也叫进程，两者混用）关联的控制终端作为分组的依据，将相关的任务组织到组中并以组为单位竞争处理器，但是目前有更好的选择。一种明显的可能性是基于会话标识符（session ID）。这个 ID 本身就标识了不同的进程组（译者注，一个会话由一个或者多个进程构成）；进程通过调用 `setsid()` 系统调用创建新的会话。由于内核已经使用会话这个概念将相关进程聚合在一起，因此在对进程进行分组调度时，借用会话 ID 作为分组依据是有意义的。升级后的补丁采用的就是这个方案。基于会话的组调度机制看起来已经逐渐为大家所接受；非常有可能在 2.6.38 的合并窗口中被合入内核主线。（译者注，该补丁集的确 [随 2.6.38 合入][2]。）

> Meanwhile, there have been a couple of discussions led by vocal proponents of other approaches to interactive scheduling. It is fair to say that neither is likely to find its way into the mainline. Both are worth a look, though, as examples of how people are thinking about the problem.

与此同时，针对如何提高交互性任务的调度响应，社区中提出了两种不同的方案。老实说，这些建议都不太可能被主线所接受。不过，还是值得在这里给大家介绍一下，看一看人们是如何思考这类问题的。

> Colin Walters [asked](https://lwn.net/Articles/418885/) about whether group scheduling could be tied into the "niceness" priorities which have been implemented by Unix and Linux schedulers for decades. People are used to `nice`, he said, but they would like it to work better. Creating groups for nice levels would help to make that happen. But Linus was [not excited](https://lwn.net/Articles/418739/) about this idea; he claims that almost nobody uses `nice` now and that is unlikely to change.

Colin Walters [询问][3] 是否可以基于各个任务的 “优先级值（niceness）” （这个几十年前就被 Unix 和 Linux 的调度器所使用的调度参数）对任务进行分组。人们已经习惯了现在 `nice` 命令的使用方式，他说，但或许他们会希望它提供更强的功能。基于 nice 级别创建分组将有助于实现这一目标。但是 Linus 对这个想法并 [不感兴趣][4]；他的理由是现在几乎没有人使用 `nice` 这个命令，所以也没必要去修改它。

> More to the point, though: the semantics implemented by `nice` are very different from those offered by group scheduling. The former is entirely priority-based, making the promise that processes with a higher "niceness" will get less processor time than those with lower values. Group scheduling, instead, is about isolation - keeping groups of processes from interfering with each other. The concept of priorities is poorly handled by group scheduling now, it's just not how that mechanism works. Group scheduling will not cause one set of processes to run in favor of another; it just ensures that the division of CPU time between the groups is fair.

更为重要的是：`nice` 命令的语义与组调度所希望实现的功能并不相同。前者完全基于优先级的概念，承诺具有更高 “nice” 值的进程将比具有较低值的进程获得更少的处理器时间（译者注，“nice” 值越高的进程其优先级越低。可以这么理解：“nice” 的原意有 “宽容仁厚” 的意思，而且是从进程或者任务相对于调度器的角度来说的。换句话就是说，对调度器来讲，哪个任务越好说话（其 “nice” 值越高），调度器就越不 “待见” 这个任务（给其分配的处理器时间越少））。然而，组调度的目的在于对任务进行隔离，确保划分后的进程组之间不会相互干扰。组调度并不关心优先级的概念，这不是该机制所追求的目标。组调度不会让一组进程在运行上优先于另一组进程；它只确保各个组之间在处理器时间的划分上是公平的。

> Colin went on to suggest that using groups would improve `nice`, giving the results that users really want. But changing something as fundamental as the effects of niceness would be, in a very real sense, an ABI change. There may not be many users of `nice`, but installations which depend on it would not appreciate a change in its semantics. So `nice` will stay the way it is, and group scheduling will be used to implement different (presumably better) semantics.

Colin 还建议，引入分组的概念将升级 `nice` 命令的功能，使得用户得到真正想要的结果。但是，从本质上来看，改变 `nice` 的行为意味着 ABI（译者注，即 [Application binary interface][6] 的缩写）上会发生变化。`nice` 的用户原本就不多，一旦其含义被改变将会直接影响依赖于该命令的其他软件运行。所以最好是让 `nice` 保持原样，而组调度则用于实现不同的（或许更好的）的功能。

> The group scheduling discussion also featured [a rare appearance by Con Kolivas](https://lwn.net/Articles/418887/). Con's view is that the session-based group scheduling patch is another attempt to put interactivity heuristics into the kernel - an approach which has failed in the past:

> 	You want to program more intelligence in to work around these regressions, you'll just get yourself deeper and deeper into the same quagmire. The 'quick fix' you seek now is not something you should be defending so vehemently. The "I have a solution now" just doesn't make sense in this light. I for one do not welcome our new heuristic overlords.

有关组调度的讨论甚至吸引了 [很少出现的 Con Kolivas][5]。Con 的观点是，基于会话的组调度补丁是另一种在交互性能上，试图在内核中引入试探方法（heuristics）的尝试，而这种做法在过去已经被证明是行不通的：

	你想要加入更多的判断来解决这些性能上的衰退问题，但这只会让你自己越来越陷入到同一个问题泥潭中。完全没有必要纠结于追求所谓的 “快速解决方案”。从这个角度来看，你所谓的 “我已经拥有了一个解决方案” 毫无意义。就我个人观点而言，我并不看好新的基于试探的处理。

> Con's alternative suggestion was to put control of interactivity more directly into the hands of user space. He would attach a parameter to every process describing its latency needs. Applications could then be coded to communicate their needs to the kernel; an audio processing application would request the lowest latency, while `make` would inform the kernel that latency matters little. Con would also add a global knob controlling whether low-latency processes would also get more CPU time. The result, he says, would be to explicitly favor "foreground" processes (assuming those processes are the ones which request lower latency). Distributors could set up defaults for these parameters; users could change them, if they wanted to.

Con 的另一个建议是将与交互性有关的决定权更直接地交给用户空间。譬如增加一个新的接口允许在创建进程时对其指定一个有关响应延迟要求的参数。应用程序通过调用该接口将其需求传递给内核；音频处理应用程序可以请求最低延迟，而 `make` 则通知内核它可以忍受较大的延迟。Con 还建议添加一个全局的调节参数，控制低延迟进程是否会获得更多的处理器时间。他说，这么做可以显式地提高 “前台” 进程（假定这些进程是希望较低延迟的）对交互响应的灵敏度。发布包提供商可以为这些参数设置默认值；而用户可以根据需要自行对其进行修改。

> All of that, Con said, would be a good way to "`move away from the fragile heuristic tweaks and find a longer term robust solution.`" The suggestion has not been particularly well received, though. Group scheduling was defended against the "heuristics" label; it is simply an implementation of the scheduling preferences established by the user or system administrator. The session-based component is just a default for how the groups can be composed; it may well be a better default than "no groups," which is what most systems are using now. More to the point, changing that default is easily done. Lennart Poettering's systemd-driven groups are an example; they are managed entirely from user space. Group scheduling is, in fact, quite easy to manage for anybody who wants to set up a different scheme.

Con 说，所有这些措施其目的都是为了 “`摆脱脆弱的基于试探的工作模式并找到长期稳定的解决方案。`” 但他的建议并没有得到特别的重视。组调度机制在设计上原本就注重避免被贴上 “采用试探方法” 的标签；所以如何启用它（译者注，包括如何分组）完全取决于用户或系统管理员的个人偏好。基于会话进行分组只是其中一种默认的可行方式；至少从默认行为上来看，它比当前大多数系统所使用的 “没有分组” 方式更好。需要了解的是，更改默认值其实很容易。Lennart Poettering 采用 systemd 的方案就是一个例子；而且完全在用户空间中进行管理。事实上，对任何人来说，想要采用自己的方式运行组调度都很方便。

> So we'll probably not see Con's knobs added anytime soon - even if somebody does actually create a patch to implement them. What we might see, though, is a variant on that approach where processes could specify exact latency and CPU requirements. A patch for that does exist - it's called the [deadline scheduler](https://lwn.net/Articles/356576/). If clever group scheduling turns out not to solve everybody's problem (likely - somebody always has an intractable problem), we might see a new push to get the deadline scheduling patches merged.

所以我们可能不会很快看到 Con 的调节方案被内核所接受，即便有人确实基于他的思路提交了一个补丁。但是，我们可能会看到和该思路类似的另一种实现形式，即可以对进程指定确切的延迟要求和处理器时间要求。这个补丁已经存在，被称之为 [deadline scheduler][7]。如果改进后的组调度还不能解决所有人的问题（这是有可能的，因为总会存在意想不到的情况），我们可能会看到新的推动来请求合入 deadline scheduler 补丁。

**请点击 [LWN 中文翻译计划](/lwn)，了解更多详情。**

[1]: /lwn-415740
[2]: https://kernelnewbies.org/Linux_2_6_38#Automatic_process_grouping_.28a.k.a._.22the_patch_that_does_wonders.22.29
[3]: https://lwn.net/Articles/418885/
[4]: https://lwn.net/Articles/418739/
[5]: https://lwn.net/Articles/418887/
[6]: https://en.wikipedia.org/wiki/Application_binary_interface
[7]: https://lwn.net/Articles/356576/
