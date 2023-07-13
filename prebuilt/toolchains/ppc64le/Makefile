# Makefile

CCORI_LIST ?= internal

ifeq ($(CCORI), internal)
  CCPRE   ?= powerpc64le-linux-gnu-
  CCPATH  ?= $(dir $(shell which $(CCPRE)gcc))
endif
