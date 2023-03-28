# frozen_string_literal: true

namespace :seattlerb do
  desc "Ensure there's a local copy of seattlerb/ruby_parser"
  file "tmp/seattlerb" do
    sh "git clone --depth=1 https://github.com/seattlerb/ruby_parser tmp/seattlerb"
  end

  desc "Ensure we have a fixtures directory for the seattlerb tests"
  file "test/fixtures/seattlerb" do
    mkdir_p "test/fixtures/seattlerb"
  end

  desc "Import the seattlerb tests"
  task import: ["tmp/seattlerb", "test/fixtures/seattlerb"] do
    # The license is in the README
    cp "tmp/seattlerb/README.rdoc", "test/fixtures/seattlerb/README.rdoc"

    require_relative "../tmp/seattlerb/test/test_ruby_parser"

    module Hook
      COLLECTED = Hash.new { |hash, key| hash[key] = [] }

      private

      def assert_parse(source, _)
        entry = caller.find { _1.include?("test_ruby_parser.rb") }
        name = entry[/\d+:in `(?:block in )?(?:assert_|test_)?(.+)'/, 1]
    
        COLLECTED[name] << source
        super
      end
    end

    RubyParserTestCase.prepend(Hook)
    Minitest.after_run do
      Hook::COLLECTED.each do |(name, codes)|
        filepath = "test/fixtures/seattlerb/#{name}.rb"
        File.write(filepath, "#{codes.uniq.sort.join("\n\n")}\n")
      end

      # These files are not valid Ruby
      rm "test/fixtures/seattlerb/block_yield.rb"
      rm "test/fixtures/seattlerb/bug170.rb"
      rm "test/fixtures/seattlerb/call_block_arg_unnamed.rb"
      rm "test/fixtures/seattlerb/iter_array_curly.rb"
      rm "test/fixtures/seattlerb/magic_encoding_comment__bad.rb"
    end
  end

  desc "Clean up tmp files related to seattlerb"
  task :clean do
    rm_rf "tmp/seattlerb"
    rm_rf "test/fixtures/seattlerb"
  end
end
