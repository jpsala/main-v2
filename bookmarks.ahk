; Window Bookmarking Systems
; See bookmarks.md for complete documentation of all features and implementation details
;
; This script provides a dynamic window bookmarking system with two assignment methods:
;
; 1. Sequential Assignment (#s):
; #s - Creates/activates a bookmark by typing any key after #s
;      - If no window is bookmarked to that key: Assigns current window
;      - If a window is already bookmarked: Toggles that window (activate/minimize)
; #+s - Same as #s but first deletes any existing bookmark, allowing reassignment
;
; 2. Direct Assignment:
; Uses specific hotkey combinations that can be directly pressed to assign/activate windows:
; - Normal hotkey (e.g. #1): Activates/minimizes the bookmarked window
; - Shift variant (e.g. #+1): Assigns current window to that hotkey
;
; 3. Bookmark Manager (Ctrl+Alt+Shift+B):
; - Shows all bookmarks in a searchable, filterable GUI
; - Row numbers (1-9) displayed in first column for quick access
; - Press a number key (1-9) to instantly activate that bookmark
; - Filter the list by typing in the search box
;
; Available combinations:
; - Win+F1 to F6
; - Alt+1 to 0
; - Win+1 to 0
; - Win+[b,d,e,f,g,t,q,z,x,v]
; - Alt+Win+[a,d,e,f,g,q,r,v,w,x,z]
;
; All bookmarks are dynamic (can be reassigned) and persist across sessions via config.ini.
global bookmarkMap := map(), dontSave := false
OnExit SaveBookmarks
^+!b:: showBookmarks()
^+!u:: showBookmarks()

SetTimer(VerifyHotkeys, 10000)

; Function to reset all bookmarks and reload
ResetAllBookmarks() {
  global dontSave
  dontSave := true  ; Prevent saving current bookmarks on exit

  try {
    ; Remove all bookmarks from config.ini
    IniDelete("config.ini", "bookmarks")

    ; Clear current bookmarkMap
    bookmarkMap := map()

    ; Close any open file handles and wait a moment
    SetTimer(() => Reload(), -500)  ; Delay reload by 500ms to allow cleanup
  } catch Error as e {
    MsgBox("Error resetting bookmarks: " e.Message)
  }
}

; Default hotkey combinations (used to seed config.ini on first run)
DEFAULT_BOOKMARK_HOTKEYS := [
  "#1", "#2", "#3", "#4", "#5", "#6", "#7", "#8", "#9", "#0",
  "#b", "#d", "#e", "#f", "#g", "#i", "#t", "#q", "#r", "#z", "#v", "#x",
  "!#a", "!#d", "!#e", "!#f", "!#g", "!#q", "!#r", "!#v", "!#x", "!#w", "!#z",
]

; Load hotkey definitions from config.ini instead of hardcoded array
bookmarks := LoadBookmarkHotkeys()

LoadBookmarksInBookmarkMap()

; Register both direct and shift variants for each hotkey in the static bookmarks array
for index, key in bookmarks {
  try {
    if (isSet(key))
      SetHotkeysForBookmark(key)
    else
      msg('error setting the bookmark', { seconds: 5 })
  } catch Error as e {
    msg('Error in SetHotkeysForBookmark for key ' e.Message, { seconds: 5 })
  }
}


; Management interface for bookmarks
; Win-key admin menu disabled; use Ctrl+Alt+Shift+B/U for bookmark manager.
; #!^b:: {
;   global
;   key := SeqGui([{ key: 's', label: 'Show Bookmarks', fn: () => showBookmarks() }, { key: 'x', label: 'Clear Bookmarks and Reload', fn: () => ClearAndReload() }, { key: 'r', label: 'Reload Bookmarks', fn: () => LoadBookmarksInBookmarkMap() }, { key: 'l', label: 'List Hotkeys', fn: ListHotkeys }, { key: 'a', label: 'Reset All Bookmarks', fn: () => ResetAllBookmarks() }
;   ], 10000, true, 100)
;   if (key == 'x')
;     ClearAndReload()
;   if (key == 'a')
;     ResetAllBookmarks()
; }

; Test hotkey for monitor detection
; #^!m:: {
;   monitor := getMonitor()
;   MouseGetPos(&x, &y)
;   msg("Monitor: " monitor "`nMouse X: " x "`nMouse Y: " y, { seconds: 3 })
; }

; Prevents auto-save when explicitly clearing bookmarks
ClearAndReload() {
  global dontSave
  dontSave := true
  IniDelete('config.ini', 'bookmarks')
  Reload()
}

; Sequential bookmark system - uses Seq() for dynamic bookmark IDs
$#s:: {
  global bookmarkMap
  ; If Seq returns empty (timeout), show current dynamic assignments
  char := Seq(1000, 1, false, 0, false, "Press a key to create/toggle bookmark")
  if (!char) {
    showBookmarks()
    return
  }
  saveCharBookmark(char)
}
$#+s:: {
  char := Seq(3000, 1, false, 0, false, "Press a key to reassign bookmark, you have ")
  if (!char) {
    soundError()
    return
  }
  saveCharBookmark(char, true)
}

