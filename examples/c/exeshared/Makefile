
CC     = gcc

CFLAGS_service := -m32 -shared -Wl,-soname,libservice.so -Wl,-e,lib_entry
CFLAGS_test    := -m32 -pie -Wl,-E
CFLAGS_main    := -m32 -lservice -ltest -L.

Q      ?= $(if $(V),,@)

SRCS   = $(wildcard service.c test.c)
LIBS   = $(addprefix ./lib, $(SRCS:.c=.so))
EXEC   = $(subst .c,,main.c)
empty  =
space  = empty empty

ALL   := $(LIBS) $(EXEC)


all: $(ALL)
	@$(foreach exe, $(ALL), PATH=$(CURDIR):$(PATH) LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):`pwd` $(exe);)

main: main.c
	$(CC) -o $@ $< $(CFLAGS_main)

libservice.so: service.c
	$(CC) $(CFLAGS_service) -o $@ $<

libtest.so: test.c
	$(CC) $(CFLAGS_test) -o $@ $<

clean:
	rm -f $(ALL)
