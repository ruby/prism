# frozen_string_literal: true

require_relative "yarp/yarp"
require_relative "yarp/version"

module YARP
  # This represents a location in the source corresponding to a node or token.
  class Location
    attr_reader :start_offset, :end_offset

    def initialize(start_offset, end_offset)
      @start_offset = start_offset
      @end_offset = end_offset
    end

    def pretty_print(q)
      q.text("(#{start_offset}..#{end_offset})")
    end

    def self.null = new(0, 0)
  end

  # This represents a token from the Ruby source.
  class Token
    attr_reader :type, :value, :location

    def initialize(type, value, location)
      @type = type
      @value = value
      @location = location
    end

    def deconstruct_keys(keys)
      { type: type, value: value, location: location }
    end

    def pretty_print(q)
      q.group do
        q.text("#{type}(")
        q.nest(2) do
          q.breakable("")
          q.pp(value)
        end
        q.breakable("")
        q.text(")")
      end
    end

    def ==(other)
      other in Token[type: ^(type), value: ^(value)]
    end
  end

  # This represents a node in the tree.
  class Node
    def pretty_print(q)
      q.group do
        q.text("#{self.class.name.split("::").last}(")
        q.nest(2) do
          deconstructed = deconstruct_keys([])
          deconstructed.delete(:location)

          q.breakable("")
          q.seplist(deconstructed, lambda { q.comma_breakable }, :each_value) { |value| q.pp(value) }
        end
        q.breakable("")
        q.text(")")
      end
    end
  end

  # A class that knows how to walk down the tree. None of the individual visit
  # methods are implemented on this visitor, so it forces the consumer to
  # implement each one that they need. For a default implementation that
  # continues walking the tree, see the Visitor class.
  class BasicVisitor
    def visit(node)
      node&.accept(self)
    end

    def visit_all(nodes)
      nodes.map { |node| visit(node) }
    end

    def visit_child_nodes(node)
      visit_all(node.child_nodes)
    end
  end

  ##############################################################################
  # BEGIN TEMPLATE                                                             #
  ##############################################################################

  class Assignment < Node
    # attr_reader target: Node
    attr_reader :target

    # attr_reader operator: Token
    attr_reader :operator

    # attr_reader value: Node
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (target: Node, operator: Token, value: Node, location: Location) -> void
    def initialize(target, operator, value, location)
      @target = target
      @operator = operator
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_assignment(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [target, value]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { target: target, operator: operator, value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in Assignment[target: ^(target), operator: ^(operator), value: ^(value)]
    end
  end

  class Binary < Node
    # attr_reader left: Node
    attr_reader :left

    # attr_reader operator: Token
    attr_reader :operator

    # attr_reader right: Node
    attr_reader :right

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (left: Node, operator: Token, right: Node, location: Location) -> void
    def initialize(left, operator, right, location)
      @left = left
      @operator = operator
      @right = right
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_binary(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [left, right]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { left: left, operator: operator, right: right, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in Binary[left: ^(left), operator: ^(operator), right: ^(right)]
    end
  end

  class CharacterLiteral < Node
    # attr_reader value: Token
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (value: Token, location: Location) -> void
    def initialize(value, location)
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_character_literal(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in CharacterLiteral[value: ^(value)]
    end
  end

  class FloatLiteral < Node
    # attr_reader value: Token
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (value: Token, location: Location) -> void
    def initialize(value, location)
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_float_literal(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in FloatLiteral[value: ^(value)]
    end
  end

  class Identifier < Node
    # attr_reader value: Token
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (value: Token, location: Location) -> void
    def initialize(value, location)
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_identifier(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in Identifier[value: ^(value)]
    end
  end

  class IfModifier < Node
    # attr_reader statement: Node
    attr_reader :statement

    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader predicate: Node
    attr_reader :predicate

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (statement: Node, keyword: Token, predicate: Node, location: Location) -> void
    def initialize(statement, keyword, predicate, location)
      @statement = statement
      @keyword = keyword
      @predicate = predicate
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_if_modifier(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [statement, predicate]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { statement: statement, keyword: keyword, predicate: predicate, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in IfModifier[statement: ^(statement), keyword: ^(keyword), predicate: ^(predicate)]
    end
  end

  class ImaginaryLiteral < Node
    # attr_reader value: Token
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (value: Token, location: Location) -> void
    def initialize(value, location)
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_imaginary_literal(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in ImaginaryLiteral[value: ^(value)]
    end
  end

  class IntegerLiteral < Node
    # attr_reader value: Token
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (value: Token, location: Location) -> void
    def initialize(value, location)
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_integer_literal(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in IntegerLiteral[value: ^(value)]
    end
  end

  class OperatorAssignment < Node
    # attr_reader target: Node
    attr_reader :target

    # attr_reader operator: Token
    attr_reader :operator

    # attr_reader value: Node
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (target: Node, operator: Token, value: Node, location: Location) -> void
    def initialize(target, operator, value, location)
      @target = target
      @operator = operator
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_operator_assignment(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [target, value]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { target: target, operator: operator, value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in OperatorAssignment[target: ^(target), operator: ^(operator), value: ^(value)]
    end
  end

  class Program < Node
    # attr_reader statements: Node
    attr_reader :statements

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (statements: Node, location: Location) -> void
    def initialize(statements, location)
      @statements = statements
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_program(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [statements]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { statements: statements, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in Program[statements: ^(statements)]
    end
  end

  class RationalLiteral < Node
    # attr_reader value: Token
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (value: Token, location: Location) -> void
    def initialize(value, location)
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_rational_literal(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in RationalLiteral[value: ^(value)]
    end
  end

  class Redo < Node
    # attr_reader value: Token
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (value: Token, location: Location) -> void
    def initialize(value, location)
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_redo(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in Redo[value: ^(value)]
    end
  end

  class Retry < Node
    # attr_reader value: Token
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (value: Token, location: Location) -> void
    def initialize(value, location)
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_retry(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in Retry[value: ^(value)]
    end
  end

  class Statements < Node
    # attr_reader body: Array[Node]
    attr_reader :body

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (body: Array[Node], location: Location) -> void
    def initialize(body, location)
      @body = body
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_statements(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [*body]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { body: body, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in Statements[body: ^(body)]
    end
  end

  class Ternary < Node
    # attr_reader predicate: Node
    attr_reader :predicate

    # attr_reader question_mark: Token
    attr_reader :question_mark

    # attr_reader true_expression: Node
    attr_reader :true_expression

    # attr_reader colon: Token
    attr_reader :colon

    # attr_reader false_expression: Node
    attr_reader :false_expression

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (predicate: Node, question_mark: Token, true_expression: Node, colon: Token, false_expression: Node, location: Location) -> void
    def initialize(predicate, question_mark, true_expression, colon, false_expression, location)
      @predicate = predicate
      @question_mark = question_mark
      @true_expression = true_expression
      @colon = colon
      @false_expression = false_expression
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_ternary(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [predicate, true_expression, false_expression]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { predicate: predicate, question_mark: question_mark, true_expression: true_expression, colon: colon, false_expression: false_expression, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in Ternary[predicate: ^(predicate), question_mark: ^(question_mark), true_expression: ^(true_expression), colon: ^(colon), false_expression: ^(false_expression)]
    end
  end

  class UnlessModifier < Node
    # attr_reader statement: Node
    attr_reader :statement

    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader predicate: Node
    attr_reader :predicate

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (statement: Node, keyword: Token, predicate: Node, location: Location) -> void
    def initialize(statement, keyword, predicate, location)
      @statement = statement
      @keyword = keyword
      @predicate = predicate
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_unless_modifier(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [statement, predicate]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { statement: statement, keyword: keyword, predicate: predicate, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in UnlessModifier[statement: ^(statement), keyword: ^(keyword), predicate: ^(predicate)]
    end
  end

  class UntilModifier < Node
    # attr_reader statement: Node
    attr_reader :statement

    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader predicate: Node
    attr_reader :predicate

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (statement: Node, keyword: Token, predicate: Node, location: Location) -> void
    def initialize(statement, keyword, predicate, location)
      @statement = statement
      @keyword = keyword
      @predicate = predicate
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_until_modifier(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [statement, predicate]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { statement: statement, keyword: keyword, predicate: predicate, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in UntilModifier[statement: ^(statement), keyword: ^(keyword), predicate: ^(predicate)]
    end
  end

  class VariableReference < Node
    # attr_reader value: Token
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (value: Token, location: Location) -> void
    def initialize(value, location)
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_variable_reference(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in VariableReference[value: ^(value)]
    end
  end

  class WhileModifier < Node
    # attr_reader statement: Node
    attr_reader :statement

    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader predicate: Node
    attr_reader :predicate

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (statement: Node, keyword: Token, predicate: Node, location: Location) -> void
    def initialize(statement, keyword, predicate, location)
      @statement = statement
      @keyword = keyword
      @predicate = predicate
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_while_modifier(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [statement, predicate]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { statement: statement, keyword: keyword, predicate: predicate, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in WhileModifier[statement: ^(statement), keyword: ^(keyword), predicate: ^(predicate)]
    end
  end

  class Visitor < BasicVisitor
    # Visit a Assignment node
    alias visit_assignment visit_child_nodes

    # Visit a Binary node
    alias visit_binary visit_child_nodes

    # Visit a CharacterLiteral node
    alias visit_character_literal visit_child_nodes

    # Visit a FloatLiteral node
    alias visit_float_literal visit_child_nodes

    # Visit a Identifier node
    alias visit_identifier visit_child_nodes

    # Visit a IfModifier node
    alias visit_if_modifier visit_child_nodes

    # Visit a ImaginaryLiteral node
    alias visit_imaginary_literal visit_child_nodes

    # Visit a IntegerLiteral node
    alias visit_integer_literal visit_child_nodes

    # Visit a OperatorAssignment node
    alias visit_operator_assignment visit_child_nodes

    # Visit a Program node
    alias visit_program visit_child_nodes

    # Visit a RationalLiteral node
    alias visit_rational_literal visit_child_nodes

    # Visit a Redo node
    alias visit_redo visit_child_nodes

    # Visit a Retry node
    alias visit_retry visit_child_nodes

    # Visit a Statements node
    alias visit_statements visit_child_nodes

    # Visit a Ternary node
    alias visit_ternary visit_child_nodes

    # Visit a UnlessModifier node
    alias visit_unless_modifier visit_child_nodes

    # Visit a UntilModifier node
    alias visit_until_modifier visit_child_nodes

    # Visit a VariableReference node
    alias visit_variable_reference visit_child_nodes

    # Visit a WhileModifier node
    alias visit_while_modifier visit_child_nodes
  end

  module DSL
    private

    # Create a new Assignment node
    def Assignment(target, operator, value) = Assignment.new(target, operator, value, Location.null)

    # Create a new Binary node
    def Binary(left, operator, right) = Binary.new(left, operator, right, Location.null)

    # Create a new CharacterLiteral node
    def CharacterLiteral(value) = CharacterLiteral.new(value, Location.null)

    # Create a new FloatLiteral node
    def FloatLiteral(value) = FloatLiteral.new(value, Location.null)

    # Create a new Identifier node
    def Identifier(value) = Identifier.new(value, Location.null)

    # Create a new IfModifier node
    def IfModifier(statement, keyword, predicate) = IfModifier.new(statement, keyword, predicate, Location.null)

    # Create a new ImaginaryLiteral node
    def ImaginaryLiteral(value) = ImaginaryLiteral.new(value, Location.null)

    # Create a new IntegerLiteral node
    def IntegerLiteral(value) = IntegerLiteral.new(value, Location.null)

    # Create a new OperatorAssignment node
    def OperatorAssignment(target, operator, value) = OperatorAssignment.new(target, operator, value, Location.null)

    # Create a new Program node
    def Program(statements) = Program.new(statements, Location.null)

    # Create a new RationalLiteral node
    def RationalLiteral(value) = RationalLiteral.new(value, Location.null)

    # Create a new Redo node
    def Redo(value) = Redo.new(value, Location.null)

    # Create a new Retry node
    def Retry(value) = Retry.new(value, Location.null)

    # Create a new Statements node
    def Statements(body) = Statements.new(body, Location.null)

    # Create a new Ternary node
    def Ternary(predicate, question_mark, true_expression, colon, false_expression) = Ternary.new(predicate, question_mark, true_expression, colon, false_expression, Location.null)

    # Create a new UnlessModifier node
    def UnlessModifier(statement, keyword, predicate) = UnlessModifier.new(statement, keyword, predicate, Location.null)

    # Create a new UntilModifier node
    def UntilModifier(statement, keyword, predicate) = UntilModifier.new(statement, keyword, predicate, Location.null)

    # Create a new VariableReference node
    def VariableReference(value) = VariableReference.new(value, Location.null)

    # Create a new WhileModifier node
    def WhileModifier(statement, keyword, predicate) = WhileModifier.new(statement, keyword, predicate, Location.null)

    # Create a new EOF token
    def EOF(value) = Token.new(:EOF, value, Location.null)

    # Create a new INVALID token
    def INVALID(value) = Token.new(:INVALID, value, Location.null)

    # Create a new AMPERSAND token
    def AMPERSAND(value) = Token.new(:AMPERSAND, value, Location.null)

    # Create a new AMPERSAND_AMPERSAND token
    def AMPERSAND_AMPERSAND(value) = Token.new(:AMPERSAND_AMPERSAND, value, Location.null)

    # Create a new AMPERSAND_AMPERSAND_EQUAL token
    def AMPERSAND_AMPERSAND_EQUAL(value) = Token.new(:AMPERSAND_AMPERSAND_EQUAL, value, Location.null)

    # Create a new AMPERSAND_EQUAL token
    def AMPERSAND_EQUAL(value) = Token.new(:AMPERSAND_EQUAL, value, Location.null)

    # Create a new BACK_REFERENCE token
    def BACK_REFERENCE(value) = Token.new(:BACK_REFERENCE, value, Location.null)

    # Create a new BACKTICK token
    def BACKTICK(value) = Token.new(:BACKTICK, value, Location.null)

    # Create a new BANG token
    def BANG(value) = Token.new(:BANG, value, Location.null)

    # Create a new BANG_AT token
    def BANG_AT(value) = Token.new(:BANG_AT, value, Location.null)

    # Create a new BANG_EQUAL token
    def BANG_EQUAL(value) = Token.new(:BANG_EQUAL, value, Location.null)

    # Create a new BANG_TILDE token
    def BANG_TILDE(value) = Token.new(:BANG_TILDE, value, Location.null)

    # Create a new BRACE_LEFT token
    def BRACE_LEFT(value) = Token.new(:BRACE_LEFT, value, Location.null)

    # Create a new BRACE_RIGHT token
    def BRACE_RIGHT(value) = Token.new(:BRACE_RIGHT, value, Location.null)

    # Create a new BRACKET_LEFT token
    def BRACKET_LEFT(value) = Token.new(:BRACKET_LEFT, value, Location.null)

    # Create a new BRACKET_LEFT_RIGHT token
    def BRACKET_LEFT_RIGHT(value) = Token.new(:BRACKET_LEFT_RIGHT, value, Location.null)

    # Create a new BRACKET_RIGHT token
    def BRACKET_RIGHT(value) = Token.new(:BRACKET_RIGHT, value, Location.null)

    # Create a new CARET token
    def CARET(value) = Token.new(:CARET, value, Location.null)

    # Create a new CARET_EQUAL token
    def CARET_EQUAL(value) = Token.new(:CARET_EQUAL, value, Location.null)

    # Create a new CHARACTER_LITERAL token
    def CHARACTER_LITERAL(value) = Token.new(:CHARACTER_LITERAL, value, Location.null)

    # Create a new CLASS_VARIABLE token
    def CLASS_VARIABLE(value) = Token.new(:CLASS_VARIABLE, value, Location.null)

    # Create a new COLON token
    def COLON(value) = Token.new(:COLON, value, Location.null)

    # Create a new COLON_COLON token
    def COLON_COLON(value) = Token.new(:COLON_COLON, value, Location.null)

    # Create a new COMMA token
    def COMMA(value) = Token.new(:COMMA, value, Location.null)

    # Create a new COMMENT token
    def COMMENT(value) = Token.new(:COMMENT, value, Location.null)

    # Create a new CONSTANT token
    def CONSTANT(value) = Token.new(:CONSTANT, value, Location.null)

    # Create a new DOT token
    def DOT(value) = Token.new(:DOT, value, Location.null)

    # Create a new DOT_DOT token
    def DOT_DOT(value) = Token.new(:DOT_DOT, value, Location.null)

    # Create a new DOT_DOT_DOT token
    def DOT_DOT_DOT(value) = Token.new(:DOT_DOT_DOT, value, Location.null)

    # Create a new EMBDOC_BEGIN token
    def EMBDOC_BEGIN(value) = Token.new(:EMBDOC_BEGIN, value, Location.null)

    # Create a new EMBDOC_END token
    def EMBDOC_END(value) = Token.new(:EMBDOC_END, value, Location.null)

    # Create a new EMBDOC_LINE token
    def EMBDOC_LINE(value) = Token.new(:EMBDOC_LINE, value, Location.null)

    # Create a new EMBEXPR_BEGIN token
    def EMBEXPR_BEGIN(value) = Token.new(:EMBEXPR_BEGIN, value, Location.null)

    # Create a new EMBEXPR_END token
    def EMBEXPR_END(value) = Token.new(:EMBEXPR_END, value, Location.null)

    # Create a new EQUAL token
    def EQUAL(value) = Token.new(:EQUAL, value, Location.null)

    # Create a new EQUAL_EQUAL token
    def EQUAL_EQUAL(value) = Token.new(:EQUAL_EQUAL, value, Location.null)

    # Create a new EQUAL_EQUAL_EQUAL token
    def EQUAL_EQUAL_EQUAL(value) = Token.new(:EQUAL_EQUAL_EQUAL, value, Location.null)

    # Create a new EQUAL_GREATER token
    def EQUAL_GREATER(value) = Token.new(:EQUAL_GREATER, value, Location.null)

    # Create a new EQUAL_TILDE token
    def EQUAL_TILDE(value) = Token.new(:EQUAL_TILDE, value, Location.null)

    # Create a new FLOAT token
    def FLOAT(value) = Token.new(:FLOAT, value, Location.null)

    # Create a new GREATER token
    def GREATER(value) = Token.new(:GREATER, value, Location.null)

    # Create a new GREATER_EQUAL token
    def GREATER_EQUAL(value) = Token.new(:GREATER_EQUAL, value, Location.null)

    # Create a new GREATER_GREATER token
    def GREATER_GREATER(value) = Token.new(:GREATER_GREATER, value, Location.null)

    # Create a new GREATER_GREATER_EQUAL token
    def GREATER_GREATER_EQUAL(value) = Token.new(:GREATER_GREATER_EQUAL, value, Location.null)

    # Create a new GLOBAL_VARIABLE token
    def GLOBAL_VARIABLE(value) = Token.new(:GLOBAL_VARIABLE, value, Location.null)

    # Create a new IDENTIFIER token
    def IDENTIFIER(value) = Token.new(:IDENTIFIER, value, Location.null)

    # Create a new IMAGINARY_NUMBER token
    def IMAGINARY_NUMBER(value) = Token.new(:IMAGINARY_NUMBER, value, Location.null)

    # Create a new INSTANCE_VARIABLE token
    def INSTANCE_VARIABLE(value) = Token.new(:INSTANCE_VARIABLE, value, Location.null)

    # Create a new INTEGER token
    def INTEGER(value) = Token.new(:INTEGER, value, Location.null)

    # Create a new KEYWORD___ENCODING__ token
    def KEYWORD___ENCODING__(value) = Token.new(:KEYWORD___ENCODING__, value, Location.null)

    # Create a new KEYWORD___LINE__ token
    def KEYWORD___LINE__(value) = Token.new(:KEYWORD___LINE__, value, Location.null)

    # Create a new KEYWORD___FILE__ token
    def KEYWORD___FILE__(value) = Token.new(:KEYWORD___FILE__, value, Location.null)

    # Create a new KEYWORD_ALIAS token
    def KEYWORD_ALIAS(value) = Token.new(:KEYWORD_ALIAS, value, Location.null)

    # Create a new KEYWORD_AND token
    def KEYWORD_AND(value) = Token.new(:KEYWORD_AND, value, Location.null)

    # Create a new KEYWORD_BEGIN token
    def KEYWORD_BEGIN(value) = Token.new(:KEYWORD_BEGIN, value, Location.null)

    # Create a new KEYWORD_BEGIN_UPCASE token
    def KEYWORD_BEGIN_UPCASE(value) = Token.new(:KEYWORD_BEGIN_UPCASE, value, Location.null)

    # Create a new KEYWORD_BREAK token
    def KEYWORD_BREAK(value) = Token.new(:KEYWORD_BREAK, value, Location.null)

    # Create a new KEYWORD_CASE token
    def KEYWORD_CASE(value) = Token.new(:KEYWORD_CASE, value, Location.null)

    # Create a new KEYWORD_CLASS token
    def KEYWORD_CLASS(value) = Token.new(:KEYWORD_CLASS, value, Location.null)

    # Create a new KEYWORD_DEF token
    def KEYWORD_DEF(value) = Token.new(:KEYWORD_DEF, value, Location.null)

    # Create a new KEYWORD_DEFINED token
    def KEYWORD_DEFINED(value) = Token.new(:KEYWORD_DEFINED, value, Location.null)

    # Create a new KEYWORD_DO token
    def KEYWORD_DO(value) = Token.new(:KEYWORD_DO, value, Location.null)

    # Create a new KEYWORD_ELSE token
    def KEYWORD_ELSE(value) = Token.new(:KEYWORD_ELSE, value, Location.null)

    # Create a new KEYWORD_ELSIF token
    def KEYWORD_ELSIF(value) = Token.new(:KEYWORD_ELSIF, value, Location.null)

    # Create a new KEYWORD_END token
    def KEYWORD_END(value) = Token.new(:KEYWORD_END, value, Location.null)

    # Create a new KEYWORD_END_UPCASE token
    def KEYWORD_END_UPCASE(value) = Token.new(:KEYWORD_END_UPCASE, value, Location.null)

    # Create a new KEYWORD_ENSURE token
    def KEYWORD_ENSURE(value) = Token.new(:KEYWORD_ENSURE, value, Location.null)

    # Create a new KEYWORD_FALSE token
    def KEYWORD_FALSE(value) = Token.new(:KEYWORD_FALSE, value, Location.null)

    # Create a new KEYWORD_FOR token
    def KEYWORD_FOR(value) = Token.new(:KEYWORD_FOR, value, Location.null)

    # Create a new KEYWORD_IF token
    def KEYWORD_IF(value) = Token.new(:KEYWORD_IF, value, Location.null)

    # Create a new KEYWORD_IN token
    def KEYWORD_IN(value) = Token.new(:KEYWORD_IN, value, Location.null)

    # Create a new KEYWORD_MODULE token
    def KEYWORD_MODULE(value) = Token.new(:KEYWORD_MODULE, value, Location.null)

    # Create a new KEYWORD_NEXT token
    def KEYWORD_NEXT(value) = Token.new(:KEYWORD_NEXT, value, Location.null)

    # Create a new KEYWORD_NIL token
    def KEYWORD_NIL(value) = Token.new(:KEYWORD_NIL, value, Location.null)

    # Create a new KEYWORD_NOT token
    def KEYWORD_NOT(value) = Token.new(:KEYWORD_NOT, value, Location.null)

    # Create a new KEYWORD_OR token
    def KEYWORD_OR(value) = Token.new(:KEYWORD_OR, value, Location.null)

    # Create a new KEYWORD_REDO token
    def KEYWORD_REDO(value) = Token.new(:KEYWORD_REDO, value, Location.null)

    # Create a new KEYWORD_RESCUE token
    def KEYWORD_RESCUE(value) = Token.new(:KEYWORD_RESCUE, value, Location.null)

    # Create a new KEYWORD_RETRY token
    def KEYWORD_RETRY(value) = Token.new(:KEYWORD_RETRY, value, Location.null)

    # Create a new KEYWORD_RETURN token
    def KEYWORD_RETURN(value) = Token.new(:KEYWORD_RETURN, value, Location.null)

    # Create a new KEYWORD_SELF token
    def KEYWORD_SELF(value) = Token.new(:KEYWORD_SELF, value, Location.null)

    # Create a new KEYWORD_SUPER token
    def KEYWORD_SUPER(value) = Token.new(:KEYWORD_SUPER, value, Location.null)

    # Create a new KEYWORD_THEN token
    def KEYWORD_THEN(value) = Token.new(:KEYWORD_THEN, value, Location.null)

    # Create a new KEYWORD_TRUE token
    def KEYWORD_TRUE(value) = Token.new(:KEYWORD_TRUE, value, Location.null)

    # Create a new KEYWORD_UNDEF token
    def KEYWORD_UNDEF(value) = Token.new(:KEYWORD_UNDEF, value, Location.null)

    # Create a new KEYWORD_UNLESS token
    def KEYWORD_UNLESS(value) = Token.new(:KEYWORD_UNLESS, value, Location.null)

    # Create a new KEYWORD_UNTIL token
    def KEYWORD_UNTIL(value) = Token.new(:KEYWORD_UNTIL, value, Location.null)

    # Create a new KEYWORD_WHEN token
    def KEYWORD_WHEN(value) = Token.new(:KEYWORD_WHEN, value, Location.null)

    # Create a new KEYWORD_WHILE token
    def KEYWORD_WHILE(value) = Token.new(:KEYWORD_WHILE, value, Location.null)

    # Create a new KEYWORD_YIELD token
    def KEYWORD_YIELD(value) = Token.new(:KEYWORD_YIELD, value, Location.null)

    # Create a new LABEL token
    def LABEL(value) = Token.new(:LABEL, value, Location.null)

    # Create a new LAMBDA_BEGIN token
    def LAMBDA_BEGIN(value) = Token.new(:LAMBDA_BEGIN, value, Location.null)

    # Create a new LESS token
    def LESS(value) = Token.new(:LESS, value, Location.null)

    # Create a new LESS_EQUAL token
    def LESS_EQUAL(value) = Token.new(:LESS_EQUAL, value, Location.null)

    # Create a new LESS_EQUAL_GREATER token
    def LESS_EQUAL_GREATER(value) = Token.new(:LESS_EQUAL_GREATER, value, Location.null)

    # Create a new LESS_LESS token
    def LESS_LESS(value) = Token.new(:LESS_LESS, value, Location.null)

    # Create a new LESS_LESS_EQUAL token
    def LESS_LESS_EQUAL(value) = Token.new(:LESS_LESS_EQUAL, value, Location.null)

    # Create a new MINUS token
    def MINUS(value) = Token.new(:MINUS, value, Location.null)

    # Create a new MINUS_AT token
    def MINUS_AT(value) = Token.new(:MINUS_AT, value, Location.null)

    # Create a new MINUS_EQUAL token
    def MINUS_EQUAL(value) = Token.new(:MINUS_EQUAL, value, Location.null)

    # Create a new MINUS_GREATER token
    def MINUS_GREATER(value) = Token.new(:MINUS_GREATER, value, Location.null)

    # Create a new NEWLINE token
    def NEWLINE(value) = Token.new(:NEWLINE, value, Location.null)

    # Create a new NTH_REFERENCE token
    def NTH_REFERENCE(value) = Token.new(:NTH_REFERENCE, value, Location.null)

    # Create a new PARENTHESIS_LEFT token
    def PARENTHESIS_LEFT(value) = Token.new(:PARENTHESIS_LEFT, value, Location.null)

    # Create a new PARENTHESIS_RIGHT token
    def PARENTHESIS_RIGHT(value) = Token.new(:PARENTHESIS_RIGHT, value, Location.null)

    # Create a new PERCENT token
    def PERCENT(value) = Token.new(:PERCENT, value, Location.null)

    # Create a new PERCENT_EQUAL token
    def PERCENT_EQUAL(value) = Token.new(:PERCENT_EQUAL, value, Location.null)

    # Create a new PERCENT_LOWER_I token
    def PERCENT_LOWER_I(value) = Token.new(:PERCENT_LOWER_I, value, Location.null)

    # Create a new PERCENT_LOWER_W token
    def PERCENT_LOWER_W(value) = Token.new(:PERCENT_LOWER_W, value, Location.null)

    # Create a new PERCENT_LOWER_X token
    def PERCENT_LOWER_X(value) = Token.new(:PERCENT_LOWER_X, value, Location.null)

    # Create a new PERCENT_UPPER_I token
    def PERCENT_UPPER_I(value) = Token.new(:PERCENT_UPPER_I, value, Location.null)

    # Create a new PERCENT_UPPER_W token
    def PERCENT_UPPER_W(value) = Token.new(:PERCENT_UPPER_W, value, Location.null)

    # Create a new PIPE token
    def PIPE(value) = Token.new(:PIPE, value, Location.null)

    # Create a new PIPE_EQUAL token
    def PIPE_EQUAL(value) = Token.new(:PIPE_EQUAL, value, Location.null)

    # Create a new PIPE_PIPE token
    def PIPE_PIPE(value) = Token.new(:PIPE_PIPE, value, Location.null)

    # Create a new PIPE_PIPE_EQUAL token
    def PIPE_PIPE_EQUAL(value) = Token.new(:PIPE_PIPE_EQUAL, value, Location.null)

    # Create a new PLUS token
    def PLUS(value) = Token.new(:PLUS, value, Location.null)

    # Create a new PLUS_AT token
    def PLUS_AT(value) = Token.new(:PLUS_AT, value, Location.null)

    # Create a new PLUS_EQUAL token
    def PLUS_EQUAL(value) = Token.new(:PLUS_EQUAL, value, Location.null)

    # Create a new QUESTION_MARK token
    def QUESTION_MARK(value) = Token.new(:QUESTION_MARK, value, Location.null)

    # Create a new RATIONAL_NUMBER token
    def RATIONAL_NUMBER(value) = Token.new(:RATIONAL_NUMBER, value, Location.null)

    # Create a new REGEXP_BEGIN token
    def REGEXP_BEGIN(value) = Token.new(:REGEXP_BEGIN, value, Location.null)

    # Create a new REGEXP_END token
    def REGEXP_END(value) = Token.new(:REGEXP_END, value, Location.null)

    # Create a new SEMICOLON token
    def SEMICOLON(value) = Token.new(:SEMICOLON, value, Location.null)

    # Create a new SLASH token
    def SLASH(value) = Token.new(:SLASH, value, Location.null)

    # Create a new SLASH_EQUAL token
    def SLASH_EQUAL(value) = Token.new(:SLASH_EQUAL, value, Location.null)

    # Create a new STAR token
    def STAR(value) = Token.new(:STAR, value, Location.null)

    # Create a new STAR_EQUAL token
    def STAR_EQUAL(value) = Token.new(:STAR_EQUAL, value, Location.null)

    # Create a new STAR_STAR token
    def STAR_STAR(value) = Token.new(:STAR_STAR, value, Location.null)

    # Create a new STAR_STAR_EQUAL token
    def STAR_STAR_EQUAL(value) = Token.new(:STAR_STAR_EQUAL, value, Location.null)

    # Create a new STRING_BEGIN token
    def STRING_BEGIN(value) = Token.new(:STRING_BEGIN, value, Location.null)

    # Create a new STRING_CONTENT token
    def STRING_CONTENT(value) = Token.new(:STRING_CONTENT, value, Location.null)

    # Create a new STRING_END token
    def STRING_END(value) = Token.new(:STRING_END, value, Location.null)

    # Create a new SYMBOL_BEGIN token
    def SYMBOL_BEGIN(value) = Token.new(:SYMBOL_BEGIN, value, Location.null)

    # Create a new TILDE token
    def TILDE(value) = Token.new(:TILDE, value, Location.null)

    # Create a new TILDE_AT token
    def TILDE_AT(value) = Token.new(:TILDE_AT, value, Location.null)

    # Create a new WORDS_SEP token
    def WORDS_SEP(value) = Token.new(:WORDS_SEP, value, Location.null)
  end

  ##############################################################################
  # END TEMPLATE                                                               #
  ##############################################################################

  # This lexes with the Ripper lex. It drops any space events and normalizes all
  # ignored newlines into regular newlines.
  def self.lex_ripper(filepath)
    Ripper.lex(File.read(filepath)).each_with_object([]) do |token, tokens|
      case token[1]
      when :on_ignored_nl
        tokens << [token[0], :on_nl, token[2], token[3]]
      when :on_sp
        # skip
      else
        tokens << token
      end
    end
  end

  # Returns an array of tokens that closely resembles that of the Ripper lexer.
  # The only difference is that since we don't keep track of lexer state in the
  # same way, it's going to always return the NONE state.
  def self.lex_compat(filepath)
    offsets = [0]
    File.foreach(filepath) { |line| offsets << offsets.last + line.bytesize }

    lexer_state = Ripper::Lexer::State.new(0)
    tokens = []

    lex_file(filepath).each do |token|
      line_number, line_offset =
        offsets.each_with_index.detect do |(offset, line)|
          break [line, offsets[line - 1]] if token.location.start_offset < offset
        end

      line_number ||= offsets.length + 1
      line_offset ||= offsets.last

      line_byte = token.location.start_offset - line_offset
      event = RIPPER.fetch(token.type)

      value = token.value
      unescaped =
        if %i[on_comment on_tstring_content].include?(event) && value.include?("\\")
          # Ripper unescapes string content and comments, so we need to do the
          # same here.
          value.force_encoding("UTF-8").unicode_normalize
        else
          value
        end

      tokens << [[line_number, line_byte], event, unescaped, lexer_state]
    end

    tokens
  end

  RIPPER = {
    AMPERSAND: :on_op,
    AMPERSAND_AMPERSAND: :on_op,
    AMPERSAND_AMPERSAND_EQUAL: :on_op,
    AMPERSAND_EQUAL: :on_op,
    BACK_REFERENCE: :on_backref,
    BACKTICK: :on_backtick,
    BANG: :on_op,
    BANG_AT: :on_op,
    BANG_EQUAL: :on_op,
    BANG_TILDE: :on_op,
    BRACE_LEFT: :on_lbrace,
    BRACE_RIGHT: :on_rbrace,
    BRACKET_LEFT: :on_lbracket,
    BRACKET_LEFT_RIGHT: :on_op,
    BRACKET_RIGHT: :on_rbracket,
    CARET: :on_op,
    CARET_EQUAL: :on_op,
    CHARACTER_LITERAL: :on_CHAR,
    CLASS_VARIABLE: :on_cvar,
    COLON: :on_op,
    COLON_COLON: :on_op,
    COMMA: :on_comma,
    COMMENT: :on_comment,
    CONSTANT: :on_const,
    DOT: :on_period,
    DOT_DOT: :on_op,
    DOT_DOT_DOT: :on_op,
    EMBDOC_BEGIN: :on_embdoc_beg,
    EMBDOC_END: :on_embdoc_end,
    EMBDOC_LINE: :on_embdoc,
    EMBEXPR_BEGIN: :on_embexpr_beg,
    EMBEXPR_END: :on_embexpr_end,
    EQUAL: :on_op,
    EQUAL_EQUAL: :on_op,
    EQUAL_EQUAL_EQUAL: :on_op,
    EQUAL_GREATER: :on_op,
    EQUAL_TILDE: :on_op,
    FLOAT: :on_float,
    GREATER: :on_op,
    GREATER_EQUAL: :on_op,
    GREATER_GREATER: :on_op,
    GREATER_GREATER_EQUAL: :on_op,
    GLOBAL_VARIABLE: :on_gvar,
    IDENTIFIER: :on_ident,
    IMAGINARY_NUMBER: :on_imaginary,
    INTEGER: :on_int,
    INSTANCE_VARIABLE: :on_ivar,
    INVALID: :INVALID,
    KEYWORD___ENCODING__: :on_kw,
    KEYWORD___LINE__: :on_kw,
    KEYWORD___FILE__: :on_kw,
    KEYWORD_ALIAS: :on_kw,
    KEYWORD_AND: :on_kw,
    KEYWORD_BEGIN: :on_kw,
    KEYWORD_BEGIN_UPCASE: :on_kw,
    KEYWORD_BREAK: :on_kw,
    KEYWORD_CASE: :on_kw,
    KEYWORD_CLASS: :on_kw,
    KEYWORD_DEF: :on_kw,
    KEYWORD_DEFINED: :on_kw,
    KEYWORD_DO: :on_kw,
    KEYWORD_ELSE: :on_kw,
    KEYWORD_ELSIF: :on_kw,
    KEYWORD_END: :on_kw,
    KEYWORD_END_UPCASE: :on_kw,
    KEYWORD_ENSURE: :on_kw,
    KEYWORD_FALSE: :on_kw,
    KEYWORD_FOR: :on_kw,
    KEYWORD_IF: :on_kw,
    KEYWORD_IN: :on_kw,
    KEYWORD_MODULE: :on_kw,
    KEYWORD_NEXT: :on_kw,
    KEYWORD_NIL: :on_kw,
    KEYWORD_NOT: :on_kw,
    KEYWORD_OR: :on_kw,
    KEYWORD_REDO: :on_kw,
    KEYWORD_RESCUE: :on_kw,
    KEYWORD_RETRY: :on_kw,
    KEYWORD_RETURN: :on_kw,
    KEYWORD_SELF: :on_kw,
    KEYWORD_SUPER: :on_kw,
    KEYWORD_THEN: :on_kw,
    KEYWORD_TRUE: :on_kw,
    KEYWORD_UNDEF: :on_kw,
    KEYWORD_UNLESS: :on_kw,
    KEYWORD_UNTIL: :on_kw,
    KEYWORD_WHEN: :on_kw,
    KEYWORD_WHILE: :on_kw,
    KEYWORD_YIELD: :on_kw,
    LABEL: :on_label,
    LAMBDA_BEGIN: :on_tlambeg,
    LESS: :on_op,
    LESS_EQUAL: :on_op,
    LESS_EQUAL_GREATER: :on_op,
    LESS_LESS: :on_op,
    LESS_LESS_EQUAL: :on_op,
    MINUS: :on_op,
    MINUS_AT: :on_op,
    MINUS_EQUAL: :on_op,
    MINUS_GREATER: :on_tlambda,
    NEWLINE: :on_nl,
    NTH_REFERENCE: :on_backref,
    PARENTHESIS_LEFT: :on_lparen,
    PARENTHESIS_RIGHT: :on_rparen,
    PERCENT: :on_op,
    PERCENT_EQUAL: :on_op,
    PERCENT_LOWER_I: :on_qsymbols_beg,
    PERCENT_LOWER_W: :on_qwords_beg,
    PERCENT_LOWER_X: :on_backtick,
    PERCENT_UPPER_I: :on_symbols_beg,
    PERCENT_UPPER_W: :on_words_beg,
    PIPE: :on_op,
    PIPE_EQUAL: :on_op,
    PIPE_PIPE: :on_op,
    PIPE_PIPE_EQUAL: :on_op,
    PLUS: :on_op,
    PLUS_AT: :on_op,
    PLUS_EQUAL: :on_op,
    QUESTION_MARK: :on_op,
    RATIONAL_NUMBER: :on_rational,
    REGEXP_BEGIN: :on_regexp_beg,
    REGEXP_END: :on_regexp_end,
    SEMICOLON: :on_semicolon,
    SLASH: :on_op,
    SLASH_EQUAL: :on_op,
    STAR: :on_op,
    STAR_EQUAL: :on_op,
    STAR_STAR: :on_op,
    STAR_STAR_EQUAL: :on_op,
    STRING_BEGIN: :on_tstring_beg,
    STRING_CONTENT: :on_tstring_content,
    STRING_END: :on_tstring_end,
    SYMBOL_BEGIN: :on_symbeg,
    TILDE: :on_op,
    TILDE_AT: :on_op,
    WORDS_SEP: :on_words_sep,
  }.freeze

  private_constant :RIPPER
end
