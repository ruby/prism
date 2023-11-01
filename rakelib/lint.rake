# frozen_string_literal: true

desc "Lint config.yml"
task :lint do
  require "yaml"
  config = YAML.safe_load_file(File.expand_path("../config.yml", __dir__))

  tokens = config.fetch("tokens")[4..-1].map { |token| token.fetch("name") }
  if tokens.sort != tokens
    warn("Tokens are not sorted alphabetically")

    tokens.sort.zip(tokens).each do |(sorted, unsorted)|
      warn("Expected #{sorted} got #{unsorted}") if sorted != unsorted
    end

    exit(1)
  end

  nodes = config.fetch("nodes")
  names = nodes.map { |node| node.fetch("name") }
  if names.sort != names
    warn("Nodes are not sorted alphabetically")

    names.sort.zip(names).each do |(sorted, unsorted)|
      warn("Expected #{sorted} got #{unsorted}") if sorted != unsorted
    end

    exit(1)
  end

  if (uncommented = nodes.select { |node| !node.key?("comment") }).any?
    names = uncommented.map { |node| node.fetch("name") }
    warn("Expected all nodes to be commented, missing comments for #{names.join(", ")}")
    exit(1)
  end

  if (uncommented = nodes.select { |node| !%w[MissingNode ProgramNode].include?(node.fetch("name")) && !node.fetch("comment").match?(/^\s{4}/) }).any?
    names = uncommented.map { |node| node.fetch("name") }
    warn("Expected all nodes to have an example, missing comments for #{names.join(", ")}")
    exit(1)
  end

  trailing_spaces_found = false
  extensions = %w[.c .h .erb .rb .yml .rake]

  `git ls-files -z`.split("\x0").each do |filepath|
    next unless extensions.include?(File.extname(filepath))

    File.foreach(filepath).with_index(1) do |line, index|
      if line.match?(/[ \t]+$/)
        warn("Trailing spaces found in #{filepath} on line #{index}")
        trailing_spaces_found = true
      end
    end
  end

  exit(1) if trailing_spaces_found
end
