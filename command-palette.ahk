; PowerToys-inspired global command palette for the main menu trees.

#Include ".\lib\WebViewToo.ahk"
#Include ".\command-palette-catalog.ahk"
#Include ".\command-palette-frecency.ahk"

global COMMAND_PALETTE_GUI := false
global COMMAND_PALETTE_READY := false
global COMMAND_PALETTE_ACTIVE := false
global COMMAND_PALETTE_RESULT := ""
global COMMAND_PALETTE_PREV_WIN := 0
global COMMAND_PALETTE_LEVELS_PER_PAGE := 0
global COMMAND_PALETTE_GROUPS_FIRST := false

CommandPaletteInit(levelsPerPage := 0, groupsFirst := false) {
    global COMMAND_PALETTE_GROUPS_FIRST, COMMAND_PALETTE_LEVELS_PER_PAGE

    COMMAND_PALETTE_LEVELS_PER_PAGE := Max(0, levelsPerPage)
    COMMAND_PALETTE_GROUPS_FIRST := groupsFirst
    CommandPaletteBuildCatalog()
    CommandPaletteFrecencyInit()
    Hotkey("$#a", CommandPaletteOpen)
    SetTimer(CommandPalettePrewarm, -700)
}

CommandPalettePrewarm(*) {
    try CommandPaletteEnsureGui()
    catch Error as e
        log("Command palette prewarm error: " . e.Message)
}

CommandPaletteEnsureGui() {
    global COMMAND_PALETTE_GUI, COMMAND_PALETTE_READY

    if IsObject(COMMAND_PALETTE_GUI)
        return

    COMMAND_PALETTE_READY := false
    dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
    COMMAND_PALETTE_GUI := WebViewGui("+AlwaysOnTop -Caption +ToolWindow -DPIScale", "Command Palette",, {DllPath: dllPath, DefaultWidth: 800, DefaultHeight: 480})
    COMMAND_PALETTE_GUI.OnEvent("Close", (*) => CommandPaletteClose())
    if A_IsCompiled
        COMMAND_PALETTE_GUI.Control.BrowseFolder(A_ScriptDir)
    COMMAND_PALETTE_GUI.Control.DefaultBackgroundColor := "1E1E1E"
    COMMAND_PALETTE_GUI.Control.wv.add_NavigationCompleted(CommandPaletteNavigationCompleted)
    COMMAND_PALETTE_GUI.Control.wv.add_WebMessageReceived(CommandPaletteHandleMessage)
    COMMAND_PALETTE_GUI.Navigate("ui/command-palette.html")
}

CommandPaletteNavigationCompleted(wv, args) {
    global COMMAND_PALETTE_READY
    COMMAND_PALETTE_READY := true
}

CommandPaletteOpen(*) {
    try CommandPaletteOpenCore()
    catch Error as e {
        log("Command palette open error: " . e.Message . " | " . e.What . " | " . e.File . ":" . e.Line . " | " . e.Stack)
        CommandPaletteClose()
    }
}

CommandPaletteOpenCore() {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_ACTIONS, COMMAND_PALETTE_CATALOG, COMMAND_PALETTE_GROUPS_FIRST, COMMAND_PALETTE_GUI, COMMAND_PALETTE_LEVELS_PER_PAGE, COMMAND_PALETTE_PREV_WIN, COMMAND_PALETTE_RESULT

    if COMMAND_PALETTE_ACTIVE {
        COMMAND_PALETTE_GUI.Control.ExecuteScript("window.focusPalette && window.focusPalette();")
        return
    }

    CommandPaletteBuildCatalog()
    CommandPaletteEnsureGui()
    if !CommandPaletteWaitUntilReady()
        throw Error("WebView did not become ready")

    COMMAND_PALETTE_RESULT := ""
    COMMAND_PALETTE_PREV_WIN := WinExist("A")
    CommandPaletteGetWorkArea(&left, &top, &right, &bottom)
    width := Min(800, right - left - 24)
    height := Min(480, bottom - top - 48)
    x := left + (right - left - width) // 2
    y := top + (bottom - top - height) // 2

    COMMAND_PALETTE_ACTIVE := true
    COMMAND_PALETTE_GUI.Show("x" . x . " y" . y . " w" . width . " h" . height)
    WinActivate("ahk_id " . COMMAND_PALETTE_GUI.Hwnd)
    COMMAND_PALETTE_GUI.Control.MoveFocus(0)
    stateJson := JsonDump(Map("catalog", COMMAND_PALETTE_CATALOG, "frecency", CommandPaletteFrecencyGetSnapshot(), "levelsPerPage", COMMAND_PALETTE_LEVELS_PER_PAGE, "groupsFirst", COMMAND_PALETTE_GROUPS_FIRST))
    COMMAND_PALETTE_GUI.Control.ExecuteScript("window.setPaletteState(" . stateJson . ");")
    CommandPaletteMouseHookInstall()

    while (COMMAND_PALETTE_ACTIVE && COMMAND_PALETTE_RESULT = "")
        Sleep(25)

    result := COMMAND_PALETTE_RESULT
    CommandPaletteClose()
    if (result != "" && COMMAND_PALETTE_ACTIONS.Has(result)) {
        CommandPaletteFrecencyRecordUse(result)
        SetTimer(COMMAND_PALETTE_ACTIONS[result], -1)
    }
}

