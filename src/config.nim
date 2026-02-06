import algorithm

type
  SortCriteria* = enum
    scName
    scSize

  Grouping* = enum
    filesFirst
    dirsFirst
    filesOnly
    dirsOnly
    mixed

  SortOrder* = algorithm.SortOrder
  Config = object
    sortCriteria*: SortCriteria
    sortOrder*: SortOrder
    grouping*: Grouping

var cfg*: Config = Config(sortCriteria: scSize, sortOrder: Descending, grouping: mixed)

template impltToggle(kind: typedesc) =
  proc toggle*(x: var kind) {.inline.} =
    ## Toggles the value of the enum to the next one, cycling back to the first if necessary.
    x =
      if x == high(x.type):
        low(x.type)
      else:
        x.succ

impltToggle(SortCriteria)
impltToggle(Grouping)
impltToggle(SortOrder)

proc `$`*(sortInfo: Config): string =
  ## Returns a formatted string for the sort information
  result = ""
  case sortInfo.sortCriteria
  of scName:
    result &= "(S)ort: by name | "
  of scSize:
    result &= "(S)ort: by size | "
  case sortInfo.grouping
  of filesFirst:
    result &= "(G)rouping: files first | "
  of dirsFirst:
    result &= "(G)rouping: directories first | "
  of filesOnly:
    result &= "(G)rouping: files only | "
  of dirsOnly:
    result &= "(G)rouping: directories only | "
  of mixed:
    result &= "(G)rouping: mixed | "
  case sortInfo.sortOrder
  of Ascending:
    result &= "(O)rder: ascending"
  of Descending:
    result &= "(O)rder: descending"
