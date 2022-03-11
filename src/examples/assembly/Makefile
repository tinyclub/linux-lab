
S         ?= --no-print-directory
ARCH_LIST := $(shell ls -1d */ | tr -d '/')

all:
	@for a in $(ARCH_LIST); do \
	  echo "* Testing $$a:"; \
	  echo --------------; \
	  make $S -C $$a; \
	  echo --------------; \
	done

clean:
	@for a in $(ARCH_LIST); do \
	  echo "* Cleaning $$a:"; \
	  echo --------------; \
	  make clean $(S) -C $$a; \
	  echo --------------; \
	done
