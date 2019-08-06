---
layout: post
author: 'Wu Zhangjin'
title: "MIPS / Linux 汇编语言编程实例"
permalink: /practical-mips-assembly-language-programming-in-linux/
category:
  - 汇编
  - MIPS
tags:
  - Linux
  - 实例
---

> By Falcon of TinyLab.org
> 2009-01-18

## Hello, MIPS Assembly Programmer!

Hello, MIPS Assembly Programmer, I'm also a newbie of MIPS Assembly
Programmer, and here is the practical & "step by step" examples of MIPS
Assembly Lanaguage Programming in Linux. which will give us a quick start of
MIPS Assembly Programming and safely say goodbye to the other boring materials.

At first, I will say "hello" to you in our first MIPS assembly language
program. and also to the world of MIPS :-)

But how to say? we should prepare the compiling & executing environment of MIPS
Assembly Language programs first of all. and which environment? a real MIPS
machine, such as FULOONG MINI machine(loongson 2e/2f inside) or a MIPS emulator,
such as qemu, gxemul, SPIM and so forth, or even a cross compiler with qemu-user-static.

To install MIPSel debian on Qemu, please read [Debian on an emulated MIPS(EL)
machine][4] or if want to use the method about qemu-user-static, please take a
look at [Linux Assembly Language Quick Start][1].

Some of the examples are on tested in a MIPS/Linux system on qemu, so, they
may not work with qemu-user-static, but they should be available in the Linux
on a real MIPS machine.

Now, Let's say hello to the MIPS Assembly Language programming world:

    # File: hello.s -- Say Hello to MIPS Assembly Language Programmer
    #
    # Author: falcon <wuzhangjin@gmail.com>, 2009/01/17
    #
    # Ref:
    #    * http://www.tldp.org/HOWTO/Assembly-HOWTO/mips.html
    #    * MIPS Assembly Language Programmer's Guide
    #    * See MIPS Run Linux(second version)
    # Compile:
    #    $ sudo apt-get install gcc-4.3-mipsel-linux-gnu qemu-user-static
    #    $ mipsel-linux-gnu-gcc hello.s -static
    #    $ ./a.out

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp      # setup the pointer to global data
        .set reorder
                         # print sth. via sys_write
        li $a0, 1        # print to standard ouput
        la $a1, stradr   # set the string address
        lw $a2, strlen   # set the string length
        li $v0, 4004     # index of sys_write:
                         # __NR_write in /usr/include/asm/unistd.h
        syscall          # causes a system call trap.

                         # exit via sys_exit
        move $a0, $0     # exit status as 0
        li $v0, 4001     # index of sys_exit
                         # __NR_exit in /usr/include/asm/unistd.h
        syscall

        .rdata
    stradr: .asciiz "Hello, World!\n"
    strlen: .word . - stradr # current address - the string address

In this demo, we showed how to use system calls provided by Linux,
including the `sys_write` and `sys_exit`. And also introduced that there is
a need to include the following instructions in the MIPS Assebmly
Language program in Linux.

    .set noreorder
    .cpload $gp
    .set reorder

We will introduce MIPS/Linux system call usage standalonely in the last
section.

## Operate hardware

### Operate memory: load & store

There are some load instructions for loading data from memory to registers,
such as `lw`, `lh`, `lb`. If without the `u` postfix, using sign extension.

Here is a demo, load.s:

    # File: load.s -- load data(w/hw/b) from memory to a temp register

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp
        .set reorder

        lw $t0, memory
        lh $t1, memory
        lb $t2, memory

        lhu $t3, memory
        lbu $t4, memory

        .rdata
        .align 4
    memory:
        .word 0xABCDE080

