---
layout: post
author: 'Wu Zhangjin'
title: "用 Cloud Ubuntu 搭建各类代理服务"
group: original
permalink: /build-varied-proxy-with-cloud-ubuntu/
description: "Cloud Ubuntu 是泰晓科技为云实验环境开发的各类 Docker 镜像，其中包括各类代理服务。"
category:
  - 在线 Linux
tags:
  - Cloud Ubuntu
  - Proxy
  - 代理
  - 透明代理
  - 反向代理
  - 代理转发
  - novnc
  - gateone
---

> By Falcon of [TinyLab.org][1]
> 2017-01-10 00:35:09

## 简介

[如何快速部署云实验环境（Cloud-Lab）][2] 一文提到了 [Cloud Ubuntu](3)，它为云实验环境提供各类 Docker 镜像，而其中部分镜像提供了各类代理服务：

* cloud-ubuntu-web: 提供 VNC 和 ssh 的 Web 代理服务
* cloud-ubuntu-proxy*：Socks5 代理服务器、客户端、透明代理客户端、代理端口转发
* cloud-ubuntu-reverse_proxy：有了它，加上一个公网运行 cloud-ubuntu-web 的服务器，就可以访问到某个内部网络，比如在家访问公司的办公电脑，实现远程办公。

下面逐个介绍其用法。

## 准备

在介绍之前，先下载 Cloud Ubuntu：

    $ git clone https://github.com/tinyclub/cloud-ubuntu.git
    $ cd cloud-ubuntu/

如果本地还没有安装 Docker，请先安装之：

    $ ./install

如果是国内用户，建议在 `/etc/default/docker` 中打开如下配置：

> DOCKER_OPTS="$DOCKER_OPTS --registry-mirror=https://docker.mirrors.ustc.edu.cn"
> DOCKER_OPTS="$DOCKER_OPTS --dns 223.5.5.5 --dns 114.114.114.114"
> DOCKER_OPTS="$DOCKER_OPTS --bip=10.66.33.10/24"

重启 Docker 服务，加载新配置：

    $ service docker restart

## cloud-ubuntu-web：VNC/ssh Web 代理

通过它可访问局域网内的 VNC 和 ssh 服务，进而访问运行有相关服务的各类实验环境，从而为云实验环境提供了远程访问能力。

VNC 的 Web 代理通过 [noVNC][4] 实现。而 ssh 的 Web 代理通过 [GateOne][5] 实现。两者都提供了密码验证，https 服务以及自动登陆。

noVNC 还提供了 token 功能，即一组到 "VNC 地址：端口" 的字符串映射，对于标准 VNC 的 5900 端口，cloud-ubuntu-web 默认映射为 IP 地址的 md5sum；对于相同服务器的其他 VNC 端口，则为端口本身的 md5sum。

通过下述命令即可开启：

    $ scripts/web-ubuntu.sh

默认情况下，它做了如下端口映射：

| Protocol     |  Internal port  | Default External port|
|-------------:|----------------:|---------------------:|
|ssh           | 22              | 2222                 |
|gateone/webssh| 443             | 4433                 |
|noVNC         | 6080            | 6080                 |

可通过修改 `./config` 中的 `LOCAL_VNC_PORT`, `LOCAL_SSH_PORT` 和 `LOCAL_WEBSSH_PORT` 进行调整。

另外，它还允许设置 `LAB_SECURITY` 来开启 https 支持。

而 ssh 密码则可以通过 `UNIX_PWD` 外加 `ENCRYPT_CMD` 来设置，默认为 `ubuntu`。

如果对外网提供服务，为安全起见，请务必设置一个更复杂的密码，例如可以用 `pwgen` 生成一个复杂密码：

    $ sudo apt-get install pwgen
    $ pwgen -c -n -s -1 15
    QHe26sHyy21AIkE

然后设置密码，并采用 md5sum 对密码进行加密，然后启动该镜像中的代理服务：

    $ UNIX_PWD=QHe26sHyy21AIkE ENCRYPT_CMD=md5sum scripts/web-ubuntu.sh
    CONTAINER: cloud-ubuntu-web-25011
    $ docker inspect --format '{{ "{{ .NetworkSettings.IPAddress " }}}}' cloud-ubuntu-web-25011
    10.66.33.1

出于安全考虑，该镜像本身的 ssh 服务禁用了 shell，而本身的 VNC 服务则直接停用了。

