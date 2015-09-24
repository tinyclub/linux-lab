---
title: 常用 Git 开发模型
author: Wu Zhangjin
layout: post
permalink: /git-development-model/
views:
  - 198
tags:
  - Gerrit
  - Git
  - Jenkins
  - Patchwork
  - 开发模型
categories:
  - SCM
---

> by falcon of [TinyLab.org][2]
> 2014/07/18

Git已被广泛使用于各种项目，很多同学虽然用Git跟了很多项目，但是还停留在基本使用阶段，导致开发效率低下。

这里介绍一个常用的开发模型或者说开发过程来展示Git的用法。


### 初始化一个项目

假设有一个项目，叫gitflow。

<pre>$ mkdir gitflow
$ cat &lt;&lt;EOF > README.md
>
>    gitflow
>
> #Introduction
>
> This is a project aims to show a standard git flow.
>
> #Client
>
> #Server
>
> #Development
>
> #Review
>
> #Upstream
>
> #Release
> EOF
</pre>

一般情况下，项目管理人员或者团队Leader会整理初始代码和文档，然后创建一个初始的代码仓库：

<pre>$ cd gitflow
$ git init
$ git add README.md
$ git commit -s -m "Init the gitflow project"
</pre>

### 初始化该项目的远程仓库

使用git通常意味着多人协同开发，也意味着C/S模式的开发，即使是单人开发的项目，远程仓库也是数据备份的必要选择。

接下来，创建一个不带工作目录的远程仓库，为了方便测试，咱们直接在本机上建立吧：

<pre>$ cd ../
$ mkdir remote-gitflow
$ cd remote-gitflow
$ git init --bare
</pre>

然后，到本地仓库设置一下远程仓库地址（创建一个默认别名为origin）：

<pre>$ cd ../gitflow/
$ git remote add origin localhost:${PWD}/../remote-gitflow/
</pre>

上传本地仓库：

<pre>$ git push origin master:master
$ git branch -a
* master
  remotes/origin/master
$ git remote show origin
* remote origin
  Fetch URL: localhost:/research/scm/examples/git-examples/gitflow/../remote-gitflow/
  Push  URL: localhost:/research/scm/examples/git-examples/gitflow/../remote-gitflow/
  HEAD branch: master
  Remote branch:
    master tracked
  Local ref configured for 'git push':
    master pushes to master (up to date)
</pre>

可以发现，多了一个远程分支。

注：

  * 上面并没有创建一个完整的git服务器，如果要支持多用户，建议采用[gitolite][3]。
  * 如果要跟本地操作一样实现无密码访问，需要使用ssh的公、私钥机制，上传公钥到服务器即可。
  * 如果项目足够大，咱们还需要在Git之上用Android [Repo][4]再建立一个Git仓库的集合。
  * 于此同时，Web在线浏览是很有必要的，可以用[gitweb][5]。
  * 再者，代码交叉索引很有必要，那么用[OpenGrok][6]来建一个吧。

### 进行本地开发

初始化仓库以后，各个团队成员就可以clone代码，进行本地的开发。

假设某个成员负责camera部分，那么clone代码为gitflow-dev：

<pre>$ cd ../
$ git clone localhost:/research/scm/examples/git-examples/remote-gitflow/ gitflow-dev
</pre>

并创建一个camera分支：

<pre>$ cd gitflow-dev
$ git checkout -b camera
$ git branch -a
* camera
  master
  remotes/origin/HEAD -> origin/master
  remotes/origin/master
</pre>

做如下改动：

<pre>$ git diff
diff --git a/README.md b/README.md
index 8851bb4..12ce03e 100644
--- a/README.md
+++ b/README.md
@@ -11,6 +11,8 @@ This is a project aims to show a standard git flow.

 #Development

+Assume I'm a camera developer...
+
 #Review

 #Upstream
$ git add README.md
$ git commit -s -m "Camera: Add a camera driver"
</pre>

经过自己足够的测试和验证以后，发现驱动已经Ok，那么接下来就是发出去评审了。注意，写完代码千万不要直接提交到服务器，必要的代码交叉检查是强制性的，不要过于自信。

以Linux为例，自己的检查通常会有：

  * 代码风格检查：scripts/checkpatch.pl
  * 更多：Documentation/SubmitChecklist

### 代码评审

在[Gerrit][7]出来之前，`git sendemail`+[Patchwork][8]+邮件列表 是社区常用的代码评审方式，不过现如今，即使是小项目，Gerrit也值得推荐。

