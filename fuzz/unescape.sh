#!/bin/bash

OUTPUT_DIR=$1

afl-fuzz -G 100 -c ./build/fuzz.unescape.cmplog -i ./fuzz/corpus/unescape -o "$OUTPUT_DIR" ./build/fuzz.unescape
