# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.19.0] - 2023-12-14

### Added

- `ArrayNode` now has a `contains_splat?` flag if it has a splatted element in it.
- All of the remaining encodings have been implemented.
- Allow forwarding `&` in a method that has a `...` parameter.
- Many statements that are found in non-statement positions are being properly rejected now.
- Void values are now properly checked.
- Referencing a parameter in its own default value is now properly rejected.
- `DATA`/`__END__` is now parsed as its own field on parse result (`data_loc`) as opposed to as a comment.
- Blank `*` now properly forwards into arrays.
- `ImplicitRestNode` is introduced to represent the implicit rest of a destructure.
- We now support negative start lines.
- `StringNode#heredoc?`, `InterpolatedStringNode#heredoc?`, `XStringNode#heredoc?`, and `InterpolatedXStringNode#heredoc?` are introduced.
- `NumberedParametersNode` is introduced to represent the implicit set of parameters when numbered parameters are used.
- `Prism::parse_success?` and `Prism::parse_failure?` are introduced to bypass reifying the AST.
- We now emit a warning for constant assignments in method definitions.
- We now provide flags on strings and xstrings to indicate the correct encoding.
- The hash pattern `rest` field now more accurately parses `**` and `**nil`.
- The equality operators are now properly parsed as non-associative.

### Changed

- **BREAKING**: Many fields have changed positions within their nodes. This impacts the C API and the Ruby API if you are manually creating nodes through the initializer.
- **BREAKING**: Almost all of the error messages have been updated to begin with lowercase characters to match ruby/spec.
- Unterminated strings with only plain content are now always `StringNode` as opposed to `InterpolatedStringNode`
- **BREAKING**: Call node has been split up when it is in the target position into `CallTargetNode` and `IndexTargetNode`.

## [0.18.0] - 2023-11-21

### Added

- The `ParametersNode#signature` method is added, which returns the same thing as `Method#parameters`.
- Visitor functionality has been added to the JavaScript API.
- The `Node#to_dot` API has been added to convert syntax trees to Graphviz digraphs.
- `IfNode` and `UnlessNode` now have a `then_keyword_loc` field.
- Many more encodings are now supported.
- Some new `Location` APIs have been added for dealing with characters instead of bytes, which are: `start_character_offset`, `end_character_offset`, `start_character_column`, and `end_character_column`.
- A warning has been added for when `END {}` is used within a method.
- `ConstantPathNode#full_name{,_parts}` will now raise an error if the receiver of the constant path is not itself a constant.
- The `in` keyword and the `=>` operator now respect non-associativity.
- The `..` and `...` operators now properly respect non-associativity.

### Changed

- Previously `...` in blocks was accepted, but it is now properly rejected.
- **BREAKING**: `librubyparser.*` has been renamed to `libprism.*` in the C API.
- We now properly reject floats with exponent and rational suffixes.
- We now properly reject void value expressions.
- **BREAKING**: The `--disable-static` option has been removed from the C extension.
- The rescue modifier keyword is now properly parsed in terms of precedence.
- We now properly reject defining a numbered parameter method.
- **BREAKING**: `MatchWriteNode` now has a list of `targets`, which are local variable target nodes. This is instead of `locals` which was a constant list. This is to support writing to local variables outside the current scope. It has the added benefit of providing location information for the local variable targets.
- **BREAKING**: `CaseNode` has been split into `CaseNode` and `CaseMatchNode`, the latter is used for `case ... in` expressions.
- **BREAKING**: `StringConcatNode` has been removed in favor of using `InterpolatedStringNode` as a list.

## [0.17.1] - 2023-11-03

### Changed

- Do not use constant nesting in RBI files.

## [0.17.0] - 2023-11-03

### Added

- We now properly support forwarding arguments into arrays, like `def foo(*) = [*]`.
- We now have much better documentation for the C and Ruby APIs.
- We now properly provide an error message when attempting to assign to numbered parameters from within regular expression named capture groups, as in `/(?<_1>)/ =~ ""`.

### Changed

