#Requires AutoHotkey v2.0
#SingleInstance Force
#ErrorStdOut UTF-8

; MainPortable for AutoHotkey v2.
; Portable: copy this folder to another PC and run MainPortable.ahk.
; State is saved next to this script in MainPortable.ini.

InstallKeybdHook()
SendMode("Input")
SetTitleMatchMode(2)
SetWorkingDir(A_ScriptDir)

global CONFIG_FILE := A_ScriptDir . "\MainPortable.ini"
global LOG_FILE := A_ScriptDir . "\MainPortable.log"
global ICON_FILE := A_ScriptDir . "\mainportable.ico"
global USER_CUSTOM_FILE := A_ScriptDir . "\user-custom.ahk"
global bookmarkMap := Map()
global dontSave := false
global hotkeysSuspended := false
global keyboardMouseEnabled := true
global cursorKeysEnabled := true
global vimMode := false
global vimCurrentMode := "off"
global vimVisualMode := false
global vimVisualLineMode := false
global vimPendingOperator := ""
global vimLAltDownTick := 0
global vimTapThresholdMs := 180
global vimRegistered := false
global watchedFileTimes := Map()

global DEFAULT_BOOKMARK_HOTKEYS := [
    "#1", "#2", "#3", "#4", "#5", "#6", "#7", "#8", "#9", "#0",
    "#b", "#d", "#e", "#f", "#g", "#i", "#t", "#q", "#z", "#v", "#x",
    "!#a", "!#d", "!#e", "!#f", "!#g", "!#q", "!#r", "!#v", "!#x", "!#w", "!#z"
]

OnExit(SaveBookmarks)
EnsureUserCustomFile()
SetupTray()
LoadBookmarksInBookmarkMap()
InitPortableVimMode()

for key in LoadBookmarkHotkeys() {
    SetHotkeysForBookmark(key)
}

^+!b::ShowBookmarks()
#!^b::ShowBookmarkAdminMenu()
$#s::StartSequentialBookmark(false)
$#+s::StartSequentialBookmark(true)

#Include *i user-custom.ahk

