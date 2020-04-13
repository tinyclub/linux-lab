# 在 Ubuntu 系统安装 Docker

本文介绍了针对国内大陆用户在 Ubuntu 环境下安装 Docker-CE 的步骤和优化方法。官网指导参考 [Get Docker Engine - Community for Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)。

验证过的版本：

- Ubuntu 16.04 LTS
- Ubuntu 18.04 LTS
- 待补充

为加速安装，采用了阿里提供的镜像，参考 [“阿里的 docker-ce 的安装方法”](https://developer.aliyun.com/mirror/docker-ce?spm=a2c6h.13651102.0.0.53322f70PlMeFc)，本文在此基础上添加了一些自己的注释。

**注**：原先参考的是 [清华大学开源软件镜像站点的 Docker Community Edition 镜像使用帮助](https://mirror.tuna.tsinghua.edu.cn/help/docker-ce/)，后来因为发现清华的源特别慢，所以还是换了阿里的源。

## Step 0：卸载旧版本

  确保机器上没有安装旧版本的 docker

    $ sudo apt-get remove docker docker-engine docker.io

## Step 1: 使用 APT 安装

### Step 1.1: 安装依赖

    $ sudo apt-get update
    $ sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common


### Step 1.2: 添加软件源的 GPG 密钥

    $ curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -


### Step 1.3: 添加 Docker 软件源


  这里添加软件源的目的是为了下载 docker-ce 的安装包比较快。

    $ sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"


## Step 2: 安装 Docker CE


  安装完成后自动启动 Docker CE 服务。


    $ sudo apt-get -y update
    $ sudo apt-get -y install docker-ce


## Step 3: 把工作用户加入 docker 组，避免使用 root 帐号工作

  APT 方式安装好 docker-ce 后已经自动帮我们建立了 docker 组，所以我们不需要自己添加 docker 组，只需要把当前工作用户加入 docker 组即可。

    $ sudo usermod -aG docker $USER


  重启系统生效。


## Step 4: 配置镜像加速

  鉴于国内网络问题，每次使用 `docker pull` 命令 pull 镜像时，docker daemon 都会去 Docker Hub 拉取镜像，拉取 Docker 镜像十分缓慢，强烈建议安装 Docker-CE 之后配置国内镜像加速。

  我们可以使用中科大的镜像源来加速（阿里云的docker镜像加速器需要注册账号，每个人都有自己唯一的地址。）。

  加速的方法参考 [“USTC Docker 镜像使用帮助”](https://lug.ustc.edu.cn/wiki/mirrors/help/docker), 对于使用 systemd 的系统，譬如 ubuntu 16.04 以上版本，修改 `/etc/docker/daemon.json` 即可（没有该文件的话，请先新建一个）。

  在该配置文件中加入如下语句，如果要换用其他的镜像源也可以修改其中的 URL 部分：

    {
        "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
    }


  配置完成之后执行如下命令重新启动服务生效。


    $ sudo systemctl daemon-reload
    $ sudo systemctl restart docker


## Step 5: 测试是否安装正确

    $ docker run hello-world

        Unable to find image 'hello-world:latest' locally
        latest: Pulling from library/hello-world
        78445dd45222: Pull complete
        Digest: sha256:c5515758d4c5e1e838e9cd307f6c6a0d620b5e07e6f927b07d05f6d12a1ac8d7
        Status: Downloaded newer image for hello-world:latest

        Hello from Docker!
        This message shows that your installation appears to be working correctly.

        To generate this message, Docker took the following steps:
         1. The Docker client contacted the Docker daemon.
         2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
         3. The Docker daemon created a new container from that image which runs the
            executable that produces the output you are currently reading.
         4. The Docker daemon streamed that output to the Docker client, which sent it
            to your terminal.

        To try something more ambitious, you can run an Ubuntu container with:
         $ docker run -it ubuntu bash

        Share images, automate workflows, and more with a free Docker ID:
         https://cloud.docker.com/

        For more examples and ideas, visit:
         https://docs.docker.com/engine/userguide/


  恭喜你，如果看到以上提示，说明 docker-ce 工作正常。
