def foo((bar, baz))
end

def a; ensure; end

def (b).a
end

def (a)::b
end

def false.a
end

def a(...)
end

def $var.a
end

def a.b
end

def @var.a
end

def a b:; end

%,abc,

def a(b:)
end

def a(**b)
end

def a(**)
end

def (1).a
end

a = 1; def a
end

def a b, c, d
end

def nil.a
end

def a b:, c: 1
end

def a(b:, c: 1)
end

def a(b:
  1, c:)
end

%.abc.

def a b = 1, c = 2
end

def a()
end

def a b, c = 2
end

def a b
end

def a; rescue; else; ensure; end

def a *b
end

def a(*)
end

def a
b = 1
end

def self.a
end

def true.a
end

def a
end

def hi
return :hi if true
:bye
end

def foo = 1
def bar = 2

def foo(bar) = 123

def foo = 123

def a(*); b(*); end

def a(...); b(...); end

def a(...); b(1, 2, ...); end

def (c = b).a
end

def a &b
end

def a(&)
end

def @@var.a
end

def (a = b).C
end

def self.Array_function; end

Const = 1; def Const.a
end

def a(...); "foo#{b(...)}"; end
