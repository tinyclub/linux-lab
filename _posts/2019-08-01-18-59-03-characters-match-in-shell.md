---
layout: post
author: 'Wu Zhangjin'
title: "如何匹配字符或字符串的多次出现"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /characters-match-in-shell/
description: "本文介绍如何用 grep 匹配某个字符或者字符串的多次出现。"
category:
  - Shell
tags:
  - grep
  - 字符串匹配
  - 多次出现
---

> By Falcon of [TinyLab.org][1]
> Aug 01, 2019

经常需要匹配某个字符或者字符串的多次出现，但是很难记住，每次要的时候翻箱倒柜，特别痛苦，这里速记一下。

## 匹配所有连续出现 4 次及以上字符

    $ echo "0000aabbaabbbffffccc" | grep -oE "(\w)\1{3,}"
    0000
    ffff

## 匹配连续出现 2 次及以上的字符串

    $ echo "00xxyyxxyyxxyy000aabbaabbffccffccggccabababc" | grep -oE "(((\w){1,})[^\2])\1{1,}"
    xxyyxxyyxxyy
    aabbaabb
    ffccffcc
    ababab

## 匹配连续出现 2 次及以上指定字符串

    $ echo "00000aaabbaabbbffffccc" | grep -oE "(aabb){2,}"
    aabbaabb

  或者

    $ echo "00000aaabbaabbbffffccc" | grep -oE "(aabb)\1{1,}"
    aabbaabb

## 匹配连续出现 2 次及以上指定字符

    $ echo "00000baabbabb" | grep -oE "(a|b)\1{1,}"
    aa
    bb
    bb


## 小结


* 上面有几处用了引用 `\1`

  这个是很关键的用法，例如如果第 4 个用 "(a|b){2,}"，就可能匹配到 `ab, bb, aa, ba` 等所有条件，而 `ab` 和 `ba` 并不是我们想要的。

* 正则表达式的语法差异

 `grep` 不带 `-E` 的时候，`{}` 等符号都得带转义，不是很好用，另外，这个表达式在 `sed/awk` 可能又不同。大体的逻辑是一致的，这里不再比较差异，待后续再做记录。


[1]: http://tinylab.org
