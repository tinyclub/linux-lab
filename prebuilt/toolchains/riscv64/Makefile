# ref: https://sifive.com/boards

VERSION ?= 8.2.0-2019.02.0

TC_BASE = riscv64-unknown-elf-gcc-$(VERSION)-x86_64-linux-ubuntu14
TC_URL  = https://static.dev.sifive.com/dev-tools/$(TC_BASE).tar.gz
TC_TAR  = $(notdir $(TC_URL))

all:
	wget -c $(TC_URL)
	tar zxvf $(TC_TAR)

clean:
	rm -rf $(TC_BASE)
