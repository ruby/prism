# frozen_string_literal: true

task "test:java_loader" do
  # Recompile with PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS=1
  # Due to some JRuby bug this does not get propagated to the compile task, so require the caller to set the env var
  # ENV["PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS"] = "1"
  raise "this task requires $SERIALIZE_ONLY_SEMANTICS_FIELDS to be set" unless ENV["PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS"]

  # Generate the expected newlines with the default (full) serialization mode
  # in a subprocess, since newlines.rb needs location fields.
  sh({ "PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS" => nil }, "bundle", "exec", "rake", "clobber", "test:java_loader:newline_fixtures")

  Rake::Task["clobber"].invoke
  Rake::Task["test:java_loader:internal"].invoke
end

# Generates the fixtures for the MarkNewlinesVisitor check of test:java_loader:
# for every file of the corpus, the lines marked by
# Prism::ParseResult#mark_newlines! (newlines.rb), so that the Java loader test
# can check that MarkNewlinesVisitor.java marks exactly the same lines.
task "test:java_loader:newline_fixtures" => :compile do
  raise "this task requires the default (full) serialization mode" if ENV["PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS"]

  $:.unshift(File.expand_path("../lib", __dir__))
  require "prism"

  root = File.expand_path("..", __dir__)
  files = Dir["test/prism/{,api/,encoding/,result/,ruby/}*.rb", base: root] +
          Dir["test/prism/fixtures/**/*.txt", base: root]

  fixtures = []
  files.sort.each do |file|
    path = File.join(root, file)
    result = Prism.parse_file(path)
    next unless result.success?

    result.mark_newlines!
    queue = [result.value]
    lines = []
    while node = queue.shift
      queue.concat(node.compact_child_nodes)
      lines << result.source.line(node.location.start_offset) if node.newline_flag?
    end

    fixtures << "#{path}\t#{lines.sort.join(" ")}"
  end

  output = File.expand_path("../java/newline_fixtures.txt", __dir__)
  require "fileutils"
  FileUtils.mkdir_p(File.dirname(output))
  File.write(output, fixtures.join("\n") + "\n")
  puts "Wrote the expected newlines of #{fixtures.size} files to #{output}"
end

task "test:java_loader:internal" => :compile do
  fixtures = File.expand_path("../test/prism/fixtures", __dir__)

  $:.unshift(File.expand_path("../lib", __dir__))
  require "prism"
  raise "this task requires the FFI backend" unless Prism::BACKEND == :FFI
  require "fileutils"
  require 'java'
  require_relative '../tmp/prism.jar'

  Dir["**/*.txt", base: fixtures].each do |relative|
    path = "#{fixtures}/#{relative}"
    puts
    puts path
    serialized = Prism.dump_file(path)
    parse_result = org.ruby_lang.prism.Loader.load(serialized.unpack('c*'))
    puts parse_result.value
  end

  # Check that MarkNewlinesVisitor.java (run by Loader.load() above) marks
  # exactly the same lines as Ruby's newlines.rb, using the fixtures generated
  # by the test:java_loader:newline_fixtures task.
  newline_fixtures = File.expand_path("../java/newline_fixtures.txt", __dir__)
  raise "no #{newline_fixtures}, run the test:java_loader task to generate it" unless File.exist?(newline_fixtures)

  collect_newlines = -> (node, source, lines) {
    return if node.nil?
    lines << source.line(node.startOffset) if node.hasNewLineFlag
    node.childNodes.each { |child| collect_newlines.call(child, source, lines) }
  }

  failures = []
  checked = 0
  File.readlines(newline_fixtures, chomp: true).each do |fixture|
    path, expected = fixture.split("\t", 2)

    serialized = Prism.dump_file(path)
    parse_result = org.ruby_lang.prism.Loader.load(serialized.unpack('c*'))

    lines = []
    collect_newlines.call(parse_result.value, parse_result.source, lines)
    actual = lines.sort.join(" ")

    checked += 1
    if actual != (expected || "")
      failures << "#{path}\n  ruby: #{expected}\n  java: #{actual}"
    end
  end

  puts
  puts "Checked the newlines of #{checked} files against MarkNewlinesVisitor"
  unless failures.empty?
    abort "#{failures.size} of #{checked} files have different newline flags " \
          "between Ruby's newlines.rb and Java's MarkNewlinesVisitor:\n#{failures.join("\n")}"
  end
end
