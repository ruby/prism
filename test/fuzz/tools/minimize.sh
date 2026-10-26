#!/bin/bash

DIR=$1

flags=""
[ "$(basename $DIR)" = "hangs" ] && {
  flags="-H"
}

executable=/prism/build/fuzz."$(basename $(dirname $(dirname $DIR)))"

for file in $(find "$DIR" -type f ! -name "*.*")
do
  echo "Minimizing $file: this may take a long time"
  AFL_TMIN_EXACT=1 afl-tmin $flags -i "$file" -o "${file}.min" -- "$executable"
done
