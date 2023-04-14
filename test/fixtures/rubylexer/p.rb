if false
p %
foo

p(%
foo

)

p((4\
+5))
p((4\

+5))
p((4+\

+5))
p((4+\

5))
end


=begin things that seem like they should work, but cause syntax errors

 (p / 1/)  

class F34534334
class A
class B
class C
end
end
end
def A::B::C::d() :abcd end
def A::B::d() :abd end   #this used to work as well... i think


def nil.d=; end #this works
def (;).d=; end
def ().d=; end
p def (p h="foobar";).default= v; p @v=v;v end
p def (p h="foobar";h).default= v; p @v=v;v end

p~4{}
p:f{}
p ~4{}
p :f{}
p ~4 {}
p :f {}
p ~ 4{}

def g a=:g; [a] end
g g g  #this works
g *g   #this works
g *g g #this doesn't
g+g 5  #this doesn't

[nil,p 5]
"foo"+[1].join' '
"foo"+join' '
if x=p :a,:b then end
{:nil?=> 1}

1+[1,2,3][1..-1].index 3

_=@cu.fixup_match_result 'md'  #works
_=md=@cu.fixup_match_result 'md'  #don't work

3+"".slice 1

""+p ""

#given:
def foo; end

foo.===/#/  #syntax error

foo.=== /#/ #no error
foo===/#/    #no error

#these work:
(not true)
p(!true) #etc
(true if false) #etc
(true and false) #etc
(undef foo)
(alias bar foo)
(BEGIN{p :yyy})

#these don't:
p(not true)
p(true if false) #etc
p(true and false) #etc
p(undef foo)
p(alias bar foo)
p(BEGIN{p :yyy})
 p 1{2}
 p 1 {2}
p(false ? Q :p8 )
p(false ? Q:p8 )
end


if false
      equal?(p) or Position===p && equal? p.data #syntax error unless add parens, but why?
end

    raise LexerError, "expected >=#{tok.offset}, got #{endpos}, "\ 
                      "token #{tok}:#{tok.class}"  #there's a space after the backslash
=end