saveCharBookmark(char := false, deleteFirst := false) {
  if (char) {
    if (deleteFirst) {
      if bookmarkMap.Has(char)
        bookmarkMap.Delete(char)
    }
    ActivateOrMinimizeBookmark(char)
  }
}

; Core window management functions
BookmarkHotkeyIsReservedMenu(key) {
  normalized := StrLower(key)
  return normalized = "#a" || normalized = "#w" || normalized = "#c"
}

BookmarkHotkeyEnableActivation(key) {
  if (BookmarkHotkeyIsReservedMenu(key))
    return

  Hotkey(key, (*) => ActivateOrMinimizeBookmark(key))
}

SetHotkeysForBookmark(key) {
  global bookmarkMap
  if (BookmarkHotkeyIsReservedMenu(key))
    return

  ; Reserve only the Shift variant for assignment. The base hotkey stays
  ; untouched by AHK until this slot has an actual bookmark.
  Hotkey('+' . key, (*) => SetBookmark(key))
  if (bookmarkMap.Has(key))
    BookmarkHotkeyEnableActivation(key)
}

; Toggles window state or creates new bookmark if none exists
ActivateOrMinimizeBookmark(_id) {
  global bookmarkMap
  try {
    bookmarkData := bookmarkMap[_id]
    if (IsObject(bookmarkData)) {
      ; New structure with id and title
      winId := bookmarkData.id
      title := bookmarkData.title
    } else {
      ; Legacy structure - just the ID string
      winId := bookmarkData
      title := ""
    }

    if (WinExist(winId) and !WinActive(winId))
      WinActivateFast(winId)
    else if WinActive(winId)
      WinMinimize(winId)
  } catch {
    SetBookmark(_id)
  }
}

; Creates/updates bookmark for current window
SetBookmark(key, title := false, winHandle := false) {
  global bookmarkMap
  try {
    if (!title) {
      if (winHandle) {
        id := 'ahk_id ' winHandle
      } else {
        id := 'ahk_id ' WinGetID("A")
      }
    } else {
      id := title
    }
    title := WinGetTitle(id)

    ; Store both ID and title in the bookmarkMap
    bookmarkMap[key] := { id: id, title: title }
    BookmarkHotkeyEnableActivation(key)

    msg('bk: ' key ' -> ' title, { seconds: 3 })
  } catch Error as e {
    msgV1('Error in SetBookmark', 2, 6)
  }
}

