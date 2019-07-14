CCVER ?= gcc-8

ifneq ($(shell which $(CCVER) 2>&1 >/dev/null; echo $$?),0)
all:
	add-apt-repository -y ppa:ubuntu-toolchain-r/test
	apt-get -y update
	apt-get install -y --force-yes $(CCVER)
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/$(CCVER) 46
endif

list:
	update-alternatives --list gcc

clean:
	apt-get remove --purge $(CCVER)
