---
title: VPN 自动分流：GFW 困境突围
author: Wen Pingbo
layout: post
permalink: /vpn-automatic-shunting/
tags:
  - chnroutes
  - 自动分流
  - GFW
  - 国内IP
categories:
  - VPN
---
  * 问题描述

    由于大陆习惯搞大局域网，访问国外资源总是显得这么困难，于是 VPN 就火起来了。但是VPN默认使用的是全局代理，当访问国内的网站时，我们不得不把 VPN 关掉。这样来回切换，很是麻烦。如果我们能够让 VPN 自动识别国内 IP 地址，并且主动绕过 VPN 访问。这样我们就不用来回切换了，提升在 VPN 下国内网站的访问速度，顺便节约了宝贵的 VPN 流量。

  * 问题分析

    这个问题实现起来，其实很简单，在一些路由器里早已实现。我们只要在我们的路由表里，为每一个国内 IP 地址都写一个路由规则，指定其通过的网关和接口，就可以达到这个目的。比如我要让 27.112.0.0 这个网段内的所有 IP 绕过 VPN，则可以这样添加路由规则：

        # route add -net 27.122.0.0 netmask 255.255.0.0 gw 192.168.1.1 dev eth0

  * 解决方案

    难道我们只能自己一个一个去添加这些路由规则么？当然不是，我们可以写一个脚本，把国内所有 IP 段批量添加到我们的路由规则里，就可以了。现在网上有一个 [chnroutes][1] 项目，它利用 APNIC 官方提供的 [IP数据][2] 生成两个脚本，`ip-pre-up` 和 `ip-down`。第一个就是往路由表中添加路由规则，而 `ip-down` 则是把前面添加的规则删除掉。

    我们可以在使用 VPN 之前，运行一下 `ip-up` 脚本，在使用完 VPN 后，用 `ip-down` 把路由表恢复原样。这样我们就可以无缝在国内线路和 VPN 线路之间切换。如果你觉得手动运行这两个脚本很麻烦，可以把这个工作交给你的 VPN Client 去做。如果你用的是 PPTP VPN，可以把 `ip-pre-up` 复制到 `/etc/ppp` 下，把 `ip-down` 复制到 `/etc/ppp/ip-down.d` 下。这样在打开 VPN 时， PPTP 会自动运行 `ip-up` 脚本，批量添加路由规则，在关闭 VPN 时，PPTP 会自动运行 `ip-down` 脚本，自动恢复路由规则。如果你用的时 OpenVPN，或者其他类型的 VPN，也有类似的机制，具体可以参考 [chnroutes的帮助页面][3]。

    `ip-pre-up` 和 `ip-down` 这两个脚本可以从 [chnroutes网站][4] 上获取，或则利用它提供的 python 脚本自动生成。

    这种简单粗暴的解决方法比较实用，但由于路由规则过于庞大，会稍微影响网络速度，但相对与你用 VPN 的延时，这就算不了什么了。由于IP地址是变动的，你需要隔一段时间更新一下这两个脚本。




 [1]: https://code.google.com/p/chnroutes/
 [2]: http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest
 [3]: https://code.google.com/p/chnroutes/wiki/Usage
 [4]: http://chnroutes-dl.appspot.com/
