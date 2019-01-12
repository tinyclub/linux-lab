---
title: LWN 中文翻译文章汇总
tagline: LWN.net 中文翻译计划
author: Wang Chen
layout: page
album: 'LWN 中文翻译'
group: translation
update: 2019-1-12
permalink: /lwn-list-time/
description: LWN 中文翻译的文章汇总。
categories:
  - Linux 综合知识
tags:
  - lwn.net
  - 中文翻译
---

[返回 “LWN 中文翻译计划” 翻译文章列表汇总][2]

# 时间与定时器管理

```
     明日歌
        钱鹤滩（明）
  
明日复明日，明日何其多？
我生待明日，万事成蹉跎。
```

## 内核修改历史（时间篇）

| 内核版本 | 发布时间 | 该版本合入的和 time 相关的补丁以及与之有关的 LWN 文章 |
|---------|--------------|----------------|
|...|||
|2.6.13   |2005/08/29    |Build-time configurable clock interrupt frequency: Now HZ defaults to 250 in x86. [(LWN 145973)][15]|
|...|||
|2.6.16   |2006/03/20    |High resolution timers. [(LWN 152436)][11]、[(LWN 156325)][12]、[(LWN 167897)][13]|
|...|||
|2.6.18   |2006/09/20    |Generic core time subsystem. [(LWN 120850)][14]|
|...|||
|2.6.21   |2007/04/25    |Dynticks and Clockevents. [(LWN 138969)][16]、[(LWN 149877)][17]|
|...|||


## 翻译文章列表

以下列表包含本 LWN 翻译计划中所有已经 **被认领** 的文章、及其翻译状态等其他信息（翻译状态包括"翻译中"，"校对中"，"已发表"）。

| 状态   | 译作者    | 校对             | 文章  |原文发表时间|
|--------|-----------|------------------|-------|------------|
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

[返回 “LWN 中文翻译计划” 翻译文章列表汇总][2]

[1]: http://tinylab.org
[2]: /lwn-list
[11]: /lwn-152436-new-approach-to-ktimers
[12]: /lwn-156325-on-merging-of-ktimers
[13]: /lwn-167897-hrtimer-api
[14]: /lwn-120850-a-new-core-time-subsystem
[15]: /lwn-145973-how-fast-should-hz-be
[16]: /lwn-138969-dynamic-tick-patch
[17]: /lwn-149877-state-of-dynamic-tick-patch
