# frozen_string_literal: true

require "rake/extensiontask"
require "rake/testtask"
require "rake/clean"

task compile: :make

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

# So `rake clobber` will delete generated files
CLOBBER.concat(TEMPLATES)

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

  results = { passing: [], failing: [] }
  colorize = ->(code, string) { "\033[#{code}m#{string}\033[0m" }

  accepted_encodings = [
    Encoding::ASCII_8BIT,
    Encoding::ISO_8859_9,
    Encoding::US_ASCII,
    Encoding::UTF_8
  ]

  filepaths =
    if ENV["FILEPATHS"]
      Dir[ENV["FILEPATHS"]]
    else
      Dir["vendor/spec/**/*.rb"]
    end

  filepaths.each do |filepath|
    source = File.read(filepath)

    # If this file can't be parsed at all, then don't try to compare it to
    # ripper's output.
    ripper = Ripper.new(source).tap(&:parse)
    next if ripper.error?

    # If this file has an encoding that we don't support, then don't try to
    # compare it to ripper's output.
    unless accepted_encodings.include?(ripper.encoding)
      print colorize.call(31, "E")
      results[:failing] << filepath
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
