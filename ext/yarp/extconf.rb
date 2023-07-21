# frozen_string_literal: true

require "mkmf"
require "rbconfig"
require "rake"

module Yarp
  module ExtConf
    class << self
      def configure
        configure_c_extension
        configure_rubyparser

        create_makefile("yarp")
      end

      def configure_c_extension
        have_func "mmap"
        have_func "snprintf"
        append_cflags("-DYARP_DEBUG_MODE_BUILD") if debug_mode_build?
        append_cflags("-fvisibility=hidden")
      end

      def configure_rubyparser
        if static_link?
          static_archive_path = File.join(build_dir, "librubyparser.a")
          unless File.exist?(static_archive_path)
            build_static_rubyparser
          end
          append_ldflags(static_archive_path)
          unless find_library("rubyparser", "yp_parser_init", build_dir)
            raise "could not link against #{File.basename(static_archive_path)}"
          end
        else
          shared_library_path = File.join(build_dir, "librubyparser.#{RbConfig::CONFIG["DLEXT"]}")
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
          if !File.exist?("configure") && Dir.exist?(".git")
            # this block only exists to support building the gem from a "git" source,
            # normally we package up the configure and other files in the gem itself
            Rake.sh("autoconf")
            Rake.sh("autoheader")
            Rake.sh("templates/template.rb")
          end
          Rake.sh("sh", "configure") # explicit "sh" for Windows where shebangs are not supported
          Rake.sh("make", target)
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

if arg_config("--help")
  Yarp::ExtConf.print_help
  exit!(0)
end

Yarp::ExtConf.configure
