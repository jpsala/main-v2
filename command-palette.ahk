; PowerToys-inspired global command palette for the main menu trees.

#Include ".\lib\WebViewToo.ahk"
#Include ".\command-palette-catalog.ahk"
#Include ".\command-palette-config.ahk"
#Include ".\command-palette-frecency.ahk"

global COMMAND_PALETTE_GUI := false
global COMMAND_PALETTE_READY := false
global COMMAND_PALETTE_ACTIVE := false
global COMMAND_PALETTE_RESULT := ""
global COMMAND_PALETTE_PREV_WIN := 0
global COMMAND_PALETTE_LEVELS_PER_PAGE := 0
global COMMAND_PALETTE_GROUPS_FIRST := false
global COMMAND_PALETTE_SESSION_SOURCE := "Global"
global COMMAND_PALETTE_SESSION_BASE_CATALOG := []
global COMMAND_PALETTE_SESSION_CODE_DEFAULTS := {}
global COMMAND_PALETTE_SESSION_ALLOW_LEVEL_CYCLE := true
global COMMAND_PALETTE_ALLOW_LEVEL_CYCLE := true
global COMMAND_PALETTE_NATIVE_GUARD_HWND := 0
global COMMAND_PALETTE_RESTORE_PREV_WIN := true
global COMMAND_PALETTE_STATE_REFRESH_PENDING := false
global COMMAND_PALETTE_STATE_REFRESH_QUERY := ""
global COMMAND_PALETTE_STATE_REFRESH_RELOAD := false

CommandPaletteInit(levelsPerPage := 0, groupsFirst := false) {
    global COMMAND_PALETTE_GROUPS_FIRST, COMMAND_PALETTE_LEVELS_PER_PAGE

    COMMAND_PALETTE_LEVELS_PER_PAGE := Min(2, Max(0, Integer(levelsPerPage)))
    COMMAND_PALETTE_GROUPS_FIRST := groupsFirst
    CommandPaletteBuildCatalog()
    CommandPaletteConfigInit()
    CommandPaletteFrecencyInit()
    Hotkey("$#e", CommandPaletteOpen)
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
    CommandPaletteOpenSession()
}

CommandPaletteOpenWith(config, actions) {
    return CommandPaletteOpenSession(config, actions)
}

CommandPaletteOpenSession(config?, actions?) {
    try {
        return IsSet(config)
            ? CommandPaletteOpenCore(config, actions)
            : CommandPaletteOpenCore()
    } catch Error as e {
        log("Command palette open error: " . e.Message . " | " . e.What . " | " . e.File . ":" . e.Line . " | " . e.Stack)
        CommandPaletteClose()
        return false
    }
}

