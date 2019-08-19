---
layout: post
author: 'Wu Zhangjin'
title: "11 个 Makefile 进阶用法"
draft: false
top: true
license: "cc-by-nc-nd-4.0"
permalink: /makefile-deep-usage/
description: "本文汇总了诸多 Makefile 进阶用法，提升 Makefile 阅读和编写效率。"
category:
  - Makefile
tags:
  - 立即赋值
  - 延迟赋值
  - .DEFAULT_GOAL
  - MAKECMDGOALS
  - MAKEOVERRIDES
  - tracing
  - debugging
  - info
  - warning
  - error
  - wildcard
  - 调用 shell
---

> By Falcon of [TinyLab.org][1]
> Aug 01, 2019

过去数月，笔者一直在重构开发了数年的开源项目：[Linux Lab](http://tinylab.org)（Linux 内核实验室）。

在开发过程中，需要跟 Makefile 打交道，完善功能，优化速度，提升体验。

数月下来，积累了不少 Makefile 实战技巧。回过来看，之前对 Makefile 的熟知程度只能说是幼儿园托班水平 ;-)

本文汇总了诸多 Makefile 进阶用法，便于提升 Makefile 阅读和编写效率，文末有彩蛋 ^_^

## 立即赋值（:=）和延迟赋值（=）

* `:=`： 强制按先后顺序执行，立即赋值。
*  `=`：赋值的结果会等到整个路径执行完再决定，后面的会覆盖前面的，延迟赋值。

按照常规逻辑，建议默认选用 ":="。

实例如下：

    $ cat Makefile

    a = foo
    b1 := $(a) bar
    b2 = $(a) bar
    a = xyz

    all:
    	@echo b1=$(b1)
    	@echo b2=$(b2)

    $ make
    b1=foo bar
    b2=xyz bar

## 变量赋值 和 目标执行 之间的时序关系

这里再看看变量赋值和编译目标之间的关系，以及不同的变量传递和设置方式。

先看看通常可能会传递参数的方式，大家觉得哪个会生效呢？

    $ make a=b target
    $ make target a=b
    $ a=b make target
    $ export a=b && make target

另外，这种情况下，target1 和 target2 打印的变量一样吗？

    a = aaa

    test1:
    	echo $a

    a = bbb

    test2:
    	echo $a

下面看一个案例（注意：target 下命令缩进必须是一个 TAB）。

    $ cat Makefile

    a ?= aaa
    b := $(a)
    c = $(a)

    a_origin = $(origin a)
    b_origin = $(origin b)
    c_origin = $(origin c)

    all:
    	@echo all:$(a)
    	@echo all:$(b)
    	@echo all:$(c)
    	@echo all:$(a_origin)
    	@echo all:$(b_origin)
    	@echo all:$(c_origin)

    a = bbb
    b := $(a)
    c = $(a)

    test1:
    	@echo test1:$(a)
    	@echo test1:$(b)
    	@echo test1:$(c)
    	@echo test1:$(a_origin)
    	@echo test1:$(b_origin)
    	@echo test1:$(c_origin)

    a = ccc
    b := $(a)
    c = $(a)

    test2:
    	@echo test2:$(a)
    	@echo test2:$(b)
    	@echo test2:$(c)
    	@echo test2:$(a_origin)
    	@echo test2:$(b_origin)
    	@echo test2:$(c_origin)

    a = ddd

看看执行情况。

**关于 变量赋值 和 目标中的变量引用 的顺序**

首先，执行默认 target，也就是第一个出现的 target，这里是 "all"：

    $ make
    all:ddd
    all:ccc
    all:ddd
    all:file
    all:file
    all:file

比较奇怪的是？为什么 "all" 目标刚好在这三条之后，却拿到了 ddd, ccc 和 ddd 呢？

    a ?= aaa
    b := $(a)
    c = $(a)

为什么不是 aaa, aaa 和 aaa 呢？

接着，执行 test1, test2：

    $ make test1
    test1:ddd
    test1:ccc
    test1:ddd
    test1:file
    test1:file
    test1:file

    $ make test2
    test2:ddd
    test2:ccc
    test2:ddd
    test2:file
    test2:file
    test2:file

发现，test1, test2 都一样？所以，结论是，Makefile 中所有变量赋值的语句在所有 target 之前完成，跟变量赋值与 target 的相对位置无关。

另外，我们可以看到 b 没有跟上 c 的节奏，拿到 ccc 就不再跟 c 一样去拿最后设置的 ddd 了，体现了 “:=” 的 “立即赋值”，而 c 一直等到了 Makefile 最后的 a。另外，三个变量最后的值都是文件内部赋值，所以 origin 是 file.

