FROM ubuntu:14.04
MAINTAINER Falcon wuzhangjin@gmail.com

RUN sed -i -e "s/archive.ubuntu.com/mirrors.163.com/g" /etc/apt/sources.list

RUN apt-get -y update

RUN apt-get install -y nginx
RUN apt-get install -y gcc
RUN apt-get install -y make
RUN apt-get install -y nodejs
RUN apt-get install -y ruby2.0
RUN apt-get install -y ruby2.0-dev

ADD tools/ruby-switch /
RUN /ruby-switch 2.0

RUN gem sources -r http://rubygems.org/
RUN gem sources -r https://rubygems.org/
RUN gem sources -a https://ruby.taobao.org/

RUN gem install iconv
RUN gem install jekyll
RUN gem install jekyll-paginate

WORKDIR /jekyll/
RUN rm -r /usr/share/nginx/html
RUN ln -sf /jekyll/_site /usr/share/nginx/html

EXPOSE 80

ADD tools/jekyll-start /

ENTRYPOINT ["/jekyll-start"]
