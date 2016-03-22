---
title: 'vnStatSVG: 流量监控软件 vnStat 最佳 Web 前端'
author: Wu Zhangjin
layout: post
permalink: /compare-different-vnstat-frontend/
tags:
  - Frontend
  - vnStat
  - vnStat PHP
  - vnstatSVG
  - Web
  - 前端
categories:
  - vnStatSVG
  - 流量监控
---

> by Falcon of [TinyLab.org][1]
> 2015/04/10


## vnStat 简介

[vnStat][2] 是一款轻量级的网络流量监控工具，目前各大 Linux/BSD 系统都已内置支持。

vnStat 本身只支持命令行的交互方式，而 Web 前端则由第三方工具支持。这里汇总并对比下 vnStat 的几种 Web 前端并为大家推荐最佳的一款。

## vnStat Web 前端对比

vnStat 首页推荐的四个前端有：

  * [vnStat SVG frontend][3]: 基于 CGI / SVG / AJAX 的轻量级 web 前端

    仅仅需要一个支持 CGI 的 HTTP 服务器，可以产生非常漂亮的基于 SVG 的图形报告。支持按月/日/时/秒等查看流量信息，还支持 top10 展示。

    因为不需要安装额外的 PHP 解析器，所以轻松支持 Apache, Nginx 以及 Busybox 内置的 httpd 服务器。

    更重要的是，vnStatSVG 不仅支持普通的 Linux 主机，还可以轻松支持服务器，集群抑或是一个小型的嵌入式系统。

    ![vnStatSVG Demo][4]

  * [jsvnstat][5]：interactive network traffic analysis

    jsvnstat 是另外一款 Web 前端，基于 Javascript 可以实现简单的交互，不过它依赖 PHP 支持，而且不支持集群和嵌入式系统。

    ![JSvnStat Demo][6]

  * [vnStat PHP frontend][7]: 一款基于 PHP 的 Web 前端

    严重依赖 PHP 和 GD image libraries。同样不支持集群和嵌入式系统。

    ![vnStatPHP Demo][8]

  * VnstatSystrayIcon (Windows): 基于 Windows 平台

## vnStatSVG 表现最佳

综合上述比较，不难发现 vnStatSVG 是一款最佳的 vnStat 前端。

关于它的更多特性，可以从其[官方主页][9]找到：

  * 基于 CGI / SVG / AJAX 动态地生成流量的图形报告（Top10/每月/每天/每时/每秒/汇总）
  * 支持 Apache, Nginx 以及 Busybox httpd，甚至其他更轻量级的 Web 服务器
  * 仅需 CGI 支持，无须 PHP 和其他额外模块，所以占用空间非常小
  * 因为只需从服务器传输 XML 格式的流量数据，所以消耗的带宽非常小
  * 可同时监控单台主机的任意多个网络设备接口，例如 eth0, eth1…
  * 可在一个窗口中同时监控某个集群的任意多台主机
  * 左侧的设备节点信息可展开，也可收缩，即使同时监控几十台主机都方便查看
  * 支持集群间的多种通信协议：http, ftp, file and even ssh
  * 支持多种浏览器客户端：Chromium, Firefox 以及 Safari
  * 可灵活通过多种不同方式获取 XML 格式的流量数据

总之，vnStatSVG 不仅支持普通的 Linux 主机，服务器，集群，而且支持基于 Busybox 这样的小型嵌入式系统。

## vnStatSVG 快速上手

[vnStatSVG 首页][9]详细介绍了其用法，不过用的是英文，咱们用中文简单介绍一下如何在 Ubuntu 主机上快速安装和使用它。

### 安装 vnStat 和 Apache

    sudo apt-get install vnstat apache2


### 下载 vnStatSVG

    git clone https://github.com/tinyclub/vnstatsvg.git


### 安装 vnStatSVG

假设 Apache 的根目录放在 `/var/www/`，可以在 `/var/www/` 创建一个 `vnstatsvg` 目录，然后把 Web 前端安装到下面。

    sudo -s
    cd vnstatsvg.git
    mkdir /var/www/vnstatsvg
    ./configure -d vnstatsvg
    make && make install


如果根目录不在 `/var/www/`，请用 `./configure w` 指定。

### 通过 Web 查看流量信息

默认就可以通过浏览器打开 `http://localhost/vnstatsvg/` 查看流量信息了。

### 添加更多网络设备节点

