---
title: Measure and Draw the Boot-up Time of Linux Kernel
author: Wu Zhangjin
layout: post
permalink: /measure-and-draw-the-boot-up-time-of-linux-kernel/
views:
  - 476
tags:
  - Boot
  - bootgraph.pl
  - Draw
  - Flame Graph
  - gnuplot
  - histogram
  - Linux
  - Time
  - TinyDraw
categories:
  - Boot Time
  - Computer Language
  - Linux
  - Shell
---

> by falcon of [TinyLab.org][2]
> 2014/01/06


## Introduction

[eLinux.org/Boot_Time][3] have collected lots of resources such as measurement, analysis, human factors, initialization techniques, and reduction techniques, we don&#8217;t want to repeat them.

In this article, we will introduce how to measure the boot-up time of Linux kernel and draw it in a more visual graph.

Linux kernel does provide a tool: [scripts/bootgraph.pl][4] to draw the time cost of the initcalls, but:

  * It can not draw the time cost of the other parts, only initcalls
  * The output graph is not that helpful to find out the time-cost parts

## Measure the boot-up time of Linux kernel

First off, please make sure *initcall&#95;debug* and *printk.time=1* passed on the Linux kernel command line.

After kernel boot, dump out the kernel printk log with timestamps into a *dmesg.log* file:

<pre>$ dmesg > dmesg.log
</pre>

To get a full printk log, please make sure the printk buffer is big enough via increasing the `CONFIG_LOG_BUF_SHIFT` to a bigger value.

## Draw the Boot-up Time

### Draw it with scripts/bootgraph.pl

By default, we can use [scripts/bootgraph.pl][4] to draw the data:

<pre>$ cat dmesg.log | perl bootgraph.pl > bootgraph.svg
</pre>

See an example of [bootgraph.svg][5].

As we can see, the output is not that friendly:

  * The name of the initcalls are output vertically, can not be read comfortably
  * Can not easily find out the difference among some similar &#8216;rectangles&#8217;

Note: if the printk is hacked by you, please modify the script to make sure it can parse the printk log normally:

