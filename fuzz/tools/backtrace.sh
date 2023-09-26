#!/bin/bash

CRASH_DIR=$1

[ "$(basename $CRASH_DIR)" = "crashes" ] || {
	echo "Must be a crash directory" >&2
	exit 1
}

executable=/prism/build/fuzz."$(basename $(dirname $(dirname $CRASH_DIR)))"

for crash in $(find "$CRASH_DIR" -type f ! -name "*.bt" ! -name "*.md")
do
	echo "Generating backtrace for $crash"
	gdb --batch -ex "b __asan::ReportGenericError" -ex "run $crash" -ex "bt" "$executable" &> "$crash".bt
done
