# typed: strict

# We keep these shims in here because our client libraries might not have parser
# in their bundle.
module Parser; end
class Parser::Base; end

class Prism::Translation::ParserBase < Parser::Base
  sig { overridable.returns(Integer) }
  def version; end
end
