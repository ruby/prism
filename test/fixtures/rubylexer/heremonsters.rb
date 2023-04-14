<<END0+<<END1+<<END2+"kdsjfasdjf"
    #{m0}
END0
    #{m1}
END1
    #{m2}
END2

foo a=<<a,b=<<b,c=<<c
jfksdkjf
dkljjkf
a
kdljfjkdg
dfglkdfkgjdf
dkf
b
lkdffdjksadhf
sdflkdjgsfdkjgsdg
dsfg;lkdflisgffd
g
c

foo(a=<<a,b=<<b,c=<<c)
jfksdkjf
dkljjkf
a
kdljfjkdg
dfglkdfkgjdf
dkf
b
lkdffdjksadhf
sdflkdjgsfdkjgsdg
dsfg;lkdflisgffd
g
c

def foo(a=<<a,b=<<b,c=<<c)
jfksdkjf
dkljjkf
a
kdljfjkdg
dfglkdfkgjdf
dkf
b
lkdffdjksadhf
sdflkdjgsfdkjgsdg
dsfg;lkdflisgffd
g
c

   a+b+c

end

p <<stuff+'foobar'.tr('j-l','d-f')\
+"more stuff"
12345678
the quick brown fox jumped over the lazy dog
stuff

p <<simple1
foo
bar
baz
simple1
p(<<simple2)
foo2
bar
baz
simple2

p <<oof+"gfert"
#{gleeble 
}
oof

    funcnames.collect{|fn| <<-endeval; hn }.to_s(fn,hn,gn=1)
         #{fn} #{gn} #{hn=2}
         #$fn #@gn #@@hn=2
    endeval
    p fn,gn,hn

p <<foo+'crazy'+<<bar+'nutty'
sdsdf
foo
sdfsdfgsdfsdf
bar

p <<foo+'crazy'+<<bar+'nutty'+<<baz+'insane!'
sdsdf
foo
sdfsdfgsdfsdf
bar
uityeiorwpieo
baz

p <<foo+'crazy'+<<bar+'nutty'+<<baz+'insane!'+<<quux+'super-wacky'
sdsdf
foo
sdfsdfgsdfsdf
bar
uityeiorwpieo
baz
CVBNXVBdfg
quux

p <<foo+'crazy'+<<bar+'nutty'+<<baz+'insane!'+<<quux+'super-wacky'+
sdsdf
foo
sdfsdfgsdfsdf
bar
uityeiorwpieo
baz
CVBNXVBdfg
quux
"5645647585735"

p <<foo+
bar
baz
foo
"quux"


p <<f+<<f
s435fg
f
2345gdf
f

p <<p
q\
p
p

p <<''
q\

p

