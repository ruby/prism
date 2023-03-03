# frozen_string_literal: true

require "delegate"

module YARP
  # This represents a location in the source corresponding to a node or token.
  class Location
    attr_reader :start_offset, :end_offset

    def initialize(start_offset, end_offset)
      @start_offset = start_offset
      @end_offset = end_offset
    end

    def deconstruct_keys(keys)
      { start_offset: start_offset, end_offset: end_offset }
    end

    def pretty_print(q)
      q.text("(#{start_offset}..#{end_offset})")
    end

    def ==(other)
      other in Location[start_offset: ^(start_offset), end_offset: ^(end_offset)]
    end

    def self.null
      new(0, 0)
    end
  end

  # This represents a comment that was encountered during parsing.
  class Comment
    attr_reader :type, :location

    def initialize(type, location)
      @type = type
      @location = location
    end

    def deconstruct_keys(keys)
      { type: type, location: location }
    end
  end

  # This represents an error that was encountered during parsing.
  class ParseError
    attr_reader :message, :location

    def initialize(message, location)
      @message = message
      @location = location
    end

    def deconstruct_keys(keys)
      { message: message, location: location }
    end
  end

  # This represents a warning that was encountered during parsing.
  class ParseWarning
    attr_reader :message, :location

    def initialize(message, location)
      @message = message
      @location = location
    end

    def deconstruct_keys(keys)
      { message: message, location: location }
    end
  end

  # This represents the result of a call to ::parse or ::parse_file. It contains
  # the AST, any comments that were encounters, and any errors that were
  # encountered.
  class ParseResult
    attr_reader :value, :comments, :errors, :warnings

    def initialize(value, comments, errors, warnings)
      @value = value
      @comments = comments
      @errors = errors
      @warnings = warnings
    end

    def deconstruct_keys(keys)
      { value: value, comments: comments, errors: errors, warnings: warnings }
    end

    def success?
      errors.empty?
    end

    def failure?
      !success?
    end
  end

  # This represents a token from the Ruby source.
  class Token
    attr_reader :type, :value, :location

    def initialize(type, value, location)
      @type = type
      @value = value
      @location = location
    end

    def deconstruct_keys(keys)
      { type: type, value: value, location: location }
    end

    def pretty_print(q)
      q.group do
        q.text("#{type}(")
        q.nest(2) do
          q.breakable("")
          q.pp(value)
        end
        q.breakable("")
        q.text(")")
      end
    end

    def ==(other)
      other in Token[type: ^(type), value: ^(value)]
    end
  end

  # This represents a node in the tree.
  class Node
    def pretty_print(q)
      q.group do
        q.text("#{self.class.name.split("::").last}(")
        q.nest(2) do
          deconstructed = deconstruct_keys([])
          deconstructed.delete(:location)

          q.breakable("")
          q.seplist(deconstructed, lambda { q.comma_breakable }, :each_value) { |value| q.pp(value) }
        end
        q.breakable("")
        q.text(")")
      end
    end
  end

  # A class that knows how to walk down the tree. None of the individual visit
  # methods are implemented on this visitor, so it forces the consumer to
  # implement each one that they need. For a default implementation that
  # continues walking the tree, see the Visitor class.
  class BasicVisitor
    def visit(node)
      node&.accept(self)
    end

    def visit_all(nodes)
      nodes.map { |node| visit(node) }
    end

    def visit_child_nodes(node)
      visit_all(node.child_nodes)
    end
  end

  # This lexes with the Ripper lex. It drops any space events but otherwise
  # returns the same tokens.
  def self.lex_ripper(source)
    Ripper.lex(source).each_with_object([]) do |token_arr, tokens|
      token = LexedToken.new(*token_arr)
      tokens << token unless token.event == :on_sp
    end
  end

  class LexedToken < SimpleDelegator
    attr_reader :location, :event, :value
    attr_accessor :state

    def initialize(location, event, value, state)
      @location = location
      @event = event
      @value = value
      @state = state
    end

    def [](index)
      inspect[index]
    end

    def ==(other)
      other in LexedToken[
        location: ^(location),
        event: ^(event),
        value: ^(value),
        state: ^(state)
      ] or other in LexedToken[
        location: ^(location),
        event: :on_comment,
        value: ^(value)
      ]
    end

    def is_tilde_heredoc?
      value[2] == "~"
    end

    def inspect
      [@location, @event, @value, @state]
    end

    def deconstruct_keys(keys)
      { location: location, event: event, value: value, state: state }
    end

    def pretty_print(q)
      q.group do
        q.text("#{self.class.name.split("::").last}(")
        q.nest(2) do
          deconstructed = deconstruct_keys([])

          q.breakable("")
          q.seplist(deconstructed, lambda { q.comma_breakable }, :each_value) { |value| q.pp(value) }
        end
        q.breakable("")
        q.text(")")
      end
    end
  end

  # This class is responsible for lexing the source using YARP and then
  # converting those tokens to be compatible with Ripper.
  class LexCompat
    RIPPER = {
      AMPERSAND: :on_op,
      AMPERSAND_AMPERSAND: :on_op,
      AMPERSAND_AMPERSAND_EQUAL: :on_op,
      AMPERSAND_DOT: :on_op,
      AMPERSAND_EQUAL: :on_op,
      BACK_REFERENCE: :on_backref,
      BACKTICK: :on_backtick,
      BANG: :on_op,
      BANG_EQUAL: :on_op,
      BANG_TILDE: :on_op,
      BRACE_LEFT: :on_lbrace,
      BRACE_RIGHT: :on_rbrace,
      BRACKET_LEFT: :on_lbracket,
      BRACKET_LEFT_RIGHT: :on_op,
      BRACKET_LEFT_RIGHT_EQUAL: :on_op,
      BRACKET_RIGHT: :on_rbracket,
      CARET: :on_op,
      CARET_EQUAL: :on_op,
      CHARACTER_LITERAL: :on_CHAR,
      CLASS_VARIABLE: :on_cvar,
      COLON: :on_op,
      COLON_COLON: :on_op,
      COMMA: :on_comma,
      COMMENT: :on_comment,
      CONSTANT: :on_const,
      DOT: :on_period,
      DOT_DOT: :on_op,
      DOT_DOT_DOT: :on_op,
      EMBDOC_BEGIN: :on_embdoc_beg,
      EMBDOC_END: :on_embdoc_end,
      EMBDOC_LINE: :on_embdoc,
      EMBEXPR_BEGIN: :on_embexpr_beg,
      EMBEXPR_END: :on_embexpr_end,
      EMBVAR: :on_embvar,
      EOF: :on_eof,
      EQUAL: :on_op,
      EQUAL_EQUAL: :on_op,
      EQUAL_EQUAL_EQUAL: :on_op,
      EQUAL_GREATER: :on_op,
      EQUAL_TILDE: :on_op,
      FLOAT: :on_float,
      GREATER: :on_op,
      GREATER_EQUAL: :on_op,
      GREATER_GREATER: :on_op,
      GREATER_GREATER_EQUAL: :on_op,
      GLOBAL_VARIABLE: :on_gvar,
      HEREDOC_END: :on_heredoc_end,
      HEREDOC_START: :on_heredoc_beg,
      IDENTIFIER: :on_ident,
      IGNORED_NEWLINE: :on_ignored_nl,
      IMAGINARY_NUMBER: :on_imaginary,
      INTEGER: :on_int,
      INSTANCE_VARIABLE: :on_ivar,
      INVALID: :INVALID,
      KEYWORD___ENCODING__: :on_kw,
      KEYWORD___LINE__: :on_kw,
      KEYWORD___FILE__: :on_kw,
      KEYWORD_ALIAS: :on_kw,
      KEYWORD_AND: :on_kw,
      KEYWORD_BEGIN: :on_kw,
      KEYWORD_BEGIN_UPCASE: :on_kw,
      KEYWORD_BREAK: :on_kw,
      KEYWORD_CASE: :on_kw,
      KEYWORD_CLASS: :on_kw,
      KEYWORD_DEF: :on_kw,
      KEYWORD_DEFINED: :on_kw,
      KEYWORD_DO: :on_kw,
      KEYWORD_DO_LOOP: :on_kw,
      KEYWORD_ELSE: :on_kw,
      KEYWORD_ELSIF: :on_kw,
      KEYWORD_END: :on_kw,
      KEYWORD_END_UPCASE: :on_kw,
      KEYWORD_ENSURE: :on_kw,
      KEYWORD_FALSE: :on_kw,
      KEYWORD_FOR: :on_kw,
      KEYWORD_IF: :on_kw,
      KEYWORD_IN: :on_kw,
      KEYWORD_MODULE: :on_kw,
      KEYWORD_NEXT: :on_kw,
      KEYWORD_NIL: :on_kw,
      KEYWORD_NOT: :on_kw,
      KEYWORD_OR: :on_kw,
      KEYWORD_REDO: :on_kw,
      KEYWORD_RESCUE: :on_kw,
      KEYWORD_RETRY: :on_kw,
      KEYWORD_RETURN: :on_kw,
      KEYWORD_SELF: :on_kw,
      KEYWORD_SUPER: :on_kw,
      KEYWORD_THEN: :on_kw,
      KEYWORD_TRUE: :on_kw,
      KEYWORD_UNDEF: :on_kw,
      KEYWORD_UNLESS: :on_kw,
      KEYWORD_UNTIL: :on_kw,
      KEYWORD_WHEN: :on_kw,
      KEYWORD_WHILE: :on_kw,
      KEYWORD_YIELD: :on_kw,
      LABEL: :on_label,
      LAMBDA_BEGIN: :on_tlambeg,
      LESS: :on_op,
      LESS_EQUAL: :on_op,
      LESS_EQUAL_GREATER: :on_op,
      LESS_LESS: :on_op,
      LESS_LESS_EQUAL: :on_op,
      MINUS: :on_op,
      MINUS_EQUAL: :on_op,
      MINUS_GREATER: :on_tlambda,
      NEWLINE: :on_nl,
      NTH_REFERENCE: :on_backref,
      PARENTHESIS_LEFT: :on_lparen,
      PARENTHESIS_RIGHT: :on_rparen,
      PERCENT: :on_op,
      PERCENT_EQUAL: :on_op,
      PERCENT_LOWER_I: :on_qsymbols_beg,
      PERCENT_LOWER_W: :on_qwords_beg,
      PERCENT_LOWER_X: :on_backtick,
      PERCENT_UPPER_I: :on_symbols_beg,
      PERCENT_UPPER_W: :on_words_beg,
      PIPE: :on_op,
      PIPE_EQUAL: :on_op,
      PIPE_PIPE: :on_op,
      PIPE_PIPE_EQUAL: :on_op,
      PLUS: :on_op,
      PLUS_EQUAL: :on_op,
      QUESTION_MARK: :on_op,
      RATIONAL_NUMBER: :on_rational,
      REGEXP_BEGIN: :on_regexp_beg,
      REGEXP_END: :on_regexp_end,
      SEMICOLON: :on_semicolon,
      SLASH: :on_op,
      SLASH_EQUAL: :on_op,
      STAR: :on_op,
      STAR_EQUAL: :on_op,
      STAR_STAR: :on_op,
      STAR_STAR_EQUAL: :on_op,
      STRING_BEGIN: :on_tstring_beg,
      STRING_CONTENT: :on_tstring_content,
      STRING_END: :on_tstring_end,
      SYMBOL_BEGIN: :on_symbeg,
      TILDE: :on_op,
      UMINUS: :on_op,
      UPLUS: :on_op,
      WORDS_SEP: :on_words_sep,
      __END__: :on___end__
    }.freeze

    # A heredoc in this case is a list of tokens that belong to the body of the
    # heredoc that should be appended onto the list of tokens when the heredoc
    # closes.
    class Heredoc
      attr_reader :state, :tokens

      def initialize(state)
        @state = state
        @tokens = []
      end

      def <<(token)
        tokens << token
      end

      def to_a
        tokens.last.state = state
        tokens
      end
    end

    private_constant :RIPPER, :Heredoc

    attr_reader :source, :offsets

    def initialize(source)
      @source = source

      @offsets = [0]
      last_offset = 0

      source.each_line do |line|
        last_offset += line.bytesize
        @offsets << last_offset
      end
    end

    def result
      tokens = []

      state = :default
      heredocs = []

      result = YARP.lex(source)
      previous_state = nil

      # If there's a UTF-8 byte-order mark as the start of the file, then ripper
      # sets every token's on the first line back by 6 bytes. It also keeps the
      # byte order mark in the first token's value. This is weird, and I don't
      # want to mirror that in our parser. So instead, we'll match up the values
      # here, and then match up the locations as we process the tokens.
      bom = source.bytes[0..2] == [0xEF, 0xBB, 0xBF]
      result.value[0][0].value.prepend("\xEF\xBB\xBF") if bom

      result.value.each_with_index do |(token, lex_state), index|
        event = RIPPER.fetch(token.type)
        lex_state =
          # On regex end, Ripper scans and then sets end state, so the ripper
          # lexed output is begin, when it should be end. YARP sets lex state
          # correctly to end state, but we want to be able to compare against
          # Ripper's lexed state. So here, if it's a regexp end token, we output
          # the state as the previous state, solely for the sake of comparison.
          if event == :on_regexp_end
            previous_token = result.value[index - 1][0]

            if RIPPER.fetch(previous_token.type) == :on_embexpr_end
              # If the previous token is embexpr_end, then we have to do even
              # more processing. The end of an embedded expression sets the
              # state to the state that it had at the beginning of the embedded
              # expression. So we have to go and find that state and set it
              # here.
              counter = 1
              current_index = index - 1

              until counter == 0
                current_index -= 1
                current_event = RIPPER.fetch(result.value[current_index][0].type)
                counter += { on_embexpr_beg: -1, on_embexpr_end: 1 }[current_event] || 0
              end

              Ripper::Lexer::State.new(result.value[current_index][1])
            else
              previous_state
            end
          else
            Ripper::Lexer::State.new(lex_state)
          end

        (lineno, column) = location_for(token.location.start_offset)
        column -= 6 if bom && lineno == 1

        token = LexedToken.new(
          [lineno, column],
          event,
          value_for(event, token.value),
          lex_state
        )

        previous_state = lex_state

        # The order in which tokens appear in our lexer is different from the
        # order that they appear in Ripper. When we hit the declaration of a
        # heredoc in YARP, we skip forward and lex the rest of the content of
        # the heredoc before going back and lexing at the end of the heredoc
        # identifier.
        #
        # To match up to ripper, we keep a small state variable around here to
        # track whether we're in the middle of a heredoc or not. In this way we
        # can shuffle around the token to match Ripper's output.
        case state
        when :default
          tokens << token

          if event == :on_heredoc_beg
            state = :heredoc_opened
            heredocs << Heredoc.new(lex_state)
          end
        when :heredoc_opened
          heredocs.last << token
          state = :heredoc_closed if event == :on_heredoc_end
        when :heredoc_closed
          tokens << token

          case event
          when :on_nl, :on_ignored_nl
            heredocs.each do |heredoc|
              tokens.concat(heredoc.to_a)
            end

            heredocs.clear
            state = :default
          when :on_heredoc_beg
            state = :heredoc_opened
            heredocs << Heredoc.new(lex_state)
          end
        end
      end

      ParseResult.new(tokens[0...-1], result.comments, result.errors, result.warnings)
    end

    private

    def location_for(start_offset)
      line_number, line_offset =
        offsets.each_with_index.detect do |(offset, line)|
          break [line, offsets[line - 1]] if start_offset < offset
        end

      [
        line_number || offsets.length - 1,
        start_offset - (line_offset || offsets.last)
      ]
    end

    def value_for(event, value)
      if event == :on___end__
        # Ripper doesn't include the rest of the token in the event, so we
        # need to trim it down to just the first newline.
        value[0..value.index("\n")]
      else
        value
      end
    end
  end

  # Returns an array of tokens that closely resembles that of the Ripper lexer.
  # The only difference is that since we don't keep track of lexer state in the
  # same way, it's going to always return the NONE state.
  def self.lex_compat(source)
    LexCompat.new(source).result
  end

  # We handle tilde heredocs in the parsing phase, not the lexing phase
  # However, we want to preserve the usefulness of comparing lexed results
  # This method allows us to sanitize lexing so we can ignore any differences
  # in the tilde heredocs
  def self.remove_tilde_heredocs(tokens)
    res = []

    ignoring_tokens = false
    tokens.each do |token|
      if token.event == :on_heredoc_beg && token.is_tilde_heredoc?
        ignoring_tokens = true
      elsif token.event == :on_heredoc_end
        ignoring_tokens = false
      elsif !ignoring_tokens
        res << token
      end
    end
    res
  end

  # Load the serialized AST using the source as a reference into a tree.
  def self.load(source, serialized)
    Serialize.load(source, serialized)
  end
end

require_relative "yarp/node"
require_relative "yarp/ripper_compat"
require_relative "yarp/serialize"
require_relative "yarp/yarp"
require_relative "yarp/pack"
