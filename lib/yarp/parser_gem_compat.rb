# frozen_string_literal: true

require 'ast'

module YARP
  module ParserGemCompat
    class Visitor < ::YARP::BasicVisitor
      include ::AST::Sexp

      def visit_program_node(node)
        convert node.statements
      end

      def visit_statements_node(node)
        statements = node.body
        if statements.size == 1
          convert statements[0]
        else
          s(:begin, *convert_array(statements))
        end
      end

      private def visit_statements_node_no_single(node)
        s(:begin, *convert_array(node.body))
      end

      def visit_begin_node(node)
        if node.rescue_clause
          s(:kwbegin, s(:rescue, convert(node.statements), convert(node.rescue_clause)), convert_or_nil(node.else_clause))
        else
          super
        end
      end

      def visit_rescue_node(node)
        s(:resbody, s(:array, *convert_array(node.exceptions)), convert_or_nil(node.reference), convert(node.statements))
      end

      def visit_if_node(node)
        s(:if, convert(node.predicate), convert_or_nil(node.statements), convert_or_nil(node.consequent))
      end

      def visit_unless_node(node)
        s(:if, convert(node.predicate), convert_or_nil(node.consequent), convert_or_nil(node.statements))
      end

      def visit_else_node(node)
        convert(node.statements)
      end

      def visit_next_node(node)
        s(:next)
      end

      def visit_module_node(node)
        s(:module, convert(node.constant_path), convert_or_nil(node.body))
      end

      def visit_class_node(node)
        s(:class, convert(node.constant_path), convert_or_nil(node.superclass), convert_or_nil(node.body))
      end

      def visit_def_node(node)
        parameters = convert_or_nil(node.parameters) || s(:args)
        if node.receiver
          s(:defs, convert(node.receiver), node.name.to_sym, parameters, convert_or_nil(node.body))
        else
          s(:def, node.name.to_sym, parameters, convert_or_nil(node.body))
        end
      end

      def visit_block_node(node)
        parameters = convert_or_nil(node.parameters) || s(:args)
        [parameters, convert_or_nil(node.body)]
      end

      def visit_block_parameters_node(node)
        raise unless node.locals.empty?
        convert(node.parameters)
      end

      def visit_parameters_node(node)
        children = [*convert_array(node.requireds), *convert_array(node.optionals)]
        children << convert(node.rest) if node.rest
        children.concat convert_array(node.posts)
        children.concat convert_array(node.keywords)
        children << convert(node.keyword_rest) if node.keyword_rest
        children << convert(node.block) if node.block
        s(:args, *children)
      end

      def visit_required_parameter_node(node)
        s(:arg, node.constant_id)
      end

      def visit_optional_parameter_node(node)
        s(:optarg, node.constant_id, convert(node.value))
      end

      def visit_rest_parameter_node(node)
        s(:restarg, node.name.to_sym)
      end

      def visit_block_parameter_node(node)
        s(:blockarg, node.name.to_sym)
      end

      def visit_array_node(node)
        s(:array, *convert_array(node.elements))
      end

      def visit_hash_node(node)
        s(:hash, *convert_array(node.elements))
      end

      def visit_keyword_hash_node(node)
        visit_hash_node(node)
      end

      def visit_assoc_node(node)
        s(:pair, convert(node.key), convert(node.value))
      end

      def visit_assoc_splat_node(node)
        s(:kwsplat, convert(node.value))
      end

      def visit_call_node(node)
        arguments = node.arguments ? convert_array(node.arguments.arguments) : []
        converted = s(:send, convert_or_nil(node.receiver), node.name.to_sym, *arguments)
        if node.block
          s(:block, converted, *convert(node.block))
        else
          converted
        end
      end

      def visit_yield_node(node)
        arguments = node.arguments ? convert_array(node.arguments.arguments) : []
        s(:yield, *arguments)
      end

      def visit_local_variable_read_node(node)
        s(:lvar, node.constant_id)
      end

      def visit_local_variable_write_node(node)
        if node.value
          s(:lvasgn, node.constant_id, convert(node.value))
        else
          s(:lvasgn, node.constant_id)
        end
      end

      def visit_instance_variable_read_node(node)
        s(:ivar, node.slice.to_sym)
      end

      def visit_instance_variable_write_node(node)
        if node.value
          s(:ivasgn, node.name.to_sym, convert(node.value))
        else
          s(:ivasgn, node.name.to_sym)
        end
      end

      def visit_constant_read_node(node)
        s(:const, nil, node.slice.to_sym)
      end

      def visit_constant_path_node(node)
        raise unless ConstantReadNode === node.child
        s(:const, convert(node.parent), node.child.slice.to_sym)
      end

      def visit_constant_write_node(node)
        s(:casgn, nil, node.name.to_sym, convert(node.value))
      end

      def visit_operator_write_node(node)
        s(:op_asgn, convert(node.target), node.operator, convert(node.value))
      end

      def visit_interpolated_string_node(node)
        s(:dstr, *convert_array(node.parts))
      end

      def visit_embedded_statements_node(node)
        visit_statements_node_no_single(node.statements)
      end

      def visit_string_node(node)
        s(:str, node.unescaped)
      end

      def visit_symbol_node(node)
        s(:sym, node.value.to_sym)
      end

      def visit_rational_node(node)
        s(:rational, node.value)
      end

      def visit_imaginary_node(node)
        s(:complex, node.value)
      end

      def visit_float_node(node)
        s(:float, node.value)
      end

      def visit_integer_node(node)
        s(:int, node.value)
      end

      def visit_self_node(node)
        s(:self)
      end

      def visit_true_node(node)
        s(:true)
      end

      def visit_false_node(node)
        s(:false)
      end

      def visit_nil_node(node)
        s(:nil)
      end

      def method_missing(name, node, *)
        if name.start_with?("visit_")
          pp node
          raise "not yet handled:\ndef #{name}(node)\n\nend"
        else
          super
        end
      end

      private def convert_array(nodes)
        nodes.map { convert _1 }
      end

      private def convert(node)
        node.accept(self)
      end

      private def convert_or_nil(node)
        node.accept(self) if node
      end
    end

    def self.parse(code, filepath = nil)
      parse_result = YARP.parse(code, filepath)
      parse_result.value.accept(Visitor.new)
    end
  end
end
