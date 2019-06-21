# ref: https://sifive.com/boards
#      https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases/download/v8.2.0-2.2-20190521/gnu-mcu-eclipse-riscv-none-gcc-8.2.0-2.2-20190521-0004-centos64.tgz

VERSION ?= 8.2.0-2.2-20190521-0004

empty =
space = $(empty) $(empty)
tmp = $(subst -,$(space),$(VERSION))
_VERSION = v$(subst -$(lastword $(tmp)),,$(VERSION))

TC_BASE = gnu-mcu-eclipse-riscv-none-gcc-$(VERSION)-centos64
TC_URL  = https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases/download/$(_VERSION)/$(TC_BASE).tgz
TC_TAR  = $(notdir $(TC_URL))

all:
	wget -c $(TC_URL)
	tar zxvf $(TC_TAR)

clean:
	rm -rf $(TC_BASE)
