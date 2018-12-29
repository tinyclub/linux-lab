---
title: LWN 中文翻译文章汇总
tagline: LWN.net 中文翻译计划
author: Wang Chen
layout: page
album: 'LWN 中文翻译'
group: translation
update: 2018-2-1
permalink: /lwn-list/
description: LWN 中文翻译的文章汇总。
categories:
  - Linux 综合知识
tags:
  - lwn.net
  - 中文翻译
---

[返回 “LWN 中文翻译计划” 主页][3]

我们鼓励大家根据自己的兴趣选择相关文章进行翻译，有志于参加本翻译计划的朋友可以从 [LWN Kernel index][2] 中挑选您感兴趣的文章，只要确保不和 本文 "翻译文章列表汇总" 中已经被其他人认领的文章冲突即可。

[LWN Kernel index][2] 中对所有文章按照 feature 做了分类，这里按照分类对近些年来的文章做了一个粗略的[统计分析](/lwn-kernel-articles-analysis)，供大家选择时参考。

## 翻译文章列表汇总

以下列表包含本 LWN 翻译计划中所有已经 **被认领** 的文章、及其翻译状态等其他信息（翻译状态包括"翻译中"，"校对中"，"已发表"）。

**计划将随时保持更新，欢迎大家关注**：

### Debugging

| 状态   | 译作者  | 校对      | 文章  |原文发表时间|
|--------|---------|-----------|-------|
| 已发表 | darmac  | unicornx  |[Bringing kgdb into 2.6](/lwn-70465-bringing-kgdb-into-2.6) |February 10, 2004|

### Development tools

| 状态   | 译作者    | 校对      | 文章  |原文发表时间|
|--------|-----------|-----------|-------|
| 已发表 | unicornx  | lzufalcon |[Device resource management](/lwn-215996-device-resource-management)|January 2, 2007|

### Device drivers

| 状态   | 译作者      | 校对                 | 文章  |原文发表时间|
|--------|-------------|----------------------|-------|
| 已发表 | unicornx    | Tacinight, lzufalcon |[The pin control subsystem](/lwn-468759-pincontrol-subsystem)|November 22, 2011|
| 已发表 | unicornx    | lzufalcon            |[The platform device API](/lwn-448499-platform-device-api)|June 21, 2011|
| 已发表 | unicornx    | maxiao1993           |[(Partially) graduating IIO](/lwn-465358-graduating-iio) |November 2, 2011|

### Device tree

| 状态   | 译作者     | 校对      | 文章  |原文发表时间|
|--------|------------|-----------|-------|
| 已发表 | unicornx   | WH2136    |[KS2009: Generic device trees](/lwn-357487-generic-device-trees) |October 19, 2009|
| 已发表 | unicornx   | lzufalcon |[Platform devices and device trees](/lwn-448502-platform-devices-and-device-trees)|June 21, 2011|
| 已发表 | unicornx   | w-simon   |[Device tree overlays](/lwn-616859-device-tree-overlays) |October 22, 2014|

### General-purpose I/O

| 状态   | 译作者    | 校对             | 文章  |原文发表时间|
|--------|-----------|------------------|-------|
| 已发表 | unicornx  | cee1, norlanjame | [GPIO in the kernel: an introduction](/lwn-532714-gpio-in-the-kernel)|January 16, 2013|
| 已发表 | unicornx  | lljgithub        | [GPIO in the kernel: future directions](/lwn-533632-gpio-in-the-kernel-future-directions) |January 23, 2013|

### Filesystems

| 状态   | 译作者    | 校对            | 文章  |原文发表时间|
|--------|-----------|-----------------|-------|
| 已发表 | Tacinight | unicornx        |[The Btrfs filesystem: An introduction](/lwn-576276-the-btrfs-filesystem-an-introduction)|December 11, 2013|
| 已发表 | Tacinight | guojian-at-wowo |[Btrfs: Getting started](/lwn-577218-btrfs-getting-started/) |December 17, 2013|
| 已发表 | Tacinight | fan-xin         |[Btrfs: Working with multiple devices](/lwn-577961-btrfs-working-with-multiple-devices) |December 30, 2013|
| 已发表 | Tacinight | cee1            |[Filesystem management interfaces](/lwn-718803-filesystem-management-interfaces) |April 5, 2017|

