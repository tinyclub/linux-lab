
## Environment inherit from parent to child

The child simply print parent and itself.

    $ cat ./child1.sh
    #!/bin/bash
    #
    # child1.sh
    #

    child=`basename $0`

    echo "parent: $parent"
    echo "child:  $child"

### Run child in parent's environment

The '.' and 'source' builtin command can be used to 'include' the child script
as part of the parent script and share the same environment variables.

    $ ./parent1.sh
    parent: parent1.sh
    child:  parent1.sh

    $ ./parent2.sh
    parent: parent2.sh
    child:  parent2.sh

### Export variable explicitly

The `export` builtin command can be used to export one variable or more
variables to childs. requires to specify the variable names explicitly.

    $ ./parent3.sh
    parent: parent3.sh
    child:  child1.sh

### Export variables inexplicitly

Another builtin command `set` can be used to export variables modified or
created during a section of shell scripts.

No need to specify name of the variables and therefore no need to know the
variables before the child access them.

    $ ./parent4.sh
    parent: parent4.sh
    child:  child1.sh
