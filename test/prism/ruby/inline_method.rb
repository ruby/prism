# A separate file because 2.7 can't parse this
module Prism
  class NodeForTest < TestCase
    def inline_method = 42
    INLINE_LOCATION_AND_FILE = [[__LINE__-1, 4, __LINE__-1, 26], __FILE__]
  end
end