### Interrupts

| 状态   | 译作者    | 校对            | 文章  |原文发表时间|
|--------|-----------|-----------------|-------|
| 已发表 | unicornx  | guojian-at-wowo |[A new generic IRQ layer](/lwn-184750-generic-irq-layer) |May 23, 2006|


### Memory management

#### During early boot

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|
| 已发表 | unicornx   | lzufalcon   |[The NO_BOOTMEM patches](/lwn-382559-no-bootmem-patches) |April 7, 2010|
| 已发表 | unicornx   | lzufalcon   |[Moving x86 to LMB](/lwn-387083-moving-x86-to-lmb) |May 11, 2010|
| 已发表 | unicornx   | lzufalcon   |[A quick history of early-boot memory allocators](/lwn-761215-quick-history-early-boot-mem-allocators) |July 30, 2018|

#### GFP flags

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|
| 已发表 | unicornx   | llseek      |[Introducing gfp_t](/lwn-155344) |Oct. 11, 2005|

#### Large allocations

##### Anti-fragmentation

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|
| 已发表 | unicornx   | Tacinight   |[Kswapd and high-order allocations](/lwn-101230)|September 8, 2004|
| 已发表 | Tacinight  | Bennnyzhao  |[Active memory defragmentation](/lwn-105021)|October 5, 2004|
| 已发表 | unicornx   | ShaolinDeng |[Yet another approach to memory fragmentation](/lwn-121618)|February 1, 2005|
| 已发表 | unicornx   | simowce     |[Fragmentation avoidance](/lwn-158211)|November 2, 2005|
| 已发表 | simowce    | unicornx    |[More on fragmentation avoidance](/lwn-159110)|November 8, 2005|
| 已发表 | unicornx   | lljgithub   |[Avoiding - and fixing - memory fragmentation](/lwn-211505)|November 28, 2006|

##### Memory compaction

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|
| 已发表 | unicornx   | llseek      |[Memory compaction](/lwn-368869) |January 6, 2010|
| 已发表 | unicornx   | hal0936     |[Memory compaction issues](/lwn-591998) |March 26, 2014|
| 已发表 | unicornx   | fan-xin     |[CMA and compaction](/lwn-684611) |April 23, 2016|
| 已发表 | unicornx   | w-simon     |[Proactive compaction](/lwn-717656) |March 21, 2017|

#### Page cache

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|
| 校对中 | unicornx   | llseek      |[The future of the page cache](/lwn-712467/) |January 25, 2017|


##### Writeback

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|
| 已发表 | unicornx   | llseek      |[Flushing out pdflush](/lwn-326552) |April 1, 2009|
| 已发表 | unicornx   | ShaolinDeng |[When writeback goes wrong](/lwn-384093/) |April 20, 2010|
| 已发表 | unicornx   | hal0936     |[Fixing writeback from direct reclaim](/lwn-396561) |July 20, 2010|
| 已发表 | unicornx   | lyzhsf      |[Dynamic writeback throttling](/lwn-405076/) |September 15, 2010|
| 已发表 | unicornx   | Tacinight   |[No-I/O dirty throttling](/lwn-456904/) |August 31, 2011|
| 校对中 | unicornx   | simowce     |[Writeback and control groups](/lwn-648292/) |June 17, 2015|
| 校对中 | unicornx   | w-simon     |[Toward less-annoying background writeback](/lwn-682582/) |April 13, 2016|
| 校对中 | unicornx   | w-simon     |[Background writeback](/lwn-685894/) |May 4, 2016|

