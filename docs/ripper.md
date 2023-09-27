# Ripper

To test the parser, we compare against the output from `Ripper`, both for testing the lexer and testing the parser. The lexer test suite is much more feature complete at the moment.

To lex source code using `prism`, you typically would run `Prism.lex(source)`. If you want to instead get output that `Ripper` would normally produce, you can run `Prism.lex_compat(source)`. This will produce tokens that should be equivalent to `Ripper`.

To parse source code using `prism`, you typically would run `Prism.parse(source)`. If you want to instead using the `Ripper` streaming interface, you can inherit from `Prism::RipperCompat` and override the `on_*` methods. This will produce a syntax tree that should be equivalent to `Ripper`. That would look like:

```ruby
class ArithmeticRipper < Prism::RipperCompat
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

There are also APIs for building trees similar to the s-expression builders in `Ripper`. The method names are the same. These include `Prism::RipperCompat.sexp_raw(source)` and `Prism::RipperCompat.sexp(source)`.
