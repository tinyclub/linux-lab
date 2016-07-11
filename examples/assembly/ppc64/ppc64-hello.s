    .data                       # section declaration - variables only
msg:
    .string "Hello, world!\n"
    len = . - msg       # length of our dear string
.text                       # section declaration - begin code
    .global _start
    .section        ".opd","aw"
    .align 3
_start:
    .quad   ._start,.TOC.@tocbase,0
    .previous
    .global  ._start
._start:
# write our string to stdout
    li      0,4         # syscall number (sys_write)
    li      3,1         # first argument: file descriptor (stdout)
                        # second argument: pointer to message to write
    # load the address of 'msg':
                        # load high word into the low word of r4:
    lis 4,msg@highest   # load msg bits 48-63 into r4 bits 16-31
    ori 4,4,msg@higher  # load msg bits 32-47 into r4 bits  0-15
    rldicr  4,4,32,31   # rotate r4's low word into r4's high word
                        # load low word into the low word of r4:
    oris    4,4,msg@h   # load msg bits 16-31 into r4 bits 16-31
    ori     4,4,msg@l   # load msg bits  0-15 into r4 bits  0-15
    # done loading the address of 'msg'
    li      5,len       # third argument: message length
    sc                  # call kernel
# and exit
    li      0,1         # syscall number (sys_exit)
    li      3,1         # first argument: exit code
    sc                  # call kernel