; Cursor movement from the main project.
CapsLock::SetCapsLockState(!GetKeyState("CapsLock", "T"))
#HotIf keyboardMouseEnabled
CapsLock & k::Send("{Up}")
CapsLock & j::Send("{Down}")
CapsLock & h::Send("{Left}")
CapsLock & l::Send("{Right}")
CapsLock & `;::Send("{End}")
CapsLock & g::Send("{Home}")
CapsLock & d::Send("{Delete}")
CapsLock & Esc::ToggleKeyboardMouse()
#HotIf

#HotIf cursorKeysEnabled && !vimMode
!j::Send("{Down}")
!+j::Send("{PgDn}")
!k::Send("{Up}")
!+k::Send("{PgUp}")
!h::Send("{Left}")
!l::Send("{Right}")
!+l::Send("{End}")
!+h::Send("{Home}")
!d::Send("{Delete}")
#HotIf

#!k::ToggleCursorKeys()
!v::ToggleVimMode()

~LAlt::PortableVimLAltDown()
~LAlt Up::PortableVimLAltUp()

SetupTray() {
    try {
        if FileExist(ICON_FILE) {
            TraySetIcon(ICON_FILE)
        } else {
            TraySetIcon("imageres.dll", 174)
        }
    }

    A_TrayMenu.Delete()
    A_TrayMenu.Add("Show bookmarks`tCtrl+Shift+Alt+B", (*) => ShowBookmarks())
    A_TrayMenu.SetIcon("Show bookmarks`tCtrl+Shift+Alt+B", PortableIcon("settings"),, 0)
    A_TrayMenu.Add("Bookmark active window...", (*) => PromptBookmarkActiveWindow())
    A_TrayMenu.SetIcon("Bookmark active window...", PortableIcon("check"),, 0)
    A_TrayMenu.Add("Quick bookmark active window`tWin+Shift+S", (*) => StartSequentialBookmark(true))
    A_TrayMenu.SetIcon("Quick bookmark active window`tWin+Shift+S", PortableIcon("keyboard"),, 0)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Toggle CapsLock cursor`tCapsLock+Esc", (*) => ToggleKeyboardMouse())
    A_TrayMenu.SetIcon("Toggle CapsLock cursor`tCapsLock+Esc", PortableIcon("keyboard"),, 0)
    A_TrayMenu.Check("Toggle CapsLock cursor`tCapsLock+Esc")
    A_TrayMenu.Add("Toggle cursor keys`tWin+Alt+K", (*) => ToggleCursorKeys())
    A_TrayMenu.SetIcon("Toggle cursor keys`tWin+Alt+K", PortableIcon("keyboard"),, 0)
    A_TrayMenu.Check("Toggle cursor keys`tWin+Alt+K")
    A_TrayMenu.Add("Toggle Vim mode`tAlt tap / Alt+V", (*) => ToggleVimMode())
    A_TrayMenu.SetIcon("Toggle Vim mode`tAlt tap / Alt+V", PortableIcon("vim-off"),, 0)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Save now", (*) => SaveBookmarks())
    A_TrayMenu.SetIcon("Save now", PortableIcon("check"),, 0)
    A_TrayMenu.Add("Reload bookmarks", (*) => ReloadBookmarksFromTray())
    A_TrayMenu.SetIcon("Reload bookmarks", PortableIcon("restart"),, 0)
    A_TrayMenu.Add("Clean missing windows", (*) => CleanMissingBookmarks(true))
    A_TrayMenu.SetIcon("Clean missing windows", PortableIcon("check"),, 0)
    A_TrayMenu.Add("Clear all bookmarks", (*) => ConfirmClearBookmarks())
    A_TrayMenu.SetIcon("Clear all bookmarks", PortableIcon("exit"),, 0)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Open config", (*) => Run('notepad.exe "' . CONFIG_FILE . '"'))
    A_TrayMenu.SetIcon("Open config", PortableIcon("config"),, 0)
    A_TrayMenu.Add("Open user custom", (*) => OpenUserCustomFile())
    A_TrayMenu.SetIcon("Open user custom", PortableIcon("code"),, 0)
    A_TrayMenu.Add("Open log", (*) => OpenLogFile())
    A_TrayMenu.SetIcon("Open log", PortableIcon("logs"),, 0)
    A_TrayMenu.Add("Open script folder", (*) => Run('explorer.exe "' . A_ScriptDir . '"'))
    A_TrayMenu.SetIcon("Open script folder", PortableIcon("folder"),, 0)
    A_TrayMenu.Add("Copy hotkey help", (*) => CopyHotkeyHelp())
    A_TrayMenu.SetIcon("Copy hotkey help", PortableIcon("logs"),, 0)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Suspend bookmark hotkeys", (*) => ToggleBookmarkHotkeys())
    A_TrayMenu.SetIcon("Suspend bookmark hotkeys", PortableIcon("pause"),, 0)
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    A_TrayMenu.SetIcon("Exit", PortableIcon("exit"),, 0)
    A_TrayMenu.Default := "Show bookmarks`tCtrl+Shift+Alt+B"
    A_IconTip := "MainPortable"
    OnMessage(0x404, TrayIconClick)
    StartPortableFileWatcher()
}

PortableIcon(name) {
    iconPath := A_ScriptDir . "\" . name . ".png"
    if FileExist(iconPath) {
        return iconPath
    }
    return A_WinDir . "\System32\shell32.dll"
}

TrayIconClick(wParam, lParam, uMsg, hwnd) {
    if (lParam = 0x202) {
        SetTimer(() => A_TrayMenu.Show(), -1)
    }
}

EnsureUserCustomFile() {
    if FileExist(USER_CUSTOM_FILE) {
        return
    }

    FileAppend(GetDefaultUserCustomContent(), USER_CUSTOM_FILE, "UTF-8")
    SetTimer(() => Reload(), -500)
}

GetDefaultUserCustomContent() {
    return "; user-custom.ahk`n"
        . "; Add your own portable hotkeys/functions here.`n"
        . "; This file is included by MainPortable.ahk and watched for changes.`n"
        . "; Save this file and MainPortable will reload automatically.`n"
        . "`n"
        . "; Examples:`n"
        . "; #n::Run('notepad.exe')`n"
        . "; #Enter::Run('wt.exe')`n"
}

OpenUserCustomFile() {
    EnsureUserCustomFile()
    Run('notepad.exe "' . USER_CUSTOM_FILE . '"')
}

