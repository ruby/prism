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
  class WASMCommon < Common
    java_import org.ruby_lang.prism.wasm.Prism

    # TODO: concurrency
    PRISM = org.ruby_lang.prism.wasm.Prism.new

    def version
      # The version constant is set by reading the result of calling pm_version.
      WASM::PRISM.version
    end

    # Prototype WASM code
    # def dump(source, **options)
    #   parsed = WASM::PRISM.parse(source.to_java_bytes, dump_options(options).to_java_bytes)
    # end
    #
    # # Mirror the Prism.dump_file API by using the serialization API.
    # def dump_file(filepath, **options)
    #   dump_file(File.read(filepath), filepath: filepath, **options)
    # end
    #
    # # Mirror the Prism.lex API by using the serialization API.
    # def lex(source, **options)
    #   lexed = WASM::PRISM.lex(source.to_java_bytes, dump_options(options).to_java_bytes)
    #   Serialize.load_lex(source, lexed, options.fetch(:freeze, false))
    # end
    #
    # # Mirror the Prism.lex_file API by using the serialization API.
    # def lex_file(filepath, **options)
    #   lex_file(File.read(filepath), filepath: filepath, **options)
    # end

    def with_buffer(&b)
      raise NotImplementedError
    end

    def with_string(string, &b)
      raise NotImplementedError
    end

    def with_file(string, &b)
      raise NotImplementedError
    end

    def lex_only(buffer, string, options)
      raise NotImplementedError
    end

    def parse_only(buffer, string, options)
      raise NotImplementedError
    end

    def parse_stream(buffer, callback, eof_callback, options, source)
      raise NotImplementedError
    end

    def parse_comments(string, code, options) # :nodoc:
      raise NotImplementedError
    end

    def parse_lex(string, code, options) # :nodoc:
      raise NotImplementedError
    end

    def parse_file_success(string, options) # :nodoc:
      raise NotImplementedError
    end

    def string_query_method_name(string)
      raise NotImplementedError
    end

    def string_query_constant(string)
      raise NotImplementedError
    end

    def string_query_local(string)
      raise NotImplementedError
    end
  end
end
