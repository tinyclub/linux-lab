#!/bin/bash
#
# Restart net servers
#

service tftpd-hpa restart
sleep 1
service rpcbind restart
sleep 1
service nfs-kernel-server restart
