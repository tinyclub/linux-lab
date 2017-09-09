
## Hello C

* Basic Usage: <http://showterm.io/a98435fb1b79b83954775>
* Advanced Usage: <http://showterm.io/887b5ee77e3f377035d01>

## Usage

    $ ls
    hello.c  Makefile

    // Build with gcc and run it
    $ gcc -o hello hello.c
    $ ./hello
    Hello, World!

    // Build with make
    $ make
    gcc -g -o hello hello.c
    /research/tinylab/cloud-lab/labs/linux-lab/examples/c/hello/hello
    Hello, World!
    $ make clean
    rm -f hello hello.o hello.s hello.i

    // Build with gcc -g and debug it with gdb
    $ gcc -g -o hello hello.c
    $ gdb ./hello
    GNU gdb (Ubuntu 7.7.1-0ubuntu5~14.04.3) 7.7.1
    Reading symbols from ./hello...done.
    (gdb) l
    1	#include <stdio.h>
    2	
    3	int main(int argc, char argv[])
    4	{
    5		printf("Hello, World!\n");
    6	
    7		return 0;
    8	}
    (gdb) b 3
    Breakpoint 1 at 0x40053c: file hello.c, line 3.
    (gdb) b 7
    Breakpoint 2 at 0x400546: file hello.c, line 7.
    (gdb) r
    Starting program: /research/tinylab/cloud-lab/labs/linux-lab/examples/c/hello/hello 
    
    Breakpoint 1, main (argc=1, argv=0x7fffffffe428 "\242\347\377\377\377\177") at hello.c:5
    5		printf("Hello, World!\n");
    (gdb) bt
    #0  main (argc=1, argv=0x7fffffffe428 "\242\347\377\377\377\177") at hello.c:5
    (gdb) quit
    A debugging session is active.
    
    	Inferior 1 [process 32518] will be killed.
    
    Quit anyway? (y or n) y
