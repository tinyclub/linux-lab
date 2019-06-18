VERSION ?= 8.3-2019.03

TC_BASE = gcc-arm-$(VERSION)-x86_64-aarch64-linux-gnu
TC_URL  = https://developer.arm.com/-/media/Files/downloads/gnu-a/$(VERSION)/binrel/$(TC_BASE).tar.xz
TC_TAR  = $(notdir $(TC_URL))

all:
	wget -c $(TC_URL)
	tar Jxvf $(TC_TAR)

clean:
	rm -rf $(TC_BASE)