接下来，开启一个新的镜像，新镜像本身有 ssh 和 VNC 服务（所有除 `cloud-ubuntu-web` 外的镜像都支持），以 `cloud-ubuntu` 为例：

    $ ./run base

然后，就可以通过上述代理访问了：

    $ ./login/vnc
    $ ./login/webssh

上述两条命令会自动生成 Web URL，设置服务器地址，端口，协议，token和密码等，并主动调用浏览器登陆。如果要手动在浏览器访问，请根据上述命令打印的日志中获取 `URL`。

## cloud-ubuntu-proxy: Socks5 代理

该镜像系列包括 4 个镜像，提供了服务器、客户端、透明代理和端口转发 4 部分功能：

* cloud-ubuntu-proxy_server：用于搭建 Socks5 代理服务器
* cloud-ubuntu-proxy_client：用于连接 Socks5 代理服务器并创建本地真正的 Socks5 代理
* cloud-ubuntu-proxy_client_transparent：用于创建透明代理，该透明代理可以在局域网内透明使用，也可以在主机当 Socks5 代理配置
* cloud-ubuntu-proxy_relay：通过端口转发快速创建一个二级代理，通过该代理可直接访问远程代理。

接下来，我们依次使用上述镜像搭建服务器、客户端、透明代理并通过端口转发实现代理转发服务。

通常，代理服务器会搭建在一个外部网络上，主要是加速对另外一个网络资源的访问。所以，通常需要先购买一台位于外部网络中的服务器，比如虚拟主机。Linode、阿里云等都有类似的服务器资源出售。在搞定服务器以后，就是搭建了。

同样地，需要先参照上述方法在服务器上安装好 Docker，下载 cloud-ubuntu，拉取 `cloud-ubuntu-proxy_server` 镜像，然后运行：

    $ git clone https://github.com/tinyclub/cloud-ubuntu.git
    $ cd cloud-ubuntu
    $ ./install
    $ ./pull proxy_server

    $ sudo apt-get install pwgen
    $ pwgen -c -n -s -1 15
    DfOPhlguZB7fbJv

    $ PROXY_PWD=DfOPhlguZB7fbJv ENCRYPT_CMD=md5sum PROXY_PORT=80 ./scripts/proxy-server.sh

接下来，在本地即可开启客户端镜像来访问。假设代理服务器的 IP 地址为 `a.b.c.d`。

    $ git clone https://github.com/tinyclub/cloud-ubuntu.git
    $ cd cloud-ubuntu
    $ ./install
    $ ./pull proxy_client

    $ PROXY_SERVER=a.b.c.d:80 PROXY_PWD=DfOPhlguZB7fbJv ENCRYPT_CMD=md5sum \
      PROXY_PORT=1080 MAP_PORT=1 ./scripts/proxy-client.sh
    CONTAINER: cloud-ubuntu-proxy_client-18928

上述命令会创建一个真正的本地 `Sock5` 代理：`localhost:1080`，该代理可以在浏览器、Git等各类场景中使用，例如：

    $ chromium-browser --proxy-server="socks5://localhost:1080"
    $ git config --global https.proxy "socks5://localhost:1080"

为安全起见，建议不要设置 `MAP_PORT` 从而避免本地代理被远程使用，因为这个是没有密码的。直接使用容器内的局域网 IP 地址则没有这个问题（记得使用 NAT 方式而不是网桥）：

    $ docker inspect --format '{{ "{{ .NetworkSettings.IPAddress " }}}}' cloud-ubuntu-proxy_client-18928
    10.66.33.3

可这么访问：`socks5://10.66.33.3:1080`，需要提到的是，在该容器内也可以使用该代理。

如果希望任何程序未经配置直接使用 sock5 代理，也即所谓的透明代理，就可以使用 `cloud-ubuntu-proxy_client_transparent`。它不仅允许所有服务透明使用代理，而且自动为国内的地址绕开代理而直连，从而区别加速不同的网络访问。其启动方法跟 `cloud-ubunt-proxy_client` 几乎一致：

    $ ./pull proxy_client_transparent

    $ PROXY_SERVER=a.b.c.d:80 PROXY_PWD=DfOPhlguZB7fbJv ENCRYPT_CMD=md5sum \
      PROXY_PORT=1080 MAP_PORT=1 ./scripts/proxy-client-transparent.sh
    CONTAINER: cloud-ubuntu-proxy_client_transparent-7831

