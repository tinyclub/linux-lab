---
title: '草稿箱'
author: Wu Zhangjin
layout: page
draft: true
permalink: /draft/
toc: false
---

<br/>
<strong>Posts： </strong>
<br/>

<section id="home">
  {% assign articles = site.posts %}
  {% assign condition = 'draft' %}
  {% assign value = true %}
  {% include widgets/articles %}
</section>

<br/>
<strong>Pages： </strong>
<br/>

<section id="home">
  {% assign articles = site.pages %}
  {% assign condition = 'draft' %}
  {% assign value = true %}
  {% include widgets/articles %}
</section>
