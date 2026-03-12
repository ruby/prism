# Releasing

To release a new version of Prism, perform the following steps:

## Preparation

* Update the `CHANGELOG.md` file.
  * Add a new section for the new version at the top of the file.
  * Fill in the relevant changes — it may be easiest to click the link for the `Unreleased` heading to find the commits.
  * Update the links at the bottom of the file.
* Update the version numbers in the various files that reference them:

```sh
export PRISM_MAJOR="x"
export PRISM_MINOR="y"
export PRISM_PATCH="z"
export PRISM_VERSION="$PRISM_MAJOR.$PRISM_MINOR.$PRISM_PATCH"
ruby -pi -e 'gsub(/spec\.version = ".+?"/, %Q{spec.version = "#{ENV["PRISM_VERSION"]}"})' prism.gemspec
ruby -pi -e 'gsub(/EXPECTED_PRISM_VERSION ".+?"/, %Q{EXPECTED_PRISM_VERSION "#{ENV["PRISM_VERSION"]}"})' ext/prism/extension.h
ruby -pi -e 'gsub(/PRISM_VERSION_MAJOR \d+/, %Q{PRISM_VERSION_MAJOR #{ENV["PRISM_MAJOR"]}})' include/prism/version.h
ruby -pi -e 'gsub(/PRISM_VERSION_MINOR \d+/, %Q{PRISM_VERSION_MINOR #{ENV["PRISM_MINOR"]}})' include/prism/version.h
ruby -pi -e 'gsub(/PRISM_VERSION_PATCH \d+/, %Q{PRISM_VERSION_PATCH #{ENV["PRISM_PATCH"]}})' include/prism/version.h
ruby -pi -e 'gsub(/PRISM_VERSION ".+?"/, %Q{PRISM_VERSION "#{ENV["PRISM_VERSION"]}"})' include/prism/version.h
ruby -pi -e 'gsub(/"version": ".+?"/, %Q{"version": "#{ENV["PRISM_VERSION"]}"})' javascript/package.json
ruby -pi -e 'gsub(/lossy\(\), ".+?"/, %Q{lossy(), "#{ENV["PRISM_VERSION"]}"})' rust/ruby-prism-sys/tests/utils_tests.rs
ruby -pi -e 'gsub(/\d+, "prism major/, %Q{#{ENV["PRISM_MAJOR"]}, "prism major})' templates/java/org/ruby_lang/prism/Loader.java.erb
ruby -pi -e 'gsub(/\d+, "prism minor/, %Q{#{ENV["PRISM_MINOR"]}, "prism minor})' templates/java/org/ruby_lang/prism/Loader.java.erb
ruby -pi -e 'gsub(/\d+, "prism patch/, %Q{#{ENV["PRISM_PATCH"]}, "prism patch})' templates/java/org/ruby_lang/prism/Loader.java.erb
ruby -pi -e 'gsub(/MAJOR_VERSION = \d+/, %Q{MAJOR_VERSION = #{ENV["PRISM_MAJOR"]}})' templates/javascript/src/deserialize.js.erb
ruby -pi -e 'gsub(/MINOR_VERSION = \d+/, %Q{MINOR_VERSION = #{ENV["PRISM_MINOR"]}})' templates/javascript/src/deserialize.js.erb
ruby -pi -e 'gsub(/PATCH_VERSION = \d+/, %Q{PATCH_VERSION = #{ENV["PRISM_PATCH"]}})' templates/javascript/src/deserialize.js.erb
ruby -pi -e 'gsub(/MAJOR_VERSION = \d+/, %Q{MAJOR_VERSION = #{ENV["PRISM_MAJOR"]}})' templates/lib/prism/serialize.rb.erb
ruby -pi -e 'gsub(/MINOR_VERSION = \d+/, %Q{MINOR_VERSION = #{ENV["PRISM_MINOR"]}})' templates/lib/prism/serialize.rb.erb
ruby -pi -e 'gsub(/PATCH_VERSION = \d+/, %Q{PATCH_VERSION = #{ENV["PRISM_PATCH"]}})' templates/lib/prism/serialize.rb.erb
ruby -pi -e 'gsub(/^version = ".+?"/, %Q{version = "#{ENV["PRISM_VERSION"]}"})' rust/ruby-prism-sys/Cargo.toml
ruby -pi -e 'gsub(/^version = ".+?"/, %Q{version = "#{ENV["PRISM_VERSION"]}"})' rust/ruby-prism/Cargo.toml
ruby -pi -e 'gsub(/^ruby-prism-sys = \{ version = ".+?"/, %Q{ruby-prism-sys = \{ version = "#{ENV["PRISM_VERSION"]}"})' rust/ruby-prism/Cargo.toml
```

* Update the `Gemfile.lock` file:

```sh
chruby ruby-4.0.0-dev
bundle install
```

* Update the version-specific lockfiles:

```sh
for VERSION in "2.7" "3.0" "3.1" "3.2" "3.3" "3.4" "4.0"; do docker run -it --rm -v "$PWD":/usr/src/app -w /usr/src/app -e BUNDLE_GEMFILE="gemfiles/$VERSION/Gemfile" "ruby:$VERSION" bundle update; done
chruby ruby-4.1.0-dev && BUNDLE_GEMFILE=gemfiles/4.1/Gemfile bundle install
```

* Update the cargo lockfiles:

```sh
bundle exec rake cargo:build
```

* Commit all of the updated files:

```sh
git commit -am "Bump to v$PRISM_VERSION"
```

* Push up the changes:

```sh
git push
```

## Publishing

* Build all gems (source + native) locally:

```sh
bin/build-gems
```

This script will:
1. Run `bundle update` and `bundle package` to vendor dependencies.
2. Run a safety check (`compile` and `test`).
3. Build all gems via `rake gem:all` (source gem + native gems for all platforms using rake-compiler-dock).
4. Verify all built gems with `bin/test-gem-file-contents`.
5. Print SHA256 checksums for inclusion in release notes.

* Push native gems first, then the source gem last (so that when users see the new version, native gems are already available):

```sh
# push native gems first
for gem in gems/prism-*-*.gem ; do
  gem push "$gem"
done

# push source gem last
gem push gems/prism-${PRISM_VERSION}.gem
```

* Push a new tag to the GitHub repository, following the `vX.Y.Z` format:

```sh
git tag "v${PRISM_VERSION}"
git push origin "v${PRISM_VERSION}"
```

* Update the GitHub release page with a copy of the latest entry in the `CHANGELOG.md` file, including the SHA256 checksums from the build output.
