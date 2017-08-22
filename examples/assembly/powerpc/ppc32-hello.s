    .data                       # section declaration - variables only
msg:
    .string "Hello, world!\n"
    len = . - msg       # length of our dear string
.text                       # section declaration - begin code
    .global _start
_start:
# write our string to stdout
    li      0,4         # syscall number (sys_write)
    li      3,1         # first argument: file descriptor (stdout)
                        # second argument: pointer to message to write
    lis     4,msg@ha    # load top 16 bits of &#038;msg
    addi    4,4,msg@l   # load bottom 16 bits
    li      5,len       # third argument: message length
    sc                  # call kernel
# and exit
    li      0,1         # syscall number (sys_exit)
    li      3,1         # first argument: exit code
    sc                  # call kernel
