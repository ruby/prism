# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.0] - 2023-08-18

### Added

- Some performance improvements when converting from the C AST to the Ruby AST.
- Two rust crates have been added: `yarp-sys` and `yarp`. They are as yet unpublished.

### Changed

- Escaped newlines in strings and heredocs are now handled more correctly.
- Dedenting heredocs that result in empty string nodes will now drop those string nodes from the list.
- Beginless and endless ranges in conditional expressions now properly form a flip flop node.
- `%` at the end of files no longer crashes.
- Location information has been corrected for `if/elsif` chains that have no `else`.
- `__END__` at the very end of the file was previously parsed as an identifier, but is now correct.
- **BREAKING**: Nodes that reference `&&=`, `||=`, and other writing operators have been consolidated. Previously, they were separate individual nodes. Now they are a tree with the target being the left-hand side and the value being the right-hand side with a joining `AndWriteNode`, `OrWriteNode`, or `OperatorWriteNode` in the middle. This impacts all of the nodes that match this pattern: `{ClassVariable,Constant,ConstantPath,GlobalVariable,InstanceVariable,LocalVariable}Operator{And,Or,}WriteNode`.
- **BREAKING**: `BlockParametersNode`, `ClassNode`, `DefNode`, `LambdaNode`, `ModuleNode`, `ParenthesesNode`, and `SingletonClassNode` have had their `statements` field renamed to `body` to give a hint that it might not be a `StatementsNode` (it could also be a `BeginNode`).

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
- **BREAKING**: `RangeNodeFlags` has been renamed to `RangeFlags`.
- Unary minus on number literals is now parsed as part of the literal, rather than a call to a unary operator. This is more consistent with how other parsers handle this.

## [0.6.0] - 2023-08-09

### Added

- 🎉 Initial release! 🎉

[unreleased]: https://github.com/ruby/yarp/compare/v0.8.0...HEAD
[0.8.0]: https://github.com/ruby/yarp/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/ruby/yarp/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/ruby/yarp/compare/d60531...v0.6.0
