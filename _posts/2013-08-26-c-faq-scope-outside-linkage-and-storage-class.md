---
title: '[c-faq] 番外-scope, linkage and storage class'
author: Wen Pingbo
album: C FAQ
layout: post
permalink: /c-faq-scope-outside-linkage-and-storage-class/
tags:
  - faq
  - linkage
  - scope
  - storage class
categories:
  - C
---

> by PingboWen of [TinyLab.org](http://tinylab.org)
> 2013/08/24

在看 c-faq ，和 c 或者 c++ 的 RFC 的时候，经常见到一些 scope, linkage 和 storage class 的字眼，让人摸不着头脑！下面就这些概念做一些说明：

其实这些概念，都是用来描述一个标识符（ identifier ）的，比如：变量标识符，函数标识符

## scope

 scope ，字面意思就是范围。 IBM 对 C 和 C++ 语言的定义文档中，对 scope 是这样描述的：

> The scope of an identifier is the largest region of the program text in which the identifier can potentially be used to refer to its object. In C++, the object being referred to must be unique. However, the name to access the object, the identifier itself, can be reused. The meaning of the identifier depends upon the context in which the identifier is used. Scope is the general context used to distinguish the meanings of names.

意思就是，标识符的 scope 是在程序上下文中，用来确定，该标识符是对应与哪个 object 的。其实说白了，就是在程序中，一个变量只能有一个定义，但可以有多个声明，那么每个声明是对应与那个具体的变量的呢？   就是靠 scope 来确定。

在 C 和 C++ 语言中，有多种 scope ，具体如下：

C | C++
block | local
function | function
function prototype | function prototype
file (global) | global namespace
              | namespace
              | class

举个例子：

    int x; //file scope
    
    int f()
    {
    	int x=10; //block scope
    }

## linkage

刚才的 scope ，只是在一个文件中，或者说一个 translation unit 中来确定每个标识符与 object 之间的对应关系。但是如果在两个文件中，有相同的标识符，那又怎么确定呢？

那就需要 linkage 这个属性，来确定。 IBM 中的 C 和 C++ 语言规范是这样来定义 linkage 的：

> Linkage determines whether identifiers that have identical names refer to the same object, function, or other entity, even if those identifiers appear in different translation units. The linkage of an identifier depends on how it was declared. There are three types of linkages: external, internal, and no linkage.

从上可以看出，有 3 中 linkage ： external, internal 和 no linkage 

有 external linkage 的标识符，对于其他编译单元是可见的，就相当于那些 extern 的全局变量之类的。

有 internal linkage 的标识符，只能在当前编译单元可见，也就是只能在当前文件中被引用。

no linkage 的标识符，那它可见的范围就由它的 scope 属性决定了。

## storage class

可能上面讲的那个 linkage ，你还有点疑惑：怎样来确定一个 identifier 的 linkage 呢？

这就要靠 storage class 关键字了。在 ISO/IEC 9899:201x 中，有如下 storage class 关键字：

* typedef
* extern
* static
* _Thread_local
* auto
* register

（这个地方， typedef 虽然是 storage class ，这只是在语法上的考虑，因为 typedef 和其他关键字的语法相同，但并不能决定一个 identifier 的属性）

是不是很熟悉？其实对于一个变量，它的默认存储周期，范围和 linkage 属性，是由该变量声明的位置决定的：是在一个 block 中声明的，还是在函数外声明的。你也可以用 storage class 的关键字对变量进行显示的声明，来决定它的属性。

对于一个函数，它可用的 storage class 只有 extern 和 static 。

具体到，那个关键字声明的变量，具有哪些属性，就不用我来说了吧，呵呵。

想要看例子的，可以到[这里](http://www.prismnet.com/~mcmahon/Notes/attributes.html)。

IBM 对 C 和 C++ 的语言规范，可以看[这里](http://publib.boulder.ibm.com/infocenter/macxhelp/v6v81/index.jsp)。
