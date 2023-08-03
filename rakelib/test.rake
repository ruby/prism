# frozen_string_literal: true

require "rake/testtask"

config = lambda do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new(:test, &config)
Rake::TestTask.new(:test_install, &config)

# Skip valgrind tests if we're on JRuby or TruffleRuby.
return if RUBY_ENGINE == "jruby" || RUBY_ENGINE == "truffleruby"

require "ruby_memcheck"
RubyMemcheck.config(binary_name: "yarp")

namespace :test do
  RubyMemcheck::TestTask.new(valgrind_internal: :compile, &config)
  Rake::Task["test:valgrind_internal"].clear_comments # Hide test:valgrind_internal from rake -T

  desc "Run tests under valgrind"
  task :valgrind do
    ENV["YARP_DEBUG_MODE_BUILD"] = "1" # Recompile with YARP_DEBUG_MODE_BUILD=1
    Rake::Task["clobber"].invoke
    Rake::Task["test:valgrind_internal"].invoke
  end

  class GDBTestTask < Rake::TestTask
    def ruby(*args, **options, &block)
      command = "gdb --args #{RUBY} #{args.join(" ")}"
      sh(command, **options, &block)
    end
  end

  GDBTestTask.new(gdb: :compile, &config)

  class LLDBTestTask < Rake::TestTask
    def ruby(*args, **options, &block)
      command = "lldb #{RUBY} -- #{args.join(" ")}"
      sh(command, **options, &block)
    end
  end

  LLDBTestTask.new(lldb: :compile, &config)
end
