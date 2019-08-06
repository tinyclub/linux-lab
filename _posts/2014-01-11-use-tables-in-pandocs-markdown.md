---
title: "Use tables in Pandoc's Markdown"
author: Wu Zhangjin
layout: post
album: Markdown 用法详解
permalink: /use-tables-in-pandocs-markdown/
tags:
  - Latex
  - Markdown
  - pandoc
  - pdf
  - table
categories:
  - Markdown
---

> by Falcon of [TinyLab.org][2]
> 2014/01/11

## Issue

The standard Markdown allows to add tables in HTML format, for exampe:

    <table>
     <tr>
       <th>
         Head row1
       </th>
       <th>
         Head row2
       </th>
     </tr>
   
     <tr>
       <td>
         Content row1
       </td>
       <td>
         Content row2
       </td>
   
     </tr>
    </table>

And it looks like:

  Head row1    | Head row2
  -------------|-------------
  Content row1 | Content row2

But Pandoc doesn&#8217;t support it, Pandoc need pure text table, see the *Tables* section in [Pandoc&#8217;s User Guide][3].

## Solution

So, to make a table work with pandoc, we must use something like:

<pre>Head row1         Head row2
----------------  ----------------
  Content row1      Content row2
</pre>





 [2]: http://tinylab.org
 [3]: http://johnmacfarlane.net/pandoc/README.html
