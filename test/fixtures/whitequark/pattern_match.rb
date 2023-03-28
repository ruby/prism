case foo; 
        in a: {b:}, c:
          p c
      ; end

case foo; 
        in {Foo: 42
        }
          false
      ; end

case foo; 
        in {a:
              2}
          false
      ; end

case foo; 
        in {a:
        }
          true
      ; end

case foo; 
        in {a: 1
        }
          false
      ; end

case foo; in "a": 1 then true; end

case foo; in "a": then true; end

case foo; in "a": 1 then true; end

case foo; in "a": then true; end

case foo; in "a": 1 then true; end

case foo; in "a": then true; end

case foo; in "a": 1 then true; end

case foo; in "a": then true; end

case foo; in (1) then true; end

case foo; in * then nil; end

case foo; in ** then true; end

case foo; in **a then true; end

case foo; in **nil then true; end

case foo; in *, 42, * then true; end

case foo; in *x then nil; end

case foo; in *x, y, z then nil; end

case foo; in ->{ 42 } then true; end

case foo; in ...2 then true; end

case foo; in ..2 then true; end

case foo; in 1 => a then true; end

case foo; in 1 | 2 then true; end

case foo; in 1, "a", [], {} then nil; end

case foo; in 1.. then true; end

case foo; in 1... then true; end

case foo; in 1...2 then true; end

case foo; in 1..2 then true; end

case foo; in 1; end

case foo; in ::A then true; end

case foo; in A then true; end

case foo; in A() then true; end

case foo; in A(1, 2) then true; end

case foo; in A(x:) then true; end

case foo; in A::B then true; end

case foo; in A[1, 2] then true; end

case foo; in A[] then true; end

case foo; in A[x:] then true; end

case foo; in Array[*, 1, *] then true; end

case foo; in String(*, 1, *) then true; end

case foo; in [*, x] then true; end

case foo; in [*x, 1 => a, *y] then true; end

case foo; in [*x, y] then true; end

case foo; in [x, *, y] then true; end

case foo; in [x, *y, z] then true; end

case foo; in [x, y, *] then true; end

case foo; in [x, y, *z] then true; end

case foo; in [x, y,] then true; end

case foo; in [x, y] then true; end

case foo; in [x,] then nil; end

case foo; in [x] then nil; end

case foo; in ^$TestPatternMatching; end

case foo; in ^(0+0) then nil; end

case foo; in ^(1
); end

case foo; in ^(42) then nil; end

case foo; in ^@@TestPatternMatching; end

case foo; in ^@a; end

case foo; in ^foo then nil; end

case foo; in a: 1 then true; end

case foo; in a: 1, _a:, ** then true; end

case foo; in a: 1, b: 2 then true; end

case foo; in a: then true; end

case foo; in a:, b: then true; end

case foo; in self then true; end

case foo; in x if true; nil; end

case foo; in x then x; end

case foo; in x unless true; nil; end

case foo; in x, *y, z then nil; end

case foo; in x, then nil; end

case foo; in x, y then nil; end

case foo; in x, y, then nil; end

case foo; in { a: 1 } then true; end

case foo; in { a: 1, } then true; end

case foo; in { foo: ^(42) } then nil; end

case foo; in {} then true; end
