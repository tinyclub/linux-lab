---
layout: page
group: navigation
toc: false
title: 人才
author: Wu Zhangjin
tagline: 大中华区 Linux 人才名录
permalink: /talents/
keywords: Linux, Team, 团队, Talents, 人才, 简历, Resume
description: 来自高校或者企业的 Linux 团队。
order: 9
---

为了更好地对接企业和高校 Linux 人才，该页面将持续收录大中华区各大高校 Linux&开源 社区、社团、用户爱好者等团队。

欢迎各团队负责人[投递](/post)团队信息，也可以直接扫码联系我们加入微信群——“校企 Linux 团队直通车”：

![tinylab wechat](/images/wechat/tinylab.jpg)

<hr>

<section id="home">
  {% assign articles = site.posts %}
  {% assign condition = 'group' %}
  {% assign value = 'team' %}
  {% include widgets/articles %}
</section>
