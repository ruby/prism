# frozen_string_literal: true

require "rake/extensiontask"
require "rake/testtask"
require "rake/clean"
require "rdoc/task"
require "ruby_memcheck"

# true for either ucrt or mingw builds, will not include mswin builds
IS_WINDOWS = RUBY_PLATFORM.include?('mingw')

Rake.add_rakelib("tasks")

RubyMemcheck.config(binary_name: "yarp")

task compile: :make
task compile_no_debug: :make_no_debug

Rake::ExtensionTask.new(:compile) do |ext|
  ext.name = "yarp"
  ext.ext_dir = "ext/yarp"
  ext.lib_dir = "lib"
  ext.gem_spec = Gem::Specification.load("yarp.gemspec")
end

test_config = lambda do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new(test: :compile, &test_config)

namespace :test do
  RubyMemcheck::TestTask.new(valgrind: :compile, &test_config)
end

task default: :test

require_relative "templates/template"

desc "Generate all ERB template based files"
task templates: TEMPLATES

file "configure" do
  cmd = IS_WINDOWS ? "sh autoconf" : "autoconf" 
  sh cmd
end

file "Makefile" => "configure" do
  cmd = IS_WINDOWS ? "sh ./configure" : "./configure"
  sh cmd
end

task make: [:templates, "Makefile"] do
  sh "make"
end

task make_no_debug: [:templates, "Makefile"] do
  sh "make all-no-debug"
end

task generate_compilation_database: [:clobber, :templates] do
  sh "which bear" do |ok, _|
    abort("Installing bear is required to generate the compilation database") unless ok
  end

  sh "bear -- make"
end

# So `rake clobber` will delete generated files
CLOBBER.concat(TEMPLATES)
CLOBBER.concat(["configure", "Makefile"])

CLOBBER << "build/librubyparser.#{RbConfig::CONFIG["SOEXT"]}"
CLOBBER << "lib/yarp.#{RbConfig::CONFIG["DLEXT"]}"

TEMPLATES.each do |filepath|
  desc "Template #{filepath}"
  file filepath => ["templates/#{filepath}.erb", "templates/template.rb", "config.yml"] do |t|
    template(t.name, locals)
  end
end

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.markup = "markdown"
  rdoc.rdoc_dir = "doc"

  rdoc.rdoc_files.include(
    "docs/*.md",
    "ext/**/*.c",
    "lib/**/*.rb",
    "src/**/*.c",
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "LICENSE.md",
    "README.md",
    "vscode/*.md"
  )
end
