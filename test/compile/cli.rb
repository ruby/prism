#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "optparse"
require_relative "vm"
require_relative "disassembler"

expressions = []
dump = false
options = OptionParser.new do |parser|
  parser.banner = "Usage: ruby test/compile/cli.rb [options] [file|-] [arguments]"
  parser.on("-e CODE", "Execute CODE; may be specified multiple times") { |code| expressions << code }
  parser.on("--dump=FORMAT", ["ir"], "Dump IR without executing") { dump = true }
  parser.on("-w", "Enable verbose warnings") { $VERBOSE = true }
  parser.on("-W[LEVEL]", ["0", "1", "2"], "Set warning level") { |level| $VERBOSE = [nil, false, true][(level || "2").to_i] }
  parser.on("-h", "--help", "Show this help") { puts parser; exit }
end

begin
  options.order!(ARGV)
rescue OptionParser::ParseError => error
  abort "#{error.message}\n#{options}"
end

input = nil
source, filepath =
  if expressions.any?
    [expressions.join("\n"), "-e"]
  else
    path = ARGV.shift
    if path.nil? || path == "-"
      [$stdin.read, "-"]
    else
      input = File.open(path)
      [input.read, path]
    end
  end

$PROGRAM_NAME = filepath
vm = Prism::Compile::VM.new
result = vm.compile(source, filepath, main_script: true, command_line: expressions.any? ? "e" : "")
unit = result.value

if dump
  input&.close
  puts Prism::Compile::Disassembler.new(unit).disasm
else
  if result.data_loc && expressions.empty?
    offset = source.b.index("\n", result.data_loc.start_offset)
    offset = offset ? offset + 1 : source.bytesize
    unless input
      require "stringio"
      input = StringIO.new(source, "r")
    end
    input.seek(offset)
    Object.const_set(:DATA, input)
  else
    input&.close
  end

  vm.run(unit)
end
