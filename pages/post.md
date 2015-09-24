---
title: 投稿
tagline: 欢迎投递原创稿件、工作机会、求职简历等
author: Wu Zhangjin
layout: page
group: navigation
permalink: /post/
order: 30
---

泰晓科技 作为一个 Android / Linux 原创交流平台，持续欢迎大家的参与。

而参与的最好方式莫过于创作并分享，我们欢迎各类 Android / Linux 原创、翻译文章，也欢迎发布工作机会，递送求职简历。

当然，为了提高稿件、工作机会和简历的质量，我们会安排严格的评审。

下面是一般的稿件投递过程。

## 投稿过程

### Fork / Star / Clone 文章仓库

我们的文章仓库托管在 [Github][1] 上，可用如下命令下载：

    $ git clone https://github.com/tinyclub/website.git && cd website

如果希望持续参与/关注我们的原创进程，请 Fork / Start 我们的仓库。

### 搭建 Jekyll 工作环境

    $ sudo apt-get install ruby ruby-dev rake nodejs
    $ sudo gem sources -r http://rubygems.org/
    $ sudo gem sources -r https://rubygems.org/
    $ sudo gem sources -a http://ruby.taobao.org/
    $ sudo gem install jekyll

### 撰写稿件

通过下面的命令创建一份模板，然后采用 Markdown 撰写。

    $ rake post

或者

    $ tools/post

后者是前者的封装，可以简化命令行的输入。

Markdown 基本用法请参考 [Markdown 语法说明][2] 以及上述命令创建的模板文件中的说明。

如果希望使用更多样式，可参照 `_posts` 下的其他文章。

### 编译文稿

    $ jekyll s --limit_posts 1

或者

    $ tools/start

**注**：`--limit_posts 1` 只编译最新的一篇，会大大加快编译和测试效率。

### 浏览文稿

通过浏览器打开：<http://localhost:4000> 进行查看。

### 递送稿件

测试完无误后即可通过 Github 发送 Pull Request 进行投稿。

这一步要求事先做如下步骤：

* 在 Github Fork 上述[文章仓库][1]
* 您在本地修改后先提交到刚 Fork 的仓库
* 然后再进入自己仓库，选择合并到我们的 master 仓库

提交 Pull Request 后，我们会尽快安排人员评审，评审通过后即可进入网站正常发布。

## 文章模板说明

我们通过 `rake post` 或者 `tools/post.sh` 可以创建一份文章模板，这里对该模板做稍许说明，更多内容请阅读模板本身。

该模板包括两大部分，第一部分是用两个 `---` 括起来的文件头，剩下的部分为文章正文。

* 文件头包含文章的关联信息，`jekyll` 模板系统用它来构建文章页面
* 文件正文即普通的 Markdown 文件主体，基本遵循 Markdown 规范

模板基本样式如下：

    ---
    layout: post
    author: "Your Name"
    title: "new post"
    permalink: /new-post-slug/
    description: "summary"
    category:
      - category1
      - category2
    tags:
      - tag1
      - tag2
    ---
    
    
    > By YOUR NICK NAME of TinyLab.org
    > 2015-09-21
    
    
    
    文章正文
    
    
    

模板文件头中的关键字大部分为 `jekyll` 默认支持，我们加入了少许关键字，这里一并说明：

| 关键字 | 说明              |  备注     |
|:------:|-------------------|---------------|
|layout  | 文章均为 post     | **必须**
|author  | 作者名，同 `_data/people.yml` | **必须**
|title   | 标题名，支持中、英文      | **必须**
|permalink| 英文短链接，不能包含中文 | **必须**
|tagline  | 子标题/副标题            | 可选
|description| 文章摘要              | 可选
|album      | 所属文章系列/专题     | 可选
|group      | 默认 original，可选 translation, news, resume or jobs, 详见 `_data/groups.yml` | 可默认
|category   | 分类，每行一个，至少一个 | **必须**
|tags       | 标签，每行一个，至少一个 | **必须**

## 完善作者信息

为了方便读者和潜在合作伙伴联系到您，请参考如下表格在 `_data/people.yml` 编辑作者信息并提交 Pull Request 入库。

更多信息说明如下，以网站帐号 `admin` 为例，即 `_data/people.yml` 中左侧的 `admin:`：

|属性    |   属性值      |  说明                    |
|:------:|:-------------:|--------------------------|
|name    | 泰晓科技      | 对应更详细的中文名或者全名
|nickname| tinylab       | 网络昵称或者英文名
|archive | true          | 指向作者所有文章的链接
|article | true          | 自动生成当前浏览文章的的二维码，方便手机阅读
|site    | tinylab.org   | 作者个人站点地址，请不要写 `http://` 头
|email   | xxx@gmail.com | 作者邮箱
|github  | tinyclub             | 作者 github 帐号
|weibo   | tinylaborg           | 新浪微博帐号，务必配置并使用短域名，否则必须使用 `u/xxx`
|weibo-qrcode  | false          | 新浪微博的二维码，本站可自动生成，无须设置
|wechat        | tinylab-org    | 微信或者公众号
|wechat-qrcode | true           | 暂时无法自动生成，需要显示二维码必须先生成一份传到 `images/wechat`，并以 `wechat` 名字命名，同时设置这里为 true
|sponsor       | weixin-pay-admin-9.68 | 如果希望获得打赏，请这样命名二维码图片名：weixin-pay-*author*-*money*
|sponsor-qrcode| true                  | 图片请存到 `images/sponsor` 并设该项为 true
|info          | ...                   | 建议介绍专业、兴趣、特长等，如较多，请用 `;` 分割，以便系统自动分段处理。
|--------------|-----------------------|----------------|




 [1]: https://github.com/tinyclub/website.git
 [2]: http://wowubuntu.com/markdown/
