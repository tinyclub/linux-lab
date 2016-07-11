# nfsd.ko must be inserted to enable nfs kernel server
lsmod | grep -q nfsd
[ $? -ne 0 ] && sudo modprobe nfsd
