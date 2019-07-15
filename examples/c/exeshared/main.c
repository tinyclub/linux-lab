#include <stdio.h>

extern void lib_service(void);
extern void sayHello (char *tag);

int main(int ac, char *av[])
{
  printf("Calling libservice.so: \n");

  lib_service();

  printf("Calling libtest.so: \n");

  sayHello("main");

  return 0;
} // main
