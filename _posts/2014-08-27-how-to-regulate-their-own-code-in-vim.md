---
title: 在 VIM 中如何规范自己的代码
author: Wen Pingbo
layout: post
permalink: /faqs/how-to-regulate-their-own-code-in-vim/
views:
  - 88
tags:
  - CodingStyle
  - linuxsty
  - Vim
  - vim plugin
categories:
  - Linux
---
  * 代码缩进

    在 VIM 中，可以在 `.vimrc` 里定义 TAB 缩进宽度和策略。主要有如下几个配置项：

      * tabstop &#8212; 用来定义一个 TAB 显示的宽度，默认是8个空格
      * shiftwidth &#8212; 指定在重新缩进代码时(>>, <<)，移动的宽度
      * softtabstop &#8212; 指定在编辑模式下，按一个 TAB 的字符宽度

    可以这样定义自己的缩进风格：

        /* TAB宽度为8 */
        :set tabstop=8 softtabstop=8 shiftwidth=8 noexpandtab
        /* TAB宽度为4 */
        :set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
        /* 把所有的TAB转换成空格，宽度为4 */
        :set softtabstop=4 shiftwidth=4 expandtab


    如果 softtabstop 和 tabstop 的宽度不一致，VIM 就会在混合使用 TAB 和空格来缩进。根据 Linux Kernel 里的代码规范，推荐把 TAB 宽度设为8.

  * 代码风格提示

    为了使代码风格和 Linux Kernel 代码规范一致，我们可以利用 VIM 的一个插件，[linuxsty插件][1]，来帮助规范代码风格。这个插件会用红色实时提醒代码中不符合规范的地方，敦促我们去改变。这个插件使用很简单，只需把 `linuxsty.vim` 这个插件放到 `.vim/plugin` 下就可以了。

  * 代码风格检查

    有时，我们在阅读他人代码时，需要确定代码使用的是什么缩进风格，这时可以使用 VIM 的 `set list` 和 `set nolist`，把不可显示的字符都显示出来，这样对查看代码缩进规则，排除一些错误很有帮助。

  * 代码风格重新格式化

    另一个有用的 VIM 命令就是 Super Tab。它可以把当前代码中的所有的 TAB 转换成空格，或者反过来，命令如下：

        :set et|retab
        :set noet|retab!


    如果需要批量转换现有代码的缩进风格，可以用 VIM 中 `=`，选中相应的代码，按 `=` 就可以重新格式化其缩进风格。




 [1]: http://www.vim.org/scripts/script.php?script_id=4369
