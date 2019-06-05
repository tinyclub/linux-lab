

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
