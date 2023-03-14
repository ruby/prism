# frozen_string_literal: true

require "test_helper"

class ParseTest < Test::Unit::TestCase
  include YARP::DSL

  test "empty string" do
    YARP.parse("") => YARP::ParseResult[value: YARP::ProgramNode[statements: YARP::StatementsNode[body: []]]]
  end

  test "comment inline" do
    YARP.parse("# comment") => YARP::ParseResult[comments: [YARP::Comment[type: :inline]]]
  end

  test "comment __END__" do
    source = <<~RUBY
      __END__
      comment
    RUBY

    YARP.parse(source) => YARP::ParseResult[comments: [YARP::Comment[type: :__END__]]]
  end

  test "comment embedded document" do
    source = <<~RUBY
      =begin
      comment
      =end
    RUBY

    YARP.parse(source) => YARP::ParseResult[comments: [YARP::Comment[type: :embdoc]]]
  end

  test "comment embedded document with content on same line" do
    source = <<~RUBY
      =begin other stuff
      =end
    RUBY

    YARP.parse(source) => YARP::ParseResult[comments: [YARP::Comment[type: :embdoc]]]
  end

  Dir[File.expand_path("fixtures/**/*.rb", __dir__)].each do |filepath|
    test filepath do
      assert_parses(filepath)
    end
  end

  private

  def assert_serializes(expected, source)
    YARP.load(source, YARP.dump(source)) => YARP::ProgramNode[statements: YARP::StatementsNode[body: [*, node]]]
    assert_equal expected, node
  end

  def assert_parses(filepath)
    source = File.read(filepath)
    refute_nil Ripper.sexp_raw(source)

    source_expression = expression(source)

    parsed_from_source = PP.pp(source_expression, +"")
    snapshot_filepath = File.expand_path(File.join("snapshots", File.basename(filepath)), __dir__)

    if File.exist?(snapshot_filepath)
      assert_equal File.read(snapshot_filepath), parsed_from_source
    else
      File.write(snapshot_filepath, parsed_from_source)
      warn("Created #{snapshot_filepath}")
    end

    assert_serializes source_expression, source

    YARP.lex_compat(source) => { errors: [], value: tokens }
    YARP.lex_ripper(source).zip(tokens).each do |(ripper, yarp)|
      assert_equal ripper, yarp
    end
  end

  def expression(source)
    result = YARP.parse(source)
    assert_empty result.errors, PP.pp(result.value, +"")

    result.value => YARP::ProgramNode[statements: YARP::StatementsNode[body: [*, node]]]
    node
  end

  # This method is just named this way to mirror the other DSL methods.
  def Location()
    YARP::Location.new(0, 0)
  end
end

# Here we're going to override the == method in order to avoid having to
# specifically track offsets and compare them.
YARP::Location.prepend(
  Module.new do
    def ==(other)
      true
    end
  end
)
