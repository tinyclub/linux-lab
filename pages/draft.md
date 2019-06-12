---
title: '草稿箱'
author: Wu Zhangjin
layout: page
draft: true
permalink: /draft/
toc: false
---

<section id="home">
  {% assign articles = site.posts %}
  {% assign condition = 'draft' %}
  {% assign value = true %}
  {% include widgets/articles %}
</section>
