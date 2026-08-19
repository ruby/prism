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

%w[rdoc rerdoc rdoc:coverage].each do |name|
  # rdoc:coverage available in rdoc as a default gem since ruby 3.3 only
  next unless Rake::Task.task_defined?(name)
  Rake::Task[name].enhance(["compile"])
end
