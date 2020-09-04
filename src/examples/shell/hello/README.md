
## Hello Shell

* Basic Usage: <http://showterm.io/445cbf5541c926b19d4af>

## Usage

    $ ls
    hello.sh
    $ cat hello.sh
    #!/bin/bash

    echo 'Hello, World!'

### Run directly

    $ chmod a+x hello.sh
    $ ./hello.sh
    Hello, World!

    $ export PATH=.:$PATH
    $ hello.sh
    Hello, World!

### Run with shell

    $ bash hello.sh
    Hello, World!
    $ dash hello.sh
    Hello, World!

### Run in current environment

    $ . hello.sh
    Hello, World!
    $ source hello.sh
    Hello, World!
