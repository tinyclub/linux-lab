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

serial_port = sys.argv[1] if len(sys.argv) > 1 else '/dev/ttyUSB0'
serial_baudrate = sys.argv[2] if len(sys.argv) > 2 else '115200'

# configure the serial connections (the parameters differs on the device you are connecting to)
ser = serial.Serial(
    port = serial_port,
    baudrate = serial_baudrate,
    rtscts=True,
    dsrdtr=True,
    timeout = 1
)

ser.isOpen()

# send the character to the device
# (note that I happend a \r\n carriage return and line feed to the characters - this is requested by my device)
ser.write(b"ifconfig | grep 'inet ' | tr -d -c '^[0-9. ]' | awk '{print $1}'\r\n")
out = b''
# let's wait one second before reading output (let's give device time to answer)
time.sleep(1)
while ser.inWaiting() > 0:
    out += ser.read(1)

if out != '':
    print (out.decode("utf-8").split("\r\n")[1])
