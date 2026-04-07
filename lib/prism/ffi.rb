# frozen_string_literal: true
# :markup: markdown
# --
# typed: ignore

# This file is responsible for mirroring the API provided by the C extension. There
# are two backends:
#
# * Native FFI based on the 'ffi' gem
# * WASM compiled to JVM bytecode (JRuby only)

require_relative "ffi/common"

begin
  require_relative "ffi/native_ffi.rb"
rescue LoadError
  if RUBY_ENGINE == "jruby"
    require_relative "ffi/wasm_ffi.rb"
  else
    raise
  end
end

module Prism # :nodoc:

  # The version constant is set by reading the result of calling pm_version.
  VERSION = FFICommon.version

  class << self
    # Mirror the Prism.dump API by using the serialization API.
    def dump(source, **options)
      FFICommon.with_string(source) { |string| FFICommon.dump(string, options) }
    end

    # Mirror the Prism.dump_file API by using the serialization API.
    def dump_file(filepath, **options)
      options[:filepath] = filepath
      FFICommon.with_file(filepath) { |string| FFICommon.dump(string, options) }
    end

    # Mirror the Prism.lex API by using the serialization API.
    def lex(code, **options)
      FFICommon.with_string(code) { |string| FFICommon.lex(string, code, options) }
    end

    # Mirror the Prism.lex_file API by using the serialization API.
    def lex_file(filepath, **options)
      options[:filepath] = filepath
      FFICommon.with_file(filepath) { |string| FFICommon.lex(string, string.read, options) }
    end

    # Mirror the Prism.parse API by using the serialization API.
    def parse(code, **options)
      FFICommon.with_string(code) { |string| FFICommon.parse(string, code, options) }
    end

    # Mirror the Prism.parse_file API by using the serialization API. This uses
    # native strings instead of Ruby strings because it allows us to use mmap
    # when it is available.
    def parse_file(filepath, **options)
      options[:filepath] = filepath
      FFICommon.with_file(filepath) { |string| FFICommon.parse(string, string.read, options) }
    end

    # Mirror the Prism.parse_stream API by using the serialization API.
    def parse_stream(stream, **options)
      FFICommon.with_buffer do |buffer|
        source = +""
        callback = -> (string, size, _) {
          raise "Expected size to be >= 0, got: #{size}" if size <= 0

          if !(line = stream.gets(size - 1)).nil?
            source << line
            string.write_string("#{line}\x00", line.bytesize + 1)
          end
        }

        eof_callback = -> (_) { stream.eof?  }

        FFICommon.parse_stream(buffer, callback, eof_callback, options, source)
      end
    end

    # Mirror the Prism.parse_comments API by using the serialization API.
    def parse_comments(code, **options)
      FFICommon.with_string(code) { |string| FFICommon.parse_comments(string, code, options) }
    end

    # Mirror the Prism.parse_file_comments API by using the serialization
    # API. This uses native strings instead of Ruby strings because it allows us
    # to use mmap when it is available.
    def parse_file_comments(filepath, **options)
      options[:filepath] = filepath
      FFICommon.with_file(filepath) { |string| FFICommon.parse_comments(string, string.read, options) }
    end

    # Mirror the Prism.parse_lex API by using the serialization API.
    def parse_lex(code, **options)
      FFICommon.with_string(code) { |string| FFICommon.parse_lex(string, code, options) }
    end

    # Mirror the Prism.parse_lex_file API by using the serialization API.
    def parse_lex_file(filepath, **options)
      options[:filepath] = filepath
      FFICommon.with_file(filepath) { |string| FFICommon.parse_lex(string, string.read, options) }
    end

    # Mirror the Prism.parse_success? API by using the serialization API.
    def parse_success?(code, **options)
      FFICommon.with_string(code) { |string| FFICommon.parse_file_success(string, options) }
    end

    # Mirror the Prism.parse_failure? API by using the serialization API.
    def parse_failure?(code, **options)
      !parse_success?(code, **options)
    end

    # Mirror the Prism.parse_file_success? API by using the serialization API.
    def parse_file_success?(filepath, **options)
      options[:filepath] = filepath
      FFICommon.with_file(filepath) { |string| FFICommon.parse_file_success(string, options) }
    end

    # Mirror the Prism.parse_file_failure? API by using the serialization API.
    def parse_file_failure?(filepath, **options)
      !parse_file_success?(filepath, **options)
    end

    # Mirror the Prism.profile API by using the serialization API.
    def profile(source, **options)
      FFICommon.with_string(source) do |string|
        FFICommon.with_buffer do |buffer|
          FFICommon.parse_only(buffer, string, options)
          nil
        end
      end
    end

    # Mirror the Prism.profile_file API by using the serialization API.
    def profile_file(filepath, **options)
      FFICommon.with_file(filepath) do |string|
        FFICommon.with_buffer do |buffer|
          options[:filepath] = filepath
          FFICommon.parse_only(buffer, string, options)
          nil
        end
      end
    end

  end

  # Here we are going to patch StringQuery to put in the class-level methods so
  # that it can maintain a consistent interface
  class StringQuery # :nodoc:
    class << self
      # Mirrors the C extension's StringQuery::local? method.
      def local?(string)
        query(FFICommon.string_query_local(string))
      end

      # Mirrors the C extension's StringQuery::constant? method.
      def constant?(string)
        query(FFICommon.string_query_constant(string))
      end

      # Mirrors the C extension's StringQuery::method_name? method.
      def method_name?(string)
        query(FFICommon.string_query_method_name(string))
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
