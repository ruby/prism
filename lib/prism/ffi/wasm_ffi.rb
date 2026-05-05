# frozen_string_literal: true
# :markup: markdown
# --
# typed: ignore

require "rbconfig"
require "ffi"

# We want to eagerly load this file if there are Ractors so that it does not get
# autoloaded from within a non-main Ractor.
require "prism/serialize" if defined?(Ractor)

# Load the prism-parser-wasm jar
require 'jar-dependencies'
require_jar('org.ruby-lang', 'prism-parser-wasm-full', '0.0.4-SNAPSHOT')
chicory_version = '1.7.5'
redline_version = '0.0.4'
require_jar('com.dylibso.chicory', 'runtime', chicory_version)
require_jar('com.dylibso.chicory', 'wasi', chicory_version)
require_jar('com.dylibso.chicory', 'wasm', chicory_version)
require_jar('com.dylibso.chicory', 'log', chicory_version)
require_jar('io.roastedroot', 'redline', redline_version)

module Prism # :nodoc:
  class WASMCommon < Common # :nodoc:
    java_import org.ruby_lang.prism.wasm.full.Prism

    # TODO: concurrency
    PRISM = org.ruby_lang.prism.wasm.full.Prism.new

    def version
      # The version constant is set by reading the result of calling pm_version.
      PRISM.version
    end

    def with_buffer(&b) # :nodoc:
      buffer = PRISM.new_buffer
      begin
        b.call(buffer)
      ensure
        buffer.close
      end
    end

    class Java::org.ruby_lang.prism.wasm.full.Prism::Buffer
      def read
        String.from_java_bytes(read_bytes)
      end
    end

    def with_string(string, &b) # :nodoc:
      source = PRISM.new_source(string.to_java_bytes)
      begin
        b.call(source)
      ensure
        source.close
      end
    end

    def with_file(string, &b) # :nodoc:
      File.open(string, "rb") do |file|
        b.call(file)
      end
    end

    def lex_only(buffer, string, options) # :nodoc:
      String.from_java_bytes(PRISM.lex(buffer, string, PRISM.new_options(dump_options(options).to_java_bytes)))
    end

    def parse_only(buffer, string, options) # :nodoc:
      String.from_java_bytes(PRISM.parse(buffer, string, PRISM.new_options(dump_options(options).to_java_bytes)))
    end

    def parse_stream(buffer, callback, eof_callback, options, source) # :nodoc:
      raise NotImplementedError
    end

    def parse_comments(string, code, options) # :nodoc:
      raise NotImplementedError
    end

    def parse_lex_only(buffer, string, options) # :nodoc:
      String.from_java_bytes(PRISM.parse_lex(buffer, string, PRISM.new_options(dump_options(options).to_java_bytes)))
    end

    def parse_success(string, options) # :nodoc:
      PRISM.parse_success(string, PRISM.new_options(dump_options(options).to_java_bytes))
    end

    def string_query_method_name(string) # :nodoc:
      raise NotImplementedError
    end

    def string_query_constant(string) # :nodoc:
      raise NotImplementedError
    end

    def string_query_local(string) # :nodoc:
      raise NotImplementedError
    end
  end

  FFICommon = WASMCommon.new.freeze
  private_constant(:FFICommon)
end
