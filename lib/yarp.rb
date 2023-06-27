# frozen_string_literal: true

module YARP
  # This represents a source of Ruby code that has been parsed. It is used in
  # conjunction with locations to allow them to resolve line numbers and source
  # ranges.
  class SourceRange
    attr_reader :source, :newlines

    def initialize(source, newlines)
      @source = source
      @newlines = newlines
    end

    def slice(offset, length)
      source.byteslice(offset, length)
    end

    def line(offset)
      newlines.bsearch_index { |newline| newline > offset } || newlines.length
    end

    def column(offset)
      newlines[line_number(offset)] || 0
    end
  end

  # This represents a location in the source.
  class Location
    # A SourceRange object that is used to determine more information from the
    # given offset and length.
    attr_reader :source_range

    # The byte offset from the beginning of the source where this location
    # starts.
    attr_reader :start_offset

    # The length of this location in bytes.
    attr_reader :length

    def initialize(source_range, start_offset, length)
      @source_range = source_range
      @start_offset = start_offset
      @length = length
    end

    # The source code that this location represents.
    def slice
      source_range.slice(start_offset, length)
    end

    # The byte offset from the beginning of the source where this location ends.
    def end_offset
      start_offset + length
    end

    # The line number where this location starts.
    def start_line
      source_range.line(start_offset)
    end

    # The line number where this location ends.
    def end_line
      source_range.line(end_offset)
    end

    # The column number in bytes where this location starts from the start of
    # the line.
    def start_column
      source_range.column(start_offset)
    end

    # The column number in bytes where this location ends from the start of the
    # line.
    def end_column
      source_range.column(end_offset)
    end

    def deconstruct_keys(keys)
      { start_offset: start_offset, end_offset: end_offset }
    end

    def pretty_print(q)
      q.text("(#{start_offset}...#{end_offset})")
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
        q.text(type.to_s)
        self.location.pretty_print(q)
        q.text("(")
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
    attr_reader :location

    def pretty_print(q)
      q.group do
        q.text(self.class.name.split("::").last)
        location.pretty_print(q)
        q.text("(")
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
  # [raises SyntaxError] if the syntax in source is invalid
  def self.lex_ripper(source)
    previous = []
    results = []

    Ripper.lex(source, raise_errors: true).each do |token|
      case token[1]
      when :on_sp
        # skip
      when :on_tstring_content
        if previous[1] == :on_tstring_content &&
            (token[2].start_with?("\#$") || token[2].start_with?("\#@"))
          previous[2] << token[2]
        else
          results << token
          previous = token
        end
      when :on_words_sep
        if previous[1] == :on_words_sep
          previous[2] << token[2]
        else
          results << token
          previous = token
        end
      else
        results << token
        previous = token
      end
    end

    results
  end

  # Load the serialized AST using the source as a reference into a tree.
  def self.load(source, serialized)
    Serialize.load(source, serialized)
  end

  def self.parse(source, filepath=nil)
    _parse(source, filepath)
  end
end

require_relative "yarp/lex_compat"
require_relative "yarp/node"
require_relative "yarp/ripper_compat"
require_relative "yarp/serialize"
require_relative "yarp/pack"
require "yarp.so"

module YARP
  class << self
    private :_parse
  end
end
