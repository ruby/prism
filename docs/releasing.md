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

* Regenerate `rust/ruby-prism-sys/src/bindings.rs` with `bundle exec rake cargo:bindings`. CI fails if the committed file is stale.

* Commit all of the updated files:

```sh
git commit -am "Bump to v$PRISM_VERSION"
```

* Push up the changes:

```sh
git push
```

## Publishing

### Automatic (Github Actions)

The [`publish-gem.yml`](../.github/workflows/publish-gem.yml) workflow handles publishing. It triggers either on a `v*` tag push or via manual `workflow_dispatch`. In both cases it:

- Builds the source gem and all native gems (calling the reusable [`build-gems.yml`](../.github/workflows/build-gems.yml) workflow with `--release`).
- Pushes every gem to RubyGems.org using OIDC trusted publishing (no API key required).
- Creates (or updates) a GitHub release for the tag, attaches the `.gem` files and a `CHECKSUMS.txt`, and auto-generates release notes.

The `push` job is gated on `github.repository == 'ruby/prism'` and runs in the `rubygems.org` GitHub environment, which is the trust anchor for OIDC publishing to RubyGems.org. Pushes that already exist on RubyGems.org are reported as warnings rather than failing the run, so re-runs after a partial failure are safe.

#### 1. Trigger the release pipeline

After the preparation commit is on `main`, tag and push:

```sh
git tag "v${PRISM_VERSION}"
git push origin "v${PRISM_VERSION}"
```

The `v*` tag push triggers `publish-gem.yml` automatically.

If you need to re-trigger the workflow against an existing tag — for example, if the tag-push run failed partway through and you've fixed the cause — go to the Actions tab and use "Run workflow" on `Publish gem to rubygems.org`, passing the tag (e.g. `v1.10.0`) as the `version_tag` input. The workflow will check out that tag, rebuild, and push.

#### 2. Edit the release notes

The workflow creates the GitHub release with auto-generated notes. Edit it to paste in the relevant section of `CHANGELOG.md`.

### Manually

If for whatever reason (like an emergency), you need to release a version and the Github Actions pipelines aren't available, here's how you can build the full set of native gems.

#### 1. Build gems

```sh
bin/build-gems
```

This script will:
- Run `bundle update` and `bundle package` to vendor dependencies
- Run a safety check (`compile` and `test`)
- Build all gems via `rake gem:all` (source gem + native gems for all platforms using rake-compiler-dock)
- Place all gems in `./gems/`
- Verify all built gems with `test/prism/packaging/test-gem-file-contents`
- Print SHA256 checksums for inclusion in release notes

#### 2. Push gems

Push the native gems first, then the source gem last (so that when users see the new version, native gems are already available):

```sh
# push native gems first
for gem in gems/prism-*-*.gem ; do
  gem push "$gem"
done

# push source gem last
gem push gems/prism-${PRISM_VERSION}.gem
```

#### 3. Push tag

Push a new tag to the GitHub repository, following the `vX.Y.Z` format:

```sh
git tag "v${PRISM_VERSION}"
git push origin "v${PRISM_VERSION}"
```

#### 4. Create a release

Update the GitHub release page with a copy of the latest entry in the `CHANGELOG.md` file, including the SHA256 checksums from the build output.
