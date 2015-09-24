---
title: '为开源 B9Creator 打印机添加中文支持'
author: Wu Zhangjin
layout: post
permalink: /3d-printing-adding-chinese-support-for-open-source-b9creator-high-precision-printers/
views:
  - 108
tags:
  - 3D打印机
  - B9Creator
  - linguist
  - lrelease
  - Qt
  - 中文支持
categories:
  - 3D-Print
---

> by falcon of [TinyLab.org][2]
> 2014/08/30


## 简介

[B9Creator 3D 打印机][3]采用DLP投影固化光敏聚合物（光引发）树脂，能够依据三维模型文件构建高分辨率三维物体。

感兴趣可以先来看以下视频：[B9Creator Getstarted][4]和[视频讲解][5]。

这款打印机有两个优点：

  * 精度高
  * 开放源代码

包括硬件、固件和软件通通开放，下载链接见 [B9Creator Source Code][6]。

只可惜这款软件并没有中文支持，也没有在国内网络中找到中文支持，咱们这里就研究下。

## B9Creator 编程语言

为了添加中文支持，咱们先下载 B9Creator 的源代码，并分析下它用的编程语言。

<pre>$ git clone https://github.com/B9Creations/B9Creator.git
</pre>

Clone下来后，就可以在 `B9Creator/Root/B9Creator` 目录下找到源代码了。

通过分析，发现 B9Creator 采用了 Qt 来开发，Qt 不仅支持跨平台，而且对多国语言的支持非常好。

## 添加Qt开发环境

在添加中文支持之前，记得先参考 [在Ubuntu下安装Qt开发环境][7] 搭建 Qt 开发环境，不然后面根本没法实验。

## 添加中文支持

要添加中文支持，需要做两个事情：

  * 添加支持中文的代码
  * 添加所有字符串的中文翻译文件
  * 进行文本翻译
  * 编译并查看效果

### 添加支持中文的代码

首先对照 [Qt多国语言支持][8] 做如下修改：

<pre>diff --git a/Root/B9Creator/B9Creator.pro b/Root/B9Creator/B9Creator.pro
index bfc0237..aaa774f 100644
--- a/Root/B9Creator/B9Creator.pro
+++ b/Root/B9Creator/B9Creator.pro
@@ -165,6 +165,8 @@ FORMS    += mainwindow.ui \
     dlgcalbuildtable.ui \
     dlgcalprojector.ui

+TRANSLATIONS = B9Creator_zh_CN.ts
+
 RESOURCES += \
     b9edit/sliceeditview.qrc \
     b9edit/b9edit.qrc \
diff --git a/Root/B9Creator/mainwindow.cpp b/Root/B9Creator/mainwindow.cpp
index d1c3ce5..8bf01ac 100644
--- a/Root/B9Creator/mainwindow.cpp
+++ b/Root/B9Creator/mainwindow.cpp
@@ -52,6 +52,10 @@ MainWindow::MainWindow(QWidget *parent) :
     QMainWindow(parent),
     ui(new Ui::MainWindow)
 {
+    QTranslator *translator = new QTranslator(0);
+    translator->load(QString("B9Creator_zh_CN.qm"), ".");
+    QCoreApplication::installTranslator(translator);
+
     // Set up Identity
     QCoreApplication::setOrganizationName("B9Creations, LLC");
     QCoreApplication::setOrganizationDomain("b9creator.com");
</pre>

需要注意的是，中文翻译的文件加载部分必须要放在 `Root/B9Creator/mainwindow.cpp` 里头，有尝试过放在 `Root/B9Creator/main.cpp`，不管用，因为那个不是真正负责窗口显示的。

### 创建中文语言翻译文件

接下来当然是创建中文语言翻译文件，即上面的 `Root/B9Creator/B9Creator_zh_CN.ts` ，这个文件需要用 `lupdate` 工具生成出来。

<pre>$ lupdate B9Creator.pro -ts B9Creator_zh_CN.ts
</pre>

### 进行文本翻译

翻译的工作可以交给懂英文并且熟悉 3D 打印的专业人员，直接把上面的文件发给他们就可以。

翻译人员可以用 `linguist` 工具进行翻译。翻译时，如果确认无误，则打个“勾”，否则直接继续后续翻译，完以后保存即可。

### 编译并查看效果

翻译人员把翻译过后的文件发过来，放回到原来的位置，即 `Root/B9Creator/B9Creator_zh_CN.ts`，执行如下指令生成二进制语言包 `.qm`。

<pre>$ lrelease B9Creator_zh_CN.ts
</pre>

然后重新编译 B9Creator、执行它就可以看到效果：

<pre>$ qmake &#038;&#038; make
$ ./B9Creator
</pre>

## 创建中文支持项目

由于比较忙，而且对 3D 打印相关的术语不是很了解，所以到目前为止只是添加了支持中文的代码，另外，也初步翻译了几个字符串，大部分内容还有待更专业的人员参与进来一起翻译。

现在，我们决定把代码和初步支持开放出来，无偿分享给国内的 3D 打印业界，希望大家能够参与进来，一起交流：

  * 项目首页：[B9Creator:添加开源3D打印机中文支持][9]
  * 代码仓库：[https://github.com/tinyclub/b9creator-zh_cn.git][10]

如果您愿意参与翻译，可以直接跟 [@泰晓科技][11] 或者 [@吴章金falcon][12] 联系。





 [2]: http://tinylab.org
 [3]: http://b9creator.com/
 [4]: http://b9creator.com/getstarted/
 [5]: http://my.tv.sohu.com/us/63290008/54522012.shtml
 [6]: http://b9creator.com/source-files/
 [7]: /faqs/how-to-install-qt-in-ubuntu/
 [8]: /faqs/qt-multi-languages-support/
 [9]: /b9creator-zh-cn-b9creator-open-source-3d-printer-language-support-project/
 [10]: https://github.com/tinyclub/b9creator-zh_cn/
 [11]: http://weibo.com/tinylaborg
 [12]: http://weibo.com/wuzhangjin