Gerrit是一个合集，集成了很多用户需要的功能，把评审做到了极致，比如说通过[Jenkins][9]可以检查是否有编译错误，甚至可以集成更多的工具做其他基本的代码检查。除此之外，人工的评审非常方便，可以支持多人评审，支持按代码行评审，粒度可以非常细。

具体怎么安装和使用，请翻搜索引擎。

下面就两种不同的评审方式来个实例比较：

  * 通过`Git sendemail` + Patchwork评审最近的一个提交

只需要把邮件发给Camera的Leader以及所有关联的开发人员即可：

<pre>$ git format-patch -1
0001-Camera-Add-a-camera-driver.patch
$ git send-email --to="camera-reviewer@example.com" --cc="camera-app-dev@example.com" 0001-Camera-Add-a-camera-driver.patch
</pre>

之后Patchwork会自动收集好上面的Patch，评审人员可以直接回复邮件指出代码存在的各类问题，也可以通过pwclient工具从Patchwork服务器下载和打上Patch，并做其他的验证，如果要做自动化检查，可以通过配置远程仓库`.git/hooks/`下的钩子脚本来实现。

可以看下Linux内核使用Patchwork的例子：<https://patchwork.kernel.org/project/LKML/list/>。

  * 通过Gerrit+Jenkins等来评审

简单提交到refs/for/branch-name即可，这个并不会自动合并，而是先进入到Gerrit的评审页面：

<pre>$ git push origin camera:refs/for/master
</pre>

之后，可以通过Gerrit界面添加Reviewers，比如camera-reviewer, camera-app-dev等，添加后会自动发送邮件给相关Reviewers登陆进来评审。另外，如果配置了Jenkins，会自动把代码提交到Jenkins服务器自动编译，有问题就会不通过Verify。

相比Patchwork的早期方式，Gerrit有更高的效率和更严格的控制流程。

### 上传代码

正常情况下，如果代码没有任何冲突，上述流程是很顺的。但是如果是多人协同开发同一个模块，那么冲突就通常是难免的。那代码管理中很重要的一个问题就是怎么解决冲突。

为了减少冲突，通常我们建议在最后提交时，确保相关修改是基于最新的远程主分支，通常会先更新主分支：

<pre>$ git checkout master
$ git pull
</pre>

如果修改很少，比如在1~3个，我们可以先基于master创建一个upstream分支，然后直接用`git cherry-pick`一个一个拿过来：

<pre>$ git checkout -b upstream master
$ git log --pretty=oneline camera
5e07158b8e6cec00f802b0e114d4f36fa646f68f Camera: Add a camera driver
9c5616269a90cd2a259dac53dd2352b919c9af2b Init the gitflow project
$ git cherry-pick 5e07158b8e6cec00f802b0e114d4f36fa646f68f
</pre>

如果修改较多，则会基于camera创建一个upstream分支，rebase到master分支，解决冲突，然后上传：

<pre>$ git checkout -b upstream camera
$ git rebase --onto master --root
</pre>

如果没有冲突就upstream的结果会是：把camera的所有变更追加到最新的master分支。

如果有冲突，就需要解决`<<<<<HEAD`等标记出来的问题，可以用`git diff`查看，解决完冲突以后添加并提交，然后执行：

<pre>$ git rebase --continue
</pre>

直到解决所有冲突以后再提交：

<pre>$ git push origin upstream:master
</pre>

其实开源社区很多时候是不允许直接提交到最终仓库的，而是由各个系统的维护人员把解决冲突后的仓库以及分支准备好，告诉顶级维护人员merge。

通过Gerrit其实也类似，只不过很多操作是通过Web和本地一起做，并且Gerrit不允许直接提交入库，而是必须由reviewer评审后才能入库。

### 项目测试与发布

在代码开发完了以后就是项目测试阶段，测试完成以后就会正式对外发布。





 [2]: http://tinylab.org
 [3]: https://github.com/sitaramc/gitolite
 [4]: http://blog.csdn.net/seker_xinjian/article/details/6232475
 [5]: http://git.kernel.org/cgit/git/git.git/tree/gitweb
 [6]: /online-cross-references-of-open-source-code-softwares/
 [7]: http://code.google.com/p/gerrit/
 [8]: http://jk.ozlabs.org/projects/patchwork/
 [9]: https://wiki.jenkins-ci.org/display/JENKINS/Gerrit+Plugin
