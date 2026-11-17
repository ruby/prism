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

source, filepath =
  if expressions.any?
    [expressions.join("\n"), "-e"]
  else
    path = ARGV.shift
    path.nil? || path == "-" ? [$stdin.read, "-"] : [File.read(path), path]
  end

$PROGRAM_NAME = filepath
vm = Prism::Compile::VM.new
unit = vm.compile(source, filepath)

if dump
  puts Prism::Compile::Disassembler.new(unit).disasm
else
  vm.run(unit)
end
