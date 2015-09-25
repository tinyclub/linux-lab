---
title: 更多
layout: page
tagline: 本站各类资源合集
permalink: /resources/
group: navigation
plugin: tab
tags:
  - 开源项目
  - 开放书籍
  - 泰晓沙龙
  - 幻灯片
  - 论文
  - 文章分类
description: 泰晓科技提供的各类资源，包括开源项目、开放书籍、幻灯片、论文，组织的各类沙龙活动以及所有文章分类、标签、作者等信息。
comments: false
order: 100
---

{% assign res = site.data.resources %}
<div class="tab_mouseover">
  <div class="tab_header">
    <ul>
    {% for item in res %}
     <li {% if item.title == res.first.title %}class="active"{% endif %}>{{ item.title }}</li>
    {% endfor %}
    </ul>
  </div>
  <div class="tab_content">
    {% for item in res %}
    <div class='tab_content_item {% if item.title == res.first.title %}active{% endif %}'>
     <ul>
     {% assign articles = site.data[item.data] %}
     {% for article in articles %}
       <li><a ref="bookmark" class="tooltip article" href="{{ article.url }}"><span>{% if article.desc %}{{ article.desc }}{% else %}{{ article.title }}{% endif %}</span>{{ article.title }}</a></li>
     {% endfor %}
     </ul>
    </div>
   {% endfor %}
  </div>
</div>
