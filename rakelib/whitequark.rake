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
  file "test/prism/fixtures/whitequark" do
    mkdir_p "test/prism/fixtures/whitequark"
  end

  desc "Import the whitequark/parser tests"
  task import: ["tmp/whitequark", "test/prism/fixtures/whitequark"] do
    cp "tmp/whitequark/LICENSE.txt", "test/prism/fixtures/whitequark/LICENSE"

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
      ALL_VERSIONS = %w[3.1 3.2 3.3]

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
        return if (versions & ALL_VERSIONS).empty?

        entry = caller_locations.find { _1.base_label.start_with?("test_") }
        name = entry.base_label.delete_prefix("test_")

        COLLECTED[name] << code
      end
    end

    require "bundler/inline"
    gemfile do
      source "https://rubygems.org"
      gem "parser", require: "parser/current"
      gem "minitest", require: "minitest/autorun"
    end

    require_relative "../tmp/whitequark/test/test_parser"

    Minitest.after_run do
      ParseHelper::COLLECTED.each do |(name, codes)|
        File.write("test/prism/fixtures/whitequark/#{name}.txt", "#{codes.sort.join("\n\n")}\n")
      end

      # These files are not valid Ruby
      known_failures = %w[
        test/prism/fixtures/whitequark/args_assocs_legacy.txt
        test/prism/fixtures/whitequark/args_assocs.txt
        test/prism/fixtures/whitequark/break_block.txt
        test/prism/fixtures/whitequark/break.txt
        test/prism/fixtures/whitequark/class_definition_in_while_cond.txt
        test/prism/fixtures/whitequark/control_meta_escape_chars_in_regexp__since_31.txt
        test/prism/fixtures/whitequark/if_while_after_class__since_32.txt
        test/prism/fixtures/whitequark/next_block.txt
        test/prism/fixtures/whitequark/next.txt
        test/prism/fixtures/whitequark/pattern_matching_pin_variable.txt
        test/prism/fixtures/whitequark/pattern_matching_hash_with_string_keys.txt
        test/prism/fixtures/whitequark/range_endless.txt
        test/prism/fixtures/whitequark/redo.txt
        test/prism/fixtures/whitequark/retry.txt
        test/prism/fixtures/whitequark/yield.txt
      ]

      # Remove all invalid Ruby files
      known_failures.each { rm _1 }
    end
  end

  desc "Clean up tmp files related to whitequark/parser"
  task :clean do
    rm_rf "tmp/whitequark"
    rm_rf "test/prism/fixtures/whitequark"
    rm_rf "test/prism/snapshots/whitequark"
  end
end
