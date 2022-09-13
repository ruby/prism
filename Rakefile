# frozen_string_literal: true

require "bundler/gem_tasks"
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
  require "bundler/setup"
  require "yarp"
  require "ripper"

  filepath = File.expand_path("KNOWN_FAILURES", __dir__)
  known_failures = File.readlines(filepath, chomp: true)

  results = { passing: 0, failing: 0 }
  colorize = ->(code, string) { "\033[#{code}m#{string}\033[0m" }

  passing = 0
  failing = 0

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

    if result
      known_failures.delete(filepath) if known_failures.include?(filepath)
      passing += 1
    else
      known_failures << filepath unless known_failures.include?(filepath)
      failing += 1
    end
  end

  File.write(filepath, known_failures.sort.join("\n") + "\n") unless ENV["FILEPATHS"]  
  puts "\n\nPASS=#{passing}\nFAIL=#{failing}"
end

task default: :test
