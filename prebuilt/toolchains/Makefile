ifneq ($(CCURL),)

CCTAR = $(notdir $(CCURL))

ifeq ($(TAR_OPTS),)

ifeq ($(findstring .tar.xz, $(CCTAR)),.tar.xz)
  TAR_OPTS = Jxvf
endif

ifeq ($(findstring .tar.bz2, $(CCTAR)),.tar.bz2)
  TAR_OPTS = jxvf
endif

ifeq ($(findstring .tar.gz, $(CCTAR)),.tar.gz)
  TAR_OPTS = zxvf
endif

ifeq ($(findstring .tgz, $(CCTAR)),.tgz)
  TAR_OPTS = zxvf
endif

endif # TAR_OPTS undef

endif # CCURL not empty
