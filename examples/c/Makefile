
CC   = gcc
SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)

all: $(OBJS)
	$(CURDIR)/$(basename $<)

%.o: %.c
	$(CC) -g -o $(basename $@) $<

clean:
	rm -f $(basename $(OBJS))