Now, let's take a look at the back of the load instructions as following (This
example is on a real MIPS machine).

    $ echo $MACHTYPE    // big endian, just like x86
    mips-unknown-linux-gnu
    $ gcc -g -o load load.s    // compile with debugging info
    $ gdb ./load        // trace the excuting procedure with gdb command
    GNU gdb 6.8-debian
    ...
    This GDB was configured as "mips-linux-gnu"...
    (gdb) break main
    Breakpoint 1 at 0x400678: file load.s, line 8.
    (gdb) r            // start running & stop before the first instruction
    Starting program: /root/load
    
    Breakpoint 1, main () at load.s:11
    11        lw $t0, memory
    Current language:  auto; currently asm
    (gdb) p/x memory   // hex value in the memory address
    $1 = 0xabcde080
    (gdb) p/x $t0      // before excuting any instruction
    $2 = 0x2ac4c2e4
    (gdb) s            // execute the first instruction: lw $t0, memory
    12        lh $t1, memory
    (gdb) p/x $t0
    $3 = 0xabcde080
    (gdb) s
    13        lb $t2, memory
    (gdb) p/x $t1
    $4 = 0xffffabcd
    (gdb) s
    15        lhu $t3, memory
    (gdb) p/x $t2
    $5 = 0xffffffab
    (gdb) s
    16        lbu $t4, memory
    (gdb) p/x $t3
    $6 = 0xabcd
    (gdb) s
    0x004006cc in main ()
    (gdb) p/x $t4
    $7 = 0xab

And of course, there are some store instructions for storing data to the
memory, such as `sw`, `sh`, `sb`:

    # store.s -- swap data in the memory address: x & y

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp
        .set reorder

        lw $t0, y
        lw $t1, x
        sw $t0, x
        sw $t1, y

        .data
    x:
        .word 0x000000FF
    y:
        .word 0xABCDE080

And the debug information on a real MIPS machine:


    $ gcc -o store store.s -g
    $ gdb ./store
    ...
    (gdb) break main
    Breakpoint 1 at 0x400678: file store.s, line 8.
    (gdb) r
    Starting program: /root/store
    
    Breakpoint 1, main () at store.s:11
    11        lw $t0, y
    Current language:  auto; currently asm
    (gdb) p/x x
    $1 = 0xff
    (gdb) p/x y
    $2 = 0xabcde080
    (gdb) s
    12        lw $t1, x
    (gdb) s
    13        sw $t0, x
    (gdb) s
    14        sw $t1, y
    (gdb) s
    0x004006b8 in main ()
    (gdb) p/x x
    $3 = 0xabcde080
    (gdb) p/x y
    $4 = 0xff


### Operate registers

MIPS can move data between registers directly via the move instruction, In
fact, `move` is a pseudo instruction which equal to the real MIPS instruction:

    move r, s <==>    or r, s, $0

`or` is a logical operation which will be introduced in the next section, Here is
a demo of using move instruction.

    # move.s -- swap data in two registers with move instruction

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp
        .set reorder

        lw $t0, x   # init
        lw $t1, y
                    # swap
        move $t2, $t0       # t0 -> t2
        move $t0, $t1       # t1 -> t0
        move $t1, $t2       # t2(t0) -> t1

        .rdata
    x:
        .word 0x000000ff
    y:
        .word 0xabcde080

Pseudo instructions are also defined in the MIPS standard, which can be used by
the assembly programmer and translated into the real MIPS instructions via the
assemblers. for examples:

    not r, s <==> nor r, s, $0
    move r, s <==> or r, s, $0
    li r, c <==> ori r, $0, c

Here is a demo of using pseudo instruction.

    # replace.s -- replace the low byte of $t0 by the low byte of $t1, leaving $t0
    # otherwise intact via using bitmasks and logical instructions

        .text
        .globl main
    main:
        li $t0, 0x11223344
        li $t1, 0x88776655
        # paste the low byte of $t1 into the low byte of $t0
        # ($t0 = 0x11223355)
        and $t0, $t0, 0xffffff00
        and $t1, $t1, 0xff
        or $t0, $t0, $t1

## Calculation

Up to now, we just play with the hardwares, in reality, we need to do some real
things: calculation

### Logical calculation

At first, let's learn how to do some logical operations in MIPS. There are lots
of logical operating instructions, such as `and`,`andi`, `or`, `ori`, `nor`, `xor`, `xori`,
`not`.

This demo will show how to swap two number in two registers via `xor` instruction.

    # xor.s -- swap two number in two registers, $t0 and $t1

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp
        .set reorder

        lw $t0, x
        lw $t1, y

        xor $t0, $t0, $t1
        xor $t1, $t0, $t1
        xor $t0, $t0, $t1

        .rdata
    x:
        .word 0x000000ff
    y:
        .word 0xabcde080

### Arithmetical calculation

