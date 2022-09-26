# frozen_string_literal: true

require "mkmf"
$INCFLAGS << " -I$(top_srcdir)" if $extmk

# There are complains about missing memcpy and strlen
$CFLAGS << ' -Wno-implicit-function-declaration'

create_makefile "yarp/yarp"
