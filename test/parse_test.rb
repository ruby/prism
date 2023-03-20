# frozen_string_literal: true

require "test_helper"

class ParseTest < Test::Unit::TestCase
  test "Ruby 3.2+" do
    assert_operator Gem::Version.new(RUBY_VERSION), :>=, Gem::Version.new("3.2.0"), "ParseTest requires Ruby 3.2+"
  end

  test "empty string" do
    YARP.parse("") => YARP::ParseResult[value: YARP::ProgramNode[statements: YARP::StatementsNode[body: []]]]
  end

  Dir[File.expand_path("fixtures/**/*.rb", __dir__)].each do |filepath|
    test(filepath) do
      # First, read the source from the filepath and make sure that it can be
      # correctly parsed by Ripper. If it can't, then we have a fixture that is
      # invalid Ruby.
      source = File.read(filepath)
      refute_nil Ripper.sexp_raw(source)

      # Next, parse the source and print the value.
      result = YARP.parse(source)
      value = result.value
      printed = PP.pp(value, +"")

      # Next, assert that there were no errors during parsing.
      assert_empty result.errors, value

      # Next, assert that the printed value matches the snapshot.
      snapshot = File.expand_path(File.join("snapshots", File.basename(filepath)), __dir__)

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
        YARP.load(source, YARP.dump(source)),
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
