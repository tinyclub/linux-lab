

    .text               # section declaration - begin code
    .global _start
_start:
                        # write(1, msg, len)
    li      3,1         # first argument: file descriptor (stdout)
                        # second argument: pointer to message to write
    lis     4,msg@ha    # load top 16 bits of &msg
    addi    4,4,msg@l   # load bottom 16 bits of&msg
    li      5,len       # third argument: message length

    li      0,4         # syscall number (sys_write)
    sc                  # call kernel

                        # and exit
    li      0,1         # syscall number (sys_exit)
    li      3,0         # first argument: exit code
    sc                  # call kernel

    .rdata              # section declaration - variables only
msg:
    .string "Hello, POWERPC!\n"
    len = . - msg       # length of our dear string
