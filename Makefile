CFLAGS += -fsanitize=address -g
CFLAGS += -Wall

LSAN_OPTIONS = suppressions=test-native/LSan.supp:print_suppressions=0

test: test-native/run-one
	LSAN_OPTIONS=$(LSAN_OPTIONS) ASAN_OPTIONS=detect_leaks=1 ./test-native/run-all.sh

test-native/run-one: test-native/run-one.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f test-native/run-one

.PHONY: test clean
