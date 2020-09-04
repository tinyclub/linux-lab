

## Important variables/goals


### .DEFAULT_GOAL

The `.DEFAULT_GOAL` variable can be overridded to update the default goal.

    $ make
    Run test1
    Command line variables:
    Command line goals:
    Run test2

`test1` is the first one, but with `override .DEFAULT_GOAL := test2`, test2
becomes the default goal now.

### MAKECMDGOALS

The `MAKECMDGOALS` variable record all of the goals input from command line:

    $ make test1 test2 test3
    "test1: Only execute for test1 goal."
    "test2: Only execute for test2 goal."
    "test3: Only execute for test3 goal."
    Run test1
    Command line variables:
    Command line goals: test1 test2 test3
    Run test2
    Run test3

### MAKEOVERRIDES or `${-*-command-variables-*-}`


The `MAKEOVERRIDES` saves all of command line variables:

    $ make a=123 b=456
    Run test1
    Command line variables: b=456 a=123
    Command line goals:
    Run test2

### Only execute code for specified make goals

Based on `MAKECMDGOALS`, we can run specified code in Makefile for specified goals:

    ifeq ($(filter test1,$(MAKECMDGOALS),test1)
        do something ...
    endif

    $ make test1
    "test1: Only execute for test1 goal."
    Run test1
    Command line variables:
    Command line goals: test1

### Treat goals after xxx-run goal as xxx-run's argument

    $ make test-run test1
    "test1: Only execute for test1 goal."
    Makefile:35: warning: overriding recipe for target 'test1'
    Makefile:16: warning: ignoring old recipe for target 'test1'
    test1

### Debugging & Tracing

    $ make --trace test1
    "test1: Only execute for test1 goal."
    Makefile:23: target 'test1' does not exist
    echo Run test1
    Run test1
    echo "Command line variables:"
    Command line variables:
    echo "Command line goals:" test1
    Command line goals: test1

    $ make --debug test1
    GNU Make 4.1
    Built for x86_64-pc-linux-gnu
    Copyright (C) 1988-2014 Free Software Foundation, Inc.
    License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
    Reading makefiles...
    "test1: Only execute for test1 goal."
    Updating goal targets....
     File 'test1' does not exist.
    Must remake target 'test1'.
    Run test1
    Command line variables:
    Command line goals: test1
    Successfully remade target file 'test1'.

### Logging

Three logging func are provided, they are `info`, `warning` and `error`, the
`error` can be used to report the status of a specified postion and exit
immediately. the other two can be used to simple logging.

    $(info Basic Information)
    $(warning Something important)
    $(error exit after show the emegency status)

Test them:

    $ make ERROR_TEST=1
    Makefile:25: *** Logging with 'error' function.  Stop.
    $ make WARN_TEST=1
    Makefile:28: Warning with 'warning' function
    Run test1
    Command line variables: WARN_TEST=1
    Command line goals:
    Run test2

### Checking variables

The `-p` option can be used to dump all of the variabls, this helps to check
the whole envrionment.


    $ make -p test1 > test1.data.dump

Take a look at the `test1` part:

    test1:
    #  Phony target (prerequisite of .PHONY).
    #  Command line target.
    #  Implicit rule search has not been done.
    #  Implicit/static pattern stem: ''
    #  File does not exist.
    #  File has been updated.
    #  Successfully updated.
    # automatic
    # @ := test1
    # automatic
    # % := 
    # automatic
    # * := 
    # automatic
    # + := 
    # automatic
    # | := 
    # automatic
    # < := 
    # automatic
    # ^ := 
    # automatic
    # ? := 
    # variable set hash-table stats:
    # Load=8/32=25%, Rehash=0, Collisions=1/20=5%
    #  recipe to execute (from 'Makefile', line 32):
    	@echo Run $@
    	@echo "Command line variables:" $(MAKEOVERRIDES)
    	@echo "Command line goals:" ${MAKECMDGOALS}
