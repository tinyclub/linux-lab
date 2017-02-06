#!/bin/bash

dpkg -l | grep "ii  gcc.*gnu" | tr -s ' ' | cut -d' ' -f2
