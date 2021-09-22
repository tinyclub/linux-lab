#!/bin/bash

CURDIR=$(cd $(dirname $0)/ && pwd)

cd $CURDIR
if [ ! -f feature.downloaded ]; then
    sudo apt update -y && \
    sudo apt install -y python3-pip && \
    sudo pip install b4 && \
    b4 am CANiq72=Q+024x_Bb__RRT9e30QmcTKhzBB2=CmfukJTCjXVY-A@mail.gmail.com
    [ $? -eq 0 ] && touch feature.downloaded
fi
