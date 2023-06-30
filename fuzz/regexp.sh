#!/bin/bash

OUTPUT_DIR=$1

afl-fuzz -G 100 -c ./build/fuzz.regexp.cmplog -i ./fuzz/corpus/regexp -o "$OUTPUT_DIR" ./build/fuzz.regexp