CommandPaletteOpenCore(config?, actions?) {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_ACTIONS, COMMAND_PALETTE_ALLOW_LEVEL_CYCLE
    global COMMAND_PALETTE_CATALOG, COMMAND_PALETTE_GROUPS_FIRST, COMMAND_PALETTE_GUI
    global COMMAND_PALETTE_LEVELS_PER_PAGE, COMMAND_PALETTE_PREV_WIN, COMMAND_PALETTE_RESULT
    global COMMAND_PALETTE_SESSION_ALLOW_LEVEL_CYCLE, COMMAND_PALETTE_SESSION_BASE_CATALOG
    global COMMAND_PALETTE_SESSION_CODE_DEFAULTS, COMMAND_PALETTE_SESSION_SOURCE

    if COMMAND_PALETTE_ACTIVE {
        COMMAND_PALETTE_GUI.Control.ExecuteScript("window.focusPalette && window.focusPalette();")
        return false
    }

    isDefaultSession := !IsSet(config)
    if isDefaultSession {
        CommandPaletteBuildCatalog()
        sessionBaseCatalog := COMMAND_PALETTE_CATALOG
        sessionActions := COMMAND_PALETTE_ACTIONS
        sessionSource := "Global"
        sessionCodeDefaults := {
            viewMode: CommandPaletteConfigLevelToViewMode(COMMAND_PALETTE_LEVELS_PER_PAGE),
            groupsFirst: COMMAND_PALETTE_GROUPS_FIRST,
            chordMode: false
        }
        sessionAllowLevelCycle := true
        sessionRecordUse := true
        initialQuery := ""
    } else {
        if !IsObject(config) || !config.HasOwnProp("catalog") || !(config.catalog is Array) || !(actions is Map)
            throw Error("Custom command palette requires config.catalog and a Map of actions")
        sessionBaseCatalog := config.catalog
        sessionActions := actions
        sessionSource := config.HasOwnProp("source")
            ? config.source
            : CommandPaletteCatalogSource(config.catalog)
        sessionCodeDefaults := {
            viewMode: "flat",
            groupsFirst: false,
            chordMode: false
        }
        if config.HasOwnProp("settings") && IsObject(config.settings)
            for field, value in config.settings.OwnProps()
                sessionCodeDefaults.%field% := value
        sessionAllowLevelCycle := config.HasOwnProp("allowLevelCycle")
            ? config.allowLevelCycle
            : false
        sessionRecordUse := config.HasOwnProp("recordUse")
            ? config.recordUse
            : false
        initialQuery := config.HasOwnProp("initialQuery")
            ? config.initialQuery
            : ""
    }
    CommandPaletteConfigLoad()
    sessionActions := CommandPaletteConfigResolveActions(sessionSource, sessionActions)


    CommandPaletteEnsureGui()
    if !CommandPaletteWaitUntilReady()
        throw Error("WebView did not become ready")

    COMMAND_PALETTE_SESSION_BASE_CATALOG := sessionBaseCatalog
    COMMAND_PALETTE_SESSION_SOURCE := sessionSource
    COMMAND_PALETTE_SESSION_CODE_DEFAULTS := sessionCodeDefaults
    COMMAND_PALETTE_SESSION_ALLOW_LEVEL_CYCLE := sessionAllowLevelCycle
    COMMAND_PALETTE_RESULT := ""
    COMMAND_PALETTE_PREV_WIN := WinExist("A")
    COMMAND_PALETTE_RESTORE_PREV_WIN := true
    COMMAND_PALETTE_ALLOW_LEVEL_CYCLE := sessionAllowLevelCycle
    CommandPaletteGetWorkArea(&left, &top, &right, &bottom)
    width := Min(800, right - left - 24)
    height := Min(560, bottom - top - 48)
    x := left + (right - left - width) // 2
    y := top + (bottom - top - height) // 2

    COMMAND_PALETTE_ACTIVE := true
    COMMAND_PALETTE_GUI.Show("x" . x . " y" . y . " w" . width . " h" . height)
    WinActivate("ahk_id " . COMMAND_PALETTE_GUI.Hwnd)
    COMMAND_PALETTE_GUI.Control.MoveFocus(0)
    CommandPaletteSendSessionState(initialQuery)
    CommandPaletteMouseHookInstall()
    CommandPaletteNativeGuardsInstall()

    focusGuardAt := A_TickCount + 250
    while (COMMAND_PALETTE_ACTIVE && COMMAND_PALETTE_RESULT = "") {
        if (A_TickCount >= focusGuardAt && !CommandPaletteWindowIsActive())
            CommandPaletteCancelFromNativeGuard(false)
        Sleep(25)
    }
    result := COMMAND_PALETTE_RESULT
    CommandPaletteClose()
    if (result != "" && sessionActions.Has(result)) {
        if sessionRecordUse
            CommandPaletteFrecencyRecordUse(result)
        SetTimer(sessionActions[result], -1)
        return true
    }
    return false
}

CommandPaletteCatalogSource(catalog) {
    return catalog.Length > 0 && catalog[1].Has("source")
        ? catalog[1]["source"]
        : "Custom"
}

