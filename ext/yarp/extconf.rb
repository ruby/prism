# frozen_string_literal: true

require "mkmf"

append_cflags("-std=c99")
append_cflags(["-Wall", "-Wconversion", "-Wextra", "-Wpedantic", "-Wundef"])
append_cflags("-Werror")
append_cflags("-fvisibility=hidden")

if enable_config("debug-mode-build", ENV.fetch("YARP_DEBUG_MODE_BUILD", false))
  append_cflags("-DYARP_DEBUG_MODE_BUILD=1")
  append_cflags("-O0")
end

if enable_config("ndebug", ENV.fetch("YARP_NO_DEBUG_BUILD", false))
  append_cflags("-DNDEBUG=1")
  append_cflags("-O3")
end

have_func("mmap")
have_func("snprintf")

unless find_header("yarp.h", File.join(__dir__, "include"))
  raise "yarp.h is required"
end

# Explicitly look for the extension header in the parent directory because we
# want to consistently look for yarp/extension.h in our source files to line up
# with our mirroring in CRuby.
unless find_header("yarp/extension.h", File.join(__dir__, ".."))
  raise "yarp/extension.h is required"
end

create_makefile("yarp/yarp")
