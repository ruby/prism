# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/extensiontask"
require "rake/clean"

require_relative "templates/template"

templates = Rake::FileList.new("templates/**/*.erb")
sources = Rake::FileList.new("src/**/*.c").concat(templates.grep(%r{^templates/src/.*\.c\.erb$}).pathmap("%{templates/,}X")).uniq
headers = Rake::FileList.new("include/**/*.h").concat(templates.grep(/\.h\.erb$/).pathmap("%{templates/,}X")).uniq

templates.each do |filepath|
  file filepath.pathmap("%{templates/,}X") => [filepath, "templates/template.rb", "config.yml"] do |t|
    template(t.name, locals)
  end
end

desc "Generate all ERB template based files"
task templates: templates.pathmap("%{templates/,}X")

file "ext/yarp/yarp.c" => sources do |t|
  File.write(t.name, sources.map { |source| File.binread(source) }.join("\n\n"))
end

headers.pathmap("ext/yarp/%p").pathmap("%d").uniq.each do |filepath|
  directory filepath
end

rule %r{^ext/yarp/include/.+\.h$} => ["%{ext/yarp/,}X.h", "%d"] do |t|
  cp t.source, t.name
end

task compile: ["ext/yarp/yarp.c", *templates.grep(%r{^templates/ext}).pathmap("%{templates/,}X"), *headers.pathmap("ext/yarp/%p")]

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

CLOBBER.push("ext/yarp/yarp.c", "ext/yarp/include")
CLOBBER.concat(templates.pathmap("%{templates/,}X"))

task build: :check_manifest
task test: :compile
task default: :test
