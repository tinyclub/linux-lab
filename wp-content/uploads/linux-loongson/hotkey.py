#!/usr/bin/env python
# author: falcon <wuzhangjin@gmail.com>
# update: 2009-08-28

"""
pyhotkey -- hotkey daemon for YeeLoong netbook
"""

import commands
import os
import re
import pyosd
import dbus
import dbus.decorators
import dbus.glib
import gobject
from time import sleep

"""
init
"""

# init pyosd
font = "-*-helvetica-*-r-normal--30-*-*-*-*-*-*-*"

import locale
locale.setlocale(locale.LC_ALL, "")

p = pyosd.osd(font, colour="#4040ff", shadow=2)
p.set_shadow_offset(2)
p.set_vertical_offset(200)
p.set_bar_length(20)
p.set_align(pyosd.ALIGN_CENTER)
p.set_timeout(2)

# init hotkey input device object
udi='/org/freedesktop/Hal/devices/computer_logicaldev_input'
bus = dbus.SystemBus()
obj = bus.get_object( 'org.freedesktop.Hal', udi)

"""
volume
"""

# any available dbus interface??
def volume_handler(key):
	vol = int(commands.getoutput("amixer sget Master | tail -1 | cut -d' ' -f7 | tr -d '[]%'"))
	print "vol: " + str(vol)
	if key == "volume-up":
		vol = vol + 5
		print "vol: " + str(vol)
		if vol > 100:
			vol = 100 
	else:
		vol = vol - 5 
		print "vol: " + str(vol)
		if vol < 0:
			vol = 0
	c = "amixer -q -c 0 sset Master,0 " + str(vol) + "%," + str(vol) + "% > /dev/null"
	os.system(c)
	p.display(vol, type=pyosd.TYPE_PERCENT, line=1)
	if vol == 0:
		c = "amixer -q -c 0 sset Master,0 mute"
		os.system(c)
		p.display("Mute (X)")
	else:
		c = "amixer -q -c 0 sset Master,0 unmute"
		os.system(c)	
		p.display("Volume (%d%%)" % vol)

"""
brightness
"""

def brightness_handler(key):
	obj_brightness = bus.get_object( 'org.freedesktop.Hal', '/org/freedesktop/Hal/devices/computer_backlight' )
	iface = dbus.Interface(obj_brightness, 'org.freedesktop.Hal.Device.LaptopPanel')
	brightness = iface.GetBrightness()
	# EC have set the brigtness for us, no need to do it again.
	# brightness = brightness + 1
	# iface.SetBrightness(brightness)
	b = brightness * 100/8
	p.display("Brightness (%d%%)" % b)
	p.display(b, type=pyosd.TYPE_PERCENT, line=1)

"""
mute
"""

def mute_handler(key):
	status = commands.getoutput("amixer sget Master | tail -1 | cut -d' ' -f 9")
	print "mute: " + status
	if status == "[on]":
		print " --> [off]"
		c = "amixer -q -c 0 sset Master,0 mute"
		os.system(c)
		p.display("Mute (X)", type=pyosd.TYPE_STRING, line=0)
	else:
		print " --> [on]"
		c = "amixer -q -c 0 sset Master,0 unmute"
		os.system(c)
		p.display("UnMute (+)", type=pyosd.TYPE_STRING, line=0)

"""
wlan
"""

def wlan_handler():
	status = commands.getoutput("cat /sys/class/rfkill/rfkill0/state")
	print "wlan: " + status
	if status == "1":
		print " --> 0"
		status = "0"
	else:
		print " --> 1"
		status = "1"
	c = "echo " + status + " > /sys/class/rfkill/rfkill0/state"
	os.system(c)

"""
input signal handlers calling interface
"""

def input_signal_handler(action, key):
	print "key: " + key + " action: " + action
	if re.search("volume", key):
		volume_handler(key)
	elif re.search("brightness", key):
		brightness_handler(key)
	elif re.search("mute", key):
		mute_handler(key)
	elif re.search("wlan", key):
		wlan_handler()

obj.connect_to_signal("Condition", input_signal_handler, dbus_interface="org.freedesktop.Hal.Device")

loop = gobject.MainLoop()
loop.run()
