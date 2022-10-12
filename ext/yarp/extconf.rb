# frozen_string_literal: true

require "mkmf"

find_header("yarp.h", File.expand_path("../../src", __dir__))
unless find_library("rubyparser", "yp_parser_init", File.expand_path("../../build", __dir__))
  raise "Please run make to build librubyparser"
end

create_makefile("yarp/yarp")