**通过命令行赋值**

    $ make a=fff
    all:fff
    all:fff
    all:fff
    all:command line
    all:file
    all:file

发现命令行覆盖了 Makefile  中所有的变量赋值，a 的优先级很高。

    $ make b=fff
    all:ddd
    all:fff
    all:ddd
    all:file
    all:command line
    all:file

由于 a 和 c 没用引用 b，所以这里只有 b 发生了变化。

    $ make c=fff
    all:ddd
    all:ccc
    all:fff
    all:file
    all:file
    all:command line

同样，a 和 b 没有引用 c，只有 c 发生了变化。

**通过环境变量赋值**

    $ a=xxx make
    all:ddd
    all:ccc
    all:ddd
    all:file
    all:file
    all:file

发现并没有生效，还是用的 make 的内部赋值语句。

    $ a=xxx make -e
    all:xxx
    all:xxx
    all:xxx
    all:environment override
    all:file
    all:file

确实都改了，所以要让环境变量生效，得给 make 传递 `-e`。

    $ b=xxx make -e
    all:ddd
    all:xxx
    all:ddd
    all:file
    all:environment override
    all:file

这个的效果同样：

    $ export b=fff
    $ make -e
    all:ddd
    all:fff
    all:ddd
    all:file
    all:environment override
    all:file

只是建议不要随便用 `-e`，万一有人在 `.bashrc` 或者 `.profile` 提前 export 了一个环境变量，自己没有主动设置的话，可能就会怀疑人生了，程序行为可能会出人意料而很难 debug。

**环境变量和命令行哪个优先**

    $ b=xxx make -e b=yyy
    all:ddd
    all:yyy
    all:ddd
    all:file
    all:command line
    all:file

可以看到 命令行 优先。

小结一下：

* 所有变量语句的执行在 target 下的语句之前（每个 target 所属语句有一个 TAB 的缩进）。
* 变量 override 优先级：`command line > environment override > file`

最后布置一个小作业？这个的结果是什么呢？

    $ b=xxx make -e b=yyy all b=zzz test2 b=mmm

## 如何获取 make 传递的所有参数和编译目标

先来看看这样一个问题：

    $ make test1 test2 test3 a=123 b=456

如何在 Makefile 中获取 `make` 命令后面的所有参数呢？

在 Shell 脚本里头这个是很常用的，参数列表：`$1`, `$2`, `$3`, `$4` ... `$@`

同样地，在 Makefile 中有这样的需求，比如说想看看到底有没有传进来某个参数，根据参数不同做不一样的动作。

`make` 后面的参数有两种类型，一种是命令行变量，一种是编译目标。

这两个分别存放在 `MAKEOVERRIDES` 和 `MAKECMDGOALS` 变量中。

判断有没有传递某个编译目标，可以这么做：

    ifeq ($(filter test1, $(MAKECMDGOALS)), test1)
        do something here
    endif

上述代码实际是也相当于可以用来把一些变量赋值放到目标相关的代码块中。这个可以大幅提升大型 Makefile 的执行效率，在执行特定的目标时，不去执行无关的代码块。

判断有没有传递某个参数，可以这么做：

    ifeq ($(origin a), command line)
        do something here
    endif

当然，也可以从 `MAKEOVERRIDES` 中做 `findstring` 检查，只是没有用 `origin` 来得简单。

## Makefile 调试与跟踪方法一览

**Debugging**

    $ make --debug xxx

  展开整个 make 解析和执行 xxx 的过程。

**Tracing**

    $ make --trace xxx

  展开 `xxx` 目标代码的执行过程，有点像 Shell 里头的 `set -x`。该功能在 make 4.1 及之后才支持。

**Logging**

    $(info ...)
    $(warning ...)
    $(error ...)

  `error` 打印日志后立即退出，非常适合已经复现的错误。

**Environment dumping**

    $ make -p xxx > xxx.data.dump

  打开 `xxx.data.dump` 找到 xxx 的位置可以查看相关变量是否符合预期。

## Makefile 与 Shell 中的文件名处理差异

