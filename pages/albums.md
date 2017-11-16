---
layout: page
title: 专辑
tagline: 展示成系列撰写的文章
header: Post By Albums
group: navigation
order: 2
permalink: /albums/
comments: false
---
{% include JB/setup %}

{% assign posts_group_by_album = site.posts | group_by:"album" %}
{% assign posts_sort_by_album = posts_group_by_album | sort:"album" %}

{% assign x_label = '专辑' %}
{% assign y_label = '数目' %}

{% assign total = 0 %}

{% for album in posts_group_by_album %}
  {% if album.name == empty %}
    {% continue %}
  {% endif %}

  {% assign album_url = "" %}
  {% for page in site.pages %}
    {% if page.path contains '/books/' and page.album %}
      {% assign book_title = page.album | remove: " " | upcase %}
      {% assign album_title = album.name | remove: " " | upcase %}
      {% if book_title == album_title %}
        {% assign album_url = page.url %}
      {% endif %}
    {% endif %}
  {% endfor %}

   {% assign total = total | plus: album.items.size %}

  <h3 id="{{ album.name | downcase | replace:' ','-' | replace:'/','-' }}-ref">{% if album_url != "" %}<a href="{{ album_url }}" title="该专辑已发布为GitBook，点击查看！">{{ album.name}}</a>{% else %}{{ album.name }}{% endif %} <sup>({{ album.items.size }})</sup></h3>
  <ul>
    {% for post in album.items %}
    <li><a href="{{ post.url }}">{{ post.title }}</a></li>
    {% endfor %}
  </ul>
{% endfor %}

{% assign list = posts_group_by_album | sort:'size' | reverse %}
{% assign empty_item = "其他" %}

<h3>{{ x_label}}{{ y_label}}统计 <sup>({{ total }})</sup></h3>
{% include widgets/svg_statistic %}
