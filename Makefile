
# V=0 quiet, V=1 verbose.  other values don't work.
V = 0
V0 = $(V:0=)
Q1 = $(V:1=)
Q = $(Q1:0=@)
ECHO1 = $(V:1=@ :)
ECHO = $(ECHO1:0=@ echo)
FUZZ_OUTPUT_DIR = $(CURDIR)/test/fuzz/output

SOEXT ?= $(shell ruby -e 'puts RbConfig::CONFIG["SOEXT"]')

CPPFLAGS := -Iinclude $(CPPFLAGS)

# The build variants. Each is on when its variable is set, even to an empty
# value, in the environment or on the command line. ext/prism/extconf.rb reads
# the same variables the same way, so one variable selects the same variant of
# libprism and of the C extension.
ifneq ($(origin PRISM_BUILD_DEBUG),undefined)
CPPFLAGS += -DPRISM_BUILD_DEBUG
endif
ifneq ($(origin PRISM_BUILD_MINIMAL),undefined)
CPPFLAGS += -DPRISM_BUILD_MINIMAL
endif
ifneq ($(origin PRISM_BUILD_NDEBUG),undefined)
CPPFLAGS += -DNDEBUG=1
endif
ifneq ($(origin PRISM_BUILD_ASAN),undefined)
CFLAGS += -fsanitize=address -fno-omit-frame-pointer
endif
ifneq ($(origin PRISM_BUILD_UBSAN),undefined)
CFLAGS += -fsanitize=undefined -fno-sanitize-recover=undefined -fno-omit-frame-pointer
endif

CFLAGS := -g -O2 -std=c99 -Wall -Werror -Wextra -Wpedantic -Wundef -Wconversion -Wno-missing-braces -fPIC -fvisibility=hidden -Wimplicit-fallthrough $(CFLAGS)
JAVA_WASM_CFLAGS := -g0 -O2 -Oz -std=c99 -Wall -Werror -Wextra -Wpedantic -Wundef -Wconversion -Wno-missing-braces -fno-sanitize=all -fno-stack-protector -fPIC -fvisibility=hidden -Wimplicit-fallthrough $(JAVA_WASM_CFLAGS)
CC ?= cc
AR ?= ar
ARFLAGS ?= -r$(V0:1=v)
WASI_SDK_PATH := /opt/wasi-sdk

# Exporting a symbol makes it a GC root, so the JavaScript module exports only
# the symbols javascript/src/parsePrism.js calls. That lets --gc-sections drop
# the rest of the C API along with the wasi-libc code reachable from it.
WASM_EXPORTS := -Wl,--export=malloc,--export=free,--export=pm_buffer_new,--export=pm_buffer_value,--export=pm_buffer_length,--export=pm_buffer_free,--export=pm_serialize_parse

# Bind the library's own references to its own definitions at link time, so
# that the functions exported for FFI cannot be interposed by another copy of
# libprism loaded in the same process (for example the copy built into the
# interpreter next to the one built by a prism gem, when either copy was loaded
# with RTLD_GLOBAL). Mach-O and PE do this by default; only ELF needs the flag.
ifeq ($(SOEXT),so)
SHARED_LDFLAGS := -Wl,-Bsymbolic
endif

MAKEDIRS ?= mkdir -p
RMALL ?= rm -f -r

HEADERS := $(wildcard include/*.h include/*/*.h include/*/*/*.h)
SOURCES := $(wildcard src/*.c src/*/*.c)
SHARED_OBJECTS := $(subst src/,build/shared/,$(SOURCES:.c=.o))
STATIC_OBJECTS := $(subst src/,build/static/,$(SOURCES:.c=.o))

# The objects depend on the flags they are compiled with as well as on their
# sources. Make only compares timestamps, so build/.flags records the flags and
# is rewritten whenever they differ from what it holds. Its timestamp then moves
# only when the flags change, which makes the objects out of date exactly then.
# Target-specific flags, such as those of `minimal`, reach it as a prerequisite.
# In the same way, build/.sources records the list of sources, so that the
# libraries are linked again when a source is removed.
#
# Separate stamps track shared-library linker flags and the archive command,
# so changing those settings rebuilds only the affected library, not its objects.
# Each Wasm target also tracks its own flags and the shared source list.
#
# Some makes compare timestamps to the second, such as the GNU Make 3.81 that
# ships with macOS. A stamp written in the same second as the last objects of
# the previous build would not be newer than them, so a changed stamp is written
# a second after it is found to differ.
BUILD_FLAGS = $(CC) $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(OPTFLAGS)
WASM_BUILD_FLAGS = $(WASI_SDK_PATH) $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(WASM_EXPORTS)
JAVA_WASM_BUILD_FLAGS = $(WASI_SDK_PATH) $(DEBUG_FLAGS) $(CPPFLAGS) $(JAVA_WASM_CFLAGS)

