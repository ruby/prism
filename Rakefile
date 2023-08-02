# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/extensiontask"
require "rake/clean"

require_relative "templates/template"

templates = Rake::FileList.new("templates/**/*.erb")
sources = Rake::FileList.new("src/**/*.c").concat(templates.grep(%r{^templates/src/.+\.c\.erb$}).pathmap("%{templates/,}X")).uniq
headers = Rake::FileList.new("include/**/*.h").concat(templates.grep(%r{^templates/include/.+\.h\.erb$}).pathmap("%{templates/,}X")).uniq

templates.each do |filepath|
  file filepath.pathmap("%{templates/,}X") => [filepath, "templates/template.rb", "config.yml"] do |t|
    template(t.name, locals)
  end
end

CLOBBER.concat(templates.pathmap("%{templates/,}X"))

desc "Generate all ERB template based files"
task templates: templates.pathmap("%{templates/,}X")

headers.pathmap("ext/yarp/%p").pathmap("%d").uniq.each do |filepath|
  directory filepath
end

rule %r{^ext/yarp/src-.+\.c$} => -> (filepath) { filepath.delete_prefix("ext/yarp/").tr("-", "/") } do |t|
  puts "cp #{t.source}, #{t.name}"
  File.write(t.name, "#line 1 \"#{t.source}\"\n#{File.read(t.source)}")
end

rule %r{^ext/yarp/include/.+\.h$} => ["%{ext/yarp/,}X.h", "%d"] do |t|
  puts "cp #{t.source}, #{t.name}"
  File.write(t.name, "#line 1 \"#{t.source}\"\n#{File.read(t.source)}")
end

generated = sources.pathmap("ext/yarp/%{.*,*}X.c") { |filepath| filepath.tr("/", "-") }.concat(headers.pathmap("ext/yarp/%p"))
CLOBBER.concat(generated)

task compile: templates.grep(%r{^templates/ext}).pathmap("%{templates/,}X").concat(generated)

task(:env_ndebug) { ENV["YARP_NO_DEBUG_BUILD"] = "1" }
task compile_no_debug: [:env_ndebug, :compile]

if RUBY_ENGINE == "jruby"
  require "rake/javaextensiontask"

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

task build: :check_manifest
task test: :compile
task default: :test
