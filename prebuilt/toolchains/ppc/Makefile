VERSION ?= 2018.11-1

TC_BASE = powerpc-e500mc--uclibc--stable-$(VERSION)
TC_URL  = https://toolchains.bootlin.com/downloads/releases/toolchains/powerpc-e500mc/tarballs/$(TC_BASE).tar.bz2
TC_TAR  = $(notdir $(TC_URL))

all:
	wget -c $(TC_URL)
	tar jxvf $(TC_TAR)

clean:
	rm -rf $(TC_BASE)
