# typed: strict

# Spoom hasn't yet adopted ErrorRecoveryNode
module Prism
  class MissingNode < Node; end

  class Visitor
    sig { params(node: MissingNode).void }
    def visit_missing_node(node); end
  end
end
