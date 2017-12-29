---
title: LWN 中文翻译
tagline: LWN.net 中文翻译计划
author: Wang Chen
layout: page
album: 'LWN 中文翻译'
group: translation
update: 2017-11-10
permalink: /lwn/
description: 翻译 LWN.net 上大家感兴趣的文章。
categories:
  - Linux 综合知识
tags:
  - lwn.net
  - 中文翻译
---

## 活动简介

[LWN.net](https://lwn.net/) 是一份著名的计算机在线刊物，专注于报道有关自由软件，特别是有关 Linux 和其他 Unix-like 相关操作系统的新闻和技术动态。具体介绍参考 [Wikipedia](https://en.wikipedia.org/wiki/LWN.net)。

- 本活动目前主要针对 [LWN.net](https://lwn.net/) 的内核相关文章进行中文翻译，目前 LWN 的内核文章原文汇总在 [Kernel index][2]，我们的中文翻译成果汇总在 [LWN 中文翻译成果索引][3]。

- 本活动本着 “自愿参与，开放共享” 的原则进行。所有译文提交给 [泰晓科技][1] 公开发布后，均遵循 [CC BY-SA 4.0 协议](http://creativecommons.org/licenses/by-sa/4.0/) 许可。

- 所有译文提交给 [泰晓科技][1] 公开发布后，[泰晓科技][1] 保留继续修改并完善的权利。在尽可能征得原翻译人员同意的前提下，欢迎其他读者提交补丁继续完善原译文。

由于是集体活动，为尽量避免冲突，也为了协调大家的兴趣爱好，特别将本活动的翻译计划在此公布，方便有兴趣参与的人员了解活动的进展和动向。

- 本计划中所有已经被认领的文章列表可参见本文最后的 [翻译文章列表汇总](#articles_summary)。

- LWN 的内核文章 “原文” 汇总在 [Kernel index][2]，有志于参加本翻译计划的朋友可以从中挑选您感兴趣的文章，只要确保不和前述 [翻译文章列表汇总](#articles_summary) 中已经被其他人认领的文章冲突即可。

- 已经翻译完毕并正式发表的文章列表也可参考 [LWN 中文翻译成果索引][3]，该索引的格式和 [LWN 的内核文章汇总 “原文”][2] 保持一致。

## 参与流程

本活动欢迎广大爱好 Linux 的朋友一起参与，为保证活动的有序和质量，特制订如下流程：

![参与流程](/wp-content/uploads/2017/11/lwn-procedure.png)

- Step 1: 加入翻译团队

  [unicornx](https://github.com/unicornx) 为该项目的发起人，有意向参与的朋友请先加他微信（polardotw），然后再申请加入微信群 "LWN 翻译团队"，入群后请提供如下信息方便沟通交流。
  
  |姓名  |微信 id               |github id      |自我介绍|
  |------|----------------------|---------------|--------|
  |汪辰  |polardotw             |unicornx       |目前的工作方向，对 Linux 内核哪方面感兴趣或者比较擅长，另外如能提供您的英语水平等级资质更好 |

- Step 2: Fork 主仓库

  我们的工作基于 Github 进行，请首先注册 [github](https://github.com) 帐号，然后 [Fork TinyLab.org](https://github.com/tinyclub/tinylab.org#fork-destination-box) .

- Step 3: Clone 仓库

  克隆 Fork 后的代码仓库到本地并添加主仓库地址为 upstream，假设你的帐号是 `jack`

		$ git clone https://github.com/jack/tinylab.org.git
		$ git remote add upstream https://github.com/tinyclub/tinylab.org.git

- Step 4: 创建开发分支

  **注意：开始翻译前请和 polardotw (微信号) 联系，确定翻译的文章没有和其他人员冲突。**
  
  确认无误后创建开发分支进行翻译：

		$ git checkout master
		$ git checkout -b lwn-<XXXXXX>-<description>

  对开发分支的要求如下：

  - 分支基于 master 创建，一篇翻译文章对应一个开发分支，对应一次或者多次 `pull request` 和 一次 `merge`。

  - 开发分支的命名规则遵循格式 `lwn-<XXXXXX>-<description>`，其中 `XXXXXX` 是文章在 [LWN.net](https://lwn.net/) 上的编号；<description> 是你自己的简单描述，描述中只用英文字母，如果有多个单词用 `-` 分隔。例子：`lwn-123456-just-an-example`。

- Step 5: 本地翻译与修改

  在开发分支上工作 ( 假设你的开发分支为 lwn-123456-just-an-example )：

		$ git checkout lwn-123456-just-an-example

  修改 ......

  - 每篇文章翻译至少包含两个文件的修改，一篇是新增的译文，一篇是对主索引文件的修改。

  - 对于新增的译文，文件放在 `_posts` 目录下。

    - 文件的命名格式如下：`YYYY-MM-DD-HH-MM-SS-lwn-XXXXXX-<article title>.md`，其中 `article title` 是原文的标题，中间的空格用 `-` 代替，具体例子参考 `_posts/2017-10-10-06-04-32-lwn-448502-platform-devices-and-device-trees.md` 。可以用 `tools/post` 创建模板文件。**注意：如果审阅后需要涉及多次修改和提交，请每次确保修改文件名中的时间戳部分，采用最新时间确保文章发布后在网站上能够被置顶显示。**

    - 译文的内容要求，也请直接参考 `_posts` 目录下的例子，LWN 的译文采取中英文联排格式，方便阅读者对比，毕竟译文再好也比不过原文的魅力，另外也方便读者随时审阅。另外注意如果原文中有链接，并且该链接所指向的文章我们已经翻译的，请在译文中修改相应链接指向我们已经翻译的文章，具体例子可以参考 `_posts/2017-10-10-06-04-32-lwn-448502-platform-devices-and-device-trees.md` 中的 `[本系列文章的上篇](/lwn-448499-platform-device-api)` 部分。
  
    - 译文中的校对人信息第一次提交时可以先留空，等指定评审人后第二次修改提交时再补上即可。

  - 新增译文后需要修改主索引文件 `_posts/2017-10-23-22-55-32-lwn-kernel-index.md`，具体索引的格式直接参考 [Kernel index][2]，如果是新增的章节则增加章节后再添加文章链接，如果所属章节已经存在则直接添加文章链接。文章链接需要修改指向我们发布的链接。**注意 [Kernel index][2] 中同一篇文章可能划归多个章节分类下，我们也同样遵循该原则，与[Kernel index][2]保持一致。**
  
  - 另外，如果您是第一次参与 [泰晓科技][1] 的文章发表，请别忘记提交您的个人信息。提交方法请参考 `_data/people.yml` 进行添加。**注：该修改请以单独的 PR 提交，不要和译文工作混淆在一起，方便检查和合入。**

  修改完毕后：
  
		$ git add .
		$ git commit -s -m "commit title"

  **注意：我们要求在每次 commit 的时候务必添加注释和说明**

- Step 6: 提交到自己仓库

  准备提交，注意提交前务必和 tinylab 的 upstream 保持同步，具体操作如下( 假设本地开发分支为 lwn-123456-just-an-example )：

		$ git fetch --all
		$ git rebase --onto upstream/master --root
		$ git push origin lwn-123456-just-an-example

  如果 merge 过程中有冲突则自行解决后继续，解决冲突后记得继续执行 `git rebase --continue` 确保所有变更都已合入。

- Step 7: 发起 `pull request`

  进入自己的 github 仓库页面，找到标签 `pull request`，点击右侧的 `New pull request` 按钮创建一笔 PR，可以直接指向远程 master 分支。

  提交后会安排交叉审阅，审阅工作通过 github 在线完成。

  如果审阅过程中有修改则返回 Step 5 继续修改。**注意：**
  
   - 我们要求一次修改和评审对应一次 `pull request`，请翻译人员在完成上次评审的修改后关闭上次的 `pull request`，重新发起一次新的 `pull request` 。
   - 每次修改后再提请审阅时一定要和 upstream 时刻保持同步。

- Step 8: 管理员 `Merge pull request`

  如果文章无误，管理员就会直接把提交合并到主线。

  Congratulations! 至此您的文章将在 [泰晓科技][1] 上发布。

## 赞助我们

为了更好地推进这个翻译项目，期待不能亲自参与的同学能够赞助我们，相关费用将用于设立项目微奖激励更多同学参与翻译和校订。

赞助方式有两种，一种是直接扫描下面的二维码，另外一种是通过 [泰晓服务中心](https://weidian.com/item.html?itemID=2208672946) 进行。

更多高质量的 Linux 翻译文章需要您的支持！

## <span id="articles_summary">翻译文章列表汇总</span>

以下列表包含本 LWN 翻译计划中所有已经 **被认领** 的文章、及其翻译状态等其他信息（翻译状态包括"翻译中"，"校对中"，"已发表"），其中 "已发表" 的文章也同时列在[LWN 中文翻译成果索引][3]中。

**计划将随时保持更新，欢迎大家关注**：

| 状态   | 译作者(Github id)  | 校对(Github id)    | 文章  |
|--------|--------------------|----------------------|-------|
| 已发表 | Tacinight          | unicornx             |[The Btrfs filesystem: An introduction](https://lwn.net/Articles/576276/)|
| 已发表 | Tacinight          | guojian-at-wowo      |[Btrfs: Getting started](https://lwn.net/Articles/577218/) |
| 校对中 | Tacinight          | fan-xin              |[Btrfs: Working with multiple devices](https://lwn.net/Articles/577961/) |
| 翻译中 | Tacinight          |                      |[Btrfs: Subvolumes and snapshots](https://lwn.net/Articles/579009/) |
| 翻译中 | Tacinight          |                      |[Btrfs: Send/receive and ioctl()](https://lwn.net/Articles/581558/) |
| 已发表 | linuxkoala         | unicornx             |[CFS group scheduling](https://lwn.net/Articles/240474/)|
| 翻译中 | linuxkoala         |                      |[CFS bandwidth control](https://lwn.net/Articles/428230/) |
| 已发表 | unicornx           | lzufalcon            |[Device resource management](https://lwn.net/Articles/215996/)|
| 已发表 | unicornx           | Tacinight, lzufalcon |[The pin control subsystem](https://lwn.net/Articles/468759/)|
| 已发表 | unicornx           | lzufalcon            |[The platform device API](https://lwn.net/Articles/448499/)|
| 已发表 | unicornx           | lzufalcon            |[Platform devices and device trees](https://lwn.net/Articles/448502/)|
| 已发表 | unicornx           | lzufalcon            |[The managed resource API](https://lwn.net/Articles/222860/)|
| 已发表 | unicornx           | cee1, norlanjame     |[GPIO in the kernel: an introduction](https://lwn.net/Articles/532714/)|
| 已发表 | unicornx           | lljgithub            |[GPIO in the kernel: future directions](https://lwn.net/Articles/533632/) |
| 校对中 | unicornx           | w-simon              |[Device tree overlays](https://lwn.net/Articles/616859/) |
| 已发表 | unicornx           | WH2136               |[KS2009: Generic device trees](https://lwn.net/Articles/357487/) |
| 校对中 | unicornx           | maxiao1993           |[(Partially) graduating IIO](https://lwn.net/Articles/465358/) |
| 翻译中 | unicornx           |                      |[ELCE: Grant Likely on device trees](https://lwn.net/Articles/414016/) |
| 翻译中 | unicornx           |                      |[Device tree troubles](https://lwn.net/Articles/560523/) |
| 翻译中 | unicornx           |                      |[Device trees as ABI](https://lwn.net/Articles/561462/) |
| 翻译中 | unicornx           |                      |[Device tree bindings](https://lwn.net/Articles/572114/) |
| 翻译中 | unicornx           |                      |[Device trees I: Are we having fun yet?](https://lwn.net/Articles/572692/) |
| 翻译中 | unicornx           |                      |[Device trees II: The harder parts](https://lwn.net/Articles/573409/) |
| 翻译中 | unicornx           |                      |[Object-oriented design patterns in the kernel, part 1](https://lwn.net/Articles/444910/) |
| 翻译中 | unicornx           |                      |[Object-oriented design patterns in the kernel, part 2](https://lwn.net/Articles/446317/) |
| 翻译中 | norlanjame         |                      |[The Video4Linux2 API: an introduction](https://lwn.net/Articles/203924/) |
| 翻译中 | lljgithub          |                      |[Realtime KVM](https://lwn.net/Articles/656807/) |
| 翻译中 | fan-xin            |                      |[LTSI and Fuego](https://lwn.net/Articles/694880/) |
| 翻译中 | fan-xin            |                      |[Yocto 2.0](https://lwn.net/Articles/664073/) |
| 翻译中 | maxiao1993         |                      |[Deadline scheduling for Linux](https://lwn.net/Articles/356576/) |

[1]: http://tinylab.org
[2]: https://lwn.net/Kernel/Index/
[3]: http://tinylab.org/lwn-kernel-index/
