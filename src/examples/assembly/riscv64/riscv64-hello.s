#
# Ref: https://github.com/riscv/riscv-asm-manual/blob/master/riscv-asm.md
#      __NR_write, __NR_exit defined include/uapi/asm-generic/unistd.h
#

    .text
    .globl _start
_start:
                                 # write(1, msg, len)
    li a0, 1                     # write to stdout
    lui a1,       %hi(msg)       # load msg(hi)
    addi a1, a1,  %lo(msg)       # load msg(lo)
    lw a2, len                   # length of the msg

    li a7, 64                    # __NR_write
    scall

                                 # exit(0)
    li a0, 0                     # return 0
    li a7, 93                    # __NR_exit
    scall

    .section .rodata
msg:
    .string "Hello, RISC-V 64!\n"
    # len = . - msg              # If want to use 'li' instead of 'lw', this .rodata section must be put before the .text section in this file, gcc 9.3

len:
    .word . - msg
