#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require_relative "vm"
require_relative "disassembler"

command = ARGV.shift
abort "Usage: ruby test/compile/cli.rb [compile|interpret] [-e source|file]" unless ["compile", "interpret"].include?(command)

source, filepath =
  case ARGV.first
  when "-e"
    ARGV.shift
    [ARGV.shift, "-e"]
  when nil
    [File.read("test.rb"), "test.rb"]
  else
    path = ARGV.shift
    [File.read(path), path]
  end

vm = Prism::Compile::VM.new
unit = vm.compile(source, filepath)

if command == "compile"
  puts Prism::Compile::Disassembler.new(unit).disasm
else
  vm.run(unit)
end
