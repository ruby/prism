# frozen_string_literal: true

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

    class RegexpOptions
      attr_reader :flags

      def initialize(flags, encoding)
        @flags = flags
        @options = RegularExpressionOptions.options(flags)
        @encoding = if flags.anybits?(RegularExpressionFlags::FORCED_BINARY_ENCODING | RegularExpressionFlags::ASCII_8BIT)
          Encoding::ASCII_8BIT
        elsif flags.anybits?(RegularExpressionFlags::UTF_8)
          Encoding::UTF_8
        elsif flags.anybits?(RegularExpressionFlags::EUC_JP)
          Encoding::EUC_JP
        elsif flags.anybits?(RegularExpressionFlags::WINDOWS_31J)
          Encoding::Windows_31J
        else
          encoding
        end
      end

      def literal(string)
        string.force_encoding(@encoding)
      end

      def build(parts)
        fixed_encoding = nil
        parts.each do |part|
          if @options.anybits?(Regexp::NOENCODING) && part.encoding != Encoding::ASCII_8BIT && !part.ascii_only?
            raise RegexpError, "/.../n has a non escaped non ASCII character in non ASCII-8BIT script"
          end
          raise ArgumentError, "invalid multibyte character" unless part.valid_encoding?
          unless part.ascii_only?
            if fixed_encoding && fixed_encoding != part.encoding
              raise RegexpError, "encoding mismatch in dynamic regexp: #{fixed_encoding} and #{part.encoding}"
            end
            fixed_encoding = part.encoding
          end
        end
        pattern = parts.empty? ? String.new(encoding: @encoding) : parts.join
        pattern.force_encoding(fixed_encoding) if fixed_encoding
        if pattern.ascii_only? && @flags.anybits?(RegularExpressionFlags::EUC_JP | RegularExpressionFlags::WINDOWS_31J | RegularExpressionFlags::UTF_8)
          pattern.force_encoding(@encoding)
        end
        Regexp.new(pattern, @options).freeze
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

    class CallInfo
      attr_reader :name, :keywords, :splat, :ignore_visibility, :variable_call, :block, :block_argument

      def initialize(name, keywords, splat, ignore_visibility, variable_call, block, block_argument)
        @name = name
        @keywords = keywords
        @splat = splat
        @ignore_visibility = ignore_visibility
        @variable_call = variable_call
        @block = block
        @block_argument = block_argument
      end
    end

    class OnceSite
      attr_reader :id

      def initialize(id)
        @id = id
      end
    end

    class Region
      attr_reader :id, :kind, :parent

      def initialize(id, kind, parent, blocks, entry_id, handler_id)
        @id = id
        @kind = kind
        @parent = parent
        @blocks = blocks
        @entry_id = entry_id
        @handler_id = handler_id
      end

      def entry
        @blocks.fetch(@entry_id)
      end

      def handler
        @blocks.fetch(@handler_id) if @handler_id
      end
    end

    class Block
      attr_reader :id, :insns, :params, :region

      def initialize(id, insns, params, region)
        @id = id
        @region = region
        @insns = insns
        @params = params
      end
    end

    class Signature
      attr_reader :requireds, :optionals, :optional_specifieds, :rest, :posts, :required_keywords, :optional_keywords, :optional_keyword_specifieds, :keyword_rest, :block, :no_keywords, :no_block, :autosplat

      def initialize(requireds, optionals, optional_specifieds, rest, posts, required_keywords, optional_keywords, optional_keyword_specifieds, keyword_rest, block, no_keywords, no_block, autosplat)
        @requireds = requireds
        @optionals = optionals
        @optional_specifieds = optional_specifieds
        @rest = rest
        @posts = posts
        @required_keywords = required_keywords
        @optional_keywords = optional_keywords
        @optional_keyword_specifieds = optional_keyword_specifieds
        @keyword_rest = keyword_rest
        @block = block
        @no_keywords = no_keywords
        @no_block = no_block
        @autosplat = autosplat
      end

      def arity
        required = requireds.length + posts.length + (required_keywords.empty? ? 0 : 1)
        if rest || !optionals.empty? || (required_keywords.empty? && (!optional_keywords.empty? || keyword_rest))
          -required - 1
        else
          required
        end
      end

      def ruby2_keywords_eligible?
        rest && posts.empty? && required_keywords.empty? && optional_keywords.empty? && !keyword_rest && !no_keywords
      end
    end

    class Graph
      attr_reader :id, :kind, :parent, :scope, :blocks, :regions, :locals, :nvalues, :nflip_flops, :signature

      def initialize(id, kind, parent, scope, blocks, regions, locals, nvalues, nflip_flops, signature)
        @id = id
        @kind = kind
        @parent = parent
        @scope = scope || self
        @regions = regions
        @blocks = blocks
        @locals = locals
        @nvalues = nvalues
        @nflip_flops = nflip_flops
        @signature = signature
      end
    end

    class Unit
      attr_reader :graphs

      def initialize(graphs)
        @graphs = graphs
      end
    end
  end
end
