# frozen_string_literal: true

require "test_helper"

class LexTest < Test::Unit::TestCase
  test "lex ext/yarp/extconf.rb" do
    assert_lex File.expand_path("../ext/yarp/extconf.rb", __dir__)
  end

  test "lex test/fixtures/lex.rb" do
    assert_lex File.expand_path("fixtures/lex.rb", __dir__)
  end

  test "lex test/test_helper.rb" do
    assert_lex File.expand_path("test_helper.rb", __dir__)
  end

  test "lex test/yarp_test.rb" do
    assert_lex __FILE__
  end

  test "lex yarp.gemspec" do
    assert_lex File.expand_path("../yarp.gemspec", __dir__)
  end

  private

  def assert_lex(filepath)
    YARP.ripper_lex(filepath).zip(YARP.compat_lex(filepath)).each do |(ripper, yarp)|
      assert_equal ripper[0...-1], yarp[0...-1]
    end
  end
end
