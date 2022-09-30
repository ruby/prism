# frozen_string_literal: true

require "rake/extensiontask"
require "rake/testtask"

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
    result =
      YARP.lex_ripper(filepath).zip(YARP.lex_compat(filepath)).all? do |(ripper, yarp)|
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
