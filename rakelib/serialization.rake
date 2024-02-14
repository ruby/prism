# frozen_string_literal: true

task "test:java_loader" do
  # Recompile with PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS=1
  # Due to some JRuby bug this does not get propagated to the compile task, so require the caller to set the env var
  # ENV["PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS"] = "1"
  raise "this task requires $SERIALIZE_ONLY_SEMANTICS_FIELDS to be set" unless ENV["PRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS"]

  Rake::Task["clobber"].invoke
  Rake::Task["test:java_loader:internal"].invoke
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
    source_bytes = File.binread(path).unpack('c*')
    parse_result = org.prism.Loader.load(serialized.unpack('c*'), source_bytes)
    puts parse_result.value
  end
end