<pre>diff --git a/scripts/bootgraph.pl b/scripts/bootgraph.pl
index b78fca9..bd3f07c 100644
--- a/scripts/bootgraph.pl
+++ b/scripts/bootgraph.pl
@@ -51,7 +51,7 @@ my %pidctr;

 while (&lt;>) {
        my $line = $_;
-       if ($line =~ /([0-9\.]+)\] calling  ([a-zA-Z0-9\_\.]+)\+/) {
+       if ($line =~ /([0-9\.]+)\].*calling  ([a-zA-Z0-9\_\.]+)\+/) {
                my $func = $2;
                if ($done == 0) {
                        $start{$func} = $1;
@@ -66,7 +66,7 @@ while (&lt;>) {
                $count = $count + 1;
        }

-       if ($line =~ /([0-9\.]+)\] async_waiting @ ([0-9]+)/) {
+       if ($line =~ /([0-9\.]+)\].*async_waiting @ ([0-9]+)/) {
                my $pid = $2;
                my $func;
                if (!defined($pidctr{$pid})) {
@@ -87,14 +87,14 @@ while (&lt;>) {
                $count = $count + 1;
        }

-       if ($line =~ /([0-9\.]+)\] initcall ([a-zA-Z0-9\_\.]+)\+.*returned/) {
+       if ($line =~ /([0-9\.]+)\].*initcall ([a-zA-Z0-9\_\.]+)\+.*returned/) {
                if ($done == 0) {
                        $end{$2} = $1;
                        $maxtime = $1;
                }
        }

-       if ($line =~ /([0-9\.]+)\] async_continuing @ ([0-9]+)/) {
+       if ($line =~ /([0-9\.]+)\].*async_continuing @ ([0-9]+)/) {
                my $pid = $2;
                my $func =  "wait_" . $pid . "_" . $pidctr{$pid};
                $end{$func} = $1;
</pre>

### Draw it with [Flame Graph](http://www.brendangregg.com/flamegraphs.html)

The *Flame Graph* do output the functions vertically, but to draw the boot-up time, the data format must be converted to the one supported by *Flame Graph* at first, its data format looks like:

<pre>a;b;c;d; 10
a;b;e 20
f 30
g 90
</pre>

Based on bootgraph.pl, we write a [dmesg-initcalls.pl][6] to convert the data format:

<pre>$ cat dmesg.log | perl dmesg-initcall.pl > boot-initcall.log
$ head -5 boot-initcall.log
s3c_fb_init 0.091
s5p_mipi_dsi_register 0.319
pl330_driver_init 0.019
s3c24xx_serial_modinit 4.706
PVRCore_Init 0.077
</pre>

Now, draw it with *Flame Graph*:

<pre>$ git clone https://github.com/brendangregg/FlameGraph.git
$ cd FlameGraph
$ cat boot-initcall.log | ./FlameGraph/flamegraph.pl > linux-boot-flamegraph.svg
</pre>

Take a look at [linux-boot-flamegraph.svg][7].

![linux-boot-flamegraph.svg][7]

As we can see, it not only highlight the time-consuming initcalls, but also give an interactive interface.

But it is also not that friendly to compare different initcalls.

### Draw it with <a href="http://www.gnuplot.info/">gnuplot</a>

*gnuplot* is a famous plotting program, it can be used to do mathematical statistics, so, we can also use it to draw the above *boot-initcall.log*.

First off, install gnuplot-x11:

<pre>$ sudo apt-get install gnuplot-x11
</pre>

Second, prepare a gnuplot script *linux-boot.gnuplot*:

<pre>set terminal svg size 800,300 fsize 4
set output 'linux-boot-gnuplot.svg'
set style data histograms
set style histogram clustered gap 1 title offset character 0, 0, 0
set style fill solid 0.4 border
set xtics rotate by -45
set boxwidth 0.9 absolute
plot './boot-initcall.log' using 2:xticlabels(1)
</pre>

Third, draw with the above script:

<pre>$ gnuplot &lt; linux-boot.gnuplot
</pre>

After that, the [linux-boot-gnuplot.svg][8] is available.

![linux-boot-gnuplot.svg][8] is available

It looks better for it shows the time consuming initcalls obviously, but unfortunately, it is not interactively.

### Draw it with <a href="/tinydraw/">TinyDraw</a><a href="https://github.com/tinyclub/tinydraw/raw/master/histogram/histogram.sh">/histogram.sh</a>

To make a better output, based on *Frame Graph*, *Bootgraph,pl* and *gnuplot*, we write a new histogram.sh tool in our [TinyDraw][9] project.

To draw it, we can simply run:

<pre>$ git clone https://github.com/tinyclub/tinydraw.git
$ ./tinydraw/histogram/histogram.sh boot-initcall.log > linux-boot-histogram.svg
</pre>

Take a look at [linux-boot-histogram.svg][10].

![linux-boot-histogram.svg][10]

## Conclusion

Based on the above practice, we found out, to draw the data in two row format: [string, value], the histogram is a better graph.

Our [TinyDraw/histogram][11] can draw such data in an interactive SVG graph.

[TinyDraw/histogram][11] is scalable, you can use it to draw the data generated by [dmesg.sh][12] and [bootprof.sh][13]. We will add a convert script of [Grabserial][14] later.

To use it to draw the other similar data, you must refer to the above dmesg.sh or bootprof.sh to convert the original data to the "two row data" format.

  * [string, value]:

<pre>a 10
b 20
f 30
g 90
</pre>

Or

  * [value, string]:

<pre>10 a
20 b
30 f
90 g
</pre>

If the string have spaces, please use the [value, string] format.





 [2]: http://tinylab.org
 [3]: http://elinux.org/Boot_Time
 [4]: http://stuff.mit.edu/afs/sipb/contrib/linux/scripts/bootgraph.pl
 [5]: /wp-content/uploads/2014/01/bootgraph.svg
 [6]: https://github.com/tinyclub/tinydraw/raw/master/histogram/examples/linux-boot-graph/dmesg-initcall.pl
 [7]: /wp-content/uploads/2014/01/linux-boot-flamegraph.svg
 [8]: /wp-content/uploads/2014/01/linux-boot-gnuplot.svg
 [9]: /tinydraw/
 [10]: /wp-content/uploads/2014/01/boot-initcall.svg
 [11]: https://github.com/tinyclub/tinydraw/raw/master/histogram/histogram.sh
 [12]: https://github.com/tinyclub/tinydraw/raw/master/histogram/examples/linux-boot-graph/dmesg.sh
 [13]: https://github.com/tinyclub/tinydraw/raw/master/histogram/examples/linux-boot-graph/bootprof.sh
 [14]: http://elinux.org/Grabserial