; Loads and validates bookmarks from config, removing stale entries
LoadBookmarksInBookmarkMap() {
  global bookmarkMap
  section := IniRead("config.ini", "bookmarks", , "")
  ar := StrSplit(section, '`n')
  for line in ar {
    lineAr := StrSplit(line, '=')
    if (lineAr.Length == 2) {
      id := lineAr[1]
      value := lineAr[2]

      ; Check if this is the new format with title (contains | separator)
      if (InStr(value, "|")) {
        parts := StrSplit(value, "|")
        if (parts.Length == 2) {
          winId := parts[1]
          title := parts[2]

          if (WinExist(winId) == 0) {
            IniDelete("config.ini", "bookmarks", id)
          } else {
            bookmarkMap[id] := { id: winId, title: title }
          }
        }
      } else {
        ; Legacy format - just the window ID
        winId := value
        if (WinExist(winId) == 0) {
          IniDelete("config.ini", "bookmarks", id)
        } else {
          ; Get current title for legacy bookmarks
          title := WinGetTitle(winId)
          bookmarkMap[id] := { id: winId, title: title }
        }
      }
    }
  }
}

ClearBookmark(key, showMessage := true) {
  global bookmarkMap

  if (key = "")
    return false

  if (bookmarkMap.Has(key))
    bookmarkMap.Delete(key)

  try IniDelete("config.ini", "bookmarks", String(key))
  try Hotkey(key, "Off")

  if (showMessage)
    msg("Bookmark libre: " . key, { seconds: 3 })
  return true
}

ClearAllBookmarksAssigned() {
  global bookmarkMap
  clearedCount := 0
  keysToClear := []

  for key, _ in bookmarkMap
    keysToClear.Push(key)

  for _, key in keysToClear {
    if (ClearBookmark(key, false))
      clearedCount++
  }

  msg("Bookmarks liberados: " . clearedCount, { seconds: 3 })
  return clearedCount
}

; Manual bookmark creation with explicit window handle
setManualBookmark(key, winHandle) {
   try {
     title := WinGetTitle(winHandle)
     setBookmark(key, , winHandle)
     Hotkey(key, (*) => ActivateOrMinimizeBookmark(key))

     ; Save with new format: id|title
     saveValue := winHandle "|" title
     IniWrite(saveValue, "config.ini", "bookmarks", String(key))
     msg('Manual bk: ' key ' -> ' title, { seconds: 6 })
   } catch Error as e {
     msg('Error in setManualBookmark ' e.Message, { seconds: 5 })
   }
}

; Helper function to get stored hwnd for a bookmark key
GetBookmarkHwnd(key) {
    global bookmarkMap
    if (!bookmarkMap.Has(key)) {
        return false
    }

    stored := bookmarkMap[key]
    if (IsObject(stored)) {
        storedHwnd := stored.id
    } else {
        storedHwnd := stored
    }

    ; Verify window still exists
    if (WinExist(storedHwnd)) {
        return storedHwnd
    } else {
        ; Clean up stale bookmark
        bookmarkMap.Delete(key)
        IniDelete("config.ini", "bookmarks", key)
        return false
    }
}

; Persists bookmarks to config.ini on script exit
SaveBookmarks(ExitReason, ExitCode) {
  global bookmarkMap, dontSave
  if (dontSave) {
    msg('dontSave is true, not saving bookmarks', { seconds: 5 })
    return
  }
  if (A_ThisHotkey == "") {
    return
  }
  try {
    for key, bookmarkData in bookmarkMap {
      if (IsObject(bookmarkData)) {
        ; New structure - save as id|title
        saveValue := bookmarkData.id "|" bookmarkData.title
      } else {
        ; Legacy structure - just the ID, get current title
        winId := bookmarkData
        title := WinGetTitle(winId)
        saveValue := winId "|" title
      }
      IniWrite(saveValue, "config.ini", "bookmarks", String(key))
    }
  } catch Error as e {
    msg('Error in SaveBookmarks ' e.Message, { seconds: 5 })
    log('Error in SaveBookmarks ' e.Message)
  }
}