StartPortableFileWatcher() {
    global watchedFileTimes
    watchedFileTimes := Map()
    WatchPortableFile(A_ScriptFullPath)
    WatchPortableFile(USER_CUSTOM_FILE)
    SetTimer(CheckPortableFileChanges, 1000)
}

WatchPortableFile(filePath) {
    global watchedFileTimes
    if FileExist(filePath) {
        watchedFileTimes[filePath] := FileGetTime(filePath, "M")
    }
}

CheckPortableFileChanges() {
    global watchedFileTimes
    for filePath, lastModified in watchedFileTimes.Clone() {
        if !FileExist(filePath) {
            if (filePath = USER_CUSTOM_FILE) {
                EnsureUserCustomFile()
            }
            continue
        }

        currentModified := FileGetTime(filePath, "M")
        if (currentModified != lastModified) {
            SaveBookmarks()
            Reload()
        }
    }
}

PromptBookmarkActiveWindow() {
    result := InputBox("Hotkey/id to assign to active window:`nExamples: #1, #b, !#w, a", "Bookmark Active Window", "w380 h150")
    if (result.Result != "OK") {
        return
    }

    key := Trim(result.Value)
    if (key = "") {
        Notify("Bookmark key is empty")
        return
    }

    SetBookmark(key)
    if IsHotkeyStyleKey(key) {
        try SetHotkeysForBookmark(key)
    }
}

ReloadBookmarksFromTray() {
    LoadBookmarksInBookmarkMap()
    Notify("Bookmarks reloaded")
}

CleanMissingBookmarks(showNotice := false) {
    removed := 0
    for key, data in bookmarkMap.Clone() {
        winId := IsObject(data) ? data.id : data
        if !WinExist(winId) {
            bookmarkMap.Delete(key)
            try IniDelete(CONFIG_FILE, "bookmarks", key)
            removed++
        }
    }
    if (showNotice) {
        Notify("Removed missing bookmarks: " . removed)
    }
    return removed
}

ConfirmClearBookmarks() {
    answer := MsgBox("Clear all saved bookmarks?", "MainPortable", "YesNo Icon!")
    if (answer = "Yes") {
        global bookmarkMap
        bookmarkMap := Map()
        try IniDelete(CONFIG_FILE, "bookmarks")
        Notify("Bookmarks cleared")
    }
}

OpenLogFile() {
    if !FileExist(LOG_FILE) {
        FileAppend("", LOG_FILE, "UTF-8")
    }
    Run('notepad.exe "' . LOG_FILE . '"')
}

CopyHotkeyHelp() {
    A_Clipboard := "MainPortable hotkeys`n"
        . "Ctrl+Shift+Alt+B: show bookmarks manager`n"
        . "Win+S then key: create/toggle sequential bookmark`n"
        . "Win+Shift+S then key: reassign sequential bookmark`n"
        . "Configured direct hotkey: activate/minimize bookmark`n"
        . "Shift+configured direct hotkey: assign active window`n"
        . "CapsLock+h/j/k/l: arrow keys`n"
        . "Alt+h/j/k/l: arrow keys when cursor keys enabled`n"
        . "CapsLock+n: left click | CapsLock+,: right click`n"
        . "CapsLock+Esc: toggle CapsLock cursor keys`n"
        . "Win+Alt+K: toggle Alt cursor keys`n"
        . "Tap Left Alt or Alt+V: toggle Vim mode`n"
        . "Vim mode: h/j/k/l arrows, w/b/e words, 0/$ line, g/Shift+g doc, d/c/y ops, v visual"
    Notify("Hotkey help copied")
}

ToggleKeyboardMouse() {
    global keyboardMouseEnabled
    keyboardMouseEnabled := !keyboardMouseEnabled
    A_TrayMenu.ToggleCheck("Toggle CapsLock cursor`tCapsLock+Esc")
    Notify(keyboardMouseEnabled ? "CapsLock cursor enabled" : "CapsLock cursor disabled")
}

KeyboardMouseMove(dx, dy) {
    global keyboardMouseEnabled
    if (!keyboardMouseEnabled) {
        return
    }

    step := 18
    if GetKeyState("Shift", "P") {
        step := 55
    } else if GetKeyState("Ctrl", "P") {
        step := 5
    }

    MouseMove(dx * step, dy * step, 0, "R")
}

