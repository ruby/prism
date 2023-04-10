# frozen_string_literal: true

require "rake/extensiontask"
require "rake/testtask"
require "rake/clean"

Rake.add_rakelib("tasks")

task compile: :make
task compile_no_debug: :make_no_debug

if RUBY_ENGINE == 'jruby'
  require 'rake/javaextensiontask'

  Rake::JavaExtensionTask.new(:compile) do |ext|
    ext.ext_dir = 'jruby'
    ext.lib_dir = "lib/yarp"
    ext.source_version = '1.8'
    ext.target_version = '1.8'
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

test_config = lambda do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new(test: :compile, &test_config)

if RUBY_ENGINE != 'jruby'
  require "ruby_memcheck"

  RubyMemcheck.config(binary_name: "yarp")
  namespace :test do
    RubyMemcheck::TestTask.new(valgrind: :compile, &test_config)
  end
end

task default: :test

TEMPLATES = [
  "ext/yarp/node.c",
  "include/yarp/ast.h",
  "java/org/yarp/Loader.java",
  "java/org/yarp/Nodes.java",
  "java/org/yarp/AbstractNodeVisitor.java",
  "lib/yarp/node.rb",
  "lib/yarp/serialize.rb",
  "src/node.c",
  "src/prettyprint.c",
  "src/serialize.c",
  "src/token_type.c"
]

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

dylib_extension = RbConfig::CONFIG["host_os"].match?(/darwin/) ? "dylib" : "so"
CLOBBER << "build/librubyparser.#{dylib_extension}"
CLOBBER << "lib/yarp.#{dylib_extension}"

TEMPLATES.each do |filepath|
  desc "Template #{filepath}"
  file filepath => ["bin/templates/#{filepath}.erb", "bin/template.rb", "config.yml"] do |t|
    require_relative "bin/template"
    template(t.name, locals)
  end
end
