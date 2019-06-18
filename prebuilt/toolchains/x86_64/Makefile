VERSION ?= gcc-8

TC = $(VERSION)

all:
	add-apt-repository -y ppa:ubuntu-toolchain-r/test
	apt-get -y update
	apt-get install -y --force-yes $(TC)
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/$(TC) 46

clean:
	apt-get remove --purge $(TC)
