# frozen_string_literal: true

begin
  require "rdoc/task"
rescue LoadError
  # RDoc is not available
  return
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.main = "README.md"

  rdoc.rdoc_dir = "doc/rb"
  rdoc.options.push("--all", "-x", "lib/prism/translation/ripper/shim.rb")

  rdoc.rdoc_files.include(
    "docs/*.md",
    "ext/**/*.c",
    "lib/**/*.rb",
    "src/**/*.c",
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "LICENSE.md",
    "README.md",
    *Prism::Template::TEMPLATES.grep(/\.(?:c|h|rb)$/)
  )
end

Rake::Task["rdoc"].prerequisites.unshift("templates")