; Debug function to display current bookmark mappings
; Shows a GUI with all active bookmarks allowing:
; - Quick number key activation (keys 1-9)
; - Filtering by process, title, or hotkey
; - Row selection via up/down keys
; - Direct activation with Enter or double-click
; - Dynamic row numbering that updates with filter
; Includes robust error handling for GUI state changes
showBookmarks(ExitReason := '', ExitCode := '') {
  static bookmarksGui := false
  static originalData := []

  ; Destroy existing GUI if it exists
  if (bookmarksGui) {
    try bookmarksGui.Destroy()
  }

  ; Create new GUI with modern styling
  bookmarksGui := Gui("+Resize +MinSize400x300")
  bookmarksGui.Title := "Bookmarks Manager"
  bookmarksGui.SetFont("s10", "Segoe UI")

  ; Add search box at the top
  bookmarksGui.Add("Text", "x10 y10", "Filter:")
  searchBox := bookmarksGui.Add("Edit", "x60 y8 w530 vSearchInput")
  searchBox.OnEvent("Change", UpdateFilter)

  ; Add ListView with proper styling and Type column. Multi-select allows clearing several bookmarks at once.
  lv := bookmarksGui.Add("ListView", "x10 y+10 w600 h400 Grid Multi", ["#", "Process", "Window Title", "Hotkey", "Type"])
  lv.OnEvent("DoubleClick", ActivateSelected)

  ; Store original data and populate ListView
  originalData := []

  ; Add all bookmarks from bookmarkMap
  for key, bookmarkData in bookmarkMap {
    ; Handle both new and legacy bookmark structures
    if (IsObject(bookmarkData)) {
      winId := bookmarkData.id
      title := bookmarkData.title
    } else {
      winId := bookmarkData
      title := WinGetTitle(winId)
    }

    if (WinExist(winId)) {
      process := WinGetProcessName(winId)
      ; Direct bookmarks have # prefix, sequential ones don't
      type := InStr(key, "#") == 1 ? "Dir" : "Seq"
      originalData.Push({ type: type, key: key, title: title, process: process, winId: winId })

      ; Only add row numbers for the first 9 rows, leave blank for others
      rowNum := A_Index <= 9 ? A_Index : ""
      lv.Add(, rowNum, process, title, key, type)
    }
  }

  ; Auto-size columns
  lv.ModifyCol(1, 30)   ; Row number column
  lv.ModifyCol(2, 150)  ; Process column
  lv.ModifyCol(3, 270)  ; Title column
  lv.ModifyCol(4, 100)  ; Hotkey column
  lv.ModifyCol(5, 50)   ; Type column (3 letters)

  ; Add status bar
  statusBar := bookmarksGui.Add("StatusBar", , "Total Bookmarks: " bookmarkMap.Count)

  ; Add buttons at the bottom
  buttonPanel := bookmarksGui.Add("Text", "x0 y+10 w600 h40 Section +Center", "")
  bookmarksGui.Add("Button", "xs+40 ys w90 h30", "Refresh").OnEvent("Click", GuiRefresh)
  bookmarksGui.Add("Button", "x+10 ys w90 h30", "Activate").OnEvent("Click", ActivateSelected)
  bookmarksGui.Add("Button", "x+10 ys w110 h30", "Clear selected").OnEvent("Click", ClearSelected)
  bookmarksGui.Add("Button", "x+10 ys w90 h30", "Clear all").OnEvent("Click", ClearAll)
  bookmarksGui.Add("Button", "x+10 ys w90 h30", "Close").OnEvent("Click", GuiClose)

  ; Add keyboard shortcuts help
  helpText := bookmarksGui.Add("Text", "x10 y+5", "Shortcuts: Ctrl/Shift click - Multi-select | Enter - Activate | Delete - Clear selected | Esc - Close")
  helpText.SetFont("s8")

  ; Position GUI on the correct monitor
  CoordMode("Mouse", "Screen")  ; Ensure we're using screen coordinates
  MouseGetPos(&mouseX, &mouseY)
  activeMonitor := getMonitor()

  ; Get the active monitor's dimensions
  MonitorGet(activeMonitor, &monLeft, &monTop, &monRight, &monBottom)

  ; Calculate initial position right next to the mouse cursor
  ; Use screen coordinates relative to monitor's left edge
  initialX := mouseX
  initialY := mouseY + 5


  ; Show GUI and get its dimensions
  bookmarksGui.Show("AutoSize x" initialX " y" initialY)
  guiWin := WinActive("A")

  ; Set up window message handler for detecting clicks outside GUI
  OnMessage(0x0006, handleGuiDeactivate)  ; WM_ACTIVATE

  ; Store the GUI handle for deactivation handling
  static lastGuiHwnd := 0
  lastGuiHwnd := bookmarksGui.Hwnd

  ; Add the handleGuiDeactivate function
  handleGuiDeactivate(wParam, lParam, msg, hwnd) {
    static isClosing := false
    if (hwnd == lastGuiHwnd && wParam == 0 && !isClosing) {  ; Window being deactivated
      isClosing := true
      SetTimer(() => GuiClose(), -1)  ; Use SetTimer to avoid recursion
      isClosing := false
    }
  }

  WinGetPos(&x, &y, &width, &height, "A")

  ; Adjust position to ensure it's fully visible on the active monitor
  yTarget := y
  xTarget := x

  if (monBottom - y < height) {
    yTarget := monBottom - height - 10  ; Add 10px margin
  }
  if (monRight - x < width) {
    xTarget := monRight - width - 10    ; Add 10px margin
  }

  ; Ensure it doesn't go off the left or top edges
  if (xTarget < monLeft) {
    xTarget := monLeft + 10    ; Add 10px margin
  }
  if (yTarget < monTop) {
    yTarget := monTop + 10     ; Add 10px margin
  }

  ; Move GUI to final position
  WinMove(xTarget, yTarget, , , "A")

  ; Handle GUI events
  bookmarksGui.OnEvent("Close", GuiClose)
  bookmarksGui.OnEvent("Size", GuiSize)
  bookmarksGui.OnEvent("Escape", GuiClose)

  ; Add message handlers for keyboard input
  OnMessage(0x100, OnKeyPress) ; WM_KEYDOWN
  OnMessage(0x102, OnChar)     ; WM_CHAR

  ; Focus search box
  searchBox.Focus()

  ; Handle direct character input (for number keys)
  ; This function processes WM_CHAR messages (0x102) for direct number key activation
  ; When a number key 1-9 is pressed, it:
  ; 1. Validates that the GUI and ListView still exist
  ; 2. Checks if the pressed number corresponds to a valid row
  ; 3. Activates the bookmark associated with that row
  ; Uses static variable to prevent errors with destroyed controls
  OnChar(wParam, lParam, msg, hwnd) {
    ; Safety check - only process if GUI and controls exist
    static lvExists := true

    if (!lvExists || !WinExist("ahk_id " . bookmarksGui.Hwnd)) {
      ; GUI is gone, disable this handler
      lvExists := false
      return
    }

    try {
      ; Convert ASCII code to character
      char := Chr(wParam)
      log("WM_CHAR: " char " (" wParam ")")

      ; Check if it's a number between 1 and 9
      if (char >= "1" && char <= "9") {
        charNum := Integer(char)
        ; Check if this row exists - with safety
        try {
          if (charNum <= lv.GetCount()) {
            log("Activating row from char: " charNum)
            lv.Modify(charNum, "+Select +Focus")
            ActivateSelected()
            return true
          }
        } catch Error as e {
          ; ListView was destroyed
          log("Error in OnChar: " e.Message)
          lvExists := false
        }
      }
    } catch Error as e {
      log("General error in OnChar: " e.Message)
      return
    }
  }

  UpdateFilter(*) {
    lv.Delete()
    searchText := searchBox.Value
    matchCount := 0

    for item in originalData {
      if (searchText = "" ||
        InStr(item.key, searchText) ||
        InStr(item.title, searchText) ||
        InStr(item.process, searchText)) {
        matchCount++

        ; Only add row numbers for the first 9 rows, leave blank for others
        ; This allows for quick activation via number keys 1-9
        ; Numbers are assigned sequentially based on filtered results
        rowNum := matchCount <= 9 ? matchCount : ""
        lv.Add(, rowNum, item.process, item.title, item.key, item.type)
      }
    }

    statusBar.SetText("Matches: " matchCount " / Total: " bookmarkMap.Count)
  }

  OnKeyPress(wParam, lParam, msg, hwnd) {
    ; Safety check - only process if GUI and controls exist
    static lvExists := true

    if (!lvExists || !WinExist("ahk_id " . bookmarksGui.Hwnd)) {
      ; GUI is gone, disable this handler
      lvExists := false
      return
    }

    try {
      ; Get the current filter text
      filterText := searchBox.Value

      ; Debug output
      log("Key pressed: " wParam " | Filter text: '" filterText "'")

      switch wParam {
        case 13: ; Enter
          ActivateSelected()
        case 46: ; Delete
          ClearSelected()
        case 38: ; Up Arrow
          if (lv.GetNext(0) > 1)
            lv.Modify(lv.GetNext(0) - 1, "+Select +Focus")
        case 40: ; Down Arrow
          if (lv.GetNext(0) < lv.GetCount())
            lv.Modify(lv.GetNext(0) + 1, "+Select +Focus")
          ; Handle number keys 1-9 (49-57)
        case 49, 50, 51, 52, 53, 54, 55, 56, 57:
          ; Convert key code to row number (49 = 1, 50 = 2, etc.)
          rowNum := wParam - 48
          log("Number key pressed: " rowNum)

          ; Check if the filter has exactly one digit
          if (StrLen(filterText) == 1 && filterText >= "1" && filterText <= "9") {
            ; Check if the row exists before selecting it
            if (rowNum <= lv.GetCount()) {
              ; Select the row and activate the bookmark
              log("Activating row: " rowNum)
              lv.Modify(rowNum, "+Select +Focus")
              ActivateSelected()
              return false ; Prevent default behavior
            }
          }
      }
    } catch Error as e {
      log("Error in OnKeyPress: " e.Message)
      lvExists := false
      return
    }
  }

  ActivateSelected(*) {
    try {
      if (selectedRow := lv.GetNext(0)) {
        ; Get the hotkey from column 4 (shifted from column 3 due to new row number column)
        hotkey := lv.GetText(selectedRow, 4)
        for item in originalData {
          if (item.key == hotkey) {
            if (WinExist(item.winId)) {
              if (!WinActive(item.winId))
                WinActivate(item.winId)
              GuiClose()
              break
            }
          }
        }
      }
    } catch Error as e {
      log("Error in ActivateSelected: " e.Message)
      ; Attempt to close the GUI if possible
      try GuiClose()
    }
  }

  ClearSelected(*) {
    try {
      selectedHotkeys := []
      selectedRow := 0
      while (selectedRow := lv.GetNext(selectedRow))
        selectedHotkeys.Push(lv.GetText(selectedRow, 4))

      clearedCount := 0
      for _, hotkey in selectedHotkeys {
        if (ClearBookmark(hotkey, false))
          clearedCount++
      }

      if (clearedCount > 0) {
        msg("Bookmarks liberados: " . clearedCount, { seconds: 3 })
        showBookmarks()
      }
    } catch Error as e {
      log("Error in ClearSelected: " e.Message)
    }
  }

  ClearAll(*) {
    if (MsgBox("Borrar todos los bookmarks asignados?", "Bookmarks", "YesNo Icon!") != "Yes")
      return

    if (ClearAllBookmarksAssigned() > 0)
      showBookmarks()
  }

  GuiRefresh(*) {
    showBookmarks()
  }

  GuiClose(*) {
    ; Remove message hooks before destroying the GUI
    OnMessage(0x100, OnKeyPress, 0)  ; Remove WM_KEYDOWN handler
    OnMessage(0x102, OnChar, 0)      ; Remove WM_CHAR handler
    OnMessage(0x0006, handleGuiDeactivate, 0)  ; Remove WM_ACTIVATE handler

    bookmarksGui.Destroy()
    bookmarksGui := false
  }

  GuiSize(thisGui, minMax, width, height) {
    if (minMax = -1) {  ; If window is minimized
      return
    }

    ; Adjust control sizes
    searchBox.Move(, , width - 70)
    lv.Move(, , width - 20, height - 140)  ; Adjust for search box, buttons, and status bar
    buttonPanel.Move(, , width)
    helpText.Move(y := height - 65)

    ; Update status bar (automatically handles its own positioning)
  }


}

