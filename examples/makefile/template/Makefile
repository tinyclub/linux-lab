# Makefile template

override .DEFAULT_GOAL := test2

# Check variables
ifeq ($(origin a), command line)
  $(info "a is from command line")
endif


# Check goals
ifeq ($(filter test1,$(MAKECMDGOALS)),test1)
  $(info "test1: Only execute for test1 goal.")
endif
ifeq ($(filter test2,$(MAKECMDGOALS)),test2)
  $(info "test2: Only execute for test2 goal.")
endif
ifeq ($(filter test3,$(MAKECMDGOALS)),test3)
  $(info "test3: Only execute for test3 goal.")
endif

test1:
	@echo Run $@
	@echo "Command line variables:" $(MAKEOVERRIDES)
	@echo "Command line goals:" ${MAKECMDGOALS}

test2: test1
	@echo Run $@

test3: test2
	@echo Run $@

# Must put this at the end of Makefile, to make sure override the targets before here
# If the first argument is "xxx-run"...
first_target := $(firstword $(MAKECMDGOALS))
reserve_target := $(first_target:-run=)

ifeq ($(findstring -run,$(first_target)),-run)
  # use the rest as arguments for "run"
  RUN_ARGS := $(filter-out $(reserve_target),$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):;@:)
endif

test-run:
	@echo $(RUN_ARGS)

FORCE:

PHONY := test1 test2 test3 test-run FORCE

.PHONY: $(PHONY)
