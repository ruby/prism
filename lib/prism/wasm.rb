# frozen_string_literal: true
# :markup: markdown
# typed: ignore

# This file is responsible for mirroring the API provided by the C extension by
# using FFI to call into the shared library.

require "rbconfig"
require "ffi"

# We want to eagerly load this file if there are Ractors so that it does not get
# autoloaded from within a non-main Ractor.
require "prism/serialize" if defined?(Ractor)

# Load the prism-parser-wasm jar
require 'jar-dependencies'
require_jar('org.ruby-lang', 'prism-parser-wasm', '0.0.1-SNAPSHOT')
require_jar('com.dylibso.chicory', 'runtime', '1.6.1')
require_jar('com.dylibso.chicory', 'wasi', '1.6.1')
require_jar('com.dylibso.chicory', 'wasm', '1.6.1')
require_jar('com.dylibso.chicory', 'log', '1.6.1')

module Prism # :nodoc:
  module WASM
    java_import org.ruby_lang.prism.wasm.Prism

    # TODO: concurrency
    PRISM = org.ruby_lang.prism.wasm.Prism.new
  end
  private_constant :WASM

  # The version constant is set by reading the result of calling pm_version.
  VERSION = WASM::PRISM.version

  class << self
    # Mirror the Prism.dump API by using the serialization API.
    def dump(source, **options)
      parsed = WASM::PRISM.parse(source.to_java_bytes, dump_options(options).to_java_bytes)
      String.from_java_bytes(parsed)
    end

    # Mirror the Prism.dump_file API by using the serialization API.
    def dump_file(filepath, **options)
      dump_file(File.read(filepath), filepath: filepath, **options)
    end

    # Mirror the Prism.lex API by using the serialization API.
    def lex(source, **options)
      lexed = WASM::PRISM.lex(source.to_java_bytes, dump_options(options).to_java_bytes)
      Serialize.load_lex(source, lexed, options.fetch(:freeze, false))
    end

    # Mirror the Prism.lex_file API by using the serialization API.
    def lex_file(filepath, **options)
      lex_file(File.read(filepath), filepath: filepath, **options)
    end

    # Mirror the Prism.parse API by using the serialization API.
    def parse(source, **options)
        serialized = dump(source, **options)
        Serialize.load_parse(source, serialized, options.fetch(:freeze, false))
    end

    # Mirror the Prism.parse_file API by using the serialization API. This uses
    # native strings instead of Ruby strings because it allows us to use mmap
    # when it is available.
    def parse_file(filepath, **options)
      parse(File.read(filepath), filepath: filepath, **options)
    end

    # Mirror the Prism.parse_stream API by using the serialization API.
    def parse_stream(stream, **options)
      LibRubyParser::PrismBuffer.with do |buffer|
        source = +""
        callback = -> (string, size, _) {
          raise "Expected size to be >= 0, got: #{size}" if size <= 0

          if !(line = stream.gets(size - 1)).nil?
            source << line
            string.write_string("#{line}\x00", line.bytesize + 1)
          end
        }

        eof_callback = -> (_) { stream.eof?  }

        # In the pm_serialize_parse_stream function it accepts a pointer to the
        # IO object as a void* and then passes it through to the callback as the
        # third argument, but it never touches it itself. As such, since we have
        # access to the IO object already through the closure of the lambda, we
        # can pass a null pointer here and not worry.
        LibRubyParser.pm_serialize_parse_stream(buffer.pointer, nil, callback, eof_callback, dump_options(options))
        Prism.load(source, buffer.read, options.fetch(:freeze, false))
      end
    end

    # Mirror the Prism.parse_comments API by using the serialization API.
    def parse_comments(code, **options)
      LibRubyParser::PrismString.with_string(code) { |string| parse_comments_common(string, code, options) }
    end

    # Mirror the Prism.parse_file_comments API by using the serialization
    # API. This uses native strings instead of Ruby strings because it allows us
    # to use mmap when it is available.
    def parse_file_comments(filepath, **options)
      options[:filepath] = filepath
      LibRubyParser::PrismString.with_file(filepath) { |string| parse_comments_common(string, string.read, options) }
    end

    # Mirror the Prism.parse_lex API by using the serialization API.
    def parse_lex(code, **options)
      LibRubyParser::PrismString.with_string(code) { |string| parse_lex_common(string, code, options) }
    end

    # Mirror the Prism.parse_lex_file API by using the serialization API.
    def parse_lex_file(filepath, **options)
      options[:filepath] = filepath
      LibRubyParser::PrismString.with_file(filepath) { |string| parse_lex_common(string, string.read, options) }
    end

    # Mirror the Prism.parse_success? API by using the serialization API.
    def parse_success?(code, **options)
      LibRubyParser::PrismString.with_string(code) { |string| parse_file_success_common(string, options) }
    end

    # Mirror the Prism.parse_failure? API by using the serialization API.
    def parse_failure?(code, **options)
      !parse_success?(code, **options)
    end

    # Mirror the Prism.parse_file_success? API by using the serialization API.
    def parse_file_success?(filepath, **options)
      options[:filepath] = filepath
      LibRubyParser::PrismString.with_file(filepath) { |string| parse_file_success_common(string, options) }
    end

    # Mirror the Prism.parse_file_failure? API by using the serialization API.
    def parse_file_failure?(filepath, **options)
      !parse_file_success?(filepath, **options)
    end

    # Mirror the Prism.profile API by using the serialization API.
    def profile(source, **options)
      LibRubyParser::PrismString.with_string(source) do |string|
        LibRubyParser::PrismBuffer.with do |buffer|
          LibRubyParser.pm_serialize_parse(buffer.pointer, string.pointer, string.length, dump_options(options))
          nil
        end
      end
    end

    # Mirror the Prism.profile_file API by using the serialization API.
    def profile_file(filepath, **options)
      LibRubyParser::PrismString.with_file(filepath) do |string|
        LibRubyParser::PrismBuffer.with do |buffer|
          options[:filepath] = filepath
          LibRubyParser.pm_serialize_parse(buffer.pointer, string.pointer, string.length, dump_options(options))
          nil
        end
      end
    end

    private

    def lex_common(string, code, options) # :nodoc:
      LibRubyParser::PrismBuffer.with do |buffer|
        LibRubyParser.pm_serialize_lex(buffer.pointer, string.pointer, string.length, dump_options(options))
        Serialize.load_lex(code, buffer.read, options.fetch(:freeze, false))
      end
    end

    def parse_common(string, code, options) # :nodoc:
      serialized = dump_common(string, options)
      Serialize.load_parse(code, serialized, options.fetch(:freeze, false))
    end

    def parse_comments_common(string, code, options) # :nodoc:
      LibRubyParser::PrismBuffer.with do |buffer|
        LibRubyParser.pm_serialize_parse_comments(buffer.pointer, string.pointer, string.length, dump_options(options))
        Serialize.load_parse_comments(code, buffer.read, options.fetch(:freeze, false))
      end
    end

    def parse_lex_common(string, code, options) # :nodoc:
      LibRubyParser::PrismBuffer.with do |buffer|
        LibRubyParser.pm_serialize_parse_lex(buffer.pointer, string.pointer, string.length, dump_options(options))
        Serialize.load_parse_lex(code, buffer.read, options.fetch(:freeze, false))
      end
    end

    def parse_file_success_common(string, options) # :nodoc:
      LibRubyParser.pm_parse_success_p(string.pointer, string.length, dump_options(options))
    end

    # Return the value that should be dumped for the command_line option.
    def dump_options_command_line(options)
      command_line = options.fetch(:command_line, "")
      raise ArgumentError, "command_line must be a string" unless command_line.is_a?(String)

      command_line.each_char.inject(0) do |value, char|
        case char
        when "a" then value | 0b000001
        when "e" then value | 0b000010
        when "l" then value | 0b000100
        when "n" then value | 0b001000
        when "p" then value | 0b010000
        when "x" then value | 0b100000
        else raise ArgumentError, "invalid command_line option: #{char}"
        end
      end
    end

    # Return the value that should be dumped for the version option.
    def dump_options_version(version)
      case version
      when "current"
        version_string_to_number(RUBY_VERSION) || raise(CurrentVersionError, RUBY_VERSION)
      when "latest", nil
        0 # Handled in pm_parser_init
      when "nearest"
        dump = version_string_to_number(RUBY_VERSION)
        return dump if dump
        if RUBY_VERSION < "3.3"
          version_string_to_number("3.3")
        else
          0 # Handled in pm_parser_init
        end
      else
        version_string_to_number(version) || raise(ArgumentError, "invalid version: #{version}")
      end
    end

    # Converts a version string like "4.0.0" or "4.0" into a number.
    # Returns nil if the version is unknown.
    def version_string_to_number(version)
      case version
      when /\A3\.3(\.\d+)?\z/
        1
      when /\A3\.4(\.\d+)?\z/
        2
      when /\A3\.5(\.\d+)?\z/, /\A4\.0(\.\d+)?\z/
        3
      when /\A4\.1(\.\d+)?\z/
        4
      end
    end

    # Convert the given options into a serialized options string.
    def dump_options(options)
      template = +""
      values = []

      template << "L"
      if (filepath = options[:filepath])
        values.push(filepath.bytesize, filepath.b)
        template << "A*"
      else
        values << 0
      end

      template << "l"
      values << options.fetch(:line, 1)

      template << "L"
      if (encoding = options[:encoding])
        name = encoding.is_a?(Encoding) ? encoding.name : encoding
        values.push(name.bytesize, name.b)
        template << "A*"
      else
        values << 0
      end

      template << "C"
      values << (options.fetch(:frozen_string_literal, false) ? 1 : 0)

      template << "C"
      values << dump_options_command_line(options)

      template << "C"
      values << dump_options_version(options[:version])

      template << "C"
      values << (options[:encoding] == false ? 1 : 0)

      template << "C"
      values << (options.fetch(:main_script, false) ? 1 : 0)

      template << "C"
      values << (options.fetch(:partial_script, false) ? 1 : 0)

      template << "C"
      values << (options.fetch(:freeze, false) ? 1 : 0)

      template << "L"
      if (scopes = options[:scopes])
        values << scopes.length

        scopes.each do |scope|
          locals = nil
          forwarding = 0

          case scope
          when Array
            locals = scope
          when Scope
            locals = scope.locals

            scope.forwarding.each do |forward|
              case forward
              when :*     then forwarding |= 0x1
              when :**    then forwarding |= 0x2
              when :&     then forwarding |= 0x4
              when :"..." then forwarding |= 0x8
              else raise ArgumentError, "invalid forwarding value: #{forward}"
              end
            end
          else
            raise TypeError, "wrong argument type #{scope.class.inspect} (expected Array or Prism::Scope)"
          end

          template << "L"
          values << locals.length

          template << "C"
          values << forwarding

          locals.each do |local|
            name = local.name
            template << "L"
            values << name.bytesize

            template << "A*"
            values << name.b
          end
        end
      else
        values << 0
      end

      values.pack(template)
    end
  end

  # Here we are going to patch StringQuery to put in the class-level methods so
  # that it can maintain a consistent interface
  class StringQuery # :nodoc:
    class << self
      # Mirrors the C extension's StringQuery::local? method.
      def local?(string)
        query(LibRubyParser.pm_string_query_local(string, string.bytesize, string.encoding.name))
      end

      # Mirrors the C extension's StringQuery::constant? method.
      def constant?(string)
        query(LibRubyParser.pm_string_query_constant(string, string.bytesize, string.encoding.name))
      end

      # Mirrors the C extension's StringQuery::method_name? method.
      def method_name?(string)
        query(LibRubyParser.pm_string_query_method_name(string, string.bytesize, string.encoding.name))
      end

      private

      # Parse the enum result and return an appropriate boolean.
      def query(result)
        case result
        when :PM_STRING_QUERY_ERROR
          raise ArgumentError, "Invalid or non ascii-compatible encoding"
        when :PM_STRING_QUERY_FALSE
          false
        when :PM_STRING_QUERY_TRUE
          true
        end
      end
    end
  end
end
