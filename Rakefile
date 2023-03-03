# frozen_string_literal: true

require "rake/extensiontask"
require "rake/testtask"
require "rake/clean"
require "ruby_memcheck"

RubyMemcheck.config(binary_name: "yarp")

task compile: :make

Rake::ExtensionTask.new(:compile) do |ext|
  ext.name = "yarp"
  ext.ext_dir = "ext/yarp"
  ext.lib_dir = "lib/yarp"
  ext.gem_spec = Gem::Specification.load("yarp.gemspec")
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

TEMPLATES = [
  "ext/yarp/node.c",
  "lib/yarp/node.rb",
  "lib/yarp/serialize.rb",
  "java/org/yarp/Loader.java",
  "java/org/yarp/Nodes.java",
  "java/org/yarp/AbstractNodeVisitor.java",
  "src/ast.h",
  "src/node.c",
  "src/node.h",
  "src/prettyprint.c",
  "src/serialize.c",
  "src/token_type.c",
]

desc "Generate all ERB template based files"
task templates: TEMPLATES

task make: :templates do
  sh "make"
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
  file filepath => ["bin/templates/#{filepath}.erb", "config.yml"] do |t|
    require_relative "bin/template"
    template(t.name, locals)
  end
end

desc "Lex ruby/spec files and compare with lex_compat"
task lex: :compile do
  $:.unshift(File.expand_path("lib", __dir__))
  require "yarp"
  require "ripper"

  passing = 0
  failing = 0
  colorize = ->(code, string) { "\033[#{code}m#{string}\033[0m" }

  filepaths =
    if ENV["FILEPATHS"]
      Dir[ENV["FILEPATHS"]]
    else
      Dir["vendor/spec/**/*.rb"]
    end

  filepaths.each do |filepath|
    print "#{filepath} " if ENV["CI"]
    source = File.read(filepath)

    # We're going to skip over any files that Ripper can't parse because it
    # means there are syntax errors.
    ripper = Ripper.new(source)
    ripper.parse
    next if ripper.error?

    begin
      lexed = YARP.lex_compat(source)
      value = YARP.remove_tilde_heredocs(lexed.value)
      if lexed.errors.empty? && YARP.remove_tilde_heredocs(YARP.lex_ripper(source)) == value
        print colorize.call(32, ".")
        passing += 1
      else
        warn(filepath) if ENV["VERBOSE"]
        print colorize.call(31, "E")
        failing += 1
      end

      puts if ENV["CI"]
    rescue ArgumentError => e
      puts "\nError in #{filepath}"
      raise e
    end
  end

  puts <<~RESULTS


    PASSING=#{passing}
    FAILING=#{failing}
    PERCENT=#{(passing.to_f / (passing + failing) * 100).round(2)}%
  RESULTS
end
