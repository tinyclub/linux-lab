# ref: https://www.sifive.com/blog/all-aboard-part-1-compiler-args
# Compile options, please refer to linux-stable/arch/riscv/Makefile

# To enable compressed instruction set extension, just use `rv64imc` instead of
# `rv64im`, then, the 16bit code can be generated automatically with the other
# 32bit codes

MARCH   := rv64im
MABI    := lp64
OFORMAT := elf64lriscv

include ../common.mk