##### Readahead

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|
| 校对中 | llseek     | unicornx    |[Adaptive file readahead](/lwn-155510) |October 12, 2005|
| 校对中 | unicornx   | llseek      |[On-demand readahead](/lwn-235164) |May 21, 2007|
| 校对中 | Tacinight  | unicornx    |[Improving readahead](/lwn-372384) |February 3, 2010|


#### Page tables

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|
| 已发表 | unicornx   | simowce & lljgithub |[Four-level page tables](/lwn-106177-four-level-pt) |October 12, 2004|
| 已发表 | unicornx   | wuhuo-org   |[Rethinking four-level page tables](/lwn-116810) |December 22, 2004|
| 已发表 | unicornx   | lljgithub   |[Four-level page tables merged](/lwn-117749-4-level-page-tables-merged) |January 5, 2005|
| 已发表 | unicornx   | simowce     |[Five-level page tables](/lwn-717293-5-level-pt) |March 15, 2017|
| 已发表 | unicornx   | fan-xin     |[Reworking page-table traversal](/lwn-753267-reworking-pt-traversal) |May 4, 2018|

#### Object-based reverse mapping

| 状态   | 译作者     | 校对      | 文章  |原文发表时间|
|--------|------------|-----------|-------|
| 已发表 | unicornx   | w-simon   |[The object-based reverse-mapping VM](/lwn-23732-object-based-reverse-mapping-vm) |February. 25, 2003|
| 已发表 | unicornx   | w-simon   |[Virtual Memory II: the return of objrmap](/lwn-75198) |March 10, 2004|
| 已发表 | unicornx   | w-simon   |[The case of the overly anonymous anon_vma](/lwn-383162-case-of-overly-anonymous-anon_vma) |April 13, 2010|

#### page allocator

| 状态   | 译作者     | 校对      | 文章  |原文发表时间|
|--------|------------|-----------|-------|
| 已发表 | unicornx   | lyzhsf    |[Speeding up the page allocator](/lwn-320556/) |June. 3, 2009|

#### struct page

| 状态   | 译作者     | 校对      | 文章  |原文发表时间|
|--------|------------|-----------|-------|
| 已发表 | unicornx   | Bennyzhao |[How many page flags do we really have?](/lwn-335768/) |June. 3, 2009|
| 已发表 | unicornx   | w-simon |[Cramming more into struct page](/lwn-565097/) |Aug. 28, 2013|

#### User-space layout

| 状态   | 译作者     | 校对      | 文章  |原文发表时间|
|--------|------------|-----------|-------|
| 已发表 | unicornx   | llseek    |[Reorganizing the address space](/lwn-91829-reorg-addr-space) |June 30, 2004|
| 已发表 | unicornx   | hal0936   |[Address space randomization in 2.6](/lwn-121845) |Feb. 2, 2005|

### Namespaces

| 状态   | 译作者    | 校对      | 文章  |原文发表时间|
|--------|-----------|-----------|-------|
| 已发表 | unicornx  | w-simon   |[Namespaces in operation, part 1: namespaces overview](/lwn-531114-namespaces-in-op-part1) |January 4, 2013|
| 已发表 | unicornx  | w-simon   |[Namespaces in operation, part 2: the namespaces API](/lwn-531381-namespaces-in-op-part2) |January 8, 2013|
| 已发表 | unicornx  | w-simon   |[Namespaces in operation, part 3: PID namespaces](/lwn-531419-namespaces-in-op-part3) |January 16, 2013|
| 已发表 | unicornx  | w-simon   |[Namespaces in operation, part 4: more on PID namespaces](/lwn-532748-namespaces-in-op-part4) |January 23, 2013|


### Resources

| 状态   | 译作者    | 校对      | 文章  |原文发表时间|
|--------|-----------|-----------|-------|
| 已发表 | unicornx  | lzufalcon |[The managed resource API](/lwn-222860-the-managed-resource-api)|February 20, 2007|

### Scheduler