ToggleCursorKeys() {
    global cursorKeysEnabled
    cursorKeysEnabled := !cursorKeysEnabled
    if (cursorKeysEnabled) {
        A_TrayMenu.Check("Toggle cursor keys`tWin+Alt+K")
    } else {
        A_TrayMenu.Uncheck("Toggle cursor keys`tWin+Alt+K")
    }
    Notify("cursor keys " . (cursorKeysEnabled ? "Enabled" : "Disabled"))
}

ToggleVimMode() {
    global vimMode
    SetVimMode(!vimMode)
}

SetVimMode(enabled) {
    global vimMode, vimCurrentMode, vimVisualMode, vimVisualLineMode, vimPendingOperator
    vimMode := enabled
    vimCurrentMode := enabled ? "normal" : "off"
    vimVisualMode := false
    vimVisualLineMode := false
    vimPendingOperator := ""
    if (vimMode) {
        A_TrayMenu.Check("Toggle Vim mode`tAlt tap / Alt+V")
    } else {
        A_TrayMenu.Uncheck("Toggle Vim mode`tAlt tap / Alt+V")
    }
    Notify(vimMode ? "Vim mode enabled" : "Vim mode disabled")
    return vimMode
}

PortableVimLAltDown(*) {
    global vimLAltDownTick
    vimLAltDownTick := A_TickCount
    Send("{Blind}{vkE8}")
}

PortableVimLAltUp(*) {
    global vimLAltDownTick, vimTapThresholdMs, vimMode
    if (A_PriorKey != "LAlt") {
        return
    }
    if ((A_TickCount - vimLAltDownTick) > vimTapThresholdMs) {
        return
    }
    if (vimMode) {
        VimEscape()
    } else {
        SetVimMode(true)
    }
}

InitPortableVimMode() {
    global vimRegistered
    if (vimRegistered) {
        return
    }
    vimRegistered := true

    keymap := Map(
        "h", VimAction("motion", "left"),
        "j", VimAction("motion", "down"),
        "k", VimAction("motion", "up"),
        "l", VimAction("motion", "right"),
        "b", VimAction("motion", "word_back"),
        "w", VimAction("motion", "word_forward"),
        "+w", VimAction("motion", "word_back"),
        "e", VimAction("motion", "word_end"),
        "0", VimAction("motion", "line_start"),
        "+4", VimAction("motion", "line_end"),
        "g", VimAction("motion", "doc_start"),
        "+g", VimAction("motion", "doc_end"),
        "+h", VimAction("history_nav", "back"),
        "+l", VimAction("history_nav", "forward"),
        "v", VimAction("toggle_visual"),
        "+v", VimAction("toggle_visual_line"),
        "x", VimAction("delete_char", false),
        "+x", VimAction("delete_char", true),
        "d", VimAction("operator", "d"),
        "+d", VimAction("operator_motion", { operator: "d", motion: "line_end" }),
        "c", VimAction("operator", "c"),
        "+c", VimAction("operator_motion", { operator: "c", motion: "line_end" }),
        "y", VimAction("operator", "y"),
        "+y", VimAction("line_operator", "y"),
        "p", VimAction("paste"),
        "+p", VimAction("paste_before"),
        "u", VimAction("send", "^z"),
        "i", VimAction("insert_here"),
        "+i", VimAction("insert_here", "{Home}"),
        "a", VimAction("insert_after", "{Right}"),
        "+a", VimAction("insert_after", "{End}"),
        "o", VimAction("insert_after", "{End}{Enter}"),
        "+o", VimAction("insert_after", "{Home}{Enter}{Up}")
    )

    VimRegisterKeymap(keymap)
    VimRegisterSuppressedPrintables(keymap)

    HotIf(VimHotIfEnabled)
    Hotkey("Esc", (*) => VimEscape(), "On")
    Hotkey("~LButton", (*) => SetVimMode(false), "On")
    HotIf()
}

VimAction(kind, value?) {
    action := { kind: kind }
    if (IsSet(value)) {
        action.value := value
    }
    return action
}

VimHotIf(*) {
    global vimMode
    return vimMode
}