;-------------------------------------------------------------------------------
; BOOKMARK HOTKEY CONFIG FUNCTIONS
;-------------------------------------------------------------------------------

; Loads enabled bookmark hotkey definitions from [bookmarkHotkeys] in config.ini
; Seeds defaults if section is empty/missing. Returns array of hotkey strings.
LoadBookmarkHotkeys() {
  global DEFAULT_BOOKMARK_HOTKEYS
  section := IniRead("config.ini", "bookmarkHotkeys",, "")

  if (section = "") {
    SeedDefaultBookmarkHotkeys()
    section := IniRead("config.ini", "bookmarkHotkeys",, "")
  }

  ; #r was added after many local configs were already seeded.
  ; Ensure it exists so Win+Shift+R can assign Win+R.
  if (!BookmarkHotkeyConfigHas(section, "#r")) {
    AddBookmarkHotkey("#r")
    section := IniRead("config.ini", "bookmarkHotkeys",, "")
  }

  result := []
  lines := StrSplit(section, "`n")
  for line in lines {
    parts := StrSplit(line, "=")
    if (parts.Length < 2)
      continue
    value := parts[2]
    pipeParts := StrSplit(value, "|")
    if (pipeParts.Length >= 2) {
      hotkeyStr := pipeParts[1]
      enabled := pipeParts[2]
      if (enabled = "1" && !BookmarkHotkeyIsReservedMenu(hotkeyStr))
        result.Push(hotkeyStr)
    } else {
      result.Push(value)
    }
  }
  return result
}

