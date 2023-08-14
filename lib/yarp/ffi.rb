# frozen_string_literal: true

# This file is responsible for mirroring the API provided by the C extension by
# using FFI to call into the shared library.

require "rbconfig"
require "ffi"

module YARP
  BACKEND = :FFI

  module LibRubyParser
    extend FFI::Library

    class Buffer < FFI::Struct
      layout value: :pointer, length: :size_t, capacity: :size_t

      def to_ruby_string
        self[:value].read_string(self[:length])
      end
    end

    ffi_lib File.expand_path("../../build/librubyparser.#{RbConfig::CONFIG["SOEXT"]}", __dir__)

    def self.resolve_type(type)
      type = type.strip.sub(/^const /, '')
      type.end_with?('*') ? :pointer : type.to_sym
    end

    def self.load_exported_functions_from(header, functions)
      File.readlines(File.expand_path("../../include/#{header}", __dir__)).each do |line|
        if line.start_with?("YP_EXPORTED_FUNCTION ")
          if functions.any? { |function| line.include?(function) }
            /^YP_EXPORTED_FUNCTION (?<return_type>.+) (?<name>\w+)\((?<arg_types>.+)\);$/ =~ line or raise "Could not parse #{line}"

            arg_types = arg_types.split(',')
            arg_types = [] if arg_types == %w[void]
            arg_types = arg_types.map { |type| resolve_type(type.sub(/\w+$/, '')) }

            return_type = resolve_type return_type
            attach_function name, arg_types, return_type
          end
        end
      end
    end

    load_exported_functions_from("yarp.h",
      %w[yp_version yp_parse_serialize yp_lex_serialize])

    load_exported_functions_from("yarp/util/yp_buffer.h",
      %w[yp_buffer_init yp_buffer_free])

    load_exported_functions_from("yarp/util/yp_string.h",
      %w[yp_string_mapped_init yp_string_free yp_string_source yp_string_length yp_string_sizeof])

    SIZEOF_YP_STRING = yp_string_sizeof

    def self.pointer(size)
      pointer = FFI::MemoryPointer.new(size)
      begin
        yield pointer
      ensure
        pointer.free
      end
    end

    def self.yp_string(&block)
      pointer(LibRubyParser::SIZEOF_YP_STRING, &block)
    end
  end
  private_constant :LibRubyParser

  VERSION = LibRubyParser.yp_version.to_s

  def self.dump_internal(source, source_size, filepath)
    buffer = LibRubyParser::Buffer.new
    begin
      raise unless LibRubyParser.yp_buffer_init(buffer)
      metadata = nil
      if filepath
        metadata = [filepath.bytesize].pack('L') + filepath + [0].pack('L')
      end
      LibRubyParser.yp_parse_serialize(source, source_size, buffer, metadata)
      buffer.to_ruby_string
    ensure
      LibRubyParser.yp_buffer_free(buffer)
      buffer.pointer.free
    end
  end
  private_class_method :dump_internal

  def self.dump(code, filepath = nil)
    dump_internal(code, code.bytesize, filepath)
  end

  def self.dump_file(filepath)
    LibRubyParser.yp_string do |contents|
      raise unless LibRubyParser.yp_string_mapped_init(contents, filepath)
      dump_internal(LibRubyParser.yp_string_source(contents), LibRubyParser.yp_string_length(contents), filepath)
    ensure
      LibRubyParser.yp_string_free(contents)
    end
  end

  def self.lex(code, filepath = nil)
    buffer = LibRubyParser::Buffer.new
    begin
      raise unless LibRubyParser.yp_buffer_init(buffer)
      LibRubyParser.yp_lex_serialize(code, code.bytesize, filepath, buffer)
      serialized = buffer.to_ruby_string

      source = Source.new(code)
      parse_result = YARP::Serialize.load_tokens(source, serialized)

      ParseResult.new(parse_result.value, parse_result.comments, parse_result.errors, parse_result.warnings, source)
    ensure
      LibRubyParser.yp_buffer_free(buffer)
      buffer.pointer.free
    end
  end

  def self.lex_file(filepath)
    LibRubyParser.yp_string do |contents|
      raise unless LibRubyParser.yp_string_mapped_init(contents, filepath)
      # We need the Ruby String for the YARP::Source anyway, so just use that
      code_string = LibRubyParser.yp_string_source(contents).read_string(LibRubyParser.yp_string_length(contents))
      lex(code_string, filepath)
    ensure
      LibRubyParser.yp_string_free(contents)
    end
  end

  def self.parse(code, filepath = nil)
    serialized = dump(code, filepath)
    parse_result = YARP.load(code, serialized)
    source = Source.new(code)
    ParseResult.new(parse_result.value, parse_result.comments, parse_result.errors, parse_result.warnings, source)
  end

  def self.parse_file(filepath)
    LibRubyParser.yp_string do |contents|
      raise unless LibRubyParser.yp_string_mapped_init(contents, filepath)
      # We need the Ruby String for the YARP::Source anyway, so just use that
      code_string = LibRubyParser.yp_string_source(contents).read_string(LibRubyParser.yp_string_length(contents))
      parse(code_string, filepath)
    ensure
      LibRubyParser.yp_string_free(contents)
    end
  end
end
