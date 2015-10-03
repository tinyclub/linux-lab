---
title: WordPress 网站 SEO 优化
author: Wu Zhangjin
layout: post
permalink: /wordpress-site-seo-optimization/
tags:
  - async
  - BOM
  - 缓存
  - DB Cache Reloaded
  - defer
  - Hyper Cache
  - JavaScript
  - Nginx
  - Robots.txt
  - SEO
  - SiteMap
  - wordpress
  - 搜索引擎收录
categories:
  - WordPress
---

> by falcon of [TinyLab.org][2]
> 2014/07/20


## 前言

本站建站有一段时间，买的阿里云，搭的WordPress, 刚开始一直有各种问题，导致无法访问，尝试过：

  * 升级Web服务器：[从Apache到Nginx][3]
  * 创建文件并配置Swap服务
  * 升级RAM：从512M到2G

但是发现有时访问还是很慢，特别是连接多了以后，服务器就down掉，所以得继续抽空优化。

## 兼容性问题

先做HTML的W3C兼容性测试，如果不兼容，很多浏览器可能无法访问，果然，通过<http://validator.nu/>一测，发现一大堆问题。最重要的问题莫过于：

<pre>Almost standards mode doctype. Expected “”
</pre>

查了一下，发现元凶竟然是M$引入&#8221;BOM&#8221;(Byte Order Mark, UTF8文件的Magic Number，但是并没有标准化)，不知道哪个插件作者用Windows开发的，导致文件里头带有BOM字节，而标准HTML在文件头是不允许有额外字节的，否则，有些浏览器就解析不了，比如M$ IE。这就是原来在IE上浏览不了该站的根源（所有页面靠左对齐了）。

通过如下命令可以确认网页开头到底有没有额外的BOM字节，如果有的话，会是这个样子：

<pre>$ curl -s http://www.your-web-site.com/ | head -1 | sed -n l
\357\273\277\r$
</pre>

前三个字节是8进制的，对应十六进制刚好是：EF、BB、BF。

在Windows下可以用notepad++等直接去掉和添加BOM字节，在Linux下可以用vim做到：

<pre>$ vim test.c
:set fileencoding=utf-8

:set bomb
:set nobomb
:set bomb?
</pre>

以上三个设置分别为添加/删除/查询bomb标志。

对于WordPress，如果安装插件很多，那得把含有BOM的文件一个一个找出来。咱们可以用grep，只需要匹配文件头是否有BOM字节就可以：

<pre>$ grep -r -I -l $'^\xEF\xBB\xBF' test.c
test.c
</pre>

找到以后，可以用`sed -i`做替换（注：千万记得备份）：

<pre>$ sed -i -e '1s/^\xEF\xBB\xBF//g' test.c
</pre>

这里是批处理（Again：操作前，千万要备份）：

<pre>$ grep -ur -I -l $'^\xEF\xBB\xBF' /test-dir | xargs -i sed -i -e '1s/^\xEF\xBB\xBF//g' {}
</pre>

关于更多的不兼容性问题，就根据测试的结果一个一个解吧。

本节参考：

  * [Why Firefox highlights HTML transitional doctype in red?][4]
  * [UTF-8编码中BOM的检测与删除][5]

## 性能问题

接下来，咱们测试一下默认配置的性能，有蛮多免费的站点：[12 个最好的免费网站速度和性能测试工具][6]。

当前试用了[Google PageSpeed Insights][7]和[Load Impact][8]。

前者允许用户分析网站页面的内容，并且会提供加快网站访问速度的建议，后者允许用户做些 web 应用的负载和性能测试。它不断增加网站流量来测量网站性能。Load Impact 会选择一个全球负载区，测试模拟客户，带宽，接收数据和每秒请求等。越来越多客户变活跃，这个工具会用个漂亮的图表来展示测量的加载时间。

通过Load Impact测试以后发现，访问时间跟并发数成线性关系，那意味着，前面提到的并发访问多了以后，整个服务性能逐步下降了，到最后Nginx都无法提供服务了。

