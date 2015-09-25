---
title: 'Google Script: Get Started'
author: Wen Pingbo
layout: post
permalink: /google-script-get-started/
tags:
  - Google Script
  - JavaScript
categories:
  - Life
---

> by WEN Pingbo of [TinyLab.org][1]
> 2014/11/02

Google Script 是 Google 最近推出来的轻应用开发平台. 和 Google App Engine 有点类似. 不过 Google Script 更加专注于与 Google 自家相关产品进行互动. 说白了,其实就是 Gmail, Google Maps, Google Translate, Google Docs 等产品提供了很多接口供 Google Script 用. 而 Google Script 本身是基于 Javascript 的. 也就是说现在你可以写一些 JavaScript 脚本来控制 Google 的一些应用, 来实现一些比较实用的功能. 而整个 Google Script 编写过程, 都是在网页端完成的, 连脚本调试都是. 这一点不得不佩服 Google. 那到底怎样去使用 Google Script 呢? 这里以 Gmail 相关的一个脚本为例来做说明. 其实我也正是因为这个问题, 才使用 Google Script 的.

之前, 我的 Gmail 里订阅了很多 maillist. 但这也带来了一个问题, 每天总有一些人往这些 maillist 发一些垃圾邮件. 之前是在 Gmail 里创建一个 filter 来把这个 maillist的所有邮件都归类到一个文件夹内, 然后再创建另外一个 filter 把一些带有我感兴趣的关键字的邮件放到我的收件箱内. 但这种做法也给了垃圾邮件机会. 有时我的邮箱莫名其妙的就多了一些垃圾邮件, 让人很是烦恼. 所以想找一些更精细的工具来过滤垃圾邮件. 最后就找到了 Google Script.

既然我们要用 Google Script 来写一个脚本, 协助 Gmail 过滤收件箱内的垃圾邮件. 那么首先要搭建开发环境, 这里你要做的就是打开 https://script.google.com. 然后新建一个新脚本. 然后我写了如下脚本:

<pre>function markNullRecipientAsSpam() {
  var count = GmailApp.getInboxUnreadCount();
  Logger.log("count: %s", count);
  var threads = GmailApp.getInboxThreads(0, count);
  for(var i = 0; i &lt; threads.length; i++) {
    var mesg = threads[i].getMessages();
    if(mesg[0].getTo() == "" && mesg[0].getCc() == "" && mesg[0].getBcc() == "") {
      Logger.log("spam message: %s", mesg[0].getSubject());
      threads[i].moveToSpam();
    }
  }
}
</pre>

这个脚本很简单, 只有一个函数, 用于获取当前 Gmail 里的未读邮件, 遍历所有未读的邮件, 判断该邮件的收件人是否为空, 标题是否只是一个 &#8220;Re:&#8221;. 如果是, 那就把这封邮件标为垃圾邮件. 我这么做的原因, 是因为我发现我收到的大部分邮件, 都是通过邮件域投递过来的. 这种邮件它的收件人一般都是空的. 还有一些垃圾邮件, 要么主题为空, 或者只有一个简单的 &#8220;Re:&#8221;.

写完后, 我们可以点击 Run 来运行我们的脚本, 然后点击 View &#8211;> Log 来查看相关 Log. 当然, 我们可以在脚本里设置断点, 然后开始在线调试我们的脚本. 是不是感觉很强大. 而整个脚本会保存到你的 Google Drive 里.

脚本完成后, 为了让脚本自动运行. 我们可以给脚本设置触发器. 我这边设置的是每15分钟运行一次. 然后你就可以 Publish 你的脚本了.

现在 Google Script 还不是很完善, 很多功能都是处于 Preview 状态, 或者 Experimental. 但这个应用确实比较灵活, 特别是对于一个 Googler 来说. 赶快去尝试一下吧.





 [1]: http://tinylab.org
