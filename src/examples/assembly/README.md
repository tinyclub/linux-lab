
# Hello World, Linux AT&T Assembly!

* Document: <http://tinylab.org/linux-assembly-language-quick-start/>

## Usage

    $ ls
    aarch64  arm  mips64sel  mipsel  powerpc  powerpc64	x86	x86_64

    $ make -s -C arm
    Hello, ARM!

## Comparison

  Arch     | Syscall insn   | write | exit | Args
-----------|----------------|-------|------|---------------------
  x86      | int 0x80       | 4     | 1    | eax, ebx, ecx, edx
  x86_64   | syscall        | 1     | 60   | rax, rdi, rsi, rdx
  arm      | swi            | 4     | 1    | r7, r0, r1, r2
  aarch64  | svc            | 64    | 93   | x8, x0, x1, x2
  mipsel   | syscall        | 4004  | 4001 | v0, a0, a1, a2
  mips64el | syscall        | 5001  | 5058 | v0, a0, a1, a2
  riscv32  | ecall          | 04    | 93   | a7, a0, a1, a2
  riscv64  | ecall          | 64    | 93   | a7, a0, a1, a2
  powerpc  | sc             | 4     | 1    | 0, 3, 4, 5
  powerpc64| sc             | 4     | 1    | 0, 3, 4, 5

## References

1. [Syscall](https://man7.org/linux/man-pages/man2/syscall.2.html)
2. [syscalls(2) — Linux manual page](https://man7.org/linux/man-pages/man2/syscalls.2.html)
3. [Adding a New System Call](https://www.kernel.org/doc/html/latest/process/adding-syscalls.html)
4. [System Calls](https://linux-kernel-labs.github.io/refs/heads/master/lectures/syscalls.html)
