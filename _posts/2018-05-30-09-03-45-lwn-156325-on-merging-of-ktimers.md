---
layout: post
author: 'Wang Chen'
title: "LWN 156325: ktimers 补丁进展情况"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-156325-on-merging-of-ktimers/
description: "LWN 文章翻译，ktimers 补丁进展情况"
category:
  - 时钟系统
  - LWN
tags:
  - Linux
  - timer
---

> 原文：[On the merging of ktimers](https://lwn.net/Articles/156325/)
> 原创：By corbet @  Oct 19, 2005
> 翻译：By [unicornx](https://github.com/unicornx) of [TinyLab.org][1]
> 校对：By [guojian-at-wowo](https://github.com/guojian-at-wowo)

> LWN [looked at the ktimers patch](http://lwn.net/Articles/152436/) about one month ago. Work continues on the new kernel timer mechanism; the [latest version](http://lwn.net/Articles/155862/) of the patch includes a new "clockevents" abstraction intended to make high-resolution timer support easier to implement in an architecture-independent way. The patch appears to be coming together well, and there has been little in the way of criticism.

LWN 在大约一个月前已经[给大家介绍了 ktimers 补丁](/lwn-152436-new-approach-to-ktimers)。随着开发的继续，在该补丁的最新版本中引入了一个新的 “clockevents” 抽象层，旨在方便地以与体系架构无关的方式实现对高精度定时器的支持。该补丁的开发工作看上去进展良好，得到了社区的一致好评。

> ...with the exception of one observer, who has kept up a steady stream of complaints about the new mechanism. His objections include the name (he would rather see "process timers" than "ktimers"), the use of high-resolution time within the kernel, and various "unnecessary complexities." The discussion has been mostly unfruitful, to the point that the normally even-keeled Ingo Molnar tried to end it with a [shut up and show me the code challenge](https://lwn.net/Articles/156327/). That led Andrew Morton to state that "show me the code" is no longer an acceptable arguing point for kernel discussions, and that the objections should be addressed regardless.

... 但也有一个例外，有一个反对者对该新机制一直颇有怨言。他的反对意见包括诸如补丁的名字（他更倾向于把它叫做 “进程定时器”（"process timers"）而不是“内核定时器”（“ktimers”）），在内核中不该使用高分辨率的时间单位，以及各种所谓的 “不必要的复杂性”。相关的讨论大多毫无结果，以致于一向在争论中尽量保持中立的 Ingo Molnar 也忍不住了，[很不客气地试图让他闭嘴，甚至说如果有能耐就自己提交补丁代码之类云云（shut up and show me the code）](https://lwn.net/Articles/156327/)。充满火药味的讨论导致 Andrew Morton 也不得不出面声明希望在内核社区的讨论中不要再出现诸如此类的言语（即 "show me the code"） ，大家还是要就事论事，心平气和地通过讨论解决所有的分歧。

> Getting a handle on the objections has proved hard; it is not clear that the person in question (Roman Zippel) truly understands the patches. One bit of the discussion is worth a look, however. It has been repeatedly pointed out that the existing kernel timer mechanism is optimized for timeouts which rarely actually expire, while ktimers are expected to expire. Roman [claimed](https://lwn.net/Articles/156328/):

> ```
> Whether the timer event is delivered or not is completely unimportant, as at some point the event has to be removed anyway, so that optimizing a timer for (non)delivery is complete nonsense.
> ```

> This claim led to [a required-reading response from Ingo](https://lwn.net/Articles/156329/) on the history of the kernel timer mechanism and why optimizing for delivery (or the lack thereof) is not nonsense. That particular branch of the discussion, at least, should not need to go much further.

然而试图完全理解反对者的出发点并不是件容易的事情; 特别是到目前为止大家并不清楚该反对意见持有者（即 Roman Zippel）是否真正了解该补丁的设计。不过在讨论中有一个事情倒是值得大家关注一下。在很多地方我们已多次指出，现有的内核定时器机制针对很少实际到期的超时场景进行了优化，而 ktimers 补丁主要针对的是经常到期的场景。Roman [在讨论中提出](https://lwn.net/Articles/156328/)：

```
定时器事件是否到期完全不重要，因为在某些时候事件最终总是会被移除，所以对不会到期的定时器事件进行优化是完全没有意义的。
```

这种说法导致 [Ingo 专门撰文](https://lwn.net/Articles/156329/)解释了内核定时器机制的发展历史，以及优化（或不优化）的具体原因。该回应写得十分精彩，强烈建议大家好好读一读。当然，具体有关这方面的争论实在是已经没有必要再继续下去了。

> Andrew Morton has, in the past, stated that he would be highly reluctant to merge new code over the objections of a developer. The need to address all objections can be highly frustrating to kernel hackers, especially when new complaints seem to keep turning up as the old ones are resolved. The result of this process, when it works well, can be a stronger kernel. But it can also be the delaying of useful code which few people have problems with. It is starting to look like that may be the outcome in the ktimers case; the code will almost certainly be merged in the end, perhaps with almost no changes resulting from the current discussion.

Andrew Morton 过去曾表示，对于新提交的补丁，只要还有开发人员持反对意见，他是不建议将其合入主线的。但如果试图解决所有的反对意见，这对于内核开发人员来说实在是一件非常令人沮丧的事情，特别是旧的问题还没解决，新的反对意见又冒出来的时候。当然这个过程如果处理得当，对内核的发展是件好事。但这也可能导致有用的代码无法被及时合入，而这仅仅是因为只有很少的人持反对意见。目前看起来，ktimers 补丁被合入内核主线是确定无疑的了，而前面所介绍的那些讨论应该也不会对该补丁有什么影响。

[1]: http://tinylab.org