VimHotIfEnabled(*) {
    global vimMode
    return vimMode
}

VimRegisterKeymap(keymap) {
    HotIf(VimHotIf)
    for hotkeyName, actionSpec in keymap {
        Hotkey(hotkeyName, VimBuildHotkeyHandler(actionSpec), "On")
    }
    HotIf()
}

VimBuildHotkeyHandler(actionSpec) {
    return (*) => VimExecuteAction(actionSpec)
}

VimRegisterSuppressedPrintables(keymap) {
    allowedKeys := Map()
    for hotkeyName, _ in keymap {
        allowedKeys[hotkeyName] := true
    }

    suppressList := [
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "+a", "+b", "+c", "+d", "+e", "+f", "+g", "+h", "+i", "+j", "+k", "+l", "+m",
        "+n", "+o", "+p", "+q", "+r", "+s", "+t", "+u", "+v", "+w", "+x", "+y", "+z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "+0", "+1", "+2", "+3", "+4", "+5", "+6", "+7", "+8", "+9",
        "Space", "-", "=", "[", "]", ";", "'", ",", ".", "/", "Tab", "Enter", "Backspace", "Delete"
    ]

    HotIf(VimHotIf)
    for _, hotkeyName in suppressList {
        if !allowedKeys.Has(hotkeyName) {
            Hotkey(hotkeyName, (*) => "", "On")
        }
    }
    HotIf()
}

VimExecuteAction(actionSpec) {
    switch actionSpec.kind {
        case "motion":
            VimHandleMotion(actionSpec.value)
        case "toggle_visual":
            ToggleVimVisualMode()
        case "toggle_visual_line":
            ToggleVimVisualLineMode()
        case "delete_char":
            VimDeleteChar(actionSpec.HasOwnProp("value") ? actionSpec.value : false)
        case "operator":
            VimHandleOperator(actionSpec.value)
        case "operator_motion":
            VimApplyOperator(actionSpec.value.operator, actionSpec.value.motion)
        case "line_operator":
            VimApplyLineOperator(actionSpec.value)
        case "paste":
            Send("^v")
        case "paste_before":
            Send("{Left}^v")
        case "history_nav":
            Send(actionSpec.value = "back" ? "!{Left}" : "!{Right}")
        case "send":
            Send(actionSpec.value)
        case "insert_after":
            if actionSpec.HasOwnProp("value")
                Send(actionSpec.value)
            SetVimMode(false)
        case "insert_here":
            if actionSpec.HasOwnProp("value")
                Send(actionSpec.value)
            SetVimMode(false)
    }
}

VimMotionKeys(motion, select := false) {
    switch motion {
        case "left": return select ? "+{Left}" : "{Left}"
        case "down": return select ? "+{Down}" : "{Down}"
        case "up": return select ? "+{Up}" : "{Up}"
        case "right": return select ? "+{Right}" : "{Right}"
        case "word_back": return select ? "^+{Left}" : "^{Left}"
        case "word_forward": return select ? "^+{Right}" : "^{Right}"
        case "line_start": return select ? "+{Home}" : "{Home}"
        case "line_end": return select ? "+{End}" : "{End}"
        case "doc_start": return select ? "^+{Home}" : "^{Home}"
        case "doc_end": return select ? "^+{End}" : "^{End}"
        default: return ""
    }
}

VimSendMotion(motion, select := false) {
    global vimVisualLineMode
    if (motion = "word_end") {
        Send(select ? "^+{Right}+{Left}" : "^{Right}{Left}")
        return
    }
    keys := VimMotionKeys(motion, select || vimVisualLineMode)
    if (keys != "") {
        Send(keys)
    }
}

VimHandleMotion(motion) {
    global vimPendingOperator, vimVisualMode
    if (vimPendingOperator != "") {
        op := vimPendingOperator
        vimPendingOperator := ""
        VimApplyOperator(op, motion)
        return
    }
    VimSendMotion(motion, vimVisualMode)
}

