# frozen_string_literal: true

require "cgi"
require "json"
require "uri"

module YARP
  # YARP additionally ships with a language server conforming to the
  # language server protocol. It can be invoked by running the yarp-lsp
  # bin script (bin/yarp-lsp)
  class LanguageServer
    DEFAULT_PRINT_WIDTH = 80

    module Request
      # Represents a hash pattern.
      class Shape
        attr_reader :values

        def initialize(values)
          @values = values
        end

        def ===(other)
          values.all? do |key, value|
            value == :any ? other.key?(key) : value === other[key]
          end
        end
      end

      # Represents an array pattern.
      class Tuple
        attr_reader :values

        def initialize(values)
          @values = values
        end

        def ===(other)
          values.each_with_index.all? { |value, index| value === other[index] }
        end
      end

      def self.[](value)
        case value
        when Array
          Tuple.new(value.map { |child| self[child] })
        when Hash
          Shape.new(value.transform_values { |child| self[child] })
        else
          value
        end
      end
    end

    attr_reader :input, :output, :print_width

    def initialize(
      input: $stdin,
      output: $stdout,
      print_width: DEFAULT_PRINT_WIDTH
    )
      @input = input.binmode
      @output = output.binmode
      @print_width = print_width
    end

    # rubocop:disable Layout/LineLength
    def run
      store =
        Hash.new do |hash, uri|
          filepath = CGI.unescape(URI.parse(uri).path)
          File.exist?(filepath) ? (hash[uri] = File.read(filepath)) : nil
        end

      while (headers = input.gets("\r\n\r\n"))
        source = input.read(headers[/Content-Length: (\d+)/i, 1].to_i)
        request = JSON.parse(source, symbolize_names: true)

        # stree-ignore
        case request
        in { method: "initialize", id: }
          store.clear
          write(id: id, result: { capabilities: capabilities })
        in { method: "initialized" }
          # ignored
        in { method: "shutdown" } # tolerate missing ID to be a good citizen
          store.clear
          write(id: request[:id], result: {})
          return
        in { method: "textDocument/didChange", params: { textDocument: { uri: }, contentChanges: [{ text: }, *] } }
          store[uri] = text
        in { method: "textDocument/didOpen", params: { textDocument: { uri:, text: } } }
          store[uri] = text
        in { method: "textDocument/didClose", params: { textDocument: { uri: } } }
          store.delete(uri)
        in { method: "textDocument/diagnostic", id:, params: { textDocument: { uri: } } }
          uri = request.dig(:params, :textDocument, :uri)
          contents = store[uri]
          write(id: request[:id], result: contents ? diagnostics(contents) : nil)
        in { method: %r{\$/.+} }
          # ignored
        else
          raise ArgumentError, "Unhandled: #{request}"
        end
      end
    end
    # rubocop:enable Layout/LineLength

    private

    def capabilities
      {
        diagnosticProvider: {
          interFileDependencies: false,
          workspaceDiagnostics: false,
        },
        textDocumentSync: {
          change: 1,
          openClose: true
        }
      }
    end

    def write(value)
      response = value.merge(jsonrpc: "2.0").to_json
      output.print("Content-Length: #{response.bytesize}\r\n\r\n#{response}")
      output.flush
    end

    def diagnostics(contents)
      parse_output = YARP.parse(contents)
      { 
        kind: "full",
        items: [
          *parse_output.errors.map do |error|
            {
              #range: error.location,
              message: error.message,
              severity: 1,
            }
          end,
          *parse_output.warnings.map do |warning|
            {
              #range: warning.location,
              #message: warning.message,
              severity: 2,
            }
          end,
        ]
      }
    end

    def log(message)
      write(method: "window/logMessage", params: { type: 4, message: message })
    end
  end
end
