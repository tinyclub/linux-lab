#
# Ref: https://github.com/riscv/riscv-asm-manual/blob/master/riscv-asm.md
#      __NR_write, __NR_exit defined include/uapi/asm-generic/unistd.h
#

    .text
    .globl _start
_start:
                                 # write(1, msg, len)
    li a0, 1                     # write to stdout
    la a1, msg                   # load msg
    lw a2, len                   # length of the msg

    li a7, 64                    # __NR_write
    ecall

#ifdef __NOLIBC__
                                 # reboot, based on tools/include/nolibc/sys.h
    li a0, 0xfffffffffee1dead
    li a1, 0x28121969
    li a2, 0x4321fedc
    li a3, 0
    li a7, 142
    ecall
#endif

    li a0, 0                     # return 0
    li a7, 93                    # __NR_exit
    ecall

    .section .rodata
msg:
    .string "Hello, RISC-V 64!\n"

len:
    .word . - msg
