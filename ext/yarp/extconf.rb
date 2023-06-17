# frozen_string_literal: true

require "mkmf"

module Yarp
  module ExtConf
    class << self
      def configure
        configure_debug
        configure_rubyparser

        create_makefile("yarp")
      end

      def configure_debug
        if debug_mode_build?
          append_cflags("-DYARP_DEBUG_MODE_BUILD")
        end
      end

      def configure_rubyparser
        find_header("yarp.h", include_dir)

        if static_link?
          static_archive_path = File.join(build_dir, "librubyparser.a")
          unless File.exist?(static_archive_path)
            raise "Please run make to build librubyparser.a"
          end
          append_ldflags(static_archive_path)
        else
          unless find_library("rubyparser", "yp_parser_init", build_dir)
            raise "Please run make to build librubyparser.so"
          end
        end
      end

      def include_dir
        File.expand_path("../../include", __dir__)
      end

      def build_dir
        File.expand_path("../../build", __dir__)
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
