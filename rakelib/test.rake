# frozen_string_literal: true

require "rake/testtask"

config = lambda do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new(:test, &config)

namespace :test do
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

  desc "Run the tests for the rust bindings"
  task :rust do
    ["rust/ruby-prism", "rust/ruby-prism-sys"].each do |dir|
      Dir.chdir(dir) do
        sh("cargo test")
      end
    end
  end
end

# If we're on JRuby or TruffleRuby, we don't want to bother to configure
# memcheck or debug tests.
return if RUBY_ENGINE == "jruby" || RUBY_ENGINE == "truffleruby"

# Don't bother trying to configure memcheck on old versions of Ruby.
return if RUBY_VERSION < "3.0"

namespace :test do
  begin
    require "ruby_memcheck"
    RubyMemcheck.config(use_only_ruby_free_at_exit: false)
    RubyMemcheck::TestTask.new(valgrind_internal: :compile, &config)
  rescue LoadError
    task :valgrind_internal do
      puts "\e[31mruby_memcheck gem not available. Try running with BUNDLE_WITH=memcheck\e[0m"
      exit 1
    end
  end

  # Hide test:valgrind_internal from rake -T
  Rake::Task["test:valgrind_internal"].clear_comments

  # The tests run under valgrind against the debug variant, which copies the
  # input into its own allocation so that reads past its end are reported. The
  # Rakefile chooses the variant when it is loaded, so the variable is set for a
  # new rake process rather than in this one.
  desc "Run tests under valgrind"
  task :valgrind do
    sh({ "PRISM_BUILD_DEBUG" => "1" }, "bundle", "exec", "rake", "test:valgrind_internal")
  end

  desc "Run tests with the address sanitizer"
  task :asan do
    sh({ "PRISM_BUILD_ASAN" => "1" }, "bundle", "exec", "rake", "compile")
    Rake::Task["test:asan_internal"].invoke
  end

  class AsanTestTask < Rake::TestTask
    def ruby(args, **options, &block)
      require "shellwords"
      compiler = Shellwords.split(RbConfig::CONFIG.fetch("CC"))

      if RbConfig::CONFIG.fetch("host_os").start_with?("darwin")
        preload = "DYLD_INSERT_LIBRARIES"
        libraries = ["libclang_rt.asan_osx_dynamic.dylib"]
      else
        preload = "LD_PRELOAD"
        cpu = RbConfig::CONFIG.fetch("host_cpu")
        libraries = ["libclang_rt.asan-#{cpu}.so", "libasan.so"]
      end

      runtime =
        libraries.find do |library|
          path = IO.popen([*compiler, "-print-file-name=#{library}"], &:read).strip
          break path if File.file?(path)
        end

      abort "Could not locate the AddressSanitizer runtime for #{compiler.join(' ')}" unless runtime

      # Set the preload in the shell that starts the test runner, since macOS
      # can strip DYLD_INSERT_LIBRARIES when launching the shell itself.
      # Let Ruby manage alternate signal stacks and scan native stacks for GC
      # roots. LeakSanitizer would also report allocations from the host VM.
      preloads = [runtime, ENV[preload]].compact.join(":")
      asan_options = ENV.fetch("ASAN_OPTIONS", "detect_leaks=0:use_sigaltstack=0:detect_stack_use_after_return=0")
      sh("#{preload}=#{Shellwords.escape(preloads)} ASAN_OPTIONS=#{Shellwords.escape(asan_options)} #{Shellwords.escape(RUBY)} #{args}", **options, &block)
    end
  end

  AsanTestTask.new(:asan_internal, &config)
  Rake::Task["test:asan_internal"].clear_comments

  # The tests run against the variant built with the undefined behavior
  # sanitizer, which aborts on the first undefined behavior it detects. As with
  # test:valgrind, the variable is set for a new rake process.
  desc "Run tests with the undefined behavior sanitizer"
  task :ubsan do
    sh({ "PRISM_BUILD_UBSAN" => "1" }, "bundle", "exec", "rake", "compile", "test")
  end
end
