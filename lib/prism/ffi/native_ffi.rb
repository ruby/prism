# frozen_string_literal: true
# :markup: markdown
# --
# typed: ignore

require "rbconfig"
require "ffi"

# We want to eagerly load this file if there are Ractors so that it does not get
# autoloaded from within a non-main Ractor.
require "prism/serialize" if defined?(Ractor)

module Prism # :nodoc:
  module LibRubyParser # :nodoc:
    extend FFI::Library

    # Define the library that we will be pulling functions from. Note that this
    # must align with the build shared library from make/rake.
    libprism_in_build = File.expand_path("../../../build/libprism.#{RbConfig::CONFIG["SOEXT"]}", __dir__)
    libprism_in_libdir = "#{RbConfig::CONFIG["libdir"]}/prism/libprism.#{RbConfig::CONFIG["SOEXT"]}"

    if File.exist?(libprism_in_build)
      INCLUDE_DIR = File.expand_path("../../../include", __dir__)
      ffi_lib libprism_in_build
    else
      INCLUDE_DIR = "#{RbConfig::CONFIG["libdir"]}/prism/include"
      ffi_lib libprism_in_libdir
    end

    # Convert a native C type declaration into a symbol that FFI understands.
    # For example:
    #
    #     const char * -> :pointer
    #     bool         -> :bool
    #     size_t       -> :size_t
    #     void         -> :void
    #
    def self.resolve_type(type, callbacks)
      type = type.strip

      if !type.end_with?("*")
        type.delete_prefix("const ").to_sym
      else
        type = type.delete_suffix("*").rstrip
        callbacks.include?(type.to_sym) ? type.to_sym : :pointer
      end
    end

    # Read through the given header file and find the declaration of each of the
    # given functions. For each one, define a function with the same name and
    # signature as the C function.
    def self.load_exported_functions_from(header, *functions, callbacks)
      File.foreach("#{INCLUDE_DIR}/#{header}") do |line|
        # We only want to attempt to load exported functions.
        next unless line.start_with?("PRISM_EXPORTED_FUNCTION ")

        # We only want to load the functions that we are interested in.
        next unless functions.any? { |function| line.include?(function) }

        # Strip trailing attributes (PRISM_NODISCARD, PRISM_NONNULL(...), etc.)
        line = line.sub(/\)(\s+PRISM_\w+(?:\([^)]*\))?)+\s*;/, ");")

        # Parse the function declaration.
        unless /^PRISM_EXPORTED_FUNCTION (?<return_type>.+) (?<name>\w+)\((?<arg_types>.+)\);$/ =~ line
          raise "Could not parse #{line}"
        end

        # Delete the function from the list of functions we are looking for to
        # mark it as having been found.
        functions.delete(name)

        # Split up the argument types into an array, ensure we handle the case
        # where there are no arguments (by explicit void).
        arg_types = arg_types.split(",").map(&:strip)
        arg_types = [] if arg_types == %w[void]

        # Resolve the type of the argument by dropping the name of the argument
        # first if it is present.
        arg_types.map! { |type| resolve_type(type.sub(/\w+$/, ""), callbacks) }

        # Attach the function using the FFI library.
        attach_function name, arg_types, resolve_type(return_type, [])
      end

      # If we didn't find all of the functions, raise an error.
      raise "Could not find functions #{functions.inspect}" unless functions.empty?
    end

    callback :pm_source_stream_fgets_t, [:pointer, :int, :pointer], :pointer
    callback :pm_source_stream_feof_t, [:pointer], :int
    pm_source_init_result_values = %i[PM_SOURCE_INIT_SUCCESS PM_SOURCE_INIT_ERROR_GENERIC PM_SOURCE_INIT_ERROR_DIRECTORY PM_SOURCE_INIT_ERROR_NON_REGULAR]
    enum :pm_source_init_result_t, pm_source_init_result_values
    enum :pm_string_query_t, [:PM_STRING_QUERY_ERROR, -1, :PM_STRING_QUERY_FALSE, :PM_STRING_QUERY_TRUE]

    # Ractor-safe lookup table for pm_source_init_result_t, since FFI's
    # enum_type accesses module instance variables that are not shareable.
    SOURCE_INIT_RESULT = pm_source_init_result_values.freeze

    load_exported_functions_from(
      "prism/version.h",
      "pm_version",
      []
    )

    load_exported_functions_from(
      "prism/serialize.h",
      "pm_serialize_parse",
      "pm_serialize_parse_stream",
      "pm_serialize_parse_comments",
      "pm_serialize_lex",
      "pm_serialize_parse_lex",
      "pm_serialize_parse_success_p",
      []
    )

    load_exported_functions_from(
      "prism/string_query.h",
      "pm_string_query_local",
      "pm_string_query_constant",
      "pm_string_query_method_name",
      []
    )

    load_exported_functions_from(
      "prism/buffer.h",
      "pm_buffer_new",
      "pm_buffer_value",
      "pm_buffer_length",
      "pm_buffer_free",
      []
    )

    load_exported_functions_from(
      "prism/source.h",
      "pm_source_file_new",
      "pm_source_mapped_new",
      "pm_source_stream_new",
      "pm_source_free",
      "pm_source_source",
      "pm_source_length",
      [:pm_source_stream_fgets_t, :pm_source_stream_feof_t]
    )

    # This object represents a pm_buffer_t. We only use it as an opaque pointer,
    # so it doesn't need to know the fields of pm_buffer_t.
    class NativeBuffer # :nodoc:
      attr_reader :pointer

      def initialize(pointer)
        @pointer = pointer
      end

      def value
        LibRubyParser.pm_buffer_value(pointer)
      end

      def length
        LibRubyParser.pm_buffer_length(pointer)
      end

      def read
        value.read_string(length)
      end

      # Initialize a new buffer and yield it to the block. The buffer will be
      # automatically freed when the block returns.
      def self.with
        buffer = LibRubyParser.pm_buffer_new
        raise unless buffer

        begin
          yield new(buffer)
        ensure
          LibRubyParser.pm_buffer_free(buffer)
        end
      end
    end

    # This object represents source code to be parsed. For strings it wraps a
    # pointer directly; for files it uses a pm_source_t under the hood.
    class NativeSource # :nodoc:
      PLATFORM_EXPECTS_UTF8 =
        RbConfig::CONFIG["host_os"].match?(/bccwin|cygwin|djgpp|mingw|mswin|wince|darwin/i)

      attr_reader :pointer, :length

      def initialize(pointer, length, from_string)
        @pointer = pointer
        @length = length
        @from_string = from_string
      end

      def read
        raise "should use the original String instead" if @from_string
        @pointer.read_string(@length)
      end

      # Yields a PrismSource backed by the given string to the block.
      def self.with_string(string)
        raise TypeError unless string.is_a?(String)

        length = string.bytesize
        # + 1 to never get an address of 0, which pm_parser_init() asserts
        FFI::MemoryPointer.new(:char, length + 1, false) do |pointer|
          pointer.write_string(string)
          # since we have the extra byte we might as well \0-terminate
          pointer.put_char(length, 0)
          return yield new(pointer, length, true)
        end
      end

      # Yields a PrismSource to the given block, backed by a pm_source_t.
      def self.with_file(filepath)
        raise TypeError unless filepath.is_a?(String)

        # On Windows and Mac, it's expected that filepaths will be encoded in
        # UTF-8. If they are not, we need to convert them to UTF-8 before
        # passing them into pm_source_mapped_new.
        if PLATFORM_EXPECTS_UTF8 && (encoding = filepath.encoding) != Encoding::ASCII_8BIT && encoding != Encoding::UTF_8
          filepath = filepath.encode(Encoding::UTF_8)
        end

        FFI::MemoryPointer.new(:int) do |result_ptr|
          pm_source = LibRubyParser.pm_source_mapped_new(filepath, 0, result_ptr)

          case SOURCE_INIT_RESULT[result_ptr.read_int]
          when :PM_SOURCE_INIT_SUCCESS
            pointer = LibRubyParser.pm_source_source(pm_source)
            length = LibRubyParser.pm_source_length(pm_source)
            return yield new(pointer, length, false)
          when :PM_SOURCE_INIT_ERROR_GENERIC
            raise SystemCallError.new(filepath, FFI.errno)
          when :PM_SOURCE_INIT_ERROR_DIRECTORY
            raise Errno::EISDIR.new(filepath)
          when :PM_SOURCE_INIT_ERROR_NON_REGULAR
            # Fall back to reading the file through Ruby IO for non-regular
            # files (pipes, character devices, etc.)
            return with_string(File.read(filepath)) { |string| yield string }
          else
            raise "Unknown error initializing pm_source_t: #{result_ptr.read_int}"
          end
        ensure
          LibRubyParser.pm_source_free(pm_source) if pm_source && !pm_source.null?
        end
      end
    end
  end

  # Mark the LibRubyParser module as private as it should only be called through
  # the prism module.
  private_constant :LibRubyParser

  class NativeCommon < Common # :nodoc:

    # The version constant is set by reading the result of calling pm_version.
    def version
      LibRubyParser.pm_version.read_string.freeze
    end

    def with_buffer(&b) # :nodoc:
      LibRubyParser::NativeBuffer.with(&b)
    end

    def with_string(string, &b) # :nodoc:
      LibRubyParser::NativeSource.with_string(string, &b)
    end

    def with_file(string, &b) # :nodoc:
      LibRubyParser::NativeSource.with_file(string, &b)
    end

    def lex_only(buffer, string, options) # :nodoc:
      LibRubyParser.pm_serialize_lex(buffer.pointer, string.pointer, string.length, dump_options(options))
    end

    def parse_only(buffer, string, options) # :nodoc:
      LibRubyParser.pm_serialize_parse(buffer.pointer, string.pointer, string.length, dump_options(options))
    end

    def parse_stream(buffer, callback, eof_callback, options, source) # :nodoc:
      pm_source = LibRubyParser.pm_source_stream_new(nil, callback, eof_callback)
      begin
        LibRubyParser.pm_serialize_parse_stream(buffer.pointer, pm_source, dump_options(options))
        Prism.load(source, buffer.read, options.fetch(:freeze, false))
      ensure
        LibRubyParser.pm_source_free(pm_source) if pm_source && !pm_source.null?
      end
    end

    def parse_comments(string, code, options) # :nodoc:
      with_buffer do |buffer|
        LibRubyParser.pm_serialize_parse_comments(buffer.pointer, string.pointer, string.length, dump_options(options))
        Serialize.load_parse_comments(code, buffer.read, options.fetch(:freeze, false))
      end
    end

    def parse_lex(string, code, options) # :nodoc:
      with_buffer do |buffer|
        LibRubyParser.pm_serialize_parse_lex(buffer.pointer, string.pointer, string.length, dump_options(options))
        Serialize.load_parse_lex(code, buffer.read, options.fetch(:freeze, false))
      end
    end

    def parse_file_success(string, options) # :nodoc:
      LibRubyParser.pm_serialize_parse_success_p(string.pointer, string.length, dump_options(options))
    end

    def string_query_method_name(string) # :nodoc:
      LibRubyParser.pm_string_query_method_name(string, string.bytesize, string.encoding.name)
    end

    def string_query_constant(string) # :nodoc:
      LibRubyParser.pm_string_query_constant(string, string.bytesize, string.encoding.name)
    end

    def string_query_local(string) # :nodoc:
      LibRubyParser.pm_string_query_local(string, string.bytesize, string.encoding.name)
    end
  end

  FFICommon = NativeCommon.new.freeze
  private_constant(:FFICommon)
end
