---
title: Add CGI support for Nginx
author: Wu Zhangjin
layout: post
permalink: /add-cgi-support-for-nginx/
tags:
  - Bash
  - CGI
  - FastCGI
  - Nginx
  - PHP
  - Shell
categories:
  - Nginx
---

> by falcon of [TinyLab.org][2]
> 2013/12/26


### Introduction

Nginx has no builtin CGI support for it cannot call external executables directly, but it allows to perform external executables via the FastCGI interface.

In Linux, FastCGI works in a socket, file socket: unix:/var/run/xxx.socket or Ip socket: 127.0.0.1:9000.

To add CGI support, some extra wrappers must be installed, the wrappers are servers who can fire a thread which execute the external programs, the architecture looks like:

  * Post

      * Internet &#8211;> Nginx &#8211;> socket &#8211;> FastCGI/Wrappers &#8211;> CGI Applications

  * Get

      * Internet <&#8211; Nginx <&#8211; socket <&#8211; FastCGI/Wrappers <&#8211; CGI Applications

### Install FastCGI

First off, Nginx does not provide FastCGI for you, so you’ve got to have a way to spawn your own FastCGI processes, here install spawn-fcgi.

<pre>$ sudo apt-get install spawn-fcgi
</pre>

### PHP: php5-fpm

To support PHP, the php5-fpm should be installed:

<pre>$ sudp apt-get install php5-fpm
</pre>

Then, configure your site&#8217;s configuration: /etc/nginx/site-available/default

<pre>server {
    ...
    index index.php index.html index.htm index.xml index.xhtml;
    ...
    location / {
        try_files $uri $uri/ /index.php?q=$request_uri;
    }
    ...
    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
</pre>

Then, start the server:

<pre>$ sudo service fcgiwrap restart
</pre>

### Shell, Perl: fcgiwrap

To support the other CGI scripts, we can install fcgiwrap.

<pre>$ sudo apt-get install fcgiwrap
</pre>

Configure it, first off, copy the example config to /etc/nginx:

<pre>$ dpkg -L fcgiwrap | grep nginx.conf
/usr/share/doc/fcgiwrap/examples/nginx.conf
$ cp /usr/share/doc/fcgiwrap/examples/nginx.conf /etc/nginx/fcgiwrap.conf
</pre>

Then, include the file to the server note of your site&#8217;s configuration: /etc/nginx/site-available/default

<pre>server {
    ...
    include /etc/nginx/fcgiwrap.conf;
}
</pre>

The fcgiwrap.conf looks like:

<pre># Include this file on your nginx.conf to support debian cgi-bin scripts using
# fcgiwrap
location /cgi-bin/ {
  # Disable gzip (it makes scripts feel slower since they have to complete
  # before getting gzipped)
  gzip off;

  # Set the root to /usr/lib (inside this location this means that we are
  # giving access to the files under /usr/lib/cgi-bin)
  root  /usr/lib;

  # Fastcgi socket
  fastcgi_pass  unix:/var/run/fcgiwrap.socket;

  # Fastcgi parameters, include the standard ones
  include /etc/nginx/fastcgi_params;

  # Adjust non standard parameters (SCRIPT_FILENAME)
  fastcgi_param SCRIPT_FILENAME  /usr/lib$fastcgi_script_name;
}
</pre>





 [2]: http://tinylab.org
