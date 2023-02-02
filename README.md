# Yet Another Ruby Parser

This is an early work-in-progress project geared at replacing the existing CRuby parser. Its aims are threefold:

* Portability - we want the ability to use this parser in other projects, implementations, and tools.
* Error tolerance - we want this parser to be able to recover from as many syntax errors as possible.
* Maintainability - we want this to be a long-standing projects with good hygiene. This means tutorials, examples, documentation, clean code, good test coverage, etc.

## Background

[This link](https://docs.google.com/document/d/1x74L_paTxS_h8_OtQjDoLVgxZP6Y96WOJ1LdLNb4BKM/edit#heading=h.6eyajfy04xhw) is where you can find the design document for the project. It is also a work-in-progress, but should give you a good sense of the overall goals and motivations.

There are many parsers that have been built before in various stages of upkeep. Below is a list of the ones I have read through and found useful:

* [jruby/jruby](https://github.com/jruby/jruby)
* [lib-ruby-parser/lib-ruby-parser](https://github.com/lib-ruby-parser/lib-ruby-parser)
* [natalie-lang/natalie_parser](https://github.com/natalie-lang/natalie_parser)
* [oracle/truffleruby](https://github.com/oracle/truffleruby)
* [ruby/ruby](https://github.com/ruby/ruby)
* [seattlerb/ruby_parser](https://github.com/seattlerb/ruby_parser)
* [sisshiki1969/ruruby](https://github.com/sisshiki1969/ruruby)
* [sorbet/sorbet](https://github.com/sorbet/sorbet)
* [whitequark/parser](https://github.com/whitequark/parser)

There are also a couple of tools that define node shapes for every kind of node in the Ruby syntax tree. I've taken inspiration from those tools as well. They include most of the parsers above, as well as:

* [ruby-syntax-tree/syntax_tree](https://github.com/ruby-syntax-tree/syntax_tree)
* [ruby/ruby/node.h](https://github.com/ruby/ruby/blob/master/node.h) (`RubyVM::AST`)

## Overview

The repository contains the infrastructure for both a shared library (librubyparser) and a native Ruby extension. The shared library has no bindings to Ruby itself, and so can be used by other C libraries. The native Ruby extension links against `ruby.h`, and so is suitable in the context of Ruby.

```
.
├── Makefile              configuration to compile the shared library and native tests
├── Rakefile              configuration to compile the native extension and run the Ruby tests
├── bin
│   ├── template          generates code from the nodes and tokens configured by config.yml
│   └── templates         directory containing all of the various templates
├── config.yml            specification for tokens and nodes in the tree
├── ext
│   └── yarp
│       └── extension.c   the native extension that interacts with librubyparser
├── lib
│   ├── yarp              support files for the Ruby library
│   └── yarp.rb           main entrypoint into the Ruby library
├── src
│   ├── yarp.c            main entrypoint into the shared library
│   └── yarp.h            main header file for the shared library
└── test                  Ruby tests for the Ruby library
```

## Contributing

See the [CONTRIBUTING.md](CONTRIBUTING.md) file for more information. We additionally have documentation about the overall design of the project as well as various subtopics.

* [Design](docs/design.md)
* [Encoding](docs/encoding.md)
* [Extension](docs/extension.md)
* [Ripper](docs/ripper.md)
* [Serialization](docs/serialization.md)
