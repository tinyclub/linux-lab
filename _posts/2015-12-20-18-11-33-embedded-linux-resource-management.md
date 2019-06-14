---
layout: post
author: 'Wu Zhangjin'
title: "嵌入式 Linux 资源管理"
album: "嵌入式 Linux 知识库"
group: translation
permalink: /embedded-linux-resource-management/
description: "本文有各类关于内核资源管理框架的信息，这些信息对于嵌入式开发者而言可能会感兴趣。"
category:
  - 资源管理
tags:
  - Linux
  - CKRM
  - UBC
  - Cgroups
  - CPUSets 
---

> 书籍：[嵌入式 Linux 知识库](https://tinylab.gitbooks.io/elinux)
> 原文：[eLinux.org](http://eLinux.org/Resource_Management)
> 翻译：[@lzufalcon](https://github.com/lzufalcon)

## 开源项目

-   [CKRM, 基于类别的的内核资源管理（注：一个类别是一组 Linux 任务）](http://ckrm.sourceforge.net)（[ckrm-tech](https://lists.sourceforge.net/lists/listinfo/ckrm-tech) 邮件列表 和 [邮件存档](http://sourceforge.net/mailarchive/forum.php?forum=ckrm-tech)）
-   [UBC, OpenVZ User beancounters（OpenVZ 用户会计师）](http://wiki.openvz.org/Category:UBC)
-   [OpenSourceMID.org](http://www.opensourcemid.org)
    -   [Opensourcemid](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Hardware_Hacking/Opensourcemid/Opensourcemid.html "Opensourcemid")


## CKRM/RG

-   [内核峰会：基于类别的的内核资源管理](http://lwn.net/Articles/94573/) - LWN 上 CKRM 文章（来自 2004 年内核峰会）
-   [资源分组](http://lwn.net/Articles/181857/) - 再次出现时，CKRM 做了大力重构


## UBC/Beancounters

-   [最初版本的补丁](http://article.gmane.org/gmane.linux.kernel/437312) 和后续 Linux 内核邮件列表中的讨论
-   [资源会计师](http://lwn.net/Articles/197433/) - 文章来自 LWN


## 其他

-   [资源管理 - 基础设施的选择](http://lkml.org/lkml/2006/10/30/49) 也是来自内核邮件列表的讨论，尝试把重点放在使用简单的模型构建一个基础设施，在该设施之上可用于构建更可靠的实现。
-   [控制组（Cgroups）](https://www.kernel.org/doc/Documentation/cgroups/cgroups.txt) 提供一种聚合/分组任务集的机制，所有后来进入某个分组的子任务会有专门的行为（可配置）。
-   [CPU分组（CpuSets）](https://www.kernel.org/doc/Documentation/cgroups/cpusets.txt) 提供了一种机制，可以用于把一组 CPU 和内存节点指派给一组任务。

译注：上述 Cgroups 和 CpuSets 信息为译者添加，更多已经进入到内核的资源管理机制可以查看[这里](https://www.kernel.org/doc/Documentation/cgroups/)的文档。


[分类](http://eLinux.org/Special:Categories "Special:Categories"):

-   [资源管理](http://eLinux.org/Category:Resource_Management "Category:Resource Management")
