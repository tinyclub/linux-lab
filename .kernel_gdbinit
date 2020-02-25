shell echo -e "\nWaiting for 1 secs..."
shell sleep 1
shell echo -e "\nExecuting gdb commands in local .gdbinit ..."

shell echo -e  "\n(gdb) target remote :1234"
target remote :1234

shell sleep 1
shell echo -e  "\n(gdb) break start_kernel"
break start_kernel

shell sleep 1
shell echo -e  "\n(gdb) break time_init"
break time_init

shell sleep 1
shell echo -e  "\n(gdb) break do_fork"
break do_fork
break _do_fork

shell sleep 1
shell echo -e  "\n(gdb) c"
c

shell sleep 1
shell echo -e  "\n(gdb) c"
c

shell sleep 1
shell echo -e  "\ngdb bt"
bt
