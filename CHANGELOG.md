# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.11.0] - 2023-09-08

### Added

- `Node#inspect` is much improved.
- `YARP::Pattern` is introduced, which can construct procs to match against nodes.
- `BlockLocalVariableNode` is introduced to take the place of the locations array on `BlockParametersNode`.
- `ParseResult#attach_comments!` is now provided to attach comments to locations in the tree.
- `MultiTargetNode` is introduced as the target of multi writes and for loops.
- `Node#comment_targets` is introduced to return the list of objects that can have attached comments.

### Changed

- **BREAKING**: `GlobalVariable*Node#name` now returns a symbol.
- **BREAKING**: `Constant*Node#name` now returns a symbol.
- **BREAKING**: `BlockParameterNode`, `KeywordParameterNode`, `KeywordRestParameterNode`, `RestParameterNode`, `DefNode` all have their `name` methods returning symbols now.
- **BREAKING**: `ClassNode#name` and `ModuleNode#name` now return symbols.
- **BREAKING**: `Location#end_column` is now exclusive instead of inclusive.
- `Location#slice` now returns a properly encoded string.
- `CallNode#operator_loc` is now `CallNode#call_operator_loc`.
- `CallOperatorAndWriteNode` is renamed to `CallAndWriteNode` and its structure has changed.
- `CallOperatorOrWriteNode` is renamed to `CallOrWriteNode` and its structure has changed.

## [0.10.0] - 2023-09-01

### Added

- `InstanceVariable*Node` and `ClassVariable*Node` objects now have their `name` returning a Symbol. This is because they are now part of the constant pool.
- `NumberedReferenceReadNode` now has a `number` field, which returns an Integer.

### Changed

- **BREAKING**: Various `operator_id` and `constant_id` fields have been renamed to `operator` and `name`, respectively. See [09d0a144](https://github.com/ruby/yarp/commit/09d0a144dfd519c5b5f96f0b6ee95d256e2cb1a6) for details.
- `%w`, `%W`, `%i`, `%I`, `%q`, and `%Q` literals can now span around the contents of a heredoc.
- **BREAKING**: All of the public C APIs that accept the source string now accept `const uint8_t *` as opposed to `const char *`.

## [0.9.0] - 2023-08-25

### Added

- Regular expressions can now be bound by `\n`, `\r`, and a combination of `\r\n`.
- Strings delimited by `%`, `%q`, and `%Q` can now be bound by `\n`, `\r`, and a combination of `\r\n`.
- `IntegerNode#value` now returns the value of the integer as a Ruby `Integer`.
- `FloatNode#value` now returns the value of the float as a Ruby `Float`.
- `RationalNode#value` now returns the value of the rational as a Ruby `Rational`.
- `ImaginaryNode#value` now returns the value of the imaginary as a Ruby `Complex`.
- `ClassNode#name` is now a string that returns the name of just the class, without the namespace.
- `ModuleNode#name` is now a string that returns the name of just the module, without the namespace.
- Regular expressions and strings found after a heredoc declaration but before the heredoc body are now parsed correctly.
- The serialization API now supports shared strings, which should help reduce the size of the serialized AST.
- `*Node#copy` is introduced, which returns a copy of the node with the given overrides.
- `Location#copy` is introduced, which returns a copy of the location with the given overrides.
- `DesugarVisitor` is introduced, which provides a simpler AST for use in tools that want to process fewer node types.
- `{ClassVariable,Constant,ConstantPath,GlobalVariable,InstanceVariable,LocalVariable}TargetNode` are introduced. These nodes represent the target of writes in locations where a value cannot be provided, like a multi write or a rescue reference.
- `UntilNode#closing_loc` and `WhileNode#closing_loc` are now provided.
- `Location#join` is now provided, which joins two locations together.
- `YARP::parse_lex` and `YARP::parse_lex_file` are introduced to parse and lex in one result.

### Changed

- When there is a magic encoding comment, the encoding of the first token's source string is now properly reencoded.
- Constants followed by unary `&` are now properly parsed as a call with a passed block argument.
- Escaping multi-byte characters in a string literal will now properly escape the entire character.
- `YARP.lex_compat` now has more accurate behavior when a byte-order mark is present in the file.
- **BREAKING**: `AndWriteNode`, `OrWriteNode`, and `OperatorWriteNode` have been split back up into their `0.7.0` versions.
- We now properly support spaces between the `encoding` and `=`/`:` in a magic encoding comment.
- We now properly parse `-> foo: bar do end`.

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

[unreleased]: https://github.com/ruby/yarp/compare/v0.11.0...HEAD
[0.11.0]: https://github.com/ruby/yarp/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/ruby/yarp/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/ruby/yarp/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/ruby/yarp/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/ruby/yarp/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/ruby/yarp/compare/d60531...v0.6.0
