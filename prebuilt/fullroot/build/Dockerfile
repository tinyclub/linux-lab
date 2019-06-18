FROM scratch

MAINTAINER Wu Zhangjin <wuzhangjin@gmail.com>
ENV DEBIAN_FRONTEND noninteractive
ARG ROOTDIR

ADD $ROOTDIR/ /

WORKDIR /root/

ENTRYPOINT ["/bin/bash"]
