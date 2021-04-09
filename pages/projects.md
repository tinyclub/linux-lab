---
layout: page
group: navigation
toc: false
title: 项目
author: Wu Zhangjin
tagline: 开源项目与书籍
permalink: /projects/
keywords: 开源项目, 开放书籍
description: 由泰晓科技参与、发起或者主导的各类开源项目与书籍
order: 3
comments: false
---

<section id="home">
  {% assign articles = site.pages %}
  {% assign condition = 'path' %}
  {% assign value = '/projects/' %}
  {% include widgets/articles %}

  {% assign articles = site.pages %}
  {% assign condition = 'path' %}
  {% assign value = '/books/' %}
  {% include widgets/articles %}
</section>
