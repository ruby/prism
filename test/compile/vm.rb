# frozen_string_literal: true

require_relative "../../lib/prism"
require "set"

module Prism
  module Compile
    class VM
      module StdLib
        @methods = {}

        class << self
          def [](method_name)
            @methods.fetch(method_name)
          end

          def lambda_method?(method)
            method == self[:Kernel_lambda] || method == self[:Kernel_singleton_lambda]
          end

          def visibility_for(method)
            case method
            when self[:Module_public] then :public
            when self[:Module_protected] then :protected
            when self[:Module_private] then :private
            when self[:Module_module_function] then :module_function
            when self[:main_singleton_public] then :public
            when self[:main_singleton_private] then :private
            end
          end

          def visibility_method_for(kind)
            case kind
            when :public then self[:Module_public]
            when :protected then self[:Module_protected]
            when :private then self[:Module_private]
            when :module_function then self[:Module_module_function]
            else raise
            end
          end

          private

          def instance_methods(owner, owner_name, method_names)
            method_names.each do |method_name|
              @methods[:"#{owner_name}_#{method_name}"] = owner.instance_method(method_name)
            end
          end

          def singleton_methods(owner, owner_name, method_names)
            method_names.each do |method_name|
              @methods[:"#{owner_name}_singleton_#{method_name}"] = owner.method(method_name).unbind
            end
          end
        end

        instance_methods(Array, "Array", %i[+ to_a])
        instance_methods(BasicObject, "BasicObject", %i[equal? __send__ instance_exec])
        instance_methods(Binding, "Binding", %i[eval])
        instance_methods(Class, "Class", %i[superclass])
        instance_methods(Hash, "Hash", %i[merge])
        singleton_methods(Hash, "Hash", %i[ruby2_keywords_hash?])
        instance_methods(Kernel, "Kernel", %i[class instance_variable_defined? instance_variable_get instance_variable_set lambda method public_send respond_to? singleton_class sprintf to_s])
        singleton_methods(Kernel, "Kernel", %i[lambda])
        singleton_methods(TOPLEVEL_BINDING.receiver, "main", %i[private public])
        instance_methods(Module, "Module", %i[=== alias_method ancestors class_variable_defined? class_variable_get class_variable_set const_defined? const_get const_set const_source_location constants define_method instance_method module_function private private_method_defined? protected protected_method_defined? public public_method_defined? singleton_class? undef_method])
      end

      class Visibility
        attr_accessor :value

        def initialize(value = :public)
          @value = value
        end
      end

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

      class Block
        attr_accessor :active
        attr_reader :graph, :frame

        def initialize(callable, graph, frame)
          @graph = graph
          @frame = frame
          @callable = callable
          @active = false
        end

        def to_proc
          @callable
        end
      end

      class MatchState
        def initialize
          @matches = ObjectSpace::WeakKeyMap.new
        end

        def value
          @matches[Fiber.current]
        end

        def value=(value)
          @matches[Fiber.current] = value
        end
      end

      class Frame
        attr_reader :graph, :recv, :nest, :locals, :values, :flip_flops, :super_method, :block, :break_target, :return_target, :visibility, :lambda, :match_state
        attr_accessor :last_line, :return_fiber, :native_binding, :native_match

        def initialize(graph, recv, nest, locals = Locals.new(graph.locals), flip_flops = Array.new(graph.nflip_flops, false), super_method = nil, visibility = Visibility.new(graph.kind == :program ? :private : :public), break_target = nil, return_target = nil, lambda = graph.kind == :lambda, match_state = MatchState.new, &block)
          @graph = graph
          @recv = recv
          @nest = nest
          @locals = locals
          @values = Array.new(graph.nvalues)
          @match_state = match_state
          @last_line = nil
          @native_binding = nil
          @native_match = nil
          @flip_flops = flip_flops
          @lambda = lambda
          @return_target = lambda || %i[def program].include?(graph.kind) ? self : return_target
          @return_fiber = nil
          @break_target = break_target
          @super_method = super_method
          @visibility = visibility
          @block = block
        end

        def last_match
          match_state.value
        end

        def last_match=(value)
          match_state.value = value
        end
      end

      class MethodDefinition
        SIGNATURES = ObjectSpace::WeakKeyMap.new

        def self.arity(method)
          signature = SIGNATURES[method]
          signature ? signature.arity : method.arity
        end

        def initialize(vm, graph, nest)
          @vm = vm
          @graph = graph
          @nest = nest
        end

        def define(parent, name)
          definition = self

          if @graph.signature.ruby2_keywords_eligible?
            StdLib[:Module_define_method].bind_call(
              parent,
              name,
              StdLib[:Binding_eval].bind_call(binding, <<~RUBY)
                Proc.new do |*args, &block|
                  super_method = ->(forwarded_args, forwarded_kwargs, forwarded_block) { super(*forwarded_args, **forwarded_kwargs, &forwarded_block) }
                  definition.call(self, args, {}, super_method, &block)
                end
              RUBY
            )
          else
            StdLib[:Module_define_method].bind_call(parent, name) do |*args, **kwargs, &block|
              super_method = ->(forwarded_args, forwarded_kwargs, forwarded_block) { super(*forwarded_args, **forwarded_kwargs, &forwarded_block) }
              definition.call(self, args, kwargs, super_method, &block)
            end
          end

          @method = StdLib[:Module_instance_method].bind_call(parent, name)
          SIGNATURES[@method] = @graph.signature
        end

        def call(receiver, args, kwargs, super_method, &block)
          locals = Locals.new(@graph.locals)
          flip_flops = Array.new(@graph.nflip_flops, false)
          @vm.run_frame(Frame.new(@graph, receiver, @nest, locals, flip_flops, super_method, &block), args, kwargs)
        end
      end

      class OnceState
        def initialize
          @mutex = Mutex.new
          @condition = ConditionVariable.new
          @owner = nil
          @completed = false
          @value = nil
        end

        def run(region)
          Thread.handle_interrupt(Exception => :never) do
            initializing = false
            begin
              @mutex.synchronize do
                loop do
                  return ExecutionResult.new(nil, @value, region) if @completed
                  if @owner.nil?
                    @owner = Thread.current
                    initializing = true
                    break
                  elsif @owner.equal?(Thread.current)
                    break
                  else
                    Thread.handle_interrupt(Exception => :on_blocking) { @condition.wait(@mutex) }
                  end
                end
              end

              result = Thread.handle_interrupt(Exception => :immediate) { yield }
              if initializing && result.region.equal?(region)
                @mutex.synchronize do
                  @value = result.value
                  @completed = true
                end
              end
              result
            ensure
              if initializing
                @mutex.synchronize do
                  @owner = nil
                  @condition.broadcast
                end
              end
            end
          end
        end
      end

      class ExecutionResult
        attr_reader :block, :value, :region

        def initialize(block, value, region = nil)
          @block = block
          @value = value
          @region = region
        end
      end

      def initialize
        @post_executions = Set.new.compare_by_identity
        @once_states = ObjectSpace::WeakKeyMap.new
        @frames = ObjectSpace::WeakKeyMap.new
        @once_mutex = Mutex.new
      end

      def compile(source, filepath = "(eval)", options = {})
        result = Prism.compile(source, filepath: filepath, raise_error: true, **options)
        result.warnings.each do |warning|
          next if warning.level == :verbose && !$VERBOSE
          warn "#{filepath}:#{warning.location.start_line}: warning: #{warning.message}"
        end
        result
      end

      def run(unit)
        run_frame(Frame.new(unit.graphs[0], TOPLEVEL_BINDING.receiver, [Object].freeze))
      end

      def run_frame(frame, args = [], kwargs = {}, passed_block = frame.block)
        frames = @frames[Fiber.current] ||= []
        frames << frame
        graph = frame.graph
        values = frame.values
        block = graph.blocks[0]

        signature = graph.signature
        values[signature.block] = passed_block if signature.block

        raise ArgumentError, "no keywords accepted" if signature.no_keywords && !kwargs.empty?

        has_keywords = !signature.required_keywords.empty? || !signature.optional_keywords.empty? || signature.keyword_rest
        if !has_keywords && !kwargs.empty?
          args = [*args, kwargs]
          kwargs = {}
        end

        if !frame.lambda && signature.autosplat && args.length == 1 && kwargs.empty?
          args = Array.try_convert(args[0]) || args
        end

        required = signature.requireds.length + signature.posts.length
        maximum = required + signature.optionals.length

        if graph.kind == :block && !frame.lambda
          args = args.take(maximum) if !signature.rest && args.length > maximum
        else
          if args.length < required || (!signature.rest && args.length > maximum)
            expected = signature.rest ? "#{required}+" : required == maximum ? required : "#{required}..#{maximum}"
            raise ArgumentError, "wrong number of arguments (given #{args.length}, expected #{expected})"
          end
        end

        if has_keywords
          missing = signature.required_keywords.keys - kwargs.keys
          unless missing.empty?
            raise ArgumentError, "missing keyword#{missing.length == 1 ? '' : 's'}: #{missing.map(&:inspect).join(', ')}"
          end

          unknown = kwargs.keys - signature.required_keywords.keys - signature.optional_keywords.keys
          if !signature.keyword_rest && !unknown.empty?
            raise ArgumentError, "unknown keyword#{unknown.length == 1 ? '' : 's'}: #{unknown.map(&:inspect).join(', ')}"
          end

          if signature.keyword_rest
            values[signature.keyword_rest] = kwargs.reject do |name, _|
              signature.required_keywords.key?(name) || signature.optional_keywords.key?(name)
            end
          end

          signature.required_keywords.each do |name, param|
            values[param] = kwargs.fetch(name)
          end

          signature.optional_keywords.each do |name, param|
            values[param] = kwargs[name]
            values[signature.optional_keyword_specifieds.fetch(name)] = kwargs.key?(name)
          end
        end

        raise ArgumentError, "no block accepted" if signature.no_block && passed_block

        signature.requireds.zip(args) { |param, value| values[param] = value }

        if signature.rest || !signature.posts.empty? || !signature.optionals.empty?
          remaining = args.drop(signature.requireds.length)
          signature.posts.zip(remaining.last(signature.posts.length)) { |param, value| values[param] = value }

          middle = remaining.take([remaining.length - signature.posts.length, 0].max)
          signature.optionals.each_with_index do |param, idx|
            values[param] = middle[idx]
            values[signature.optional_specifieds[idx]] = idx < middle.length
          end

          values[signature.rest] = middle.drop(signature.optionals.length) if signature.rest
        end

        if frame.return_target.equal?(frame)
          frame.return_fiber = Fiber.current
          begin
            catch(frame) { run_region(frame, graph.regions[0], block).value }
          ensure
            frame.return_fiber = nil
          end
        else
          run_region(frame, graph.regions[0], block).value
        end
      ensure
        frames.pop
      end

      private

      def run_region(frame, region, block)
        if region.kind == :ensure
          run_ensure_region(frame, region, block)
        else
          run_blocks(frame, region, block)
        end
      rescue Exception => exception
        if region.kind == :rescue
          handler = region.handler
          frame.values[handler.params[0]] = exception
          run_blocks(frame, handler.region, handler)
        else
          raise
        end
      end

      def run_ensure_region(frame, region, block)
        begin
          result = run_blocks(frame, region, block)
        ensure
          handler = region.handler
          cleanup = run_region(frame, handler.region, handler)
          return cleanup unless cleanup.region.equal?(region)
        end
        result
      end

      def run_blocks(frame, region, block)
        recv = frame.recv
        nest = frame.nest
        locals = frame.locals
        values = frame.values
        flip_flops = frame.flip_flops
        super_method = frame.super_method
        previous_binding = frame.native_binding
        previous_native_match = frame.native_match
        frame.native_binding = binding
        $~ = frame.last_match
        $_ = frame.last_line

        while true
          unless block.region.equal?(region)
            child = block.region
            child = child.parent until child.nil? || child.parent.equal?(region)

            if child
              frame.last_match = $~
              frame.last_line = $_
              result = nil

              begin
                result = run_region(frame, child, block)
              ensure
                $~ = frame.last_match
                $_ = frame.last_line
              end

              if (block = result.block)
                next
              else
                return result
              end
            else
              return ExecutionResult.new(block, nil)
            end
          end

          block.insns.each do |insn|
            previous_match = frame.native_match = frame.last_match = $~
            case insn.kind
            when :alias_gvar
              StdLib[:Binding_eval].bind_call(TOPLEVEL_BINDING, "alias #{values[insn.opnds[0]]} #{values[insn.opnds[1]]}")
            when :alias_method
              StdLib[:Module_alias_method].bind_call(nest[0], values[insn.opnds[0]], values[insn.opnds[1]])
            when :any_truthy
              values[insn.opnds[0]] = values[insn.opnds[1]].any?
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
            when :break
              throw frame, values[insn.opnds[0]] if frame.lambda
              target = frame.break_target
              unless target && target.active
                error = LocalJumpError.new("break from proc-closure")
                StdLib[:Kernel_instance_variable_set].bind_call(error, :@exit_value, values[insn.opnds[0]])
                StdLib[:Kernel_instance_variable_set].bind_call(error, :@reason, :break)
                raise error
              end
              throw target, values[insn.opnds[0]]
            when :call
              call = insn.data
              arguments = values.values_at(*insn.opnds[2..])
              passed_block = call.block ? arguments.pop : nil
              keywords = call.keywords ? arguments.pop : {}
              arguments.concat(arguments.pop) if call.splat
              if call.splat && !call.keywords && Hash === arguments.last && StdLib[:Hash_singleton_ruby2_keywords_hash?].bind_call(Hash, arguments.last)
                keywords = arguments.pop
              end
              receiver = values[insn.opnds[1]]

              if call.ignore_visibility && arguments.empty? && (Module === receiver || StdLib[:BasicObject_equal?].bind_call(receiver, TOPLEVEL_BINDING.receiver)) && (visibility = default_visibility(receiver, call.name))
                frame.visibility.value = visibility
                values[insn.opnds[0]] = nil
                next
              end

              if !call.block_argument && Block === passed_block && arguments.empty? && keywords.empty? && builtin_lambda?(receiver, call.name) && (call.ignore_visibility || StdLib[:Module_public_method_defined?].bind_call(method_lookup_class(receiver), call.name))
                values[insn.opnds[0]] = new_block(passed_block.graph, passed_block.frame, true)
                next
              end

              values[insn.opnds[0]] =
                with_break_target(passed_block) do
                  if call.ignore_visibility || protected_call?(receiver, call.name, recv)
                    StdLib[:BasicObject___send__].bind_call(receiver, call.name, *arguments, **keywords, &passed_block)
                  else
                    StdLib[:Kernel_public_send].bind_call(receiver, call.name, *arguments, **keywords, &passed_block)
                  end
                end
            when :call_super
              raise NoMethodError, "super called outside of method" unless super_method
              call = insn.data
              arguments = values.values_at(*insn.opnds[1...-1])
              keywords = call.keywords ? arguments.pop : {}
              arguments.concat(arguments.pop) if call.splat
              if call.splat && !call.keywords && Hash === arguments.last && StdLib[:Hash_singleton_ruby2_keywords_hash?].bind_call(Hash, arguments.last)
                keywords = arguments.pop
              end
              passed_block = values[insn.opnds[-1]]

              values[insn.opnds[0]] =
                with_break_target(passed_block) do
                  StdLib[:BasicObject_instance_exec].bind_call(recv, arguments, keywords, passed_block, &super_method)
                end
            when :coerce_array_to_a
              values[insn.opnds[0]] = [*values[insn.opnds[1]]]
            when :coerce_array_to_ary
              value = values[insn.opnds[1]]
              values[insn.opnds[0]] = Array.try_convert(value) || [value]
            when :coerce_hash
              value = values[insn.opnds[1]]
              values[insn.opnds[0]] = NilClass === value ? {} : {}.update(value)
            when :coerce_string
              value = values[insn.opnds[1]]
              string = StdLib[:BasicObject___send__].bind_call(value, :to_s)
              values[insn.opnds[0]] = String === string ? string : StdLib[:Kernel_to_s].bind_call(value)
            when :concat_array
              values[insn.opnds[0]] = StdLib[:"Array_+"].bind_call(values[insn.opnds[1]], values[insn.opnds[2]])
            when :deconstruct_array
              value = values[insn.opnds[1]]
              if value.respond_to?(:deconstruct)
                array = StdLib[:BasicObject___send__].bind_call(value, :deconstruct)
                raise TypeError, "deconstruct must return Array" unless Array === array
                values[insn.opnds[0]] = array
              else
                values[insn.opnds[0]] = false
              end
            when :deconstruct_hash
              value = values[insn.opnds[1]]
              if value.respond_to?(:deconstruct_keys)
                hash = StdLib[:BasicObject___send__].bind_call(value, :deconstruct_keys, values[insn.opnds[2]])
                raise TypeError, "deconstruct_keys must return Hash" unless Hash === hash
                values[insn.opnds[0]] = hash
              else
                values[insn.opnds[0]] = false
              end
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
              define_method(nest[0], name, method_graph, nest)

              if frame.visibility.value == :module_function
                StdLib.visibility_method_for(:module_function).bind_call(nest[0], name)
                next
              end

              visibility =
                case name
                when :initialize, :initialize_copy, :initialize_dup, :initialize_clone, :respond_to_missing?
                  StdLib[:Module_singleton_class?].bind_call(nest[0]) ? frame.visibility.value : :private
                else
                  frame.visibility.value
                end

              StdLib.visibility_method_for(visibility).bind_call(nest[0], name) if visibility != :public
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
              klass = StdLib[:Kernel_singleton_class].bind_call(values[insn.opnds[1]])
              values[insn.opnds[0]] = run_frame(Frame.new(insn.data, klass, [klass, *nest].freeze))
            when :define_singleton_method
              name, method_graph = insn.data
              klass = StdLib[:Kernel_singleton_class].bind_call(values[insn.opnds[0]])
              define_method(klass, name, method_graph, nest)
            when :defined_const_abs
              values[insn.opnds[0]] = const_defined_recv_rel?(Object, insn.data)
            when :defined_const_nest_rel
              values[insn.opnds[0]] = nest[0...-1].any? { |scope| StdLib[:Module_const_defined?].bind_call(scope, insn.data, false) } || StdLib[:Module_const_defined?].bind_call(nest[0], insn.data)
            when :defined_const_recv_rel
              values[insn.opnds[0]] = const_defined_recv_rel?(values[insn.opnds[1]], insn.data)
            when :defined_cvar
              values[insn.opnds[0]] = StdLib[:Module_class_variable_defined?].bind_call(cvar_parent(nest) || nest[-1], insn.data)
            when :defined_implicit_method
              values[insn.opnds[0]] = !!defined_implicit_method?(values[insn.opnds[1]], insn.data)
            when :defined_gvar
              values[insn.opnds[0]] = !StdLib[:Binding_eval].bind_call(binding, "defined?(#{insn.data})").nil?
            when :defined_ivar
              values[insn.opnds[0]] = StdLib[:Kernel_instance_variable_defined?].bind_call(recv, insn.data)
            when :defined_explicit_method
              values[insn.opnds[0]] = !!defined_explicit_method?(values[insn.opnds[1]], insn.data, recv)
            when :defined_super
              values[insn.opnds[0]] = !!(super_method && StdLib[:Binding_eval].bind_call(super_method.binding, "defined?(super)"))
            when :ensure_return
              return ExecutionResult.new(nil, nil, insn.data)
            when :ensure_shareable
              value = values[insn.opnds[1]]
              unless Ractor.shareable?(value)
                raise Ractor::IsolationError, "cannot assign unshareable object to #{insn.data}"
              end
              values[insn.opnds[0]] = value
            when :expand_array
              lefts, rights, rest = insn.data
              array = StdLib[:Array_to_a].bind_call(values[insn.opnds[0]])

              leading = array.take(lefts)
              leading.fill(nil, leading.length...lefts)

              remaining = array.drop(lefts)
              trailing = remaining.last(rights)
              trailing.fill(nil, trailing.length...rights)

              leading << remaining.take([remaining.length - rights, 0].max) if rest

              insn.opnds[1..].zip(leading.concat(trailing)) { |opnd, element| values[opnd] = element }
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
            when :load_block
              values[insn.opnds[0]] = frame.block
            when :load_cvar
              parent = cvar_parent(nest)
              check_cvar_parent(parent)
              values[insn.opnds[0]] = StdLib[:Module_class_variable_get].bind_call(parent, insn.data)
            when :load_flip_flop
              values[insn.opnds[0]] = flip_flops[insn.data]
            when :load_gvar
              values[insn.opnds[0]] = StdLib[:Binding_eval].bind_call(binding, insn.data.name)
            when :load_ivar
              values[insn.opnds[0]] = StdLib[:Kernel_instance_variable_get].bind_call(recv, insn.data)
            when :load_last_match
              values[insn.opnds[0]] = $~
            when :load_last_match_group, :load_last_match_named_group
              values[insn.opnds[0]] = values[insn.opnds[1]]&.[](insn.data)
            when :load_last_match_match
              values[insn.opnds[0]] = values[insn.opnds[1]]&.[](0)
            when :load_last_match_paren
              values[insn.opnds[0]] = values[insn.opnds[1]]&.captures&.reverse_each&.find(&:itself)
            when :load_last_match_post
              values[insn.opnds[0]] = values[insn.opnds[1]]&.post_match
            when :load_last_match_pre
              values[insn.opnds[0]] = values[insn.opnds[1]]&.pre_match
            when :load_lvar
              values[insn.opnds[0]] = locals[insn.data.id]
            when :load_self
              values[insn.opnds[0]] = recv
            when :make_shareable
              values[insn.opnds[0]] = Ractor.make_shareable(values[insn.opnds[1]])
            when :make_shareable_copy
              values[insn.opnds[0]] = Ractor.make_shareable(values[insn.opnds[1]], copy: true)
            when :match
              values[insn.opnds[0]] = StdLib[:BasicObject___send__].bind_call(values[insn.opnds[2]], :===, values[insn.opnds[1]])
            when :match_array
              value = values[insn.opnds[1]]
              values[insn.opnds[0]] = values[insn.opnds[2]].any? { |pattern| StdLib[:BasicObject___send__].bind_call(pattern, :===, value) }
            when :merge_hash
              values[insn.opnds[0]] = StdLib[:Hash_merge].bind_call(values[insn.opnds[1]], values[insn.opnds[2]])
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
              values[insn.opnds[0]] = insn.data.build(values.values_at(*insn.opnds[1..]))
            when :new_string
              values[insn.opnds[0]] = concatenate_strings(values.values_at(*insn.opnds[1..]))
            when :new_symbol
              values[insn.opnds[0]] = concatenate_strings(values.values_at(*insn.opnds[1..])).to_sym
            when :once
              site, initializer = insn.data
              state = @once_mutex.synchronize { @once_states[site] ||= OnceState.new }
              frame.last_match = $~
              frame.last_line = $_
              begin
                result = state.run(initializer) { run_region(frame, initializer, initializer.entry) }
              ensure
                $~ = frame.last_match
                $_ = frame.last_line
              end
              if result.region.equal?(initializer)
                values[insn.opnds[0]] = result.value
              elsif result.block
                block = result.block
                break
              else
                return result
              end
            when :once_return
              return ExecutionResult.new(nil, values[insn.opnds[0]], insn.data)
            when :post_execution
              if @post_executions.add?(insn.data)
                visibility = frame.visibility
                at_exit { run_frame(Frame.new(insn.data, recv, nest, locals, flip_flops, super_method, visibility)) }
              end
            when :raise_pattern_deconstruct
              raise_pattern_error(values[insn.opnds[0]], "%p does not respond to #deconstruct", values[insn.opnds[1]])
            when :raise_pattern_deconstruct_keys
              raise_pattern_error(values[insn.opnds[0]], "%p does not respond to #deconstruct_keys", values[insn.opnds[1]])
            when :raise_pattern_empty
              raise_pattern_error(values[insn.opnds[0]], "%p is not empty", values[insn.opnds[1]])
            when :raise_pattern_find
              raise_pattern_error(values[insn.opnds[0]], "%p does not match to find pattern", values[insn.opnds[1]])
            when :raise_pattern_guard
              raise NoMatchingPatternError, "#{values[insn.opnds[0]].inspect}: guard clause does not return true"
            when :raise_pattern_key
              root, matchee, key = values.values_at(*insn.opnds)
              message = StdLib[:Kernel_sprintf].bind_call(self, "%p: key not found: %p", root, key)
              raise NoMatchingPatternKeyError.new(message, matchee: matchee, key: key)
            when :raise_pattern_length
              raise_pattern_error(values[insn.opnds[0]], "%p length mismatch (given %p, expected %p)", *values.values_at(*insn.opnds[1..]))
            when :raise_pattern_min_length
              raise_pattern_error(values[insn.opnds[0]], "%p length mismatch (given %p, expected %p+)", *values.values_at(*insn.opnds[1..]))
            when :raise_pattern_mismatch
              raise_pattern_error(values[insn.opnds[0]], "%p === %p does not return true", values[insn.opnds[2]], values[insn.opnds[1]])
            when :raise_pattern_nomatch
              raise NoMatchingPatternError, values[insn.opnds[0]]
            when :raise_pattern_rest_empty
              raise_pattern_error(values[insn.opnds[0]], "rest of %p is not empty", values[insn.opnds[1]])
            when :reraise
              raise
            when :rescue_match
              values[insn.opnds[0]] = rescue_match(values[insn.opnds[1]], values[insn.opnds[2]])
            when :rescue_match_array
              exception = values[insn.opnds[1]]
              values[insn.opnds[0]] = values[insn.opnds[2]].any? { |klass| rescue_match(exception, klass) }
            when :return
              return ExecutionResult.new(nil, nil)
            when :return_nonlocal
              target = frame.return_target
              unless target && target.return_fiber.equal?(Fiber.current)
                error = LocalJumpError.new("unexpected return")
                StdLib[:Kernel_instance_variable_set].bind_call(error, :@exit_value, values[insn.opnds[0]])
                StdLib[:Kernel_instance_variable_set].bind_call(error, :@reason, :return)
                raise error
              end
              throw target, values[insn.opnds[0]]
            when :return_value
              return ExecutionResult.new(nil, values[insn.opnds[0]])
            when :store_const_abs
              StdLib[:Module_const_set].bind_call(Object, insn.data, values[insn.opnds[0]])
            when :store_const_nest_rel
              StdLib[:Module_const_set].bind_call(nest[0], insn.data, values[insn.opnds[0]])
            when :store_const_recv_rel
              check_module(values[insn.opnds[0]])
              StdLib[:Module_const_set].bind_call(values[insn.opnds[0]], insn.data, values[insn.opnds[1]])
            when :store_cvar
              parent = cvar_parent(nest)
              check_cvar_parent(parent)
              StdLib[:Module_class_variable_set].bind_call(parent, insn.data, values[insn.opnds[0]])
            when :store_ivar
              StdLib[:Kernel_instance_variable_set].bind_call(recv, insn.data, values[insn.opnds[0]])
            when :store_flip_flop
              flip_flops[insn.data] = values[insn.opnds[0]]
            when :store_gvar
              StdLib[:Binding_eval].bind_call(binding, "#{insn.data} = values[#{insn.opnds[0]}]")
            when :store_lvar
              locals[insn.data.id] = values[insn.opnds[0]]
            when :trace_b_call, :trace_b_return, :trace_call, :trace_class, :trace_end, :trace_line, :trace_rescue, :trace_return
              # ignore
            when :undef_method
              StdLib[:Module_undef_method].bind_call(nest[0], values[insn.opnds[0]])
            when :yield
              raise LocalJumpError, "no block given (yield)" unless frame.block
              call = insn.data
              arguments = values.values_at(*insn.opnds[1..])
              keywords = call.keywords ? arguments.pop : {}
              arguments.concat(arguments.pop) if call.splat
              if call.splat && !call.keywords && Hash === arguments.last && StdLib[:Hash_singleton_ruby2_keywords_hash?].bind_call(Hash, arguments.last)
                keywords = arguments.pop
              end
              values[insn.opnds[0]] = frame.block.call(*arguments, **keywords)
            else
              raise "Unknown instruction kind: #{insn.kind}"
            end
          ensure
            # Native calls update this Ruby scope; interpreted callbacks update the shared state.
            if frame.last_match.equal?(previous_match)
              frame.last_match = $~
            else
              $~ = frame.last_match
            end
          end
        end
      ensure
        frame.last_match = $~
        frame.last_line = $_
        frame.native_binding = previous_binding
        frame.native_match = previous_native_match
      end

      def concatenate_strings(parts)
        result = String.new(encoding: parts.empty? ? Encoding::ASCII_8BIT : parts[0].encoding)
        parts.each do |part|
          result << part
          if result.encoding == Encoding::US_ASCII && part.encoding != Encoding::US_ASCII
            result.force_encoding(part.encoding)
          end
        end
        result
      end

      def with_break_target(block)
        return yield unless Block === block

        block.active = true
        begin
          catch(block) { yield }
        ensure
          block.active = false
        end
      end

      def builtin_lambda?(receiver, name)
        StdLib.lambda_method?(StdLib[:Module_instance_method].bind_call(method_lookup_class(receiver), name))
      rescue NameError
        false
      end

      def default_visibility(receiver, name)
        StdLib.visibility_for(StdLib[:Module_instance_method].bind_call(method_lookup_class(receiver), name))
      rescue NameError
        nil
      end

      def method_lookup_class(receiver)
        case receiver
        when Integer, Float, Symbol
          StdLib[:Kernel_class].bind_call(receiver)
        else
          StdLib[:Kernel_singleton_class].bind_call(receiver)
        end
      rescue TypeError
        StdLib[:Kernel_class].bind_call(receiver)
      end

      def defined_implicit_method?(receiver, name)
        klass = method_lookup_class(receiver)
        begin
          query = StdLib[:Module_instance_method].bind_call(klass, :respond_to?)
        rescue NameError
          return StdLib[:Kernel_respond_to?].bind_call(receiver, name, true)
        end

        arity = MethodDefinition.arity(query)
        if arity == 1
          query.bind_call(receiver, name)
        elsif arity > 2
          raise ArgumentError, "respond_to? must accept 1 or 2 arguments (requires #{arity})"
        else
          query.bind_call(receiver, name, true)
        end
      end

      def defined_explicit_method?(receiver, name, caller)
        klass = method_lookup_class(receiver)
        return true if StdLib[:Module_public_method_defined?].bind_call(klass, name)
        return false if StdLib[:Module_private_method_defined?].bind_call(klass, name)
        return protected_call?(receiver, name, caller) if StdLib[:Module_protected_method_defined?].bind_call(klass, name)

        if defined_implicit_method?(receiver, :respond_to_missing?)
          StdLib[:BasicObject___send__].bind_call(receiver, :respond_to_missing?, name, false)
        else
          false
        end
      end

      def protected_call?(receiver, name, caller)
        return false unless StdLib[:Module_protected_method_defined?].bind_call(method_lookup_class(receiver), name)

        owner = StdLib[:Kernel_method].bind_call(receiver, name).owner
        StdLib[:"Module_==="].bind_call(owner, caller)
      end

      def raise_pattern_error(root, format, *arguments)
        detail = StdLib[:Kernel_sprintf].bind_call(self, format, *arguments)
        message = StdLib[:Kernel_sprintf].bind_call(self, "%p: %s", root, detail)
        raise NoMatchingPatternError, message
      end

      def rescue_match(exception, klass)
        raise TypeError, "class or module required for rescue clause" unless Module === klass
        StdLib[:BasicObject___send__].bind_call(klass, :===, exception)
      end

      def cvar_parent(nest)
        nest[0...-1].find { |scope| !StdLib[:Module_singleton_class?].bind_call(scope) }
      end

      ###

      def define_method(parent, name, graph, nest)
        MethodDefinition.new(self, graph, nest).define(parent, name)
      end

      def new_block(graph, frame, lambda = graph.kind == :lambda)
        vm = self
        locals = frame.locals
        flip_flops = frame.flip_flops
        super_method = frame.super_method
        nest = frame.nest
        block = frame.block
        return_target = frame.return_target
        visibility = frame.visibility

        target = nil
        invoke =
          proc do |receiver, args, kwargs, passed_block|
            if (active_frame = @frames[Fiber.current]&.reverse_each&.find { |active| active.native_binding && active.match_state.equal?(frame.match_state) })
              native_match = StdLib[:Binding_eval].bind_call(active_frame.native_binding, "$~")
              unless native_match.equal?(active_frame.native_match)
                frame.last_match = active_frame.native_match = native_match
              end
            end

            block_locals = graph.scope.equal?(graph) ? Locals.new(graph.locals, locals) : locals
            vm.run_frame(Frame.new(graph, receiver, nest, block_locals, flip_flops, super_method, visibility, target, return_target, lambda, frame.match_state, &block), args, kwargs, passed_block)
          end

        callable =
          StdLib[:BasicObject_instance_exec].bind_call(frame.recv) do
            if graph.signature.ruby2_keywords_eligible?
              # Keep keyword flags independent of blocks compiled from other graphs.
              source = lambda ? "->(*args, &passed_block) { invoke.call(self, args, {}, passed_block) }" : "Proc.new { |*args, &passed_block| invoke.call(self, args, {}, passed_block) }"
              StdLib[:Binding_eval].bind_call(binding, source)
            elsif lambda
              ->(*args, **kwargs, &passed_block) { invoke.call(self, args, kwargs, passed_block) }
            else
              Proc.new { |*args, **kwargs, &passed_block| invoke.call(self, args, kwargs, passed_block) }
            end
          end

        lambda ? callable : (target = Block.new(callable, graph, frame))
      end

      ###

      def define_module(parent, name, check_public)
        if StdLib[:Module_const_defined?].bind_call(parent, name, false)
          check_public_const(parent, parent, name) if check_public
          const = StdLib[:Module_const_get].bind_call(parent, name, false)
          unless Module === const && !(Class === const)
            message = +"#{name} is not a module"
            if (location = StdLib[:Module_const_source_location].bind_call(parent, name, false))
              message << "\n#{location[0]}:#{location[1]}: previous definition of #{name} was here"
            end
            raise TypeError, message
          end
          const
        else
          StdLib[:Module_const_set].bind_call(parent, name, Module.new)
        end
      end

      def define_class(parent, name, check_public)
        existing_class(parent, name, check_public) || StdLib[:Module_const_set].bind_call(parent, name, Class.new)
      end

      def define_class_super(parent, name, check_public, superclass)
        if (klass = existing_class(parent, name, check_public))
          unless StdLib[:BasicObject_equal?].bind_call(StdLib[:Class_superclass].bind_call(klass), superclass)
            raise TypeError, "superclass mismatch for class #{name}"
          end

          klass
        else
          StdLib[:Module_const_set].bind_call(parent, name, Class.new(superclass))
        end
      end

      def existing_class(parent, name, check_public)
        if StdLib[:Module_const_defined?].bind_call(parent, name, false)
          check_public_const(parent, parent, name) if check_public
          const = StdLib[:Module_const_get].bind_call(parent, name, false)
          check_class(parent, name, const)
          const
        end
      end

      ###

      def const_get_nest_rel(nest, name)
        nest[0...-1].each do |scope|
          if StdLib[:Module_const_defined?].bind_call(scope, name, false)
            return StdLib[:Module_const_get].bind_call(scope, name, false)
          end
        end

        StdLib[:Module_const_get].bind_call(nest[0], name)
      end

      def constant_owner(recv, name)
        check_module(recv)
        owner =
          StdLib[:Module_ancestors].bind_call(recv).find do |ancestor|
            StdLib[:Module_const_defined?].bind_call(ancestor, name, false)
          end

        owner unless owner == Object && recv != Object
      end

      def const_defined_recv_rel?(recv, name)
        owner = constant_owner(recv, name)
        !!owner && StdLib[:Module_constants].bind_call(owner, false).include?(name)
      end

      def const_get_recv_rel(recv, name)
        owner = constant_owner(recv, name)
        if owner
          check_public_const(owner, recv, name)
          StdLib[:Module_const_get].bind_call(owner, name, false)
        else
          StdLib[:BasicObject___send__].bind_call(recv, :const_missing, name)
        end
      end

      ###

      def check_class(parent, name, const)
        unless Class === const
          message = +"#{name} is not a class"

          if (location = StdLib[:Module_const_source_location].bind_call(parent, name, false))
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
          raise TypeError, "superclass must be an instance of Class (given an instance of #{StdLib[:Kernel_class].bind_call(superclass)})"
        end
      end

      def check_public_const(parent, recv, name)
        unless StdLib[:Module_constants].bind_call(parent, false).include?(name)
          raise NameError.new("private constant #{recv}::#{name} referenced", name, receiver: recv)
        end
      end
    end
  end
end
