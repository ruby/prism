# frozen_string_literal: true

task "test:java_loader" do
  # Recompile with YARP_SERIALIZE_ONLY_SEMANTICS_FIELDS=1
  # Due to some JRuby bug this does not get propagated to the compile task, so require the caller to set the env var
  # ENV["YARP_SERIALIZE_ONLY_SEMANTICS_FIELDS"] = "1"
  raise "this task requires $SERIALIZE_ONLY_SEMANTICS_FIELDS to be set" unless ENV["YARP_SERIALIZE_ONLY_SEMANTICS_FIELDS"]

  Rake::Task["clobber"].invoke
  Rake::Task["test:java_loader:internal"].invoke
end

task "test:java_loader:internal" => :compile do
  fixtures = File.expand_path("../test/yarp/fixtures", __dir__)

  $:.unshift(File.expand_path("../lib", __dir__))
  require "yarp"
  raise "this task requires the FFI backend" unless YARP::BACKEND == :FFI
  require "fileutils"
  require 'java'
  require_relative '../tmp/yarp.jar'
  java_import 'org.yarp.Nodes$Source'

  Dir["**/*.txt", base: fixtures].each do |relative|
    path = "#{fixtures}/#{relative}"
    puts
    puts path
    serialized = YARP.dump_file(path)
    source_bytes = File.binread(path).unpack('c*')
    source = Source.new(source_bytes.to_java(:byte))
    parse_result = org.yarp.Loader.load(serialized.unpack('c*'), source)
    puts parse_result.value
  end
end
