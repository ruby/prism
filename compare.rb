require 'pp'
require 'parser/current'
code = ARGV.fetch(0)
original = Parser::CurrentRuby.parse(code).pretty_inspect
puts original

$:.unshift("#{__dir__}/lib")
require 'yarp'
require 'yarp/parser_gem_compat'
puts
converted = YARP::ParserGemCompat.parse(code).pretty_inspect
puts converted

if original == converted
  puts "OK"
else
  puts "DIFFERS"
  File.write('original', original)
  File.write('converted', converted)
end
