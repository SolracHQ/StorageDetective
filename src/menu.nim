import illwill
import std/[options]
import iter

type Menu* = object
  items: Iterator
  selected: int
  convertor: proc(item: TreeItem): string

type DrawableWindow* = tuple[x1, y1, x2, y2: int]

proc newMenu*(items: Iterator, convertor: proc(item: TreeItem): string): Menu =
  ## Creates a new menu with the given items.
  ##
  ## Parameters:
  ## - `items`: A sequence of items to display in the menu.
  ## - `convertor`: A function that converts an item to a string.
  ##
  result = Menu(items: items, selected: 0, convertor: convertor)

proc listRange(index, size, availableRows: int): HSlice[int, int] =
  ## Gets the range of indices to be displayed in the terminal.
  ## 
  ## Parameters:
  ## - `index`: The index of the currently selected item.
  ## - `size`: The total number of items in the list.
  ## - `availableRows`: The number of rows available in the terminal to display the list.
  
  # If the list size is smaller or equal to the number of available columns, display the entire list
  if size <= availableRows:
    return 0 ..< size

  # Calculate the half of the available columns to center the index around
  let halfRows = availableRows div 2
  var startIndex, endIndex: int

  # If the index is small enough to be at the start
  if index <= halfRows:
    startIndex = 0
    endIndex = availableRows
  # If the index is large enough to be at the end
  elif index >= size - halfRows - 1:
    startIndex = size - availableRows
    endIndex = size
  # If the index is somewhere in the middle, center it
  else:
    startIndex = index - halfRows
    endIndex = index + halfRows + 1

  result = startIndex..<endIndex

proc draw*(menu: var Menu, window: DrawableWindow, tb: var TerminalBuffer) =
  ## Draws the menu to the terminal.
  ##
  ## Parameters:
  ## - `menu`: The menu to draw.
  ## - `window`: The window to draw the menu in.

  let (x1, y1, x2, y2) = window
  let availableRows = y2 - y1

  var i = 0
  for item in listRange(menu.selected, menu.items.len, availableRows):
    if item == menu.selected:
      tb.setForegroundColor(fgCyan)
    else:
      tb.setForegroundColor(fgWhite)
    var text = menu.convertor(menu.items.get(item))
    if text.len > x2 - x1:
      text = text[0 ..< x2 - x1]
    tb.write(x1, y1 + i, text)
    tb.resetAttributes()
    i += 1

proc inc*(menu: var Menu) =
  ## Selects the next item in the menu.
  if menu.items.len == 0: return
  menu.selected = (menu.selected + 1) mod menu.items.len

proc dec*(menu: var Menu) =
  ## Selects the previous item in the menu.
  if menu.items.len == 0: return
  menu.selected = (menu.selected + menu.items.len - 1) mod menu.items.len

proc selected*(menu: var Menu): Option[TreeItem] =
  ## Returns the selected item in the menu.
  if menu.items.len == 0: return none(TreeItem)
  result = some(menu.items.get(menu.selected))

proc selectedIndex*(menu: var Menu): int =
  ## Returns the index of the selected item in the menu.
  result = menu.selected