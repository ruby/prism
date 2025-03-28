# typed: strict

class Prism::Translation::Parser < Prism::Translation::ParserBase
  sig { overridable.returns(Integer) }
  def version; end
end