Makefile 中有类似 Shell 的 `dirname` 和 `basename` 命令，它们是：`dir`, `basename`, `notdir`，但是用法有差异，千万别弄混，下面来一个对比。

    $ cat Makefile
    makefile:
    	@echo $(dir $a)
    	@echo $(basename $a)
    	@echo $(notdir $a)

    shell:
    	@echo $(shell dirname $a)
    	@echo $(shell basename $a)

    $ make makefile a=/path/to/abc.efg.tgz
    /path/to/
    /path/to/abc.efg
    abc.efg.tgz
    $ make shell a=/path/to/abc.efg.tgz
    /path/to
    abc.efg.tgz

    $ make makefile a=/path/to/
    /path/to/
    /path/to/

    $ make shell a=/path/to/
    /path
    to

    $ make makefile a=/path/to
    /path/
    /path/to
    to


通过对比，可以看到，Makefile 的 `dir` 和 `basename` 跟 Shell 中的 `dirname` 和 `basename` 有非常微妙的差异。如果理解成等价，那就很麻烦了，因为拿到的结果并不如预期。

对于文件，有如下等价关系：

  参数                 |  动作       | Makefile     |   Shell
  ---------------------|-------------|--------------|--------------
  /path/to/abc.efg.tgz |  取目录     |  dir         | dirname
  同上                 |  取文件名   |  notdir      | basename

并且需要注意，Makefile 的 `dir` 取到的目录带有 `/` 后缀，而 Shell 的 `dirname` 结果不带 `/`。对于目录，两者的认知千差万别，Makefile 的 `dir` 和 `basename` 拿到的都是目录，而 Shell 能够拆分出父目录和字目录的文件名。如果要对齐到 Makefile，用 `dir` 和 `notdir` 起到类似 Shell `dirname` 和 `basename` 的效果，得先 strip 掉后面的 '/'。

下面改造一下：

    $ cat Makefile
    makefile:
    	@echo $(patsubst %/,%,$(dir $(patsubst %/,%,$a)))
    	@echo $(notdir $(patsubst %/,%,$a))

    shell:
    	@echo $(shell dirname $a)
    	@echo $(shell basename $a)

    $ make makefile a=/path/to/abc.efg.tgz
    /path/to
    abc.efg.tgz
    $ make shell a=/path/to/abc.efg.tgz
    /path/to
    abc.efg.tgz

    $ make shell a=/path/to/
    /path
    to
    $ make makefile a=/path/to/
    /path
    to

可以看到，改造完以后，结果跟 Shell 结果对齐了。

## 在 Makefile 表达式中使用逗号和空格变量

逗号和空格是 Makefile 表达式中的特殊符号，如果要用它们的愿意，需要特别处理。

    empty :=
    space := $(empty) $(empty)
    comma := ,

## 在 Makefile 中对软件版本号做差异化处理

Makefile 通常需要根据软件版本传递不同的参数，所以经常需要对软件版本号做比较。

例如，在 Linux 4.19 之后删除了 oldnoconfig，并替换为了 olddefconfig，所以之前用到的 oldnoconfig 在新版本用不了，直接改掉老版本又用不了，得做差异化处理。

大家觉得应该怎么处理呢？先思考一下再看答案吧。

下面贴出关键片段：

    LINUX_MAJOR_VER := $(subst v,,$(firstword $(subst .,$(space),$(LINUX))))
    LINUX_MINOR_VER := $(subst v,,$(word 2,$(subst .,$(space),$(LINUX))))

    ifeq ($(shell [ $(LINUX_MAJOR_VER) -lt 4 -o $(LINUX_MAJOR_VER) -eq 4 -a $(LINUX_MINOR_VER) -le 19 ]; echo $$?),0)
        KERNEL_OLDDEFCONFIG := oldnoconfig
    else
        KERNEL_OLDDEFCONFIG := olddefconfig
    endif

类似地，如果要同时兼容不同版本的 GCC，得根据 GCC 版本传递不同的编译选项，也可以像上面这样去做识别，Linux 源码下就有很多这样的需求。

不过它用了 `try-run` 的方式实现了一个 `cc-option-yn` （见 `linux-stable/scripts/Kbuild.include`），它是试错的方式，避免了堆积大量的判断代码，不过这里用的版本判断不多，而且调用这类 target 开销较大，没必要，直接加判断即可。

需要注意的是，考虑到版本号命名的潜在不一致性，比如说，后面加个 `-rc1`，再加点别的什么，判断的复杂度会增加不少，所以，这类逻辑可以替换为其他方式，比如说，这里可以直接去 `linux-stable/scripts/Makefile` 下用 grep 查询 `olddefconfig` 是否存在：

    KCONFIG_MAKEFILE := $(KERNEL_SRC)/scripts/kconfig/Makefile
    KERNEL_OLDDEFCONFIG := olddefconfig
    ifeq ($(KCONFIG_MAKEFILE), $(wildcard $(KCONFIG_MAKEFILE)))
      ifneq ($(shell grep olddefconfig -q $(KCONFIG_MAKEFILE); echo $$?),0)
        ifneq ($(shell grep oldnoconfig -q $(KCONFIG_MAKEFILE); echo $$?),0)
          KERNEL_OLDDEFCONFIG := oldconfig
        else
          KERNEL_OLDDEFCONFIG := oldnoconfig
        endif
      endif
    endif