CommandPaletteBuildSessionState(initialQuery := "", reloadConfig := true) {
    global COMMAND_PALETTE_SESSION_ALLOW_LEVEL_CYCLE, COMMAND_PALETTE_SESSION_BASE_CATALOG
    global COMMAND_PALETTE_SESSION_CODE_DEFAULTS, COMMAND_PALETTE_SESSION_SOURCE
    global COMMAND_PALETTE_CONFIG_LAST_ERROR

    if reloadConfig
        CommandPaletteConfigLoad()
    menuPreferences := CommandPaletteConfigGetMenu(
        COMMAND_PALETTE_SESSION_SOURCE,
        COMMAND_PALETTE_SESSION_CODE_DEFAULTS
    )
    catalog := CommandPaletteConfigBuildCatalog(
        COMMAND_PALETTE_SESSION_SOURCE,
        COMMAND_PALETTE_SESSION_BASE_CATALOG
    )
    customizationCatalog := CommandPaletteConfigBuildEditorCatalog(
        COMMAND_PALETTE_SESSION_SOURCE,
        COMMAND_PALETTE_SESSION_BASE_CATALOG
    )
    frecency := CommandPaletteFrecencyGetSnapshot()
    levelsPerPage := CommandPaletteConfigViewModeToLevel(menuPreferences["viewMode"])
    return Map(
        "catalog", catalog,
        "customizationCatalog", customizationCatalog,
        "frecency", frecency,
        "levelsPerPage", levelsPerPage,
        "viewMode", menuPreferences["viewMode"],
        "groupsFirst", menuPreferences["groupsFirst"],
        "allowLevelCycle", COMMAND_PALETTE_SESSION_ALLOW_LEVEL_CYCLE,
        "maxPinned", menuPreferences["maxPinned"],
        "maxSuggested", menuPreferences["maxSuggested"],
        "source", COMMAND_PALETTE_SESSION_SOURCE,
        "menuPreferences", menuPreferences,
        "configError", COMMAND_PALETTE_CONFIG_LAST_ERROR,
        "initialQuery", initialQuery
    )
}

CommandPaletteSendSessionState(initialQuery := "", reloadConfig := true) {
    global COMMAND_PALETTE_GUI

    stateJson := JsonDump(CommandPaletteBuildSessionState(initialQuery, reloadConfig))
    COMMAND_PALETTE_GUI.Control.ExecuteScript("window.setPaletteState(" . stateJson . ");")
}
CommandPaletteQueueSessionState(initialQuery := "", reloadConfig := true) {
    global COMMAND_PALETTE_STATE_REFRESH_PENDING, COMMAND_PALETTE_STATE_REFRESH_QUERY
    global COMMAND_PALETTE_STATE_REFRESH_RELOAD

    COMMAND_PALETTE_STATE_REFRESH_QUERY := initialQuery
    COMMAND_PALETTE_STATE_REFRESH_RELOAD := COMMAND_PALETTE_STATE_REFRESH_RELOAD || reloadConfig
    if COMMAND_PALETTE_STATE_REFRESH_PENDING
        return
    COMMAND_PALETTE_STATE_REFRESH_PENDING := true
    SetTimer(CommandPaletteFlushSessionState, -1)
}

