# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/clean"

begin
  require "rake_compiler_dock"
rescue LoadError
  # rake_compiler_dock is not available in versioned Gemfiles (gemfiles/2.7/, etc.)
  # that don't include the gem. The native gem tasks will not be defined.
end

PRISM_SPEC = Bundler.load_gemspec("prism.gemspec")

task default: %i[compile test]

require_relative "templates/template"

desc "Generate all ERB template based files"
task templates: Prism::Template::TEMPLATES

make = RUBY_PLATFORM.match?(/openbsd|freebsd/) ? "gmake" : "make"
task(make: :templates) {
  ENV["MAKEFLAGS"] ||= "-j"
  sh(make)
}
task(make_no_debug: :templates) { sh("#{make} all-no-debug") }
task(make_minimal: :templates) { sh("#{make} minimal") }

task compile: :make
task compile_no_debug: %i[make_no_debug compile]
task compile_minimal: %i[make_minimal compile]

# decorate the gem build task with prerequisites
task build: [:check_manifest, :templates]

# the C extension
task "compile:prism" => ["templates"] # must be before the ExtensionTask is created

RCD_CROSS_PLATFORMS = %w[
  aarch64-linux-gnu
  aarch64-linux-musl
  aarch64-mingw-ucrt
  arm-linux-gnu
  arm-linux-musl
  arm64-darwin
  x64-mingw-ucrt
  x86_64-darwin
  x86_64-linux-gnu
  x86_64-linux-musl
]

if defined?(RakeCompilerDock)
  RakeCompilerDock.set_ruby_cc_version(">= 3.3")

  namespace "gem" do
    RCD_CROSS_PLATFORMS.each do |platform|
      desc "build native gem for #{platform}"
      task platform do
        RakeCompilerDock.sh(<<~EOF, platform: platform, verbose: true)
          gem install bundler --no-document &&
          bundle &&
          bundle exec rake gem:#{platform}:build
        EOF
      end

      namespace platform do
        # this runs in the rake-compiler-dock docker container
        task "build" => ["templates"] do
          Rake::Task["native:#{platform}"].invoke
          Rake::Task["pkg/#{PRISM_SPEC.full_name}-#{Gem::Platform.new(platform)}.gem"].invoke
        end
      end
    end

    desc "build native gem for all platforms"
    task "all" => [RCD_CROSS_PLATFORMS, "build"].flatten
  end
end

if RUBY_ENGINE == "ruby" and !ENV["PRISM_FFI_BACKEND"]
  require "rake/extensiontask"

  Rake::ExtensionTask.new("prism", PRISM_SPEC) do |ext|
    ext.ext_dir = "ext/prism"
    ext.lib_dir = "lib/prism"
    ext.cross_compile = true
    ext.cross_platform = RCD_CROSS_PLATFORMS
  end
elsif RUBY_ENGINE == "jruby"
  require "rake/javaextensiontask"

  # This compiles java to make sure any templating changes produces valid code.
  Rake::JavaExtensionTask.new(:compile) do |ext|
    ext.name = "prism"
    ext.ext_dir = "java/api"
    ext.lib_dir = "tmp"
    ext.release = "21"
    ext.gem_spec = PRISM_SPEC
  end
end

desc "Temporarily set VERSION to a unique timestamp"
task "set-version-to-timestamp" do
  # this task is used by bin/test-gem-build
  # to test building, packaging, and installing a precompiled gem
  version_re = /spec\.version = "(.*)"/

  gemspec_path = File.join(__dir__, "prism.gemspec")
  gemspec_contents = File.read(gemspec_path)

  current_version_string = version_re.match(gemspec_contents)[1]
  current_version = Gem::Version.new(current_version_string)

  fake_version = Gem::Version.new(format("%s.test.%s", current_version.bump, Time.now.strftime("%Y.%m%d.%H%M")))

  unless gemspec_contents.gsub!(version_re, "spec.version = \"#{fake_version}\"")
    raise("Could not hack the VERSION constant")
  end

  File.write(gemspec_path, gemspec_contents)
  puts "NOTE: wrote version as \"#{fake_version}\""
end

# So `rake clobber` will delete generated files
CLOBBER.concat(Prism::Template::TEMPLATES)
CLOBBER.concat(["build"])
CLOBBER << "lib/prism/prism.#{RbConfig::CONFIG["DLEXT"]}"
CLOBBER << "java/wasm/src/main/resources/prism.wasm"

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

task :build_in_docker => :templates do
  # Versions from https://github.com/ruby/ruby/blob/master/.github/workflows/compilers.yml
  versions = (7..15).to_a
  versions.each do |version|
    dockerfile = <<~DOCKERFILE
    FROM docker.io/library/gcc:#{version}
    COPY Makefile /prism/
    COPY src /prism/src
    COPY include /prism/include
    WORKDIR /prism
    RUN gcc --version
    RUN make SOEXT=so
    DOCKERFILE
    File.write 'Dockerfile', dockerfile
    sh "docker build ."
    rm 'Dockerfile'
  end
end
