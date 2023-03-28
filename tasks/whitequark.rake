# frozen_string_literal: true

# This file's purpose is to extract the examples from the whitequark/parser
# gem and generate a test file that we can use to ensure that our parser
# generates equivalent syntax trees when translating. To do this, it runs the
# parser's test suite but overrides the `assert_parses` method to collect the
# examples into a hash. Then, it writes out the hash to a file that we can use
# to generate our own tests.
#
# To run the test suite, it's important to note that we have to mirror both any
# APIs provided to the test suite (for example the ParseHelper module below).
# This is obviously relatively brittle, but it's effective for now.

namespace :whitequark do
  desc "Ensure there's a local copy of whitequark/parser"
  file "tmp/whitequark" do
    sh "git clone --depth=1 https://github.com/whitequark/parser tmp/whitequark"
  end

  desc "Ensure we have a fixtures directory for the whitequark/parser tests"
  file "test/fixtures/whitequark" do
    mkdir_p "test/fixtures/whitequark"
  end

  desc "Import the whitequark/parser tests"
  task import: ["tmp/whitequark", "test/fixtures/whitequark"] do
    cp "tmp/whitequark/LICENSE.txt", "test/fixtures/whitequark/LICENSE.txt"

    mkdir_p "tmp/whitequark/scratch"
    touch "tmp/whitequark/scratch/helper.rb"
    touch "tmp/whitequark/scratch/parse_helper.rb"
    $:.unshift("tmp/whitequark/scratch")

    require "ast"
    module ParseHelper
      include AST::Sexp

      # This object is going to collect all of the examples from the parser gem
      # into a hash that we can use to generate our own tests.
      COLLECTED = Hash.new { |hash, key| hash[key] = [] }
      ALL_VERSIONS = %w[3.1 3.2]

      private

      def assert_context(*)
      end
    
      def assert_diagnoses(*)
      end
    
      def assert_diagnoses_many(*)
      end
    
      def refute_diagnoses(*)
      end
    
      def with_versions(*)
      end
    
      def assert_parses(_ast, code, _source_maps = "", versions = ALL_VERSIONS)
        # We're going to skip any examples that are for older Ruby versions
        # that we do not support.
        return if (versions & %w[3.1 3.2]).empty?
    
        entry = caller.find { _1.include?("test_parser.rb") }
        _, name = *entry.match(/\d+:in `(?:block in )?(?:test_|assert_parses_)?(.+)'/)
    
        COLLECTED[name] << code
      end
    end

    require "parser/current"
    require "minitest/autorun"
    require_relative "../tmp/whitequark/test/test_parser"

    Minitest.after_run do
      ParseHelper::COLLECTED.each do |(name, codes)|
        File.write("test/fixtures/whitequark/#{name}.rb", "#{codes.sort.join("\n\n")}\n")
      end

      # We need to gsub a file because of
      # https://github.com/whitequark/parser/issues/919.
      filepath = "test/fixtures/whitequark/pattern_match.rb"
      File.write(filepath, File.read(filepath).gsub(/case foo; in \"\#{.+?}\"/, "case foo; in \"a\""))

      # These test files just straight up doesn't work.
      rm "test/fixtures/whitequark/range_endless.rb"
      rm "test/fixtures/whitequark/control_meta_escape_chars_in_regexp__since_31.rb"
    end
  end

  desc "Clean up tmp files related to whitequark/parser"
  task :clean do
    rm_rf "tmp/whitequark"
    rm_rf "test/fixtures/whitequark"
  end
end
