
1. buildroot: libfakeroot error

    rm -rf output/aarch64/buildroot-cortex-a57/build/_fakeroot.fs 
    rm -rf output/aarch64/buildroot-cortex-a57/build/host-fakeroot-1.20.2/
    rm -rf output/aarch64/buildroot-cortex-a57/host/usr/bin/{tic,toe,tset,clear,infocmp,tput,tabs}
    make root