all: shared static

shared: build/libprism.$(SOEXT)
static: build/libprism.a
wasm: javascript/src/prism.wasm
java-wasm: java/wasm/src/main/wasm/prism.wasm
playground: doc/playground

build/.flags: FORCE
	$(Q) $(MAKEDIRS) $(@D)
	$(Q) printf '%s\n' '$(BUILD_FLAGS)' | cmp -s - $@ || { sleep 1; printf '%s\n' '$(BUILD_FLAGS)' > $@; }

build/.sources: FORCE
	$(Q) $(MAKEDIRS) $(@D)
	$(Q) printf '%s\n' '$(SOURCES)' | cmp -s - $@ || { sleep 1; printf '%s\n' '$(SOURCES)' > $@; }

build/.ldflags: FORCE
	$(Q) $(MAKEDIRS) $(@D)
	$(Q) printf '%s\n' '$(SHARED_LDFLAGS)' | cmp -s - $@ || { sleep 1; printf '%s\n' '$(SHARED_LDFLAGS)' > $@; }

build/.arflags: FORCE
	$(Q) $(MAKEDIRS) $(@D)
	$(Q) printf '%s\n' '$(AR) $(ARFLAGS)' | cmp -s - $@ || { sleep 1; printf '%s\n' '$(AR) $(ARFLAGS)' > $@; }

build/.wasm.flags: FORCE
	$(Q) $(MAKEDIRS) $(@D)
	$(Q) printf '%s\n' '$(WASM_BUILD_FLAGS)' | cmp -s - $@ || { sleep 1; printf '%s\n' '$(WASM_BUILD_FLAGS)' > $@; }

build/.java-wasm.flags: FORCE
	$(Q) $(MAKEDIRS) $(@D)
	$(Q) printf '%s\n' '$(JAVA_WASM_BUILD_FLAGS)' | cmp -s - $@ || { sleep 1; printf '%s\n' '$(JAVA_WASM_BUILD_FLAGS)' > $@; }

build/libprism.$(SOEXT): $(SHARED_OBJECTS) build/.flags build/.sources build/.ldflags
	$(ECHO) "linking $@ with $(CC)"
	$(Q) $(CC) $(DEBUG_FLAGS) $(CFLAGS) $(OPTFLAGS) -shared $(SHARED_LDFLAGS) -o $@ $(SHARED_OBJECTS)

# `ar -r` only adds and replaces members, so the archive is created afresh to
# hold exactly the current objects.
build/libprism.a: $(STATIC_OBJECTS) build/.flags build/.sources build/.arflags
	$(ECHO) "building $@ with $(AR)"
	$(Q) $(RMALL) $@
	$(Q) $(AR) $(ARFLAGS) $@ $(STATIC_OBJECTS)

javascript/src/prism.wasm: Makefile $(SOURCES) $(HEADERS) build/.sources build/.wasm.flags
	$(ECHO) "building $@"
	$(Q) $(WASI_SDK_PATH)/bin/clang --sysroot=$(WASI_SDK_PATH)/share/wasi-sysroot/ \
		$(DEBUG_FLAGS) \
		-DPRISM_EXPORT_SYMBOLS -DPRISM_EXCLUDE_PRETTYPRINT -DPRISM_EXCLUDE_JSON \
		-D_WASI_EMULATED_MMAN -lwasi-emulated-mman $(CPPFLAGS) $(CFLAGS) \
		$(WASM_EXPORTS) -Wl,--gc-sections -Wl,--strip-all -Wl,--lto-O3 -Wl,--no-entry -mexec-model=reactor \
		-Oz -g0 -flto -fdata-sections -ffunction-sections \
		-o $@ $(SOURCES)

