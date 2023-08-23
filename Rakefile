# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/extensiontask"
require "rake/clean"

task compile: :make
task compile_no_debug: :make_no_debug

task default: [:check_manifest, :compile, :test]

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

task make: [:templates] do
  sh "make"
end

task make_no_debug: [:templates] do
  sh "make all-no-debug"
end

# decorate the gem build task with prerequisites
task build: [:templates, :check_manifest]

# the C extension
task "compile:yarp" => ["templates"] # must be before the ExtensionTask is created

if RUBY_ENGINE == "ruby" and !ENV["YARP_FFI_BACKEND"]
  Rake::ExtensionTask.new(:compile) do |ext|
    ext.name = "yarp"
    ext.ext_dir = "ext/yarp"
    ext.lib_dir = "lib/yarp"
    ext.gem_spec = Gem::Specification.load("yarp.gemspec")
  end
elsif RUBY_ENGINE == "jruby"
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
end

# So `rake clobber` will delete generated files
CLOBBER.concat(TEMPLATES)
CLOBBER.concat(["build"])
CLOBBER << "lib/yarp/yarp.#{RbConfig::CONFIG["DLEXT"]}"

TEMPLATES.each do |filepath|
  desc "Generate #{filepath}"
  file filepath => ["templates/#{filepath}.erb", "templates/template.rb", "config.yml"] do |t|
    template(t.name, locals)
  end
end
