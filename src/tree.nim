import std/os
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