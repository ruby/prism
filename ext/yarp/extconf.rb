# frozen_string_literal: true

require "mkmf"

find_header("yarp.h", File.expand_path("../../src", __dir__))
find_library("rubyparser", "yp_parser_create", File.expand_path("../../build", __dir__))

create_makefile("yarp/yarp")
