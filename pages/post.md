---
title: 投稿
author: Wu Zhangjin
tagline: 欢迎投递原创稿件、工作机会、求职简历等
layout: page
highlight: false
permalink: /post/
order: 60
---

泰晓科技 作为一个 Linux 原创交流平台，热烈欢迎大家参与。

而参与的最好方式莫过于创作并分享。我们欢迎各类 Linux 原创、翻译文章，也欢迎发布工作机会，递送求职简历。

**树立行业影响力，换一种择业方式，从投递原创稿件开启！**

投稿就会受邀进入原创作者群，就有机会：

* 结交数百位来自企业一线的资深 Linux 工程师。
* 结识数十位各大新创企业或团队的老板和高管。
* 认识数十位来自各大高校的研究员和教授。

并且会赢得越来越多的读者朋友，从而不断提升行业影响力，为未来学习、择业和创业开辟新的途径。

为了提高内容质量，我们也会安排严格的评审。

下面是一般的稿件投递过程。

## 获取访问 “投稿仓库” 权限

首先去 [Gitee][5] 注册一个 gitee 账号。

以上操作完成后就可以访问 “投稿仓库” 了，泰晓科技的 “投稿仓库” 地址是: <https://gitee.com/tinylab/tinylab.org>。请注意访问该仓库时务必已经注册并登录 [Gitee][5] 且您的 gitee 账号拥有访问该仓库的相应权限。

## 撰写稿件

稿件的投稿和评审采用 [Gitee][5] 提供的标准的 “Fork + PullRequest 模式”，具体操作请参考 [Gitee 说明文档][6]。 

Fork 泰晓科技的 “投稿仓库” 完成后，就可以下载仓库了，假设您的 gitee 账号是 “jack”：

```
$ git clone https://gitee.com/jack/tinylab.org.git
$ cd tinylab.org
```

然后生成文章模板, slug 为泰晓科技站内链接（字符中间请使用 `-` 连接），title 为标题。举例如下

```
$ tools/post slug=this-is-my-link title="This is 我的文章标题"
Creating new post: ./_posts/2019-05-21-09-04-37-this-is-my-link.md
```

注：执行该命令可能会报系统缺少 rake 命令，无法运行，解决方法很简单，直接安装 rake 即可，譬如在 Ubuntu 系统上可以直接运行 `sudo apt-get install rake` 完成安装。

执行 `tools/post` 命令后会在 `./_posts/` 目录下生成名为类似 `2019-05-21-09-04-37-this-is-my-link.md` 的文章模版，该文件名由当前时间戳和您提供的 slug 字符串拼接组成。文章发表后可以通过链接 `http://tinylab.org/this-is-my-link` 访问该文章页面如下，其中红色框部分是该文章的站内链接，蓝色框部分是 title 的内容：

![tools/post1](/wp-content/uploads/2019/05/post1.png)

接着，参照模板编辑文章。

```
$ vim ./_posts/2019-05-21-09-04-37-this-is-my-link.md
```

打开后内容如下所示：

![tools/post2](/wp-content/uploads/2019/05/post2.png)

Markdown 基本用法请参考 [Markdown 语法说明][2] 以及上面创建的文章模板中的说明。

如果希望使用更多样式，可参照 `_posts/` 目录下的其他文章。

如果有附件或者图片资料，请创建目录 `wp-content/uploads/年/月/`，并添加资料进去，然后在文章中通过 Markdown 语法引用。引用图片的方式：

```
![图片简介](/wp-content/uploads/2017/09/xxx.png)
```

## 递送稿件

撰写完后即可通过 [Gitee][5] 发送 Pull Request 进行投稿。具体操作请参考 [Gitee 说明文档][6]。

这一步要求事先做如下准备：

  * 您在本地修改后先提交到刚 Fork 的自己账号的仓库
  * 然后再进入自己仓库，创建 PR 并选择合并到泰晓科技的 “投稿仓库” 的 gh-pages 分支

提交 Pull Request 后，我们会尽快安排人员评审，评审通过后即可发布。

## 文章模板说明

通过 `rake post` 或者 `tools/post` 可以创建一份文章模板，这里对该模板做稍许说明，更多内容请阅读模板本身。

该模板包括两大部分，第一部分是用两个 `---` 括起来的文件头，剩下的部分为文章正文。

* 文件头包含文章的基本信息，`jekyll` 模板系统用它来构建文章页面
* 文件正文即普通的 Markdown 文件主体，基本遵循 Markdown 规范

模板基本样式如下：

```
layout: post
author: 'Your Name'
title: "This is 我的文章标题"
draft: true
# tagline: " 子标题，如果存在的话 "
# album: " 所属文章系列/专辑，如果有的话"
# group: " 默认为 original，也可选 translation, news, resume or jobs, 详见 _data/groups.yml"
license: "cc-by-nc-nd-4.0"
permalink: /this-is-my-link/
description: " 文章摘要 "
category:
  - category1
  - category2
tags:
  - tag1
  - tag2
---

> By Your Nick Name of [TinyLab.org][1]
> May 21, 2019

文章正文
```



模板文件头中的关键字大部分为 `jekyll` 默认支持，我们加入了少许关键字，这里一并说明：

