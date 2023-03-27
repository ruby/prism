foo rescue nil

foo rescue
nil

break rescue nil

next rescue nil

return rescue nil

foo rescue nil || 1

foo rescue nil ? 1 : 2

begin; a; rescue *b; end

foo do |x|
  bar(y) rescue ArgumentError fail "baz"
end
