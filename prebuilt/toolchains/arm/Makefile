VERSION ?= 7.4.1-2019.02

empty =
space = $(empty) $(empty)
tmp = $(subst -,$(space),$(VERSION))
_VERSION = $(basename $(firstword $(tmp)))-$(lastword $(tmp))

TC_BASE = gcc-linaro-$(VERSION)-x86_64_arm-linux-gnueabi
TC_URL  = https://releases.linaro.org/components/toolchain/binaries/$(_VERSION)/arm-linux-gnueabi/$(TC_BASE).tar.xz
TC_TAR  = $(notdir $(TC_URL))

all:
	wget -c $(TC_URL)
	tar Jxvf $(TC_TAR)

clean:
	rm -rf $(TC_BASE)
