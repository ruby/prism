#!/usr/bin/env sh

echo "Running lexer tests..."

exitcode=0

for f in $(find test-native/cases/lexer -type f); do
    ./test-native/run-one --lexer "$f" > /dev/null
    if [ $? -ne 0 ]
    then
        exitcode=1
    fi
done

for f in $(find test-native/cases/parser -type f); do
    ./test-native/run-one --parser "$f" > /dev/null
    if [ $? -ne 0 ]
    then
        exitcode=1
    fi
done

exit $exitcode
