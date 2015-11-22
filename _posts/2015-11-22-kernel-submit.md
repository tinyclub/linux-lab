---
layout: post
author: 'Wen Pingbo'
title: "2015 内核峰会简报"
group: "news"
permalink: /kernel-submit-2015/
category:
  - 技术动态
tags:
  - Linux
  - Kernel Submit

---

> By Pingbo of TinyLab.org
> 2015-11-22

今年的内核峰会是在 10 月 26 - 28 日，韩国首尔举行，到现行已经过了大半个月了。下面让我们一起看看今年的内核峰会的亮点。

## Day 0 - minisummit

往年，内核中各个子系统一般会在内核峰会之前，举办一些针对特定子系统的小型峰会。但今年只有多媒体子系统开了一个小型峰会，并且还是 Samsung 主办的。难道其他开发者不想来首尔了？

在这个峰会上，开发者讨论了多媒体子系统中以后的发展方向，以及一些重要的 API 变更方向。详细报道见：[[S-OSG](http://blogs.s-osg.org/planning-future-media-linux-linux-kernel-summit-media-workshop-seoul-south-korea/)]

## Day 1 - open technical day

### 在手机上运行最新的主线内核

Rob Herring 为了让 Project Ara 运行最新主线内核，已经在这个点上工作了一年。但是最终的结果是让人悲伤的。所以 Rob 在内核峰会上发起了这个讨论，看是否有一些解决方案。这个议题获得了很多的人的响应。大部分人认为 Android 手机不使用主线内核，是因为平台商没有及时跟进上游的开发进度，并且平台商很少向社区反馈他们所遇到的问题。同时，Tim Bird 指出最开始的 Android 手机就没有使用主线内核，这给后来者开了一坏头。Arnd Bergmann 和 Johannes Berg 也指出现在主线内核中并没有一个完全免费的 GPU 驱动，最新的 WIFI 特性也不会立即进入主线内核中，这也阻碍了在手机上运行主线内核。[[LWN](http://lwn.net/Articles/662147/)]

好吧，这其实是各位技术大牛的吐槽。现在每个新平台的研发周期这么短，新特性又这么多。而内核社区的代码 Review 周期又这么长，并且这个社区还经常反应迟钝，犯二。实在很难让平台商有动力去推动这件事。相比这个，主线内核对现有的开源硬件（beaglebone, cubieboard, dragonboard, etc）支持的很好。这些开源硬件所用的 Soc 和手机很类似，但为什么对内核社区的追捧程度却迥异？我想这是因为没人会买一个不支持主线内核的开源硬件吧。

### 废除 kthread freezer

Jiri Kosina 在内核峰会上提出现有的 kthread freezer 是非常不合理的。原因有二，一是 freezer 机制本身只是保证系统能够睡下去，而这只需要 freeze 用户态程序。内核线程有很多种方法可以让系统睡不下去，而这是 kthread freezer 所无法阻止的。二是 kthread freezer 在调用 `try_to_freeze()` 之前，不主动清除 `PF_NOFREEZE` 标志。这让系统中一些内核线程永远都无法被 freeze。最后，Jiri 提出，我们可以只去 freeze 上层应用，移除 kthread freezer。相比于 kthread freezer，只把文件系统 freeze 是一个更好的选择。[[LWN](http://lwn.net/Articles/662703/)]

尽管这里存在很多疑问，但 kthread freezer 确实存在一些设计缺陷。至于内核社区是否接受这个想法，还得看 Jiri 提交的 Patches。

### 全局 PM 配置选项

很多硬件都带有多个低功耗状态，但是配置这些状态的接口都非常分散，甚至有一些设备的状态完全无法被发现。这让做功耗优化的开发者很头疼。而 Rafael Wysocki 就指出，我们可以通过做一个全局配置选项来控制各个设备的状态，或者在用户层实现一个全局的配置的接口，这样用户就可以很方便的调节各个设备的状态。但参加这个会议的其他人认为现在的工作重点应该是 Power 相关的接口的标准化，以及各个接口文档的补充。[[LWN](http://lwn.net/Articles/662701/)]

理想很美好，现实很残酷。且行且珍惜。

### 设备依赖和延迟 probe

如果一个设备 A 依赖 设备 B，那么设备 A 需要等待设备 B 加载完后，才能继续初始化。这在内核中，已经有相应的 patches 来应对这种情况 - [deferred probing](http://lwn.net/Articles/658690/)。但是 Mark Brown 觉得这个方案没有完全解决这个问题。而 Grant 也指出内核现有设备树结构不能完全描述现实世界的设备依赖关系，尽管可以从 DT 中获取部分信息。整个小组都觉得应该在驱动核心中实现一个设备依赖机制来解决这个问题。

Rafael J. Wysocki 随后提出了他的解决方案 - [device link](http://lwn.net/Articles/662205/)。通过管理 device_link 结构体：

```
struct device_link {
        struct device *supplier;
        struct list_head supplier_node;
        struct device *consumer;
        struct list_head consumer_node;
        <flags, status etc>
};
```

来描述设备之间的依赖关系。

### 其他

* [Benchmarking and performance trends](http://lwn.net/Articles/662825/) - Chris Mason(Facebook) 和 Mel Gorman(SUSE) 介绍了内核各个模块的性能衰退问题，以及 Facebook 和 SUSE 在这些模块中的优化。调度器和 block 是其中两个大块。

* [Realtime mainlining](http://lwn.net/Articles/662833/) - 实时内核又获得到了资金支持（LinuxFoundation），而这个项目的领导者 Thomas Gleixner 介绍了相关工作。

* [Kernel security: beyond bug fixing](http://lwn.net/Articles/662219/) - Kernel Security 的维护者 James Morris 指出，内核安全不应该只是做一些 Bugfix 和访问控制。而应该主动保护自己，来防范那些 0Day 攻击。James 同时提出了一系列的步骤来解决这个问题。

* [Developer workflow security](http://lwn.net/Articles/662839/) - 内核各个模块的核心维护者是有能力直接往主线内核提交代码的。那么，怎样保证各个维护者的开发环境是安全的，且不被坏人利用？来看看各个 maintainers 是怎样做的。而其中比较有趣的是，Linus 在这个议题中有过这样一句话：

  > Does anybody have the SSH daemon running? "Don't do that" was my advice there.

## Day 2 -  invitation-only day for core developer

### Restartable sequences

在内核代码中，我们可以通过 per-cpu 变量来避免 cpu 之间的竞争。但是用户态程序却不能使用 per-cpu 变量来做相同的事情，它们只能通过加锁来避免竞态。但是锁是非常影响性能的，特别是在一些高并发的场景。Paul Turner 提出一个新的机制 - [Restartable sequences](http://lwn.net/Articles/650333/)（原谅我，作者真的不知道怎么翻译这个词），通过创建一个特殊的内存区域，来存放数据。当检测到线程在 cpu 之间切换时，所有的指令重新执行。这样就可以让用户态程序通过系统调用来使用 per-cpu 这一机制，从而可以避免使用锁，提高性能。尽管这种方法有很多限制，但 Paul 确实做到了。

而在这次内核峰会中，就专门有一个议题来讨论是否应该合入这个新特性。尽管最后并没有一个确定的结论，但可以去看看他们是怎么吵架的。[[LWN](http://lwn.net/Articles/662946/)]

### Lightning talks

每一年内核峰会都有一次大杂谈，来把那些不够独立成议题的问题汇总起来，在一个会议中讨论，今年也不例外。

这次大杂谈的主要内容有：

1. y2038 问题 - Arnd Bergmann 介绍了 y2038 现状，并表示现在还有 200 多个 patches 还没有合入主线内核。移除了 time_t，并添加了一个新的系统调用来获取正确的时间。同时，input 系统的 y2038 问题可能需要上层也做一些改动。ext4 需要一个扩展的 inode 来避免 y2038 问题。

2. Tim Bird 指出当前主线内核和真实产品所有的内核差别非常大。并列举了当前手机平台内核的主要差异。

### 其他

* [Kernel testing](http://lwn.net/Articles/662882/) - 自从内核自动测试框架合入到 3.17 后（kselftest），很多集成测试可以进行。Shuah Khan 和 Masami Hiramatsu 总结了现在内核测试的现状，以及未来的方向。

* [Developer recruitment and outreach](http://lwn.net/Articles/662911/) - Greg Kroah-Hartman 指出内核开发的门槛很高，而我们应该非常热情的帮助开发者参与到内核社区。同时 Greg 提出是否可以对新手放低一些要求，来降低门槛，但这并没有得到很多人的响应。大部分人认为参加 Outreachy 和 Gsoc 项目来参与到内核开发，是一个不错的选择。Greg 也号召各个 maintainers 制作一份不是很难的 tasklist，让新手可以认领，并且让 LinuxFoundation 可以资助。

  > I prefer to see self-driven people coming into our community. They need to have enthusiasm or they won't stick with it. - Christoph

  > We, as a community, are good at killing enthusiasm, be it by not responding to patches or arguing over little details. We should remember, that maintainership is a service role and act accordingly. - Dan Williams

* [Kernel documentation](http://lwn.net/Articles/662930/) - Jonathan Corbet 内核文档的维护者，介绍了内核文档生成工具的开发现状，以及内核文档的模板和格式的建立。

* [The stable kernel process](http://lwn.net/Articles/662966/) - 介绍了内核稳定版本存在的问题。Greg 在会议的最后，也宣布 4.4 将会成为下一个内核稳定版本。

* [Is Linus happy?](http://lwn.net/Articles/662979/) - 就像春晚每次结束时都有一个”难忘今宵”保留节目，内核峰会在结束时，也有一个保留节目 - “Is Linus happy?”。就跟标题说得一样，就是听 Linus 对今年内核社区的吐槽。而万幸的是，今年 Linus 并没有开启骂街模式。只是提了一下，现在他还缺一个内核回归测试的维护者，来告诉 Linus，这个版本的内核该不该 release。Linus 也表示，希望有更多的子系统可以成立一个维护者小组，而不是单枪匹马一个人。而其他维护者也介绍了他们的维护小组是怎样工作的。