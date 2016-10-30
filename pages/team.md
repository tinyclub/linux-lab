---
layout: page
group: navigation
toc: false
title: 人才
tagline: 大中华区 Linux 团队名录
permalink: /team/
keywords: Linux, Team, 团队, Talents, 人才
description: 来自高校或者企业的 Linux 团队。
order: 9
---

<section id="home">
  {% assign articles = site.posts %}
  {% assign condition = 'group' %}
  {% assign value = 'team' %}
  {% include widgets/articles %}
</section>
