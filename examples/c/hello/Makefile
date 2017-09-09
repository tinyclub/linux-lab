
CC   = gcc
SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)
ASMS = $(SRCS:.c=.s)
PRES = $(SRCS:.c=.i)

all: $(OBJS)
	$(CURDIR)/$(basename $<)

%.o: %.c
	$(CC) -g -o $(basename $@) $<

clean:
	rm -f $(basename $(OBJS)) $(OBJS) $(ASMS) $(PRES)
