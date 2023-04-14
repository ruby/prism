#offsets in these cases are incorrect... maybe never

p <<-foo+'123
  abcd
  foo
  456'+"8910"
p heh

p <<-foo+"123#{2.718281828}
  abcd
  foo
  456#{3.14159265}"+"8910"
p hurhurhurhurhur!

p <<-foo+"123#{2.718281828}
  abcd
  foo
  456#{3.14159265}"
p hurhurhurhurhur!


p <<here+'123
456
there
here
789'
p snort!

p <<here+'123\
456
there
here
789'
p snort!

p <<here+'123\
456
there
here
789'

p <<-foo+'123
  abcd
  foo
  456'
p ha-ha

p <<-foo+'123tyurui
  abcdCWECWWE
  foo
  456rtjmnj'
p ha-ha


p "#{<<foobar1.each('|'){|s| '\nthort: '+s}
jbvd|g4543ghb|!@G$dfsd|fafr|e
|s4e5rrwware|BBBBB|*&^(*&^>"PMK:njs;d|

foobar1
}"


p <<bazquux+"#{
dfgnb
t 67sevrgvase
234vjvj7ui
bazquux
}foobar"
