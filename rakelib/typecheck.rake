# frozen_string_literal: true

namespace :typecheck do
  class RBICompiler
    INODE = Set.new(%i[accept child_nodes comment_targets compact_child_nodes deconstruct each_child_node inspect type])

    attr_reader :parent

    def initialize(parent, abstract: Set.new, override: Set.new)
      @parent = parent
      @abstract = abstract
      @override = override
      @visibility = RBI::Public.new
    end

    def compile_comments(node)
      comments = []

      if (comment = node.comment)
        index = 0
        lines = comment.string.lines(chomp: true)

        while index < lines.length
          case (line = lines[index])
          when ":call-seq:"
            # skip RDoc call-seq annotations
            index += 1 until index >= lines.length || lines[index + 1].empty?
            index += 1
          when "--"
            # break when RDoc private starts
            break
          when /\A:/
            # skip RBS type annotations
          else
            comments << RBI::Comment.new(line)
          end

          index += 1
        end
      end

      comments
    end

    def compile(node)
      case node
      when RBS::AST::Members::AttrReader
        parent <<
          RBI::AttrReader.new(
            node.name.name,
            visibility: @visibility,
            sigs: [RBI::Sig.new(return_type: compile_type(node.type).to_rbi)],
            comments: compile_comments(node)
          )
      when RBS::AST::Members::Include
        parent << RBI::Include.new(compile_name(node.name))
      when RBS::AST::Members::Private
        @visibility = RBI::Private.new
      when RBS::AST::Declarations::Constant
        parent <<
          RBI::Const.new(
            compile_name(node.name),
            "T.let(nil, #{compile_type(node.type).to_rbi})",
            comments: compile_comments(node)
          )
      when RBS::AST::Declarations::Class
        parent << RBI::Class.new(compile_name(node.name), comments: compile_comments(node)) do |cls|
          abstract = Set.new
          override = Set.new

          if parent && parent.name.name == "Prism" && cls.name.name == "Node"
            cls << RBI::Helper.new("abstract")
            abstract = INODE
          end

          if (super_class = node.super_class).is_a?(RBS::AST::Declarations::Class::Super)
            cls.superclass_name = compile_name(super_class.name)
            override = INODE if parent && parent.name.name == "Prism" && super_class.name.name.name == "Node"
          end

          compiler = RBICompiler.new(cls, abstract: abstract, override: override)
          node.members.each { |member| compiler.compile(member) }
        end
      when RBS::AST::Declarations::Module
        parent << RBI::Module.new(compile_name(node.name), comments: compile_comments(node)) do |mod|
          compiler = RBICompiler.new(mod)
          node.members.each { |member| compiler.compile(member) }
        end
      when RBS::AST::Members::MethodDefinition
        parent <<
          RBI::Method.new(
            node.name.name,
            visibility: @visibility,
            is_singleton: node.kind == :singleton,
            comments: compile_comments(node)
          ) do |method|
            params = Set.new
            node.overloads.each_with_index do |overload, index|
              method_type = overload.method_type
              func = method_type.type

              sig =
                RBI::Sig.new(
                  return_type: compile_type(func.return_type).to_rbi,
                  is_abstract: @abstract.include?(node.name),
                  is_override: @override.include?(node.name)
                )

              compile_function(func) do |kind, name, type|
                if !params.include?(name)
                  case kind
                  when :param         then method.add_param(name)
                  when :opt_param     then method.add_opt_param(name, "T.unsafe(nil)")
                  when :rest_param    then method.add_rest_param(name)
                  when :kw_opt_param  then method.add_kw_opt_param(name, "T.unsafe(nil)")
                  when :kw_rest_param then method.add_kw_rest_param(name)
                  else raise
                  end
                  params.add(name)
                end

                sig.params << RBI::SigParam.new(name, type)
              end

              if (block = method_type.block)
                if !params.include?("blk")
                  method.add_block_param("blk")
                  params.add("blk")
                end

                proc = RBI::Type.proc
                compile_function(block.type) { |kind, name, type| proc.proc_params[name] = type }
                proc.returns(compile_type(block.type.return_type))

                sig.params << RBI::SigParam.new("blk", proc)
              end

              method.sigs << sig
            end
          end
      when RBS::AST::Members::Alias
        case [node.new_name, node.old_name]
        when [:dispatch, :visit]
          parent <<
            RBI::Method.new("dispatch", visibility: @visibility, comments: compile_comments(node)) do |method|
              method.add_param("node")
              method.sigs <<
                RBI::Sig.new(
                  params: [RBI::SigParam.new("node", RBI::Type.nilable(RBI::Type.simple("Node")))],
                  return_type: RBI::Type.untyped
                )
            end
        when [:script_lines, :source_lines],
             [:find, :breadth_first_search],
             [:find_all, :breadth_first_search_all],
             [:deconstruct, :child_nodes]
          found = parent.nodes.find { |child| child.is_a?(RBI::Method) && child.name == node.old_name.name }
          parent <<
            found.dup.tap do |method|
              method.name = node.new_name.name
              method.comments = compile_comments(node)
            end
        else
          raise
        end
      when RBS::AST::Members::InstanceVariable, RBS::AST::Declarations::Interface, RBS::AST::Declarations::TypeAlias
        # skip
      else
        raise
      end
    end

    private

    def compile_name(name)
      RBI::Type.simple(name.to_namespace.path.join("::"))
    end

    def compile_function(func)
      argidx = -1
      kwargidx = -1

      func.required_positionals.each do |param|
        yield :param, param.name&.name || "arg#{argidx += 1}", compile_type(param.type)
      end

      func.optional_positionals.each do |param|
        yield :opt_param, param.name&.name || "arg#{argidx += 1}", compile_type(param.type)
      end

      if (rest_positionals = func.rest_positionals)
        yield :rest_param, rest_positionals.name&.name || "args", compile_type(rest_positionals.type)
      end

      func.trailing_positionals.each do |param|
        raise
      end

      func.required_keywords.each do |param|
        raise
      end

      func.optional_keywords.each do |name, param|
        yield :kw_opt_param, name, compile_type(param.type)
      end

      if (rest_keywords = func.rest_keywords)
        yield :kw_rest_param, rest_keywords.name&.name || "kwargs", compile_type(rest_keywords.type)
      end
    end

    def compile_type(type)
      case type
      when RBS::Types::Literal
        case type.literal
        when FalseClass
          RBI::Type.simple("FalseClass")
        when Symbol
          RBI::Type.simple("Symbol")
        else
          raise
        end
      when RBS::Types::Bases::Any
        RBI::Type.untyped
      when RBS::Types::Bases::Bool
        RBI::Type.boolean
      when RBS::Types::Bases::Bottom
        RBI::Type.noreturn
      when RBS::Types::Bases::Self
        RBI::Type.self_type
      when RBS::Types::Bases::Void
        RBI::Type.void
      when RBS::Types::Union
        RBI::Type.any(*type.types.map { |child| compile_type(child) })
      when RBS::Types::Tuple
        RBI::Type.tuple(*type.types.map { |child| compile_type(child) })
      when RBS::Types::ClassSingleton
        RBI::Type.class_of(compile_name(type.name))
      when RBS::Types::Optional
        RBI::Type.nilable(compile_type(type.type))
      when RBS::Types::ClassInstance
        if (args = type.args).any?
          case (name = type.name.name)
          when :Array, :Hash
            RBI::Type.generic("T::#{name.name}", *args.map { |arg| compile_type(arg) })
          when :Enumerator
            RBI::Type.generic("T::Enumerator", compile_type(args.first))
          else
            raise
          end
        else
          compile_name(type.name)
        end
      when RBS::Types::Alias
        case type.name.name
        when :node
          RBI::Type.simple("Node")
        when :lex_compat_token
          RBI::Type.tuple(
            RBI::Type.tuple(RBI::Type.simple("Integer"), RBI::Type.simple("Integer")),
            RBI::Type.simple("Symbol"),
            RBI::Type.simple("String"),
            RBI::Type.untyped
          )
        when :entry_values
          RBI::Type.generic("T::Hash", RBI::Type.simple("Symbol"), RBI::Type.untyped)
        when :entry_value
          RBI::Type.untyped
        when :boolish
          RBI::Type.nilable(RBI::Type.boolean)
        else
          raise
        end
      when RBS::Types::Interface
        case type.name.name
        when :_CodeUnitsCache, :_CommentTarget, :_Field, :_Repository, :_Stream, :_Value
          RBI::Type.untyped
        when :_Visitor
          RBI::Type.simple("Visitor")
        else
          raise
        end
      else
        raise
      end
    end
  end

  def with_gemfile
    Bundler.with_original_env do
      ENV['BUNDLE_GEMFILE'] = "gemfiles/typecheck/Gemfile"
      yield
    end
  end

  desc "Generate RBS with rbs-inline"
  task rbs_inline: :templates do
    with_gemfile do
      sh "bundle", "exec", "rbs-inline", "lib", "--output", "lib"
    end
  end

  desc "Generate RBIs from RBSs"
  task rbi: :templates do
    with_gemfile do
      require "fileutils"
      require "rbs"
      require "rbi"
      require "set"

      rbs_base = File.expand_path("../sig/generated", __dir__)
      rbi_base = File.expand_path("../rbi/generated", __dir__)

      Dir["**/*.rbs", base: rbs_base].each do |filepath|
        RBI::File.new(strictness: "true") do |file|
          compiler = RBICompiler.new(file)

          _, _, decls = RBS::Parser.parse_signature(File.read(File.join(rbs_base, filepath)))
          decls.each { |decl| compiler.compile(decl) }

          mkdir_p((dirpath = File.join(rbi_base, File.dirname(filepath))))
          File.write(File.join(dirpath, "#{File.basename(filepath, ".rbs")}.rbi"), file.string)
        end
      end
    end
  end

  desc "Typecheck with Steep"
  task steep: :templates do
    with_gemfile do
      sh "bundle", "exec", "steep", "check"
    end
  end

  desc "Generate RBIs with Tapioca"
  task tapioca: :templates do
    Rake::Task["compile:prism"].invoke

    with_gemfile do
      sh "bundle", "exec", "tapioca", "configure"
      sh "bundle", "exec", "tapioca", "gems", "--exclude", "prism"
      sh "bundle", "exec", "tapioca", "todo"
    end
  end

  desc "Typecheck with Sorbet"
  task sorbet: :templates do
    locals = {
      polyfills: Dir["lib/prism/polyfill/**/*.rb"],
      gem_rbis: Dir["sorbet/rbi/**/*.rbi"]
    }

    File.write("sorbet/typed_overrides.yml", ERB.new(<<~YAML, trim_mode: "-").result_with_hash(locals))
      false:
        - ./lib/prism/lex_compat.rb
        - ./lib/prism/node.rb
        - ./lib/prism/node_ext.rb
        - ./lib/prism/parse_result.rb
        - ./lib/prism/pattern.rb
        - ./lib/prism/visitor.rb
        - ./lib/prism/translation/parser/lexer.rb
        - ./lib/prism/translation/ripper.rb
        - ./lib/prism/translation/ripper/sexp.rb
        - ./lib/prism/translation/ruby_parser.rb
        - ./lib/prism/inspect_visitor.rb
        - ./lib/prism/serialize.rb
        - ./sample/prism/multiplex_constants.rb
        # We want to treat all polyfill files as "typed: false"
      <% polyfills.each do |file| -%>
        - ./<%= file %>
      <% end -%>
        # We want to treat all RBI files as "typed: false"
      <% gem_rbis.each do |file| -%>
        - ./<%= file %>
      <% end -%>
    YAML

    File.write("sorbet/config", <<~CONFIG)
      --dir=.
      --ignore=tmp/
      --ignore=vendor/
      --ignore=ext/
      --ignore=test/
      --ignore=rakelib/
      --ignore=Rakefile
      --ignore=top-100-gems/
      #{Dir.glob("*.rb").map { |f| "--ignore=/#{f}" }.join("\n")}
      # Treat all files as "typed: true" by default
      --typed=true
      # Use the typed-override file to revert some files to "typed: false"
      --typed-override=sorbet/typed_overrides.yml
      # We want to permit initializing a class by constant assignment
      --suppress-error-code=4022
      # We want to permit redefining the existing method as a method alias
      --suppress-error-code=5037
      # We want to permit changing the type of a variable in a loop
      --suppress-error-code=7001
    CONFIG

    with_gemfile do
      sh "bundle", "exec", "srb"
    end
  end
end
