
    .text             // code section
    .globl _start
_start:

    mov x0, 1         // stdout has file descriptor 1
    ldr x1, =msg      // buffer to write
    mov x2, len       // size of buffer

    mov w8, 64        // sys_write() is at index 64 in kernel functions table
    svc #0            // generate kernel call sys_write(stdout, msg, len);

    mov x0, 0         // exit code
    mov w8, 93        // sys_exit() is at index 93 in kernel functions table
    svc #0            // generate kernel call sys_exit(123);

    .section .rodata  // rodata section
msg:
    .ascii "Hello, ARM64!\n"
    len = . - msg
