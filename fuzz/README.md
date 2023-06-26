# System Requirements

- docker

# AFL++

The fuzzer used here is [AFL++](https://aflplus.plus). The user should
read the overview to get an idea of how the fuzzer works and its outputs.

# Usage

There are currently three fuzzing targets


- yp_parse_serialize (parse)
- yp_regexp_named_capture_group_names (regexp)
- yp_unescape_manipulate_string (unescape)

Respectively, fuzzing can be performed with
```
make fuzz-run-parse
make fuzz-run-regexp
make fuzz-run-unescape
```

To end a fuzzing job, interrupt with CTRL+C.

To enter a container with the fuzzing toolchain and debug
utilities, run

```
make fuzz-debug
```

# Out-of-bounds reads

Currently, encoding functionality implementing the ```yp_encoding_t``` interface can read outside
of inputs. For the time being, ASAN instrumentation is disabled for functions from src/enc.
See ```fuzz/asan.ignore```.


# Triaging Crashes and Hangs


Triaging crashes and hangs is easier when the inputs are as short as possible. In the
fuzz container, an entire crash or hang directory can be minimized using

```
./fuzz/tools/minimize.sh <directory>
```

e.g.
```
./fuzz/tools/minimize.sh fuzz/output/parse/default/crashes
```

This may take a long time. In the the crash/hang directory, for each input file there will
appear a minimized version with the extension ```.min``` appended.

Backtraces for crashes (not hangs) can be generated en masse with
```
./fuzz/tools/backtrace.sh <directory>
```
Files with basename equal to the input file name with extension ```.bt``` will be created e.g.

```
id:000000,sig:06,src:000006+000190,time:8480,execs:18929,op:splice,rep:4
id:000000,sig:06,src:000006+000190,time:8480,execs:18929,op:splice,rep:4.bt
```