BookmarkHotkeyConfigHas(section, hotkeyStr) {
  lines := StrSplit(section, "`n")
  for line in lines {
    parts := StrSplit(line, "=")
    if (parts.Length < 2)
      continue
    pipeParts := StrSplit(parts[2], "|")
    if (pipeParts.Length >= 1 && pipeParts[1] = hotkeyStr)
      return true
  }
  return false
}

; Writes default hotkeys to [bookmarkHotkeys] on first run
SeedDefaultBookmarkHotkeys() {
  global DEFAULT_BOOKMARK_HOTKEYS
  for index, key in DEFAULT_BOOKMARK_HOTKEYS {
    IniWrite(key . "|1", "config.ini", "bookmarkHotkeys", String(index))
  }
}

; Returns ALL bookmark hotkeys (including disabled) as array of Maps for settings UI
GetAllBookmarkHotkeys() {
  section := IniRead("config.ini", "bookmarkHotkeys",, "")
  if (section = "") {
    SeedDefaultBookmarkHotkeys()
    section := IniRead("config.ini", "bookmarkHotkeys",, "")
  }

  result := []
  lines := StrSplit(section, "`n")
  for line in lines {
    parts := StrSplit(line, "=")
    if (parts.Length < 2)
      continue
    idx := parts[1]
    value := parts[2]
    pipeParts := StrSplit(value, "|")
    hotkeyStr := pipeParts[1]
    enabled := pipeParts.Length >= 2 ? pipeParts[2] : "1"
    result.Push(Map("index", idx, "hotkey", hotkeyStr, "enabled", enabled))
  }
  return result
}

