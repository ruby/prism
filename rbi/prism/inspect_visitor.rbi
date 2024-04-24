# typed: strict

class Prism::InspectVisitor < Prism::Visitor
  sig { params(String).void }
  def initialize(indent = ""); end

  sig { params(Prism::Node).returns(String) }
  def self.compose(node); end

  sig { returns(String) }
  def compose; end
end
