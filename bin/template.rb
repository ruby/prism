#!/usr/bin/env ruby

require "erb"
require "fileutils"
require "yaml"
require_relative "node_types"

# This templates out a file using ERB with the given locals. The locals are
# derived from the config.yml file.
def template(name, locals)
  template = File.expand_path("../bin/templates/#{name}.erb", __dir__)
  write_to = File.expand_path("../#{name}", __dir__)

  erb = ERB.new(File.read(template), trim_mode: "-")
  erb.filename = template

  contents = erb.result_with_hash(locals)
  FileUtils.mkdir_p(File.dirname(write_to))
  File.write(write_to, contents)
end

def locals
  config = YAML.load_file(File.expand_path("../config.yml", __dir__))
  {
    nodes: config.fetch("nodes").map { |node| NodeType.new(node) }.sort_by(&:name),
    tokens: config.fetch("tokens").map { |token| Token.new(token) }
  }
end
