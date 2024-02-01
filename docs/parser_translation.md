# parser translation

Prism ships with the ability to translate its syntax tree into the syntax tree used by the [whitequark/parser](https://github.com/whitequark/parser) gem. This allows you to use tools built on top of the `parser` gem with the `prism` parser.

## Usage

The `parser` gem provides multiple parsers to support different versions of the Ruby grammar. This includes all of the Ruby versions going back to 1.8, as well as third-party parsers like MacRuby and RubyMotion. The `prism` gem provides another parser that uses the `prism` parser to build the syntax tree.

You can use the `prism` parser like you would any other. After requiring the parser, you should be able to call any of the regular `Parser::Base` APIs that you would normally use.

```ruby
require "prism"

Prism::Translation::Parser.parse_file("path/to/file.rb")
```

### RuboCop

To run RuboCop using the `prism` gem as the parser, you will need to require the `prism/translation/parser/rubocop` file. This file injects `prism` into the known options for both `rubocop` and `rubocop-ast`, such that you can specify it in your `.rubocop.yml` file. Unfortunately `rubocop` doesn't support any direct way to do this, so we have to get a bit hacky.

First, set the `TargetRubyVersion` in your RuboCop configuration file to `80_82_73_83_77.33`. This is the version of Ruby that `prism` reports itself as. (The leading numbers are the ASCII values for `PRISM`.)

```yaml
AllCops:
  TargetRubyVersion: 80_82_73_83_77.33
```

Now when you run `rubocop` you will need to require the `prism/translation/parser/rubocop` file before executing so that it can inject the `prism` parser into the known options.

```
bundle exec ruby -rprism/translation/parser/rubocop $(bundle exec which rubocop)
```

This should run RuboCop using the `prism` parser.
