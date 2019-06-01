---
title: '资讯'
tagline: '追踪 Linux 业界动态'
author: Wu Zhangjin
layout: page
album: '泰晓资讯'
permalink: /news/
update: 2019-6-1
group: navigation
order: 2 
toc: false
description: '汇集国内外 Linux 社区最新最重要的资讯，及时跟踪业界动态和发展趋势，主要关注 Linux 内核、发行版、应用、行业峰会等最新进展。'
categories:
  - 泰晓资讯
  - 技术动态
  - 行业动向
tags:
  - Linux 内核
  - 行业峰会
  - Linux 发行版
---

早在 2015 年，本站编辑 [@cee1](/authors/#chen-jie-ref) 发起并维护了数月的 “泰晓周报”，及时跟踪了行业动态，由于时间关系，该专辑一度中断。

亲爱的读者朋友们，我们计划从 2019-05-31 日起，重新启动该专辑，同时更名为 “泰晓资讯”，该专辑致力于及时地把国内外 Linux 社区的一些重要资讯汇总起来，同步给大家。

欢迎大家关注，也欢迎大家投递资讯线索、撰写资讯摘要。

* 资讯首页
  * [tinylab.org/news](/news)
* **投稿地址**
  * [Github 投稿页面](https://github.com/tinyclub/tinylab.org/issues)

<hr>

<section id="home">
  {% assign articles = site.posts %}
  {% assign condition = 'group' %}
  {% assign value = 'news' %}
  {% include widgets/articles %}
</section>
