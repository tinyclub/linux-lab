---
layout: post
author: 'Wu Zhangjin'
title: "RISC V Linux 内核兴趣小组活动简报（1）"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /riscv-linux-report-1/
description: "本文简单总结了过去三周 RISC-V Linux 内核剖析第 1 阶段活动的进展。"
category:
  - 开源项目
  - Risc-V
tags:
  - RISC-V
  - Linux 内核
  - 内核剖析
  - 兴趣小组
  - 技术直播
  - 知识星球
  - 测试框架
---

> By Falcon of [TinyLab.org][1]
> Mar 28, 2022

大家好，

咱们在 3 月初正式启动了 [RISC-V Linux 内核兴趣小组](https://tinylab.org/riscv-linux-analyse/)，并于上上周组织了 [第一次技术直播分享](https://zhuanlan.zhihu.com/p/482851953)。活动从筹备到现在接近 3 周，现在刚好是月底，咱们做个简单的报告。

首先，各项活动有条不紊地推进着：


* 创建 [协作仓库](https://gitee.com/tinylab/riscv-linux)，任务认领与输出 PR,Review,Merge, 97 笔。
* 成立 协作群组，已有 78+，来自 RISC-V 芯片与周边一线。联系方式：tinylab，做技术背景介绍并说明认领任务。
* 开展 [直播分享](https://gitee.com/tinylab/riscv-linux/tree/master/meeting)，每周六晚 8:30-9:30 直播交流与分享, 2 场。

另外，相关文章、视频、代码等成果正在陆续输出。

* 创建 [文章专辑](https://tinylab.org/riscv-linux)，汇总图文类分析成果，累计发布 10 篇。
* 开设 [视频合集](https://www.cctalk.com/m/group/90251209)，发布直播回放和演示视频，累计发布 6 个。
* 建立 [速记频道](https://t.zsxq.com/uB2vJyF)，速记学习材料和思考，向核心成员开放。
* 完善 [实验环境](https://tinylab.org/linux-lab-disk)，Linux Lab 已支持 RISC-V32/64 + Linux v5.17。
* 发布 [测试框架](https://gitee.com/tinylab/riscv-linux/tree/master/test/microbench)，基于开源框架开发了一套微指令性能测试框架。


为鼓励大家提交 PR，已经送出 4 本 Linux 图书。

接下来，在推进日常活动的基础上，咱们计划：

* 本周起将在该公众号陆续连载图文类分析成果，右上角关注哈
* 每周六晚协调组织1场技术直播，直播地址详见协作仓库 meetings/ 目录
* 协调成员关注RISC-V还未支持的内核新特性，支持做官方Upstream
* 准备更多图书等激励成员踊跃认领任务并提交PR，欢迎赞助Linux图书

最后，欢迎大家踊跃报名或者推荐给周边感兴趣的同学，Welcome~

任务列表一定有你感兴趣的哈，内容太多，请大家访问 [plan/README.md](https://link.zhihu.com/?target=https%3A//gitee.com/tinylab/riscv-linux/tree/master/plan) 哈。点击一下试试，觉得有兴趣就提交一个 PR，加上自己的 ID 就好。

正式提交 PR 前建议看看上面的 **视频合集** 链接，有详细介绍与讨论分享活动参与方式等事项。现在确实太忙不能参与的话，也可以点个在看收藏起来哈。

[1]: https://tinylab.org
