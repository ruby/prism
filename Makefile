ifeq ($(shell uname), Darwin)
SOEXT := dylib
else
SOEXT := so
endif

build/librubyparser.$(SOEXT): $(shell find src -name '*.c') $(shell find src -name '*.h') Makefile build src/ast.h
	$(CC) -Wall -Werror -fPIC -g -fvisibility=hidden -shared -Isrc -o $@ $(shell find src -name '*.c')

build:
	mkdir -p build

src/ast.h: bin/templates/src/ast.h.erb
	rake $@

clean:
	rm -f build/librubyparser.$(SOEXT) ext/yarp/node.c lib/yarp/{node,prettyprint,serialize}.rb src/{ast.h,node.{c,h},serialize.c,token_type.c}

.PHONY: clean
