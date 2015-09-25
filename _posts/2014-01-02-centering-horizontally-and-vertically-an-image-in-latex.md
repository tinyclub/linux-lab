---
title: Centering (horizontally and vertically) an image in Latex
author: Wu Zhangjin
layout: post
permalink: /centering-horizontally-and-vertically-an-image-in-latex/
tags:
  - Book
  - Centering
  - Cover
  - horizontal
  - Image
  - Latex
  - vertical
categories:
  - Latex
---

> by falcon of [TinyLab.org][2]
> 2014/01/02


## Background

In [Open-Shell-Book][3] project, I want to add an image as the book cover.

First off, I tried to convert the image to a pdf file with the *convert.im6* tool from *imagemagick*, and then, used *pdftk* to merge this cover pdf file with the book pdf file, it basically worked, but the bookmarks lost.

<pre>$ sudo apt-get install imagemagick pdftk
$ convert cover.png cover.pdf
$ pdftk A=cover.pdf B=book.pdf cat A B output book-with-cover.pdf
</pre>

Google gave me *gs* and *pdf-merge.py*, both of them didn&#8217;t work well, the former although reserved the bookmarks, but their links didn&#8217;t point to the right places, the latter fixed up part of the links, but also broke the accessing of the codes: the content listed as code can not be searched/copied in pdf readers.

## Issue

So, I plan to use Latex itself to build the cover, but to do so, I must center the image horizontally and vertically.

## Solution

To fix up this issue, after reading several pages of Google results, I get this solution:

  * Horizontally center the image with `\begin{table} ... \end{table}`
  * Vertically center the image with the export feature of the `adjustbox` package: `\includegraphics[width=1.5\textwidth,center]{image.png}`

The full code looks like:

<pre>\begin{table}
    \includegraphics[width=1.5\textwidth,center]{cover.png}
\end{table}
</pre>

To simplify the using, our [Open-Shell-Book][3] defined a new command for the cover usage:

<pre>\documentclass[a4paper,oneside]{book}
\usepackage[export]{adjustbox}[2011/08/13]
\usepackage{graphicx}

\newcommand\makecover[1]{
    \clearpage
    \begin{table}
        \includegraphics[width=1.5\textwidth,center]{#1}
    \end{table}
    \addtocounter{page}{-1}
    \newpage}

\begin{document}

\makecover{cover.png}

\end{document}
</pre>





 [2]: http://tinylab.org
 [3]: /open-shell-book/
