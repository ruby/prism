# frozen_string_literal: true

require "test_helper"

class ParseTest < Test::Unit::TestCase
  test "Ruby 3.2+" do
    assert_operator Gem::Version.new(RUBY_VERSION), :>=, Gem::Version.new("3.2.0"), "ParseTest requires Ruby 3.2+"
  end

  test "empty string" do
    YARP.parse("") => YARP::ParseResult[value: YARP::ProgramNode[statements: YARP::StatementsNode[body: []]]]
  end

  known_failures = %w[
    seattlerb/heredoc__backslash_dos_format.rb
    seattlerb/heredoc_nested.rb
    seattlerb/heredoc_trailing_slash_continued_call.rb
    seattlerb/pct_w_heredoc_interp_nested.rb
    seattlerb/required_kwarg_no_value.rb
  ]

  Dir[File.expand_path("fixtures/**/*.rb", __dir__)].each do |filepath|
    relative = filepath.delete_prefix("#{File.expand_path("fixtures", __dir__)}/")
    next if known_failures.include?(relative)

    snapshot = File.expand_path(File.join("snapshots", relative), __dir__)
    directory = File.dirname(snapshot)
    FileUtils.mkdir_p(directory) unless File.directory?(directory)

    test(filepath) do
      # First, read the source from the filepath and make sure that it can be
      # correctly parsed by Ripper. If it can't, then we have a fixture that is
      # invalid Ruby.
      source = File.read(filepath)
      refute_nil Ripper.sexp_raw(source)

      # Next, parse the source and print the value.
      result = YARP.parse_file_dup(filepath)
      value = result.value
      # This gsub removes most of the filepath in SourceFileNodes
      # which allows comparing snapshots generated from
      # different machines
      printed = PP.pp(value, +"").gsub(__dir__, "")

      # Next, assert that there were no errors during parsing.
      assert_empty result.errors, value

      if File.exist?(snapshot)
        # If the snapshot file exists, then assert that the printed value
        # matches the snapshot.
        assert_equal(File.read(snapshot), printed)
      else
        # If the snapshot file does not yet exist, then write it out now.
        File.write(snapshot, printed)
        warn("Created snapshot at #{snapshot}.")
      end

      # Next, assert that the value can be serialized and deserialized without
      # changing the shape of the tree.
      assert_equal_nodes(
        value,
        YARP.load(source, YARP.dump(source, filepath)),
        # We should be comparing the location here, but can't because of bugs.
        # We should fix this.
        compare_location: false
      )

      # Finally, assert that we can lex the source and get the same tokens as
      # Ripper.
      YARP.lex_compat(source) => { errors: [], value: tokens }
      YARP.lex_ripper(source).zip(tokens).each do |(ripper, yarp)|
        assert_equal ripper, yarp
      end
    end
  end
end