- **BREAKING**: `KeywordParameterNode` is split into `OptionalKeywordParameterNode` and `RequiredKeywordParameterNode`. `RequiredKeywordParameterNode` has no `value` field.
- **BREAKING**: Most of the `Prism::` APIs now accept a bunch of keyword options. The options we now support are: `filepath`, `encoding`, `line`, `frozen_string_literal`, `verbose`, and `scopes`. See [the pull request](https://github.com/ruby/prism/pull/1763) for more details.
- **BREAKING**: Comments are now split into three different classes instead of a single class, and the `type` field has been removed. They are: `InlineComment`, `EmbDocComment`, and `DATAComment`.

## [0.16.0] - 2023-10-30

### Added

- `InterpolatedMatchLastLineNode#options` and `MatchLastLineNode#options` are added, which are the same methods as are exposed on `InterpolatedRegularExpressionNode` and `RegularExpressionNode`.
- The project can now be compiled with `wasi-sdk` to expose a WebAssembly interface.
- `ArgumentsNode#keyword_splat?` is added to indicate if the arguments node has a keyword splat.
- The C API `pm_prettyprint` has a much improved output which lines up closely with `Node#inspect`.
- Prism now ships with `RBS` and `RBI` type signatures (in the `/sig` and `/rbi` directories, respectively).
- `Prism::parse_comments` and `Prism::parse_file_comments` APIs are added to extract only the comments from the source code.

### Changed

- **BREAKING**: `Multi{Target,Write}Node#targets` is split up now into `lefts`, `rest`, and `rights`. This is to avoid having to scan the list in the case that there are splat nodes.
- Some bugs are fixed on `Multi{Target,Write}Node` accidentally creating additional nesting when not necessary.
- **BREAKING**: `RequiredDestructuredParameterNode` has been removed in favor of using `MultiTargetNode` in those places.
- **BREAKING**: `HashPatternNode#assocs` has been renamed to `HashPatternNode#elements`. `HashPatternNode#kwrest` has been renamed to `HashPatternNode#rest`.

## [0.15.1] - 2023-10-18

### Changed

- Fix compilation warning on assigning to bitfield.

## [0.15.0] - 2023-10-18

### Added

- `BackReferenceReadNode#name` is now provided.
- `Index{Operator,And,Or}WriteNode` are introduced, split out from `Call{Operator,And,Or}WriteNode` when the method is `[]`.

### Changed

- Ensure `PM_NODE_FLAG_COMMON_MASK` into a constant expression to fix compile errors.
- `super(&arg)` is now fixed.
- Ensure the last encoding flag on regular expressions wins.
- Fix the common whitespace calculation when embedded expressions begin on a line.
- Capture groups in regular expressions now scan the unescaped version to get the correct local variables.
- `*` and `&` are added to the local table when `...` is found in the parameters of a method definition.

## [0.14.0] - 2023-10-13

### Added

- Syntax errors are added for invalid lambda local semicolon placement.
- Lambda locals are now checked for duplicate names.
- Destructured parameters are now checked for duplicate names.
- `Constant{Read,Path,PathTarget}Node#full_name` and `Constant{Read,Path,PathTarget}Node#full_name_parts` are added to walk constant paths for you to find the full name of the constant.
- Syntax errors are added when assigning to a numbered parameter.
- `Node::type` is added, which matches the `Node#type` API.
- Magic comments are now parsed as part of the parsing process and a new field is added in the form of `ParseResult#magic_comments` to access them.

### Changed

- **BREAKING**: `Call*Node#name` methods now return symbols instead of strings.
- **BREAKING**: For loops now have their index value considered as part of the body, so depths of local variable assignments will be increased by 1.
- Tilde heredocs now split up their lines into multiple string nodes to make them easier to dedent.

## [0.13.0] - 2023-09-29

### Added

- `BEGIN {}` blocks are only allowed at the top-level, and will now provide a syntax error if they are not.
- Numbered parameters are not allowed in block parameters, and will now provide a syntax error if they are.
- Many more Ruby modules and classes are now documented. Also, many have been moved into their own files and autoloaded so that initial boot time of the gem is much faster.
- `PM_TOKEN_METHOD_NAME` is introduced, used to indicate an identifier that if definitely a method name because it has an `!` or `?` at the end.
- In the C API, arrays, assocs, and hashes now can have the `PM_NODE_FLAG_STATIC_LITERAL` flag attached if they can be compiled statically. This is used in CRuby, for example, to determine if a `duphash`/`duparray` instruction can be used as opposed to a `newhash`/`newarray`.
- `Node#type` is introduced, which returns a symbol representing the type of the node. This is useful for case comparisons when you have to compare against multiple types.

### Changed

- **BREAKING**: Everything has been renamed to `prism` instead of `yarp`. The `yp_`/`YP_` prefix in the C API has been changed to `pm_`/`PM_`. For the most part, everything should be find/replaceable.
- **BREAKING**: `BlockArgumentNode` nodes now go into the `block` field on `CallNode` nodes, in addition to the `BlockNode` nodes that used to be there. Hopefully this makes it more consistent to compile/deal with in general, but it does mean it can be a surprising breaking change.
- Escaped whitespace in `%w` lists is now properly unescaped.
- `Node#pretty_print` now respects pretty print indentation.
- `Dispatcher` was previously firing `_leave` events in the incorrect order. This has now been fixed.
- **BREAKING**: `Visitor` has now been split into `Visitor` and `Compiler`. The visitor visits nodes but doesn't return anything from the visit methods. It is suitable for taking action based on the tree, but not manipulating the tree itself. The `Compiler` visits nodes and returns the computed value up the tree. It is suitable for compiling the tree into another format. As such, `MutationVisitor` has been renamed to `MutationCompiler`.

## [0.12.0] - 2023-09-15

### Added

- `RegularExpressionNode#options` and `InterpolatedRegularExpressionNode#options` are now provided. These return integers that match up to the `Regexp#options` API.
- Greatly improved `Node#inspect` and `Node#pretty_print` APIs.
- `MatchLastLineNode` and `InterpolatedMatchLastLineNode` are introduced to represent using a regular expression as the predicate of an `if` or `unless` statement.
- `IntegerNode` now has a base flag on it.
- Heredocs that were previously `InterpolatedStringNode` and `InterpolatedXStringNode` nodes without any actual interpolation are now `StringNode` and `XStringNode`, respectively.
- `StringNode` now has a `frozen?` flag on it, which respects the `frozen_string_literal` magic comment.
- Numbered parameters are now supported, and are properly represented using `LocalVariableReadNode` nodes.
- `ImplicitNode` is introduced, which wraps implicit calls, local variable reads, or constant reads in omitted hash values.
- `YARP::Dispatcher` is introduced, which provides a way for multiple objects to listen for certain events on the AST while it is being walked. This is effectively a way to implement a more efficient visitor pattern when you have many different uses for the AST.

### Changed

- **BREAKING**: Flags fields are now marked as private, to ensure we can change their implementation under the hood. Actually querying should be through the accessor methods.
- **BREAKING**: `AliasNode` is now split into `AliasMethodNode` and `AliasGlobalVariableNode`.
- Method definitions on local variables is now correctly handled.
- Unary minus precedence has been fixed.
- Concatenating character literals with string literals is now fixed.
- Many more invalid syntaxes are now properly rejected.
- **BREAKING**: Comments now no longer include their trailing newline.

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

[unreleased]: https://github.com/ruby/prism/compare/v0.19.0...HEAD
[0.19.0]: https://github.com/ruby/prism/compare/v0.18.0...v0.19.0
[0.18.0]: https://github.com/ruby/prism/compare/v0.17.1...v0.18.0
[0.17.1]: https://github.com/ruby/prism/compare/v0.17.0...v0.17.1
[0.17.0]: https://github.com/ruby/prism/compare/v0.16.0...v0.17.0
[0.16.0]: https://github.com/ruby/prism/compare/v0.15.1...v0.16.0
[0.15.1]: https://github.com/ruby/prism/compare/v0.15.0...v0.15.1
[0.15.0]: https://github.com/ruby/prism/compare/v0.14.0...v0.15.0
[0.14.0]: https://github.com/ruby/prism/compare/v0.13.0...v0.14.0
[0.13.0]: https://github.com/ruby/prism/compare/v0.12.0...v0.13.0
[0.12.0]: https://github.com/ruby/prism/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/ruby/prism/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/ruby/prism/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/ruby/prism/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/ruby/prism/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/ruby/prism/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/ruby/prism/compare/d60531...v0.6.0
