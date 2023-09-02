# frozen_string_literal: true

require "rake/testtask"

config = lambda do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new(:test, &config)

# If we're on JRuby or TruffleRuby, we don't want to bother to configure
# memcheck or debug tests.
return if RUBY_ENGINE == "jruby" || RUBY_ENGINE == "truffleruby"

# Don't bother trying to configure memcheck on old versions of Ruby.
return if RUBY_VERSION < "3.0"

require "ruby_memcheck"

namespace :test do
  RubyMemcheck::TestTask.new(valgrind_internal: :compile, &config)

  # Hide test:valgrind_internal from rake -T
  Rake::Task["test:valgrind_internal"].clear_comments

  desc "Run tests under valgrind"
  task :valgrind do
    # Recompile with YARP_DEBUG_MODE_BUILD=1
    ENV["YARP_DEBUG_MODE_BUILD"] = "1"
    Rake::Task["clobber"].invoke
    Rake::Task["test:valgrind_internal"].invoke
  end

  class GdbTestTask < Rake::TestTask
    def ruby(*args, **options, &block)
      command = "gdb --args #{RUBY} #{args.join(" ")}"
      sh(command, **options, &block)
    end
  end

  GdbTestTask.new(gdb: :compile, &config)

  class LldbTestTask < Rake::TestTask
    def ruby(*args, **options, &block)
      command = "lldb #{RUBY} -- #{args.join(" ")}"
      sh(command, **options, &block)
    end
  end

  LldbTestTask.new(lldb: :compile, &config)
end