CommandPaletteGetWorkArea(&left, &top, &right, &bottom) {
    previousMouseCoordMode := CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    CoordMode("Mouse", previousMouseCoordMode)

    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &monitorLeft, &monitorTop, &monitorRight, &monitorBottom)
        if (mouseX >= monitorLeft && mouseX < monitorRight && mouseY >= monitorTop && mouseY < monitorBottom) {
            left := monitorLeft
            top := monitorTop
            right := monitorRight
            bottom := monitorBottom
            return
        }
    }
    MonitorGetWorkArea(MonitorGetPrimary(), &left, &top, &right, &bottom)
}

CommandPaletteWaitUntilReady(timeoutMs := 1200) {
    global COMMAND_PALETTE_READY

    start := A_TickCount
    while (!COMMAND_PALETTE_READY && (A_TickCount - start) < timeoutMs)
        Sleep(15)
    return COMMAND_PALETTE_READY
}

CommandPaletteHandleMessage(wv, args) {
    global COMMAND_PALETTE_RESULT

    try {
        message := args.WebMessageAsJson
        payload := JsonLoad(&message)
        if !payload.Has("action")
            return
        if (payload["action"] = "execute" && payload.Has("id"))
            COMMAND_PALETTE_RESULT := payload["id"]
        else if (payload["action"] = "cancel")
            COMMAND_PALETTE_RESULT := "CANCELLED"
    } catch Error as e {
        log("Command palette message error: " . e.Message)
        COMMAND_PALETTE_RESULT := "CANCELLED"
    }
}

CommandPaletteClose() {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_GUI, COMMAND_PALETTE_PREV_WIN

    COMMAND_PALETTE_ACTIVE := false
    CommandPaletteMouseHookRemove()
    if IsObject(COMMAND_PALETTE_GUI)
        try COMMAND_PALETTE_GUI.Hide()
    if (COMMAND_PALETTE_PREV_WIN != 0) {
        try WinActivate("ahk_id " . COMMAND_PALETTE_PREV_WIN)
        COMMAND_PALETTE_PREV_WIN := 0
    }
}

CommandPaletteMouseHookInstall() {
    Hotkey("~LButton", CommandPaletteMouseClickHandler, "On")
}

CommandPaletteMouseHookRemove() {
    try Hotkey("~LButton", CommandPaletteMouseClickHandler, "Off")
}

CommandPaletteMouseClickHandler(*) {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_GUI, COMMAND_PALETTE_RESULT

    try {
        if !COMMAND_PALETTE_ACTIVE || !IsObject(COMMAND_PALETTE_GUI)
            return

        previousMouseCoordMode := CoordMode("Mouse", "Screen")
        MouseGetPos(&mouseX, &mouseY)
        CoordMode("Mouse", previousMouseCoordMode)
        WinGetPos(&x, &y, &width, &height, "ahk_id " . COMMAND_PALETTE_GUI.Hwnd)
        if (mouseX < x || mouseX > x + width || mouseY < y || mouseY > y + height)
            COMMAND_PALETTE_RESULT := "CANCELLED"
    } catch Error as e {
        log("Command palette mouse handler error: " . e.Message)
        COMMAND_PALETTE_RESULT := "CANCELLED"
    }
}
