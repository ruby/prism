#!/bin/bash

OUTPUT_DIR=$1

screen -S grammar_fuzzer -d -m  /bin/bash -c "AFL_CUSTOM_MUTATOR_LIBRARY=/usr/local/lib/libgrammarmutator-ruby.so AFL_CUSTOM_MUTATOR_ONLY=1 afl-fuzz -i fuzz/corpus/parse -o $OUTPUT_DIR -S grammar -- ./build/fuzz.parse"

screen -S main_fuzzer -m /bin/bash -c "afl-fuzz -x ./fuzz/dict -G 500 -c ./build/fuzz.parse.cmplog -i ./fuzz/corpus/parse -M main_parse -o $OUTPUT_DIR ./build/fuzz.parse || read -n 1"

exec /bin/bash
