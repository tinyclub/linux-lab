FROM dorowu/ubuntu-desktop-lxde-vnc
MAINTAINER Falcon wuzhangjin@gmail.com

RUN sed -i -e "s%/archive.ubuntu.com%/cn.archive.ubuntu.com%g" /etc/apt/sources.list

RUN apt-get -y update

RUN apt-get install -y vim
RUN apt-get install -y git
RUN apt-get install -y ca-certificates
RUN apt-get install -y nginx
RUN apt-get install -y gcc
RUN apt-get install -y make
RUN apt-get install -y nodejs
RUN apt-get install -y ruby2.0
RUN apt-get install -y ruby2.0-dev

ADD ruby-switch /
RUN /ruby-switch 2.0

RUN gem sources -r http://rubygems.org/
RUN gem sources -r https://rubygems.org/
RUN gem sources -a https://ruby.taobao.org/

RUN gem install iconv
RUN gem install jekyll
RUN gem install jekyll-paginate

ADD lab.desktop /
ADD jekyll.desktop /
ADD lab-name /
ADD startup.sh /

# Tune the screen size
ADD supervisord.conf /etc/supervisor/conf.d/

WORKDIR /tinylab.org/

EXPOSE 6080

ENTRYPOINT ["/startup.sh"]