Now, it's time to introduce the arithmatical calculation, which include
`+`,`-`,`*`,`/`, concretely, `add`,`addu`,`addi`,`addiu`,`sub`,`subu`,`mulo`,`mul`,`div`,`divu`, and
of course, the other related operations, such as `abs`, `neg`, `negu`, `rem`, `remu`,
`sll`, `sllv`, `srl`, `srlv`, `sra`, `srav`, `rol`, `ror`. some of these instructions also be
classified into bit operating instructions or shift/rotate instructions.

    # calc.s -- a not complex arithmetical operations
    #
    # (x^2 + y^2)/(x^2 - y^2): 
    #
    # 1. $t0 <- x^2, $t1 <- y^2
    # 2. $t2 <- $t0 + $t1, $t3 <- $t0 - $t1
    # 3. $t4 <- $t2 / $t3 (quotient)
    # 4. $t5 <- $t2 / $t3 (remainder)

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp
        .set reorder

        li $t6, 3           # x
        li $t7, 2           # y
        
        mul $t0, $t6, $t6   # x^2
        mul $t1, $t7, $t7   # y^2
        add $t2, $t0, $t1   # x^2 + y^2
        sub $t3, $t0, $t1   # x^2 - y^2
                            # (x^2+y^2)/(x^2-y^2)
        div $t5, $t2, $t3   # remainder(lo)
        mfhi $t4            # quotient(hi)

## Flow control

MIPS provides two methods to change the flow control, one is the
unconditionally, another is depending on the specified condition, e.g.
equality of two registers.

fib.s:

    # fib.s -- compute the fibonacii numbers...
    #
    # $a0, parameter n
    # $v0, last Fibonacci number computed so far(and result)
    # t0, second last Fibonacci number computed so far
    # t1, temporary scratch register

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp
        .set reorder

        li $a0, 1    # fib(n): paramter n
        
        move $v0, $a0  # n < 2 => fib(n) = n
        blt $a0, 2, done

        li $t0, 0
        li $v0, 1

    fib:
        add $t1, $t0, $v0
        move $t0, $v0
        move $v0, $t1
        sub $a0, $a0, 1
        bgt $a0, 1, fib

    done:
        sw $v0, result 
        
        .data
    result:
        .word 0x11111111

booth.s:

    # booth.s -- multiply two's complement numbers, equivalent functionality is provided by MIPS instruction mult

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp
        .set reorder

        li $a0, -5  # parameter A
        li $a1, 7   # parameter C
        li $v0, 0   # R <- 0
        li $t1, 0   # A(-1) <- 0
        li $t0, 32  # i <- n (32 bits)
    booth:
        and $t2, $a0, 0x00000001    # $t2 <- A0
        sll $t2, $t2, 1
        or $t2, $t2, $t1    # $t2 = A0,A(-1)
        beq $t2, 2, case10  # $t2 = 10?
        beq $t2, 1, case01  # $t2 = 01?
        b shift             # $t2 = 00 or $t2 = 11
    case10:
        sub $v0, $v0, $a1   # R <- R - C
        b shift
    case01:
        add $v0, $v0, $a1   # R <- R + C
    shift:
        and $t1, $a0, 0x00000001 # A(-1) <- A0
        and $t2, $v0, 0x00000001 # save R0
        sll $t2, $t2, 31
        srl $a0, $a0, 1     # shift right A
        or $a0, $a0, $t2    # A31 <- R0
        sra $v0, $v0, 1     # arithmetic shift right R
        sub $t0,$t0, 1      # i <- i - 1
        bnez $t0, booth     # i = 0?
                            # result in $v0,$a0

## Memory addressing modes: access consecutive ranges of memory addresses

Addressing modes include immediate address, IP related address, direct,
indirect & indexed addressing.

  Mode       | Example            |MIPS instruction(s)  | Remark [Address]
  -----------|--------------------|---------------------|--------------------
  immediate  | andi $t0, $t0, 0x03|                     | 16-bit constant embedded in instruction
  IP related | beqz $t0, done     |                     | signed 16-bit jump offset o embedded in instruction [IP + 4 × o]
  direct     | lw $t0, 0x11223344 | lui $at, 0x1122     | [0x11223344]
             |                    | lw $t0, 0x3344($at) |
  indirect   | lw $t0, ($t1)      | lw   $t0, 0($t1)    | [$t1]
  indexed    | lw $t0, 0x11223344($t1)| lui $at, 0x1122  | [0x11223344 + $t1]
             |                        | addu $at, $at, $t1 |
             |                        | lw $t0, 0x3344($at) |

