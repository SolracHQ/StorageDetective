import std/[strformat]

type 
  SizeKind = enum
    B, KB, MB, GB, TB, PB

  Size* = distinct int

proc `$`*(size: Size): string =
  var kind = B
  var res = size.float
  while res > 1024 and kind < PB:
    res /= 1024
    kind.inc
  result = &"{res:.2f} {kind}"

proc `+`*(a: Size, b: Size): Size =
  result = Size(a.int + b.int)

proc `+=`*(a: var Size, b: Size) =
  a = a + b

proc `==`*(a: Size, b: Size): bool =
  result = a.int == b.int

proc `%`*(a: Size, b: Size): float =
  # Get the percentage of `a` relative to `b`
  result = (a.int / b.int) * 100

proc cmp*(a: Size, b: Size): int {.inline.} =
  # Compare `a` to `b`
  a.int.cmp(b.int)