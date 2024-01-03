#!/usr/bin/python3
#
# getip.py  -- get ip address via serial port
#
# Copyright (C) 2020 Wu Zhangjin <falcon@tinylab.org>
#
# Usage: ./getip.py /dev/ttyUSB0 115200
#
# Note: let this script run without password: `passwd -d USER_NAME`
#

import time
import serial
import sys
import re

ip_cmd = "ifconfig | grep 'inet ' | grep -v 127.0.0.1 | tail -1 | tr -d -c '^[0-9. ]' | awk '{print $1}'"

if len(sys.argv) <= 2:
  run_cmd = sys.argv[1] if len(sys.argv) > 1 else ip_cmd
  serial_port = '/dev/ttyUSB0'
  serial_baudrate = '115200'
  login_user = 'debian'
  login_pass = 'linux-lab'
else:
  serial_port = sys.argv[1] if len(sys.argv) > 1 else '/dev/ttyUSB0'
  serial_baudrate = sys.argv[2] if len(sys.argv) > 2 else '115200'
  login_user = sys.argv[3] if len(sys.argv) > 3 else 'debian'
  login_pass = sys.argv[4] if len(sys.argv) > 4 else 'linux-lab'
  run_cmd = sys.argv[5] if len(sys.argv) > 5 else ip_cmd

# configure the serial connections (the parameters differs on the device you are connecting to)
ser = serial.Serial(
    port = serial_port,
    baudrate = serial_baudrate,
    rtscts = False,
    dsrdtr = False,
    timeout = 1
)

ser.isOpen()

# send the character to the device
ser.write(b"\n")
out = b''
# let's wait one second before reading output (let's give device time to answer)
time.sleep(0.1)
while ser.inWaiting() > 0:
    out += ser.read(1)

if (out.decode("utf-8").find("$ ")) == -1 and (out.decode("utf-8").find("# ")) == -1:
    ser.write(b"\n")
    while out.decode("utf-8").find("login:") == -1:
        out = b''
        time.sleep(0.2)
        while ser.inWaiting() > 0:
            out += ser.read(1)
        #if out != '':
        #    print (out.decode("utf-8"))
        if (out.decode("utf-8").find("=> ")) != -1:
            ser.write(b"boot\n");

    ser.write(login_user.encode() + b"\r\n")
    while out.decode("utf-8").find("Password:") == -1:
        out = b''
        time.sleep(0.2)
        while ser.inWaiting() > 0:
            out += ser.read(1)
        #if out != '':
        #    print (out.decode("utf-8"))

    ser.write(login_pass.encode() + b"\r\n")
    while out.decode("utf-8").find("$ ") == -1 and (out.decode("utf-8").find("# ")) == -1:
        out = b''
        time.sleep(0.5)
        while ser.inWaiting() > 0:
            out += ser.read(1)
        #if out != '':
        #    print (out.decode("utf-8"))

ser.write(run_cmd.encode("utf-8") + b"\r\n")
out = b''

while out.decode("utf-8").find("$ ") == -1 and (out.decode("utf-8").find("# ")) == -1:
    out = b''
    time.sleep(0.2)
    while ser.inWaiting() > 0:
        out += ser.read(1)

    if out != '':
        for l in out.decode("utf-8").split("\r\n"):
            if re.search("^(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$", l):
                print("%s" % l)
