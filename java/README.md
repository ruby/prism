# Prism Java API and bindings

This is the top-level project for the Java API and backend bindings for the Prism Ruby language parser.

* api/ contains the API
* native/ contains a native binding for the Prism shared library
* wasm/ contains a Chicory-based WASM build and binding

## Building the Java components

Some files need to be generated before the Maven artifacts can build:

### Templated sources

Sources under `api` are generated from templates in `../templates`. Those sources are generated using the follow command line:

```
$ PRISM_EXCLUDE_PRETTYPRINT=1 PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS=1 bundle exec rake templates
```

The files go under `api/target/generated-sources/java` and will be removed with `mvn clean`.

### WASM build of Prism

The `wasm` project needs a WASM build of Prism to be generated with the following command:

```
$ make java-wasm WASI_SDK_PATH=<path to WASI sdk>
```

The files go under `wasm/target/generated-sources/wasm` and will be removed with `mvn clean`.

### Build and install

The projects can be built and installed into a local Maven repository by running the following command:

```
$ mvn install
```

## Updating versions

Run the following command to update all module versions:

```
$ mvn versions:set -DnewVersion=1.2.3-SNAPSHOT
```

## Releasing

Snapshots can be deployed to the Maven snapshot repository while the versions end with `-SNAPSHOT`:

```
$ mvn deploy
```

When releasing to Maven Central, all projects should be released together using the `release` profile, which will use the local default GPG key to sign the packages:

```
$ mvn deploy -Prelease
```