Here is the very classical example of copy data from the first memory area to
another.

    # copy.s -- Copying byte sequences via lb/sb is inefficient on von-Neumann machines

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp
        .set reorder

        li $a0, 11     # length n of byte sequence
        la $a1, src    # source address
        la $a2, dst    # destination address
        and $t1, $a0, 0x03
        srl $t0, $a0, 2
    copy:
        beqz $t0, rest
        lw $t2, ($a1)
        sw $t2, ($a2)
        add $a1, $a1, 4
        add $a2, $a2, 4
        sub $t0, $t0, 1
        b copy
    rest:
        beqz $t1, done
        lb $t2, ($a1)
        sb $t2, ($a2)
        add $a1, $a1, 1
        add $a2, $a2, 1
        sub $t1, $t1, 1
        b rest
    done:

        .data
        .align 4
    src:
        .byte 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA
        .align 4
    dst:
        .space 11

Another short but not efficient implementation method is like this:

    # copy_lsb.s -- copy a sequence of n bytes from address src to address dst

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp
        .set reorder

        li $t0, 5
    copy:
        lb $t1, src($t0)
        sb $t1, dst($t0)
        sub $t0, $t0, 1
        bgez $t0, copy

        .data
    src:
        .byte 0x11, 0x22, 0x33, 0x44, 0x55, 0x66
    dst:
        .space 6

Now, let's see the buble sort algorithm implmented in MIPS Assembly Language.

    # bub.s -- Bubble sort is a simple sorting algorithm

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp
        .set reorder

        li $a0, 10          # parameter n
        sll $a0, $a0, 2     # number of bytes in array A
    outer:
        sub $t0, $a0, 8     # $t0: j-1
        li $t1, 0           # no swap yet
    inner:
        lw $t2, A+4($t0)    # $t2 <- A[j]
        lw $t3, A($t0)      # $t3 <- A[j-1]
        bgt $t2, $t3, no_swap # A[j] <= A[j-1]?
        sw $t2, A($t0)      # A[j-1] <- $t2  \ move bubble
        sw $t3, A+4($t0)    # A[j] <- $t3   / $t2 upwards
        li $t1, 1           # swap occurred
    no_swap:
        sub $t0, $t0, 4     # next array element
        bgez $t0, inner     # more?
        bnez $t1, outer     # did we swap?
        
        .data
    A:                      # array A (sorted in-place)
        .word 4,5,6,7,8,9,10,2,1,3

## Procedures(sub-routine)

The best solution to resolve the complex problem is dividing the big problem to
several parts. in programming, the relative solution is procedure(sub-routines).

And in MIPS, there is an instruction `jal` (jump and link, `$ra` <- IP+4, IP <- a),
which jumps to the given address (a procedure entry point) and records the
correct return address in register $ra. and in the calle, there is only a need
to execute `j $ra` (IP <- $ra) to return to the correct address in the caller.

Here is a very simple demo for compute the average of two numbers:

    # avr.s -- compute the average of two numbers

        .text
        .globl main
    main:

        .set noreorder
        .cpload $gp
        .set reorder

        li $a0, 9
        li $a1, 1
        jal average
        sw $v0, result

    average:
        add $v0, $a0, $a1
        sra $v0, $v0, 1
        j $ra        

        .data
    result:
        .word 0

As the above demo shows, `jal & j` is not powerful enough like the `call & ret` in
x86. before jumping to the target address, the `call` instruction save the next
address in the stack, and accordingly, when returning, the `ret` instruction get
the next address in the top of the stack and jump to it. but here, `jal & j` use
the `$ra` to save the next address, so, if we want to use recursion, there is a
need to save & restore the `$ra` ourselves.

The basic solution is like this:

|MIPS                 |   X86     | pseudo code  |     stack
|---------------------|-----------|--------------|-------------
|    jal proc         | call proc | push done    |     \/
|done:                |           | jmp  to proc |    done
|    <sys_exit>       |           |              |
|proc:                |           |              |
|    subu $sp, $sp, 4 |           |              |
|    sw   $ra, 4($sp) |           |              |
|    ...              |           |              |
|    jal proc         |           |              |   return
|return:              |           |              |
|    lw   $ra, 4($sp) |           |              |
|    addu $sp, $sp, 4 |           | pop          |    done
|    j    $ra         | ret       | jmp to done  |     /\

