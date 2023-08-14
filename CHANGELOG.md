# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - 2023-08-14

### Added

- We now have an explicit `FlipFlopNode`. It has the same flags as `RangeNode`.
- We now have a syntax error when implicit and explicit blocks are passed to a method call.
- `Node#slice` is now implemented, for retrieving the slice of the source code corresponding to a node.
- We now support the `utf8-mac` encoding.
- Predicate methods have been added for nodes that have flags. For example `CallNode#safe_navigation?` and `RangeNode#exclude_end?`.
- The gem now functions on JRuby and TruffleRuby, thanks to a new FFI backend.
- Comments are now part of the serialization API.

### Changed

- Autotools has been removed from the build system, so when the gem is installed it will no longer need to go through a configure step.
- The AST for `foo = *bar` has changed to have an explicit array on the right hand side, rather than a splat node. This is more consistent with how other parsers handle this.
- `RangeNodeFlags` has been renamed to `RangeFlags`.
- Unary minus on number literals is now parsed as part of the literal, rather than a call to a unary operator. This is more consistent with how other parsers handle this.

## [0.6.0] - 2023-08-09

### Added

- 🎉 Initial release! 🎉

[unreleased]: https://github.com/ruby/yarp/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/ruby/yarp/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/ruby/yarp/compare/d60531...v0.6.0
