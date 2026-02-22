# typed: true

module Prism
  module Translation
    class Ripper
      EXPR_NONE = T.let(nil, Integer)
      EXPR_BEG = T.let(nil, Integer)
      EXPR_MID = T.let(nil, Integer)
      EXPR_END = T.let(nil, Integer)
      EXPR_CLASS = T.let(nil, Integer)
      EXPR_VALUE = T.let(nil, Integer)
      EXPR_ARG = T.let(nil, Integer)
      EXPR_CMDARG = T.let(nil, Integer)
      EXPR_ENDARG = T.let(nil, Integer)
      EXPR_ENDFN = T.let(nil, Integer)

      class Lexer < Ripper
        class State
          sig { params(value: Integer).returns(State) }
          def self.[](value); end
        end
      end
    end
  end

  # This class is responsible for lexing the source using prism and then
  # converting those tokens to be compatible with Ripper. In the vast majority
  # of cases, this is a one-to-one mapping of the token type. Everything else
  # generally lines up. However, there are a few cases that require special
  # handling.
  class LexCompat
    # A result class specialized for holding tokens produced by the lexer.
    class Result < Prism::Result
      # The list of tokens that were produced by the lexer.
      sig { returns(T::Array[[[Integer, Integer], Symbol, String, T.untyped]]) }
      attr_reader :value

      # Create a new lex compat result object with the given values.
      sig { params(value: T::Array[[[Integer, Integer], Symbol, String, T.untyped]], comments: T::Array[Comment], magic_comments: T::Array[MagicComment], data_loc: T.nilable(Location), errors: T::Array[ParseError], warnings: T::Array[ParseWarning], source: Source).void }
      def initialize(value, comments, magic_comments, data_loc, errors, warnings, source); end

      # Implement the hash pattern matching interface for Result.
      sig { params(keys: T.nilable(T::Array[Symbol])).returns(T::Hash[Symbol, T.untyped]) }
      def deconstruct_keys(keys); end
    end

    # This is a mapping of prism token types to Ripper token types. This is a
    # many-to-one mapping because we split up our token types, whereas Ripper
    # tends to group them.
    RIPPER = T.let(nil, T.untyped)

    # A heredoc in this case is a list of tokens that belong to the body of the
    # heredoc that should be appended onto the list of tokens when the heredoc
    # closes.
    module Heredoc
      # Heredocs that are no dash or tilde heredocs are just a list of tokens.
      # We need to keep them around so that we can insert them in the correct
      # order back into the token stream and set the state of the last token to
      # the state that the heredoc was opened in.
      class PlainHeredoc
        sig { returns(T::Array[[[Integer, Integer], Symbol, String, T.untyped]]) }
        attr_reader :tokens

        sig { void }
        def initialize; end

        sig { params(token: [[Integer, Integer], Symbol, String, T.untyped]).void }
        def <<(token); end

        sig { returns(T::Array[[[Integer, Integer], Symbol, String, T.untyped]]) }
        def to_a; end
      end

      # Dash heredocs are a little more complicated. They are a list of tokens
      # that need to be split on "\\\n" to mimic Ripper's behavior. We also need
      # to keep track of the state that the heredoc was opened in.
      class DashHeredoc
        sig { returns(T::Boolean) }
        attr_reader :split

        sig { returns(T::Array[[[Integer, Integer], Symbol, String, T.untyped]]) }
        attr_reader :tokens

        sig { params(split: T::Boolean).void }
        def initialize(split); end

        sig { params(token: [[Integer, Integer], Symbol, String, T.untyped]).void }
        def <<(token); end

        sig { returns(T::Array[[[Integer, Integer], Symbol, String, T.untyped]]) }
        def to_a; end
      end

      # Heredocs that are dedenting heredocs are a little more complicated.
      # Ripper outputs on_ignored_sp tokens for the whitespace that is being
      # removed from the output. prism only modifies the node itself and keeps
      # the token the same. This simplifies prism, but makes comparing against
      # Ripper much harder because there is a length mismatch.
      #
      # Fortunately, we already have to pull out the heredoc tokens in order to
      # insert them into the stream in the correct order. As such, we can do
      # some extra manipulation on the tokens to make them match Ripper's
      # output by mirroring the dedent logic that Ripper uses.
      class DedentingHeredoc
        TAB_WIDTH = T.let(nil, Integer)

        sig { returns(T::Array[[[Integer, Integer], Symbol, String, T.untyped]]) }
        attr_reader :tokens

        sig { returns(T::Boolean) }
        attr_reader :dedent_next

        sig { returns(T.nilable(Integer)) }
        attr_reader :dedent

        sig { returns(Integer) }
        attr_reader :embexpr_balance

        sig { void }
        def initialize; end

        # As tokens are coming in, we track the minimum amount of common leading
        # whitespace on plain string content tokens. This allows us to later
        # remove that amount of whitespace from the beginning of each line.
        #
        sig { params(token: [[Integer, Integer], Symbol, String, T.untyped]).void }
        def <<(token); end

        sig { returns(T::Array[[[Integer, Integer], Symbol, String, T.untyped]]) }
        def to_a; end
      end

      # Here we will split between the two types of heredocs and return the
      # object that will store their tokens.
      sig { params(opening: [[Integer, Integer], Symbol, String, T.untyped]).returns(T.any(PlainHeredoc, DashHeredoc, DedentingHeredoc)) }
      def self.build(opening); end
    end

    # In previous versions of Ruby, Ripper wouldn't flush the bom before the
    # first token, so we had to have a hack in place to account for that.
    BOM_FLUSHED = T.let(nil, T.untyped)

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :options

    sig { params(source: String, options: T.untyped).void }
    def initialize(source, **options); end

    sig { returns(Result) }
    def result; end

    sig { params(tokens: T::Array[[[Integer, Integer], Symbol, String, T.untyped]], source: Source, data_loc: T.nilable(Location), bom: T::Boolean, eof_token: T.nilable(Token)).returns(T::Array[[[Integer, Integer], Symbol, String, T.untyped]]) }
    private def post_process_tokens(tokens, source, data_loc, bom, eof_token); end
  end
end
