// ref: https://unix.stackexchange.com/questions/223385/why-and-how-are-some-shared-libraries-runnable-as-though-they-are-executables

#include <stdio.h>

void sayHello (char *tag) {
    printf("%s: Hello!\n", tag);
}

int main (int argc, char *argv[]) {
    sayHello(argv[0]);
    return 0;
}
