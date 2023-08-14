# frozen_string_literal: true

require "rbconfig"

module Yarp
  module ExtConf
    class << self
      def configure
        unless RUBY_ENGINE == "ruby"
          # On non-CRuby we only need the shared library, so build only that and not the C extension.
          # We also avoid `require "mkmf"` as that prepends the LLVM toolchain to PATH on TruffleRuby,
          # but we want to use the native toolchain here since librubyparser is run natively.
          build_shared_rubyparser
          File.write("Makefile", "all install clean:\n\t@#{RbConfig::CONFIG["NULLCMD"]}\n")
          return
        end

        require "mkmf"
        configure_c_extension
        configure_rubyparser

        create_makefile("yarp/yarp")

        if static_link?
          File.open('Makefile', 'a') do |mf|
            mf.puts
            mf.puts '# Automatically rebuild the extension if librubyparser.a changed'
            mf.puts '$(TARGET_SO): $(LOCAL_LIBS)'
          end
        end
      end

      def configure_c_extension
        append_cflags("-DYARP_DEBUG_MODE_BUILD") if debug_mode_build?
        append_cflags("-fvisibility=hidden")
      end

      def configure_rubyparser
        if static_link?
          static_archive_path = File.join(build_dir, "librubyparser.a")
          unless File.exist?(static_archive_path)
            build_static_rubyparser
          end
          $LOCAL_LIBS << " #{static_archive_path}"
        else
          shared_library_path = File.join(build_dir, "librubyparser.#{RbConfig::CONFIG["SOEXT"]}")
          unless File.exist?(shared_library_path)
            build_shared_rubyparser
          end
          unless find_library("rubyparser", "yp_parser_init", build_dir)
            raise "could not link against #{File.basename(shared_library_path)}"
          end
        end

        find_header("yarp.h", include_dir) or raise "yarp.h is required"

        # Explicitly look for the extension header in the parent directory
        # because we want to consistently look for yarp/extension.h in our
        # source files to line up with our mirroring in CRuby.
        find_header("yarp/extension.h", File.join(__dir__, "..")) or raise "yarp/extension.h is required"
      end

      def build_shared_rubyparser
        build_target_rubyparser "build/librubyparser.#{RbConfig::CONFIG["SOEXT"]}"
      end

      def build_static_rubyparser
        build_target_rubyparser "build/librubyparser.a"
      end

      def build_target_rubyparser(target)
        Dir.chdir(root_dir) do
          if !File.exist?("include/yarp/ast.h") && Dir.exist?(".git")
            # this block only exists to support building the gem from a "git" source,
            # normally we package up the configure and other files in the gem itself
            system("templates/template.rb", exception: true)
          end
          system("make", target, exception: true)
        end
      end

      def root_dir
        File.expand_path("../..", __dir__)
      end

      def include_dir
        File.join(root_dir, "include")
      end

      def build_dir
        File.join(root_dir, "build")
      end

      def print_help
        print(<<~TEXT)
          USAGE: ruby #{$PROGRAM_NAME} [options]

            Flags that are always valid:

                --enable-static
                --disable-static
                    Enable or disable static linking against librubyparser.
                    The default is to statically link.

                --enable-debug-mode-build
                    Enable debug mode build.
                    You may also use set YARP_DEBUG_MODE_BUILD environment variable.

                --help
                    Display this message.

            Environment variables used:

                YARP_DEBUG_MODE_BUILD
                    Equivalent to `--enable-debug-mode-build` when set, even if nil or blank.

        TEXT
      end

      def static_link?
        enable_config("static", true)
      end

      def debug_mode_build?
        enable_config("debug-mode-build", ENV["YARP_DEBUG_MODE_BUILD"] || false)
      end
    end
  end
end

if ARGV.delete("--help")
  Yarp::ExtConf.print_help
  exit!(0)
end

Yarp::ExtConf.configure
