import std/[algorithm, sugar]
import sizes, config, tree

type
  Iterator* = object
    len*: int
    get*: proc(i: int): TreeItem

  TreeKind* = enum
    tkFile
    tkDir
    tkUpLink

  TreeItem* = object
    case kind*: TreeKind
    of tkFile: file*: tree.File
    of tkDir: dir*: Dir
    of tkUpLink: parent*: Dir

proc size(element: TreeItem): Size =
  ## Returns the size of the file or directory.
  if element.kind == tkFile:
    result = element.file.size
  else:
    result = size(element.dir)

proc name(element: TreeItem): string =
  ## Returns the name of the file or directory.
  if element.kind == tkFile:
    result = element.file.name
  else:
    result = element.dir.name

proc sortItems[T](items: var seq[T]) =
  ## Sorts a sequence of T based on the provided sort criteria and order.
  case cfg.sortCriteria
  of scName:
    items.sort((a, b) => a.name.cmp(b.name), order = cfg.sortOrder)
  of scSize:
    items.sort((a, b) => a.size.cmp(b.size), order = cfg.sortOrder)

proc createGetClosure(
    files: seq[tree.File], dirs: seq[Dir], grouping: Grouping
): proc(i: int): TreeItem {.closure.} =
  ## Creates a closure that returns the appropriate TreeItem based on the grouping strategy.
  result = proc(i: int): TreeItem =
    case grouping
    of filesFirst:
      if i < files.len:
        result = TreeItem(kind: tkFile, file: files[i])
      else:
        result = TreeItem(kind: tkDir, dir: dirs[i - files.len])
    of dirsFirst:
      if i < dirs.len:
        result = TreeItem(kind: tkDir, dir: dirs[i])
      else:
        result = TreeItem(kind: tkFile, file: files[i - dirs.len])
    of filesOnly:
      result = TreeItem(kind: tkFile, file: files[i])
    of dirsOnly:
      result = TreeItem(kind: tkDir, dir: dirs[i])
    else:
      discard # For cases that should not occur

proc items*(dir: Dir): Iterator =
  ## Returns an iterator that yields the items in the directory in the order specified by the sort criteria.
  case cfg.grouping
  of filesFirst, dirsFirst:
    result.len = dir.files.len + dir.dirs.len
    sortItems(dir.files)
    sortItems(dir.dirs)
    result.get = createGetClosure(dir.files, dir.dirs, cfg.grouping)
  of filesOnly:
    result.len = dir.files.len
    sortItems(dir.files)
    result.get = createGetClosure(dir.files, @[], cfg.grouping)
  of dirsOnly:
    result.len = dir.dirs.len
    sortItems(dir.dirs)
    result.get = createGetClosure(@[], dir.dirs, cfg.grouping)
  else:
    # Default case: no grouping, merge all items into a single list
    var allItems: seq[TreeItem] = @[]
    for file in dir.files:
      allItems.add(TreeItem(kind: tkFile, file: file))
    for directory in dir.dirs:
      allItems.add(TreeItem(kind: tkDir, dir: directory))
    sortItems(allItems)
    result.len = allItems.len
    result.get = (i: int) => allItems[i]

  if dir.parent != nil:
    let oldGet = result.get
    result.len += 1
    result.get = proc(i: int): TreeItem =
      if i == 0:
        result = TreeItem(kind: tkUpLink, parent: dir.parent)
      else:
        result = oldGet(i - 1)
