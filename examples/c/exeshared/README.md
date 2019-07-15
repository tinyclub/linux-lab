
# Executable shared library

## Method 1

Use traditional shared libraries building method but specify the dynamic linker and the lib entry point explicitly:

    $ gcc -m32 -shared -Wl,-soname,libservice.so -Wl,-e,lib_entry -o libservice.so service.c

## Method 2

Generating position independent executable with -pie and using the -E option or the --export-dynamic option causes the linker to add all symbols to the dynamic symbol table:

    $ gcc -m32 -pie -Wl,-E -o libtest.so test.c

## References

* [How to make executable shared libraries](http://rachid.koucha.free.fr/tech_corner/executable_lib.html)
* [Why and how are some shared libraries runnable, as though they are executables?](https://unix.stackexchange.com/questions/223385/why-and-how-are-some-shared-libraries-runnable-as-though-they-are-executables)
* [Building shared library which is executable and linkable using Cmake](https://unix.stackexchange.com/questions/479333/building-shared-library-which-is-executable-and-linkable-using-cmake/479334)
