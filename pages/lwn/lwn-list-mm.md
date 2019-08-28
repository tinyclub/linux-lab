---
title: LWN 中文翻译文章汇总
tagline: LWN.net 中文翻译计划
author: Wang Chen
layout: page
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

## 内存管理

### During early boot

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-382559">The NO_BOOTMEM patches</a></td>
		<td>April 7, 2010</td>
  </tr>
  <tr>
		<td><a href="/lwn-387083">Moving x86 to LMB</a></td>
		<td>May 11, 2010</td>
  </tr>
  <tr>
		<td><a href="/lwn-761215">A quick history of early-boot memory allocators</a></td>
		<td>July 30, 2018</td>
	</tr>
</table>

### GFP(Get Free Pages)

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-155344">Introducing gfp_t</a></td>
		<td>Oct. 11, 2005</td>
  </tr>
	<tr>
		<td><a href="/lwn-320556/">Speeding up the page allocator</a></td>
		<td>June. 3, 2009</td>
  </tr>
</table>


### Huge pages

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-359158">Transparent hugepages</a></td>
		<td>October 28, 2009</td>
  </tr>
	<tr>
		<td><a href="/lwn-423584">Transparent huge pages in 2.6.38</a></td>
		<td>January 19, 2011</td>
  </tr>
	<tr>
		<td><a href="/lwn-517465">Adding a huge zero page</a></td>
		<td>September 26, 2012</td>
  </tr>
</table>


### Anti-fragmentation (Large allocations)


<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-101230">Kswapd and high-order allocations</a></td>
		<td>September 8, 2004</td>
  </tr>
	<tr>
		<td><a href="/lwn-105021">Active memory defragmentation</a></td>
		<td>October 5, 2004</td>
  </tr>
	<tr>
		<td><a href="/lwn-121618">Yet another approach to memory fragmentation</a></td>
		<td>February 1, 2005</td>
  </tr>
	<tr>
		<td><a href="/lwn-158211">Fragmentation avoidance</a></td>
		<td>November 2, 2005</td>
  </tr>
	<tr>
		<td><a href="/lwn-159110">More on fragmentation avoidance</a></td>
		<td>November 8, 2005</td>
  </tr>
	<tr>
		<td><a href="/lwn-211505">Avoiding - and fixing - memory fragmentation</a></td>
		<td>November 28, 2006</td>
  </tr>
	<tr>
		<td><a href="/lwn-368869">Memory compaction</a></td>
		<td>January 6, 2010</td>
  </tr>
	<tr>
		<td><a href="/lwn-591998">Memory compaction issues</a></td>
		<td>March 26, 2014</td>
  </tr>
	<tr>
		<td><a href="/lwn-684611">CMA and compaction</a></td>
		<td>April 23, 2016</td>
  </tr>
	<tr>
		<td><a href="/lwn-717656">Proactive compaction</a></td>
		<td>March 21, 2017</td>
  </tr>
</table>

### Object-based reverse mapping

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-23732">The object-based reverse-mapping VM</a></td>
		<td>February. 25, 2003</td>
  </tr>
	<tr>
		<td><a href="/lwn-75198">Virtual Memory II: the return of objrmap</a></td>
		<td>March 10, 2004</td>
  </tr>
	<tr>
		<td><a href="/lwn-383162">The case of the overly anonymous anon_vma</a></td>
		<td>April 13, 2010</td>
  </tr>
</table>

### Out-of-memory handling

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-391222">Another OOM killer rewrite</a></td>
		<td>June 7, 2010</td>
  </tr>
	<tr>
		<td><a href="/lwn-562211">Reliable out-of-memory handling</a></td>
		<td>August 6, 2013</td>
  </tr>
	<tr>
		<td><a href="/lwn-668126">Toward more predictable and reliable out-of-memory handling</a></td>
		<td>December 16, 2015</td>
  </tr>
</table>

### Page cache

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-712467/">The future of the page cache</a></td>
		<td>January 25, 2017</td>
  </tr>
</table>

### Page replacement algorithms (Page replacement)

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-226756/">Toward improved page replacement</a></td>
		<td>March 20, 2007</td>
  </tr>
	<tr>
		<td><a href="/lwn-257541/">Page replacement for huge memory systems</a></td>
		<td>November 7, 2007</td>
  </tr>
	<tr>
		<td><a href="/lwn-286472/">The state of the pageout scalability patches</a></td>
		<td>June 17, 2008</td>
  </tr>
	<tr>
		<td><a href="/lwn-333742/">Being nicer to executable pages</a></td>
		<td>May 19, 2009</td>
  </tr>
	<tr>
		<td><a href="/lwn-495543/">Better active/inactive list balancing</a></td>
		<td>May 2, 2012</td>
  </tr>
