# Testing

This document explains how to test prism, both locally, and against existing test suites.

## Test suite

`rake test` will run all of the files in the `test/` directory. This can be conceived of as two parts: unit tests, and snapshot tests.

### Unit tests

These test specific prism implementation details like comments, errors, and regular expressions. There are corresponding files for each thing being tested (like `test/errors_test.rb`).

### Snapshot tests

Snapshot tests ensure that parsed output is equivalent to previous parsed output. There are many categorized examples of valid syntax within the `test/prism/fixtures/` directory. When the test suite runs, it will parse all of this syntax, and compare it against corresponding files in the `test/prism/snapshots/` directory. For example, `test/prism/fixtures/strings.txt` has a corresponding `test/prism/snapshots/strings.txt`.

If the parsed files do not match, it will raise an error. If there is not a corresponding file in the `test/prism/snapshots/` directory, one will be created so that it exists for the next test run. If the snapshot already exists but differs you can run with `UPDATE_SNAPSHOTS=1` to regenerate them.

When working on a specific example, you can limit tests to a single fixture via `FOCUS=strings.txt`.

#### Versioning

Prism is capable of parsing code with different version specifiers. The test suite reflects this:
* Test files under `test/prism/snapshots/*.txt` are validated against all supported versions.
* Test files under `test/prism/snapshots/[MAJOR].[MINOR]/*.txt` are validated against all versions starting from the given version.
* Test files under `test/prism/snapshots/[MAJOR].[MINOR]-[MAJOR].[MINOR]/*.txt` are validated against the given version range.

Should you add logic specific to a new ruby version, validate the new behavior but also that old behavior remains the same.

### Error tests

Error tests are similar to snapshot tests and expectations are located under `test/prism/errors/`.
They contain invalid syntax and rendered errors, similar to how `ruby -c` would show them.
Error tests are versioned in the same way that snapshot tests are and also support `FOCUS`/`UPDATE_SNAPSHOTS`.

## Local testing

As you are working, you will likely want to test your code locally. `test.rb` is ignored by git, so it can be used for local testing. **bin/prism** contains a multitude of options to aid you, depending on which area
of prism you are working on. `bin/prism --help` prints a list of all available commands.

Commands that take a `[source]` can be called in three different ways:
1. `bin/prism parse` will use `test.rb` as input.
1. `bin/prism parse foo.rb` will read from the given path.
1. `bin/prism parse -e "1 + 2"` will use the given source code.

`bin/prism parse` is aliased as `bin/parse` for for convenience.

### Validating your changes against real code

If you create a change which is not expected to have a large impact on real code, you can use
`bin/compare` to validate that assumption. It compiles two versions of prism (for example
your feature branch and main), comparing ast, errors and warnings. Once done, a report is
printed showcasing in what way files changed, if any (syntax valid -> syntax invalid, changed AST, etc.)

```sh
$ bin/compare main feature-branch ~/all-of-rubygems`
...
0/3157385
1000/3157385
...
3157000/3157385
Oops:
intermine-1.05.00/lib/intermine/lists.rb changed from valid(true) to valid(false)
whistle-0.1.1/lib/resource.rb changed from valid(true) to valid(false)
Took 2661.5390081949999512 seconds
```

It is up to you to aquire code samples. Here are some resources you can use for this purpose:
* https://github.com/jeromedalbert/real-world-ruby-apps
* https://github.com/eliotsykes/real-world-rails
* https://github.com/rubygems/rubygems-mirror
  Requires some work to unpack the downloaded gems. You should also run with `RUBYGEMS_MIRROR_ONLY_LATEST=TRUE`.
