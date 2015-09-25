---
title: 沙龙
tagline: 由泰晓科技举办的线下沙龙活动
layout: page
group: navigation
permalink: /tinysalon/
order: 20
---

泰晓沙龙 致力于打造一个线下交流平台，主要围绕智能手机生态，探讨产品创意、技术热点、行业观察等。

* 活动时间：每个月定期组织。
* 活动地点：环境优美，气氛轻松的场所。
* 活动内容：通过在线交流讨论出1～2个主题，由相关同学准备材料，然后围绕主题展开讨论。
* 活动经费：初期主要是由报名参会的同学 AA 制。
* <b>报名方式</b>：关注 泰晓科技 微博/微信公众号：@泰晓科技，然后私信留言。

## 历届活动

{% for salon in site.data.salons %}

### [{{ salon.title }}]({{ salon.url }})

  * 主题：{{ salon.topic }}
  * 时间：{{ salon.time }}
  * 地点：{{ salon.addr }}
  * 人员：{{ salon.people }}
  * 小结：{{ salon.desc }}

{% endfor %}