</table>

### page tables

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-106177">Four-level page tables</a></td>
		<td>October 12, 2004</td>
  </tr>
	<tr>
		<td><a href="/lwn-116810">Rethinking four-level page tables</a></td>
		<td>December 22, 2004</td>
  </tr>
	<tr>
		<td><a href="/lwn-117749">Four-level page tables merged</a></td>
		<td>January 5, 2005</td>
  </tr>
	<tr>
		<td><a href="/lwn-717293">Five-level page tables</a></td>
		<td>March 15, 2017</td>
  </tr>
	<tr>
		<td><a href="/lwn-753267">Reworking page-table traversal</a></td>
		<td>May 4, 2018</td>
  </tr>
</table>

### Readahead

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-155510">Adaptive file readahead</a></td>
		<td>October 12, 2005</td>
  </tr>
	<tr>
		<td><a href="/lwn-235164">On-demand readahead</a></td>
		<td>May 21, 2007</td>
  </tr>
	<tr>
		<td><a href="/lwn-372384">Improving readahead</a></td>
		<td>February 3, 2010</td>
  </tr>
</table>

### Shrinkers

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-550463/">Smarter shrinkers</a></td>
		<td>May 14, 2013</td>
  </tr>
</table>

### struct page

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-335768/">How many page flags do we really have?</a></td>
		<td>June. 3, 2009</td>
  </tr>
	<tr>
		<td><a href="/lwn-565097/">Cramming more into struct page</a></td>
		<td>Aug. 28, 2013</td>
  </tr>
</table>

### Swapping

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-83588/">2.6 swapping behavior</a></td>
		<td>May 5, 2004</td>
  </tr>
	<tr>
		<td><a href="/lwn-334649/">Compcache: in-memory compressed swapping</a></td>
		<td>May 26, 2009</td>
  </tr>
	<tr>
		<td><a href="/lwn-439298/">Safely swapping over the net</a></td>
		<td>April 19, 2011</td>
  </tr>
	<tr>
		<td><a href="/lwn-704478/">Making swapping scalable</a></td>
		<td>October 26, 2016</td>
  </tr>
	<tr>
		<td><a href="/lwn-717707/">The next steps for swap</a></td>
		<td>March 22, 2017</td>
  </tr>
	<tr>
		<td><a href="/lwn-758677/">The final step for huge-page swapping</a></td>
		<td>July 2, 2018</td>
  </tr>
</table>

### User-space layout

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-91829">Reorganizing the address space</a></td>
		<td>June 30, 2004</td>
  </tr>
	<tr>
		<td><a href="/lwn-121845">Address space randomization in 2.6</a></td>
		<td>Feb. 2, 2005</td>
  </tr>
</table>

### Writeback

<table width="100%" height="100%" border="1" cellpadding="0" cellspacing="0">
	<tr>
		<th width="50%" style="text-align: center;">文章</th>
		<th width="50%" style="text-align: center;">原文发表时间</th>
	</tr>
	<tr>
		<td><a href="/lwn-326552">Flushing out pdflush</a></td>
		<td>April 1, 2009</td>
  </tr>
	<tr>
		<td><a href="/lwn-384093/">When writeback goes wrong</a></td>
		<td>April 20, 2010</td>
  </tr>
	<tr>
		<td><a href="/lwn-396561">Fixing writeback from direct reclaim</a></td>
		<td>July 20, 2010</td>
  </tr>
	<tr>
		<td><a href="/lwn-405076/">Dynamic writeback throttling</a></td>
		<td>September 15, 2010</td>
  </tr>
	<tr>
		<td><a href="/lwn-456904/">No-I/O dirty throttling</a></td>
		<td>August 31, 2011</td>
  </tr>
	<tr>
		<td><a href="/lwn-648292/">Writeback and control groups</a></td>
		<td>June 17, 2015</td>
  </tr>
	<tr>
		<td><a href="/lwn-682582/">Toward less-annoying background writeback</a></td>
		<td>April 13, 2016</td>
  </tr>
	<tr>
		<td><a href="/lwn-685894/">Background writeback</a></td>
		<td>May 4, 2016</td>
  </tr>
</table>

## 赞助我们

为了更好地推进这个翻译项目，期待不能亲自参与的同学能够赞助我们，相关费用将用于设立项目微奖激励更多同学参与翻译和校订。

赞助方式有两种，一种是直接扫描下面的二维码，另外一种是通过 [泰晓服务中心](https://weidian.com/item.html?itemID=2208672946) 进行。

更多高质量的 LWN 翻译文章需要您的支持！谢谢。

[返回 “LWN 中文翻译计划” 翻译文章列表汇总][2]

[1]: http://tinylab.org
[2]: /lwn#翻译成果


