# frozen_string_literal: true

module Prism
  module Compile
    class Local
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end

    class Insn
      attr_reader :kind, :node_id, :opnds, :data

      def initialize(kind, node_id, opnds, data)
        @kind = kind
        @node_id = node_id
        @opnds = opnds
        @data = data
      end
    end

    class Block
      attr_reader :insns, :params

      def initialize(insns, params)
        @insns = insns
        @params = params
      end
    end

    class Graph
      attr_reader :kind, :parent, :blocks, :locals

      def initialize(kind, parent, blocks, locals)
        @kind = kind
        @parent = parent
        @blocks = blocks
        @locals = locals
      end
    end

    class Unit
      attr_reader :graphs

      def initialize(graphs)
        @graphs = graphs
      end
    end

    class << self
      def run_unit(unit)
        run_graph(unit.graphs[0], TOPLEVEL_BINDING.receiver, [Object].freeze)
      end

      def run_graph(graph, recv, nest)
        values = []
        locals = graph.locals.to_h { |local| [local.name, nil] }
        block = graph.blocks[0]

        while true
          block.insns.each do |insn|
            case insn.kind
            when :alias_method
              Module.instance_method(:alias_method).bind_call(nest[0], values[insn.opnds[0]], values[insn.opnds[1]])
            when :branch
              block = insn.data
              block.params.zip(insn.opnds.map { |opnd| values[opnd] }) { |param, value| values[param] = value }
              break
            when :branch_if
              then_block, else_block, then_block_nopnds = insn.data
              if values[insn.opnds[0]]
                block = then_block
                block.params.zip(insn.opnds[1...(then_block_nopnds + 1)].map { |opnd| values[opnd] }) { |param, value| values[param] = value }
              else
                block = else_block
                block.params.zip(insn.opnds[(then_block_nopnds + 1)..].map { |opnd| values[opnd] }) { |param, value| values[param] = value }
              end
              break
            when :call
              values[insn.opnds[0]] = values[insn.opnds[1]].send(insn.data, *values.values_at(*insn.opnds[2..]))
            when :coerce_hash
              value = values[insn.opnds[1]]
              values[insn.opnds[0]] = NilClass === value ? {} : {}.update(value)
            when :coerce_string
              value = values[insn.opnds[1]]
              string = value.__send__(:to_s)
              values[insn.opnds[0]] = String === string ? string : Kernel.instance_method(:to_s).bind_call(value)
            when :define_class_abs
              name, class_graph = insn.data
              klass = define_class(Object, name, true)
              values[insn.opnds[0]] = run_graph(class_graph, klass, [klass, *nest].freeze)
            when :define_class_abs_super
              name, class_graph = insn.data
              superclass = values[insn.opnds[1]]
              check_superclass(superclass)
              klass = define_class_super(Object, name, true, superclass)
              values[insn.opnds[0]] = run_graph(class_graph, klass, [klass, *nest].freeze)
            when :define_class_nest_rel
              name, class_graph = insn.data
              klass = define_class(nest[0], name, false)
              values[insn.opnds[0]] = run_graph(class_graph, klass, [klass, *nest].freeze)
            when :define_class_nest_rel_super
              name, class_graph = insn.data
              superclass = values[insn.opnds[1]]
              check_superclass(superclass)
              klass = define_class_super(nest[0], name, false, superclass)
              values[insn.opnds[0]] = run_graph(class_graph, klass, [klass, *nest].freeze)
            when :define_class_recv_rel
              name, class_graph = insn.data
              parent = values[insn.opnds[1]]
              check_module(parent)
              klass = define_class(parent, name, true)
              values[insn.opnds[0]] = run_graph(class_graph, klass, [klass, *nest].freeze)
            when :define_class_recv_rel_super
              name, class_graph = insn.data
              parent = values[insn.opnds[1]]
              superclass = values[insn.opnds[2]]
              check_superclass(superclass)
              check_module(parent)
              klass = define_class_super(parent, name, true, superclass)
              values[insn.opnds[0]] = run_graph(class_graph, klass, [klass, *nest].freeze)
            when :define_method
              raise "todo"
            when :define_singleton_class
              raise "todo"
            when :defined_cvar
              values[insn.opnds[0]] = Module.instance_method(:class_variable_defined?).bind_call(cvar_parent(nest) || nest[-1], insn.data)
            when :defined_gvar
              values[insn.opnds[0]] = !eval("defined?(#{insn.data})", TOPLEVEL_BINDING).nil?
            when :extract_last_match_group
              values[insn.opnds[0]] = values[insn.opnds[1]]&.[](insn.data)
            when :extract_last_match_match
              values[insn.opnds[0]] = values[insn.opnds[1]]&.[](0)
            when :extract_last_match_paren
              values[insn.opnds[0]] = values[insn.opnds[1]]&.captures&.reverse_each&.find(&:itself)
            when :extract_last_match_post
              values[insn.opnds[0]] = values[insn.opnds[1]]&.post_match
            when :extract_last_match_pre
              values[insn.opnds[0]] = values[insn.opnds[1]]&.pre_match
            when :load_object
              values[insn.opnds[0]] = insn.data
            when :load_const_abs
              values[insn.opnds[0]] = insn.data.inject(Object) { |scope, name| const_get_recv_rel(scope, name) }
            when :load_const_nest_rel
              first, *rest = insn.data
              values[insn.opnds[0]] = rest.inject(const_get_nest_rel(nest, first)) { |scope, name| const_get_recv_rel(scope, name) }
            when :load_const_recv_rel
              values[insn.opnds[0]] = insn.data.inject(values[insn.opnds[1]]) { |scope, name| const_get_recv_rel(scope, name) }
            when :load_cvar
              parent = cvar_parent(nest)
              check_cvar_parent(parent)
              values[insn.opnds[0]] = Module.instance_method(:class_variable_get).bind_call(parent, insn.data)
            when :load_gvar
              values[insn.opnds[0]] = eval(insn.data.name, TOPLEVEL_BINDING)
            when :load_ivar
              values[insn.opnds[0]] = recv.instance_variable_get(insn.data)
            when :load_last_match
              values[insn.opnds[0]] = $~
            when :load_lvar
              values[insn.opnds[0]] = locals[insn.data]
            when :load_self
              values[insn.opnds[0]] = recv
            when :match
              values[insn.opnds[0]] = values[insn.opnds[2]] === values[insn.opnds[1]]
            when :merge_hash
              values[insn.opnds[0]] = values[insn.opnds[1]].merge(values[insn.opnds[2]])
            when :new_array
              values[insn.opnds[0]] = values.values_at(*insn.opnds[1..])
            when :new_array_static
              values[insn.opnds[0]] = insn.data.dup
            when :new_hash
              values[insn.opnds[0]] = values.values_at(*insn.opnds[1..]).each_slice(2).to_h
            when :new_hash_static
              values[insn.opnds[0]] = insn.data.dup
            when :new_range_exc
              values[insn.opnds[0]] = (values[insn.opnds[1]]...values[insn.opnds[2]])
            when :new_range_inc
              values[insn.opnds[0]] = (values[insn.opnds[1]]..values[insn.opnds[2]])
            when :new_regexp
              values[insn.opnds[0]] = Regexp.new(values.values_at(*insn.opnds[1..]).join)
            when :new_string
              values[insn.opnds[0]] = values.values_at(*insn.opnds[1..]).join
            when :new_symbol
              values[insn.opnds[0]] = values.values_at(*insn.opnds[1..]).join.to_sym
            when :return
              return values[insn.opnds[0]]
            when :store_const_abs
              Object.const_set(insn.data, values[insn.opnds[0]])
            when :store_const_nest_rel
              nest[0].const_set(insn.data, values[insn.opnds[0]])
            when :store_const_recv_rel
              check_module(values[insn.opnds[0]])
              values[insn.opnds[0]].const_set(insn.data, values[insn.opnds[1]])
            when :store_cvar
              parent = cvar_parent(nest)
              check_cvar_parent(parent)
              Module.instance_method(:class_variable_set).bind_call(parent, insn.data, values[insn.opnds[0]])
            when :store_ivar
              recv.instance_variable_set(insn.data, values[insn.opnds[0]])
            when :store_gvar
              eval("#{insn.data} = value", TOPLEVEL_BINDING.tap { |binding| binding.local_variable_set(:value, values[insn.opnds[0]]) })
            when :store_lvar
              locals[insn.data] = values[insn.opnds[0]]
            when :trace_call, :trace_class, :trace_end, :trace_line, :trace_return
              # ignore
            when :undef_method
              Module.instance_method(:undef_method).bind_call(nest[0], values[insn.opnds[0]])
            else
              raise "Unknown instruction kind: #{insn.kind}"
            end
          end
        end
      end

      private

      def cvar_parent(nest)
        nest[0...-1].find { |scope| !Module.instance_method(:singleton_class?).bind_call(scope) }
      end

      ###

      def define_class(parent, name, check_public)
        existing_class(parent, name, check_public) || parent.const_set(name, Class.new)
      end

      def define_class_super(parent, name, check_public, superclass)
        if (klass = existing_class(parent, name, check_public))
          unless klass.superclass.equal?(superclass)
            raise TypeError, "superclass mismatch for class #{name}"
          end

          klass
        else
          parent.const_set(name, Class.new(superclass))
        end
      end

      def existing_class(parent, name, check_public)
        if parent.const_defined?(name, false)
          check_public_const(parent, parent, name) if check_public
          const = parent.const_get(name, false)
          check_class(parent, name, const)
          const
        end
      end

      ###

      def const_get_nest_rel(nest, name)
        nest[0...-1].each do |scope|
          return scope.const_get(name, false) if scope.const_defined?(name, false)
        end

        nest[0].const_get(name)
      end

      def const_get_recv_rel(recv, name)
        check_module(recv)
        owner = recv.ancestors.find { |ancestor| ancestor.const_defined?(name, false) }

        if owner.nil? || (owner == Object && recv != Object)
          recv.const_missing(name)
        else
          check_public_const(owner, recv, name)
          owner.const_get(name, false)
        end
      end

      ###

      def check_class(parent, name, const)
        unless Class === const
          message = +"#{name} is not a class"

          if (location = parent.const_source_location(name, false))
            message << "\n#{location[0]}:#{location[1]}: previous definition of #{name} was here"
          end

          raise TypeError, message
        end
      end

      def check_cvar_parent(parent)
        unless parent
          raise RuntimeError, "class variable access from toplevel"
        end
      end

      def check_module(const)
        unless Module === const
          raise TypeError, "#{const.inspect} is not a class/module"
        end
      end

      def check_superclass(superclass)
        unless Class === superclass
          raise TypeError, "superclass must be an instance of Class (given an instance of #{Kernel.instance_method(:class).bind_call(superclass)})"
        end
      end

      def check_public_const(parent, recv, name)
        unless parent.constants(false).include?(name)
          raise NameError.new("private constant #{recv}::#{name} referenced", name, receiver: recv)
        end
      end
    end
  end
end
