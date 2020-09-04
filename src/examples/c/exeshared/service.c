// ref: http://rachid.koucha.free.fr/tech_corner/executable_lib.html

#include <stdio.h>
#include <unistd.h>

const char service_interp[] __attribute__((section(".interp"))) = "/lib/ld-linux.so.2";

void lib_service(void)
{

  printf("%s: This is a service of the shared library\n", __func__);

} // lib_service


//extern "C" {

void lib_entry(void)
{
  printf("%s: Entry point of the service library\n", __func__);

  _exit(0);
}

//}
