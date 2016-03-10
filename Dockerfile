FROM ubuntu:14.04
MAINTAINER Falcon wuzhangjin@gmail.com

RUN sed -i -e "s/archive.ubuntu.com/mirrors.163.com/g" /etc/apt/sources.list

RUN apt-get -y update

ADD tools/ruby-switch /
ADD tools/jekyll-start /

RUN apt-get install -y nginx
RUN apt-get install -y gcc make rake nodejs

RUN apt-get install -y ruby2.0 ruby2.0-dev
RUN /ruby-switch 2.0

RUN gem sources -r http://rubygems.org/
RUN gem sources -r https://rubygems.org/
RUN gem sources -a https://ruby.taobao.org/

RUN gem install iconv
RUN gem install jekyll
RUN gem install jekyll-paginate

WORKDIR /tinylab.org/
RUN rm -r /usr/share/nginx/html
RUN ln -sf /tinylab.org/_site /usr/share/nginx/html

EXPOSE 80

ENTRYPOINT ["/jekyll-start"]
