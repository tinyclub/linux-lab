#!/usr/bin/python3
#
# run.py  -- run command via serial port
#
# Copyright (C) 2024 Wu Zhangjin <falcon@tinylab.org>
#
# Usage: ./run.py command /dev/ttyUSB0 115200
#
# Note: let this script run without password: `passwd -d USER_NAME`
#

import time
import serial
import sys
import re

if len(sys.argv) <= 2:
  run_cmd = sys.argv[1] if len(sys.argv) > 1 else "ls /"
  serial_port = '/dev/ttyUSB0'
  serial_baudrate = '115200'
  login_user = 'debian'
  login_pass = 'linux-lab'
else:
  serial_port = sys.argv[1] if len(sys.argv) > 1 else '/dev/ttyUSB0'
  serial_baudrate = sys.argv[2] if len(sys.argv) > 2 else '115200'
  login_user = sys.argv[3] if len(sys.argv) > 3 else 'debian'
  login_pass = sys.argv[4] if len(sys.argv) > 4 else 'linux-lab'
  run_cmd = sys.argv[5] if len(sys.argv) > 5 else "ls"

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

if not re.search("$ |# ", out.decode("utf-8")):
    ser.write(b"\n")
    while not re.search("$ |# |login:", out.decode("utf-8")):
        out = b''
        time.sleep(0.2)
        while ser.inWaiting() > 0:
            out += ser.read(1)
        #if out != '':
        #    print (out.decode("utf-8"))
        if (out.decode("utf-8").find("=> ")) != -1:
            ser.write(b"run bootcmd\n");
        if (out.decode("utf-8").find("cv180x_c906# ")) != -1:
            ser.write(b"run bootcmd\n");

    ser.write(login_user.encode() + b"\r\n")
    while not re.search("$ |# |Password:", out.decode("utf-8")):
        out = b''
        time.sleep(0.2)
        while ser.inWaiting() > 0:
            out += ser.read(1)
        #if out != '':
        #    print (out.decode("utf-8"))

    ser.write(login_pass.encode() + b"\r\n")
    while not re.search("$ |# ", out.decode("utf-8")):
        out = b''
        time.sleep(0.5)
        while ser.inWaiting() > 0:
            out += ser.read(1)
        #if out != '':
        #    print (out.decode("utf-8"))

if (out.decode("utf-8").find("cv180x_c906# ")) != -1:
    ser.write(b"run bootcmd\n");

    while not re.search("$ |# ", out.decode("utf-8")):
        out = b''
        time.sleep(0.5)
        while ser.inWaiting() > 0:
            out += ser.read(1)
        #if out != '':
        #    print (out.decode("utf-8"))

ser.write(run_cmd.encode("utf-8") + b"\r\n")
out = b''
time.sleep(0.5)
while ser.inWaiting() > 0:
    out += ser.read(1)
if out != '':
    print (out.decode("utf-8"))