在主机端用法同上，暂时不支持透明访问，但是在容器内部或者在局域网内的其他容器上，可通过更换路由为该容器的 IP 地址而轻松实现透明代理访问。

    $ docker inspect --format '{{ "{{ .NetworkSettings.IPAddress " }}}}' cloud-ubuntu-proxy_client_transparent-7831
    10.66.33.4
    $ ./login/vnc

进去以后，打开浏览器，无需配置即可访问外部网络。如果要在其他容器内使用，简单配置即可，以 `cloud-ubuntu-dev` 为例：

    $ ./pull dev
    $ ./run dev
    $ ./login/bash
    # route -n
    Kernel IP routing table
    Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
    0.0.0.0         10.66.33.10     0.0.0.0         UG    0      0        0 eth0
    10.66.33.0      0.0.0.0         255.255.255.0   U     0      0        0 eth0
    # route del default gw 10.66.33.10 eth0
    # route add default gw 10.66.33.4 eth0

    $ ./login/vnc

如果直连国外的代理服务器比较慢的话，可以考虑在国内找一个转发服务器，此时可以用 `cloud-ubuntu-proxy_relay`：

    $ git clone https://github.com/tinyclub/cloud-ubuntu.git
    $ cd cloud-ubuntu
    $ ./install
    $ ./pull proxy_relay

    $ PROXY_SERVER=a.b.c.d:80 RELAY_PORT=80  ./scripts/proxy-relay.sh

此时会创建一个新的 Socks5 代理服务器，假设该转发服务器的 IP 为 `x.y.z.j`，在客户端中使用时，仅需从 `a.b.c.d` 切换为 `x.y.z.j`，其他用法类似。

## cloud-ubuntu-reverse_proxy：ssh 反向代理

在实际工作中，有很多远程办公的需求，比如从家里访问公司的电脑。很多朋友使用商业方案，但是存在很严重的安全缺陷，因为数据有很大可能性被泄露。

Cloud Ubuntu 为此提供了开放和便捷的解决方案。首先，它需要一台公网的服务器，在该服务器上，通过 `cloud-ubuntu-web` 开启 ssh 和 VNC 代理。其次，要做的仅仅是在需要被外部访问的主机上启动 `cloud-ubuntu-reverse_proxy`：

    $ git clone https://github.com/tinyclub/cloud-ubuntu.git
    $ cd cloud-ubuntu
    $ ./install
    $ ./pull reverse_proxy

    $ SSH_SERVER=a.b.c.d SSH_PORT=2222 SSH_USER=ubuntu SSH_PASS=QHe26sHyy21AIkE ./scripts/reverse-proxy.sh

其中 `SSH_SERVER`, `SSH_PORT`, `SSH_USER` 和 `SSH_PASS` 分别为 `cloud-ubuntu-web` 所在的服务器的公网 IP 地址，ssh 端口，登陆帐号和密码。该镜像通过 ssh 把本机上该容器的 VNC 和 ssh 端口分别转发到公网的 5000 和 2000 端口。

如果想直接把本地主机（而不是容器）的 VNC 和 ssh 反向转发到公网，可以直接使用 `system/reverse_proxy/etc/startup.aux/lan2internet.sh`，替代 `scripts/reverse-proxy.sh`。用法完全一样。

为了在外网可以访问这台主机中该容器的 VNC 和 ssh 端口。不能直接通过 `./login/vnc` 和 `./login/webssh` 访问，需要稍微构建一下 URL 地址，容器地址设置为 `cloud-ubuntu-web` 的 `10.66.33.1`。 

    $ VNC_PORT=5000 HOST_NAME=a.b.c.d ./login/vnc

    $ CONTAINER_IP=10.66.33.1 SSH_PORT=2000 HOST_NAME=a.b.c.d ./login/webssh

## 总结

综上所述，Cloud Ubuntu 为各类网络之间提供了便捷的透明访问支持，轻松搭建，简单易用。

[1]: http://tinylab.org
[2]: http://tinylab.org/how-to-deploy-cloud-labs/
[3]: https://github.com/tinyclub/cloud-ubuntu.git
[4]: https://kanaka.github.io/noVNC/
[5]: https://github.com/liftoff/GateOne
