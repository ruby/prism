#-Ku required on command line...
def ♥(name)
  puts "I ♥ you, #{name}!"
end

♥ ARGV.shift
#p ?♥ #not til 1.9
p :♥
#♥

def spade; :sam end
def club; :sangwich end

=begin ♥
♥♥♥
 ♥
=end ♥

alias heart ♥
alias :heart2 :♥
undef ♥
alias ♥ spade
undef :♥
alias :♥ :club

♥ 2

$♥=2
 
class A♥
  @@♥=3
  def new
    @♥=4
  end

  def show
    ♥=4
    p $♥,@@♥,@♥,♥
  end
end

A♥.new.show

alias $heart $♥

p $heart

p '♥'
p %w[♥ b c♥ d ♥e f♥g]