CommandPaletteFlushSessionState(*) {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_STATE_REFRESH_PENDING
    global COMMAND_PALETTE_STATE_REFRESH_QUERY, COMMAND_PALETTE_STATE_REFRESH_RELOAD

    query := COMMAND_PALETTE_STATE_REFRESH_QUERY
    reloadConfig := COMMAND_PALETTE_STATE_REFRESH_RELOAD
    COMMAND_PALETTE_STATE_REFRESH_PENDING := false
    COMMAND_PALETTE_STATE_REFRESH_QUERY := ""
    COMMAND_PALETTE_STATE_REFRESH_RELOAD := false
    if COMMAND_PALETTE_ACTIVE
        CommandPaletteSendSessionState(query, reloadConfig)
}
CommandPaletteCancelQueuedSessionState() {
    global COMMAND_PALETTE_STATE_REFRESH_PENDING, COMMAND_PALETTE_STATE_REFRESH_QUERY
    global COMMAND_PALETTE_STATE_REFRESH_RELOAD

    try SetTimer(CommandPaletteFlushSessionState, 0)
    COMMAND_PALETTE_STATE_REFRESH_PENDING := false
    COMMAND_PALETTE_STATE_REFRESH_QUERY := ""
    COMMAND_PALETTE_STATE_REFRESH_RELOAD := false
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
    global COMMAND_PALETTE_ALLOW_LEVEL_CYCLE, COMMAND_PALETTE_RESULT, COMMAND_PALETTE_SESSION_SOURCE

    try {
        message := args.WebMessageAsJson
        payload := JsonLoad(&message)
        if !payload.Has("action")
            return
        action := payload["action"]
        if (action = "execute" && payload.Has("id")) {
            COMMAND_PALETTE_RESULT := payload["id"]
        } else if (action = "setLevel"
            && payload.Has("level")
            && COMMAND_PALETTE_ALLOW_LEVEL_CYCLE) {
            viewMode := CommandPaletteConfigLevelToViewMode(payload["level"])
            CommandPaletteConfigSetMenu(COMMAND_PALETTE_SESSION_SOURCE, "viewMode", viewMode)
            CommandPaletteQueueSessionState("", false)
        } else if (action = "togglePin"
            && payload.Has("id")
            && CommandPaletteSessionHasId(payload["id"])) {
            CommandPaletteConfigTogglePin(payload["id"])
            CommandPaletteQueueSessionState("", false)
        } else if (action = "movePin"
            && payload.Has("id")
            && payload.Has("direction")
            && CommandPaletteSessionHasId(payload["id"])) {
            direction := payload["direction"] < 0 ? -1 : 1
            CommandPaletteConfigMovePin(payload["id"], direction)
            CommandPaletteQueueSessionState("", false)
        } else if (action = "resetRanking"
            && payload.Has("id")
            && CommandPaletteSessionHasId(payload["id"])) {
            CommandPaletteFrecencyReset(payload["id"])
            CommandPaletteQueueSessionState()
        } else if (action = "setItemPreference"
            && payload.Has("id")
            && payload.Has("field")
            && payload.Has("value")
            && CommandPaletteSessionHasId(payload["id"])) {
            CommandPaletteConfigSetItem(payload["id"], payload["field"], payload["value"])
            CommandPaletteQueueSessionState("", false)
        } else if (action = "deleteItem"
            && payload.Has("id")
            && CommandPaletteSessionHasId(payload["id"])) {
            CommandPaletteConfigDeleteItem(payload["id"])
            CommandPaletteQueueSessionState("", false)
        } else if (action = "setMenuPreference"
            && payload.Has("field")
            && payload.Has("value")) {
            CommandPaletteConfigSetMenu(COMMAND_PALETTE_SESSION_SOURCE, payload["field"], payload["value"])
            CommandPaletteQueueSessionState("", false)
        } else if (action = "reloadPreferences") {
            CommandPaletteConfigLoad()
            CommandPaletteQueueSessionState()
        } else if (action = "cancel") {
            COMMAND_PALETTE_RESULT := "CANCELLED"
        }
    } catch Error as e {
        log("Command palette message error: " . e.Message)
        COMMAND_PALETTE_RESULT := "CANCELLED"
    }
}

CommandPaletteSessionHasId(id) {
    global COMMAND_PALETTE_SESSION_BASE_CATALOG

    for _, command in COMMAND_PALETTE_SESSION_BASE_CATALOG
        if command["id"] = id
            return true
    return false
}

CommandPaletteNativeGuardsInstall() {
    global COMMAND_PALETTE_GUI, COMMAND_PALETTE_NATIVE_GUARD_HWND

    if !IsObject(COMMAND_PALETTE_GUI)
        return
    COMMAND_PALETTE_NATIVE_GUARD_HWND := COMMAND_PALETTE_GUI.Hwnd
    OnMessage(0x0006, CommandPaletteWindowActivateHandler)
    OnMessage(0x001C, CommandPaletteApplicationActivateHandler)
    HotIf(CommandPaletteEscapeHotIf)
    try Hotkey("$Escape", CommandPaletteEscapeHotkey, "On")
    finally HotIf()
}

CommandPaletteNativeGuardsRemove() {
    global COMMAND_PALETTE_NATIVE_GUARD_HWND

    OnMessage(0x0006, CommandPaletteWindowActivateHandler, 0)
    OnMessage(0x001C, CommandPaletteApplicationActivateHandler, 0)
    HotIf(CommandPaletteEscapeHotIf)
    try Hotkey("$Escape", "Off")
    catch Error {
    }
    finally HotIf()
    COMMAND_PALETTE_NATIVE_GUARD_HWND := 0
}

CommandPaletteEscapeHotIf(*) {
    global COMMAND_PALETTE_ACTIVE
    return COMMAND_PALETTE_ACTIVE
}

CommandPaletteEscapeHotkey(*) {
    CommandPaletteCancelFromNativeGuard(true)
}

