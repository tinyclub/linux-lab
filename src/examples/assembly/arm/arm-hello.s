# thumb code are added in arm assembly as demonstration

    /* .arm @ .code 32 */
    .text
    .globl _start

_start:
                        /* syscall write(int fd, const void *buf, size_t count) */
    mov     %r0, $1     /* fd -> stdout */
    ldr     %r1, =msg   /* buf -> msg */
    mov     %r2, #len   /* count -> len(msg) */

    mov     %r7, $4     /* write is syscall #4 */
    swi     $0          /* invoke syscall */

    blx     _thumb      /* call thumb from arm, just for demo, not really required for pure arm mode */

                        /* syscall exit(int status) */
    mov     %r0, $0     /* status -> 0 */
    mov     %r7, $1     /* exit is syscall #1 */
    swi     $0          /* invoke syscall */

    /* thumb code begin, just for demo */
    .thumb @ .code 16
    .thumb_func         /* must tell gcc the func is thumb func */
_thumb:
    mov    %r0, $0      /* do whatever you want here */
    bx     %lr          /* back from thumb to arm, we can simply use `blx _label` too */
    /* thumb code end */

    .section .rodata    /* rodata section*/
msg:
    .ascii "Hello, ARM!\n"
    len = . - msg