| 关键字    | 说明              |  备注     |
|:---------:|-------------------|---------------|
|layout     | 文章均为 post     | **必须**
|author     | 作者名，同 `_data/people.yml` | **必须**
|title      | 标题名，支持中、英文      | **必须**
|draft      | “是（true）”“否（false）”为草稿，缺省为 “是（true）”| **必须**
|permalink  | 英文短链接，不能包含中文 | **必须**
|tagline    | 子标题/副标题            | 可选
|description| 文章摘要              | **必须**，会优化搜索引擎效果
|plugin     | 仅支持mermaid，用于绘制流程图等| 可选
|album      | 所属文章系列/专题     | 可选，连载系列文章时推荐
|group      | 默认 original，可选 translation, news, resume or jobs, 详见 `_data/groups.yml` | 可默认
|category   | 分类，每行1个，至少1个，必须在`_data/categories.yml` | **必须**
|tags       | 标签，每行1个，至少1个，至多5个 | **必须**

## 完善作者信息

为了方便读者和潜在合作伙伴联系到您，请参考如下表格在 `_data/people.yml` 中编辑作者信息并发送 Pull Request 入库。

更多信息说明如下，以网站帐号 `admin` 为例，即 `_data/people.yml` 中左侧的 `admin:`：

|属性    |   属性值      |  说明                    |
|:------:|:-------------:|--------------------------|
|name    | 泰晓科技      | 对应中文名或者全名
|nickname| tinylab       | 网络昵称或者英文名
|archive | true          | 展示作者所有文章
|article | true          | 生成当前文章二维码，手机可扫码阅读
|site    | tinylab.org   | 作者个人站点地址，请不要写 `http://` 头
|email   | xxx@gmail.com | 作者邮箱
|github  | tinyclub             | 作者 github 帐号
|weibo   | tinylaborg           | 新浪微博帐号，务必事先配好短域名，否则须用 `u/xxx`
|weibo-qrcode  | false          | 新浪微博二维码，本站可自动生成，请保留为false
|wechat        | tinylab-org    | 微信或者公众号
|wechat-qrcode | true           | 暂时无法自动生成，需要显示二维码必须先生成一份传到 `images/wechat`，并以 `wechat` 帐号命名，该项为 true
|ali-pay       | ali-pay-admin-9.68 | 如希望获得支付宝打赏，请命名二维码图片为：ali-pay-*author*-*money*
|wechat-pay    | wechat-pay-admin-9.68 | 如希望获得微信打赏，请命名二维码图片为：wechat-pay-*author*-*money*
|sponsor       | wechat-pay            | 选择一种打赏方式（仅用于作者信息栏）
|sponsor-qrcode| true                  | 图片请存到 `images/sponsor` 并设该项为 true
|photo         | unicorn-wang          | 图片请存到 `images/photo`
|avatar        | photo                 | 可设置为 email, weibo, github, wechat, wechat-qrcode, photo
|info          | ...                   | 建议介绍专业、兴趣、特长等，如较多，请用 `;` 分割，以便自动分段展示
|--------------|-----------------------|----------------|

## 有关 “赞赏”

在辛苦撰写完文章之后，能获得读者的认可是一件美滋滋的事情。这里给大家解释一下目前的打赏机制，目前有两个途径可以获取打赏。

### 网站内

一个是 “泰晓科技” 网站上的二维码收款。文章在 “泰晓科技” 网站上发表后，读者可以通过扫描文章末尾的 “支付宝打赏” 或者 “微信打赏” 二维码给心仪的作者打赏。效果见本文末尾的 [打赏](#sponsor)。

<div class="reward-button">[赏](#sponsor)</div>

网站内的收款二维码配置方式见上一节：“完善作者信息”，这里再详细说明一下：

- 首先通过支付宝和微信导出收款二维码，保存为 jpg 格式，建议仅仅截取二维码部分，分辨率为 `150*150` 左右。

- 然后放置到 `images/sponsor` 下，并分别命名为 `ali-pay-*author*-*money*.jpg` 和 `wechat-pay-*author*-*money*.jpg`。

- 在 `_data/people.yml` 下相应配置 `ali-pay: ali-pay-*author*-*money*` 和 `wechat-pay: wechat-pay-*author*-*money*`。

具体可以参考 `admin` 等用户进行配置，修改完以后，类似文章一样，通过发送 Pull Request 上传即可。

### 公众号

另外一个是 “泰晓科技” 公众号上的 “赞赏用户”。所有文章在 “泰晓科技” 网站上发表后，我们会一并推送到 “泰晓科技” 的微信公众号上，公众号的读者也可以通过点击文章末尾的 “喜欢读者” 给心仪的作者打赏，效果如：

![tools/post4](/wp-content/uploads/2019/05/post4.png)

我们建议作者首先完善 **“泰晓科技” 网站上的二维码收款方式**，因为凡是发表在 “泰晓科技” 网站上的文章永久有效，只要文章写得足够精彩，就会有源源不断的读者为您赞赏。

关于 **微信公众号的 “赞赏用户”**，需要作者自己提供。另外根据微信公众号的要求，每个人的 “赞赏帐号” 需要采用公众号邀请的方式创建，邀请可以来自 “泰晓科技” 公众号，也可以是其他的公众号，但每个公众号目前最多只能邀请三个，目前 “泰晓科技” 公众号的邀请名额已满，所以如果作者自己已经拥有 “赞赏帐号”，请直接关联 “泰晓科技” 微信公众号就可以了。如果作者目前还没有自己的 “赞赏帐号”，也没有关系，“泰晓科技” 微信公众号提供缺省的打赏账户，一旦有读者为您的文章打赏，“泰晓科技” 将及时与您联系，并将打赏金额通过您方便的方式转赠给您。

 [1]: https://github.com/tinyclub/tinylab.org.git
 [2]: https://www.w3cschool.cn/markdownyfsm/
 [3]: https://github.com/tinyclub/tinylab.org#fork-destination-box
 [4]: https://wx.zsxq.com/dweb2/index/group/455128114458
 [5]: https://gitee.com/
 [6]: https://gitee.com/help/articles/4128
