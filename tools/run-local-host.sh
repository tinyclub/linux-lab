# nfsd.ko must be inserted to enable nfs kernel server

which lsmod 2>&1 > /dev/null

if [ $? -eq 0 ]; then
	lsmod | grep -q nfsd
	[ $? -ne 0 ] && sudo modprobe nfsd
fi
