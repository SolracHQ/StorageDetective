import std/[os, strformat, times, options]
import illwill
import tree, sizes, menu, config, iter

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  let e = getCurrentException()
  if e != nil:
    echo e.getStackTrace()
  quit(if e == nil: 0 else: 1)

proc treeDisplayer(x: TreeItem): string =
  ## Returns a formatted string for a TreeItem
  case x.kind:
  of tkFile:   result = &"{x.file.size%x.file.parent.size:>5}% {x.file.size:>10} {x.file.name}"
  of tkDir:    result = &"{x.dir.size%x.dir.parent.size:>5}% {x.dir.size:>10} {x.dir.name}"
  of tkUpLink: result = &"{x.parent.size:>17} .."

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

  var (firstPart, lastPart) = path.splitPath()

  if lastPart.len + 5 >= maxLen:
    return &".../{lastPart.lastPathPart}"

  while firstPart.len + lastPart.len + 5 > maxLen and firstPart.len > 0:
    firstPart = firstPart.splitPath()[0]

  return &"{firstPart}/.../{lastPart}"

proc analyzingDialog(path: string, terminalBuffer: var TerminalBuffer) =
  terminalBuffer.clear()
  terminalBuffer.drawRect(0, 0, terminalBuffer.width - 1, terminalBuffer.height - 1)
  
  # Draw the main message
  let message = "Analyzing..."
  terminalBuffer.write(terminalBuffer.width div 2 - message.len div 2, terminalBuffer.height div 2, message)

  # Draw the current path
  let displayPath = if path.len > terminalBuffer.width - 10: shortenPath(path, terminalBuffer.width - 10) else: path
  terminalBuffer.write(terminalBuffer.width div 2 - displayPath.len div 2, terminalBuffer.height div 2 + 1, displayPath)

  terminalBuffer.display()

proc main() =
  var path = if paramCount() == 0: "." else: paramStr(1)

  if not path.dirExists:
    stderr.write "Error: path does not exist"
    quit(1)

  illwillInit()
  setControlCHook(exitProc)
  hideCursor()

  var terminalBuffer: TerminalBuffer = newTerminalBuffer(terminalWidth(), terminalHeight())

  var lastUpdateTime = now()

  let shouldUpdate = proc(): bool =
    const freq = initDuration(milliseconds = 20)
    result = (now() - lastUpdateTime) >= freq

  var dir = buildTree(path.absolutePath, proc(path: string) =
    # Update the display every 20ms
    if not shouldUpdate(): return

    lastUpdateTime = now()
    analyzingDialog(path, terminalBuffer)
  )

  var menu = newMenu(dir.items, treeDisplayer)

  while true:
    terminalBuffer = newTerminalBuffer(terminalWidth(), terminalHeight())
    terminalBuffer.clear()

    # Draw UI frame
    # -- path  -  files  |  dirs  -  total size --
    # | Size Item                                 |
    # | Size Item                                 |
    # | Size Item                                 |
    # - (S)ort - (G)rouping - (O)rder - (Q)uit ----
    terminalBuffer.drawRect(0, 0, terminalBuffer.width - 1, terminalBuffer.height - 1)
    let count = dir.count
    terminalBuffer.write(4, 0, " ", dir.path, " - ", $count.files , " files | ", $count.dirs , " dirs - Total size: ", $dir.size, " ")
    menu.draw((1, 1, terminalBuffer.width - 2, terminalBuffer.height - 1), terminalBuffer)
    terminalBuffer.write(1, terminalBuffer.height - 1, " ", $cfg, " - Press Q to quit ")

    terminalBuffer.display()

    case getKey()
    of Key.Q: exitProc()
    of Key.Escape, Key.Backspace:
      if dir.parent != nil:
        dir = dir.parent
        menu = newMenu(dir.items, treeDisplayer)
    of Key.Enter:
      if menu.selected.isSome and menu.selected.get.kind == tkDir:
        dir = menu.selected.get.dir
        menu = newMenu(dir.items, treeDisplayer)
      elif menu.selected.isSome and menu.selected.get.kind == tkUpLink:
        dir = menu.selected.get.parent
        menu = newMenu(dir.items, treeDisplayer)
    of Key.Up, Key.Left, Key.K: menu.dec
    of Key.Down, Key.Right, Key.J: menu.inc
    of Key.G:
      cfg.grouping.toggle()
      menu = newMenu(dir.items, treeDisplayer)
    of Key.S:
      cfg.sortCriteria.toggle()
      menu = newMenu(dir.items, treeDisplayer)
    of Key.O:
      cfg.sortOrder.toggle()
      menu = newMenu(dir.items, treeDisplayer)
    else: discard

    sleep(20)

when isMainModule:
  try:
    main()
  except:
    exitProc()