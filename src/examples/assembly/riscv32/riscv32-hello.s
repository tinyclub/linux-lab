#
# Ref: https://github.com/riscv/riscv-asm-manual/blob/master/riscv-asm.md
#      __NR_write, __NR_exit defined include/uapi/asm-generic/unistd.h
#

    .section .rodata
msg:
    .string "Hello, RISC-V 32!\n"
    len = . - msg                # to use 'li', this .rodata section must be put before the .text section in this file, gcc 9.3
                                 # otherwise, we should use 'lw' with "len: .word . - msg"
    .text
    .globl _start
_start:
                                 # write(1, msg, len)
    li a0, 1                     # write to stdout
    lui a1,       %hi(msg)       # load msg(hi)
    addi a1, a1,  %lo(msg)       # load msg(lo)
    li a2,        len            # length of the msg

    li a7, 64                    # __NR_write
    ecall

    li a0, 0
    li a7, 93                    # __NR_exit
    ecall
