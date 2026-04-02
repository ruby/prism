# frozen_string_literal: true

task "test:java_loader" do
  Rake::Task["clobber"].invoke
  # All Java API consumers want semantic-only build
  ENV["CFLAGS"] = "-DPRISM_SERIALIZE_ONLY_SEMANTICS_FIELDS=1"
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
    parse_result = org.ruby_lang.prism.Loader.load(serialized.unpack('c*'))
    puts parse_result.value
  end
end
