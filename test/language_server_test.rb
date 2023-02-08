# frozen_string_literal: true

require_relative "test_helper"
require "yarp/language_server"

module YARP
  class LanguageServerTest < Test::Unit::TestCase
    class Initialize < Struct.new(:id)
      def to_hash
        { method: "initialize", id: id }
      end
    end

    class Shutdown < Struct.new(:id)
      def to_hash
        { method: "shutdown", id: id }
      end
    end

    class TextDocumentDidOpen < Struct.new(:uri, :text)
      def to_hash
        {
          method: "textDocument/didOpen",
          params: { textDocument: { uri: uri, text: text } }
        }
      end
    end

    class TextDocumentDidChange < Struct.new(:uri, :text)
      def to_hash
        {
          method: "textDocument/didChange",
          params: {
            textDocument: { uri: uri },
            contentChanges: [{ text: text }]
          }
        }
      end
    end

    class TextDocumentDidClose < Struct.new(:uri)
      def to_hash
        {
          method: "textDocument/didClose",
          params: { textDocument: { uri: uri } }
        }
      end
    end

    class TextDocumentDiagnostic < Struct.new(:id, :uri)
      def to_hash
        {
          method: "textDocument/diagnostic",
          id: id,
          params: {
            textDocument: { uri: uri },
          }
        }
      end
    end

    def test_reading_file
      Tempfile.open(%w[test- .rb]) do |file|
        file.write("class Foo; end")
        file.rewind

        responses = run_server([
          Initialize.new(1),
          Shutdown.new(3)
        ])

        shape = LanguageServer::Request[[
          { id: 1, result: { capabilities: Hash } },
          { id: 3, result: {} }
        ]]

        assert_operator(shape, :===, responses)
      end
    end

    def test_bogus_request
      assert_raises(ArgumentError) do
        run_server([{ method: "textDocument/bogus" }])
      end
    end

    def test_clean_shutdown
      responses = run_server([Initialize.new(1), Shutdown.new(2)])

      shape = LanguageServer::Request[[
        { id: 1, result: { capabilities: Hash } },
        { id: 2, result: {} }
      ]]

      assert_operator(shape, :===, responses)
    end

    def test_file_that_does_not_exist
      responses = run_server([
        Initialize.new(1),
        Shutdown.new(3)
      ])

      shape = LanguageServer::Request[[
        { id: 1, result: { capabilities: Hash } },
        { id: 3, result: {} }
      ]]

      assert_operator(shape, :===, responses)
    end

    def test_diagnostics_request
      responses = run_server([
        Initialize.new(1),
        TextDocumentDidOpen.new("file:///path/to/file.rb", <<~RUBY),
          1 + (
        RUBY
        TextDocumentDiagnostic.new(2, "file:///path/to/file.rb"),
        Shutdown.new(3)
      ])

      shape = LanguageServer::Request[[
        { id: 1, result: { capabilities: Hash } },
        { id: 2, result: :any },
        { id: 3, result: {} }
      ]]

      assert_operator(shape, :===, responses)
      assert_equal(2, responses.dig(1, :items).size)
    end

    private

    def write(content)
      request = content.to_hash.merge(jsonrpc: "2.0").to_json
      "Content-Length: #{request.bytesize}\r\n\r\n#{request}"
    end

    def read(content)
      [].tap do |messages|
        while (headers = content.gets("\r\n\r\n"))
          source = content.read(headers[/Content-Length: (\d+)/i, 1].to_i)
          messages << JSON.parse(source, symbolize_names: true)
        end
      end
    end

    def run_server(messages, print_width: LanguageServer::DEFAULT_PRINT_WIDTH)
      input = StringIO.new(messages.map { |message| write(message) }.join)
      output = StringIO.new

      LanguageServer.new(
        input: input,
        output: output,
        print_width: print_width
      ).run

      read(output.tap(&:rewind))
    end
  end
end
