# frozen_string_literal: true

#
#  this file should only be required when building against YARP's C API
#

unless Dir.exist?(File.join(__dir__, 'c_api'))
  raise LoadError, "Yarp's C API is not installed. Please re-install with the --install-c-api flag."
end

module Yarp
  module CAPI
    CPPFLAGS = ["-I#{File.join(__dir__, "c_api", "include")}"]
    LDFLAGS = [File.join(__dir__, "c_api", "lib", "librubyparser.a")]
  end
end
