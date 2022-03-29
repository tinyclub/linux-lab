---
layout: post
author: 'Wu Zhangjin'
title: "RISC-V Linux jump_label 详解，第 2 部分：指令编码"
draft: false
album: 'RISC-V Linux'
license: "cc-by-nc-nd-4.0"
permalink: /riscv-jump-label-part2/
description: "本文是对 RISC-V jump_label 架构支持分析成果的第 2 部分，主要介绍如何参考指令手册编码 Jump Label 用到的几条指令。"
category:
  - 开源项目
  - Risc-V
tags:
  - Linux
  - RISC-V
  - Tracepoint
  - Jump Label
  - 条件分支
  - 无条件跳转
  - NOP
  - JAL
  - ISA
  - 指令编码
---

> Author:  Wu Zhangjin <falcon@tinylab.org>
> Date:    2022/03/28
> Project: <https://gitee.com/tinylab/riscv-linux>

## 背景简介

该系列有多篇文章，旨在分析 RISC-V 架构上的 `jump_label` 实现。

上一篇介绍了其技术原理，`jump_label` 能够基本消除 [Tracepoint](https://www.kernel.org/doc/html/latest/core-api/tracepoint.html) 禁用状态的开销，从而确保 Tracepoint 功能可直接编译进内核，并允许线上按需启用 Tracepoints。

从上一节我们已经知道，`jump_label` 的实现包含三部分：`static_branch(foo)`, 指令编码以及运行时交换 `nop` 和 `goto label(foo)` 指令。

本节先来介绍指令编码部分，即带领大家阅读 RISC-V ISA 手册并把 `nop` 和 `goto label(foo)` 指令编码出来，继而分析 `arch/riscv/kernel/jump_label.c` 中的具体实现。

## 下载指令手册

上周的直播分享上，贾老师简单介绍了 [RISC-V ISA](https://www.cctalk.com/m/group/90251209) 相关的内容，其中提到有两个重要的手册，一个是非特权 ISA，另外一个是特权 ISA。

从 [这里](https://riscv.org/technical/specifications/) 可以找到相应的手册，其中指令编码部分属于 [非特权 ISA 手册](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf)。

需要注意的是，这个 Spec 文档并表示一成不变的，所以本文提到的页面甚至章节等都可能变动，本文以 riscv-spec-20191213.pdf 为准。

## 参考手册编码目标指令

### 指令长度

在第 1 章中明确提到：

> The base RISC-V ISA has fixed-length 32-bit instructions that must be naturally aligned on 32-bit
> boundaries.

但是：

> However, the standard RISC-V encoding scheme is designed to support ISA extensions
> with variable-length instructions, where each instruction can be any number of 16-bit instruction
> parcels in length and parcels are naturally aligned on 16-bit boundaries. The standard compressed
> ISA extension described in Chapter 16 reduces code size by providing compressed 16-bit instructions
> and relaxes the alignment constraints to allow all instructions (16 bit and 32 bit) to be aligned on
> any 16-bit boundary to improve code densit

本文讨论正常情况，即所有的指令编码长度是 32 位无符号数。

### NOP 指令编码

先来看简单一点的 `nop` 指令，这个在几乎所有架构上都有定义，但是编码却完全跟架构相关。

在非特权手册的 P20/38 页，即下述位置：

* Chapter 2. RV32I Base Integer Instruction Set
    * 2.4 Integer Computational Instructions
        * Nop Instruction

很详细的介绍了：

> The NOP instruction does not change any architecturally visible state, except
> for advancing the pc and incrementing any applicable performance counters.
> NOP is encoded as ADDI x0, x0, 0.

其编码如下：

    31   -   20|19-15|14  - 12|11 - 7|6  -   0 | Bits
    -----------|-----|--------|------|---------|------------
     imm[11:0] | rs1 | funct3 | rd   | opcode  | Instruction
    -----------|-----|--------|------|---------|------------
         12    | 5   |   3    | 5    |    7    | Bits Length
    -----------|-----|--------|------|---------|------------
         0     | 0   |  ADDI  | 0    | OP-IMM  | Encoding

其中，`x0` 被编码为 0，而 `ADDI` 的 `OP-IMM` 和 `funct3` 编码可以从 P130/148 页，即下述位置：

* Chapter 24. RV32/64G Instruction Set Listings

直接找到：


    31   -   20|19-15|14  - 12|11 - 7|6  -   0 | Bits
    -----------|-----|--------|------|---------|------------
     imm[11:0] | rs1 | funct3 |  rd  | opcode  | I-Type Instruction
    -----------|-----|--------|------|---------|------------
     imm[11:0] | rs1 |  000   |  rd  | 0010011 | ADDI

结合这两部分，确认了 `funct3` 为 `000`，而 `OP-IMM` 为 `0010011`，进而可以得到如下编码：

    31   -   20|19-15|14  - 12|11 - 7|6  -   0 | Bits
    -----------|-----|--------|------|---------|------------
     imm[11:0] | rs1 | funct3 |  rd  | opcode  | Instruction
    -----------|-----|--------|------|---------|------------
         12    | 5   |   3    |  5   |    7    | Bits Length
    -----------|-----|--------|------|---------|------------
         0     | 0   |  000   |00000 | 0010011 | Encoding

所以，NOP 的最终编码是 `00010011`，即 `0x13`，考虑指令长度为 32 位，可以定义为：

    #define RISCV_INSN_NOP 0x00000013U

### JAL/J offset 指令编码

`goto label(foo)` 是一种无条件跳转需求，并且根据上一篇的分析，其跳转范围在一条 `if` 语句后面，不会涉及长跳转，所以可以对应 `J offset` 这样一种直接跳转指令，无需寄存器存放地址后再间接跳转（对应 `JALR`）。

在最新的 ISA 手册中，硬件 `J` 指令已经被删除，变成了伪指令，其实现合并进了 `JAL` 指令，对应 `rd=x0`，所以实际上我们需要查找的是 `JAL offset` 指令的编码。

>
> Preface to Version 2.0:
>
> The JAL instruction has now moved to the U-Type format with an explicit destination
> register, and the J instruction has been dropped being replaced by JAL with rd=x0. This
> removes the only instruction with an implicit destination register and removes the J-Type
> instruction format from the base ISA. There is an accompanying reduction in JAL reach, but
> a significant reduction in base ISA complexity

找到手册的 P21/39 页，即如下位置：

* Chapter 2. RV32I Base Integer Instruction Set
    * 2.5 Control Transfer Instructions
        * Unconditional Jumps

其说明如下：

> Plain unconditional jumps (assembler pseudoinstruction J) are encoded as a JAL with rd=x0.

          31|30  -  21|  20    |19   -  12|11 - 7|6  -   0 | Bits
    --------|---------|--------|----------|------|---------|------------
    imm[20] |imm[10:1]|imm[11] |imm[19:12]|  rd  | opcode  | Instruction
    --------|---------|--------|----------|------|---------|------------
        1   |   10    |   1    |    8     |  5   |   7     | Bits Length
    --------------------------------------|------|---------|-----------
                 offset[20:1]             | dest |   JAL   | Encoding

其中这里的直接跳转也是用到 `x0` 寄存器，`dest` 可以直接同 `NOP` 指令，直接编码为 `0`，而 `JAL` 的 `OP-IMM` 同样可以从 P130/148 页，即下述位置：

* Chapter 24. RV32/64G Instruction Set Listings

直接找到：

    31       -          12|11 - 7|6  -   0| Bits
    ----------------------|------|--------|--------------------
    imm[20|10:1|11|19:12] |  rd  | opcode | J-type Instruction
    ----------------------|------|--------|---------------------
    imm[20|10:1|11|19:12] |  rd  | 1101111| JAL Encoding

接下来先把 rd 替换为 x0 寄存器并编码为 0, 则 `J offset` 指令可以编码如下：

    31       -          12|11 - 7|6  -   0| Bits
    ----------------------|------|--------|--------------------
    imm[20|10:1|11|19:12] |  rd  | opcode | J-type Instruction
    ----------------------|------|--------|---------------------
    imm[20|10:1|11|19:12] |  0   | 1101111| J offset Encoding

这里先把 `J offset` 的 `rd` 和 `opcode` 编码定义出来：

    #define RISCV_INSN_JAL 0x0000006fU

后面复杂的其实是 `offset` 的编码，这个并不是简单的把 offset 直接编码进目标指令，而是需要经过复杂的移位。

          31|30  -  21|  20    |19   -  12|11 - 7|6  -   0 | Bits
    --------|---------|--------|----------|------|---------|------------
    imm[20] |imm[10:1]|imm[11] |imm[19:12]|  rd  | opcode  | Instruction
    --------|---------|--------|----------|------|---------|------------
        1   |   10    |   1    |    8     |  5   |   7     | Bits Length
    --------------------------------------|------|---------|-----------
                 offset[20:1]             |  0   | 1101111 | J offset Encoding

比如说 offset 的第 0 位直接是舍弃的（考虑到代码指令长度和对齐要求，所以这一位其实会一直是零），剩下的是复杂的移位：

* `offset[20]` 放到目标指令的第 31 位
* `offset[10:1]` 放到目标指令的第 21-30 位
* `offset[11]` 放到目标指令的第 20 位
* `offset[12-19]` 放到目标指令的第 12-19 位

需要先取出目标位再做相对移植，比如第 11 位要移到目标指令的第 20 位，相对移动 (20-11）。

好在 Linux 内核对于取出目标位提供了专门的宏，咱们先搬运一个试试：

    ((u32)offset & GENMASK(11, 11)) << (20 - 11)

其对应 “取目标位” 和 “相对移位” 两个操作，完整的 `J offset` 指令编码则如下：

    insn = RISCV_INSN_JAL |
	(((u32)offset & GENMASK(19, 12)) << (12 - 12)) |
	(((u32)offset & GENMASK(11, 11)) << (20 - 11)) |
	(((u32)offset & GENMASK(10,  1)) << (21 -  1)) |
	(((u32)offset & GENMASK(20, 20)) << (31 - 20));

### 寄存器编码

上面介绍到的 `NOP` 和 `JAL/J offset` 指令均只用到 `x0` 寄存器，其编码为 0。

由于其他指令可能会用到寄存器编码，这里做个补充介绍。

相关寄存器（x0-x31）的编码为对应的编号 0-31，验证如下。

先准备一段简单的汇编，保存为 `test.s`：

    # test.s
        .text
        .globl _start
    _start:
        li x0, 0
        li x1, 0
        li x2, 0
        li x3, 0
        li x4, 0
        li x5, 0
        li x6, 0
        li x7, 0
        li x8, 0

        li a0, 0                     # return 0
        li a7, 93                    # __NR_exit
        scall

编译并反编译如下：

    $ riscv64-linux-gnu-gcc -march=rv64im -mabi=lp64 -nostdlib -static -o test test.s
    $ riscv64-linux-gnu-objdump -d -M no-aliases,numeric ./test

    Disassembly of section .text:

    0000000000010078 <_start>:
       10078:	00000013          	addi	x0,x0,0
       1007c:	00000093          	addi	x1,x0,0
       10080:	00000113          	addi	x2,x0,0
       10084:	00000193          	addi	x3,x0,0
       10088:	00000213          	addi	x4,x0,0
       1008c:	00000293          	addi	x5,x0,0
       10090:	00000313          	addi	x6,x0,0
       10094:	00000393          	addi	x7,x0,0
       10098:	00000413          	addi	x8,x0,0
       1009c:	00000513          	addi	x10,x0,0
       100a0:	05d00893          	addi	x17,x0,93
       100a4:	00000073          	ecall

可以看到 `li` 被实际编码为 `addi` 指令。`ADDI` 指令的编码方式已经在 `NOP 指令编码` 一节找到：

    31   -   20|19-15|14  - 12|11 - 7|6  -   0 | Bits
    -----------|-----|--------|------|---------|------------
     imm[11:0] | rs1 | funct3 | rd   | opcode  | I-Type Instruction
    -----------|-----|--------|------|---------|------------
     imm[11:0] | rs1 |  000   | rd   | 0010011 | ADDI

把 `x0-x8` 的寄存器序号 `0-8` 的二进制编码代入可以依次得到如下编码：

    31   -   20|19-15|14  - 12|11 - 7|6  -   0 | Bits
    -----------|-----|--------|------|---------|------------
     imm[11:0] | rs1 | funct3 | rd   | opcode  | I-Type Instruction
    -----------|-----|--------|------|---------|------------
             0 | 0   |  000   |00000 | 0010011 | addi x0,x0,0
             0 | 0   |  000   |00001 | 0010011 | addi x1,x0,0
             0 | 0   |  000   |00010 | 0010011 | addi x2,x0,0
             0 | 0   |  000   |00011 | 0010011 | addi x3,x0,0
             0 | 0   |  000   |00100 | 0010011 | addi x4,x0,0
             0 | 0   |  000   |00101 | 0010011 | addi x5,x0,0
             0 | 0   |  000   |00110 | 0010011 | addi x6,x0,0
             0 | 0   |  000   |00111 | 0010011 | addi x7,x0,0
             0 | 0   |  000   |01000 | 0010011 | addi x8,x0,0

`rd` 和 `opcode` 合并后，正好对应上面的反编译结果，请注意 `opcode` 只有 7 位，需要从 `rd` 编码取 1 位凑成后面 2 个十六进制编码，而两者一共 12 位，刚好构成 3 个十六进制数字。

    31   -   20|19-15|14  - 12|11 - 7|6  -   0 | Bits
    -----------|-----|--------|------|---------|------------
     imm[11:0] | rs1 | funct3 | rd   | opcode  | I-Type Instruction
    -------------------------------------------|------------
                   0x13:       0000 0001 0011  | addi x0,x0,0
                   0x93:       0000 1001 0011  | addi x1,x0,0
                  0x113:       0001 0001 0011  | addi x2,x0,0
                  0x193:       0001 1001 0011  | addi x3,x0,0
                  0x213:       0010 0001 0011  | addi x4,x0,0
                  0x293:       0010 1001 0011  | addi x5,x0,0
                  0x313:       0011 0001 0011  | addi x6,x0,0
                  0x393:       0011 1001 0011  | addi x7,x0,0
                  0x413:       0100 0001 0011  | addi x8,x0,0

这样调整一下，就很容易映射过去了。感兴趣的同学，也可以进一步阅读 [riscv-gcc](https://gitee.com/mirrors/riscv-gcc) 的源代码：`gcc/config/riscv`。

## 查看代码实现

接下来再去看代码就比较容易理解了，核心实现见 `arch/riscv/kernel/jump_label.c`：

    #define RISCV_INSN_NOP 0x00000013U
    #define RISCV_INSN_JAL 0x0000006fU

    void arch_jump_label_transform(struct jump_entry *entry,
    			       enum jump_label_type type)
    {
    	void *addr = (void *)jump_entry_code(entry);
    	u32 insn;

    	if (type == JUMP_LABEL_JMP) {
    		long offset = jump_entry_target(entry) - jump_entry_code(entry);

    		if (WARN_ON(offset & 1 || offset < -524288 || offset >= 524288))
    			return;

    		insn = RISCV_INSN_JAL |     /* J offset 指令编码 */
    			(((u32)offset & GENMASK(19, 12)) << (12 - 12)) |
    			(((u32)offset & GENMASK(11, 11)) << (20 - 11)) |
    			(((u32)offset & GENMASK(10,  1)) << (21 -  1)) |
    			(((u32)offset & GENMASK(20, 20)) << (31 - 20));
    	} else {
    		insn = RISCV_INSN_NOP;     /* NOP 指令编码 */
    	}

    	mutex_lock(&text_mutex);
    	patch_text_nosync(addr, &insn, sizeof(insn));
    	mutex_unlock(&text_mutex);
    }

本文只涉及 `insn` 编码部分，余下的部分包括如何获取和计算 `offset`，如何交换 `nop` 和 `J offset`（即 `goto label(foo)`），其中 `offset` 的获取和计算同 `static_branch(foo)` 的实现和 `jump table` 的设计密切相关。

## 小结

本文介绍了如何根据 RISC-V 的指令集手册来编码目标指令 `nop` 和 `goto label(foo)`，该方法适合类似的指令编码需求，相关需求预期会出现在编译技术、内核汇编、性能优化等领域。

接下来我们将继续探讨剩下的两部分代码实现：`static_branch(foo)` 和运行时交换 `nop` 和 `goto label(foo)` 指令。
