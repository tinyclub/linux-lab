FROM dorowu/ubuntu-desktop-lxde-vnc
MAINTAINER Falcon wuzhangjin@gmail.com

RUN sed -i -e "s/archive.ubuntu.com/mirrors.163.com/g" /etc/apt/sources.list

RUN apt-get -y update

COPY tools/ruby-switch /
COPY tools/jekyll-start /

RUN apt-get install -y vim git ca-certificates
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

EXPOSE 6080
EXPOSE 4000
EXPOSE 5900
EXPOSE 22

ENTRYPOINT ["/jekyll-start"]
