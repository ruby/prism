# frozen_string_literal: true

require "rbconfig"

if ARGV.delete("--help")
  print(<<~TEXT)
    USAGE: ruby #{$PROGRAM_NAME} [options]

      Flags that are always valid:

          --enable-build-debug
              Enable debug build.
              You may also set the PRISM_BUILD_DEBUG environment variable.

          --enable-build-minimal
              Enable minimal build.
              You may also set the PRISM_BUILD_MINIMAL environment variable.

          --help
              Display this message.

      Environment variables used:

          PRISM_BUILD_DEBUG
              Equivalent to `--enable-build-debug` when set, even if nil or blank.

          PRISM_BUILD_MINIMAL
              Equivalent to `--enable-build-minimal` when set, even if nil or blank.

  TEXT
  exit!(0)
end

# If this gem is being build from a git source, then we need to run
# templating if it hasn't been run yet. In normal packaging, we would have
# shipped the templated files with the gem, so this wouldn't be necessary.
def generate_templates
  Dir.chdir(File.expand_path("../..", __dir__)) do
    if !File.exist?("include/prism/ast.h") && Dir.exist?(".git")
      system("templates/template.rb", exception: true)
    end
  end
end

# Runs `make` in the root directory of the project. Note that this is the
# `Makefile` for the overall project, not the `Makefile` that is being generated
# by this script.`
def make(env, target)
  puts "Running make #{target} with #{env.inspect}"
  Dir.chdir(File.expand_path("../..", __dir__)) do
    system(
      env,
      RUBY_PLATFORM.match?(/openbsd|freebsd/) ? "gmake" : "make",
      target,
      exception: true
    )
  end
end

# On non-CRuby we only need the shared library since we'll interface with it
# through FFI, so we'll build only that and not the C extension. We also avoid
# `require "mkmf"` as that prepends the GraalVM LLVM toolchain to PATH on TruffleRuby < 24.0,
# but we want to use the system toolchain here since libprism is run natively.
if RUBY_ENGINE != "ruby"
  generate_templates
  soext = RbConfig::CONFIG["SOEXT"]
  # Pass SOEXT to avoid an extra subprocess just to query that
  make({ "SOEXT" => soext }, "build/libprism.#{soext}")
  File.write("Makefile", "all install clean:\n\t@#{RbConfig::CONFIG["NULLCMD"]}\n")
  return
end

# We're going to need to run `make` using prism's `Makefile`.
# We want to use the same toolchain (compiler, flags, etc) to compile libprism.a and
# the C extension since they will be linked together.
# The C extension uses RbConfig, which contains values from the toolchain that built the running Ruby.
env = RbConfig::CONFIG.slice("SOEXT", "CPPFLAGS", "CFLAGS", "CC", "AR", "ARFLAGS", "MAKEDIRS", "RMALL")

# It's possible that the Ruby that is being run wasn't actually compiled on this
# machine, in which case parts of RbConfig might be incorrect. In this case
# we'll need to do some additional checks and potentially fall back to defaults.
if env.key?("CC") && !File.exist?(env["CC"])
  env.delete("CC")
  env.delete("CFLAGS")
  env.delete("CPPFLAGS")
end

if env.key?("AR") && !File.exist?(env["AR"])
  env.delete("AR")
  env.delete("ARFLAGS")
end

require "mkmf"

# First, ensure that we can find the header for the prism library.
generate_templates # Templates should be generated before find_header.
unless find_header("prism.h", File.expand_path("../../include", __dir__))
  raise "prism.h is required"
end

# Next, ensure we can find the header for the C extension. Explicitly look for
# the extension header in the parent directory because we want to consistently
# look for `prism/extension.h` in our source files to line up with our mirroring
# in CRuby.
unless find_header("prism/extension.h", File.expand_path("..", __dir__))
  raise "prism/extension.h is required"
end

# If `--enable-build-debug` is passed to this script or the
# `PRISM_BUILD_DEBUG` environment variable is defined, we'll build with the
# `PRISM_BUILD_DEBUG` macro defined. This causes parse functions to
# duplicate their input so that they have clearly set bounds, which is useful
# for finding bugs that cause the parser to read off the end of the input.
if enable_config("build-debug", ENV["PRISM_BUILD_DEBUG"] || false)
  append_cflags("-DPRISM_BUILD_DEBUG")
end

# If `--enable-build-minimal` is passed to this script or the
# `PRISM_BUILD_MINIMAL` environment variable is defined, we'll build with the
# set of defines that comprise the minimal set. This causes the parser to be
# built with minimal features, necessary for stripping out functionality when
# the size of the final built artifact is a concern.
if enable_config("build-minimal", ENV["PRISM_BUILD_MINIMAL"] || false)
  append_cflags("-DPRISM_BUILD_MINIMAL")
end

# By default, all symbols are hidden in the shared library.
append_cflags("-fvisibility=hidden")

# We need to link against the libprism.a archive, which is built by the
# project's `Makefile`. We'll build it if it doesn't exist yet, and then add it
# to `mkmf`'s list of local libraries.
archive_target = "build/libprism.a"
archive_path = File.expand_path("../../#{archive_target}", __dir__)

make(env, archive_target) unless File.exist?(archive_path)
$LOCAL_LIBS << " #{archive_path}"

# Finally, we'll create the `Makefile` that is going to be used to configure and
# build the C extension.
create_makefile("prism/prism")

# Now that the `Makefile` for the C extension is built, we'll append on an extra
# rule that dictates that the extension should be rebuilt if the archive is
# updated.
File.open("Makefile", "a") do |mf|
  mf.puts
  mf.puts("# Automatically rebuild the extension if libprism.a changed")
  mf.puts("$(TARGET_SO): $(LOCAL_LIBS)")
end
