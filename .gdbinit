python import time; print ("\nWaiting for 1 secs..."); time.sleep(1)
python print ("\nExecuting gdb commands in local .gdbinit ...")

python print ("\n(gdb) target remote :1234")
target remote :1234

python import time; time.sleep(1)
python print ("\n(gdb) break start_kernel")
break start_kernel

python import time; time.sleep(1)
python print ("\n(gdb) break time_init")
break time_init

python import time; time.sleep(1)
python print ("\n(gdb) break do_fork")
break do_fork
break _do_fork

python import time; time.sleep(1)
python print ("\n(gdb) c")
c

python import time; time.sleep(1)
python print ("\n(gdb) c")
c

python import time; time.sleep(1)
python print ("\n(gdb) bt")
bt
