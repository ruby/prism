test_config = lambda do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new(test: :compile, &test_config)

class GdbTestTask < Rake::TestTask
  def ruby(*args, **options, &block)
    command = "gdb --args #{RUBY} #{args.join(" ")}"
    sh(command, **options, &block)
  end
end

class LldbTestTask < Rake::TestTask
  def ruby(*args, **options, &block)
    command = "lldb #{RUBY} -- #{args.join(" ")}"
    sh(command, **options, &block)
  end
end

namespace :test do
  RubyMemcheck::TestTask.new(valgrind_internal: :compile, &test_config)
  Rake::Task['test:valgrind_internal'].clear_comments # Hide test:valgrind_internal from rake -T

  desc "Run tests under valgrind"
  task :valgrind do
    # Recompile with YARP_DEBUG_MODE_BUILD=1
    ENV['YARP_DEBUG_MODE_BUILD'] = '1'
    Rake::Task['clobber'].invoke
    Rake::Task['test:valgrind_internal'].invoke
  end

  GdbTestTask.new(gdb: :compile, &test_config)
  LldbTestTask.new(lldb: :compile, &test_config)
end
