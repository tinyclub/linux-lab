#
# Ref: https://github.com/riscv/riscv-asm-manual/blob/master/riscv-asm.md
#      __NR_write, __NR_exit defined include/uapi/asm-generic/unistd.h
#

.section .text
.globl _start
_start:
	    li a0, 1
	    lui a1,       %hi(msg)       # load msg(hi)
	    addi a1, a1,  %lo(msg)       # load msg(lo)
	    lw a2, length

	    li a7, 64                    # __NR_write
	    scall

	    li a0, 0
	    li a7, 93                    # __NR_exit
	    scall

.section .rodata
msg:
	    .string "Hello Risc-V\n"
length:
	    .word . - msg
