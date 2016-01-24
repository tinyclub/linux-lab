---
layout: post
author: 'Wu Weilin'
title: "如何贡献内核补丁（Kernel Mainlining）"
album: "嵌入式 Linux 知识库"
group: "translation"
permalink: /embedded-linux-kernel-mailining/
description: "本文为嵌入式开发者介绍了如何往 Linux 内核主线贡献补丁。"
category:
  - 开源社区
tags:
  - Linux
  - 社区
  - Mainlining
  - Upstream
  - 补丁
---

> 书籍：[嵌入式 Linux 知识库](http://tinylab.gitbooks.io/elinux)
> 原文：[eLinux.org](http://elinux.org/Kernel_Mainlining)
> 翻译：[@DecJude](https://github.com/DecJude)
> 校订：[@lzufalcon](https://github.com/lzufalcon)

## 通用资源

-   [Documentation/HOWTO](https://www.kernel.org/doc/Documentation/HOWTO)
    - 说明了如何为 Linux 内核编写并贡献代码
-   [Documentation/development-process](https://www.kernel.org/doc/Documentation/development-process/)
    - 讲述了内核开发流程


### 相关演讲

Greg KH 曾做过一次伟大的演讲，主题是关于 Linux 社区是如何工作的，下面是演讲内容的链接，可以参考用以入门:

-   [Linux 内核开发（PDF）](https://github.com/gregkh/kernel-development/blob/master/kernel-development.pdf?raw=true)

更早的时候（2008 年），Andrew Morton 在一次演讲中谈到了往 Linux 内核贡献的原因，以及往内核社区贡献代码的最佳方法：

-   [kernel.org 开发和嵌入式世界](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Kernel_Mainlining/Session:kernel.org_development_and_the_embedded_world/Session:kernel.org_development_and_the_embedded_world.html "Session:kernel.org development and the embedded world")
    -   在 2008 年的这次开创性的演讲中，Andrew 勾勒出了嵌入式企业参与内核开发的情景。他讲解了整个开发流程，更为重要的是，他讲到了开发者们很期待的内容，即在一步步 Mainlining（往内核贡献补丁）的过程中，要做什么，不要做什么，以及如何组建团队，以便可以和内核社区高效地协同工作。


#### 演讲列表

下面是之前提到的 Linux 会议中的关于 Mainlining 和社区参与的一系列演讲:

-   [如何参与内核开发过程（PDF）](http://eLinux.org/images/0/00/Corbet-dev-process.pdf "Corbet-dev-process.pdf")
    - 2007 年嵌入式 Linux 会议，举办于 2007 年 4 月，由 Jonathan Corbet 报告
    - 这次演讲旨在厘清那些取得成功和导致失败的因素，这将在某种程度上帮助到那些意图将代码合入内核主线的人。
-   2008 年 Andrew Motion 的演讲 （同上）
-   适当的社区做法: 社会和技术咨询 - 2008 年嵌入式 Linux 会议，举办于 2008 年 4 月，由 Deepak Saxena 报告
    -   摘要：随着 Linux 在嵌入式领域越来越受欢迎，硬件厂商们都在跃跃欲试，想要为他们的设备/芯片/SoC 添加对 Linux 内核的支持。在社区内，我们不断看到同样的错误在重演（包括技术和交流方面）。参与内核社区我们可以得到一些益处，并且可以借鉴一些 Linux 开发生态系统中失败的例子，来适当加以练习，从而提高代码被收录到 kernel.org 的几率;
-   [嵌入式 Linux 维护者：社区和嵌入式 Linux](http://eLinux.org/images/c/c5/Dwmw2-community_and_embedded_linux.pdf "Dwmw2-community and embedded linux.pdf") - 在 2008 年欧洲嵌入式 Linux 会议上，由 David Woodhouse 报告
    -   这次演讲介绍并讨论了关于"嵌入式内核维护者" 的新的社区规则，和 David 主席的一些构想，并且在寻求大家的意见。即"嵌入式内核维护者"这个工作实际上应该意味着什么？
    -   内核社区迫切需要更加凝聚 - 不仅仅是希望大公司和我们关系融洽，也是因为到目前为止我们还没有建立起一个围绕嵌入式 Linux 的社区。他们本应该协同工作，但即使在少数的项目中也没有做到。"嵌入式内核维护者"的角色和其他内核模块的维护者不一样 - 我们甚至没有自己的特定的整块代码，只是扮演了看门人和权威人士（arbiter of taste）的角色。所以更多的是需要把开发者聚在一起，让大家更好的合作。
-   [嵌入式 Linux 和主线内核](http://eLinux.org/images/c/c5/Dwmw2-ELC-2009-04.pdf "Dwmw2-ELC-2009-04.pdf")
    -   2009 年嵌入式 Linux 会议，举办于 2009 年 4 月，由 David Woodhouse 报告
    -   在技术层面，嵌入式 Linux 和其他的 Linux 应用领域的共性，比嵌入式开发者意识到的要多得多。在这次演讲中，David 将会阐述嵌入式开发者们所关心的功能与那些企业和桌面级系统需求之间的许多重要的交叉领域。那些关于嵌入式开发者不需要和更大 Linux 社区进行互动交流的陈辞滥调是站不住脚的。David 不但讲解了应对不断增加的社区内协同工作的技术原理，也为嵌入式开发者更好的参与进来提供了一些建议。
    -   Notes: 从嵌入式领域外找寻其他有相同需求的第三方。 虚拟化系统是一个很值得去了解的地方，因为他们经常会有资源方面的约束。
-   [社区内的合作与发展](http://eLinux.org/images/5/50/CommunityDevelopment.pdf "CommunityDevelopment.pdf") - 在 2009 年嵌入式 Linux 会议上，由 Jeff Osier-Mixon 报告
    -   这次演讲介绍了 MELD （MontaVista 主办的嵌入式 Linux 社区）
-   [成为内核社区的一部分](http://eLinux.org/images/6/63/Elc2011_bergmann_keynote.pdf "Elc2011 bergmann keynote.pdf") - 在 2011 年嵌入式 Linux 会议上，由 Arnd Bergmann 报告
    -   这次演讲介绍了被整合进 Linux 社区的好处（嬉皮士风格的演讲）。
-   [开发者日记：去推动进程](http://eLinux.org/images/f/fe/Elc2011_sang.pdf "Elc2011 sang.pdf") 2011 年嵌入式 Linux 会议，举办于 2011 年 4 月，由 Wolfram Sang 报告
    -   包括了往内核主线贡献代码的最佳做法的记录。
-   为社区做贡献？你的经理支持你吗？ - 在2011 年欧洲嵌入式 Linux 会议上，由 Satoru Ueda 报告
    -   这是一场关于"如何说服你的上司"的演讲。
-   ELC-2013 rose
-   ELC-2013 chalmers
-   ELC-2014 maupin
-   [两年的 Mainlining ARM Soc 支持的经验与教训](http://eLinux.org/images/d/dc/Petazzoni-soc-mainlining-lessons-learned.pdf "Petazzoni-soc-mainlining-lessons-learned.pdf") - 2014 年嵌入式 Linux 会议，举办于 2014 年 4 月，由 Thomas Petazzoni 报告
    -   给出了很多好的技巧，包括社群方面的。


### 训练，指导和挑战

-   [内核新手网站](http://kernelnewbies.org/) 是一个专注于帮助开发者学习如何往 Linux 内核做贡献的网站
    -   该网站有一个"待做" 列表，上面是一些小的开发任务，地址在[http://kernelnewbies.org/KernelJanitors/Todo](http://kernelnewbies.org/KernelJanitors/Todo)
    -   他们有个非常好的 [上游合并指南](http://kernelnewbies.org/UpstreamMerge) 板块，那里有很多技术以及社群方面的技巧。

-   The Outreach Program For Women（女性推广项目）有一个非常好的指导步骤，是关于如何贡献你的第一个补丁到内核
    -   [OPFW 第一个内核补丁教程](http://kernelnewbies.org/OPWfirstpatch)

-   [Eudyptula 挑战](http://eudyptula-challenge.org/)
    -   这是一个通过邮件来管理的一系列任务，总共 20 个， 用以帮助开发者学习如何开发内核并提交补丁。
    -   LWN.net 的文章：[http://lwn.net/Articles/599231/](http://lwn.net/Articles/599231/)

-   [Linux 内核骇客新手指南](http://www.tuxradar.com/content/newbies-guide-hacking-linux-kernel)


## 具体项目

-   [CE 工作组设备 Mailining 项目](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Kernel_Mainlining/CE_Workgroup_Device_Mainlining_Project/CE_Workgroup_Device_Mainlining_Project.html "CE Workgroup Device Mainlining Project")
-   [高通 SOC Mainlining 的项目](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Kernel_Mainlining/Qualcomm_SOC_Mainlining_Project/Qualcomm_SOC_Mainlining_Project.html "Qualcomm SOC Mainlining Project")
-   [全志 Mainlining 的努力](http://linux-sunxi.org/Linux_mainlining_effort)
    -   这是一个相当好的网站，上面更新了已经合入各内核分支的补丁的状态，以及哪些些任务仍在进行中。


## 最佳行动说明


### 来自 Andrew Morton

-   工业界应当有一个嵌入式内核维护者
-   向内核社区上报问题和需求
-   参与社区论坛
-   企业应该贡献出几位工程师，独立于产品开发团队
-   基于最新的内核主线开发产品，产品开发结束时冻结它（译者注：不再和主线保持同步）。
    -   从我所了解的看：目前 Android 相关模块和板级支持不在此列（译者注：主流 Android 设备都会不定时获得系统更新，包括了 Linux 内核)。
-   向社区（Andrew）寻求帮助


### 来自 Deepak Saxena

-   不要傲慢 - 不要试图把你在特定领域开发的经验照搬到开源领域
    -   保持谦逊并听取其他人的想法
-   早点发布，频繁发布
    -   不这样做的话，以后会浪费很多时间在实现的推翻和重写上面
-   个人练习
    -   看看那些 Linux 内核已经实现了的部分，看它是否可以扩展来支持你的案子。
    -   把实现加入到现有的抽象层，而不是用你自己的新潮的方案 (愿意去舍弃你自己的部分代码，只要最终你的相关模块可以得到社区支持)
-   不要添加 OS 层面的抽象实现（或者是来自其他操作系统的 HAL 层）
    -   驱动程序必须是位于 Linux 内核层面 - 位于其他层和复杂的驱动程序没有办法被 Linux 内核开发者所维护
-   添加抽象实现 - 不要仅仅只解决你眼前的问题
    -   实现支持多个相关硬件的系统方案
    -   有意愿去推广普及
-   个人练习
    -   使用 Mainlining 资源
    -   提出有见解的问题
-   和社区协同工作，把他们看作是你自己的团队
    -   把来自外部的开发者当作你的团队成员
    -   尊重他们


### 来自 Jonathan Corbet

-   原因 <查看演讲稿>
-   专有软件和开源软件的差异
    -   专有软件 = 产品驱动，自上而下的需求，短期，内部品控，层层决策，私有代码库，完全控制
    -   开源软件 = 流程驱动，自下而上的需求，长期，外部品控，一致决策，公共代码库，轻度控制
-   理解补丁的生命周期
    -   尽早发出来，通过社区解决问题
    -   进入 staging 目录
    -   被内核主线接纳
-   尽早发布，频繁发布
-   提交补丁
    -   发送变更，即使不被接受也可以影响相关方向
    -   不要有一对多的补丁， 把每个补丁做到简单和独立
    -   做出一分为二的补丁系列
    -   遵循提交规则
        -   使用 `diff -u`，不带媒体信息，格式正确，添加署名行（Signed-off-by），避免自动换行
            watch word-wrapping
    -   发送到正确的地方: MAINTAINERS（维护人员），可通过 get-maintainer.pl 工具自动获得
    -   听取审核人的意见，要有礼貌，不要忽略他们的反馈
-   看开点
    -   你的代码或许要重写或者被替换
-   写代码
    -   遵循代码风格规范
        -   不要太多 (HAL 层，没有用到的参数，只有一行代码的函数)
            -   不要有支持多个 OS 的代码
        -   不要太少 - 如果相关实现已经有了，应当推广之
    -   不要破坏 API
        -   只有在理由充分时才可以破坏内核的 API，但是你也必须把整个内核的相关部分都修复
        -   永远不要破坏用户空间的 API
    -   不要引发衰退


### 来自 Arnd Bergmann

-   朋友，支持者和不速之客
-   不要（通过下述方式之一）骚扰你的内核维护者
    -   公开你所有的代码，包括设备驱动
    -   他们会很喜欢开源的 3D 嵌入式图形驱动
-   成为社区的一份子
-   付出和回报
    -   分步解决
        -   使用公开的源代码
        -   修改源代码 - 给每个功能做一个 git 分支
        -   每个分支都应该有机会向社区提交
    -   跨越浪潮
        -   尽可能的多去重构（译者注：应该是指 `git rebase` 来重构内核补丁，确保准备提交往内核的补丁足够逻辑清晰、代码干净）
    -   把产品的代码树和开发的代码树分开
        -   把开发一直放在单独的分支进行
    -   审核
        -   提供学习经验
        -   新来的人也可以评审，并且在这个过程中学习
    -   尊重
        -   审核人 - 要认可开发者的努力工作，即使你不得不打回他们的提交
        -   提交人 - 应当尊重审核人的经验和知识，按他们的建议来做，即使你可能并不认同
    -   拒绝
        -   维护者 - 拒绝差的代码比接受好的代码更为重要
    -   责任
        -   不要仅仅只复制这些基础的部分，还要扩展它，推广它


### 来自 David Arlie

[http://airlied.livejournal.com/80112.html](http://airlied.livejournal.com/80112.html)

* * * * *

你有很长的一段路要走，但首先你要从家里离开

或是为什么公开代码才是 STEP ZERO.

如果你已经在内部开发好了准备往内核贡献的代码，你也许有很多原因不能一开始就默认选择开源，你也许不是在像 Red Hat 这样的默认支持开源政策的公司工作，或者是你可能害怕恐怖的内核社区，想自己成为一块闪亮的宝石。

如果你的公司正在遭受代码合法性评审等等之类的痛苦，可能你已经花费/浪费了好几个月的工程时间在内部评审和相关事项上，所以你还有什么理由不去考虑这些问题呢？你都已经浪费了这么多的时间在这些事上了，这绝对是个问题

所以如果你都有了优雅的代码库，那么内核维护者们有什么理由不喜欢去合入它们呢？！

然后，你就公开了你的代码。

看吧，你才离开你的屋子。而合入你的代码还有数英里远的距离，你才刚刚踏上路途，是从现在开始算起，不是在你开始写代码的时候，不是在你开始做代码合法性评审的时候，也不是当你私底下第四次重写代码的时候。 你只是从现在开始。

也许你不得不公开重写的你代码多达 6 次， 也许你永远没有机会让它合入进去，也许你的竞争对手也在进行这方面的工作，内核维护者更希望你去跟他人合作，"操纵民意"的做法只会让他们大发雷霆，这就是内核开发的过程。

STEP ZERO: 公开你的代码。离开屋子。

（最近我看到这样的问题越来越多，所以我决定把它写出来，这真的不是针对特定的任何人，因为我想大部分的厂商都会犯这样的问题）。

* * * * *

\< 文章是关于为何你应该立即公开你的代码\>

-  这引发了这些问题:
    -   为何要尽早开源？ 因为如果不这样的话，后续的工作量可能会加倍
    -   立即开源代码的障碍是什么:
        -   依赖关系!!! （大部分是版本之间的差异）


## 克服 Mainlining 遇到的障碍

Tim Bird 为 2014 年欧洲嵌入式 Linux 会议准备了一篇关于 [克服 Mainlining 障碍](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Kernel_Mainlining/Overcoming_Obstacles_to_Mainlining/Overcoming_Obstacles_to_Mainlining.html "Overcoming Obstacles to Mainlining") 的演讲。那篇文章里头有演讲信息和演讲稿的下载链接。


[类别](http://eLinux.org/Special:Categories "Special:Categories"):

-   [内核](http://eLinux.org/Category:Kernel "Category:Kernel")
