---
title: 五分钟内把项目仓库从 gitorious 搬到 GitLab
author: Wu Zhangjin
layout: post
permalink: /take-5-minutes-to-migrate-projects-repo-from-gitorious-to-gitlab/
views:
  - 46
tags:
  - GitLab
  - Gitorious.org
  - 停止服务
  - 收购
categories:
  - git
---

> by Falcon of [TinyLab.org][1]
> 2015/03/15


## 前言

前几天在新浪微博 [@泰晓科技][2] 收到一条信息，[gitorious.org][3] 因为商业化不利，导致无法继续运营，把业务卖给了 [GitLab.com][4]，并且要求用户在 5 月底之前把所有仓库赶紧迁移走，之后将停止提供服务，看它首页顶部通知，以及相关信息：

> System notice: Gitorious is being acquired by GitLab and gitorious.org will shut down end of May. Please import your repositories to GitLab.com &#8211; [Read about it][5]
>
> Starting today, Gitorious.org users can import their existing projects into GitLab.com by clicking the “Import projects from Gitorious.org” link when creating a new project. Gitorious.org will stay online until the end of May 2015 to give people time to migrate their repositories. Existing users of Gitorious on-premises can contact sales@gitlab.com for more information.

那意味着预留给我们迁移项目的时间只剩下 2 个月多一点，[泰晓科技][1]刚好有把所有项目仓库托管在 gitorious.org，赶紧迁移。

在迁移之前，感谢这些通过商业服务补贴开源软件托管的平台，是你们让开源软件得以蓬勃发展，是你们让这个世界更美好。

## 五分钟内完成迁移

### 确认原有的仓库地址

以本站为例，原来在 gitorious.org 添加了 TinyLab 项目，所有本站的项目仓库全部挂在下面，所以仓库地址为：

> https://gitorious.org/tinylab/hello-c-world
### 赶紧在 GitLab.com 上抢注帐号

登录 GitLab.com，抢注自己上述项目名字的帐号，本站为 tinylab。并使用跟 gitorious.org 相同的注册邮箱地址，以便确保 GitLab.com 可以自动登录 gitorious.org，方便自动导入仓库。这样就可以尽量确保路径跟原来大体一致，以便降低迁移后各种地方仓库地址变更的成本。

例如，目标地址如果变成：

> https://gitlab.com/tinylab/hello-c-world
就只需要把域名 gitorious.org 替换为 gitlab.com 即可，所有本地资料修改非常简便：

`sed -e "s/gitorious.org/gitlab.com/g"`

### 一键迁移

登录 GitLab.com，在右上角选择 `+` 号创建一个新的项目，然后，把 NameSpace 选择为你刚才创建的用户名，比如本站为 TinyLab。

之后，点击中间三个链接中的：

> Import projects from Gitorious.org

点击后会进入到一个页面，该页面会列出你的邮箱帐号在 Gitorious.org 上的所有项目仓库。

然后选择需要导入的仓库逐个导入，或者直接选择如下按钮一键导入：

> Import all projects

接下来就是等待 GitLab.com 的后台服务逐个自动迁移所有项目仓库了。

### 查看迁移成果

完成后，点击左侧的 [Projects][6] 就可以查看所有的项目了。

## 迁移完成之后

迁移之后，一个很重要的工作是赶紧更新所有文章的仓库地址和链接，如果你在 GitLab.com 注册的帐号 (username) 刚好是 gitorious.org 上的项目名字，那么路径就可以基本保持了。简单如上替换域名即可。否则，就根据实际情况替换吧。

除了更新文章内的链接外，仓库内部用到的路径也记得更换掉，免得用户到时候无法访问 gitorious.org 造成糟糕的用户体验：

`$ grep gitorious.org -ur ./ | cut -d':' -f1 | xargs -i sed -i -e "s/gitorious.org/gitlab.com/g" {}`





 [1]: http://tinylab.org
 [2]: http://weibo.com/tinylaborg
 [3]: http://gitorious.org
 [4]: http://gitlab.com
 [5]: https://about.gitlab.com/2015/03/03/gitlab-acquires-gitorious/
 [6]: https://gitlab.com/dashboard/projects