VimHandleOperator(op) {
    global vimPendingOperator, vimVisualMode, vimVisualLineMode
    if (vimVisualMode || vimVisualLineMode) {
        switch op {
            case "d": Send("{Delete}")
            case "c":
                Send("{Delete}")
                SetVimMode(false)
                return
            case "y": Send("^c")
        }
        VimSetPrimaryMode("normal")
        return
    }
    if (vimPendingOperator = op) {
        vimPendingOperator := ""
        VimApplyLineOperator(op)
        return
    }
    vimPendingOperator := op
    SetTimer(() => vimPendingOperator := "", -1200)
}

VimApplyOperator(op, motion) {
    VimSendMotion(motion, true)
    switch op {
        case "d": Send("{Delete}")
        case "c":
            Send("{Delete}")
            SetVimMode(false)
        case "y": Send("^c")
    }
}

VimApplyLineOperator(op) {
    Send("{Home}+{End}")
    switch op {
        case "d": Send("{Delete}")
        case "c":
            Send("{Delete}")
            SetVimMode(false)
        case "y": Send("^c")
    }
}

VimDeleteChar(backward := false) {
    global vimVisualMode, vimVisualLineMode
    if (vimVisualMode || vimVisualLineMode) {
        Send("{Delete}")
        VimSetPrimaryMode("normal")
        return
    }
    Send(backward ? "{Backspace}" : "{Delete}")
}

VimSetPrimaryMode(mode) {
    global vimCurrentMode, vimMode, vimVisualMode, vimVisualLineMode
    vimCurrentMode := mode
    vimMode := (mode != "off")
    vimVisualMode := (mode = "visual")
    vimVisualLineMode := (mode = "visual_line")
}

ToggleVimVisualMode() {
    global vimVisualMode
    VimSetPrimaryMode(vimVisualMode ? "normal" : "visual")
}

ToggleVimVisualLineMode() {
    global vimVisualLineMode
    if (vimVisualLineMode) {
        VimSetPrimaryMode("normal")
        return
    }
    VimSetPrimaryMode("visual_line")
    Send("{Home}+{End}")
}

VimEscape() {
    global vimPendingOperator, vimVisualMode, vimVisualLineMode, vimMode
    if (vimPendingOperator != "") {
        vimPendingOperator := ""
        return
    }
    if (vimVisualMode || vimVisualLineMode) {
        VimSetPrimaryMode("normal")
        return
    }
    if (vimMode) {
        SetVimMode(false)
    }
}

ToggleBookmarkHotkeys() {
    global hotkeysSuspended
    hotkeysSuspended := !hotkeysSuspended
    Suspend(hotkeysSuspended)
    A_TrayMenu.ToggleCheck("Suspend bookmark hotkeys")
    Notify(hotkeysSuspended ? "Bookmark hotkeys suspended" : "Bookmark hotkeys enabled")
}

IsHotkeyStyleKey(key) {
    return InStr(key, "#") || InStr(key, "!") || InStr(key, "^") || InStr(key, "+")
}

ShowBookmarkAdminMenu() {
    menu := Menu()
    menu.Add("Show bookmarks", (*) => ShowBookmarks())
    menu.Add("Reload bookmarks", (*) => LoadBookmarksInBookmarkMap())
    menu.Add("Clear bookmarks and reload", (*) => ClearAndReload())
    menu.Add("Reset all bookmarks", (*) => ResetAllBookmarks())
    menu.Add("Open config", (*) => Run('notepad.exe "' . CONFIG_FILE . '"'))
    menu.Show()
}

StartSequentialBookmark(deleteFirst := false) {
    ih := InputHook("L1 T1", "{Esc}")
    ih.Start()
    ih.Wait()

    char := ih.Input
    if (char = "") {
        if (!deleteFirst) {
            ShowBookmarks()
        } else {
            Notify("Bookmark reassign cancelled")
        }
        return
    }

    if (deleteFirst && bookmarkMap.Has(char)) {
        bookmarkMap.Delete(char)
        try IniDelete(CONFIG_FILE, "bookmarks", char)
    }
    ActivateOrMinimizeBookmark(char)
}

SetHotkeysForBookmark(key) {
    Hotkey(key, (*) => ActivateOrMinimizeBookmark(key))
    Hotkey("+" . key, (*) => SetBookmark(key))
}

