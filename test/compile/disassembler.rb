# frozen_string_literal: true

require_relative "../../lib/prism"

module Prism
  module Compile
    class Disassembler
      def initialize(unit)
        @unit = unit
      end

      def disasm
        @unit.graphs.each_with_object(+"") do |graph, output|
          context = [graph.kind]
          context << "parent=#{graph_ref(graph.parent)}" if graph.parent
          context << "scope=#{graph_ref(graph.scope)}"
          context << "flip_flops=#{graph.nflip_flops}" if graph.nflip_flops > 0
          signature = graph.signature
          params = signature.requireds.map { |id| value(id) }
          signature.optionals.zip(signature.optional_specifieds) { |id, specified| params << "#{value(id)}?#{value(specified)}" }
          params << "*#{value(signature.rest)}" if signature.rest
          params.concat(signature.posts.map { |id| value(id) })
          signature.required_keywords.each { |name, id| params << "#{name}: #{value(id)}" }
          signature.optional_keywords.each { |name, id| params << "#{name}: #{value(id)}?#{value(signature.optional_keyword_specifieds.fetch(name))}" }
          params << "**#{value(signature.keyword_rest)}" if signature.keyword_rest
          params << "**nil" if signature.no_keywords
          params << "&#{value(signature.block)}" if signature.block
          params << "&nil" if signature.no_block
          output << "#{graph_ref(graph)}#{params.empty? ? "" : "(#{params.join(', ')})"}#{signature.autosplat ? " [autosplat]" : ""} (#{context.join(', ')}):\n"

          graph.regions.each do |region|
            context = [region.kind]
            context << "parent=r#{region.parent.id}" if region.parent
            context << "entry=#{block_ref(region.entry)}"
            context << "handler=#{block_ref(region.handler)}" if region.handler
            output << "  r#{region.id} (#{context.join(', ')}):\n"
          end

          graph.blocks.each do |block|
            output << "  #{block_ref(block)}#{values(block.params)}: [region=r#{block.region.id}]\n"
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

      def call_flags(info)
        flags = []
        flags << "ignore_visibility" if info.ignore_visibility
        flags << "variable_call" if info.variable_call
        flags << "block_argument" if info.block_argument
        flags.empty? ? "" : " [#{flags.join(', ')}]"
      end

      def instruction(insn)
        case insn.kind
        when :alias_gvar
          "alias_gvar #{insn.opnds.map { |id| value(id) }.join(', ')}"
        when :alias_method
          "alias_method #{insn.opnds.map { |id| value(id) }.join(', ')}"
        when :any_truthy
          opnds = insn.opnds
          "#{value(opnds[0])} = any_truthy#{values(opnds[1..])}"
        when :branch
          "branch #{block_ref(insn.data)}#{values(insn.opnds)}"
        when :branch_if
          opnds = insn.opnds
          then_block, else_block, then_count = insn.data
          "branchif #{value(opnds[0])} #{block_ref(then_block)}#{values(opnds[1, then_count])} #{block_ref(else_block)}#{values(opnds[(then_count + 1)..])}"
        when :break
          "break#{values(insn.opnds)}"
        when :call
          opnds = insn.opnds
          data = insn.data
          arguments = data.block ? opnds[2...-1] : opnds[2..]
          "#{value(opnds[0])} = call #{value(opnds[1])}.#{data.name}#{values(arguments)}#{data.splat ? " [splat]" : ""}#{data.keywords ? " [keywords]" : ""}#{data.block ? " &#{value(opnds[-1])}" : ""}#{call_flags(data)}"
        when :coerce_array_to_a
          opnds = insn.opnds
          "#{value(opnds[0])} = coerce_array_to_a#{values(opnds[1..])}"
        when :coerce_array_to_ary
          opnds = insn.opnds
          "#{value(opnds[0])} = coerce_array_to_ary#{values(opnds[1..])}"
        when :coerce_hash
          opnds = insn.opnds
          "#{value(opnds[0])} = coerce_hash#{values(opnds[1..])}"
        when :coerce_string
          opnds = insn.opnds
          "#{value(opnds[0])} = coerce_string#{values(opnds[1..])}"
        when :concat_array
          opnds = insn.opnds
          "#{value(opnds[0])} = concat_array#{values(opnds[1..])}"
        when :deconstruct_array
          opnds = insn.opnds
          "#{value(opnds[0])} = deconstruct_array#{values(opnds[1..])}"
        when :deconstruct_hash
          opnds = insn.opnds
          "#{value(opnds[0])} = deconstruct_hash#{values(opnds[1..])}"
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
        when :defined_implicit_method
          "#{value(insn.opnds[0])} = defined_implicit_method(#{value(insn.opnds[1])}, #{insn.data})"
        when :defined_gvar
          "#{value(insn.opnds[0])} = defined_gvar #{insn.data}"
        when :defined_ivar
          "#{value(insn.opnds[0])} = defined_ivar #{insn.data}"
        when :defined_explicit_method
          "#{value(insn.opnds[0])} = defined_explicit_method(#{value(insn.opnds[1])}, #{insn.data})"
        when :defined_super
          "#{value(insn.opnds[0])} = defined_super"
        when :ensure_return
          "ensure_return r#{insn.data.id}"
        when :ensure_shareable
          opnds = insn.opnds
          "#{value(opnds[0])} = ensure_shareable#{values(opnds[1..])}, #{literal(insn.data)}"
        when :expand_array
          opnds = insn.opnds
          lefts, rights, rest = insn.data
          outputs = opnds[1..].map { |id| value(id) }
          "#{outputs.empty? ? "" : "#{outputs.join(', ')} = "}expand_array #{value(opnds[0])}, lefts=#{lefts}, rights=#{rights}, rest=#{rest}"
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
        when :load_block
          "#{value(insn.opnds[0])} = load_block"
        when :load_cvar
          "#{value(insn.opnds[0])} = load_cvar #{insn.data}"
        when :load_flip_flop
          "#{value(insn.opnds[0])} = load_flip_flop #{insn.data}"
        when :load_gvar
          "#{value(insn.opnds[0])} = load_gvar #{insn.data}"
        when :load_ivar
          "#{value(insn.opnds[0])} = load_ivar #{insn.data}"
        when :load_last_match
          opnds = insn.opnds
          "#{value(opnds[0])} = load_last_match#{values(opnds[1..])}"
        when :load_last_match_group
          opnds = insn.opnds
          "#{value(opnds[0])} = load_last_match_group #{value(opnds[1])}, group=#{insn.data}"
        when :load_last_match_match
          opnds = insn.opnds
          "#{value(opnds[0])} = load_last_match_match#{values(opnds[1..])}"
        when :load_last_match_named_group
          opnds = insn.opnds
          "#{value(opnds[0])} = load_last_match_named_group(#{value(opnds[1])}, #{insn.data})"
        when :load_last_match_paren
          opnds = insn.opnds
          "#{value(opnds[0])} = load_last_match_paren#{values(opnds[1..])}"
        when :load_last_match_post
          opnds = insn.opnds
          "#{value(opnds[0])} = load_last_match_post#{values(opnds[1..])}"
        when :load_last_match_pre
          opnds = insn.opnds
          "#{value(opnds[0])} = load_last_match_pre#{values(opnds[1..])}"
        when :load_lvar
          "#{value(insn.opnds[0])} = load_lvar #{local_ref(insn.data)}"
        when :load_object
          "#{value(insn.opnds[0])} = load_object(#{literal(insn.data)})"
        when :load_self
          opnds = insn.opnds
          "#{value(opnds[0])} = load_self#{values(opnds[1..])}"
        when :make_shareable
          opnds = insn.opnds
          "#{value(opnds[0])} = make_shareable#{values(opnds[1..])}"
        when :make_shareable_copy
          opnds = insn.opnds
          "#{value(opnds[0])} = make_shareable_copy#{values(opnds[1..])}"
        when :match
          opnds = insn.opnds
          "#{value(opnds[0])} = match#{values(opnds[1..])}"
        when :match_array
          opnds = insn.opnds
          "#{value(opnds[0])} = match_array#{values(opnds[1..])}"
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
          "#{value(opnds[0])} = new_regexp#{values(opnds[1..])} flags=#{insn.data.flags}"
        when :new_string
          opnds = insn.opnds
          "#{value(opnds[0])} = new_string#{values(opnds[1..])}"
        when :new_symbol
          opnds = insn.opnds
          "#{value(opnds[0])} = new_symbol#{values(opnds[1..])}"
        when :once
          site, region = insn.data
          "#{value(insn.opnds[0])} = once @site#{site.id}, r#{region.id}"
        when :once_return
          "once_return r#{insn.data.id}#{values(insn.opnds)}"
        when :post_execution
          "post_execution #{graph_ref(insn.data)}"
        when :raise_pattern_deconstruct
          "raise_pattern_deconstruct#{values(insn.opnds)}"
        when :raise_pattern_deconstruct_keys
          "raise_pattern_deconstruct_keys#{values(insn.opnds)}"
        when :raise_pattern_empty
          "raise_pattern_empty#{values(insn.opnds)}"
        when :raise_pattern_find
          "raise_pattern_find#{values(insn.opnds)}"
        when :raise_pattern_guard
          "raise_pattern_guard#{values(insn.opnds)}"
        when :raise_pattern_key
          "raise_pattern_key#{values(insn.opnds)}"
        when :raise_pattern_length
          "raise_pattern_length#{values(insn.opnds)}"
        when :raise_pattern_min_length
          "raise_pattern_min_length#{values(insn.opnds)}"
        when :raise_pattern_mismatch
          "raise_pattern_mismatch#{values(insn.opnds)}"
        when :raise_pattern_nomatch
          "raise_pattern_nomatch#{values(insn.opnds)}"
        when :raise_pattern_rest_empty
          "raise_pattern_rest_empty#{values(insn.opnds)}"
        when :reraise
          "reraise"
        when :rescue_match
          opnds = insn.opnds
          "#{value(opnds[0])} = rescue_match#{values(opnds[1..])}"
        when :rescue_match_array
          opnds = insn.opnds
          "#{value(opnds[0])} = rescue_match_array#{values(opnds[1..])}"
        when :return
          "return"
        when :return_nonlocal
          "return_nonlocal #{value(insn.opnds[0])}"
        when :return_value
          "return_value #{value(insn.opnds[0])}"
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
        when :store_flip_flop
          "store_flip_flop #{insn.data}, #{value(insn.opnds[0])}"
        when :store_gvar
          "store_gvar #{insn.data}, #{value(insn.opnds[0])}"
        when :store_ivar
          "store_ivar #{insn.data}, #{value(insn.opnds[0])}"
        when :store_lvar
          "store_lvar #{local_ref(insn.data)}, #{value(insn.opnds[0])}"
        when :call_super
          opnds = insn.opnds
          data = insn.data
          "#{value(opnds[0])} = call_super#{values(opnds[1...-1])}#{data.splat ? " [splat]" : ""}#{data.keywords ? " [keywords]" : ""} &#{value(opnds[-1])}#{call_flags(data)}"
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
        when :trace_rescue
          "trace_rescue"
        when :trace_return
          "trace_return #{insn.opnds.map { |id| value(id) }.join(', ')}"
        when :yield
          opnds = insn.opnds
          data = insn.data
          "#{value(opnds[0])} = yield#{values(opnds[1..])}#{data.splat ? " [splat]" : ""}#{data.keywords ? " [keywords]" : ""}"
        when :undef_method
          "undef_method #{insn.opnds.map { |id| value(id) }.join(', ')}"
        else
          opnds = insn.opnds
          "#{value(opnds[0])} = #{insn.kind}#{values(opnds[1..])}"
        end
      end
    end
  end
end