CommandPaletteWindowActivateHandler(wParam, lParam, msg, hwnd) {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_NATIVE_GUARD_HWND

    if (COMMAND_PALETTE_ACTIVE
        && hwnd = COMMAND_PALETTE_NATIVE_GUARD_HWND
        && (wParam & 0xFFFF) = 0)
        SetTimer(CommandPaletteCheckFocusAfterDeactivate, -50)
}

CommandPaletteApplicationActivateHandler(wParam, lParam, msg, hwnd) {
    global COMMAND_PALETTE_ACTIVE
    if COMMAND_PALETTE_ACTIVE && !wParam
        SetTimer(CommandPaletteCheckFocusAfterDeactivate, -50)
}

CommandPaletteCheckFocusAfterDeactivate(*) {
    global COMMAND_PALETTE_ACTIVE
    if COMMAND_PALETTE_ACTIVE && !CommandPaletteWindowIsActive()
        CommandPaletteCancelFromNativeGuard(false)
}

CommandPaletteCancelFromNativeGuard(restorePrevious := true) {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_RESULT, COMMAND_PALETTE_RESTORE_PREV_WIN

    if COMMAND_PALETTE_ACTIVE && COMMAND_PALETTE_RESULT = "" {
        COMMAND_PALETTE_RESTORE_PREV_WIN := restorePrevious
        COMMAND_PALETTE_RESULT := "CANCELLED"
    }
}

CommandPaletteWindowIsActive() {
    global COMMAND_PALETTE_GUI

    if !IsObject(COMMAND_PALETTE_GUI)
        return false
    activeHwnd := WinExist("A")
    if !activeHwnd
        return false
    paletteHwnd := COMMAND_PALETTE_GUI.Hwnd
    if activeHwnd = paletteHwnd || DllCall("user32\IsChild", "Ptr", paletteHwnd, "Ptr", activeHwnd)
        return true
    candidate := activeHwnd
    Loop 8 {
        rootHwnd := DllCall("user32\GetAncestor", "Ptr", candidate, "UInt", 2, "Ptr")
        if rootHwnd = paletteHwnd
            return true
        ownerHwnd := DllCall("user32\GetWindow", "Ptr", rootHwnd, "UInt", 4, "Ptr")
        if !ownerHwnd || ownerHwnd = candidate
            break
        candidate := ownerHwnd
    }
    return false
}

CommandPaletteClose() {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_GUI, COMMAND_PALETTE_PREV_WIN
    global COMMAND_PALETTE_RESTORE_PREV_WIN

    COMMAND_PALETTE_ACTIVE := false
    CommandPaletteNativeGuardsRemove()
    CommandPaletteMouseHookRemove()
    CommandPaletteCancelQueuedSessionState()
    if IsObject(COMMAND_PALETTE_GUI)
        try COMMAND_PALETTE_GUI.Hide()
    if COMMAND_PALETTE_RESTORE_PREV_WIN && COMMAND_PALETTE_PREV_WIN != 0
        try WinActivate("ahk_id " . COMMAND_PALETTE_PREV_WIN)
    COMMAND_PALETTE_PREV_WIN := 0
    COMMAND_PALETTE_RESTORE_PREV_WIN := true
}

CommandPaletteMouseHookInstall() {
    Hotkey("~LButton", CommandPaletteMouseClickHandler, "On")
}

CommandPaletteMouseHookRemove() {
    try Hotkey("~LButton", CommandPaletteMouseClickHandler, "Off")
}

CommandPaletteMouseClickHandler(*) {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_GUI

    try {
        if !COMMAND_PALETTE_ACTIVE || !IsObject(COMMAND_PALETTE_GUI)
            return

        previousMouseCoordMode := CoordMode("Mouse", "Screen")
        MouseGetPos(&mouseX, &mouseY)
        CoordMode("Mouse", previousMouseCoordMode)
        WinGetPos(&x, &y, &width, &height, "ahk_id " . COMMAND_PALETTE_GUI.Hwnd)
        if (mouseX < x || mouseX > x + width || mouseY < y || mouseY > y + height)
            CommandPaletteCancelFromNativeGuard(false)
    } catch Error as e {
        log("Command palette mouse handler error: " . e.Message)
        CommandPaletteCancelFromNativeGuard(false)
    }
}
