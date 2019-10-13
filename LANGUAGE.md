## General

## Types

```
true
 "hello"
1
1.1
```

## Variable assignment

```
let status = true
let msg = "hello"
let num = 1
let float = 1.1
```

Variables named or starting with `_` are discarded.


## Functions

Functions are first class and can be both named and anonymous, Väja supports two types of function syntax:

Arrow syntax for short function declarations, where the last statement are automatically returned:

```
# Assigned to variable a
let a = fn () -> 1
a()  # 1

# Anonymous
map(["John", "Paul", "Ringo", "George"], fn (x) -> x)
```

And fn/end syntax, that allows multiline statments, `return` is optional

```
# Named function
fn hello(name)
  "hello " & name
end
hello("Martin")  # "hello Martin"

# Anonymous
map(["John", "Paul", "Ringo", "George"], fn (x)
  return x
end)
```

Closures look like this

```
fn adder(x)
  fn (y) -> x + y
end
adder(1)(2)  # 3
```

## If/else

```
if (1 > 2) 1 end

if (1 > 2)
    1
elif (2 > 2)
    2
else
    3
end
```

## Switch

```
case (1 > 2)
    true -> 1
    _ -> 2
end
```

## Pipe operator

```
"hello" $ capitalize()  # HELLO
1 $ print()  # 1
```

## Array

```
let a = [1, 2, 3]
```

## Iterators

```
map(a, fn (x) -> x)
map(a, fn (x)
    x
end)
```


## Builints

```
print("hello")
len("hello")
type(1)
```


## Logical operators

```
1 and 5
not 5
1 or 5
```

## Comparison operators

```
>
<
==
!=
>=
<=
```

## Math operators

```
*
/
+
-
%
**
```

## String operators

```
"a" & "b" >> "ab"
```
