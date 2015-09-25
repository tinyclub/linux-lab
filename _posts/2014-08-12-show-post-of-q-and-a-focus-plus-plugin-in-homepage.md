---
title: Q and A Focus Plus FAQ 显示到网站首页
author: Wu Zhangjin
layout: post
permalink: /faqs/show-post-of-q-and-a-focus-plus-plugin-in-homepage/
tags:
  - 首页
  - faq
  - Q and A Focus Plus FAQ
  - qa_posts
  - wordpress
categories:
  - WordPress
---
* 问题描述

  安装 [Q&A Focus Plus FAQ][1] 插件后，发现通过它发的文章无法展示在网站首页，这样非常不方便用户及时获取FAQ的内容，那怎么办呢？

* 问题分析

  之前尝试过直接去修改Wordpress的Main Query逻辑，不过一直没找对点。今天再次Google: How to add another post type to wordpress homepage，马上就找到很多资料，例如：[Custom Post Types in the Main Query][2]。

  WordPress的强大真地让人难以置信，竟然可以直接通过一个`pre_get_posts()`钩子解决问题。

  > Registering a custom post type does not mean it gets added to the main query automatically.
  >
  > If you want your custom post type posts to show up on standard archives or include them on your home page mixed up with other post types, use the pre\_get\_posts action hook.

      // Show posts of 'post', 'page' and 'movie' post types on home page
      add_action( 'pre_get_posts', 'add_my_post_types_to_query' );
      
      function add_my_post_types_to_query( $query ) {
      if ( is_home() &#038;&#038; $query->is_main_query() )
        $query->set( 'post_type', array( 'post', 'page', 'movie' ) );
      return $query;
      }


* 解决方案

  根据上述方法，咱们可以直接编辑 [Q&A Focus Plus FAQ][1] 插件，在 `q-and-a-focus-plus-faq/q-and-a-focus-plus.php` 最后加入如下内容即可：

      function add_faqs_to_query( $query ) {
      if ( (is_home() || is_archive() || is_author()) &#038;&#038; $query->is_main_query() )
        $query->set( 'post_type', array( 'post', 'page', 'qa_faqs' ) );
      return $query;
      }
      
      // Show posts of 'post', 'page' and 'movie' post types on home page
      add_action( 'pre_get_posts', 'add_faqs_to_query' );


  上面不仅会把FAQ添加到网站首页，还会添加到归档、作者文集页面。




 [1]: http://wordpress.org/plugins/q-and-a-focus-plus-faq/
 [2]: http://codex.wordpress.org/Post_Types
