# frozen_string_literal: true

require "rdoc/task"

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.markup = "markdown"
  rdoc.rdoc_dir = "doc/ruby"

  rdoc.options << "--all"
  rdoc.options << "--coverage-report"

  rdoc.rdoc_files.include(
    "docs/*.md",
    "ext/**/*.c",
    "lib/**/*.rb",
    "src/**/*.c",
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "LICENSE.md",
    "README.md",
  )
end
