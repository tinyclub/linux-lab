---
layout: post
author: 'Wu Zhangjin'
title: "如何获取 Linux 某个子系统上游最新代码"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /latest-linux-code/
description: ""
category:
  - 技术动态
tags:
  - upstream
  - git
  - patchwork
  - mailing list
---

> By Falcon of [TinyLab.org][1]
> Dec 09, 2019

## 背景简介

有同学在『Linux 知识星球』微信群问到：

> 比如某个内核子系统，我想看看 upstream 上面最新的代码，怎么找比较方便啊。

这里把回答整理如下。

## Linux 社区开发模型

回答这个问题，首先要了解 Linux 的开发模型，从开发模型中找出代码流向，包括代码来自哪里，走向哪里，用什么东西存储的，用什么方式 Review，以及哪里可以找到对代码的解释和描述。

在 [如何往官方 Linux 社区贡献代码](http://tinylab.org/contribute-source-code-to-linux-mainline/) 一文中，我们介绍了 Linux 的开发模型和 Upstream 流程。

![官方 Linux 开发模型](http://tinylab.org/wp-content/uploads/2019/12/latest-linux-code/linux-dev-model.jpg)

这里做个回顾：

1. Linux 社区中的代码流向

    Developers -> Subsys -> Next -> Mainline -> Stable -> Longterm

    越到后面理论上越 Stable，越到前面越新。是否 Upstream，通常以进入 Mainline 为界，也就是进到 Linus 维护的主仓库。

2. 代码提交的方式：邮件列表

    绝大部分的子系统的邮件服务都由 vger.kernel.org 提供，在这里可以找到完整的列表：[Majordomo Lists at VGER.KERNEL.ORG](http://vger.kernel.org/vger-lists.html)。

    部分厂家和子系统有搭建自己的邮件服务，请另行查找，这不做说明。

    需要提到的是，社区的邮件要求是 plain text 的，主要就是方便贴 patch 和打 patch。所以，很多对 plain text 支持得不友好或者被国人滥用的邮件地址都被 block 了。

3. 代码 Review 的方式：邮件列表

    社区至今还在用“最原始最古老”的方式做代码 Review，没有用任何复杂的现代工具，比如 Gerrit。我原来在部门也试行推广过这种传统的方式，其实效果还是可行的，反而 Gerrit 比较容易被忽视，沦为一个简单的“确认器”（+1/+2）。

    邮件，配合 Tested-by, Reviewed-by, Signed-off-by 等关键字就可以把代码提交方、Review 方、测试方，几种不同的角色呈现出来。

4. 代码存储的方式：Git & Patchwork

    代码在不同状态存储的方式其实是有差异的，在提交方（Signed-off-by）可能是 Git 仓库，进入到 Subsys maintainer， Linus （mainline） 或者 Greg-KH (stable, longterm) 那里，也是 Git 仓库。

    对于通过 Reviewed-by 和 Tested-by 的 patchset，Maintainer 才可能会 Merge 到上游仓库，剩下的呢，还继续呆在提交方的 Git 仓库，这些仓库可能是私有的，也可能是公开的企业仓库。不过，还有一种存在方式，那就是 patchwork。patchwork 监控了所有的 mailing list，并且把里头的 patch 全部抓出来，存档了一份。

    所以，我们除了 Git, patchwork 也是一种 Linux 社区存储代码的方式，它在存档代码方面比邮件友好很多，可以打包成 bundle 下载，甚至还有脚本可以直接拉下来给 git am 使用。

5. 代码提交计划

    在撰写和正式提交代码之前，通常会有看到带 RFC 的代码或者文档，这类代码是在酝酿新的计划，是值得关注的趋势。及早关注，有望跟进社区的发展动态，或者获取好的思路和创意。

6. 代码的解释和描述

    回到上面的邮件，在提交方发送代码时，通常是用 git format-patch 生成一组 patchset，然后在这组 patchset 之外，通常还会通过 `--ccover-letter` 加一个 cover letter，需要加上 "BLURB" (简介、推荐广告)。这个 cover letter 会有这组 patchset 的详细描述。

    除了这个 Cover letter，每个 patch 有单独的 commit log，另外，在某个内核版本发布以后，[kernelnewbies.org](https://kernelnewbies.org/) 会有版本发布记录，会对一些关键 feature 做综述，而 lwn.net 对一些关键 feature 会有专题文章发表。

## 小结

所以，综合来回答这个问题。

* 查看已经进入了主线的代码

  可以用 Git log 去看 Mainline/Stable/Longterm 中 subsys 所在目录和文件的变更。从 Commit log 中可以查看变更描述。

  与此同时，可以看 [kernelnewbies.org](https://kernelnewbies.org/) 和 [lwn.net](https://lwn.net/) 的相关报导。

* 查看已经发起 upstream 的代码（含已经进入、正在 Review 和未进入的）

  可以去 [patchwork.kernel.org](https://patchwork.kernel.org/) 查看，这个站点按照子邮件列表的方式分门别类抓取了数十种不同子系统或者架构的所有 patchset。

* 查看还在各个子系统酝酿的代码

  可以去各个子系统的代码仓库查看，通常正在准备 upstream 的代码，会有类似 upstream 和 next 这样的分支。例如 MIPS Linux 的 patchwork 在这里：[Linux mips](https://patchwork.linux-mips.org/project/linux-mips/list/)。

最后，Patchwork 官方地址在这里：[patchwork](http://jk.ozlabs.org/projects/patchwork/)，得空也可以[给 Linus 发个 Patch 吧](http://tinylab.org/upstream-patches-to-linux-mainline/)。

[1]: http://tinylab.org