; Adds a new bookmark hotkey to config.ini. Returns the new index.
AddBookmarkHotkey(hotkeyStr) {
  if (BookmarkHotkeyIsReservedMenu(hotkeyStr)) {
    msg("Reservado para menu: " . hotkeyStr, { seconds: 4 })
    return false
  }

  section := IniRead("config.ini", "bookmarkHotkeys",, "")
  maxIndex := 0
  if (section != "") {
    lines := StrSplit(section, "`n")
    for line in lines {
      parts := StrSplit(line, "=")
      if (parts.Length >= 1) {
        try {
          idx := Integer(parts[1])
          if (idx > maxIndex)
            maxIndex := idx
        }
      }
    }
  }
  newIndex := maxIndex + 1
  IniWrite(hotkeyStr . "|1", "config.ini", "bookmarkHotkeys", String(newIndex))
  return newIndex
}

; Removes a bookmark hotkey by index. Disables the live hotkey first.
RemoveBookmarkHotkey(index) {
  section := IniRead("config.ini", "bookmarkHotkeys",, "")
  lines := StrSplit(section, "`n")
  for line in lines {
    parts := StrSplit(line, "=")
    if (parts.Length >= 2 && parts[1] = String(index)) {
      pipeParts := StrSplit(parts[2], "|")
      hotkeyStr := pipeParts[1]
      try Hotkey(hotkeyStr, "Off")
      try Hotkey("+" . hotkeyStr, "Off")
    }
  }
  IniDelete("config.ini", "bookmarkHotkeys", String(index))
}

