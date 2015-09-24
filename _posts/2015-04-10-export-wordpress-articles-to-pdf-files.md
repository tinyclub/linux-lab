---
title: WordPress 文章保存为 PDF 的最佳方式
author: Wu Zhangjin
layout: post
permalink: /export-wordpress-articles-to-pdf-files/
views:
  - 257
tags:
  - CleanPrint
  - CleanSave
  - Crayon
  - CSS Print
  - Hacklog Down As PDF
  - pdf
  - Print Friendly and PDF Button
  - wordpress
  - WP Print Friendly
  - 导出
  - 打印支持
  - 插件
  - 保存为
categories:
  - WordPress
---

> by Falcon of [TinyLab.org][1]
> 2015/04/08


## 由来

如果碰到好文章，通常希望下载并收藏起来，甚至直接打印成纸质版。由于 Web 页面不便于直接保存，所以，一个 WordPress 站点提供导出 PDF 的功能变得非常迫切。

尝试了诸多办法，都或多或少有一些缺点，不过最后找到了两个比较不错的方式，下面来逐个比较与分析下。

## PDF 插件一览

一旦有新的需求，通常想到的是看看有没有合适的插件，搜罗了一遍网路和 WordPress 插件中心，发现这几个是比较推荐的：

  * CleanPrint / CleanSave

    非常美观，可惜有两个缺点：

      * 部分选项的中文支持不好
      * 在加载页面时会访问 CleanPrint / CleanSave 的网站，会拖慢整个系统

  * Print Friendly and PDF Button

    中文支持得不错，也比较美观，比较可惜的是：

      * 同样会在加载页面时访问外部网站，会拖慢整个页面加载，甚至好像会被 GFW 屏蔽，导致整个网站都无法加载
      * 生成的目录无法正常链接到文档内部，而是会链接到网站的原有链接

  * Hacklog Down As PDF

    中文支持得非常好，只是太丑陋了。

## 最佳插件：WP Print Friendly

经过大量的尝试，发现了一个非常简单的插件：**WP Print Friendly**

这个插件的思路很简单，

  * 不用额外的库
  * 不需要访问外部网站
  * 直接生成另外一个更简洁适合打印的页面
  * 最后让用户自己使用浏览器的打印支持 **Print to PDF**

在测试过 3 个主流浏览器：Chromium-browser, Firefox 以及 Safari 后，

  * 完美支持中文
  * 生成 PDF 后，目录链接轻松跳转到文档内部（注：Safari 似乎有些问题）
  * 高效快捷
      * 无须在服务器端生成 PDF，减轻服务器压力
      * 无须访问第三方网站，也不用担心 GFW

不过需要注意的是，该插件不能很好支持源代码格式化插件：**Crayon**，需要稍微改一下插件，把输出页面的 `textarea` 框干掉，否则同一份代码会重复输出两次。

改动大体如下：

<pre>$ diff -Nubr a/wp-content/plugins/wp-print-friendly/default-template.php b/wp-content/plugins/wp-print-friendly/default-template.phpp
--- a/wp-content/plugins/wp-print-friendly/default-template.php 2015-04-09 02:14:09.361139007 +0800
+++ b/wp-content/plugins/wp-print-friendly/default-template.php 2015-04-09 02:14:10.117158690 +0800
@@ -20,7 +20,9 @@
                        if( is_attachment() &#038;&#038; wp_attachment_is_image() )
                            echo '

<p>
  ' . wp_get_attachment_image( $post->ID, 'large' ) . '
</p>';

-                       the_content();
+                       $content = apply_filters('the_content', $content);
+                       $content = preg_replace('#<textarea[^>]*>(.*?)</textarea>#is', '', $content);
+                       echo $content;
                    ?>



<?php
</pre>



<p>
  另外，为了让打印按钮（实际是生成另外一个适合打印页面的按钮）悬浮在文章正文的右侧，我们在 WordPress 的主题下的 <code>style.css</code> 中加了如下三行：
</p>



<pre>
/* For WP Print Friendly */
.print_link{text-align:right;}
.wpf_wrapper{text-align:right;}


 [1]: http://tinylab.org
