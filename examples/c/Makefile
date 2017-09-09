
CC=gcc
OBJ=hello.o

all: $(OBJ)
	$(CURDIR)/$(basename $<)

%.o: %.c
	$(CC) -g -o $(basename $@) $<

clean:
	rm -f $(basename $(OBJ))
