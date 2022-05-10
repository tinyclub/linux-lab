---
layout: post
author: 'Wu Zhangjin'
title: "RISC V Linux 内核兴趣小组活动简报（2）"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /riscv-linux-report-2/
description: "本文简单总结了过去 1 个月 RISC-V Linux 内核剖析第 2 阶段活动的进展。"
category:
  - 开源项目
  - Risc-V
  - 技术动态
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
> May 10, 2022

## 简介

为了支持国内的 RISC-V 技术生态建设，作为一个聚焦 Linux 内核近 10 年的原创技术社区，泰晓科技在 3 月初正式启动了 [RISC-V Linux 内核兴趣小组](/riscv-linux-analyse)，并于 3 周后发布了 [首个简报（1）](/riscv-linux-report-1)。刚好又过去了 1 个多月，为方便大家了解活动进展，本次发布第 2 期简报。

## 数据

咱们通过数据看看活动的情况。

|           | 4.9-5.9  | Total  
|-----------|----------|--------
| Commits   | 82       | 260    
| PR        |          | 51/71
| Articles  | 8/10     | 21/23
| Picks     | 7        | 44
| Authors   | 15       | 30
| Lives     | 3        | 6
| Wechat    |          | 116
| Microbench| 2        | 5

可以从上表看到整个活动非常活跃，累计已经有 30 位作者参与了协作仓库，一共输出了 21 篇原创技术分析文章，并有 6 位老师开展了精彩的线上技术交流。

社区网站、公众号、知乎专栏、B 站等渠道也在持续连载原创文章和线上技术交流的剪辑视频。

另外，由本次项目孵化的处理器指令级性能测试套件 microbench 已经添加了 5 大主流处理器架构支持并发布了首份跨架构的性能对比评估报告。

咱们是怎么统计的呢？

```
// Articles
$ ls articles/*.md | grep -v README.md | wc -l
21

// Commits
$ git log --oneline --root | wc -lgit log --oneline --root | wc -l
260

// Authors
$ git log --format="%aN <%aE>" --root | tr '[A-Z]' '[a-z]' | sort -u | wc -l
30

// Picks
$ grep @ plan/README.md  | wc -l
44

// Lives & Videos
$ sed -n "/已完成/,/会议记录/p" meeting/README.md  | grep "^-" | wc -l
6

// Supported Architectures of Microbench
$ ls test/microbench/test/ | wc -l
5
```

## 小结

过去 2 个月的活动期间，包括 6 位在线分享的老师、30 位协作仓库的 Authors 和 116 位协作微信群的同学们在内，大家踊跃分享和交流，已经理清了很多 RISC-V 架构的基础知识，并已经详尽分析了十数个主题。

1. 基础知识（RISC-V Spec 在线分享、RISC-V 指令编码在线分享、RISC-V 汇编在线分享、特权模式文章分享）
2. 引导（RustSBI 在线分享; OpenSBI/UEFI 文章分享）
3. 启动（启动流程 在线分享 & Linux Porting 系列译文；RISC-V Linux Quickstart 文章分享）
4. 内存管理（Paging & MMU 文章&在线分享, Sparsemem 文章分享）
5. 原子操作（Atomics 文章&在线分享）
6. 时钟（Timers 文章分享）
7. 系统调用（Syscall 文章分享）
8. 调度（Context Switch 文章分享）
9. 调试与跟踪（StackTrace、Earlycon、Kfence 以及 Tracepoint&Jump Label系列文章分享）
10. Benchmark（原创 microbench 指令级性能测试套件以及跨架构性能对比报告）
11. 发行版（RISC-V发行版 文章分享）
12. 实验（Linux Lab已经支持 RISC-V Qemu v6.0.0、RISC-V Linux v5.17、RVOS 课程、RISC-V 汇编案例）
13. 硬件（D1上手 文章分享）

在线分享一般会在第二天就在知乎、B站、Cctalk 等 3 大渠道同时发布剪辑视频回放，原创文章是每周二在公众号和知乎专栏等渠道连载 1 篇，敬请关注、收藏、在看、转发。

## 参与

还等什么？快来参加吧~~

最简参与方式：编辑下述协作仓库的 `plan/README.md`，选中一个感兴趣的 Topic，追加自己的 @id，然后提交 PR 即可。建议趁热打铁在两周内提交分析成果。

详情看过来：<https://gitee.com/tinylab/riscv-linux>

[1]: https://tinylab.org
