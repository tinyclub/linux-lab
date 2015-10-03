---
title: 编译 Python 源代码 py 成字节码 pyc
author: Wu Zhangjin
layout: post
permalink: /faqs/compile-python-from-py-to-pyc/
tags:
  - pyc
categories:
  - Python
---

* 问题描述

  Python 作为解释型语言，也可以编译成 pyc，在一定程度上可以保护源代码。如果想做一定的优化，则可以编译成 pyo。

* 问题分析

  python 提供了一个 py_compile 模块可以直接完成这个编译的工作。

* 解决方案

      $ python -m py_compile test.py
      $ python -O -m py_compile test.py

  注：需要说明的是，类似 java, c 等各类代码一样，pyc 也是可以反编译的，这个工具就是 [uncompyle2][1]。

 [1]: https://github.com/wibiti/uncompyle2
