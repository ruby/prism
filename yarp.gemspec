# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "yarp"
  spec.version = "0.4.0"
  spec.authors = ["Shopify"]
  spec.email = ["ruby@shopify.com"]

  spec.summary = "Yet Another Ruby Parser"
  spec.homepage = "https://github.com/ruby/yarp"
  spec.license = "MIT"

  spec.require_paths = ["lib"]
  spec.files = [
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "LICENSE.md",
    "Makefile.in",
    "README.md",
    "config.h.in",
    "config.yml",
    "configure",
    "docs/building.md",
    "docs/configuration.md",
    "docs/design.md",
    "docs/encoding.md",
    "docs/extension.md",
    "docs/fuzzing.md",
    "docs/heredocs.md",
    "docs/mapping.md",
    "docs/ripper.md",
    "docs/serialization.md",
    "docs/testing.md",
    "ext/yarp/api_node.c",
    "ext/yarp/api_pack.c",
    "ext/yarp/extension.c",
    "ext/yarp/extension.h",
    "ext/yarp/include/yarp.h",
    "ext/yarp/include/yarp/ast.h",
    "ext/yarp/include/yarp/defines.h",
    "ext/yarp/include/yarp/diagnostic.h",
    "ext/yarp/include/yarp/enc/yp_encoding.h",
    "ext/yarp/include/yarp/node.h",
    "ext/yarp/include/yarp/pack.h",
    "ext/yarp/include/yarp/parser.h",
    "ext/yarp/include/yarp/regexp.h",
    "ext/yarp/include/yarp/unescape.h",
    "ext/yarp/include/yarp/util/yp_buffer.h",
    "ext/yarp/include/yarp/util/yp_char.h",
    "ext/yarp/include/yarp/util/yp_constant_pool.h",
    "ext/yarp/include/yarp/util/yp_list.h",
    "ext/yarp/include/yarp/util/yp_memchr.h",
    "ext/yarp/include/yarp/util/yp_newline_list.h",
    "ext/yarp/include/yarp/util/yp_state_stack.h",
    "ext/yarp/include/yarp/util/yp_string.h",
    "ext/yarp/include/yarp/util/yp_string_list.h",
    "ext/yarp/include/yarp/util/yp_strpbrk.h",
    "ext/yarp/include/yarp/version.h",
    "ext/yarp/yarp.c",
    "lib/yarp.rb",
    "lib/yarp/lex_compat.rb",
    "lib/yarp/node.rb",
    "lib/yarp/pack.rb",
    "lib/yarp/ripper_compat.rb",
    "lib/yarp/serialize.rb",
    "yarp.gemspec",
  ]

  spec.extensions = ["ext/yarp/extconf.rb"]
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
end