可以通过编辑 `/var/www/vnstatsvg/sidebar.xml` 修改各个设备节点的信息，也可以直接复制一个模板过去：

    sudo cp src/admin/sidebar.xml-template-4-singlehost /var/www/vnstatsvg/sidebar.xml


配置大体如下：

    <?xml version='1.0' encoding='UTF-8' standalone='no' ?>
    <sidebar id="sidebar">
    <iface>
        <name>eth0</name>
        <host>localhost</host>
        <description>Local Host</description>
    </iface>
    </sidebar>

更多模板请查看 `src/admin/sidebar.xml-template*`。

之后，编辑 `sidebar.xml` 配置各类网络设备节点的信息：

  * name: 网络设备节点名，默认为 eth0, eth1
  * host: 主机地址或者域名
  * protocol: XML 格式的流量数据获取协议，默认为 http
  * dump_tool: 默认为 shell 方式，即 `/cgi-bin/vnstat.sh`
  * description: 设备节点对应的服务信息描述

### 支持同时监控多台主机

如果要同时监控多个主机，最简单的方式莫过于在其他机器上用同样方式安装一份 `vnstat` 和 `vnStatSVG`，这样就只需要配置 `name`，`host` 和 `description`，其他保持默认。

例如，如果要监控 `localhost` 和 泰晓科技（域名为 tinylab.org） 的数据，可以添加一份如下配置：

    <?xml version='1.0' encoding='UTF-8' standalone='no' ?>
    <sidebar id="sidebar">
    <iface>
        <name>eth0</name>
        <host>localhost</host>
        <description>Local Host</description>
    </iface>
    <iface>
        <name>eth1</name>
        <host>tinylab.org</host>
        <description>TinyLab.org</description>
    </iface>
    </sidebar>

如果不想在其他机器上安装一份额外的 `vnStatSVG`，那么可以只安装 `vnstat`，但是需要有一种方式从其他主机上把数据拷贝到本地，例如，拷贝到本地的 `vnstat` 数据目录下 `/var/lib/vnstat`。

例如，可以用 ssh 协议（可以通过配置公钥免密登录）。

    # collect-data.sh
    hosts="tinylab.org"
    ifaces="eth0 eth1"
    while :;
    do
        for h in hosts
        do
                    for i in $ifaces
                    do
                        scp ${h}:/var/lib/vnstat/${i} /var/lib/vnstat/${h}-${i}
                        scp ${h}:/proc/net/dev > /var/lib/vnstat/${h}-${i}-second
                    done
        done
        sleep 5
    done

可以在后台一直执行该脚本或者启动另外一个 `cron` 任务来执行该脚本。这样就可以用 `file` 虚拟协议，如下的 `sidebar.xml` 就可以实现同样的效果了。

    <?xml version='1.0' encoding='UTF-8' standalone='no' ?>
    <sidebar id="sidebar">
    <!-- this configuration is for single host, the hosts and dump_tool field should be the same -->
    <iface>
        <name>eth0</name>
        <host>localhost</host>
        <description>Local Host</description>
    </iface>
    <iface>
        <name>tinylab.org-eth0</name>
        <host>localhost</host>
        <description>TinyLab.org : eth0</description>
    </iface>
    <iface>
        <name>tinylab.org-eth1</name>
        <host>localhost</host>
        <description>TinyLab.org : eth1</description>
    </iface>
    </sidebar>

## 小结

vnStatSVG 的确是一款非常小巧但是功能强大的 vnStat web 前端，非常推荐！

关于更多用法，比如说嵌入式系统支持，请参考其[项目首页][9]和演示站点[11]。

另外，如果要给 Nginx 添加 CGI 支持，可以参考 [Add CGI support for Nginx][10]。





 [1]: http://tinylab.org
 [2]: http://humdi.net/vnstat/
 [3]: /vnstatsvg/
 [4]: /wp-content/uploads/file/vnstatsvg-network-traffic-per-hour.png
 [5]: http://www.rakudave.ch/?q=jsvnstat
 [6]: http://www.rakudave.ch/userfiles/images/jsvnstat.png
 [7]: http://www.sqweek.com/sqweek/index.php?p=1
 [8]: http://www.sqweek.com/sqweek/files/scrot1.png
 [9]: /vnstatsvg
 [10]: /add-cgi-support-for-nginx/
 [11]: /vnstatsvg-demo/
