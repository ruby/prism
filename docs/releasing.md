# Releasing

To release a new version of Prism, perform the following steps:

## Preparation

* Update the `CHANGELOG.md` file.
  * Add a new section for the new version at the top of the file.
  * Fill in the relevant changes — it may be easiest to click the link for the `Unreleased` heading to find the commits.
  * Update the links at the bottom of the file.
* Update the version in the following files:
  * `prism.gemspec` in the `Gem::Specification#version=` method call
  * `ext/prism/extension.h` in the `EXPECTED_PRISM_VERSION` macro
  * `include/prism/version.h` in the version macros
  * `javascript/package.json` in the `version` field
  * `rust/ruby-prism-sys/tests/utils_tests.rs` in the `version_test` function
  * `templates/java/org/prism/Loader.java.erb` in the `load` function
  * `templates/javascript/src/deserialize.js.erb` in the version constants
  * `templates/lib/prism/serialize.rb.erb` in the version constants
* Run `bundle install` to update the `Gemfile.lock` file.

```sh
bundle install
```

* Run `bundle install` with the various other gemfiles:

```sh
chruby ruby-2.7.8 && BUNDLE_GEMFILE=gemfiles/2.7/Gemfile bundle install
chruby ruby-3.0.6 && BUNDLE_GEMFILE=gemfiles/3.0/Gemfile bundle install
chruby ruby-3.1.4 && BUNDLE_GEMFILE=gemfiles/3.1/Gemfile bundle install
chruby ruby-3.2.3 && BUNDLE_GEMFILE=gemfiles/3.2/Gemfile bundle install
chruby ruby-3.3.0 && BUNDLE_GEMFILE=gemfiles/3.3/Gemfile bundle install
chruby ruby-3.4.0-dev && BUNDLE_GEMFILE=gemfiles/3.4/Gemfile bundle install
chruby jruby-9.4.5.0 && BUNDLE_GEMFILE=gemfiles/jruby/Gemfile bundle install
chruby truffleruby-23.1.2 && BUNDLE_GEMFILE=gemfiles/truffleruby/Gemfile bundle install
```

* Update `rust/ruby-prism-sys/Cargo.toml` to match the new version and run `cargo build`
* Update `rust/ruby-prism/Cargo.toml` to match the new version and run `cargo build`
* Commit all of the updated files.

## Publishing

* Update the GitHub release page with a copy of the latest entry in the `CHANGELOG.md` file.
* Run `bundle exec rake release` to publish the gem to [rubygems.org](rubygems.org). Note that you must have access to the `prism` gem to do this.
* Either download the `wasm` artifact from GitHub actions or generate it yourself with `make wasm`.
* Run `npm publish` to publish the JavaScript package to [npmjs.com](npmjs.com). Note that you must have access to the `ruby-prism` package to do this.
