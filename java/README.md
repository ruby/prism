# Prism Java API and bindings

This is the top-level project for the Java API and backend bindings for the Prism Ruby language parser.

* api/ contains the API
* native/ contains a native binding for the Prism shared library
* wasm/ contains a Chicory-based WASM build and binding

## Updating versions

Run the following command to update all module versions:

```
mvn versions:set -DnewVersion=1.2.3-SNAPSHOT
```

## Releasing

Snapshots can be deployed with `mvn deploy` while the versions are `-SNAPSHOT`.

When releasing to Maven Central, all projects should be released together using the `release` profile:

```
mvn clean deploy -Prelease
```
