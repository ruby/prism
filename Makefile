CFLAGS := -Wall -Werror -fPIC -g -fvisibility=hidden
LSAN_OPTIONS := suppressions=test-native/LSan.supp:print_suppressions=0
ASAN_OPTIONS := detect_leak=1

ifeq ($(shell uname), Darwin)
SOEXT := dylib
LDFLAGS :=
else
SOEXT := so
LDFLAGS := -Wl,-rpath,build
endif

YARP_SOURCES := $(shell find src -name '*.c')
YARP_HEADERS := $(shell find src -name '*.h')

build/librubyparser.$(SOEXT): $(YARP_SOURCES) $(YARP_HEADERS) build Makefile
	$(CC) $(CFLAGS) -shared -Isrc -o $@ $(YARP_SOURCES)

build:
	mkdir -p build

test: test-native/run-one
	LSAN_OPTIONS=$(LSAN_OPTIONS) ASAN_OPTIONS=$(ASAN_OPTIONS) test-native/run-all.sh

test-native/run-one: test-native/run-one.c build/librubyparser.$(SOEXT)
	$(CC) $(CFLAGS) $(LDFLAGS) -fsanitize=address -Isrc -Lbuild -lrubyparser $< -o $@

clean:
	rm -f build/librubyparser.$(SOEXT) test-native/run-one

.PHONY: test clean
