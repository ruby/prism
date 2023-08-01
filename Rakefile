# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/extensiontask"
require "rake/testtask"
require "rake/clean"
require "rdoc/task"

Rake.add_rakelib("tasks")

if RUBY_ENGINE != "jruby"
  require "ruby_memcheck"
  RubyMemcheck.config(binary_name: "yarp")
end

task compile: :make
task compile_no_debug: :make_no_debug

task default: [:compile, :test]

require_relative "templates/template"

desc "Generate all ERB template based files"
task templates: TEMPLATES

def windows?
  RUBY_PLATFORM.include?("mingw")
end

def run_script(command)
  command = "sh #{command}" if windows?
  sh command
end

file "configure" => ["configure.ac"] do
  # autoreconf would be more generic, but it does not seem to work on GitHub Actions on macOS
  run_script "autoconf"
  run_script "autoheader"
end

file "Makefile" => ["configure", "Makefile.in"] do
  run_script "./configure"
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

# decorate the gem build task with prerequisites
task build: [:templates, :check_manifest]

# the C extension
task "compile:yarp" => ["configure", "templates"] # must be before the ExtensionTask is created

if RUBY_ENGINE == 'jruby'
  require 'rake/javaextensiontask'

  # This compiles java to make sure any templating changes produces valid code.
  Rake::JavaExtensionTask.new(:compile) do |ext|
    ext.name = "yarp"
    ext.ext_dir = "java"
    ext.lib_dir = "tmp"
    ext.source_version = "1.8"
    ext.target_version = "1.8"
    ext.gem_spec = Gem::Specification.load("yarp.gemspec")
  end
else
  Rake::ExtensionTask.new(:compile) do |ext|
    ext.name = "yarp"
    ext.ext_dir = "ext/yarp"
    ext.lib_dir = "lib/yarp"
    ext.gem_spec = Gem::Specification.load("yarp.gemspec")
  end
end

# So `rake clobber` will delete generated files
CLOBBER.concat(TEMPLATES)
CLOBBER.concat(["configure", "Makefile", "build", "config.h.in", "include/yarp/config.h"])
CLOBBER << "lib/yarp/yarp.#{RbConfig::CONFIG["DLEXT"]}"

TEMPLATES.each do |filepath|
  desc "Generate #{filepath}"
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
  )
end
