# Ripper translation

Prism provides the ability to mirror the `Ripper` standard library. You can do this by:

```ruby
require "prism/translation/ripper/shim"
```

This provides the APIs like:

```ruby
Ripper.lex
Ripper.parse
Ripper.sexp_raw
Ripper.sexp

Ripper::SexpBuilder
Ripper::SexpBuilderPP
```

Briefly, `Ripper` is a streaming parser that allows you to construct your own syntax tree. As an example:

```ruby
class ArithmeticRipper < Prism::Translation::Ripper
  def on_binary(left, operator, right)
    left.public_send(operator, right)
  end

  def on_int(value)
    value.to_i
  end

  def on_program(stmts)
    stmts
  end

  def on_stmts_new
    []
  end

  def on_stmts_add(stmts, stmt)
    stmts << stmt
    stmts
  end
end

ArithmeticRipper.new("1 + 2 - 3").parse # => [0]
```

The exact names of the `on_*` methods are listed in the `Ripper` source.
