ifeq ($(shell uname), Darwin)
SOEXT := dylib
else
SOEXT := so
endif

build/librubyparser.$(SOEXT): $(shell find src -name '*.c') $(shell find src -name '*.h') Makefile build include/yarp/ast.h
	$(CC) -std=c99 -Wall -Werror -Wpedantic -fPIC -g -fvisibility=hidden -shared -Iinclude -o $@ $(shell find src -name '*.c')

build:
	mkdir -p build

include/yarp/ast.h: bin/templates/include/yarp/ast.h.erb
	rake $@

clean:
	rm -f \
		build/librubyparser.$(SOEXT) \
		ext/yarp/node.c \
		include/{ast.h,node.h} \
		java/org/yarp/{AbstractNodeVisitor.java,Loader.java,Nodes.java} \
		lib/yarp/{node,serialize}.rb \
		src/{node.c,prettyprint.c,serialize.c,token_type.c} \
		src/util/yp_strspn.c

.PHONY: clean
