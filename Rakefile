# frozen_string_literal: true

require "rake/extensiontask"
require "rake/testtask"
require "rake/clean"

task :compile => :make

Rake::ExtensionTask.new(:compile) do |ext|
  ext.name = "yarp"
  ext.ext_dir = "ext/yarp"
  ext.lib_dir = "lib/yarp"
  ext.gem_spec = Gem::Specification.load("yarp.gemspec")
end

Rake::TestTask.new(test: :compile) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

ERB_GENERATED_FILES = [
  "ext/yarp/node.c",
  "lib/yarp/node.rb",
  "lib/yarp/serialize.rb",
  "src/ast.h",
  "src/node.c",
  "src/node.h",
  "src/prettyprint.c",
  "src/serialize.c",
  "src/token_type.c",
]

desc "Generate all ERB template based files"
task templates: ERB_GENERATED_FILES

task make: :templates do
  sh "make"
end

# So `rake clobber` will delete generated files
CLOBBER.concat ERB_GENERATED_FILES

escaped = ERB_GENERATED_FILES.map { |filepath| Regexp.escape(filepath) }
rule Regexp.new("\\A(#{escaped.join("|")})\\z") => ["bin/templates/%p.erb", "config.yml"] do |t|
  require_relative "bin/template"
  template(t.name, locals)
end

desc "Lex ruby/spec files and compare with lex_compat"
task lex: :compile do
  $:.unshift(File.expand_path("lib", __dir__))
  require "yarp"
  require "ripper"

  results = { passing: [], failing: [] }
  colorize = ->(code, string) { "\033[#{code}m#{string}\033[0m" }

  filepaths =
    if ENV["FILEPATHS"]
      Dir[ENV["FILEPATHS"]]
    else
      Dir["vendor/spec/**/*.rb"]
    end

  filepaths.each do |filepath|
    source = File.read(filepath)

    # We're not currently handling anything that can contain a null byte, so
    # skipping right past them here.
    if source.include?("\x0")
      print colorize.call(31, "E")
      next
    end

    result =
      YARP.lex_ripper(source).zip(YARP.lex_compat(source)).all? do |(ripper, yarp)|
        break false if yarp.nil?
        ripper[0...-1] == yarp[0...-1]
      end

    print result ? colorize.call(32, ".") : colorize.call(31, "E")
    results[result ? :passing : :failing] << filepath
  end

  puts "\n\nPASSING=#{results[:passing].length}\nFAILING=#{results[:failing].length}"
  puts "\n#{results[:failing].sort.join("\n")}"
end

task default: :test
