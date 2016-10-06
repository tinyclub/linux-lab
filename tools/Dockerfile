FROM dorowu/ubuntu-desktop-lxde-vnc
MAINTAINER Falcon wuzhangjin@gmail.com

RUN sed -i -e "s%/archive.ubuntu.com%/cn.archive.ubuntu.com%g" /etc/apt/sources.list

RUN apt-get -y update

RUN apt-get install -y chromium-browser

RUN apt-get install -y ruby
RUN gem sources -r http://rubygems.org/
RUN gem sources -r https://rubygems.org/
RUN gem sources -a https://ruby.taobao.org/

RUN gem install showterm

RUN apt-get install -y vim
RUN apt-get install -y git ca-certificates
RUN apt-get install -y gcc
RUN apt-get install -y make
RUN apt-get install -y nginx
RUN apt-get install -y nodejs
RUN apt-get install -y ruby2.0
RUN apt-get install -y ruby2.0-dev

ADD ruby-switch /
RUN /ruby-switch 2.0

RUN gem install iconv
RUN gem install jekyll
RUN gem install jekyll-paginate

# Chinese support
RUN apt-get install -y ibus ibus-sunpinyin dbus-x11
RUN apt-get install -y terminator
# RUN apt-get install -y fonts-arphic-bkai00mp fonts-arphic-bsmi00lp
# RUN apt-get install -y fonts-arphic-gbsn00lp fonts-arphic-gkai00mp
# RUN apt-get install -y fonts-arphic-ukai fonts-arphic-uming

ADD autostart /etc/xdg/lxsession/LXDE/autostart
ADD lab.desktop /
ADD demo.desktop /
ADD local.desktop /
ADD help.desktop /
ADD lab-name /
ADD startup.sh /

# Tune the screen size
ADD supervisord.conf /etc/supervisor/conf.d/

WORKDIR /tinylab.org/

EXPOSE 6080
EXPOSE 80

ENTRYPOINT ["/startup.sh"]