## 修改默认执行目标的简单方法

如果不指定目标直接敲击 make 的话，Makefile 中的第一个目标会被执行到。这个是比较自然的逻辑，但是有些情况下，比如说，在代码演化以后，如果需要调整执行目标的话，得把特定目标以及相应代码从 Makefile 中搬到文件开头，这个改动会比较大，这个时候，就可以用 Makefile 提供的机制来修改默认执行目标。

来看看上面那个例子：

    $ make -p | grep makefile | grep -v ^#
    .DEFAULT_GOAL := makefile
    makefile:

可以看到，`makefile` 被赋值给了 `.DEFAULT_GOAL` 变量，通过 `override` 这个变量，就可以设置任意的目标了，把默认目标改为 `shell` 看看。

    $ make -p .DEFAULT_GOAL=shell a=/path/to/abc.efg.tgz | grep ^.DEFAULT_GOAL
    .DEFAULT_GOAL = shell

确实可以改写，这个要永久生效的话，直接加到 Makefile 中即可：

    override .DEFAULT_GOAL := shell

## 检查文件是否存在的两种方法

在 Makefile 中，通常需要检查一些环境或者工具是否 Ready，检查文件是否存在的话，可以用 `wildcard` 展开再匹配，也可以用 Shell 来做判断。

    ifeq ($(TEST_FILE), $(wildcard $(TEST_FILE)))
        $(info file exists)
    endif

    ifeq ($(shell [ -f $(TEST_FILE) ]; echo $$?), 0)
        $(info file exists)
    endif

第二种方法比较自由，可以扩展用来检查文件是否可执行，也可以调用 grep 做更多复杂的文本内容检查。在复杂场景下，通过第二种方法调用 Shell 是比较好的选择。

## 如何类似普通程序一样把目标当变量使用

如果执行 `make test-run arg1 arg2` 想达到把 `arg1 arg2` 作为 `test-run` 目标的参数这样的效果该怎么做呢？可以用 `eval` 指令，它能够动态构建编译目标。

通过 eval 指令把 `arg1 arg2` 这两个目标变成空操作，即使有 `arg1 arg2` 这样的目标也不再执行,  然后执行 `test-run` 运行。

大概实现为：

    $ cat Makefile

    # Must put this at the end of Makefile, to make sure override the targets before here
    # If the first argument is "xxx-run"...
    first_target := $(firstword $(MAKECMDGOALS))
    reserve_target := $(first_target:-run=)

    ifeq ($(findstring -run,$(first_target)),-run)
      # use the rest as arguments for "run"
      RUN_ARGS := $(filter-out $(reserve_target),$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
      # ...and turn them into do-nothing targets
      $(eval $(RUN_ARGS):;@:)
    endif

    test-run:
        @echo $(RUN_ARGS)


    $ make test-run test1 test2

这个的实际应用场景有，比如说想在外面的目标中调用内核的编译目标，通常得进入内核源码，再执行 `make target`，可能得写很多条这样的目标：

    kernel-target1:
    	@make target1 -C /path/to/linux-src

    kernel-target2:
    	@make target2 -C /path/to/linux-src

有了上面的支持，就可以实现成这样：

    kernel-run:
    	@make $(arg1) -C /path/to/linux-src

使用时也不复杂，内核的各种目标都可以作为参数传递进去：

    $ make kernel-run target1
    $ make kernel-run target2

虽然说，上述 arg1，也可以这样写：

    $ make kernel-run arg1=target1
    $ make kernel-run arg1=target2

但是在使用效率上明显不如前者来得直接。

## Makefile 实例模板

本文的内容大部分都汇整到了 [Linux Lab: examples/makefile/template](https://gitee.com/tinylab/linux-lab/tree/master/examples/makefile/template)。

## 送您一枚免费体验卡

更多 Linux 精彩欢迎透过下方免费体验卡访问『Linux 知识星球』：

![『Linux 知识星球』免费体验卡](http://tinylab.org/images/xingqiu/planet-free-card.jpg)


[1]: http://tinylab.org
