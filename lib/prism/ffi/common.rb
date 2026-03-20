# frozen_string_literal: true
# :markup: markdown
# typed: ignore

module Prism

  class Common
    def dump(string, options) # :nodoc:
      with_buffer do |buffer|
        parse_only(buffer, string, options)

        dumped = buffer.read
        dumped.freeze if options.fetch(:freeze, false)

        dumped
      end
    end

    def parse(string, code, options) # :nodoc:
      serialized = dump(string, options)
      Serialize.load_parse(code, serialized, options.fetch(:freeze, false))
    end

    def lex(string, code, options) # :nodoc:
      with_buffer do |buffer|
        lex_only(buffer, string, options)
        Serialize.load_lex(code, buffer.read, options.fetch(:freeze, false))
      end
    end

    # Return the value that should be dumped for the command_line option.
    def dump_options_command_line(options)
      command_line = options.fetch(:command_line, "")
      raise ArgumentError, "command_line must be a string" unless command_line.is_a?(String)

      command_line.each_char.inject(0) do |value, char|
        case char
        when "a" then value | 0b000001
        when "e" then value | 0b000010
        when "l" then value | 0b000100
        when "n" then value | 0b001000
        when "p" then value | 0b010000
        when "x" then value | 0b100000
        else raise ArgumentError, "invalid command_line option: #{char}"
        end
      end
    end

    # Return the value that should be dumped for the version option.
    def dump_options_version(version)
      case version
      when "current"
        version_string_to_number(RUBY_VERSION) || raise(CurrentVersionError, RUBY_VERSION)
      when "latest", nil
        0 # Handled in pm_parser_init
      when "nearest"
        dump = version_string_to_number(RUBY_VERSION)
        return dump if dump
        if RUBY_VERSION < "3.3"
          version_string_to_number("3.3")
        else
          0 # Handled in pm_parser_init
        end
      else
        version_string_to_number(version) || raise(ArgumentError, "invalid version: #{version}")
      end
    end

    # Converts a version string like "4.0.0" or "4.0" into a number.
    # Returns nil if the version is unknown.
    def version_string_to_number(version)
      case version
      when /\A3\.3(\.\d+)?\z/
        1
      when /\A3\.4(\.\d+)?\z/
        2
      when /\A3\.5(\.\d+)?\z/, /\A4\.0(\.\d+)?\z/
        3
      when /\A4\.1(\.\d+)?\z/
        4
      end
    end

    # Convert the given options into a serialized options string.
    def dump_options(options)
      template = +""
      values = []

      template << "L"
      if (filepath = options[:filepath])
        values.push(filepath.bytesize, filepath.b)
        template << "A*"
      else
        values << 0
      end

      template << "l"
      values << options.fetch(:line, 1)

      template << "L"
      if (encoding = options[:encoding])
        name = encoding.is_a?(Encoding) ? encoding.name : encoding
        values.push(name.bytesize, name.b)
        template << "A*"
      else
        values << 0
      end

      template << "C"
      values << (options.fetch(:frozen_string_literal, false) ? 1 : 0)

      template << "C"
      values << dump_options_command_line(options)

      template << "C"
      values << dump_options_version(options[:version])

      template << "C"
      values << (options[:encoding] == false ? 1 : 0)

      template << "C"
      values << (options.fetch(:main_script, false) ? 1 : 0)

      template << "C"
      values << (options.fetch(:partial_script, false) ? 1 : 0)

      template << "C"
      values << (options.fetch(:freeze, false) ? 1 : 0)

      template << "L"
      if (scopes = options[:scopes])
        values << scopes.length

        scopes.each do |scope|
          locals = nil
          forwarding = 0

          case scope
          when Array
            locals = scope
          when Scope
            locals = scope.locals

            scope.forwarding.each do |forward|
              case forward
              when :*     then forwarding |= 0x1
              when :**    then forwarding |= 0x2
              when :&     then forwarding |= 0x4
              when :"..." then forwarding |= 0x8
              else raise ArgumentError, "invalid forwarding value: #{forward}"
              end
            end
          else
            raise TypeError, "wrong argument type #{scope.class.inspect} (expected Array or Prism::Scope)"
          end

          template << "L"
          values << locals.length

          template << "C"
          values << forwarding

          locals.each do |local|
            name = local.name
            template << "L"
            values << name.bytesize

            template << "A*"
            values << name.b
          end
        end
      else
        values << 0
      end

      values.pack(template)
    end

    # Required APIs below

    def with_buffer(&b)
      raise NotImplementedError
    end

    def with_string(string, &b)
      raise NotImplementedError
    end

    def with_file(string, &b)
      raise NotImplementedError
    end

    def lex_only(buffer, string, options)
      raise NotImplementedError
    end

    def parse_only(buffer, string, options)
      raise NotImplementedError
    end

    def parse_stream(buffer, callback, eof_callback, options, source)
      raise NotImplementedError
    end

    def parse_comments(string, code, options) # :nodoc:
      raise NotImplementedError
    end

    def parse_lex(string, code, options) # :nodoc:
      raise NotImplementedError
    end

    def parse_file_success(string, options) # :nodoc:
      raise NotImplementedError
    end

    def string_query_method_name(string)
      raise NotImplementedError
    end

    def string_query_constant(string)
      raise NotImplementedError
    end

    def string_query_local(string)
      raise NotImplementedError
    end
  end
end
