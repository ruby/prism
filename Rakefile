# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/extensiontask"
require "rake/clean"

require_relative "templates/template"

templates = Rake::FileList.new("templates/**/*.erb")
sources = Rake::FileList.new("src/**/*.c").concat(templates.grep(%r{^templates/src/.+\.c\.erb$}).pathmap("%{templates/,}X")).uniq
headers = Rake::FileList.new("include/**/*.h").concat(templates.grep(%r{^templates/include/.+\.h\.erb$}).pathmap("%{templates/,}X")).uniq

generated_templates = templates.pathmap("%{templates/,}X")
generated_sources = sources.pathmap("ext/yarp/%{.*,*}X.c") { |filepath| filepath.tr("/", "-") }
generated_headers = headers.pathmap("ext/yarp/%p")

generated = generated_templates.concat(generated_sources).concat(generated_headers)
CLOBBER.concat(generated)

templates.each do |filepath|
  file filepath.pathmap("%{templates/,}X") => [filepath, "templates/template.rb", "config.yml"] do |t|
    template(t.name, locals)
  end
end

desc "Generate all ERB template based files"
task templates: generated_templates

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

task compile: generated

directory "pkg"

sopath = "pkg/librubyparser.#{RbConfig::CONFIG["SOEXT"]}"
CLOBBER.push(sopath)

file sopath => [*sources, *headers, "pkg"] do |t|
  sh "cc -std=c99 -Wall -Wconversion -Wextra -Wpedantic -Wundef -Werror -fvisibility=hidden -DYP_EXPORT_SYMBOLS -Iinclude -shared -o #{t.name} #{sources.join(" ")}"
end

task shared: sopath

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

task build: [:check_manifest, *generated]
task test: :compile
task default: :test
