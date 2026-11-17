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

          --enable-build-ndebug
              Enable build without assertions.
              You may also set the PRISM_BUILD_NDEBUG environment variable.

          --enable-build-ubsan
              Enable build with the undefined behavior sanitizer.
              You may also set the PRISM_BUILD_UBSAN environment variable.

          --help
              Display this message.

      Environment variables used:

          PRISM_BUILD_DEBUG
              Equivalent to `--enable-build-debug` when set, even if nil or blank.

          PRISM_BUILD_MINIMAL
              Equivalent to `--enable-build-minimal` when set, even if nil or blank.

          PRISM_BUILD_NDEBUG
              Equivalent to `--enable-build-ndebug` when set, even if nil or blank.

          PRISM_BUILD_UBSAN
              Equivalent to `--enable-build-ubsan` when set, even if nil or blank.

  TEXT
  exit
end

# If this gem is being build from a git source, then we need to run
# templating if it hasn't been run yet. In normal packaging, we would have
# shipped the templated files with the gem, so this wouldn't be necessary.
def generate_templates
  Dir.chdir(File.expand_path("../..", __dir__)) do
    if !File.exist?("include/prism/ast.h") && Dir.exist?(".git")
      system(RbConfig.ruby, "templates/template.rb", exception: true)
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
      RbConfig::CONFIG['host_os'].match?(/openbsd|freebsd/i) ? "gmake" : "make",
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

# If `--enable-build-ndebug` is passed to this script or the
# `PRISM_BUILD_NDEBUG` environment variable is defined, we'll build with the
# `NDEBUG` macro defined, which compiles out the assertions in the parser. This
# skips the check that append_cflags makes, which compiles ruby.h with -Werror:
# a Ruby built with RUBY_DEBUG warns there that its own headers ignore NDEBUG.
# The sources of libprism do not include ruby.h, so NDEBUG still applies to them.
if enable_config("build-ndebug", ENV["PRISM_BUILD_NDEBUG"] || false)
  $defs << "-DNDEBUG=1"
end

# If `--enable-build-ubsan` is passed to this script or the `PRISM_BUILD_UBSAN`
# environment variable is defined, we'll build with the undefined behavior
# sanitizer. Any undefined behavior it detects, such as a misaligned access or a
# signed overflow, aborts the process with a report of where it happened. The
# sanitizer runtime is linked into the extension itself, so the Ruby that loads
# it does not need to be built with the sanitizer.
if enable_config("build-ubsan", ENV["PRISM_BUILD_UBSAN"] || false)
  flags = "-fsanitize=undefined -fno-sanitize-recover=undefined -fno-omit-frame-pointer"
  append_cflags(flags)
  append_ldflags(flags)
end

# By default, all symbols are hidden in the shared library.
append_cflags("-fvisibility=hidden")

def src_list(path)
  srcdir = path.dup
  RbConfig.expand(srcdir) # mutates srcdir :-/
  Dir[File.join(srcdir, "*.{#{SRC_EXT.join(%q{,})}}")]
end

def add_libprism_source(path)
  $VPATH << path
  src_list path
end

$srcs = src_list("$(srcdir)") + add_libprism_source("$(srcdir)/../../src")
$headers += Dir["#{$srcdir}/../../include/**/*.h"]

# Finally, we'll create the `Makefile` that is going to be used to configure and
# build the C extension.
create_makefile("prism/prism")

# The Makefile that mkmf creates makes the objects depend on their sources and
# headers, but not on the Makefile itself, which holds the flags they are
# compiled with. This script writes a new Makefile whenever it runs, so with
# this rule a change to the build options recompiles every object.
File.open("Makefile", "a") { |file| file.puts("", "$(OBJS): Makefile") }