; Toggles enabled/disabled state for a bookmark hotkey
ToggleBookmarkHotkey(index, enabled) {
  section := IniRead("config.ini", "bookmarkHotkeys",, "")
  lines := StrSplit(section, "`n")
  for line in lines {
    parts := StrSplit(line, "=")
    if (parts.Length >= 2 && parts[1] = String(index)) {
      pipeParts := StrSplit(parts[2], "|")
      hotkeyStr := pipeParts[1]
      IniWrite(hotkeyStr . "|" . (enabled ? "1" : "0"), "config.ini", "bookmarkHotkeys", String(index))

      if (enabled) {
        if (BookmarkHotkeyIsReservedMenu(hotkeyStr)) {
          IniWrite(hotkeyStr . "|0", "config.ini", "bookmarkHotkeys", String(index))
          msg("Reservado para menu: " . hotkeyStr, { seconds: 4 })
          return
        }
        SetHotkeysForBookmark(hotkeyStr)
      } else {
        try Hotkey(hotkeyStr, "Off")
        try Hotkey("+" . hotkeyStr, "Off")
      }
      return
    }
  }
}

; Validates an AHK hotkey string by attempting to register/unregister it
ValidateHotkeyString(hotkeyStr) {
  if (BookmarkHotkeyIsReservedMenu(hotkeyStr))
    return false

  stripped := hotkeyStr
  stripped := StrReplace(stripped, "#", "")
  stripped := StrReplace(stripped, "!", "")
  stripped := StrReplace(stripped, "^", "")
  stripped := StrReplace(stripped, "+", "")

  ; Must have at least one modifier
  if (stripped = hotkeyStr)
    return false
  ; Must have a key after stripping modifiers
  if (stripped = "")
    return false

  try {
    Hotkey(hotkeyStr, (*) => "", "On")
    Hotkey(hotkeyStr, "Off")
    return true
  } catch {
    return false
  }
}

VerifyHotkeys() {
  global bookmarkMap
  for key, bookmarkData in bookmarkMap {
    ; Handle both new and legacy bookmark structures
    if (IsObject(bookmarkData)) {
      winId := bookmarkData.id
      title := bookmarkData.title
    } else {
      winId := bookmarkData
      title := WinGetTitle(winId)
    }

    if(! WinExist(winId)) {

      msg('Window not found: ' key ' -> ' title, { seconds: 5, x: 0, y: 0 })
      soundError()
      bookmarkMap.Delete(key)
      try FileAppend(A_Now " -> " key " -> " title "`n", "bookmarks-missing.txt")
    }
  }
}