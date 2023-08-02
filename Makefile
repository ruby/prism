
# V=0 quiet, V=1 verbose.  other values don't work.
V = 0
V0 = $(V:0=)
Q1 = $(V:1=)
Q = $(Q1:0=@)
ECHO1 = $(V:1=@ :)
ECHO = $(ECHO1:0=@ echo)

CPPFLAGS := -Iinclude
CFLAGS := -std=c99 -Wall -Werror -Wextra -Wpedantic -Wundef -Wconversion -fPIC -fvisibility=hidden
SOURCES := $(shell find src -name '*.c')
FUZZ_OUTPUT_DIR = $(shell pwd)/fuzz/output

build/fuzz.%: $(SOURCES) fuzz/%.c fuzz/fuzz.c
	$(ECHO) "building $* fuzzer"
	$(ECHO) "building main fuzz binary"
	$(Q) AFL_HARDEN=1 afl-clang-lto $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(FUZZ_FLAGS) -O0 -fsanitize-ignorelist=fuzz/asan.ignore -fsanitize=fuzzer,address -ggdb3 -std=c99 -Iinclude -o $@ $^
	$(ECHO) "building cmplog binary"
	$(Q) AFL_HARDEN=1 AFL_LLVM_CMPLOG=1 afl-clang-lto $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(FUZZ_FLAGS) -O0 -fsanitize-ignorelist=fuzz/asan.ignore -fsanitize=fuzzer,address -ggdb3 -std=c99 -Iinclude -o $@.cmplog $^

build/fuzz.heisenbug.%: $(SOURCES) fuzz/%.c fuzz/heisenbug.c
	$(Q) AFL_HARDEN=1 afl-clang-lto $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(FUZZ_FLAGS) -O0 -fsanitize-ignorelist=fuzz/asan.ignore -fsanitize=fuzzer,address -ggdb3 -std=c99 -Iinclude -o $@ $^

fuzz-debug:
	$(ECHO) "entering debug shell"
	$(Q) docker run -it --rm -e HISTFILE=/yarp/fuzz/output/.bash_history -v $(shell pwd):/yarp -v $(FUZZ_OUTPUT_DIR):/fuzz_output yarp/fuzz

fuzz-docker-build: fuzz/docker/Dockerfile
	$(ECHO) "building docker image"
	$(Q) docker build -t yarp/fuzz fuzz/docker/

fuzz-run-%: FORCE fuzz-docker-build
	$(ECHO) "running $* fuzzer"
	$(Q) docker run --rm -v $(shell pwd):/yarp yarp/fuzz /bin/bash -c "FUZZ_FLAGS=\"$(FUZZ_FLAGS)\" make build/fuzz.$*"
	$(ECHO) "starting AFL++ run"
	$(Q) mkdir -p $(FUZZ_OUTPUT_DIR)/$*
	$(Q) docker run -it --rm -v $(shell pwd):/yarp -v $(FUZZ_OUTPUT_DIR):/fuzz_output yarp/fuzz /bin/bash -c "./fuzz/$*.sh /fuzz_output/$*"
FORCE:

clean:
	$(Q) rm -f -r build

.PHONY: clean
