# File: hello.s -- "hello, world!" in MIPS Assembly Programming
# by falcon <wuzhangjin@gmail.com>, 2008/05/21
# refer to:
#    [*] http://www.tldp.org/HOWTO/Assembly-HOWTO/mips.html
#    [*] MIPS Assembly Language Programmer’s Guide
#    [*] See MIPS Run Linux(second version)
# compile:
#       $ as -o hello.o hello.s
#       $ ld -e main -o hello hello.o


    # text section
    .text
    .globl __start
__start:
    # If compiled with gcc-4.2.3 in 2.6.18-6-qemu the following three statements are needed
    # in compiling relocatable code, to follow the PIC-ABI calling conventions and other protocols.
    .set noreorder
    .cpload $gp
    .set reorder

    # There is no need to include regdef.h in gcc-4.2.3 in 2.6.18-6-qemu
    # but you should use $a0, not a0, of course, you can use $4 directly

    # print "hello, world!" with the sys_write system call,
    # -- ssize_t write(int fd, const void *buf, size_t count);

                         # write(1, msg, len)
    li $a0, 1            # first argument: the standard output, 1
    dla $a1, msg         # second argument: the string addr
    li $a2, len          # third argument: the string len

    li $v0, 5001         # sys_write: system call number, defined as __NR_write in /usr/include/asm/unistd.h
    syscall              # causes a system call trap.

                         # exit(0)
                         # exit from this program via calling the sys_exit system call
    move $a0, $0         # or "li $a0, 0", set the normal exit status as 0
                         # you can print the exit status with "echo $?" after executing this program
    li $v0, 5058         # __NR_exit defined in /usr/include/asm/unistd.h
    syscall

    # rdata section
    .rdata
msg:
    .asciiz "Hello, MIPS64EL!\n"
    len = . - msg        # len = current address - the string address
