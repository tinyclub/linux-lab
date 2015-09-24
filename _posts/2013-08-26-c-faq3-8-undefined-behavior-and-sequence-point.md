---
title: '[c-faq] 3.8-未定义行为与sequence point'
author: Wen Pingbo
album: C FAQ
layout: post
permalink: /c-faq3-8-undefined-behavior-and-sequence-point/
views:
  - 164
tags:
  - c
  - faq
  - sequence point
categories:
  - C
  - Computer Language
---

> by PingboWen of [TinyLab.org](http://tinylab.org)
> 2013/08/24

在 C 语言中，我们经常会碰到很多新奇的写法，比如：

    a[i]=i++;
    i++ * i++;
    i = i++;
    a^=b^=a^=b; //swap a, b

而这些表达式，虽然看上去很简洁，但是结果可能是不确定的。因为 ANSI C 中并没有对这些行为定义。

通常来说，在 C 中，有 3 种情况：

 * implementation-defined：就是 ANSI C 标准中有明确定义的，编译器必须保证标准所列的特性都已经实现
 * unspecified：尽管 ANSI C 中有明确定义，但是并没有明确说明应该具有那些特性，也就是说编译器可以自己做一种选择，只要实现了标准所定义的
 * undefined：未定义，也就是编译器可以不具有这种功能或特性，甚至不接受带有这种特性的程序

现在，我们再回过头来，看看这些新奇的写法。发现这些语句都有一个特点：在同一个语句中，一个 object 被引用两次以上，且值被修改。

要解释这种复杂的表达式，我们先来看一个在 C/C++ 语言中经常提到的一个概念： sequence point 。我们可以把它翻译为 "顺序点"，但是我更愿意翻译为检查点。

sequence point 在 C 标准文档中是这样定义的：

> A sequence point is a point in time at which the dust has settled and all side effects which have been seen so far are guaranteed to be complete.

翻译过来，意思就是说检查点是指在这个点之前的所有操作和副效果，都会被处理完，然后才会处理检查点之后的东西。   在 ISO IEC 的 Annex C 中，对一个检查点，有明确的说明。说的有点细，我们可以借用 c-faq 上所总结的 3 点：

> 1. at the end of the evaluation of a full expression (a full expression is an expression statement, or any other expression which is not a subexpression within any larger expression);
> 2. at the `||`, `&&`, `?:`, and comma operators;
> 3. at a function call (after the evaluation of all the arguments, and just before the actual call).

也就是说在一个表达式的赋值最后、在 `||`，`&&`，`?:` 和逗号、在函数调用的地方，都是检查点。

也许现在，你可能还是不能很好的把握 sequence point 。那我们以 自增/自减 操作为例，进行一下说明：

我们都知道自增和自减操作都有两步语义，一个是赋值，另外一个是 加/减。哪个先做？那就看是 `++i`,  还是 `i++` 了，但是另外一个什么时候做， ANSI C 没有定义， ANSI C 只定义了在检查点的地方，你把这些副操作全部做了就 OK 。但是如果在一个检查点内部，副操作应该什么时候做？那就看你用的是哪个编译器了。

再看 `i=i++;` 这个语句。检查点在语句结束的地方，但是在检查点内部，却两次引用了 i ，且修改了 i 的值。那么最后 i 的值是加了 1, 还是没变？由于 ANSI C 没有明确定义，所以只能看编译器是怎么处理这种情况了。换句话说，在不同的编译器下，这个语句的执行结果可能不一样，这在程序中是绝对不允许的！

开头所列的其他例子，都是这个道理。那么这个表达式是否有问题： `i++ && i++ ？`   这个表达式是正确的， WHY ？回过头来看检查点的定义， `&&` 是一个检查点，也就是说副操作执行的顺序被 ANSI C 严格定义了 , 那么也就不存在二义性问题了。
