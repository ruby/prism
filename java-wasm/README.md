This dir contains the chicory-prism artifact, a version of prism compiled to WASM and then AOT compiled to JVM bytecode by the Chicory project.

Generate the templated sources:

```
PRISM_EXCLUDE_PRETTYPRINT=1 PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS=1 PRISM_JAVA_BACKEND=jruby bundle exec rake templates
```

Compile to WASM using WASI SDK version 25:

```
make java-wasm WASI_SDK_PATH=.../wasi-sdk-25.0-arm64-macos
```

Build the AOT-compiled machine and wrapper library:

```
mvn -f java-wasm/pom.xml clean package
```

This should build the chicory-wasm jar file and pass some basic tests.

The jar will be under `java-wasm/target/chicory-prism-#####-SNAPSHOT.jar` or can be installed by using `install` instead of `pacakge` in the `mvn` command line above.
