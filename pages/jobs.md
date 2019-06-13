---
layout: page
toc: false
group: navigation
title: 机会
author: Wu Zhangjin
tagline: 由各企业一线工程师发布的工作机会
permalink: /jobs/
keywords: Android, Linux, Jobs, 工作机会
description: 这里所有的工作机会都由企业一线员工发布，定位清晰，目标明确。
order: 10
---

为了更好地对接企业和高校 Linux 人才，该页面将持续发布各大企业 Linux 团队负责人直接提交的招聘信息。

欢迎各企业 Linux 部门负责人[投递](/post)招聘信息，也可以直接扫码联系我们加入微信群——“校企 Linux 团队直通车”：

![tinylab wechat](/images/wechat/tinylab.jpg)

<hr>

<section id="home">
  {% assign articles = site.posts %}
  {% assign condition = 'group' %}
  {% assign value = 'jobs' %}
  {% include widgets/articles %}
</section>
