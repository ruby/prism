begin
  a
rescue Exception => ex
  b
rescue AnotherException, OneMoreException => ex
  c
end