### 化动为静；缓存起来

这个问题，通过查找资料并分析，发现务必要做几个工作：

  * 把动态页面转换为静态页面

这个跟Android上的ART一个原理，页面一旦编辑完就可以生成一个静态的html页面，用户访问时就可以直接从磁盘甚至内存里头拿html代码，无需额外的PHP解析开销（包括处理器和内存）了。

  * 把一些SQL访问缓存

大量并发的数据库访问会带来很大的IO性能开销，可以把一些SQL查询的结果缓存起来，这样可以节省IO开销。

上面两个的选择很多，经过对比，分别采用了：

  * 页面缓存：[Hyper Cache][9]
  * SQL缓存：[DB Cache Reloaded Fix][10]

### 除杂去冗，化繁为简

后面综合Google PageSpeed Insights的测试结果，又做了如下几项优化：

  * CSS Minify：[Autoptimize][11]，注：不能使用其JS优化，有严重Bug。
  * JS Minify：[HeadJS Plus][12]
  * HTML Minify：[WP-HTML-Compression][13]

### 线性转并行；同步转异步

需要特别强调的是 JS 异步加载优化，这个效果非常明显也很典型。

该站用到了第三方统计，发现通过国外 VPN 进来的时候，统计站点的 Javascript 加载严重拖慢了整个系统，导致文章带有代码高亮插件的内容无法正常渲染。

于是乎，想到了异步加载 Javascript 应该能解决问题，通过查找确实发现大部分浏览器都已经支持 async 或者 defer 属性，后者确保执行时序，前者则不会保障 Javascript 的加载顺序。

对于我们这里的特例，统计站点与站内其他资源有任何依赖关系，完全可以用 async 属性，用法如下：

<pre></pre>

异步以后，效果相当明显，系统其他部分顺利加载，统计就让它慢悠悠地干吧。

需要注意的是，上面的方法好像效果不好，对于站长统计，会导致那个统计图标不显示，这样的话，可以用类似下面的思路（站长统计和百度统计都已经支持，可以直接复制过来）：

<pre></pre>

### 性能测试和优化建议

后面又尝试了其他几个测试服务：

  * [neustar][14]展示各地的连接速度，并且详细地展示了各个资源的获取时间，可以很方便地辅助开发者定位问题并做针对性优化。
  * [Web Page Analyzer][15]非常强大，提供了详细的网站分析数据并且会提供提高网站性能的建议。它提供大量的 web 页面速度报告，global report，外部文件计算，加载时间，网站分析数据和改善建议。
  * [Octa Gate Site Timer][16] 允许用户检测每个用户加载一个或多个页面的时间。当页面加载的时候，SiteTimer 存储每个项目加载的数据和用户接收的数据，这些数据会用一个网格来显示。
  * [Pingdom][17] 是个非常杰出的工具，帮助用户生成大量网站的报告（页面大小，浏览器缓存，性能等级等），确定网站的加载时间，而且允许用户跟踪性能的历史记录，能在不同位置进行网站测试。
  * [GTmetrix][18] 可以帮助用户开发一个快速，高效，能全面改善用户体验的网站。它会为网站性能打分，然后提供可行性的建议来改善已发现的问题。

本节参考：

  * [WordPress缓存插件Hyper Cache使用方法与缓存加速效果对比分析][19]
  * [wordpress插件之缓存类插件总结与点评][20]
  * [Improving Page Load Speed][21]

## 搜索引擎收录问题

这里涉及三个动作，分别是：

  * robots.txt协议：告诉搜索引擎能不能搜，哪些目录可以搜
  * SiteMap协议：告诉搜索引擎我这个网站有哪些东西
  * 直接提交给搜索引擎进行收录

首先是robots.txt，这个可以通过一些网站自动生成一个配置文件：robots.txt，例如<http://tool.chinaz.com/robots/>，生成后这个文件放在网站根目录下。

接着是安装一个SiteMap自动生成的插件，例如：[Baidu Sitemap Generator][22]。生成后，在robots.txt的最后加入如下两行，例如，本站：

