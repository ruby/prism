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

    class Runner
      def run_unit(unit)
        run_graph(unit.graphs[0])
      end

      def run_graph(graph)
        values = []
        locals = graph.locals.to_h { |local| [local.name, nil] }
        block = graph.blocks[0]

        while true
          block.insns.each do |insn|
            case insn.kind
            when :alias_method
              raise "todo"
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
            when :call_to_s
              values[insn.opnds[0]] = values[insn.opnds[1]].to_s
            when :coerce_hash
              value = values[insn.opnds[1]]
              values[insn.opnds[0]] = value.nil? ? {} : value.to_hash
            when :convert_to_string
              values[insn.opnds[0]] = values[insn.opnds[2]].is_a?(String) ? values[insn.opnds[2]] : Kernel.instance_method(:to_s).bind_call(values[insn.opnds[1]])
            when :define_class_abs
              raise "todo"
            when :define_class_nest_rel
              raise "todo"
            when :define_class_recv_rel
              raise "todo"
            when :define_method
              raise "todo"
            when :define_singleton_class
              raise "todo"
            when :defined_cvar
              raise "todo"
            when :defined_gvar
              raise "todo"
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
              values[insn.opnds[0]] = insn.data.inject(Object) { |accum, name| accum.const_get(name) }
            when :load_const_nest_rel
              values[insn.opnds[0]] = insn.data.inject(self.class) { |accum, name| accum.const_get(name) }
            when :load_const_recv_rel
              values[insn.opnds[0]] = insn.data.inject(values[insn.opnds[1]]) { |accum, name| accum.const_get(name) }
            when :load_cvar
              values[insn.opnds[0]] = Object.class_variable_get(insn.data)
            when :load_gvar
              values[insn.opnds[0]] = eval(insn.data.name, TOPLEVEL_BINDING)
            when :load_ivar
              values[insn.opnds[0]] = instance_variable_get(insn.data)
            when :load_last_match
              values[insn.opnds[0]] = $~
            when :load_lvar
              values[insn.opnds[0]] = locals[insn.data]
            when :load_self
              values[insn.opnds[0]] = self
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
              Object.const_set(insn.data.join("::"), values[insn.opnds[0]])
            when :store_const_nest_rel
              self.class.const_set(insn.data.join("::"), values[insn.opnds[0]])
            when :store_const_recv_rel
              values[insn.opnds[0]].const_set(insn.data.join("::"), values[insn.opnds[1]])
            when :store_cvar
              Object.class_variable_set(insn.data, values[insn.opnds[0]])
            when :store_ivar
              instance_variable_set(insn.data, values[insn.opnds[0]])
            when :store_gvar
              eval("#{insn.data} = value", TOPLEVEL_BINDING.tap { |binding| binding.local_variable_set(:value, values[insn.opnds[0]]) })
            when :store_lvar
              locals[insn.data] = values[insn.opnds[0]]
            when :trace_call, :trace_class, :trace_end, :trace_line, :trace_return
              # ignore
            when :undef_method
              raise "todo"
            else
              raise "Unknown instruction kind: #{insn.kind}"
            end
          end
        end
      end
    end
  end
end
