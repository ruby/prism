# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/clean"

task default: %i[compile test]

require_relative "templates/template"

desc "Generate all ERB template based files"
task templates: Prism::Template::TEMPLATES

make = RUBY_PLATFORM.match?(/openbsd|freebsd/) ? "gmake" : "make"
task(make: :templates) { sh(make) }
task(make_no_debug: :templates) { sh("#{make} all-no-debug") }
task(make_minimal: :templates) { sh("#{make} minimal") }

task compile: :make
task compile_no_debug: %i[make_no_debug compile]
task compile_minimal: %i[make_minimal compile]

# decorate the gem build task with prerequisites
task build: [:check_manifest, :templates]

# the C extension
task "compile:prism" => ["templates"] # must be before the ExtensionTask is created

if RUBY_ENGINE == "ruby" and !ENV["PRISM_FFI_BACKEND"]
  require "rake/extensiontask"

  Rake::ExtensionTask.new(:compile) do |ext|
    ext.name = "prism"
    ext.ext_dir = "ext/prism"
    ext.lib_dir = "lib/prism"
    ext.gem_spec = Gem::Specification.load("prism.gemspec")
  end
elsif RUBY_ENGINE == "jruby"
  require "rake/javaextensiontask"

  # This compiles java to make sure any templating changes produces valid code.
  Rake::JavaExtensionTask.new(:compile) do |ext|
    ext.name = "prism"
    ext.ext_dir = "java"
    ext.lib_dir = "tmp"
    ext.source_version = "1.8"
    ext.target_version = "1.8"
    ext.gem_spec = Gem::Specification.load("prism.gemspec")
  end
end

# So `rake clobber` will delete generated files
CLOBBER.concat(Prism::Template::TEMPLATES)
CLOBBER.concat(["build"])
CLOBBER << "lib/prism/prism.#{RbConfig::CONFIG["DLEXT"]}"

Prism::Template::TEMPLATES.each do |filepath|
  desc "Generate #{filepath}"
  file filepath => ["templates/#{filepath}.erb", "templates/template.rb", "config.yml"] do |t|
    Prism::Template.render(t.name)
  end
end

namespace :build do
  task :dev_version_set do
    filepath = File.expand_path("prism.gemspec", __dir__)
    File.write(filepath, File.read(filepath).sub(/spec\.version = ".+?"/, %Q{spec.version = "9999.9.9"}))
  end

  task :dev_version_clear do
    sh "git checkout -- prism.gemspec Gemfile.lock"
  end

  desc "Build a development version of the gem"
  task dev: ["build:dev_version_set", "build", "build:dev_version_clear"]
end
