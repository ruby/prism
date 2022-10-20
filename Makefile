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

build/librubyparser.$(SOEXT): $(shell find src -name '*.c') $(shell find src -name '*.h') Makefile build src/ast.h
	$(CC) $(CFLAGS) -shared -Isrc -o $@ $(shell find src -name '*.c')

build:
	mkdir -p build

src/ast.h: bin/templates/src/ast.h.erb
	rake $@

test: test-native/run-one
	LSAN_OPTIONS=$(LSAN_OPTIONS) ASAN_OPTIONS=$(ASAN_OPTIONS) test-native/run-all.sh

test-native/run-one: test-native/run-one.c build/librubyparser.$(SOEXT)
	$(CC) $(CFLAGS) $(LDFLAGS) -fsanitize=address -Isrc -Lbuild -lrubyparser $< -o $@

clean:
	rm -f build/librubyparser.$(SOEXT) ext/yarp/node.c lib/yarp/{node,prettyprint,serialize}.rb src/{ast.h,node.{c,h},serialize.c,token_type.c} test-native/run-one

.PHONY: test clean
