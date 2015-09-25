---
title: WordPress 站点 JavaScript 错误调试
author: Wu Zhangjin
layout: post
permalink: /faqs/wordpress-site-javascript-error-debug/
tags:
  - Chrome
  - 调试
  - JavaScript
  - SCRIPT_DEBUG
  - wordpress
categories:
  - WordPress
---
  * 问题描述

    在WordPress安装一些插件或者做了其他修改后，可能会导致JavaScript出错，该如何调试呢？

  * 问题分析

    通过检索，发现浏览器都有调试功能，另外，WordPress也有内置JavaScript调试支持：[Using Your Browser to Diagnose JavaScript Errors][1]。

  * 解决方案

    通过实验，发现Chrome浏览器的调试支持更直观醒目。如果确定不是浏览器本身的问题，那么建议用Chome调试。下面开始调试。

      * 首先在WordPress的wp-config.php的开头加入如下配置

        <pre>define('SCRIPT_DEBUG', true);</pre>

      * 通过Chrome浏览器打开有问题的网页

      * 打开Chrome的调试终端

        <pre>Tools -&gt; Developer Tools -&gt; Console</pre>

        根据错误提示，找到出错的文件和所在的行就可以很快定位到问题了。

      * 解决问题后记得把SCRIPUT_DEBUG选项行删除掉，或者设置为false

        <pre>define(&#39;SCRIPT_DEBUG&#39;, false);</pre>




 [1]: http://codex.wordpress.org/Using_Your_Browser_to_Diagnose_JavaScript_Errors