ok, let's implement the binary search algorithm in MIPS Assembly Language.

    # rec.s -- Recursive binary search

        .data
    first: # sorted array of 32 bit words
        .word 2, 3, 8, 10, 16, 21, 35, 42, 43, 50, 64, 69
        .word 70, 77, 82, 83, 84, 90, 96, 99, 100, 105, 111, 120
    last:    # address just after sorted array

        .text
        .globl main
    main:

    # binary search in sorted array
    # input: search value (needle) in $a0
    #         base address of array in $a1
    #         last address of array in $a2
    # output: address of needle in $v0 if found,
    #         0 in $v0 otherwise

        .set noreorder
        .cpload $gp
        .set reorder

        li $a0, 42          # needle value
        la $a1, first       # address of first array entry
        la $a2, last - 4    # address of last array entry
        jal binsearch       # perform binary search
        li $v0, 4001
        syscall

    binsearch:
        subu $sp, $sp, 4    # allocate 4 bytes on stack
        sw $ra, 4($sp)      # save return address on stack
        subu $t0, $a2, $a1  # $t0 <- size of array    
        bnez $t0, search    # if size > 0, continue search
        move $v0, $a1       # address of only entry in array
        lw $t0, ($v0)       # load the entry
        beq $a0, $t0, return  # equal to needle value? yes => return
        li $v0, 0           # no => needle not in array
        b return            # done, return
    search:
        sra $t0, $t0, 3     # compute offset of middle entry m:
        sll $t0, $t0, 2     # $t0 <- ($t0 / 8) * 4
        addu $v0, $a1, $t0  # compute address of middle entry m
        lw $t0, ($v0)       # $t0 <- middle entry m
        beq $a0, $t0, return  # m = needle? yes => return
        blt $a0, $t0, go_left # needle less than m? yes =>
                            # search continues left of m
    go_right:
        addu $a1, $v0, 4    # search continues right of m
        jal binsearch       # recursive call
        b return            # done, return
    go_left:
        move $a2, $v0       # search continues left of m
        jal binsearch       # recursive call
    return:
        lw $ra, 4($sp)      # recover return address from stack
        addu $sp, $sp, 4    # release 4 bytes on stack
        j $ra               # return to caller

## System call

The system calls usage in Linux / MIPS is something like in Linux / i386, we
use `sys_write` as an examples for showing the "likeness":

  Linux / MIPS   |    Linux / i386   |
  ---------------|-------------------|--------------------------------
  li $a0, 1      |movl $1, %ebx      | # arg1
  la $a1, stradr |movl $stradr, %ecx | # arg2
  lw $a2, strlen |movl $strlen, %edx | # arg3
  li $v0, 4004   |movl $4, %eax      | # syscall no.
                 |                   | # defined in /usr/include/asm/unistd*.h
                 |
  syscall        |int $0x80          | # activate the system call and
                 |                   | # enter into the kernel space

Here is a complete demo for showing how to use system call in Linux / i386.

    # syscall.s -- using system call in Linux/i386

        .text
        .globl main
    main:

        movl $1, %ebx
        movl $stradr, %ecx
        movl $strlen, %edx
        movl $4, %eax       # __NR_write in /usr/include/asm/unistd_32.h
        int  $0x80

        movl $0, %ebx
        movl $1, %eax       # __NR_exit in /usr/include/asm/unistd_32.h
        int  $0x80 

        .data
    stradr:
        .ascii "Hello, World!\n\r"
    strlen:
        .word . - stradr

## References

* [Linux Assembly Quick Start][1]
* [MIPS Assembly Language][2]
* [MIPS Assembly Language Programmer's Guide.pdf][3]

[1]: http://tinylab.org/linux-assembly-language-quick-start
[2]: http://www.inf.uni-konstanz.de/dbis/teaching/ws0304/computing-systems/download/rs-05.pdf
[3]: http://www.cs.unibo.it/~solmi/teaching/arch_2002-2003/AssemblyLanguageProgDoc.pdf
[4]: http://www.aurel32.net/info/debian_mips_qemu.php