ActivateOrMinimizeBookmark(key) {
    global bookmarkMap
    try {
        if (!bookmarkMap.Has(key)) {
            SetBookmark(key)
            return
        }

        data := bookmarkMap[key]
        winId := IsObject(data) ? data.id : data

        if (!WinExist(winId)) {
            bookmarkMap.Delete(key)
            try IniDelete(CONFIG_FILE, "bookmarks", key)
            SetBookmark(key)
            return
        }

        if WinActive(winId) {
            WinMinimize(winId)
        } else {
            WinActivate(winId)
        }
    } catch Error as e {
        LogError("ActivateOrMinimizeBookmark", e)
        SetBookmark(key)
    }
}

SetBookmark(key, winHandle := 0) {
    global bookmarkMap
    try {
        hwnd := winHandle ? winHandle : WinGetID("A")
        winId := "ahk_id " . hwnd
        title := WinGetTitle(winId)

        if (title = "") {
            Notify("No active window to bookmark")
            return
        }

        bookmarkMap[key] := { id: winId, title: title }
        IniWrite(winId . "|" . title, CONFIG_FILE, "bookmarks", String(key))
        Notify("Bookmark: " . key . " -> " . title)
    } catch Error as e {
        LogError("SetBookmark", e)
        Notify("Error setting bookmark: " . e.Message)
    }
}

LoadBookmarksInBookmarkMap() {
    global bookmarkMap
    bookmarkMap := Map()
    section := IniRead(CONFIG_FILE, "bookmarks", , "")

    for line in StrSplit(section, "`n") {
        parts := StrSplit(line, "=")
        if (parts.Length != 2) {
            continue
        }

        key := parts[1]
        value := parts[2]
        pipeParts := StrSplit(value, "|")

        winId := pipeParts[1]
        title := pipeParts.Length >= 2 ? pipeParts[2] : ""

        if WinExist(winId) {
            if (title = "") {
                title := WinGetTitle(winId)
            }
            bookmarkMap[key] := { id: winId, title: title }
        } else {
            try IniDelete(CONFIG_FILE, "bookmarks", key)
        }
    }
}

SaveBookmarks(*) {
    global bookmarkMap, dontSave
    if (dontSave) {
        return
    }

    try {
        for key, data in bookmarkMap {
            winId := IsObject(data) ? data.id : data
            if !WinExist(winId) {
                continue
            }
            title := IsObject(data) ? data.title : WinGetTitle(winId)
            IniWrite(winId . "|" . title, CONFIG_FILE, "bookmarks", String(key))
        }
    } catch Error as e {
        LogError("SaveBookmarks", e)
    }
}

