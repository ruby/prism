# Yet Another Ruby Parser

This is a very early work-in-progress project geared at replacing the existing CRuby parser. Its aims are threefold:

* Portability - we want the ability to use this parser in other projects, implementations, and tools.
* Error tolerance - we want this parser to be able to recover from as many syntax errors as possible.
* Maintainability - we want this to be a long-standing projects with good hygeine. This means tutorials, examples, documentation, clean code, good test coverage, etc.

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

Feel free to open a discussion with any thoughts you may have. Also be sure to check out the [first issue](https://github.com/ruby-syntax-tree/yarp/issues/1) opened on this repository which has the answer to a lot of questions relevant at the moment.
