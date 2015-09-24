---
title: Wordpress Q and A Focus Plus FAQ 中用 Markdown
author: Wu Zhangjin
layout: post
permalink: /faqs/user-markdown-in-q-and-a-focus-plus-faq/
views:
  - 20
tags:
  - Markdown
  - Q and A Focus Plus FAQ
  - wordpress
categories:
  - WordPress
---
  * 问题描述

    早前把网站的编辑器强制采用了Markdown，用的是[Markdown on Save Improved][1]插件。最近安装了[Q and A Focus Plus FAQ][2]系统，发现编辑FAQ时只能用富文本的编辑器，而不是之前用的Markdown，很不方便，很不统一，所以务必解决。

  * 问题分析

    那问题就是想办法找到为什么Markdown在FAQ编辑时不起作用呢？

    首先，试着看了一下Markdown插件的源代码，找到如下几行：

        protected function add_post_type_support() {
                add_post_type_support( 'post', 'markdown-osi' );
                add_post_type_support( 'page', 'markdown-osi' );
        }


    发现上述函数似乎有点关联，尝试着找到FAQ插件的文章类别，发现是qa_faqs，加上看看：

        protected function add_post_type_support() {
                add_post_type_support( 'post', 'markdown-osi' );
                add_post_type_support( 'page', 'markdown-osi' );
                add_post_type_support( 'qa_faqs', 'markdown-osi' );
        }


    改好后，发现并没有效果，然后回想起来当时为了避免协作的其他作者使用富文本的编辑器，所以把Markdown的选择给干掉了，强制采用了Markdown。所以，第一个动作就是通过修改wp-config.php重新打开Markdown选择设置项，即把如下的定义注释掉：

        define( 'SD_HIDE_MARKDOWN_BOX', true );


    发现，进入到FAQs里头编辑文档时，Markdown的设置项回来了，并且Markdown都被disable了。

    > [*] Disable Markdown formatting
    > [ ] Convert HTML to Markdown (experimental)

    Ok，回来了，可以使用Markdown了。那已经用其他编辑器写的文档呢？还好不多，全部转成Markdown吧。

  * 解决方案

      * 在Markdown插件中加入qa_faqs文章类型支持，代码修改如上分析。
      * 通过wp-config.php把Markdown设置项打开，改动如上分析。
      * 把所有现有的HTML格式文章转换为Markdown，并把HTML相关的格式去掉，转换完成后把wp-config.php配置改回重新隐藏Markdown设置
      * 所有新的代码已经可以用Markdown重写了

    在展示代码时需要注意，为了保持正常的缩进，需要把代码强制控制4个字节，如果有多一级列表缩进，那么再加4个，也就是说，有两级列表那么代码就需要加8个空格作为缩进。尽量都增加额外的`<pre>...</pre>`。




 [1]: https://wordpress.org/plugins/markdown-on-save-improved/
 [2]: http://lanexatek.com/downloads/wordpress-plugins/qa-focus-plus
