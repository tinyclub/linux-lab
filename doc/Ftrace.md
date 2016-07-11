
# Ftrace Usage

## Documentation

[linux-stable/Documentation/trace/ftrace.txt](https://www.kernel.org/doc/Documentation/trace/ftrace.txt)

## Kernel Configuration

```
Kernel Hacking --->
  [*] Tracers --->
      [*] Kernel Function Tracer
          [*] Kernel Function Graph Tracer
      [*] Interrupts-off Latency Tracer
      [*] Scheduling Latency Tracer
      [*] Trace syscalls
      [*] enable/disable ftrace tracepoints dynamically
```

## Build kernel with Ftrace

    $ make kernel-defconfig
    $ make kernel-menuconfig  # Make sure the above options are enabled if exist
    $ make kernel

## Boot kernel with Ftrace

    $ make boot ROOTDEV=/dev/nfs  # Use NFS for share files between Qemu and Lab

    $ make boot-ng ROOTDEV=/dev/nfs  # G3beige can not boot with graphic currently

## Use it

In Lab:

    $ cp misc/ftrace/trace.sh prebuilt/root/arm/arm926t/rootfs/root/  # Use ARM as example

In Qemu:

    # ./trace.sh
    [Available Tracers]
    wakeup_rt wakeup irqsoff function sched_switch nop
    [Using tracer: function]
    [Enabling tracing]
    [Running command: ls]
    trace.sh
    [Disabling tracing]
    [Recording tracing result]
    
    Tracing [ls] log with [function] saved in /root/trace.log

    # ./trace.sh irqsoff ls # Trace [ls] with [irqsoff] tracer
