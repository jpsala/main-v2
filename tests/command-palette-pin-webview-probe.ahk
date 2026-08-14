#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(CommandPalettePinWebViewProbeUnhandledError)
#Include ..\lib\logging.ahk
#Include ..\command-palette.ahk
#Include ..\lib\json.ahk

global COMMAND_PALETTE_PIN_WEBVIEW_STATE := ""
global COMMAND_PALETTE_PIN_CONFIG_STATE := ""
global COMMAND_PALETTE_PIN_WEBVIEW_FAILED := false

try {
    SetWorkingDir(A_ScriptDir . "\..")
    global COMMAND_PALETTE_CONFIG_PATH
    originalPath := COMMAND_PALETTE_CONFIG_PATH
    stateDir := A_Temp . "\main-command-palette-pin-webview-" . A_TickCount
    DirCreate(stateDir)
    COMMAND_PALETTE_CONFIG_PATH := stateDir . "\menu-config.json"
    FileCopy(originalPath, COMMAND_PALETTE_CONFIG_PATH)
    CommandPaletteConfigLoad()

    catalog := [Map(
        "id", "Reentrant:a",
        "kind", "action",
        "parentId", "",
        "depth", 1,
        "label", "Reentrant action",
        "source", "Reentrant",
        "breadcrumb", "",
        "shortcut", "Reentrant A",
        "detail", ""
    )]
    config := {
        source: "Reentrant",
        catalog: catalog,
        settings: { viewMode: "groups", chordMode: false },
        allowLevelCycle: true,
        recordUse: true
    }
    actions := Map("Reentrant:a", (*) => 0)
    global COMMAND_PALETTE_SESSION_SOURCE, COMMAND_PALETTE_SESSION_BASE_CATALOG
    global COMMAND_PALETTE_SESSION_CODE_DEFAULTS, COMMAND_PALETTE_SESSION_ALLOW_LEVEL_CYCLE
    COMMAND_PALETTE_SESSION_SOURCE := "Reentrant"
    COMMAND_PALETTE_SESSION_BASE_CATALOG := catalog
    COMMAND_PALETTE_SESSION_CODE_DEFAULTS := config.settings
    COMMAND_PALETTE_SESSION_ALLOW_LEVEL_CYCLE := true

    SetTimer(CommandPalettePinWebViewProbeClickPin, -50)
    SetTimer(CommandPalettePinWebViewProbeSafety, -1800)
    CommandPaletteOpenCore(config, actions)
    SetTimer(CommandPalettePinWebViewProbeSafety, 0)
    CommandPalettePinWebViewProbeAssert(!COMMAND_PALETTE_PIN_WEBVIEW_FAILED, "pin callback remains responsive")
    CommandPalettePinWebViewProbeAssert(COMMAND_PALETTE_PIN_CONFIG_STATE = "true", "pin reaches config: " . COMMAND_PALETTE_PIN_CONFIG_STATE)

    CommandPaletteConfigLoad()
    resolved := CommandPaletteConfigBuildCatalog("Reentrant", catalog)
    CommandPalettePinWebViewProbeAssert(resolved[1]["pinned"], "pin survives config reload")

    COMMAND_PALETTE_PIN_WEBVIEW_STATE := ""
    SetTimer(CommandPalettePinWebViewProbeReadAndClose, -50)
    SetTimer(CommandPalettePinWebViewProbeSafety, -1200)
    CommandPaletteOpenCore(config, actions)
    SetTimer(CommandPalettePinWebViewProbeSafety, 0)
    CommandPalettePinWebViewProbeAssert(!COMMAND_PALETTE_PIN_WEBVIEW_FAILED, "reopen after pin remains responsive")
    CommandPalettePinWebViewProbeAssert(COMMAND_PALETTE_PIN_WEBVIEW_STATE = "true", "reopened WebView contains pin: " . COMMAND_PALETTE_PIN_WEBVIEW_STATE)

    global COMMAND_PALETTE_GUI
    if IsObject(COMMAND_PALETTE_GUI)
        COMMAND_PALETTE_GUI.Destroy()
    COMMAND_PALETTE_GUI := false
    COMMAND_PALETTE_CONFIG_PATH := originalPath
    CommandPaletteConfigLoad()
    DirDelete(stateDir, true)
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    try FileAppend(e.Message . "`n" . e.Stack . "`n", "**")
    try COMMAND_PALETTE_GUI.Destroy()
    try COMMAND_PALETTE_CONFIG_PATH := originalPath
    try CommandPaletteConfigLoad()
    try DirDelete(stateDir, true)
    ExitApp(1)
}

CommandPalettePinWebViewProbeClickPin() {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_GUI, COMMAND_PALETTE_READY
    if !COMMAND_PALETTE_ACTIVE || !COMMAND_PALETTE_READY || !IsObject(COMMAND_PALETTE_GUI)
        || CommandPaletteConfigGetItem("Reentrant:a").Count = 0 {
        SetTimer(CommandPalettePinWebViewProbeClickPin, -50)
        return
    }
    payload := JsonDump(Map("action", "togglePin", "id", "Reentrant:a"))
    CommandPaletteHandleMessage(0, { WebMessageAsJson: payload })
    SetTimer(CommandPalettePinWebViewProbeReadAndClose, -300)
}

CommandPalettePinWebViewProbeReadAndClose() {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_GUI, COMMAND_PALETTE_READY
    global COMMAND_PALETTE_PIN_CONFIG_STATE, COMMAND_PALETTE_PIN_WEBVIEW_STATE
    if !COMMAND_PALETTE_ACTIVE || !COMMAND_PALETTE_READY || !IsObject(COMMAND_PALETTE_GUI) {
        SetTimer(CommandPalettePinWebViewProbeReadAndClose, -50)
        return
    }
    item := CommandPaletteConfigGetItem("Reentrant:a")
    COMMAND_PALETTE_PIN_CONFIG_STATE := item.Count > 0 && item["pinned"] ? "true" : "false"
    COMMAND_PALETTE_PIN_WEBVIEW_STATE := COMMAND_PALETTE_GUI.Control.ExecuteScript("Boolean(catalog.find(command=>command.id==='Reentrant:a')?.pinned)")
    Send("{Escape}")
}

CommandPalettePinWebViewProbeSafety() {
    try SetTimer(CommandPalettePinWebViewProbeClickPin, 0)
    try SetTimer(CommandPalettePinWebViewProbeReadAndClose, 0)
    try SetTimer(CommandPalettePinWebViewProbeSafety, 0)
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_RESULT, COMMAND_PALETTE_PIN_WEBVIEW_FAILED
    if COMMAND_PALETTE_ACTIVE && COMMAND_PALETTE_RESULT = "" {
        COMMAND_PALETTE_PIN_WEBVIEW_FAILED := true
        COMMAND_PALETTE_RESULT := "CANCELLED"
    }
}

CommandPalettePinWebViewProbeAssert(condition, label) {
    if !condition
        throw Error("FAIL: " . label)
}

CommandPalettePinWebViewProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    try COMMAND_PALETTE_GUI.Destroy()
    ExitApp(1)
    return true
}
