---
title: 删除 Git 仓库中的第一条记录
author: Wu Zhangjin
layout: post
permalink: /faqs/delete-the-first-commit-of-the-git-repositor/
tags:
  - rebase
  - 删除历史记录
categories:
  - Git
---
  * 问题描述

    `git rebase -i` 命令被广泛用于“篡改历史”，主要是在 upstream 代码到 Git 服务器或者上游仓库时，为了代码更好看，更条理清晰，更适合 Review。

    平时如果想处理某个变更 `commit_id`，我们可以简单地用下面的命令来决定如何操作：

        git rebase -i commit_id^


    但是这条命令对于 Git 仓库的第一条记录却不管用。

  * 问题分析

    因为在 `^` 总意味着 `commit_id` 的前一条记录，例如：`HEAD` 表示当下的第一条记录，`HEAD^` 则表示倒数第 2 条记录。

    `rebase` 在这里用 `commit_id^` 表示在 `commit_id^` 的基础上重构所有 commits，那意味着，就可以处理 `commit_id` 以及之后的所有内容，具体处理包括：

        # Commands:
        #  p, pick = use commit
        #  r, reword = use commit, but edit the commit message
        #  e, edit = use commit, but stop for amending
        #  s, squash = use commit, but meld into previous commit
        #  f, fixup = like "squash", but discard this commit's log message
        #  x, exec = run command (the rest of the line) using shell



    当然，`edit` 和 `reword` 可以通过 `git commit ---amend` 来实现。但是如果要去掉该 `commit_id`，也就是普通 `git rebase -i commit_id^` 中的删除 `pick commit_id` 的做法却不能使用，因为对于第一条 commit_id 而言，之前没有了任何变更记录，所以 `commit_id^` 并不存在。

  * 解决方案

    那办法当然是，另辟蹊跷，那就是 **`--root`**：

        --root
       Rebase all commits reachable from &lt;branch>, instead of limiting
       them with an &lt;upstream>. This allows you to rebase the root
       commit(s) on a branch.


    这意味着，Linux 世界本来不支持“斩草除根”，但是它留了后门，方便在人类面临正义问题时，有机会让主人公做出艰难抉择：

        $ git rebase -i --root


    这样就可以尝试删除第一条 `pick commit_id` 记录，也就是删除 Git 仓库中的第一条修改记录。当然，如果仓库里头只有一条记录，那就没有删除的必要，直接修改或者删除整个 Git 仓库就好。



