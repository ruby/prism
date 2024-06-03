# frozen_string_literal: true

namespace :seattlerb do
  desc "Ensure there's a local copy of seattlerb/ruby_parser"
  file "tmp/seattlerb" do
    sh "git clone --depth=1 https://github.com/seattlerb/ruby_parser tmp/seattlerb"
  end

  desc "Ensure we have a fixtures directory for the seattlerb tests"
  file "test/prism/fixtures/seattlerb" do
    mkdir_p "test/prism/fixtures/seattlerb"
  end

  desc "Import the seattlerb tests"
  task import: ["tmp/seattlerb", "test/prism/fixtures/seattlerb"] do
    require "bundler/inline"
    gemfile do
      source "https://rubygems.org"
      gem "minitest", require: "minitest/autorun"
      gem "ruby_parser"
    end

    # These files are not valid Ruby
    known_failures = %w[
      test/prism/fixtures/seattlerb/args_dstar__anon_solo.txt
      test/prism/fixtures/seattlerb/args_dstar__anon_trailing.txt
      test/prism/fixtures/seattlerb/args_star__anon_solo.txt
      test/prism/fixtures/seattlerb/args_star__anon_trailing.txt
      test/prism/fixtures/seattlerb/begin_else_return_value.txt
      test/prism/fixtures/seattlerb/block_break.txt
      test/prism/fixtures/seattlerb/block_next.txt
      test/prism/fixtures/seattlerb/block_yield.txt
      test/prism/fixtures/seattlerb/bug_begin_else.txt
      test/prism/fixtures/seattlerb/bug170.txt
      test/prism/fixtures/seattlerb/call_block_arg_unnamed.txt
      test/prism/fixtures/seattlerb/dasgn_icky2.txt
      test/prism/fixtures/seattlerb/iter_array_curly.txt
      test/prism/fixtures/seattlerb/magic_encoding_comment__bad.txt
      test/prism/fixtures/seattlerb/yield_arg.txt
      test/prism/fixtures/seattlerb/yield_call_assocs.txt
      test/prism/fixtures/seattlerb/yield_empty_parens.txt
    ]

    # Cleaning up some file names
    renames = [
      "aGVyZWRvY193dGZfSV9oYXRlX3lvdQ==\n",
      "aV9mdWNraW5nX2hhdGVf\n",
      "aV9oYXZlX25vX2ZyZWFraW5fY2x1ZQ==\n",
      "a2lsbF9tZQ==\n",
      "bW90aGVyZnVja2lu\n",
      "d3RmX2lfaGF0ZV95b3U=\n",
      "d3Rm\n",
      "em9tZ19zb21ldGltZXNfaV9oYXRlX3RoaXNfcHJvamVjdA==\n"
    ].map { _1.unpack1("m") }

    # The license is in the README
    cp "tmp/seattlerb/README.rdoc", "test/prism/fixtures/seattlerb/README.rdoc"

    require_relative "../tmp/seattlerb/test/test_ruby_parser"

    module Hook
      COLLECTED = Hash.new { |hash, key| hash[key] = [] }

      private

      def assert_parse(source, _)
        entry = caller.find { _1.include?("test_ruby_parser.rb") }
        name = entry[/\d+:in `(?:block (?:\(\d+ levels\) )?in )?(?:assert_|test_|<module:)?(.+?)\>?'/, 1]

        COLLECTED[name] << source
        super
      end
    end

    RubyParserTestCase.prepend(Hook)
    Minitest.after_run do
      Hook::COLLECTED.each do |(name, codes)|
        name = name.delete("?")

        # Clean up the names a bit
        renames.each_with_index do |rename, index|
          if name.start_with?(rename)
            name = "difficult#{index}_#{name.delete_prefix(rename)}"
            break
          end
        end

        filepath = "test/prism/fixtures/seattlerb/#{name}.txt"
        File.write(filepath, "#{codes.uniq.sort.join("\n\n")}\n")
      end

      # Remove all invalid Ruby files
      known_failures.each { rm _1 }
    end
  end

  desc "Clean up tmp files related to seattlerb"
  task :clean do
    rm_rf "tmp/seattlerb"
    rm_rf "test/prism/fixtures/seattlerb"
    rm_rf "test/prism/snapshots/seattlerb"
  end
end