ShowBookmarks() {
    global bookmarkMap
    static bookmarksGui := false
    static originalData := []

    if (bookmarksGui) {
        try bookmarksGui.Destroy()
    }

    bookmarksGui := Gui("+Resize +MinSize460x320", "Bookmarks Manager")
    bookmarksGui.SetFont("s10", "Segoe UI")

    bookmarksGui.Add("Text", "x10 y10", "Filter:")
    searchBox := bookmarksGui.Add("Edit", "x60 y8 w560 vSearchInput")
    lv := bookmarksGui.Add("ListView", "x10 y+10 w650 h380 Grid -Multi", ["#", "Process", "Window Title", "Hotkey", "Type"])
    statusBar := bookmarksGui.Add("StatusBar", , "Total Bookmarks: " . bookmarkMap.Count)
    bookmarksGui.Add("Button", "x190 y+10 w90 h30", "Refresh").OnEvent("Click", (*) => ShowBookmarks())
    bookmarksGui.Add("Button", "x+12 yp w90 h30", "Activate").OnEvent("Click", ActivateSelected)
    bookmarksGui.Add("Button", "x+12 yp w90 h30", "Close").OnEvent("Click", GuiClose)
    helpText := bookmarksGui.Add("Text", "x10 y+8", "Enter/double-click activates | 1-9 quick activate | Esc closes")
    helpText.SetFont("s8")

    originalData := []
    for key, data in bookmarkMap {
        winId := IsObject(data) ? data.id : data
        title := IsObject(data) ? data.title : ""
        if WinExist(winId) {
            process := WinGetProcessName(winId)
            if (title = "") {
                title := WinGetTitle(winId)
            }
            type := InStr(key, "#") || InStr(key, "!") || InStr(key, "^") || InStr(key, "+") ? "Dir" : "Seq"
            originalData.Push({ key: key, title: title, process: process, winId: winId, type: type })
        }
    }

    PopulateList("")
    lv.OnEvent("DoubleClick", ActivateSelected)
    searchBox.OnEvent("Change", (*) => PopulateList(searchBox.Value))
    bookmarksGui.OnEvent("Close", GuiClose)
    bookmarksGui.OnEvent("Escape", GuiClose)
    bookmarksGui.OnEvent("Size", GuiSize)

    OnMessage(0x100, OnKeyDown)

    bookmarksGui.Show("AutoSize")
    searchBox.Focus()

    PopulateList(filterText) {
        lv.Delete()
        matchCount := 0
        for item in originalData {
            if (filterText = "" || InStr(item.key, filterText) || InStr(item.title, filterText) || InStr(item.process, filterText)) {
                matchCount++
                rowNum := matchCount <= 9 ? matchCount : ""
                lv.Add(, rowNum, item.process, item.title, item.key, item.type)
            }
        }
        lv.ModifyCol(1, 35)
        lv.ModifyCol(2, 140)
        lv.ModifyCol(3, 330)
        lv.ModifyCol(4, 100)
        lv.ModifyCol(5, 50)
        statusBar.SetText("Matches: " . matchCount . " / Total: " . originalData.Length)
    }

    ActivateSelected(*) {
        selectedRow := lv.GetNext(0)
        if (!selectedRow) {
            return
        }

        hotkey := lv.GetText(selectedRow, 4)
        for item in originalData {
            if (item.key = hotkey && WinExist(item.winId)) {
                WinActivate(item.winId)
                GuiClose()
                return
            }
        }
    }

    OnKeyDown(wParam, lParam, msg, hwnd) {
        if (!bookmarksGui || hwnd != bookmarksGui.Hwnd && !DllCall("IsChild", "ptr", bookmarksGui.Hwnd, "ptr", hwnd)) {
            return
        }

        if (wParam = 13) {
            ActivateSelected()
            return 0
        }

        if (wParam >= 49 && wParam <= 57) {
            rowNum := wParam - 48
            if (rowNum <= lv.GetCount()) {
                lv.Modify(rowNum, "+Select +Focus")
                ActivateSelected()
                return 0
            }
        }
    }

    GuiClose(*) {
        OnMessage(0x100, OnKeyDown, 0)
        try bookmarksGui.Destroy()
        bookmarksGui := false
    }

    GuiSize(thisGui, minMax, width, height) {
        if (minMax = -1) {
            return
        }
        searchBox.Move(, , width - 70)
        lv.Move(, , width - 20, height - 130)
        helpText.Move(, height - 28)
    }
}

ClearAndReload() {
    global dontSave, bookmarkMap
    dontSave := true
    try IniDelete(CONFIG_FILE, "bookmarks")
    bookmarkMap := Map()
    Reload()
}

ResetAllBookmarks() {
    ClearAndReload()
}

LoadBookmarkHotkeys() {
    section := IniRead(CONFIG_FILE, "bookmarkHotkeys", , "")
    if (section = "") {
        SeedDefaultBookmarkHotkeys()
        section := IniRead(CONFIG_FILE, "bookmarkHotkeys", , "")
    }

    result := []
    for line in StrSplit(section, "`n") {
        parts := StrSplit(line, "=")
        if (parts.Length < 2) {
            continue
        }
        pipeParts := StrSplit(parts[2], "|")
        hotkeyStr := pipeParts[1]
        enabled := pipeParts.Length >= 2 ? pipeParts[2] : "1"
        if (enabled = "1") {
            result.Push(hotkeyStr)
        }
    }
    return result
}

SeedDefaultBookmarkHotkeys() {
    global DEFAULT_BOOKMARK_HOTKEYS
    for index, key in DEFAULT_BOOKMARK_HOTKEYS {
        IniWrite(key . "|1", CONFIG_FILE, "bookmarkHotkeys", String(index))
    }
}

Notify(text, seconds := 2) {
    ToolTip(text)
    SetTimer(() => ToolTip(), -seconds * 1000)
}

LogError(context, err) {
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") . " | " . context . " | " . err.Message . " | line=" . err.Line . "`n", LOG_FILE, "UTF-8")
}
