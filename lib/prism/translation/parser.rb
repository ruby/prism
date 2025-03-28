# frozen_string_literal: true

module Prism
  module Translation
    class Parser < ParserBase # :nodoc:
      def self.inherited(subclass)
        warn(<<~MSG, uplevel: 1, category: :deprecated)
          [deprecation]: Using `Prism::Translation::Parser` is deprecated and will be \
          removed in the next major version. Use `Prism::Translation::Parser34` instead.
        MSG
        super
      end

      def initialize(builder = Prism::Translation::Parser::Builder.new, parser: Prism)
        # Filter parser frames, find first user code
        offset = caller(1..5)&.find_index do |loc|
          !loc.include?("/lib/parser/base.rb")
        end

        warn(<<~MSG, uplevel: 1 + (offset || 0), category: :deprecated)
          [deprecation]: Using `Prism::Translation::Parser` is deprecated and will be \
          removed in the next major version. Use `Prism::Translation::Parser34` instead.
        MSG
        super
      end

      def version # :nodoc:
        34
      end
    end
  end
end
