# frozen_string_literal: true

require_relative "yarp/yarp"
require_relative "yarp/serialization"
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

    def self.null
      new(0, 0)
    end
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

  class CallNode < Node
    # attr_reader message: Token
    attr_reader :message

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (message: Token, location: Location) -> void
    def initialize(message, location)
      @message = message
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_call_node(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { message: message, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in CallNode[message: ^(message)]
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

  class ClassVariableRead < Node
    # attr_reader name: Token
    attr_reader :name

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (name: Token, location: Location) -> void
    def initialize(name, location)
      @name = name
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_class_variable_read(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { name: name, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in ClassVariableRead[name: ^(name)]
    end
  end

  class ClassVariableWrite < Node
    # attr_reader name: Token
    attr_reader :name

    # attr_reader operator: Token
    attr_reader :operator

    # attr_reader value: Node
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (name: Token, operator: Token, value: Node, location: Location) -> void
    def initialize(name, operator, value, location)
      @name = name
      @operator = operator
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_class_variable_write(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [value]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { name: name, operator: operator, value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in ClassVariableWrite[name: ^(name), operator: ^(operator), value: ^(value)]
    end
  end

  class FalseNode < Node
    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (keyword: Token, location: Location) -> void
    def initialize(keyword, location)
      @keyword = keyword
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_false_node(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { keyword: keyword, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in FalseNode[keyword: ^(keyword)]
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

  class GlobalVariableRead < Node
    # attr_reader name: Token
    attr_reader :name

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (name: Token, location: Location) -> void
    def initialize(name, location)
      @name = name
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_global_variable_read(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { name: name, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in GlobalVariableRead[name: ^(name)]
    end
  end

  class GlobalVariableWrite < Node
    # attr_reader name: Token
    attr_reader :name

    # attr_reader operator: Token
    attr_reader :operator

    # attr_reader value: Node
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (name: Token, operator: Token, value: Node, location: Location) -> void
    def initialize(name, operator, value, location)
      @name = name
      @operator = operator
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_global_variable_write(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [value]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { name: name, operator: operator, value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in GlobalVariableWrite[name: ^(name), operator: ^(operator), value: ^(value)]
    end
  end

  class IfNode < Node
    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader predicate: Node
    attr_reader :predicate

    # attr_reader statements: Node
    attr_reader :statements

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (keyword: Token, predicate: Node, statements: Node, location: Location) -> void
    def initialize(keyword, predicate, statements, location)
      @keyword = keyword
      @predicate = predicate
      @statements = statements
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_if_node(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [predicate, statements]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { keyword: keyword, predicate: predicate, statements: statements, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in IfNode[keyword: ^(keyword), predicate: ^(predicate), statements: ^(statements)]
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

  class InstanceVariableRead < Node
    # attr_reader name: Token
    attr_reader :name

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (name: Token, location: Location) -> void
    def initialize(name, location)
      @name = name
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_instance_variable_read(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { name: name, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in InstanceVariableRead[name: ^(name)]
    end
  end

  class InstanceVariableWrite < Node
    # attr_reader name: Token
    attr_reader :name

    # attr_reader operator: Token
    attr_reader :operator

    # attr_reader value: Node
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (name: Token, operator: Token, value: Node, location: Location) -> void
    def initialize(name, operator, value, location)
      @name = name
      @operator = operator
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_instance_variable_write(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [value]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { name: name, operator: operator, value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in InstanceVariableWrite[name: ^(name), operator: ^(operator), value: ^(value)]
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

  class LocalVariableRead < Node
    # attr_reader name: Token
    attr_reader :name

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (name: Token, location: Location) -> void
    def initialize(name, location)
      @name = name
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_local_variable_read(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { name: name, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in LocalVariableRead[name: ^(name)]
    end
  end

  class LocalVariableWrite < Node
    # attr_reader name: Token
    attr_reader :name

    # attr_reader operator: Token
    attr_reader :operator

    # attr_reader value: Node
    attr_reader :value

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (name: Token, operator: Token, value: Node, location: Location) -> void
    def initialize(name, operator, value, location)
      @name = name
      @operator = operator
      @value = value
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_local_variable_write(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [value]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { name: name, operator: operator, value: value, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in LocalVariableWrite[name: ^(name), operator: ^(operator), value: ^(value)]
    end
  end

  class NilNode < Node
    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (keyword: Token, location: Location) -> void
    def initialize(keyword, location)
      @keyword = keyword
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_nil_node(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { keyword: keyword, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in NilNode[keyword: ^(keyword)]
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
    # attr_reader scope: Node
    attr_reader :scope

    # attr_reader statements: Node
    attr_reader :statements

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (scope: Node, statements: Node, location: Location) -> void
    def initialize(scope, statements, location)
      @scope = scope
      @statements = statements
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_program(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [scope, statements]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { scope: scope, statements: statements, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in Program[scope: ^(scope), statements: ^(statements)]
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

  class Scope < Node
    # attr_reader locals: Array[Token]
    attr_reader :locals

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (locals: Array[Token], location: Location) -> void
    def initialize(locals, location)
      @locals = locals
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_scope(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [*locals]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { locals: locals, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in Scope[locals: ^(locals)]
    end
  end

  # Represents the `self` keyword.
  # 
  #     self
  #     ~~~~
  class SelfNode < Node
    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (keyword: Token, location: Location) -> void
    def initialize(keyword, location)
      @keyword = keyword
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_self_node(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { keyword: keyword, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in SelfNode[keyword: ^(keyword)]
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

  class TrueNode < Node
    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (keyword: Token, location: Location) -> void
    def initialize(keyword, location)
      @keyword = keyword
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_true_node(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      []
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { keyword: keyword, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in TrueNode[keyword: ^(keyword)]
    end
  end

  class UnlessNode < Node
    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader predicate: Node
    attr_reader :predicate

    # attr_reader statement: Node
    attr_reader :statement

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (keyword: Token, predicate: Node, statement: Node, location: Location) -> void
    def initialize(keyword, predicate, statement, location)
      @keyword = keyword
      @predicate = predicate
      @statement = statement
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_unless_node(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [predicate, statement]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { keyword: keyword, predicate: predicate, statement: statement, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in UnlessNode[keyword: ^(keyword), predicate: ^(predicate), statement: ^(statement)]
    end
  end

  class UntilNode < Node
    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader predicate: Node
    attr_reader :predicate

    # attr_reader statement: Node
    attr_reader :statement

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (keyword: Token, predicate: Node, statement: Node, location: Location) -> void
    def initialize(keyword, predicate, statement, location)
      @keyword = keyword
      @predicate = predicate
      @statement = statement
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_until_node(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [predicate, statement]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { keyword: keyword, predicate: predicate, statement: statement, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in UntilNode[keyword: ^(keyword), predicate: ^(predicate), statement: ^(statement)]
    end
  end

  class WhileNode < Node
    # attr_reader keyword: Token
    attr_reader :keyword

    # attr_reader predicate: Node
    attr_reader :predicate

    # attr_reader statement: Node
    attr_reader :statement

    # attr_reader location: Location
    attr_reader :location

    # def initialize: (keyword: Token, predicate: Node, statement: Node, location: Location) -> void
    def initialize(keyword, predicate, statement, location)
      @keyword = keyword
      @predicate = predicate
      @statement = statement
      @location = location
    end

    # def accept: (visitor: Visitor) -> void
    def accept(visitor)
      visitor.visit_while_node(self)
    end

    # def child_nodes: () -> Array[nil | Node]
    def child_nodes
      [predicate, statement]
    end

    # def deconstruct: () -> Array[nil | Node]
    alias deconstruct child_nodes

    # def deconstruct_keys: (keys: Array[Symbol]) -> Hash[Symbol, nil | Token | Node | Array[Node] | Location]
    def deconstruct_keys(keys)
      { keyword: keyword, predicate: predicate, statement: statement, location: location }
    end

    # def ==(other: Object) -> bool
    def ==(other)
      other in WhileNode[keyword: ^(keyword), predicate: ^(predicate), statement: ^(statement)]
    end
  end

  class Visitor < BasicVisitor
    # Visit a Assignment node
    alias visit_assignment visit_child_nodes

    # Visit a Binary node
    alias visit_binary visit_child_nodes

    # Visit a CallNode node
    alias visit_call_node visit_child_nodes

    # Visit a CharacterLiteral node
    alias visit_character_literal visit_child_nodes

    # Visit a ClassVariableRead node
    alias visit_class_variable_read visit_child_nodes

    # Visit a ClassVariableWrite node
    alias visit_class_variable_write visit_child_nodes

    # Visit a FalseNode node
    alias visit_false_node visit_child_nodes

    # Visit a FloatLiteral node
    alias visit_float_literal visit_child_nodes

    # Visit a GlobalVariableRead node
    alias visit_global_variable_read visit_child_nodes

    # Visit a GlobalVariableWrite node
    alias visit_global_variable_write visit_child_nodes

    # Visit a IfNode node
    alias visit_if_node visit_child_nodes

    # Visit a ImaginaryLiteral node
    alias visit_imaginary_literal visit_child_nodes

    # Visit a InstanceVariableRead node
    alias visit_instance_variable_read visit_child_nodes

    # Visit a InstanceVariableWrite node
    alias visit_instance_variable_write visit_child_nodes

    # Visit a IntegerLiteral node
    alias visit_integer_literal visit_child_nodes

    # Visit a LocalVariableRead node
    alias visit_local_variable_read visit_child_nodes

    # Visit a LocalVariableWrite node
    alias visit_local_variable_write visit_child_nodes

    # Visit a NilNode node
    alias visit_nil_node visit_child_nodes

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

    # Visit a Scope node
    alias visit_scope visit_child_nodes

    # Visit a SelfNode node
    alias visit_self_node visit_child_nodes

    # Visit a Statements node
    alias visit_statements visit_child_nodes

    # Visit a Ternary node
    alias visit_ternary visit_child_nodes

    # Visit a TrueNode node
    alias visit_true_node visit_child_nodes

    # Visit a UnlessNode node
    alias visit_unless_node visit_child_nodes

    # Visit a UntilNode node
    alias visit_until_node visit_child_nodes

    # Visit a WhileNode node
    alias visit_while_node visit_child_nodes
  end

  module DSL
    private

    # Create a new Assignment node
    def Assignment(target, operator, value, location = Location.null)
      Assignment.new(target, operator, value, location)
    end

    # Create a new Binary node
    def Binary(left, operator, right, location = Location.null)
      Binary.new(left, operator, right, location)
    end

    # Create a new CallNode node
    def CallNode(message, location = Location.null)
      CallNode.new(message, location)
    end

    # Create a new CharacterLiteral node
    def CharacterLiteral(value, location = Location.null)
      CharacterLiteral.new(value, location)
    end

    # Create a new ClassVariableRead node
    def ClassVariableRead(name, location = Location.null)
      ClassVariableRead.new(name, location)
    end

    # Create a new ClassVariableWrite node
    def ClassVariableWrite(name, operator, value, location = Location.null)
      ClassVariableWrite.new(name, operator, value, location)
    end

    # Create a new FalseNode node
    def FalseNode(keyword, location = Location.null)
      FalseNode.new(keyword, location)
    end

    # Create a new FloatLiteral node
    def FloatLiteral(value, location = Location.null)
      FloatLiteral.new(value, location)
    end

    # Create a new GlobalVariableRead node
    def GlobalVariableRead(name, location = Location.null)
      GlobalVariableRead.new(name, location)
    end

    # Create a new GlobalVariableWrite node
    def GlobalVariableWrite(name, operator, value, location = Location.null)
      GlobalVariableWrite.new(name, operator, value, location)
    end

    # Create a new IfNode node
    def IfNode(keyword, predicate, statements, location = Location.null)
      IfNode.new(keyword, predicate, statements, location)
    end

    # Create a new ImaginaryLiteral node
    def ImaginaryLiteral(value, location = Location.null)
      ImaginaryLiteral.new(value, location)
    end

    # Create a new InstanceVariableRead node
    def InstanceVariableRead(name, location = Location.null)
      InstanceVariableRead.new(name, location)
    end

    # Create a new InstanceVariableWrite node
    def InstanceVariableWrite(name, operator, value, location = Location.null)
      InstanceVariableWrite.new(name, operator, value, location)
    end

    # Create a new IntegerLiteral node
    def IntegerLiteral(value, location = Location.null)
      IntegerLiteral.new(value, location)
    end

    # Create a new LocalVariableRead node
    def LocalVariableRead(name, location = Location.null)
      LocalVariableRead.new(name, location)
    end

    # Create a new LocalVariableWrite node
    def LocalVariableWrite(name, operator, value, location = Location.null)
      LocalVariableWrite.new(name, operator, value, location)
    end

    # Create a new NilNode node
    def NilNode(keyword, location = Location.null)
      NilNode.new(keyword, location)
    end

    # Create a new OperatorAssignment node
    def OperatorAssignment(target, operator, value, location = Location.null)
      OperatorAssignment.new(target, operator, value, location)
    end

    # Create a new Program node
    def Program(scope, statements, location = Location.null)
      Program.new(scope, statements, location)
    end

    # Create a new RationalLiteral node
    def RationalLiteral(value, location = Location.null)
      RationalLiteral.new(value, location)
    end

    # Create a new Redo node
    def Redo(value, location = Location.null)
      Redo.new(value, location)
    end

    # Create a new Retry node
    def Retry(value, location = Location.null)
      Retry.new(value, location)
    end

    # Create a new Scope node
    def Scope(locals, location = Location.null)
      Scope.new(locals, location)
    end

    # Create a new SelfNode node
    def SelfNode(keyword, location = Location.null)
      SelfNode.new(keyword, location)
    end

    # Create a new Statements node
    def Statements(body, location = Location.null)
      Statements.new(body, location)
    end

    # Create a new Ternary node
    def Ternary(predicate, question_mark, true_expression, colon, false_expression, location = Location.null)
      Ternary.new(predicate, question_mark, true_expression, colon, false_expression, location)
    end

    # Create a new TrueNode node
    def TrueNode(keyword, location = Location.null)
      TrueNode.new(keyword, location)
    end

    # Create a new UnlessNode node
    def UnlessNode(keyword, predicate, statement, location = Location.null)
      UnlessNode.new(keyword, predicate, statement, location)
    end

    # Create a new UntilNode node
    def UntilNode(keyword, predicate, statement, location = Location.null)
      UntilNode.new(keyword, predicate, statement, location)
    end

    # Create a new WhileNode node
    def WhileNode(keyword, predicate, statement, location = Location.null)
      WhileNode.new(keyword, predicate, statement, location)
    end

    # Create a new EOF token
    def EOF(value, location = Location.null)
      Token.new(:EOF, value, location)
    end

    # Create a new INVALID token
    def INVALID(value, location = Location.null)
      Token.new(:INVALID, value, location)
    end

    # Create a new AMPERSAND token
    def AMPERSAND(value, location = Location.null)
      Token.new(:AMPERSAND, value, location)
    end

    # Create a new AMPERSAND_AMPERSAND token
    def AMPERSAND_AMPERSAND(value, location = Location.null)
      Token.new(:AMPERSAND_AMPERSAND, value, location)
    end

    # Create a new AMPERSAND_AMPERSAND_EQUAL token
    def AMPERSAND_AMPERSAND_EQUAL(value, location = Location.null)
      Token.new(:AMPERSAND_AMPERSAND_EQUAL, value, location)
    end

    # Create a new AMPERSAND_EQUAL token
    def AMPERSAND_EQUAL(value, location = Location.null)
      Token.new(:AMPERSAND_EQUAL, value, location)
    end

    # Create a new BACK_REFERENCE token
    def BACK_REFERENCE(value, location = Location.null)
      Token.new(:BACK_REFERENCE, value, location)
    end

    # Create a new BACKTICK token
    def BACKTICK(value, location = Location.null)
      Token.new(:BACKTICK, value, location)
    end

    # Create a new BANG token
    def BANG(value, location = Location.null)
      Token.new(:BANG, value, location)
    end

    # Create a new BANG_AT token
    def BANG_AT(value, location = Location.null)
      Token.new(:BANG_AT, value, location)
    end

    # Create a new BANG_EQUAL token
    def BANG_EQUAL(value, location = Location.null)
      Token.new(:BANG_EQUAL, value, location)
    end

    # Create a new BANG_TILDE token
    def BANG_TILDE(value, location = Location.null)
      Token.new(:BANG_TILDE, value, location)
    end

    # Create a new BRACE_LEFT token
    def BRACE_LEFT(value, location = Location.null)
      Token.new(:BRACE_LEFT, value, location)
    end

    # Create a new BRACE_RIGHT token
    def BRACE_RIGHT(value, location = Location.null)
      Token.new(:BRACE_RIGHT, value, location)
    end

    # Create a new BRACKET_LEFT token
    def BRACKET_LEFT(value, location = Location.null)
      Token.new(:BRACKET_LEFT, value, location)
    end

    # Create a new BRACKET_LEFT_RIGHT token
    def BRACKET_LEFT_RIGHT(value, location = Location.null)
      Token.new(:BRACKET_LEFT_RIGHT, value, location)
    end

    # Create a new BRACKET_RIGHT token
    def BRACKET_RIGHT(value, location = Location.null)
      Token.new(:BRACKET_RIGHT, value, location)
    end

    # Create a new CARET token
    def CARET(value, location = Location.null)
      Token.new(:CARET, value, location)
    end

    # Create a new CARET_EQUAL token
    def CARET_EQUAL(value, location = Location.null)
      Token.new(:CARET_EQUAL, value, location)
    end

    # Create a new CHARACTER_LITERAL token
    def CHARACTER_LITERAL(value, location = Location.null)
      Token.new(:CHARACTER_LITERAL, value, location)
    end

    # Create a new CLASS_VARIABLE token
    def CLASS_VARIABLE(value, location = Location.null)
      Token.new(:CLASS_VARIABLE, value, location)
    end

    # Create a new COLON token
    def COLON(value, location = Location.null)
      Token.new(:COLON, value, location)
    end

    # Create a new COLON_COLON token
    def COLON_COLON(value, location = Location.null)
      Token.new(:COLON_COLON, value, location)
    end

    # Create a new COMMA token
    def COMMA(value, location = Location.null)
      Token.new(:COMMA, value, location)
    end

    # Create a new COMMENT token
    def COMMENT(value, location = Location.null)
      Token.new(:COMMENT, value, location)
    end

    # Create a new CONSTANT token
    def CONSTANT(value, location = Location.null)
      Token.new(:CONSTANT, value, location)
    end

    # Create a new DOT token
    def DOT(value, location = Location.null)
      Token.new(:DOT, value, location)
    end

    # Create a new DOT_DOT token
    def DOT_DOT(value, location = Location.null)
      Token.new(:DOT_DOT, value, location)
    end

    # Create a new DOT_DOT_DOT token
    def DOT_DOT_DOT(value, location = Location.null)
      Token.new(:DOT_DOT_DOT, value, location)
    end

    # Create a new EMBDOC_BEGIN token
    def EMBDOC_BEGIN(value, location = Location.null)
      Token.new(:EMBDOC_BEGIN, value, location)
    end

    # Create a new EMBDOC_END token
    def EMBDOC_END(value, location = Location.null)
      Token.new(:EMBDOC_END, value, location)
    end

    # Create a new EMBDOC_LINE token
    def EMBDOC_LINE(value, location = Location.null)
      Token.new(:EMBDOC_LINE, value, location)
    end

    # Create a new EMBEXPR_BEGIN token
    def EMBEXPR_BEGIN(value, location = Location.null)
      Token.new(:EMBEXPR_BEGIN, value, location)
    end

    # Create a new EMBEXPR_END token
    def EMBEXPR_END(value, location = Location.null)
      Token.new(:EMBEXPR_END, value, location)
    end

    # Create a new EQUAL token
    def EQUAL(value, location = Location.null)
      Token.new(:EQUAL, value, location)
    end

    # Create a new EQUAL_EQUAL token
    def EQUAL_EQUAL(value, location = Location.null)
      Token.new(:EQUAL_EQUAL, value, location)
    end

    # Create a new EQUAL_EQUAL_EQUAL token
    def EQUAL_EQUAL_EQUAL(value, location = Location.null)
      Token.new(:EQUAL_EQUAL_EQUAL, value, location)
    end

    # Create a new EQUAL_GREATER token
    def EQUAL_GREATER(value, location = Location.null)
      Token.new(:EQUAL_GREATER, value, location)
    end

    # Create a new EQUAL_TILDE token
    def EQUAL_TILDE(value, location = Location.null)
      Token.new(:EQUAL_TILDE, value, location)
    end

    # Create a new FLOAT token
    def FLOAT(value, location = Location.null)
      Token.new(:FLOAT, value, location)
    end

    # Create a new GREATER token
    def GREATER(value, location = Location.null)
      Token.new(:GREATER, value, location)
    end

    # Create a new GREATER_EQUAL token
    def GREATER_EQUAL(value, location = Location.null)
      Token.new(:GREATER_EQUAL, value, location)
    end

    # Create a new GREATER_GREATER token
    def GREATER_GREATER(value, location = Location.null)
      Token.new(:GREATER_GREATER, value, location)
    end

    # Create a new GREATER_GREATER_EQUAL token
    def GREATER_GREATER_EQUAL(value, location = Location.null)
      Token.new(:GREATER_GREATER_EQUAL, value, location)
    end

    # Create a new GLOBAL_VARIABLE token
    def GLOBAL_VARIABLE(value, location = Location.null)
      Token.new(:GLOBAL_VARIABLE, value, location)
    end

    # Create a new IDENTIFIER token
    def IDENTIFIER(value, location = Location.null)
      Token.new(:IDENTIFIER, value, location)
    end

    # Create a new IMAGINARY_NUMBER token
    def IMAGINARY_NUMBER(value, location = Location.null)
      Token.new(:IMAGINARY_NUMBER, value, location)
    end

    # Create a new INSTANCE_VARIABLE token
    def INSTANCE_VARIABLE(value, location = Location.null)
      Token.new(:INSTANCE_VARIABLE, value, location)
    end

    # Create a new INTEGER token
    def INTEGER(value, location = Location.null)
      Token.new(:INTEGER, value, location)
    end

    # Create a new KEYWORD___ENCODING__ token
    def KEYWORD___ENCODING__(value, location = Location.null)
      Token.new(:KEYWORD___ENCODING__, value, location)
    end

    # Create a new KEYWORD___LINE__ token
    def KEYWORD___LINE__(value, location = Location.null)
      Token.new(:KEYWORD___LINE__, value, location)
    end

    # Create a new KEYWORD___FILE__ token
    def KEYWORD___FILE__(value, location = Location.null)
      Token.new(:KEYWORD___FILE__, value, location)
    end

    # Create a new KEYWORD_ALIAS token
    def KEYWORD_ALIAS(value, location = Location.null)
      Token.new(:KEYWORD_ALIAS, value, location)
    end

    # Create a new KEYWORD_AND token
    def KEYWORD_AND(value, location = Location.null)
      Token.new(:KEYWORD_AND, value, location)
    end

    # Create a new KEYWORD_BEGIN token
    def KEYWORD_BEGIN(value, location = Location.null)
      Token.new(:KEYWORD_BEGIN, value, location)
    end

    # Create a new KEYWORD_BEGIN_UPCASE token
    def KEYWORD_BEGIN_UPCASE(value, location = Location.null)
      Token.new(:KEYWORD_BEGIN_UPCASE, value, location)
    end

    # Create a new KEYWORD_BREAK token
    def KEYWORD_BREAK(value, location = Location.null)
      Token.new(:KEYWORD_BREAK, value, location)
    end

    # Create a new KEYWORD_CASE token
    def KEYWORD_CASE(value, location = Location.null)
      Token.new(:KEYWORD_CASE, value, location)
    end

    # Create a new KEYWORD_CLASS token
    def KEYWORD_CLASS(value, location = Location.null)
      Token.new(:KEYWORD_CLASS, value, location)
    end

    # Create a new KEYWORD_DEF token
    def KEYWORD_DEF(value, location = Location.null)
      Token.new(:KEYWORD_DEF, value, location)
    end

    # Create a new KEYWORD_DEFINED token
    def KEYWORD_DEFINED(value, location = Location.null)
      Token.new(:KEYWORD_DEFINED, value, location)
    end

    # Create a new KEYWORD_DO token
    def KEYWORD_DO(value, location = Location.null)
      Token.new(:KEYWORD_DO, value, location)
    end

    # Create a new KEYWORD_ELSE token
    def KEYWORD_ELSE(value, location = Location.null)
      Token.new(:KEYWORD_ELSE, value, location)
    end

    # Create a new KEYWORD_ELSIF token
    def KEYWORD_ELSIF(value, location = Location.null)
      Token.new(:KEYWORD_ELSIF, value, location)
    end

    # Create a new KEYWORD_END token
    def KEYWORD_END(value, location = Location.null)
      Token.new(:KEYWORD_END, value, location)
    end

    # Create a new KEYWORD_END_UPCASE token
    def KEYWORD_END_UPCASE(value, location = Location.null)
      Token.new(:KEYWORD_END_UPCASE, value, location)
    end

    # Create a new KEYWORD_ENSURE token
    def KEYWORD_ENSURE(value, location = Location.null)
      Token.new(:KEYWORD_ENSURE, value, location)
    end

    # Create a new KEYWORD_FALSE token
    def KEYWORD_FALSE(value, location = Location.null)
      Token.new(:KEYWORD_FALSE, value, location)
    end

    # Create a new KEYWORD_FOR token
    def KEYWORD_FOR(value, location = Location.null)
      Token.new(:KEYWORD_FOR, value, location)
    end

    # Create a new KEYWORD_IF token
    def KEYWORD_IF(value, location = Location.null)
      Token.new(:KEYWORD_IF, value, location)
    end

    # Create a new KEYWORD_IN token
    def KEYWORD_IN(value, location = Location.null)
      Token.new(:KEYWORD_IN, value, location)
    end

    # Create a new KEYWORD_MODULE token
    def KEYWORD_MODULE(value, location = Location.null)
      Token.new(:KEYWORD_MODULE, value, location)
    end

    # Create a new KEYWORD_NEXT token
    def KEYWORD_NEXT(value, location = Location.null)
      Token.new(:KEYWORD_NEXT, value, location)
    end

    # Create a new KEYWORD_NIL token
    def KEYWORD_NIL(value, location = Location.null)
      Token.new(:KEYWORD_NIL, value, location)
    end

    # Create a new KEYWORD_NOT token
    def KEYWORD_NOT(value, location = Location.null)
      Token.new(:KEYWORD_NOT, value, location)
    end

    # Create a new KEYWORD_OR token
    def KEYWORD_OR(value, location = Location.null)
      Token.new(:KEYWORD_OR, value, location)
    end

    # Create a new KEYWORD_REDO token
    def KEYWORD_REDO(value, location = Location.null)
      Token.new(:KEYWORD_REDO, value, location)
    end

    # Create a new KEYWORD_RESCUE token
    def KEYWORD_RESCUE(value, location = Location.null)
      Token.new(:KEYWORD_RESCUE, value, location)
    end

    # Create a new KEYWORD_RETRY token
    def KEYWORD_RETRY(value, location = Location.null)
      Token.new(:KEYWORD_RETRY, value, location)
    end

    # Create a new KEYWORD_RETURN token
    def KEYWORD_RETURN(value, location = Location.null)
      Token.new(:KEYWORD_RETURN, value, location)
    end

    # Create a new KEYWORD_SELF token
    def KEYWORD_SELF(value, location = Location.null)
      Token.new(:KEYWORD_SELF, value, location)
    end

    # Create a new KEYWORD_SUPER token
    def KEYWORD_SUPER(value, location = Location.null)
      Token.new(:KEYWORD_SUPER, value, location)
    end

    # Create a new KEYWORD_THEN token
    def KEYWORD_THEN(value, location = Location.null)
      Token.new(:KEYWORD_THEN, value, location)
    end

    # Create a new KEYWORD_TRUE token
    def KEYWORD_TRUE(value, location = Location.null)
      Token.new(:KEYWORD_TRUE, value, location)
    end

    # Create a new KEYWORD_UNDEF token
    def KEYWORD_UNDEF(value, location = Location.null)
      Token.new(:KEYWORD_UNDEF, value, location)
    end

    # Create a new KEYWORD_UNLESS token
    def KEYWORD_UNLESS(value, location = Location.null)
      Token.new(:KEYWORD_UNLESS, value, location)
    end

    # Create a new KEYWORD_UNTIL token
    def KEYWORD_UNTIL(value, location = Location.null)
      Token.new(:KEYWORD_UNTIL, value, location)
    end

    # Create a new KEYWORD_WHEN token
    def KEYWORD_WHEN(value, location = Location.null)
      Token.new(:KEYWORD_WHEN, value, location)
    end

    # Create a new KEYWORD_WHILE token
    def KEYWORD_WHILE(value, location = Location.null)
      Token.new(:KEYWORD_WHILE, value, location)
    end

    # Create a new KEYWORD_YIELD token
    def KEYWORD_YIELD(value, location = Location.null)
      Token.new(:KEYWORD_YIELD, value, location)
    end

    # Create a new LABEL token
    def LABEL(value, location = Location.null)
      Token.new(:LABEL, value, location)
    end

    # Create a new LAMBDA_BEGIN token
    def LAMBDA_BEGIN(value, location = Location.null)
      Token.new(:LAMBDA_BEGIN, value, location)
    end

    # Create a new LESS token
    def LESS(value, location = Location.null)
      Token.new(:LESS, value, location)
    end

    # Create a new LESS_EQUAL token
    def LESS_EQUAL(value, location = Location.null)
      Token.new(:LESS_EQUAL, value, location)
    end

    # Create a new LESS_EQUAL_GREATER token
    def LESS_EQUAL_GREATER(value, location = Location.null)
      Token.new(:LESS_EQUAL_GREATER, value, location)
    end

    # Create a new LESS_LESS token
    def LESS_LESS(value, location = Location.null)
      Token.new(:LESS_LESS, value, location)
    end

    # Create a new LESS_LESS_EQUAL token
    def LESS_LESS_EQUAL(value, location = Location.null)
      Token.new(:LESS_LESS_EQUAL, value, location)
    end

    # Create a new MINUS token
    def MINUS(value, location = Location.null)
      Token.new(:MINUS, value, location)
    end

    # Create a new MINUS_AT token
    def MINUS_AT(value, location = Location.null)
      Token.new(:MINUS_AT, value, location)
    end

    # Create a new MINUS_EQUAL token
    def MINUS_EQUAL(value, location = Location.null)
      Token.new(:MINUS_EQUAL, value, location)
    end

    # Create a new MINUS_GREATER token
    def MINUS_GREATER(value, location = Location.null)
      Token.new(:MINUS_GREATER, value, location)
    end

    # Create a new NEWLINE token
    def NEWLINE(value, location = Location.null)
      Token.new(:NEWLINE, value, location)
    end

    # Create a new NTH_REFERENCE token
    def NTH_REFERENCE(value, location = Location.null)
      Token.new(:NTH_REFERENCE, value, location)
    end

    # Create a new PARENTHESIS_LEFT token
    def PARENTHESIS_LEFT(value, location = Location.null)
      Token.new(:PARENTHESIS_LEFT, value, location)
    end

    # Create a new PARENTHESIS_RIGHT token
    def PARENTHESIS_RIGHT(value, location = Location.null)
      Token.new(:PARENTHESIS_RIGHT, value, location)
    end

    # Create a new PERCENT token
    def PERCENT(value, location = Location.null)
      Token.new(:PERCENT, value, location)
    end

    # Create a new PERCENT_EQUAL token
    def PERCENT_EQUAL(value, location = Location.null)
      Token.new(:PERCENT_EQUAL, value, location)
    end

    # Create a new PERCENT_LOWER_I token
    def PERCENT_LOWER_I(value, location = Location.null)
      Token.new(:PERCENT_LOWER_I, value, location)
    end

    # Create a new PERCENT_LOWER_W token
    def PERCENT_LOWER_W(value, location = Location.null)
      Token.new(:PERCENT_LOWER_W, value, location)
    end

    # Create a new PERCENT_LOWER_X token
    def PERCENT_LOWER_X(value, location = Location.null)
      Token.new(:PERCENT_LOWER_X, value, location)
    end

    # Create a new PERCENT_UPPER_I token
    def PERCENT_UPPER_I(value, location = Location.null)
      Token.new(:PERCENT_UPPER_I, value, location)
    end

    # Create a new PERCENT_UPPER_W token
    def PERCENT_UPPER_W(value, location = Location.null)
      Token.new(:PERCENT_UPPER_W, value, location)
    end

    # Create a new PIPE token
    def PIPE(value, location = Location.null)
      Token.new(:PIPE, value, location)
    end

    # Create a new PIPE_EQUAL token
    def PIPE_EQUAL(value, location = Location.null)
      Token.new(:PIPE_EQUAL, value, location)
    end

    # Create a new PIPE_PIPE token
    def PIPE_PIPE(value, location = Location.null)
      Token.new(:PIPE_PIPE, value, location)
    end

    # Create a new PIPE_PIPE_EQUAL token
    def PIPE_PIPE_EQUAL(value, location = Location.null)
      Token.new(:PIPE_PIPE_EQUAL, value, location)
    end

    # Create a new PLUS token
    def PLUS(value, location = Location.null)
      Token.new(:PLUS, value, location)
    end

    # Create a new PLUS_AT token
    def PLUS_AT(value, location = Location.null)
      Token.new(:PLUS_AT, value, location)
    end

    # Create a new PLUS_EQUAL token
    def PLUS_EQUAL(value, location = Location.null)
      Token.new(:PLUS_EQUAL, value, location)
    end

    # Create a new QUESTION_MARK token
    def QUESTION_MARK(value, location = Location.null)
      Token.new(:QUESTION_MARK, value, location)
    end

    # Create a new RATIONAL_NUMBER token
    def RATIONAL_NUMBER(value, location = Location.null)
      Token.new(:RATIONAL_NUMBER, value, location)
    end

    # Create a new REGEXP_BEGIN token
    def REGEXP_BEGIN(value, location = Location.null)
      Token.new(:REGEXP_BEGIN, value, location)
    end

    # Create a new REGEXP_END token
    def REGEXP_END(value, location = Location.null)
      Token.new(:REGEXP_END, value, location)
    end

    # Create a new SEMICOLON token
    def SEMICOLON(value, location = Location.null)
      Token.new(:SEMICOLON, value, location)
    end

    # Create a new SLASH token
    def SLASH(value, location = Location.null)
      Token.new(:SLASH, value, location)
    end

    # Create a new SLASH_EQUAL token
    def SLASH_EQUAL(value, location = Location.null)
      Token.new(:SLASH_EQUAL, value, location)
    end

    # Create a new STAR token
    def STAR(value, location = Location.null)
      Token.new(:STAR, value, location)
    end

    # Create a new STAR_EQUAL token
    def STAR_EQUAL(value, location = Location.null)
      Token.new(:STAR_EQUAL, value, location)
    end

    # Create a new STAR_STAR token
    def STAR_STAR(value, location = Location.null)
      Token.new(:STAR_STAR, value, location)
    end

    # Create a new STAR_STAR_EQUAL token
    def STAR_STAR_EQUAL(value, location = Location.null)
      Token.new(:STAR_STAR_EQUAL, value, location)
    end

    # Create a new STRING_BEGIN token
    def STRING_BEGIN(value, location = Location.null)
      Token.new(:STRING_BEGIN, value, location)
    end

    # Create a new STRING_CONTENT token
    def STRING_CONTENT(value, location = Location.null)
      Token.new(:STRING_CONTENT, value, location)
    end

    # Create a new STRING_END token
    def STRING_END(value, location = Location.null)
      Token.new(:STRING_END, value, location)
    end

    # Create a new SYMBOL_BEGIN token
    def SYMBOL_BEGIN(value, location = Location.null)
      Token.new(:SYMBOL_BEGIN, value, location)
    end

    # Create a new TILDE token
    def TILDE(value, location = Location.null)
      Token.new(:TILDE, value, location)
    end

    # Create a new TILDE_AT token
    def TILDE_AT(value, location = Location.null)
      Token.new(:TILDE_AT, value, location)
    end

    # Create a new WORDS_SEP token
    def WORDS_SEP(value, location = Location.null)
      Token.new(:WORDS_SEP, value, location)
    end
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
