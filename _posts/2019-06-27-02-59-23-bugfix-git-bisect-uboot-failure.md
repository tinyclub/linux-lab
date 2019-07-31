---
layout: post
author: 'Wu Zhangjin'
title: "bugfix: 使用 git bisect 自动定位 uboot 启动失败问题"
draft: false
album: "Debugging+Tracing"
license: "cc-by-nc-nd-4.0"
permalink: /bugfix-git-bisect-uboot-failure/
description: "git bisect 可以用于快速定位引入衰退的变更"
category:
  - Linux Lab
  - 调试技巧
tags:
  - git bisect
  - uboot
---

> By Falcon of [TinyLab.org][1]
> Jun 11, 2019

在重构 Linux Lab 的过程中，某一天发现两款支持 uboot 的板子都无法正常启动了。

这是一个明显的衰退问题，就是说历史上 ok，后来出故障了。

这类问题，当然也可以从正面分析，只是蛮多时候，这类问题有专门的应对方式，那就是直接去查找看看到底是哪一笔变更引起的。

如果变更少，一笔一笔 checkout、配置、编译、运行、启动是可以的，如果变更一多，这种方式就很低效和愚蠢。通常会用一些提高搜寻效率的方式，比如说二分法。

git 版本管理系统本身提供了二分法的工具：`git bisect`。这个工具有三个参数：

1. bad commit 号，某个已知的不能正常工作了的变更号
2. good commit 号，某个已知的能正常工作的历史变更点
3. 判断 bad/good 的规则，可以是人为判断，也可以是自动化脚本。

这里以 Uboot 启动失效为例。

1. bad commit: efa5cf
2. good commit: a61e84

`bad commit` 比较好确定，最新的几个版本都不能工作，随便指定其中一个即可。而 `good commit` 可以根据记忆往后找，也可以用 `git checkout HEAD~n` 这种方式大范围跳跃式的找，这里本身也可以人肉二分法提高效率。

之后就是找到一套规则，这个规则可以是人肉的 step-by-step，也可以是脚本化的规则。

对于 uboot 启动失败问题，在 Linux Lab 的强大测试功能下很容易撰写这样的判断规则，只要把 checkout、配置、编译、运行、启动等动作打包成一个脚本，并且对启动日志做判断即可，如果能正常打印内核日志，说明 uboot 可以正常启动，否则不正常。

这个规则实现为 [tools/uboot/boot-test.sh](https://github.com/tinyclub/linux-lab/blob/master/tools/uboot/boot-test.sh)，这个脚本的参数是开发板的名字，目前支持 uboot 的板子为 versatilepb 和 vexpress-a9，任选一个即可，因为两款板子的 uboot 都启动失败了。

到这里，获得了三个关键参数：

1. bad commit: efa5cf
2. good commit: a61e84
3. good/bad detect script: tools/uboot/boot-test.sh，参数为 versatilepb 或 vexpress-a9

接下来就可以执行 git bisect：

    $ cd /path/to/linux-lab
    $ cp tools/uboot/boot-test.sh ./

    $ git bisect start efa5cf a61e84
    $ git bisect run ./boot-test.sh versatilepb
    d1fccb583bc60c504d7531ffe6c6934ddf960cb4 is the first bad commit
    commit d1fccb583bc60c504d7531ffe6c6934ddf960cb4
    Author: Wu Zhangjin <wuzhangjin@gmail.com>
    Date:   Mon May 27 20:05:47 2019 -0700

        Makefile: fix up file existing check

        dynamic checking instead of static checking ...

        Makefile doesn't update the variable on targets in the 'dependencies'...

        Signed-off-by: Wu Zhangjin <wuzhangjin@gmail.com>

    :100644 100644 0796fabf9ad05c5db83035bca79cce9b37ff6185 13a2a0fd1f4855c83429e00991231befab261ddd M	Makefile

很快就找到了引入问题的第一个 commit。可以通过 `git bisect log` 回看执行过程：

    $ git bisect log
    # bad: [efa5cf2a8df0c23a30fa223993cca1a3093e44f1] README: document TEST_RD
    # good: [a61e84ac2cb67138418ecee176c389f4ec9c752e] Makefile: add missing ifneq
    git bisect start 'efa5cf' 'a61e84'
    # bad: [2df9185a37125d067ada6e535582e8904d6c5eb4] README: raspi3: update usage
    git bisect bad 2df9185a37125d067ada6e535582e8904d6c5eb4
    # good: [69d8ae4c76a05e86f69c31c3931e8560ca4ed62d] Makefile: fix up for internel kernel module support
    git bisect good 69d8ae4c76a05e86f69c31c3931e8560ca4ed62d
    # good: [7de514ba6918c2d18a9cc1b2d33ee7b7fe3d94d3] README: use simpler hello instead of ldt
    git bisect good 7de514ba6918c2d18a9cc1b2d33ee7b7fe3d94d3
    # bad: [47221e73cf63b97a2ca49511460b1b143e418dbe] Makefile: use olddefconfig for automation
    git bisect bad 47221e73cf63b97a2ca49511460b1b143e418dbe
    # bad: [b7e2b70d31ab8bfe1f1893827a38612e0fcefb2f] Makefile: disable default KP and QP
    git bisect bad b7e2b70d31ab8bfe1f1893827a38612e0fcefb2f
    # bad: [d1fccb583bc60c504d7531ffe6c6934ddf960cb4] Makefile: fix up file existing check
    git bisect bad d1fccb583bc60c504d7531ffe6c6934ddf960cb4
    # first bad commit: [d1fccb583bc60c504d7531ffe6c6934ddf960cb4] Makefile: fix up file existing check


执行完以后务必记得退出 bisect：

    $ git bisect reset

想完全自动化的话，可以用 [tools/git/bisect.sh](https://github.com/tinyclub/linux-lab/blob/master/tools/git/bisect.sh)：

    $ cp tools/git/bisect.sh ./
    $ ./bisect.sh efa5cf a61e84 ./boot-test.sh versatilepb

详细执行过程请参考下面录制的命令行视频：

<iframe src="http://showterm.io/6ef2e19278ed1fd183771" width="100%" height="600" marginheight="0" marginwidth="0" frameborder="0" scrolling="no" border="0" style="margin-top: 10px" allowfullscreen></iframe>

在实际产品研发中，判断规则的自动化是一个蛮有挑战性的工作，得要有比较好的测试基础设施，比如说自动刷机，自动上电开机，然后死机了还要有超时检测，并且要有硬件串口数据抓取和关键词匹配等。

如果想在实际产品中部署类似自动化体系，欢迎加笔者微信沟通交流，wechat: lzufalcon。

[1]: http://tinylab.org
