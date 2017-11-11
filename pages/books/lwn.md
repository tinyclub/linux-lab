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

[LWN.net](https://lwn.net/) 是一份著名的计算机在线刊物，专注于报道有关自由软件，特别是有关 Linux 和其他 Unix-like 相关操作系统的新闻和技术动态。具体介绍参考[wiki LWN](https://en.wikipedia.org/wiki/LWN.net)。

- 本活动目前主要针对 [LWN.net](https://lwn.net/) 的内核相关文章进行中文翻译，目前 LWN 的内核文章汇总在 [Kernel index](https://lwn.net/Kernel/Index/)，其中文翻译成果汇总在 [LWN 中文翻译成果索引](http://tinylab.org/lwn-kernel-index/)。

- 本活动本着 “自愿参与，开放共享” 的原则进行。所有译文提交给 [泰晓科技](http://www.tinylab.org/) 公开发布后，均遵循 [CC BY-NC-ND 4.0 协议](http://creativecommons.org/licenses/by-nc-nd/4.0/) 许可。

- 所有译文提交给 [泰晓科技](http://www.tinylab.org/) 公开发布后，[泰晓科技](http://www.tinylab.org/) 保留继续修改并完善的权利。在尽可能征得原翻译人员同意的前提下，欢迎其他读者提交补丁继续完善原译文。

## 翻译计划

由于是集体活动，为尽量避免冲突，也为了协调大家的兴趣爱好，特别将本活动的翻译计划在此公布，方便有兴趣参与的人员了解活动的进展和动向。

- LWN 的内核文章原文汇总在 [Kernel index](https://lwn.net/Kernel/Index/)

- 已经翻译完毕并正式发布的文章列表请参考 [LWN 中文翻译成果索引](http://tinylab.org/lwn-kernel-index/)。

- 以下列表包含当前计划进行中已经认领的文章、及其翻译状态（状态包括"翻译中"，"审核中"，翻译完毕或者取消翻译的会从列表中删除）等其他信息。

**计划将随时保持更新，欢迎大家关注**：

| 认领人(Github id)| 状态   | 文章  |
|------------------|--------|-------|
| [tacinight][100] | 翻译中 | [The Btrfs filesystem: An introduction](https://lwn.net/Articles/576276/) |
| [tacinight][100] | 翻译中 | [Btrfs: Getting started](https://lwn.net/Articles/577218/) |
| [tacinight][100] | 翻译中 | [Btrfs: Working with multiple devices](https://lwn.net/Articles/577961/) |
| [tacinight][100] | 翻译中 | [Btrfs: Subvolumes and snapshots](https://lwn.net/Articles/579009/) |
| [tacinight][100] | 翻译中 | [Btrfs: Send/receive and ioctl()](https://lwn.net/Articles/581558/) |
| [linuxkoala][101]| 翻译中 | [CFS group scheduling](https://lwn.net/Articles/240474/) |
| [linuxkoala][101]| 翻译中 | [CFS bandwidth control](https://lwn.net/Articles/428230/) |
| [unicornx][102]  | 翻译中 | [The pin control subsystem](https://lwn.net/Articles/468759/) |

[100]: https://github.com/tacinight
[101]: https://github.com/linuxkoala
[102]: https://github.com/unicornx

## 参与流程

本活动欢迎广大爱好 Linux 的朋友一起参与，为保证活动的有序和质量，特制订如下流程：

- Step 1: 加入翻译团队

  [unicornx][102] 为该项目的发起人，有意向参与的朋友请先加他微信（polardotw），然后再申请加入微信群 "LWN 翻译团队"，方便沟通交流。

- Step 2: Fork 主仓库

  我们的工作基于 Github 进行，请首先注册 [github](https://github.com) 帐号，然后 [Fork TinyLab.org](https://github.com/tinyclub/tinylab.org#fork-destination-box) .

- Step 3: 下载并配置仓库

  克隆 Fork 后的代码仓库到本地并添加主仓库地址为 upstream，假设你的帐号是 `jack`

		$ git clone https://github.com/jack/tinylab.org.git
		$ git remote add upstream https://github.com/tinyclub/tinylab.org.git

- Step 4: 创建开发分支

  创建开发分支进行翻译：

		$ git checkout master
		$ git checkout -b lwn-<XXXXXX>

  对开发分支的要求如下：

  - 分支基于 master 创建，一篇翻译文章一个开发分支，对应一次 `pull request` 和 `merge`。i

  - 开发分支的命名规则遵循格式 `lwn-<XXXXXX>`，其中 `XXXXXX` 是文章在 [LWN.net](https://lwn.net/) 上的编号。例子：`lwn-222860`。

    - 每次提交至少包含两个文件的修改，一篇是新增的译文，一篇是对主索引的修改。

    - 对于新增的译文，文件放在 `_posts` 目录下。

      - 文件的命名格式如下：`YYYY-MM-DD-HH-MM-SS-lwn-XXXXXX-<article title>.md`，其中 `article title` 是原文的标题，中间的空格用 `-` 代替，具体例子参考 `_posts/2017-10-10-06-04-32-lwn-448502-platform-devices-and-device-trees.md` 。可以用 `tools/post` 创建模板文件。

      - 译文的内容要求，也请直接参考 `_posts` 目录下的例子，LWN 的译文采取中英文联排格式，方便阅读者对比，毕竟译文再好也比不过原文的魅力，另外也方便读者随时审阅。另外注意如果原文中有链接，并且该链接所指向的文章我们已经翻译的，请在译文中修改相应链接指向我们已经翻译的文章，具体例子可以参考`_posts/2017-10-10-06-04-32-lwn-448502-platform-devices-and-device-trees.md` 中的 `[本系列文章的上篇](/lwn-448499-platform-device-api)`部分。

  - 新增译文后需要修改主索引文件 `_posts/2017-10-23-22-55-32-lwn-kernel-index.md`，具体索引的格式直接参考 [Kernel index](https://lwn.net/Kernel/Index/)，如果是新增的章节则增加章节后再添加文章链接，如果所属章节已经存在则直接添加文章链接。文章链接需要修改指向我们发布的链接。注意 [Kernel index](https://lwn.net/Kernel/Index/) 中同一篇文章可能划归多个章节分类下，我们也同样遵循该原则。

- Step 5: 本地翻译与修改

  在开发分支上工作 ( 假设你的开发分支为 lwn-123456 )：

		$ git checkout lwn-123456

  修改 ......

		$ git add .
		$ git commit -s -m "commit title"

  **注意：我们要求在每次 commit 的时候务必添加注释和说明**

- Step 6: 提交到自己仓库

  准备提交，注意提交前务必和 tinylab 的 upstream 保持同步，具体操作如下( 假设本地开发分支为 lwn-123456 )：

		$ git fetch --all
		$ git rebase --onto upstream/master --root
		$ git push origin lwn-123456

  如果 merge 过程中有冲突则自行解决后继续，解决冲突后记得继续执行 `git rebase --continue` 确保所有变更都已合入。

- Step 7: 发起 `pull request`

  进入自己的 github 仓库页面，找到标签 `pull request`，点击右侧的 `New pull request` 按钮创建一笔 PR，可以直接指向远程 master 分支。

  提交后会安排交叉审阅，审阅工作通过 github 在线完成。

  如果审阅过程中有修改请修改人员注意每次修改后再提请审阅时和 upstream 时刻保持同步。

- Step 8: 管理员 `Merge pull request`

  如果文章无误，管理员就会直接把提交合并到主线。

  Congratulations! 至此您的文章将在 [泰晓科技](http://www.tinylab.org/) 上发布。
