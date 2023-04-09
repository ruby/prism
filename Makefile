ifeq ($(shell uname), Darwin)
SOEXT := dylib
else
SOEXT := so
endif

OPTFLAGS :=
CFLAGS :=

# Check for the presence of strncasecmp
ifeq ($(shell $(CC) -Iinclude -o /dev/null test/availability/strncasecmp.c 2>/dev/null && echo 1), 1)
CFLAGS := $(CFLAGS) -DHAVE_STRNCASECMP
endif

# Check for the presence of strnstr
ifeq ($(shell $(CC) -Iinclude -o /dev/null test/availability/strnstr.c 2>/dev/null && echo 1), 1)
CFLAGS := $(CFLAGS) -DHAVE_STRNSTR
endif

all: build/librubyparser.$(SOEXT)

build/librubyparser.$(SOEXT): $(shell find src -name '*.c') $(shell find src -name '*.h') Makefile build include/yarp/ast.h
	$(CC) $(OPTFLAGS) $(DEBUG_FLAGS) $(CFLAGS) -std=c99 -Wall -Werror -Wextra -Wpedantic -Wsign-conversion -fPIC -g -fvisibility=hidden -shared -Iinclude -o $@ $(shell find src -name '*.c')

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
		src/{node.c,prettyprint.c,serialize.c,token_type.c}

.PHONY: clean

all-no-debug: DEBUG_FLAGS := -DNDEBUG=1
all-no-debug: OPTFLAGS := -O3
all-no-debug: all
