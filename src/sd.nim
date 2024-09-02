import std/[os, strformat, algorithm, times]
import illwill
import tree, sizes, menu

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc `$`*(sortInfo: tuple[sortCriteria: SortCriteria, sortOrder: algorithm.SortOrder, grouping: Grouping]): string =
  ## Returns a formatted string for the sort information
  result = ""
  case sortInfo.sortCriteria
  of scName: result &= "(s)ort: by name | "
  of scSize: result &= "(s)ort: by size | "
  case sortInfo.grouping
  of filesFirst: result &= "(g)rouping: files first | "
  of dirsFirst: result &= "(g)rouping: directories first | "
  of filesOnly: result &= "(g)rouping: files only | "
  of dirsOnly: result &= "(g)rouping: directories only | "
  of mixed: result &= "(g)rouping: mixed | "
  case sortInfo.sortOrder
  of Ascending: result &= "(o)rder: ascending"
  of Descending: result &= "(o)rder: descending"

template toggleEnumValue(x: enum): untyped =
  ## Toggles the value of an enum to the next one, cycling back to the first if necessary.
  x = if x == high(x.type): low(x.type) else: x.succ

proc treeDisplayer(x: TreeItem): string =
  ## Returns a formatted string for a TreeItem
  if x.kind == tkFile:
    return &"{x.file.size:>10} {x.file.name}"
  else:
    return &"{x.dir.size:>10} {x.dir.name}"

proc shortenPath(path: string, maxLen: int): string =
  ## Shortens a long path by replacing the middle part with '...'.
  ## Keeps the beginning and end of the path intact.
  ##
  ## Parameters:
  ## - `path`: The original path to shorten.
  ## - `maxLen`: The maximum length of the resulting string.
  ##
  ## Returns:
  ## - A shortened version of the path, if necessary.
  if path.len <= maxLen:
    return path

  let parts = path.splitPath()
  var firstPart = parts[0]
  let lastPart = parts[1]

  if lastPart.len + 5 >= maxLen:
    return &"{firstPart}/.../{lastPart.lastPathPart}"

  while firstPart.len + lastPart.len + 5 > maxLen and firstPart.len > 0:
    firstPart = firstPart.splitPath()[0]

  return &"{firstPart}/.../{lastPart}"

proc main() =
  var path = if paramCount() == 0: "." else: paramStr(1)

  if not path.dirExists:
    stderr.write "Error: path does not exist"
    quit(1)

  illwillInit()
  setControlCHook(exitProc)
  hideCursor()

  var terminalBuffer: TerminalBuffer = newTerminalBuffer(terminalWidth(), terminalHeight())

  var lastUpdate = now()

  var dir = buildTree(path.absolutePath, proc(path: string) =
    if now() - lastUpdate < initDuration(milliseconds = 20):
      return
    lastUpdate = now()
    terminalBuffer.clear()
    terminalBuffer.drawRect(0, 0, terminalBuffer.width - 1, terminalBuffer.height - 1)
    var message = "Analyzing..."
    terminalBuffer.write(terminalBuffer.width div 2 - message.len div 2, terminalBuffer.height div 2, message)
    if path.len > terminalBuffer.width - 10:
      message = shortenPath(path, terminalBuffer.width - 10)
    else:
      message = path
    terminalBuffer.write(terminalBuffer.width div 2 - message.len div 2, terminalBuffer.height div 2 + 1, message)
    terminalBuffer.display()
  )

  var menu = newMenu(dir.items, treeDisplayer)

  while true:
    terminalBuffer = newTerminalBuffer(terminalWidth(), terminalHeight())
    terminalBuffer.clear()

    # Draw UI frame
    terminalBuffer.drawRect(0, 0, terminalBuffer.width - 1, terminalBuffer.height - 1)
    terminalBuffer.write(4, 0, " ", dir.path, " - Press Q to quit ")
    menu.draw((1, 1, terminalBuffer.width - 2, terminalBuffer.height - 1), terminalBuffer)
    terminalBuffer.write(1, terminalBuffer.height - 1, " ", $sortInfo, " ")

    terminalBuffer.display()
    let key = getKey()

    case key
    of Key.Q: exitProc()
    of Key.Escape, Key.Backspace:
      if dir.parent != nil:
        dir = dir.parent
        menu = newMenu(dir.items, treeDisplayer)
    of Key.Enter:
      if menu.selected.kind != tkFile:
        dir = menu.selected.dir
        menu = newMenu(dir.items, treeDisplayer)
    of Key.Up: menu.dec
    of Key.Down: menu.inc
    of Key.G:
      toggleEnumValue(sortInfo.grouping)
      menu = newMenu(dir.items, treeDisplayer)
    of Key.S:
      toggleEnumValue(sortInfo.sortCriteria)
      menu = newMenu(dir.items, treeDisplayer)
    of Key.O:
      toggleEnumValue(sortInfo.sortOrder)
      menu = newMenu(dir.items, treeDisplayer)
    else: discard

    sleep(20)

when isMainModule:
  main()