puts "%\sfoo\s "

puts "%\tfoo\t "
puts "%\vfoo\v "
puts "%\rfoo\r "
puts "%\nfoo\n "
puts "%\0foo\0 "

puts "%\r\nfoo\r\n "

#given that \n\r is not considered a valid eol
#sequence in ruby (unlike \r\n), the next 2 are ok
puts "%\n\rfoo\n\r " 
puts "%\n\rfoo\n "                                 

#seems like just \r isn't valid newline either, so
#the following are are correct.
puts "%\r\nfoo\n " 
puts "%\rfoo\r "  
puts "%\nfoo\n "    
puts "%\nfoo\r\n "    

