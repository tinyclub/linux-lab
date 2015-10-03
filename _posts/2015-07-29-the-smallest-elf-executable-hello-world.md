---
title: 史上最小可执行 ELF 文件
author: Wu Zhangjin
album: C 语言编程透视
layout: post
permalink: /the-smallest-elf-executable-hello-world/
tags:
  - 45
  - ELF
  - 可执行文件
  - 最小
  - Linux
categories:
  - C
  - 系统裁剪
---
 
> by Falcon of [TinyLab.org][1]
> 2015/07/29

笔者最早在 2008 年写过一篇[《如何为可执行文件“减肥”》][2]。

该文通过各种努力，把可打印 `Hello World` 的 Linux ELF 可执行文件，从 6442 个字节，减少到 76 字节。

并且早期也有在知乎的相关问题下回复：[Windows 上最小的“HelloWorld.exe”能有多小？][3]，不过反响较小。

最近笔者抽空整理该文，并在重读 [A Whirlwind Tutorial on Creating Really Teensy ELF Executables for Linux][4]（史上最小 Linux ELF 文件，即 [ELF Kickers][5] 作者，不过该 ELF 只能产生一个返回值）的基础上，做了进一步突破，先后造出了 52 字节和 45 字节的 ELF 可执行文件，并且可以打印 `Hello World`。

而社区的早期纪录是 59 字节，也是 ELF Kickers 作者创造的，文件在 [ELF Kickers][6] 的 `tiny/hello`：

    $ git clone https://github.com/BR903/ELFkickers
    $ cd ELFkickers
    $ wc -c tiny/hello
    59 tiny/hello

其中 52 字节的突破主要借鉴 [A Whirlwind Tutorial on Creating Really Teensy ELF Executables for Linux][4] 关于把 ELF 程序头完全合并进 ELF 文件头的努力，而 45 字节的突破除了继承自己早期那篇文章的用参数赋值的想法外，还有些幸运的因素在（通过非法系统调用可以正常退出程序）。

最后，不仅获得了一个二进制只有 8 字节的 `hello.s`：

<pre>.file "hello.s"
.global _start
_start:
    popl %eax
    popl %ecx
    mov $5, %dl
    int $0x80
    loop _start
</pre>

最后，完全把 ELF 程序头和代码合并进了 ELF 文件头，而且可以打印字符串。

而最重要的是，通过这个过程，可以透彻地理解 C 语言的开发过程，关于 C、汇编、操作系统背后的很多奥秘。

由于最近把早期的一些文章整理成了[《C 语言编程透视》][7]一书，相关记录也更新到了该书。

如果想了解该 ELF 裁剪的细节，请移步[《C 语言编程透视》GitBook 版][8]，并阅读第 10 章。

欢迎做进一步交流，关注我们的微博[@泰晓科技][9] 或者关注我们的开源书籍项目 [Github 源码仓库][10]。也欢迎提交 Pull Request。





 [1]: http://tinylab.org
 [2]: /as-an-executable-file-to-slim-down/
 [3]: http://www.zhihu.com/question/21715980
 [4]: http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
 [5]: http://www.muppetlabs.com/~breadbox/software/elfkickers.html
 [6]: https://github.com/BR903/ELFkickers
 [7]: http://tinylab.org/open-c-book
 [8]: http://tinylab.gitbooks.io/cbook
 [9]: http://weibo.com/tinylaborg
 [10]: https://github.com/tinyclub/open-c-book
