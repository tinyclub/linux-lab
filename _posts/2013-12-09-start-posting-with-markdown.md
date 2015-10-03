---
title: Start posting with Markdown
author: Wu Zhangjin
layout: post
album: Markdown 用法详解
permalink: /start-posting-with-markdown/
tags:
  - markdown on save
  - retext
  - Tools
categories:
  - Markdown
---

> by falcon of [TinyLab.org][2]
> 2013/11/09

### Background

It's really painful to write blogs with a visual editor:

  * I want a pretty output
  * I'm not a UI designer, I don't know how to tune the formats
  * I want to print my idea as quickly as possible

**Markdown** solved the above issue, it allows us to write a pretty document quickly in a very simple markup language.

Likes **Latex**, it can be converted to *HTML*, *PDF* and the other visual output formats, but it is simpler and easier to use.

### Usage

To use it, at first, please learn [Markdown Syntax][3] or its Chinese translation: <http://wowubuntu.com/markdown/> or [Markdown Cheatsheet][4].

Then, we can write something with a plan text editor, such as gedit or vim, after editing, save the content to a file named with the '.md' suffix.

To display the real output, we can convert the just saved file to the other generic formats, such as Html, ODT or PDF, in Ubuntu, the tool **markdown** is such a tool:

    $ sudo apt-get install markdown

If want an integrated editor, we can use the tools like **Retext**, which allows to edit, preview and export to HTML, ODT or PDF.

    $ sudo apt-get install retext

In WordPress, If want to write blogs in **Markdown**, a plugin named **Markdown on save** can be installed, it can be used like **Retext**.

### Conclusion

With the help of the **Markdown** language and the **Markdown on save** plugin, we're able to publish our idea more efficiently.

 [2]: tinylab.org
 [3]: http://daringfireball.net/projects/markdown/syntax
 [4]: https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet
