# frozen_string_literal: true

require "set"

module Prism
  module Compile
    class Result < Prism::Result
      attr_reader :value

      def initialize(value, magic_comments, data_loc, errors, warnings, continuable, source)
        @value = value
        super(magic_comments, data_loc, errors, warnings, continuable, source)
      end

      def deconstruct_keys(keys)
        super.merge!(value: value)
      end
    end

    class Local
      attr_reader :id, :name

      def initialize(id, name)
        @id = id
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
      attr_reader :id, :insns, :params

      def initialize(id, insns, params)
        @id = id
        @insns = insns
        @params = params
      end
    end

    class Signature
      attr_reader :requireds, :rest, :autosplat

      def initialize(requireds, rest, autosplat)
        @requireds = requireds
        @rest = rest
        @autosplat = autosplat
      end
    end

    class Graph
      attr_reader :id, :kind, :parent, :scope, :blocks, :locals, :nvalues, :signature

      def initialize(id, kind, parent, scope, blocks, locals, nvalues, signature)
        @id = id
        @kind = kind
        @parent = parent
        @scope = scope || self
        @blocks = blocks
        @locals = locals
        @nvalues = nvalues
        @signature = signature
      end
    end

    class Unit
      attr_reader :graphs

      def initialize(graphs)
        @graphs = graphs
      end

      def disasm
        Disassembler.new(self).disasm
      end
    end

    class Disassembler
      def initialize(unit)
        @unit = unit
      end

      def disasm
        @unit.graphs.each_with_object(+"") do |graph, output|
          context = [graph.kind]
          context << "parent=#{graph_ref(graph.parent)}" if graph.parent
          context << "scope=#{graph_ref(graph.scope)}"
          signature = graph.signature
          params = signature.requireds.map { |id| value(id) }
          params << "*#{value(signature.rest)}" if signature.rest
          output << "#{graph_ref(graph)}#{params.empty? ? "" : "(#{params.join(', ')})"}#{signature.autosplat ? " [autosplat]" : ""} (#{context.join(', ')}):\n"

          graph.blocks.each do |block|
            output << "  #{block_ref(block)}#{values(block.params)}:\n"
            block.insns.each do |insn|
              output << "    #{instruction(insn)}\n"
            end
          end
        end
      end

      private

      def graph_ref(graph)
        "g#{graph.id}"
      end

      def block_ref(block)
        "bb#{block.id}"
      end

      def local_ref(local)
        "v#{local.id}"
      end

      def value(id)
        "%#{id}"
      end

      def values(ids)
        ids.empty? ? "" : "(#{ids.map { |id| value(id) }.join(', ')})"
      end

      def literal(object)
        Encoding === object ? "encoding(#{object.name})" : object.inspect
      end

      def instruction(insn)
        case insn.kind
        when :alias_method
          "alias_method #{insn.opnds.map { |id| value(id) }.join(', ')}"
        when :branch
          "branch #{block_ref(insn.data)}#{values(insn.opnds)}"
        when :branch_if
          opnds = insn.opnds
          then_block, else_block, then_count = insn.data
          "branchif #{value(opnds[0])} #{block_ref(then_block)}#{values(opnds[1, then_count])} #{block_ref(else_block)}#{values(opnds[(then_count + 1)..])}"
        when :call_with_block
          opnds = insn.opnds
          "#{value(opnds[0])} = call_with_block #{value(opnds[1])}.#{insn.data}#{values(opnds[2...-1])} &#{value(opnds[-1])}"
        when :call
          opnds = insn.opnds
          "#{value(opnds[0])} = call #{value(opnds[1])}.#{insn.data}#{values(opnds[2..])}"
        when :coerce_array
          opnds = insn.opnds
          "#{value(opnds[0])} = coerce_array#{values(opnds[1..])}"
        when :coerce_hash
          opnds = insn.opnds
          "#{value(opnds[0])} = coerce_hash#{values(opnds[1..])}"
        when :coerce_string
          opnds = insn.opnds
          "#{value(opnds[0])} = coerce_string#{values(opnds[1..])}"
        when :define_class_abs
          opnds = insn.opnds
          name, graph = insn.data
          name = "::#{name}"
          args = [name, *opnds[1..].map { |id| value(id) }, graph_ref(graph)]
          "#{value(opnds[0])} = define_class_abs(#{args.join(', ')})"
        when :define_class_abs_super
          opnds = insn.opnds
          name, graph = insn.data
          name = "::#{name}"
          args = [name, *opnds[1..].map { |id| value(id) }, graph_ref(graph)]
          "#{value(opnds[0])} = define_class_abs_super(#{args.join(', ')})"
        when :define_class_nest_rel
          opnds = insn.opnds
          name, graph = insn.data
          args = [name, *opnds[1..].map { |id| value(id) }, graph_ref(graph)]
          "#{value(opnds[0])} = define_class_nest_rel(#{args.join(', ')})"
        when :define_class_nest_rel_super
          opnds = insn.opnds
          name, graph = insn.data
          args = [name, *opnds[1..].map { |id| value(id) }, graph_ref(graph)]
          "#{value(opnds[0])} = define_class_nest_rel_super(#{args.join(', ')})"
        when :define_class_recv_rel
          opnds = insn.opnds
          name, graph = insn.data
          args = [name, *opnds[1..].map { |id| value(id) }, graph_ref(graph)]
          "#{value(opnds[0])} = define_class_recv_rel(#{args.join(', ')})"
        when :define_class_recv_rel_super
          opnds = insn.opnds
          name, graph = insn.data
          args = [name, *opnds[1..].map { |id| value(id) }, graph_ref(graph)]
          "#{value(opnds[0])} = define_class_recv_rel_super(#{args.join(', ')})"
        when :define_method
          name, graph = insn.data
          "define_method #{name.inspect}, #{graph_ref(graph)}"
        when :define_module_abs
          opnds = insn.opnds
          name, graph = insn.data
          name = "::#{name}"
          args = [name, *opnds[1..].map { |id| value(id) }, graph_ref(graph)]
          "#{value(opnds[0])} = define_module_abs(#{args.join(', ')})"
        when :define_module_nest_rel
          opnds = insn.opnds
          name, graph = insn.data
          args = [name, *opnds[1..].map { |id| value(id) }, graph_ref(graph)]
          "#{value(opnds[0])} = define_module_nest_rel(#{args.join(', ')})"
        when :define_module_recv_rel
          opnds = insn.opnds
          name, graph = insn.data
          args = [name, *opnds[1..].map { |id| value(id) }, graph_ref(graph)]
          "#{value(opnds[0])} = define_module_recv_rel(#{args.join(', ')})"
        when :define_singleton_class
          opnds = insn.opnds
          "#{value(opnds[0])} = define_singleton_class(#{value(opnds[1])}, #{graph_ref(insn.data)})"
        when :define_singleton_method
          name, graph = insn.data
          "define_singleton_method(#{name.inspect}, #{value(insn.opnds[0])}, #{graph_ref(graph)})"
        when :defined_const_abs
          opnds = insn.opnds
          name = "::#{insn.data}"
          "#{value(opnds[0])} = defined_const_abs(#{[*opnds[1..].map { |id| value(id) }, name].join(', ')})"
        when :defined_const_nest_rel
          opnds = insn.opnds
          name = insn.data
          "#{value(opnds[0])} = defined_const_nest_rel(#{[*opnds[1..].map { |id| value(id) }, name].join(', ')})"
        when :defined_const_recv_rel
          opnds = insn.opnds
          name = insn.data
          "#{value(opnds[0])} = defined_const_recv_rel(#{[*opnds[1..].map { |id| value(id) }, name].join(', ')})"
        when :defined_cvar
          "#{value(insn.opnds[0])} = defined_cvar #{insn.data}"
        when :defined_gvar
          "#{value(insn.opnds[0])} = defined_gvar #{insn.data}"
        when :extract_last_match_group
          opnds = insn.opnds
          "#{value(opnds[0])} = extract_last_match_group #{value(opnds[1])}, group=#{insn.data}"
        when :extract_last_match_named_group
          opnds = insn.opnds
          "#{value(opnds[0])} = extract_last_match_named_group(#{value(opnds[1])}, #{insn.data})"
        when :extract_last_match_match
          opnds = insn.opnds
          "#{value(opnds[0])} = extract_last_match_match#{values(opnds[1..])}"
        when :extract_last_match_paren
          opnds = insn.opnds
          "#{value(opnds[0])} = extract_last_match_paren#{values(opnds[1..])}"
        when :extract_last_match_post
          opnds = insn.opnds
          "#{value(opnds[0])} = extract_last_match_post#{values(opnds[1..])}"
        when :extract_last_match_pre
          opnds = insn.opnds
          "#{value(opnds[0])} = extract_last_match_pre#{values(opnds[1..])}"
        when :nil_p
          opnds = insn.opnds
          "#{value(opnds[0])} = nil_p#{values(opnds[1..])}"
        when :load_const_abs
          opnds = insn.opnds
          path = insn.data.join("::")
          path = "::#{path}"
          args = [*opnds[1..].map { |id| value(id) }, path]
          "#{value(opnds[0])} = load_const_abs(#{args.join(', ')})"
        when :load_const_nest_rel
          opnds = insn.opnds
          path = insn.data.join("::")
          args = [*opnds[1..].map { |id| value(id) }, path]
          "#{value(opnds[0])} = load_const_nest_rel(#{args.join(', ')})"
        when :load_const_recv_rel
          opnds = insn.opnds
          path = insn.data.join("::")
          args = [*opnds[1..].map { |id| value(id) }, path]
          "#{value(opnds[0])} = load_const_recv_rel(#{args.join(', ')})"
        when :load_cvar
          "#{value(insn.opnds[0])} = load_cvar #{insn.data}"
        when :load_gvar
          "#{value(insn.opnds[0])} = load_gvar #{insn.data}"
        when :load_ivar
          "#{value(insn.opnds[0])} = load_ivar #{insn.data}"
        when :load_last_match
          opnds = insn.opnds
          "#{value(opnds[0])} = load_last_match#{values(opnds[1..])}"
        when :load_lvar
          "#{value(insn.opnds[0])} = load_lvar #{local_ref(insn.data)}"
        when :load_object
          "#{value(insn.opnds[0])} = load_object(#{literal(insn.data)})"
        when :load_self
          opnds = insn.opnds
          "#{value(opnds[0])} = load_self#{values(opnds[1..])}"
        when :match
          opnds = insn.opnds
          "#{value(opnds[0])} = match#{values(opnds[1..])}"
        when :merge_hash
          opnds = insn.opnds
          "#{value(opnds[0])} = merge_hash#{values(opnds[1..])}"
        when :new_array
          opnds = insn.opnds
          "#{value(opnds[0])} = new_array#{values(opnds[1..])}"
        when :new_block
          "#{value(insn.opnds[0])} = new_block #{graph_ref(insn.data)}"
        when :new_array_static
          "#{value(insn.opnds[0])} = new_array_static(#{literal(insn.data)})"
        when :new_hash
          opnds = insn.opnds
          "#{value(opnds[0])} = new_hash#{values(opnds[1..])}"
        when :new_hash_static
          "#{value(insn.opnds[0])} = new_hash_static(#{literal(insn.data)})"
        when :new_range_exc
          opnds = insn.opnds
          "#{value(opnds[0])} = new_range_exc#{values(opnds[1..])}"
        when :new_range_inc
          opnds = insn.opnds
          "#{value(opnds[0])} = new_range_inc#{values(opnds[1..])}"
        when :new_regexp
          opnds = insn.opnds
          "#{value(opnds[0])} = new_regexp#{values(opnds[1..])} flags=#{insn.data}"
        when :new_string
          opnds = insn.opnds
          "#{value(opnds[0])} = new_string#{values(opnds[1..])}"
        when :new_symbol
          opnds = insn.opnds
          "#{value(opnds[0])} = new_symbol#{values(opnds[1..])}"
        when :post_execution
          "post_execution #{graph_ref(insn.data)}"
        when :return
          "return #{insn.opnds.map { |id| value(id) }.join(', ')}"
        when :store_const_abs
          name = "::#{insn.data}"
          "store_const_abs(#{name}, #{value(insn.opnds[0])})"
        when :store_const_nest_rel
          name = insn.data
          "store_const_nest_rel(#{name}, #{value(insn.opnds[0])})"
        when :store_const_recv_rel
          opnds = insn.opnds
          "store_const_recv_rel(#{value(opnds[0])}, #{insn.data}, #{value(opnds[1])})"
        when :store_cvar
          "store_cvar #{insn.data}, #{value(insn.opnds[0])}"
        when :store_gvar
          "store_gvar #{insn.data}, #{value(insn.opnds[0])}"
        when :store_ivar
          "store_ivar #{insn.data}, #{value(insn.opnds[0])}"
        when :store_lvar
          "store_lvar #{local_ref(insn.data)}, #{value(insn.opnds[0])}"
        when :trace_b_call
          "trace_b_call"
        when :trace_b_return
          "trace_b_return #{insn.opnds.map { |id| value(id) }.join(', ')}"
        when :trace_call
          "trace_call"
        when :trace_class
          "trace_class"
        when :trace_end
          "trace_end"
        when :trace_line
          "trace_line #{insn.data}"
        when :trace_return
          "trace_return #{insn.opnds.map { |id| value(id) }.join(', ')}"
        when :yield
          opnds = insn.opnds
          "#{value(opnds[0])} = yield#{values(opnds[1..])}"
        when :undef_method
          "undef_method #{insn.opnds.map { |id| value(id) }.join(', ')}"
        else
          opnds = insn.opnds
          "#{value(opnds[0])} = #{insn.kind}#{values(opnds[1..])}"
        end
      end
    end

    class VM
      class Locals
        attr_reader :parent

        def initialize(locals, parent = nil)
          @locals = locals.to_h { |local| [local.id, nil] }
          @parent = parent
        end

        def [](id)
          if @locals.key?(id)
            @locals.fetch(id)
          elsif parent
            parent[id]
          else
            raise KeyError, "unknown local: #{id}"
          end
        end

        def []=(id, value)
          if @locals.key?(id)
            @locals[id] = value
          elsif parent
            parent[id] = value
          else
            raise KeyError, "unknown local: #{id}"
          end
        end
      end

      class Frame
        attr_reader :graph, :recv, :nest, :locals, :values, :block

        def initialize(graph, recv, nest, locals = Locals.new(graph.locals), &block)
          @graph = graph
          @recv = recv
          @nest = nest
          @locals = locals
          @values = Array.new(graph.nvalues)
          @block = block
        end
      end

      def initialize
        @post_executions = Set.new.compare_by_identity
      end

      def run(unit)
        run_frame(Frame.new(unit.graphs[0], TOPLEVEL_BINDING.receiver, [Object].freeze))
      end

      def run_frame(frame, args = [])
        graph = frame.graph
        recv = frame.recv
        nest = frame.nest
        locals = frame.locals
        values = frame.values
        block = graph.blocks[0]

        signature = graph.signature

        if signature.autosplat && args.length == 1
          args = Array.try_convert(args[0]) || args
        end

        if graph.kind != :block
          required = signature.requireds.length
          if signature.rest ? args.length < required : args.length != required
            expected = signature.rest ? "#{required}+" : required
            raise ArgumentError, "wrong number of arguments (given #{args.length}, expected #{expected})"
          end
        end

        signature.requireds.zip(args) { |param, value| values[param] = value }
        values[signature.rest] = args.drop(signature.requireds.length) if signature.rest

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
              values[insn.opnds[0]] = values[insn.opnds[1]].__send__(insn.data, *values.values_at(*insn.opnds[2..]))
            when :call_with_block
              values[insn.opnds[0]] = values[insn.opnds[1]].__send__(insn.data, *values.values_at(*insn.opnds[2...-1]), &values[insn.opnds[-1]])
            when :coerce_array
              value = values[insn.opnds[1]]
              values[insn.opnds[0]] = Array.try_convert(value) || [value]
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
              values[insn.opnds[0]] = run_frame(Frame.new(class_graph, klass, [klass, *nest].freeze))
            when :define_class_abs_super
              name, class_graph = insn.data
              superclass = values[insn.opnds[1]]
              check_superclass(superclass)
              klass = define_class_super(Object, name, true, superclass)
              values[insn.opnds[0]] = run_frame(Frame.new(class_graph, klass, [klass, *nest].freeze))
            when :define_class_nest_rel
              name, class_graph = insn.data
              klass = define_class(nest[0], name, false)
              values[insn.opnds[0]] = run_frame(Frame.new(class_graph, klass, [klass, *nest].freeze))
            when :define_class_nest_rel_super
              name, class_graph = insn.data
              superclass = values[insn.opnds[1]]
              check_superclass(superclass)
              klass = define_class_super(nest[0], name, false, superclass)
              values[insn.opnds[0]] = run_frame(Frame.new(class_graph, klass, [klass, *nest].freeze))
            when :define_class_recv_rel
              name, class_graph = insn.data
              parent = values[insn.opnds[1]]
              check_module(parent)
              klass = define_class(parent, name, true)
              values[insn.opnds[0]] = run_frame(Frame.new(class_graph, klass, [klass, *nest].freeze))
            when :define_class_recv_rel_super
              name, class_graph = insn.data
              parent = values[insn.opnds[1]]
              superclass = values[insn.opnds[2]]
              check_superclass(superclass)
              check_module(parent)
              klass = define_class_super(parent, name, true, superclass)
              values[insn.opnds[0]] = run_frame(Frame.new(class_graph, klass, [klass, *nest].freeze))
            when :define_method
              name, method_graph = insn.data
              vm = self
              Module.instance_method(:define_method).bind_call(nest[0], name) { |*args, &block| vm.run_frame(Frame.new(method_graph, self, nest, &block), args) }
              Module.instance_method(:private).bind_call(nest[0], name) if graph.kind == :program
            when :define_module_abs
              name, module_graph = insn.data
              mod = define_module(Object, name, true)
              values[insn.opnds[0]] = run_frame(Frame.new(module_graph, mod, [mod, *nest].freeze))
            when :define_module_nest_rel
              name, module_graph = insn.data
              mod = define_module(nest[0], name, false)
              values[insn.opnds[0]] = run_frame(Frame.new(module_graph, mod, [mod, *nest].freeze))
            when :define_module_recv_rel
              name, module_graph = insn.data
              parent = values[insn.opnds[1]]
              check_module(parent)
              mod = define_module(parent, name, true)
              values[insn.opnds[0]] = run_frame(Frame.new(module_graph, mod, [mod, *nest].freeze))
            when :define_singleton_class
              klass = Kernel.instance_method(:singleton_class).bind_call(values[insn.opnds[1]])
              values[insn.opnds[0]] = run_frame(Frame.new(insn.data, klass, [klass, *nest].freeze))
            when :define_singleton_method
              name, method_graph = insn.data
              klass = Kernel.instance_method(:singleton_class).bind_call(values[insn.opnds[0]])
              vm = self
              Module.instance_method(:define_method).bind_call(klass, name) { |*args, &block| vm.run_frame(Frame.new(method_graph, self, nest, &block), args) }
            when :defined_const_abs
              values[insn.opnds[0]] = const_defined_recv_rel?(Object, insn.data)
            when :defined_const_nest_rel
              values[insn.opnds[0]] = nest[0...-1].any? { |scope| scope.const_defined?(insn.data, false) } || nest[0].const_defined?(insn.data)
            when :defined_const_recv_rel
              values[insn.opnds[0]] = const_defined_recv_rel?(values[insn.opnds[1]], insn.data)
            when :defined_cvar
              values[insn.opnds[0]] = Module.instance_method(:class_variable_defined?).bind_call(cvar_parent(nest) || nest[-1], insn.data)
            when :defined_gvar
              values[insn.opnds[0]] = !eval("defined?(#{insn.data})", TOPLEVEL_BINDING).nil?
            when :extract_last_match_group, :extract_last_match_named_group
              values[insn.opnds[0]] = values[insn.opnds[1]]&.[](insn.data)
            when :extract_last_match_match
              values[insn.opnds[0]] = values[insn.opnds[1]]&.[](0)
            when :extract_last_match_paren
              values[insn.opnds[0]] = values[insn.opnds[1]]&.captures&.reverse_each&.find(&:itself)
            when :extract_last_match_post
              values[insn.opnds[0]] = values[insn.opnds[1]]&.post_match
            when :extract_last_match_pre
              values[insn.opnds[0]] = values[insn.opnds[1]]&.pre_match
            when :nil_p
              values[insn.opnds[0]] = NilClass === values[insn.opnds[1]]
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
              values[insn.opnds[0]] = locals[insn.data.id]
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
            when :new_block
              values[insn.opnds[0]] = new_block(insn.data, frame)
            when :new_hash
              values[insn.opnds[0]] = values.values_at(*insn.opnds[1..]).each_slice(2).to_h
            when :new_hash_static
              values[insn.opnds[0]] = insn.data.dup
            when :new_range_exc
              values[insn.opnds[0]] = (values[insn.opnds[1]]...values[insn.opnds[2]])
            when :new_range_inc
              values[insn.opnds[0]] = (values[insn.opnds[1]]..values[insn.opnds[2]])
            when :new_regexp
              values[insn.opnds[0]] = Regexp.new(values.values_at(*insn.opnds[1..]).join, (insn.data >> 2) & 7)
            when :new_string
              values[insn.opnds[0]] = values.values_at(*insn.opnds[1..]).join
            when :new_symbol
              values[insn.opnds[0]] = values.values_at(*insn.opnds[1..]).join.to_sym
            when :post_execution
              if @post_executions.add?(insn.data)
                at_exit { run_frame(Frame.new(insn.data, recv, nest, locals)) }
              end
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
              locals[insn.data.id] = values[insn.opnds[0]]
            when :trace_b_call, :trace_b_return, :trace_call, :trace_class, :trace_end, :trace_line, :trace_return
              # ignore
            when :undef_method
              Module.instance_method(:undef_method).bind_call(nest[0], values[insn.opnds[0]])
            when :yield
              raise LocalJumpError, "no block given (yield)" unless frame.block
              values[insn.opnds[0]] = frame.block.call
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

      def new_block(graph, frame)
        vm = self
        locals = frame.locals
        nest = frame.nest
        block = frame.block

        BasicObject.instance_method(:instance_exec).bind_call(frame.recv) do
          Proc.new do |*args|
            block_locals = graph.scope.equal?(graph) ? Locals.new(graph.locals, locals) : locals
            vm.run_frame(Frame.new(graph, self, nest, block_locals, &block), args)
          end
        end
      end

      ###

      def define_module(parent, name, check_public)
        if parent.const_defined?(name, false)
          check_public_const(parent, parent, name) if check_public
          const = parent.const_get(name, false)
          unless Module === const && !(Class === const)
            message = +"#{name} is not a module"
            if (location = parent.const_source_location(name, false))
              message << "\n#{location[0]}:#{location[1]}: previous definition of #{name} was here"
            end
            raise TypeError, message
          end
          const
        else
          parent.const_set(name, Module.new)
        end
      end

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

      def const_defined_recv_rel?(recv, name)
        check_module(recv)
        owner = recv.ancestors.find { |ancestor| ancestor.const_defined?(name, false) }
        return false if owner.nil? || (owner == Object && recv != Object)

        owner.constants(false).include?(name)
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
