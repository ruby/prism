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
require_jar('org.ruby-lang', 'prism-parser-wasm', '0.0.1-SNAPSHOT')
require_jar('com.dylibso.chicory', 'runtime', '1.6.1')
require_jar('com.dylibso.chicory', 'wasi', '1.6.1')
require_jar('com.dylibso.chicory', 'wasm', '1.6.1')
require_jar('com.dylibso.chicory', 'log', '1.6.1')

module Prism # :nodoc:
  class WASMCommon < Common # :nodoc:
    java_import org.ruby_lang.prism.wasm.Prism

    # TODO: concurrency
    PRISM = org.ruby_lang.prism.wasm.Prism.new

    def version
      # The version constant is set by reading the result of calling pm_version.
      WASM::PRISM.version
    end

    def with_buffer(&b) # :nodoc:
      raise NotImplementedError
    end

    def with_string(string, &b) # :nodoc:
      raise NotImplementedError
    end

    def with_file(string, &b) # :nodoc:
      raise NotImplementedError
    end

    def lex_only(buffer, string, options) # :nodoc:
      raise NotImplementedError
    end

    def parse_only(buffer, string, options) # :nodoc:
      raise NotImplementedError
    end

    def parse_stream(buffer, callback, eof_callback, options, source) # :nodoc:
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
end
