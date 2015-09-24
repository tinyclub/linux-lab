---
title: Qt 多国语言支持
author: Wu Zhangjin
layout: post
permalink: /faqs/qt-multi-languages-support/
views:
  - 152
voted_ID:
  - 'a:3:{s:11:"A1945097233";s:10:"1404712013";s:11:"A1945097294";s:10:"1405172057";s:11:"A1945097412";s:10:"1405338501";}'
votes_count:
  - 3
tags:
  - linguist
  - lrelease
  - lupdate
  - Qt
  - QtCreator
  - 多国语言
  - 中文
categories:
  - Qt
---
* 问题描述

  很多软件在全球各地广泛使用，有众多不同国籍和语言的用户。用Qt开发的软件同样受众广泛，跨越多个国家。如果某个软件最早源自英语国家，要想推广到中国，如何支持中文呢？

* 问题分析

  Qt对多国语言的支持非常有好。所有用`QObject::tr()`包含的字符串都可以翻译成多个不同国家的语言，如果要翻译成多国语言，只需要在`.pro`中添加TRANSLATIONS指定某个国家的语言，然后可以用`lupdate`把所有这样的字符串dump出来并生成一个`.ts`文件，该文件可以用linguist翻译工具编辑，翻译完成后，可以用lrelease生`.qm`格式的Qt message files，这个文件可以被Qt加载，加载不同国家语言的这种文件就可以让该软件呈现出不同国家的语言。

* 解决方案

  这里以qtcreator快速创建一个Qt例子，并从头开始介绍如何添加中文支持。

  快速创建一个Qt例子，先启动qtcreator：

      $ qtcreator

  然后，依次：

      New File or Project --&gt; Applications --&gt; Qt Gui Application --&gt; Next --&gt; Name: test --&gt; Class: test --&gt; Finis

  这样会创建一个默认的只支持英文的Qt程序。通过Build, Run启动后，发现标题是英文test。

  如果要支持中文，让标题显示为“多国语言测试”，相关改动如下：

      diff --git a/main.cpp b/main.cpp
      index 0980f59..976e320 100644
      --- a/main.cpp
      +++ b/main.cpp
      @@ -1,9 +1,20 @@
       #include &lt;QApplication>
      +#include &lt;QTextCodec>
      +#include &lt;QTranslator>
       #include "test.h"
      
       int main(int argc, char *argv[])
       {
         QApplication a(argc, argv);
      +
      +    QTextCodec::setCodecForTr(QTextCodec::codecForName("UTF-8"));
      +    QFont font1("unifont", 16, 50, FALSE);
      +    a.setFont(font1);
      +
      +    QTranslator *t = new QTranslator(0);
      +    t->load(QString("test_zh_CN.qm"), ".");
      +    a.installTranslator(t);
      +
         test w;
         w.show();
      
      diff --git a/test.pro b/test.pro
      index ceeb973..6282570 100644
      --- a/test.pro
      +++ b/test.pro
      @@ -18,3 +18,5 @@ SOURCES += main.cpp\
       HEADERS  += test.h
      
       FORMS    += test.ui
      +
      +TRANSLATIONS += test_zh_CN.ts

  然后，咱们可以通过lupdate生成test\_zh\_CN.ts这个中文翻译文件，这个文件主要给语言学家用：

      $ lupdate test.pro

  生成的test\_zh\_CN.ts可以用linguist打开：

      $ linguist test_zh_CN.ts

  打开以后填充Chinese Translation部分的内容为“多国语言测试”，并选择那个对钩按钮，设置翻译完成，然后保存退出即可。

  之后通过lrelease生成Qt message file：test\_zh\_CN.qm：

      $ lrelease test_zh_CN.ts

  翻译完成后，咱们重新编译并启动：

      $ qmake &#038;&#038; make
      $ ./test

  会发现标题已经变成了“多国语言测试”。