| 状态   | 译作者      | 校对      | 文章  |原文发表时间|
|--------|-------------|-----------|-------|
| 已发表 | linuxkoala  | unicornx  |[CFS group scheduling](/lwn-240474-cfs-group-scheduling)|July 2, 2007|

### Timers

| 状态   | 译作者    | 校对             | 文章  |原文发表时间|
|--------|-----------|------------------|-------|
| 已发表 | unicornx  | guojian-at-wowo  |[A new core time subsystem](/lwn-120850-a-new-core-time-subsystem) |January 26, 2005|
| 已发表 | unicornx  | guojian-at-wowo  |[The dynamic tick patch](/lwn-138969-dynamic-tick-patch) |June 7, 2005|
| 已发表 | unicornx  | guojian-at-wowo  |[How fast should HZ be?](/lwn-145973-how-fast-should-hz-be) |August 2, 2005|
| 已发表 | unicornx  | guojian-at-wowo  |[The state of the dynamic tick patch](/lwn-149877-state-of-dynamic-tick-patch) |August 31, 2005|
| 已发表 | unicornx  | guojian-at-wowo  |[A new approach to kernel timers](/lwn-152436-new-approach-to-ktimers) |September 20, 2005|
| 已发表 | unicornx  | guojian-at-wowo  |[On the merging of ktimers](/lwn-156325-on-merging-of-ktimers) |October 19, 2005|
| 已发表 | unicornx  | guojian-at-wowo  |[The high-resolution timer API](/lwn-167897-hrtimer-api) |January 16, 2006|
| 已发表 | unicornx  | guojian-at-wowo  |[Clockevents and dyntick](/lwn-223185-clockevents-and-dyntick) |February 21, 2007|
| 翻译中 | unicornx  |                  |[Deferrable timers](https://lwn.net/Articles/228143/) |March 28, 2007|
| 翻译中 | unicornx  |                  |[The new timerfd() API](https://lwn.net/Articles/251413/) |September 25, 2007|
| 翻译中 | unicornx  |                  |[High- (but not too high-) resolution timeouts](https://lwn.net/Articles/296578/) |September 2, 2008|
| 翻译中 | unicornx  |                  |[Timer slack](https://lwn.net/Articles/369549/) |January 12, 2010|
| 翻译中 | unicornx  |                  |[NoHZ tasks](https://lwn.net/Articles/420544/) |December 20, 2010|
| 已发表 | unicornx  | guojian-at-wowo  |[(Nearly) full tickless operation in 3.10](/lwn-549580-nearly-full-tickless-3.10) |May 8, 2013|
| 已发表 | unicornx  | guojian-at-wowo  |[Is the whole system idle?](/lwn-558284-is-the-whole-system-idle) |July 10, 2013|
| 已发表 | unicornx  | w-simon          |[The tick broadcast framework](/lwn-574962-the-tick-broadcast-framework) |November 26, 2013|
| 翻译中 | unicornx  |                  |[Reinventing the timer wheel](https://lwn.net/Articles/646950/) |June 3, 2015|
| 翻译中 | unicornx  |                  |[Dropping the timer tick — for real this time](https://lwn.net/Articles/659490/) |October 7, 2015|
| 翻译中 | unicornx  |                  |[Improving the kernel timers API](https://lwn.net/Articles/735887/) |October 9, 2017|

## 赞助我们

为了更好地推进这个翻译项目，期待不能亲自参与的同学能够赞助我们，相关费用将用于设立项目微奖激励更多同学参与翻译和校订。

赞助方式有两种，一种是直接扫描下面的二维码，另外一种是通过 [泰晓服务中心](https://weidian.com/item.html?itemID=2208672946) 进行。

更多高质量的 LWN 翻译文章需要您的支持！谢谢。

[返回 “LWN 中文翻译计划” 主页][3]

[1]: http://tinylab.org
[2]: https://lwn.net/Kernel/Index/
[3]: /lwn
