# frozen_string_literal: true

desc "Lint config.yml"
task :lint do
  require "yaml"
  config = YAML.safe_load_file(File.expand_path("../config.yml", __dir__))

  tokens = config.fetch("tokens")[4..].map { |token| token.fetch("name") }
  if tokens.sort != tokens
    warn("Tokens are not sorted alphabetically")

    tokens.sort.zip(tokens).each do |(sorted, unsorted)|
      warn("Expected #{sorted} got #{unsorted}") if sorted != unsorted
    end

    exit(1)
  end

  nodes = config.fetch("nodes").map { |node| node.fetch("name") }
  if nodes.sort != nodes
    warn("Nodes are not sorted alphabetically")

    nodes.sort.zip(nodes).each do |(sorted, unsorted)|
      warn("Expected #{sorted} got #{unsorted}") if sorted != unsorted
    end

    exit(1)
  end
end
