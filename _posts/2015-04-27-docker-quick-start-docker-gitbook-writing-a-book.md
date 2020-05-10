---
title: Docker 快速上手：用 Docker + GitBook 写书
author: Wu Zhangjin
layout: post
album: Markdown 用法详解
permalink: /docker-quick-start-docker-gitbook-writing-a-book/
tags:
  - Gitbook
  - 写作
  - 书籍
  - 泰晓沙龙
categories:
  - Docker
  - Markdown
  - Gitbook
---

> By Falcon of [TinyLab.org][1]
> [泰晓沙龙][2]第二期 @ 2015/04/26


注：由于 Docker 和 Gitbook 更新换代太快，以下方法或许已经失效，推荐直接通过 [Markdown Lab](http://tinylab.org/markdown-lab) 来撰写书籍，它基于 Docker 内建有 Gitbook 环境。

# 准备 GitBook 环境

## 安装 Docker

  * 以Ubuntu为例

        $ echo deb http://get.docker.io/ubuntu docker main \
            | sudo tee /etc/apt/sources.list.d/docker.list
        $ sudo apt-key adv --keyserver keyserver.ubuntu.com \
            --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
        $ sudo apt-get update
        $ sudo apt-get install -y lxc-docker

  **注**：以上方法在新版 Ubuntu 上已经失效，最新版本已经转为使用 [docker engine](https://docs.docker.com/engine/installation/linux/ubuntulinux/)。

## 安装 GitBook 环境

  * 搜索镜像

        $ sudo docker search gitbook
        NAME  DESCRIPTION   STARS     OFFICIAL   AUTOMATED
        tobegit3hub/gitbook-server 2             [OK]


  * 安装镜像

      * ubuntu
      * npm + nodejs
      * gitbook + calibre(ebook-convert)

            $ sudo docker pull tobegit3hub/gitbook-server


## 完善 GitBook 环境

  * 启动 GitBook 环境

        $ sudo docker images | grep gitbook
        tobegit3hub/gitbook-server   latest d171079650c8
        $ sudo docker run -i -t \
        tobegit3hub/gitbook-server /bin/bash


  * 安装 字体 和 Git

        $ apt-get install git
        $ apt-get install fonts-arphic-gbsn00lp


# 用 GitBook 写书

## 基础准备

  * Markdown

      * 当前最流行的内容创作标记语言
      * Google自然设计：突出内容，抛弃繁杂的格式！
      * [Markdown 基本语法][3]
      * Markdown 编辑器：retext

  * Pandoc

      * 各种格式自由转换
      * [Pandoc Markdown 语法][4]

  * GitBook

      * [GitBook 快速上手][5]
      * [GitBook 简明教程][6]

## GitBook 核心文件

  * GitBook 本身是一个 Git 仓库

      * .gitignore: 需要忽略的临时内容

  * 重要组件

      * README.md: 书籍简介
      * SUMMARY.md: 图书结构，文章索引
      * LANGS.md: 多国语言，每种一个目录
      * GLOSSARY.md: 词汇表
      * cover.jpg: 图书封面
      * cover_small.jpg: 小尺寸图书封面

## GitBook 输出格式

  * 静态 HTML 页面

      * `gitbook build ./ --output=./_book/`

  * PDF

      * `gitbook pdf`

## GitBook 在线预览

  * 启动服务
      * `gitbook serve ./`

> Starting server &#8230;
>
> Serving book on http://localhost:4000

  * 在线预览
      * 用浏览器打开: `http://localhost:4000`

## 杂项

  * Json 语法错误
      * book.json：不支持注释等。
      * [JSON 在线验证][7]

> SyntaxError:&#8230;/book.json:Unexpected token o

  * GitBook 调试

      * `export DEBUG=true`

  * GitBook 插件

      * Google Analytics
      * Disqus: Comments
      * Exercises

# GitBook 图书实例

## 下载和编译图书

  * 下载

        $ git clone \

        https://github.com/tobegit3hub/understand_linux_process.git



  * 编译

        $ cd understand_linux_process
        $ gitbook build
        $ gitbook pdf


## 在线预览图书

  * Docker 侧

      * 启动图书服务器

            $ ifconfig eth0 | grep "inet addr"
            inet addr:172.17.0.31 ...
            $ gitbook serve ./
            Starting server ...
            Serving book on http://localhost:4000


  * 主机侧

      * 在浏览器访问：http://172.17.0.31:4000

## 从 Docker 拷贝出 pdf

  * Docker 侧：确认 pdf 路径

        $ readlink -f book.pdf
        /gitbook/understand_linux_process/book.pdf


  * 主机侧：`docker cp CONTAINER_ID:PATH HOSTPATH`

        $ sudo docker ps -a
        CONTAINER ID   IMAGE              COMMAND
        cf5925e tobegit3hub/gitbook-server "/bin/bash"
        $ sudo docker cp \
        cf5925e:/gitbook/understand_linux_process/book.pdf .


## 从 主机 拷入 Docker

  * 两个步骤

      * 获取容器挂载路径
      * 通过本地 cp 命令直接拷贝进去

            $ fullid=`sudo docker inspect -f '{{ "{{ .Id " }}}}' cf5925e`
            $ gitbook=/var/lib/docker/aufs/mnt/$fullid/gitbook/
            $ ls $gitbook
            understand_linux_process
            $ cp book.pdf $gitbook/book-from-host.pdf


## 直接挂载卷共享

  * 挂载主机 GitBook 目录到 Docker

        $ sudo docker run -i -t \
          -v /path/to/mybook/:/gitbook/ \
          tinylab/gitbook /bin/bash


# 新建 GitBook 环境

## 备份/导出/导入容器

  * 保存容器为新镜像: commit

        $ sudo docker commit cf5925e tinylab/gitbook
        $ sudo docker images | grep tinylab/gitbook
        tinylab/gitbook latest 2106b9f7f675


  * 导出镜像文件: save/export

        $ sudo docker save tinylab/gitbook > gitbook.tar


  * 导入镜像文件到其他主机上: load/import

        $ sudo docker load < gitbook.tar


## 其他操作

  * 删除/杀掉容器

      * `docker rm [-f]  contaier_id`
      * `docker kill contaier_id`

  * 停止容器

      * `docker stop container_id`

  * 启动容器

      * `docker start container_id`

  * 删除镜像

      * `docker rmi image_id`

## 新建 GitBook Dockerfile

    # Dockerfile
    FROM ubuntu:14.04
    MAINTAINER Falcon wuzhangjin@gmail.com
    RUN sed -i -e "s/archive.ubuntu.com/mirrors.163.com/g" \
        /etc/apt/sources.list
    RUN apt-get -y update
    RUN apt-get install -y nodejs npm git && \
        npm install gitbook-cli -g
    RUN apt-get install -y calibre
    RUN apt-get install -y fonts-arphic-gbsn00lp
    RUN mkdir /gitbook
    WORKDIR /gitbook
    EXPOSE 4000
    CMD ["gitbook", "serve", "/gitbook"]


## 新建 GitBook Dockerfile（续）

    # Dockerfile
    FROM ubuntu:14.04
    MAINTAINER Falcon wuzhangjin@gmail.com
    RUN sed -i -e "s/archive.ubuntu.com/mirrors.163.com/g" \
        /etc/apt/sources.list
    RUN apt-get -y update
    RUN apt-get install -y curl git && cd / && \
        git clone https://github.com/creationix/nvm.git nvm && \
        echo ". /nvm/nvm.sh" > ~/.bashrc && . ~/.bashrc && \
        nvm install 0.12.2 && nvm use 0.12.2 && \
        npm install gitbook-cli -g
    RUN apt-get install -y calibre
    RUN apt-get install -y fonts-arphic-gbsn00lp
    RUN mkdir /gitbook
    WORKDIR /gitbook
    EXPOSE 4000
    CMD ["gitbook", "serve", "/gitbook"]


## 基于 Dockerfile 构建映像

  * 快速构建

        $ sudo docker build -t tinylab/gitbook ./


  * 更多参数: Cgroup

> -c, &#8211;cpu-shares=0 CPU shares (relative weight)
>
> &#8211;cpuset-cpus= CPUs in which to allow execution (0-3, 0,1)
>
> -m, &#8211;memory= Memory limit

# 免 sudo 使用 docker

## 把普通用户加入 docker 用户组

* 如果还没有 docker group 就添加一个：

        $ sudo groupadd docker

* 将用户加入该 group 内。然后退出并重新登录就生效啦。

        $ sudo gpasswd -a ${USER} docker

* 重启 docker 服务

        $ sudo service docker restart

## 原因

  * 因为 `/var/run/docker.sock` 所属 docker 组具有 setuid 权限

        $ sudo ls -l /var/run/docker.sock
        srw-rw---- 1 root docker 0 May  1 21:35 /var/run/docker.sock


# 参考资料


  * [Gitbook 快速上手][5]
  * [GitBook 简明教程][6]
  * [Ubuntu環境下，如何安裝nvm以及nodejs][8]
  * [Ubuntu環境下，快速開始使用gitbook][9]
  * [Docker详细的基本用法][10]
  * [支持中文搜索的gitbook][11]
  * [Docker官方文档][12]





 [1]: http://tinylab.org
 [2]: /tinysalon/
 [3]: https://www.markdownguide.org/basic-syntax
 [4]: http://johnmacfarlane.net/pandoc/demo/example9/pandocs-markdown.html
 [5]: http://colobu.com/2014/10/09/gitbook-quickstart/
 [6]: http://www.chengweiyang.cn/gitbook/
 [7]: http://www.bejson.com/
 [8]: http://samwhelp.github.io/blog/read/platform/nodejs/install/
 [9]: http://samwhelp.github.io/blog/read/platform/gitbook/start/
 [10]: http://www.linuxeye.com/Linux/2019.html
 [11]: http://www.oschina.net/question/615647_195686
 [12]: http://docs.docker.com/articles/basics/
