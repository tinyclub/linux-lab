---
title: Q and A Focus Plus FAQ 添加随机 FAQ 小工具
author: Wu Zhangjin
layout: post
permalink: /q-and-a-focus-plus-faq-add-random-faq-widget/
tags:
  - Q and A Focus Plus FAQ
  - Random FAQ
  - Widget
  - wordpress
categories:
  - WordPress
---
  * 问题描述

    WordPress 的 [Q & A Focus Plus FAQ][1] 插件默认的 Widget 只能显示最新 FAQ，如果要随机显示 FAQ，怎么办？

  * 问题分析

    经过查找，发现有如下支持 [wp_query orderby random not working][2]：

        <?php $loop = new WP_Query( array( orderby => 'rand', 'post_type' => 'testimonials', 'posts_per_page' => 1 ) ); ?>
        <?php while ( $loop->have_posts() ) : $loop->the_post(); ?>
        <?php the_permalink();?>


  * 解决方案

    通过 `插件->编辑` 菜单，找到插件名称: `Q And A Focus Plus FAQ`，找到 `q-and-a-focus-plus-faq/inc/widgets.php`，发现做如下修改即可：

        //$pq = new WP_Query(array( 'post_type' => 'qa_faqs', 'orderby' => 'post_date', 'showposts' => $instance['numberposts'] ));
        $pq = new WP_Query(array( 'post_type' => 'qa_faqs', 'orderby' => 'rand', 'showposts' => $instance['numberposts'] ));





 [1]: http://lanexatek.com/downloads/wordpress-plugins/qa-focus-plus
 [2]: http://wordpress.org/support/topic/wp_query-orderby-random-not-working
