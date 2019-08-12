
CC     = gcc
CFLAGS = -fno-stack-protector
CFLAGS+= -fomit-frame-pointer
CFLAGS+= -fno-asynchronous-unwind-tables
CFLAGS+= -fno-pie -no-pie
CFLAGS+= -m32
CFLAGS+= -Wall -Werror
#CFLAGS+= -std=c89

CC    += $(CFLAGS)

Q      ?= $(if $(V),,@)

SRCS   = $(wildcard *.c)
EXEC   = $(basename $(SRCS))
OBJS   = $(SRCS:.c=.o)
ASMS   = $(SRCS:.c=.s)
PRES   = $(SRCS:.c=.i)

ALL   := $(EXEC) $(OBJS) $(ASMS) $(PRES)

all: $(EXEC)
	$(Q)PATH=$(CURDIR):$(PATH) $(EXEC)

%: %.c
	$(CC) -g -o $@ $<

%.o: %.c
	$(CC) -c -o $@ $<

%.s: %.c
	$(CC) -S -o $@ $<

%.i: %.c
	$(CC) -E -o $@ $<

clean:
	rm -f $(ALL)
