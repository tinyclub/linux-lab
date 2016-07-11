#!/bin/bash

## Enable network bridge support

/enable_net_bridge.sh

## Start Net servers
/restart-net-servers.sh

## Fire the original /startup.sh

/startup.sh
