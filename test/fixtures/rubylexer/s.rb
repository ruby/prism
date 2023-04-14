#string content tokens move around in this file; its not really a problem

if false 
p %w[\ .]
p %w[\\ .]
p %W[\ .]
p %W[\\ .]

p %W[\  
] #ruby interprets this one as a single (totally unescaped) newline,
  #but i suspect that might be a bug.

p "\
"

p '\
'

p /\
/

p `\
`

p %w[\
]

p %[\
]

p "

"

p %{

}

  p %W(\s .)

  p %W(\ .)
  p %W(\\ .)
  p %w(\ .)
  p %w(\\ .)
  p %w(\\
.)

  p %W(\s .)
  p  %r/ \d/
  p %w[\ ]
  p %W[\ ]

PROTOCOLS=%w[http ftp]
EXTENSIONS=%w[tar zip rb tgz tbz2 tbz]
EXTRA_EXTENSIONS=%w[gz bz2]
TARBALL=%r<
  \A(?:#{PROTOCOLS.join('|')})://
  (?:[^/]+/)+
  (.*)
  [_-](.*)
  \.(?:#{EXTENSIONS.join('|')})
  (?:\.(?:#{EXTRA_EXTENSIONS.join'|'}))\Z
>ix


      t=0
      t ?'t':0
      "#{t ?'t':0}"

	e.hour %= 12;	( downcase == 'p')
	e.hour %= 12;	begin downcase == 'p'; end
	e.hour %= 12;	if downcase == 'p'; end
	e.hour %= 12;	(downcase)
	e.hour %= 12;	if downcase; end

      proc do <<EOD
          [#{dqname}]
EOD
      end
      
      proc do <<-EOD
          [#{dqname}]
        EOD
      end
      
      proc do|x| <<-EOD
          [#{dqname}]
        EOD
      end
      
      proc do|| <<-EOD
          [#{dqname}]
        EOD
      end
      
      proc { <<-EOD
          [#{dqname}]
        EOD
      }

      proc {|x| <<-EOD
          [#{dqname}]
        EOD
      }

      p <<-EOD
          [#{dqname}]
        EOD




      proc do "
          [#{dqname}]
          "
      end
      
      proc do `
          [#{dqname}]
          `
      end
      
      proc do /
          [#{dqname}]
          /
      end
      
      proc do '
          [#{dqname}]
          '
      end
      
      proc do %Q{
          [#{dqname}]
          }
      end
      
      proc do %{
          [#{dqname}]
          }
      end
      
end      

def SelfReferencing 
#old name alias
end

def SelfReferencing #old name alias
end

def SelfReferencing#old name alias
end

def SelfReferencing;end#old name alias

p ?a
p :a
p :@a
p :@@a
p :$a
p :A
p :+
p :`#`
p ? p : 0

if false
O=0
false ? 2:O
false ? 2: O
false ? 2 :O
false ? 2 : O

eof??n
eof? ?n

eof??nil:true
eof? ?nil:true
eof?? nil:true
eof? ? nil:true

eof??nil:true
eof??nil :true
eof??nil: true
eof??nil : true

eof!?nil:true
eof! ?nil:true
eof!? nil:true
eof! ? nil:true

eof!?nil:true
eof!?nil :true
eof!?nil: true
eof!?nil : true

end

p <<'FOO'.gsub(" ","\n")
BAR#{BAZ}
FOO

p "\
#{foo}"

p "#{foo}#{bar}"

p "
#{compile_body}\
#{outvar}
"

p "
#{a}\
#{b}\
#{c}\
#{d}\
#{e}\
#{f}\
#{g}\
#{h}\
"

p <<end
#{compile_body}\
#{outvar}
end

p <<end
#{a}\
#{b}\
#{c}\
#{d}\
#{e}\
#{f}\
#{g}\
#{h}
end




p "#{<<foobar2
bim
baz
bof
foobar2
}"


p <<""
foo


bar
