import std/[strformat]

type
  SizeKind = enum
    B   ## 1024 ^ 0
    KB  ## 1024 ^ 1
    MB  ## 1024 ^ 2
    GB  ## 1024 ^ 3
    TB  ## 1024 ^ 4
    PB  ## 1024 ^ 5

  Size* = distinct int ## Represents a file size in bytes.

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

proc `%`*(a: Size, b: Size): string =
  # Get the percentage of `a` relative to `b`
  result = &"{(a.int / b.int) * 100:.2f}"

proc cmp*(a: Size, b: Size): int {.inline.} =
  # Compare `a` to `b`
  a.int.cmp(b.int)