<pre>Sitemap: http://tinylab.org/sitemap_baidu.xml
Sitemap: http://tinylab.org/sitemap.html
</pre>

在最后，咱们可以主动给各大搜索引擎提交收录，各大收录的入口地址[这里][23]有一份清单。

经过这三步以后，搜索引擎的收录问题就不大了。

## 更多SEO

除了上述问题外，通过一些专门的SEO评测站点可以获取更多有价值的优化信息。

  * [SEO综合查询][24]

该站提供了各家搜索引擎的收录情况，域名，备案，服务性能，站点描述与关键字设置情况等。通过该工具查到该站的主题没有添加站点描述和关键字信息。

  * [Website Review][25]

这个网站则提供了另外的一些视角，比如上面的兼容性问题测试就是该站提出的建议。

通过SEO综合查询以及相关的检索后，找到了手动为各种场景添加关键字和描述的方式，那就是在header.php的head部分添加如下内容：

<pre><?php
    if (is_home()) {
        $description = "网站描述：不超过200字符。";
        $keywords = "网站关键字：不超过100字符";
    } elseif (is_single()) {
        if ($post->post_excerpt)
            $description = $post->post_excerpt;
        else
            $description = $post->post_title . ':' . substr(strip_tags($post->post_content),0,200);

        $keywords = "";
        $tags = wp_get_post_tags($post->ID);
        foreach ($tags as $tag ) {
            $keywords = $keywords . $tag->name . ", ";
        }
    } elseif (is_category()) {
        $keywords = single_cat_title('', false);
                if (category_description())
                        $description = category_description();
                else
                        $description = $keywords;
    } elseif (is_tag()) {
        $keywords = single_tag_title('', false);
                if (tag_description())
                        $description = tag_description();
                else
                        $description = $keywords;
    }
    $keywords = htmlspecialchars(trim(strip_tags($keywords)));
    $description = htmlspecialchars(trim(strip_tags($description)));
?>


<meta name="keywords" content="<?=$keywords?>" />

<meta name="description" content="<?=$description?>" />
</pre>

记得把首页部分的描述和关键字修改为你自己的内容。

## 小结

上面的优化其实都是最基础的，要真正优化SEO，那就是要逐步丰富与站点主体相关的内容，保持持续的更新和维护，吸引足够的忠实读者。





 [2]: http://tinylab.org
 [3]: /add-cgi-support-for-nginx/
 [4]: http://stackoverflow.com/questions/10775005/why-firefox-highlights-html-transitional-doctype-in-red
 [5]: http://huoding.com/2011/05/14/78
 [6]: http://segmentfault.com/a/1190000000447171
 [7]: http://developers.google.com/speed/pagespeed/insights/
 [8]: http://loadimpact.com/
 [9]: http://www.satollo.net/plugins/hyper-cache
 [10]: http://www.ivankristianto.com/web-development/programming/db-cache-reloaded-fix-for-wordpress-3-1/1784/
 [11]: http://wordpress.org/plugins/autoptimize/
 [12]: https://wordpress.org/plugins/headjs-plus/
 [13]: http://www.svachon.com/blog/html-minify/
 [14]: http://www.neustar.biz/resources/tools/free-website-performance-test
 [15]: http://www.websiteoptimization.com/services/analyze/
 [16]: http://www.octagate.com/service/SiteTimer/
 [17]: http://tools.pingdom.com/fpt/
 [18]: http://gtmetrix.com/
 [19]: http://www.freehao123.com/hyper-cache/
 [20]: http://www.wpcourse.com/wordpress-cache-plugin-summary.html
 [21]: http://www.terranetwork.net/blog/2012/12/improving-page-load-speed/
 [22]: http://www.wpdaxue.com/baidu-sitemap-generator.html
 [23]: http://jingyan.baidu.com/article/d5a880eb70424413f147cce4.html
 [24]: http://seo.chinaz.com/
 [25]: http://www.woorank.com
