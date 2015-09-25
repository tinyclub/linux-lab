---
layout: page
# group: navigation
toc: false
title: 工作
tagline: 由各企业一线工程师发布的工作机会
permalink: /jobs/
keywords: Android, Linux, 工作机会
description: 这里所有的工作机会都由企业一线员工发布，定位清晰，目标明确。
order: 10
---

<section id="home">
  {% assign articles = site.posts %}
  {% assign condition = 'group' %}
  {% assign value = 'jobs' %}
  {% include widgets/articles %}
</section>
