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

# A stamp is a file that records some contents, such as the values of the
# environment variables that a build reads, and is rewritten only when they
# differ from what it holds. Rake only compares file timestamps, so a file that
# depends on a stamp is out of date exactly when the contents change. The
# contents are computed when the stamp is checked rather than when this file is
# loaded, so that they reflect the files generated earlier in the same run.
class StampTask < Rake::FileTask
  def self.define(name, &contents)
    define_task(name) do |task|
      FileUtils.mkdir_p(File.dirname(task.name))
      File.write(task.name, task.contents)
    end.tap { |task| task.contents_block = contents }
  end

  attr_writer :contents_block

  def contents
    @contents_block.call
  end

  def needed?
    super || File.read(name) != contents
  end
end

desc "Generate all ERB template based files"
task templates: Prism::Template::TEMPLATES

# The make that builds libprism runs one job per processor unless MAKEFLAGS is
# already set. The variable is set in this process's environment, so the make
# that rake-compiler runs for the C extension uses the same number of jobs.
make = RUBY_PLATFORM.match?(/openbsd|freebsd/) ? "gmake" : "make"
task(make: :templates) {
  require "etc"
  ENV["MAKEFLAGS"] ||= "-j#{Etc.nprocessors}"
  sh(make)
}

task compile: :make

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
  require "shellwords"

  extension = Rake::ExtensionTask.new("prism", PRISM_SPEC) do |ext|
    ext.ext_dir = "ext/prism"
    ext.lib_dir = "lib/prism"
    ext.cross_compile = true
    ext.cross_platform = RCD_CROSS_PLATFORMS

    # The build options of extconf.rb are inputs to the build that
    # rake-compiler does not track: it configures the extension again only
    # when extconf.rb itself changes. So each combination of options builds in
    # its own directory, and switching between them never reuses objects that
    # were compiled with different flags. An option is on when its environment
    # variable is set or its flag is passed after `--`, as extconf.rb reads it.
    #
    # Match mkmf's enable_config: an enable option takes precedence over a
    # disable option, and both take precedence over the environment default.
    # Option values do not affect enable_config's presence checks.
    options = [
      *Shellwords.split(RbConfig::CONFIG["configure_args"] || ""),
      *Shellwords.split(ENV["CONFIGURE_ARGS"] || ""),
      *ext.config_options,
      *ext.extra_options
    ].filter_map do |option|
      argument, value = option.split("=", 2)
      argument = argument.tr("_", "-")

      unless argument.start_with?("--")
        next unless value
        argument = "--#{argument.downcase}"
      end

      argument
    end

    variant = ["debug", "minimal", "ndebug", "ubsan"].filter_map do |name|
      name if (
        options.include?("--enable-build-#{name}") ||
        (!options.include?("--disable-build-#{name}") && ENV.key?("PRISM_BUILD_#{name.upcase}"))
      )
    end

    unless variant.empty?
      ext.tmp_dir = "tmp/#{variant.join("-")}"
      task(:compile) { warn "Built the #{variant.join(" and ")} variant of the extension in #{ext.tmp_dir}" }
    end
  end

  # The Makefile that extconf.rb writes lists the sources and headers that
  # existed when it ran, and rake-compiler runs extconf.rb again only when
  # extconf.rb itself changes. So the Makefile depends on a stamp of that list,
  # and adding or removing a source or header configures the extension again,
  # which recompiles every object through the rule that extconf.rb adds.
  extension_files = "tmp/extension.files"

  StampTask.define(extension_files) do
    Dir["ext/prism/*.{c,h}", "src/**/*.c", "include/**/*.h"].sort.map { |path| "#{path}\n" }.join
  end

  file "#{extension.tmp_dir}/#{extension.platform}/#{extension.name}/#{RUBY_VERSION}/Makefile" => extension_files
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

# So `rake clobber` will delete generated files
CLOBBER.concat(Prism::Template::TEMPLATES)
CLOBBER.concat(["build"])
CLOBBER << "lib/prism/prism.#{RbConfig::CONFIG["DLEXT"]}"
CLOBBER << "java/wasm/src/main/resources/prism.wasm"

# The generated files depend on the environment variables listed in
# Prism::Template::ENVIRONMENT as well as on their templates, so they depend on
# a stamp of the variables' values.
template_environment = "tmp/template.env"

StampTask.define(template_environment) do
  Prism::Template::ENVIRONMENT.map { |name, value| "#{name}=#{value.inspect}\n" }.join
end

Prism::Template::TEMPLATES.each do |filepath|
  desc "Generate #{filepath}"
  file filepath => ["templates/#{filepath}.erb", "templates/template.rb", "config.yml", template_environment] do |t|
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
