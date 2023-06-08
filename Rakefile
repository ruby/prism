# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/extensiontask"
require "rake/testtask"
require "rake/clean"
require "ruby_memcheck"

Rake.add_rakelib("tasks")

RubyMemcheck.config(binary_name: "yarp")

task compile: :make
task compile_no_debug: :make_no_debug

Rake::ExtensionTask.new(:compile) do |ext|
  ext.name = "yarp"
  ext.lib_dir = "lib"
  ext.ext_dir = "ext/yarp"
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

require_relative "bin/template"

desc "Generate all ERB template based files"
task templates: TEMPLATES

task make: :templates do
  sh "make"
end

task make_no_debug: :templates do
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

CLOBBER << "build/librubyparser.#{RbConfig::CONFIG["SOEXT"]}"
CLOBBER << "lib/yarp.#{RbConfig::CONFIG["DLEXT"]}"

TEMPLATES.each do |filepath|
  desc "Template #{filepath}"
  file filepath => ["bin/templates/#{filepath}.erb", "bin/template.rb", "config.yml"] do |t|
    template(t.name, locals)
  end
end
