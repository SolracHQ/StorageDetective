import std/[os, algorithm, sugar]
import sizes

type
  ## Represents a file in the file tree.
  File* = object
    name*: string    ## The full path of the file.
    size*: Size      ## The size of the file.
    parent*: Dir    ## The parent directory of the file.

  ## Represents a directory in the file tree.
  Dir* = ref object
    name*: string        ## The full path of the directory.
    parent*: Dir        ## The parent directory, or `nil` if it is the root.
    files*: seq[File]   ## A sequence of `File` objects representing the files in the directory.
    dirs*: seq[Dir]     ## A sequence of `Dir` objects representing the subdirectories.
    size: Size          ## The total size of all files in the directory and its subdirectories.

  SortCriteria* = enum
    scName, scSize
  Grouping* = enum
    filesFirst, dirsFirst, filesOnly, dirsOnly, mixed

var sortInfo*: tuple[sortCriteria: SortCriteria, sortOrder: algorithm.SortOrder, grouping: Grouping] = (scSize, Descending, mixed)

proc buildTree*(path: string, callback: proc(path: string)): Dir =
  ## Builds a tree structure representing the files and directories starting from the given path.
  ##
  ## Parameters:
  ## - `path`: A string representing the root directory from which to start building the tree.
  ##
  ## Returns:
  ## - A `Dir` object representing the entire directory tree rooted at `path`.
  let rootDir = Dir(name: path, parent: nil, files: @[], dirs: @[])
  var stack: seq[(string, Dir)] = @[(path, rootDir)]

  while stack.len != 0:
    let (currentPath, currentDir) = stack.pop()
    callback(currentPath)

    for file in walkDir(currentPath, skipSpecial = true):
      if file.kind == pcFile:
        currentDir.files.add File(
          name: file.path.lastPathPart,
          size: file.path.getFileSize.Size,
          parent: currentDir
        )
      elif file.kind == pcDir:
        let newDir = Dir(
          name: file.path.lastPathPart & "/",
          parent: currentDir
        )
        currentDir.dirs.add(newDir)
        stack.add((file.path, newDir))
  result = rootDir

proc size*(dir: Dir): Size =
  ## Calculates the total size of all files in the directory and its subdirectories.
  if dir.size != 0.Size:
    return dir.size
  result = 0.Size
  for file in dir.files:
    result += file.size
  for subDir in dir.dirs:
    result += size(subDir)
  dir.size = result

proc count*(dir: Dir): tuple[files: int, dirs: int] =
  ## Counts the total number of files and directories in the given directory.
  result.files = dir.files.len
  result.dirs = dir.dirs.len
  for subDir in dir.dirs:
    let (subFiles, subDirs) = count(subDir)
    result.files += subFiles
    result.dirs += subDirs

proc path*[T: Dir or File](element: T): string =
  ## Returns the path of the file or directory.
  result = ""
  if element.parent == nil:
    result = element.name
  else:
    result = element.parent.path / element.name

type 
  Iterator* = tuple[len: int, get: proc(i: int): TreeItem {.closure.}]
  TreeKind* = enum
    tkFile, tkDir
  TreeItem* = object
    case kind*: TreeKind
    of tkFile: file*: File
    of tkDir: dir*: Dir

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
  case sortInfo.sortCriteria
  of scName:
    items.sort((a, b) => a.name.cmp(b.name), order = sortInfo.sortOrder)
  of scSize:
    items.sort((a, b) => a.size.cmp(b.size), order = sortInfo.sortOrder)

proc createGetClosure(files: seq[File], dirs: seq[Dir], grouping: Grouping): proc(i: int): TreeItem {.closure.} =
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
      discard  # For cases that should not occur

proc items*(dir: Dir): Iterator =
  ## Returns an iterator that yields the items in the directory in the order specified by the sort criteria.
  
  case sortInfo.grouping
  of filesFirst, dirsFirst:
    result.len = dir.files.len + dir.dirs.len
    sortItems(dir.files)
    sortItems(dir.dirs)
    result.get = createGetClosure(dir.files, dir.dirs, sortInfo.grouping)
  of filesOnly:
    result.len = dir.files.len
    sortItems(dir.files)
    result.get = createGetClosure(dir.files, @[], sortInfo.grouping)
  of dirsOnly:
    result.len = dir.dirs.len
    sortItems(dir.dirs)
    result.get = createGetClosure(@[], dir.dirs, sortInfo.grouping)
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

