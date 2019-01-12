---
title: LWN 中文翻译文章汇总
tagline: LWN.net 中文翻译计划
author: Wang Chen
layout: page
album: 'LWN 中文翻译'
group: translation
update: 2019-1-12
permalink: /lwn-list-mm/
description: LWN 中文翻译的文章汇总。
categories:
  - Linux 综合知识
tags:
  - lwn.net
  - 中文翻译
---

[返回 “LWN 中文翻译计划” 翻译文章列表汇总][2]

以下列表包含本 LWN 翻译计划中所有已经 **被认领** 的文章、及其翻译状态等其他信息（翻译状态包括"翻译中"，"校对中"，"已发表"）。

## 内存管理

### During early boot

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|------------|
| 已发表 | unicornx   | lzufalcon   |[The NO_BOOTMEM patches](/lwn-382559-no-bootmem-patches) |April 7, 2010|
| 已发表 | unicornx   | lzufalcon   |[Moving x86 to LMB](/lwn-387083-moving-x86-to-lmb) |May 11, 2010|
| 已发表 | unicornx   | lzufalcon   |[A quick history of early-boot memory allocators](/lwn-761215-quick-history-early-boot-mem-allocators) |July 30, 2018|

### GFP flags

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|------------|
| 已发表 | unicornx   | llseek      |[Introducing gfp_t](/lwn-155344) |Oct. 11, 2005|

### Large allocations

#### Anti-fragmentation

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|------------|
| 已发表 | unicornx   | Tacinight   |[Kswapd and high-order allocations](/lwn-101230)|September 8, 2004|
| 已发表 | Tacinight  | Bennnyzhao  |[Active memory defragmentation](/lwn-105021)|October 5, 2004|
| 已发表 | unicornx   | ShaolinDeng |[Yet another approach to memory fragmentation](/lwn-121618)|February 1, 2005|
| 已发表 | unicornx   | simowce     |[Fragmentation avoidance](/lwn-158211)|November 2, 2005|
| 已发表 | simowce    | unicornx    |[More on fragmentation avoidance](/lwn-159110)|November 8, 2005|
| 已发表 | unicornx   | lljgithub   |[Avoiding - and fixing - memory fragmentation](/lwn-211505)|November 28, 2006|

#### Memory compaction

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|------------|
| 已发表 | unicornx   | llseek      |[Memory compaction](/lwn-368869) |January 6, 2010|
| 已发表 | unicornx   | hal0936     |[Memory compaction issues](/lwn-591998) |March 26, 2014|
| 已发表 | unicornx   | fan-xin     |[CMA and compaction](/lwn-684611) |April 23, 2016|
| 已发表 | unicornx   | w-simon     |[Proactive compaction](/lwn-717656) |March 21, 2017|

### Page cache

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|------------|
| 校对中 | unicornx   | llseek      |[The future of the page cache](/lwn-712467/) |January 25, 2017|


#### Writeback

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|------------|
| 已发表 | unicornx   | llseek      |[Flushing out pdflush](/lwn-326552) |April 1, 2009|
| 已发表 | unicornx   | ShaolinDeng |[When writeback goes wrong](/lwn-384093/) |April 20, 2010|
| 已发表 | unicornx   | hal0936     |[Fixing writeback from direct reclaim](/lwn-396561) |July 20, 2010|
| 已发表 | unicornx   | lyzhsf      |[Dynamic writeback throttling](/lwn-405076/) |September 15, 2010|
| 已发表 | unicornx   | Tacinight   |[No-I/O dirty throttling](/lwn-456904/) |August 31, 2011|
| 校对中 | unicornx   | simowce     |[Writeback and control groups](/lwn-648292/) |June 17, 2015|
| 校对中 | unicornx   | w-simon     |[Toward less-annoying background writeback](/lwn-682582/) |April 13, 2016|
| 校对中 | unicornx   | w-simon     |[Background writeback](/lwn-685894/) |May 4, 2016|

#### Readahead

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|------------|
| 校对中 | llseek     | unicornx    |[Adaptive file readahead](/lwn-155510) |October 12, 2005|
| 校对中 | unicornx   | llseek      |[On-demand readahead](/lwn-235164) |May 21, 2007|
| 校对中 | Tacinight  | unicornx    |[Improving readahead](/lwn-372384) |February 3, 2010|


### Page tables

| 状态   | 译作者     | 校对        | 文章  |原文发表时间|
|--------|------------|-------------|-------|------------|
| 已发表 | unicornx   | simowce & lljgithub |[Four-level page tables](/lwn-106177-four-level-pt) |October 12, 2004|
| 已发表 | unicornx   | wuhuo-org   |[Rethinking four-level page tables](/lwn-116810) |December 22, 2004|
| 已发表 | unicornx   | lljgithub   |[Four-level page tables merged](/lwn-117749-4-level-page-tables-merged) |January 5, 2005|
| 已发表 | unicornx   | simowce     |[Five-level page tables](/lwn-717293-5-level-pt) |March 15, 2017|
| 已发表 | unicornx   | fan-xin     |[Reworking page-table traversal](/lwn-753267-reworking-pt-traversal) |May 4, 2018|

### Object-based reverse mapping

| 状态   | 译作者     | 校对      | 文章  |原文发表时间|
|--------|------------|-----------|-------|------------|
| 已发表 | unicornx   | w-simon   |[The object-based reverse-mapping VM](/lwn-23732-object-based-reverse-mapping-vm) |February. 25, 2003|
| 已发表 | unicornx   | w-simon   |[Virtual Memory II: the return of objrmap](/lwn-75198) |March 10, 2004|
| 已发表 | unicornx   | w-simon   |[The case of the overly anonymous anon_vma](/lwn-383162-case-of-overly-anonymous-anon_vma) |April 13, 2010|

### page allocator

| 状态   | 译作者     | 校对      | 文章  |原文发表时间|
|--------|------------|-----------|-------|------------|
| 已发表 | unicornx   | lyzhsf    |[Speeding up the page allocator](/lwn-320556/) |June. 3, 2009|

### struct page

| 状态   | 译作者     | 校对      | 文章  |原文发表时间|
|--------|------------|-----------|-------|------------|
| 已发表 | unicornx   | Bennyzhao |[How many page flags do we really have?](/lwn-335768/) |June. 3, 2009|
| 已发表 | unicornx   | w-simon |[Cramming more into struct page](/lwn-565097/) |Aug. 28, 2013|

### User-space layout

| 状态   | 译作者     | 校对      | 文章  |原文发表时间|
|--------|------------|-----------|-------|------------|
| 已发表 | unicornx   | llseek    |[Reorganizing the address space](/lwn-91829-reorg-addr-space) |June 30, 2004|
| 已发表 | unicornx   | hal0936   |[Address space randomization in 2.6](/lwn-121845) |Feb. 2, 2005|

## 赞助我们

为了更好地推进这个翻译项目，期待不能亲自参与的同学能够赞助我们，相关费用将用于设立项目微奖激励更多同学参与翻译和校订。

赞助方式有两种，一种是直接扫描下面的二维码，另外一种是通过 [泰晓服务中心](https://weidian.com/item.html?itemID=2208672946) 进行。

更多高质量的 LWN 翻译文章需要您的支持！谢谢。

[返回 “LWN 中文翻译计划” 翻译文章列表汇总][2]

[1]: http://tinylab.org
[2]: /lwn-list


