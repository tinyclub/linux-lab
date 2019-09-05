CCVER ?= gcc-8

ifneq ($(shell which $(CCVER) 2>&1 >/dev/null; echo $$?),0)
all:
	add-apt-repository -y ppa:ubuntu-toolchain-r/test
	apt-get -y update
	apt-get install -y --force-yes $(CCVER)
	apt-get install -y --force-yes libc6-dev libc6-dev-i386 lib32gcc-8-dev #gcc-multilib
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/$(CCVER) 46
endif

dummy:

clean:
	apt-get remove --purge $(CCVER)