# The playground parses with the JavaScript package built from this checkout, so
# the page is served the parser the rest of the site was generated from. The
# JavaScript half of the package is generated by `rake templates`.
doc/playground: javascript/src/prism.wasm
	$(ECHO) "building $@"
	$(Q) $(MAKEDIRS) $@
	$(Q) cp javascript/src/*.js javascript/src/prism.wasm javascript/package.json $@

java/wasm/src/main/wasm/prism.wasm: Makefile $(SOURCES) $(HEADERS) build/.sources build/.java-wasm.flags
	$(ECHO) "building $@"
	$(Q) $(MAKEDIRS) $(@D)
	$(Q) $(WASI_SDK_PATH)/bin/clang \
		$(DEBUG_FLAGS) \
		-DPRISM_EXCLUDE_PRETTYPRINT -DPRISM_EXPORT_SYMBOLS -D_WASI_EMULATED_MMAN \
		-lwasi-emulated-mman $(CPPFLAGS) $(JAVA_WASM_CFLAGS) \
		-Wl,--export-all -Wl,--no-entry -mexec-model=reactor -lc++ -lc++abi \
		-o $@ $(SOURCES)

build/shared/%.o: src/%.c Makefile $(HEADERS) build/.flags
	$(ECHO) "compiling $@"
	$(Q) $(MAKEDIRS) $(@D)
	$(Q) $(CC) $(DEBUG_FLAGS) -DPRISM_EXPORT_SYMBOLS $(CPPFLAGS) $(CFLAGS) $(OPTFLAGS) -c -o $@ $<

build/static/%.o: src/%.c Makefile $(HEADERS) build/.flags
	$(ECHO) "compiling $@"
	$(Q) $(MAKEDIRS) $(@D)
	$(Q) $(CC) $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(OPTFLAGS) -c -o $@ $<

build/fuzz.%: $(SOURCES) test/fuzz/%.c test/fuzz/fuzz.c
	$(ECHO) "building $* fuzzer"
	$(Q) $(MAKEDIRS) $(@D)
	$(ECHO) "building main fuzz binary"
	$(Q) afl-clang-lto $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(FUZZ_FLAGS) -O0 -fsanitize=fuzzer,address -ggdb3 -std=c99 -Iinclude -o $@ $^
	$(ECHO) "building cmplog binary"
	$(Q) AFL_LLVM_CMPLOG=1 afl-clang-lto $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(FUZZ_FLAGS) -O0 -fsanitize=fuzzer,address -ggdb3 -std=c99 -Iinclude -o $@.cmplog $^

build/fuzz.heisenbug.%: $(SOURCES) test/fuzz/%.c test/fuzz/heisenbug.c
	$(Q) afl-clang-lto $(DEBUG_FLAGS) $(CPPFLAGS) $(CFLAGS) $(FUZZ_FLAGS) -O0 -fsanitize=fuzzer,address -ggdb3 -std=c99 -Iinclude -o $@ $^

fuzz-debug:
	$(ECHO) "entering debug shell"
	$(Q) docker run -it --rm -e HISTFILE=/prism/test/fuzz/output/.bash_history -v $(CURDIR):/prism -v $(FUZZ_OUTPUT_DIR):/fuzz_output prism/fuzz

fuzz-docker-build: test/fuzz/docker/Dockerfile
	$(ECHO) "building docker image"
	$(Q) docker build -t prism/fuzz test/fuzz/docker/

fuzz-run-%: FORCE fuzz-docker-build
	$(ECHO) "generating templates"
	$(Q) bundle exec rake templates
	$(ECHO) "running $* fuzzer"
	$(Q) docker run --rm -v $(CURDIR):/prism prism/fuzz /bin/bash -c "FUZZ_FLAGS=\"$(FUZZ_FLAGS)\" make build/fuzz.$*"
	$(ECHO) "starting AFL++ run"
	$(Q) $(MAKEDIRS) $(FUZZ_OUTPUT_DIR)/$*
	$(Q) docker run -it --rm -v $(CURDIR):/prism -v $(FUZZ_OUTPUT_DIR):/fuzz_output prism/fuzz /bin/bash -c "./test/fuzz/$*.sh /fuzz_output/$*"
FORCE:

fuzz-clean:
	$(Q) $(RMALL) test/fuzz/output

clean:
	$(Q) $(RMALL) build

CBMC ?= cbmc
CBMC_FLAGS ?= --compact-trace --trace-hex --slice-formula --property main.assertion.1

test-cbmc:
	$(ECHO) "running CBMC check on SWAR scan_identifier_ascii"
	$(Q) command -v $(CBMC) >/dev/null 2>&1 || { echo "error: $(CBMC) not found in PATH" >&2; exit 1; }
	$(Q) $(CBMC) -DPRISM_ACCEL_SWAR -Iinclude --unwind 17 --unwinding-assertions $(CBMC_FLAGS) test/cbmc/scan_identifier_ascii.c

.PHONY: clean doc/playground fuzz-clean test-cbmc

all-no-debug: DEBUG_FLAGS := -DNDEBUG=1
all-no-debug: OPTFLAGS := -O3
all-no-debug: all

minimal: CFLAGS := $(CFLAGS) -DPRISM_BUILD_MINIMAL
minimal: all

run: Makefile $(STATIC_OBJECTS) $(HEADERS) test.c
	$(ECHO) "compiling test.c"
	$(Q) $(CC) $(CPPFLAGS) $(CFLAGS) $(STATIC_OBJECTS) test.c
	$(ECHO) "running test.c"
	$(Q) ./a.out
