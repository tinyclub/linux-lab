# 在 Arch Linux 系统安装 Docker

安装之前请将镜像源设置为国内镜像站，如：[TUNA ArchLinux](https://mirrors.tuna.tsinghua.edu.cn/help/archlinux/) ; [TUNA ArchLinuxCN](https://mirrors.tuna.tsinghua.edu.cn/help/archlinuxcn/)

验证过的版本：

- Arch Linux
- Manjaro Linux
- 待补充


## Step 0：使用 Pacman 搜索 Docker

    $ sudo pacman -Ss docker

## Step 1: 使用 Pacman 安装

### Step 1.1: Pacman 自动解决依赖关系

    $ sudo pacman -S docker
	正在解析依赖关系...
	正在查找软件包冲突...

	软件包 (3) containerd-1.3.4-2  runc-1.0.0rc91-1  docker-1:19.03.12-1

	下载大小:    91.07 MiB
	全部安装大小：  391.31 MiB


### Step 1.2: Pacman 可选依赖安装

	(3/3) 正在检查密钥环里的密钥                                     [###################################] 100%
	(3/3) 正在检查软件包完整性                                       [###################################] 100%
	(3/3) 正在加载软件包文件                                         [###################################] 100%
	(3/3) 正在检查文件冲突                                           [###################################] 100%
	(3/3) 正在检查可用存储空间                                       [###################################] 100%
	:: 正在处理软件包的变化...
	(1/3) 正在安装 runc                                              [###################################] 100%
	(2/3) 正在安装 containerd                                        [###################################] 100%
	(3/3) 正在安装 docker                                            [###################################] 100%
	docker 的可选依赖
		btrfs-progs: btrfs backend support [已安装]
		pigz: parallel gzip compressor support


    $ sudo pacman -S pigz


## Step 2: 启动 Docker

### Step 2.1: 开启 Docker 开机自动启动服务

  安装完成后设置 Docker 开机自动启动服务。

    $ sudo systemctl enable docker.service


### Step 2.2: 关闭 Docker 开机自动启动服务

    $ sudo systemctl disable docker.service


### Step 2.3: 启动 Docker 服务

    $ sudo systemctl start docker.service


## Step 3: 把工作用户加入 docker 组，避免使用 root 帐号工作

  Pacman 方式安装好 docker 后已经自动帮我们建立了 docker 组，所以我们不需要自己添加 docker 组，只需要把当前工作用户加入 docker 组即可。

    $ sudo gpasswd -a $USER docker
    $ reboot


  重启系统生效。


## Step 4: 配置镜像加速

  鉴于国内网络问题，每次使用 `docker pull` 命令 pull 镜像时，docker daemon 都会去 Docker Hub 拉取镜像，拉取 Docker 镜像十分缓慢，强烈建议安装 Docker-CE 之后配置国内镜像加速。

  我们可以使用中科大的镜像源来加速（阿里云的docker镜像加速器需要注册账号，每个人都有自己唯一的地址。）。

  加速的方法参考 [“USTC Docker 镜像使用帮助”](https://lug.ustc.edu.cn/wiki/mirrors/help/docker), 对于使用 systemd 的系统，修改 `/etc/docker/daemon.json` 即可（没有该文件的话，请先新建一个）。

  在该配置文件中加入如下语句，如果要换用其他的镜像源也可以修改其中的 URL 部分：

    {
        "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
    }


  配置完成之后执行如下命令重新启动服务生效。


    $ sudo systemctl daemon-reload
    $ sudo systemctl restart docker.service


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


  恭喜你，如果看到以上提示，说明 Docker 工作正常。
