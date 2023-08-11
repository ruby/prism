# frozen_string_literal: true

known_failures = %w[seattlerb/heredoc_nested.txt]
fixtures = File.expand_path("../test/fixtures", __dir__)
serialized_dir = File.expand_path("../serialized", fixtures)

desc "Serialize test fixtures and save it to .serialized files"
task "test:serialize_fixtures" do
  $:.unshift(File.expand_path("../lib", __dir__))
  require "yarp"
  require "fileutils"

  Dir["**/*.txt", base: fixtures].each do |relative|
    next if known_failures.include?(relative)
    path = "#{fixtures}/#{relative}"
    serialized_path = "#{serialized_dir}/#{relative}"

    serialized = YARP.dump_file(path)
    FileUtils.mkdir_p(File.dirname(serialized_path))
    File.write(serialized_path, serialized)
  end
end

task "test:java_loader" do
  require 'java'
  require_relative '../tmp/yarp.jar'
  java_import 'org.yarp.Nodes$Source'

  Dir["**/*.txt", base: fixtures].each do |relative|
    next if known_failures.include?(relative)
    path = "#{fixtures}/#{relative}"
    serialized_path = "#{serialized_dir}/#{relative}"
    serialized = File.binread(serialized_path).unpack('c*')

    puts
    puts path
    source_bytes = File.binread(path).unpack('c*')
    source = Source.new(source_bytes.to_java(:byte))
    parse_result = org.yarp.Loader.load(serialized, source)
    puts parse_result.value
  end
end
