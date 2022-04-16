# Need to register mips64el to /proc/sys/fs/binfmt_misc/register
# Based on /usr/share/binfmts/
# See the binfmt target, this must be run in host system, not guest

CARCH   := mipsel
MABI    := 64
OFORMAT := elf64ltsmip

include ../common.mk

binfmt:
	@# ref: http://magikh0e.ihtb.org/pubHardwareHacking/AnalyzingReversingAndEmulatingFirmware.html
	@# ref: https://github.com/qemu/qemu/blob/master/scripts/qemu-binfmt-conf.sh
	sudo bash -c "echo ':mips64el:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x08\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-mips64el:' > /proc/sys/fs/binfmt_misc/register"
