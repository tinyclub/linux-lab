---
layout: page
group: navigation
toc: false
title: 书籍
tagline: 泰晓科技各类开源书籍汇总
permalink: /books/
keywords: 开源书籍，Gitbook
description: 泰晓科技撰写或者翻译的文章专辑和开源书籍。
order: 5
comments: false
---

<section id="home">
  {% assign articles = site.pages %}
  {% assign condition = 'path' %}
  {% assign value = '/books/' %}
  {% include widgets/articles %}
</section>
