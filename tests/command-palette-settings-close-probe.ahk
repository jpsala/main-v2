#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(CommandPaletteSettingsCloseProbeUnhandledError)
#Include ..\lib\logging.ahk
#Include ..\command-palette.ahk

global COMMAND_PALETTE_SETTINGS_CLOSE_ESCAPE_FAILED := false
global COMMAND_PALETTE_SETTINGS_CLOSE_FOCUS_FAILED := false
global COMMAND_PALETTE_SETTINGS_CLOSE_OTHER_GUI := false

try {
    SetWorkingDir(A_ScriptDir . "\..")
    catalog := [Map(
        "id", "Probe:a",
        "kind", "action",
        "parentId", "",
        "depth", 1,
        "label", "Probe action",
        "source", "Probe",
        "breadcrumb", "",
        "shortcut", "Probe A",
        "detail", ""
    )]
    config := {
        source: "Probe",
        catalog: catalog,
        settings: { viewMode: "groups", chordMode: false },
        allowLevelCycle: true,
        recordUse: false
    }
    actions := Map("Probe:a", (*) => 0)

    SetTimer(CommandPaletteSettingsCloseProbeEscape, -250)
    SetTimer(CommandPaletteSettingsCloseProbeEscapeSafety, -1200)
    CommandPaletteOpenWith(config, actions)
    CommandPaletteSettingsCloseProbeAssert(
        !COMMAND_PALETTE_SETTINGS_CLOSE_ESCAPE_FAILED,
        "Escape consumed after Settings focus"
    )

    SetTimer(CommandPaletteSettingsCloseProbeFocus, -250)
    SetTimer(CommandPaletteSettingsCloseProbeFocusSafety, -1200)
    CommandPaletteOpenWith(config, actions)
    CommandPaletteSettingsCloseProbeAssert(
        !COMMAND_PALETTE_SETTINGS_CLOSE_FOCUS_FAILED,
        "focus loss after Settings"
    )
    CommandPaletteSettingsCloseProbeAssert(
        WinActive("ahk_id " . COMMAND_PALETTE_SETTINGS_CLOSE_OTHER_GUI.Hwnd),
        "focus loss keeps the clicked window active"
    )

    if IsObject(COMMAND_PALETTE_SETTINGS_CLOSE_OTHER_GUI)
        COMMAND_PALETTE_SETTINGS_CLOSE_OTHER_GUI.Destroy()
    global COMMAND_PALETTE_GUI
    if IsObject(COMMAND_PALETTE_GUI)
        COMMAND_PALETTE_GUI.Destroy()
    COMMAND_PALETTE_GUI := false
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    try FileAppend(e.Message . "`n" . e.Stack . "`n", "**")
    try COMMAND_PALETTE_SETTINGS_CLOSE_OTHER_GUI.Destroy()
    try COMMAND_PALETTE_GUI.Destroy()
    ExitApp(1)
}

CommandPaletteSettingsCloseProbeEscape() {
    global COMMAND_PALETTE_GUI
    COMMAND_PALETTE_GUI.Control.ExecuteScript("openCustom(); document.querySelector('#set-view').focus();")
    Sleep(50)
    Send("!{Down}")
    Sleep(50)
    Send("{Escape}")
}

CommandPaletteSettingsCloseProbeEscapeSafety() {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_RESULT, COMMAND_PALETTE_SETTINGS_CLOSE_ESCAPE_FAILED
    if COMMAND_PALETTE_ACTIVE && COMMAND_PALETTE_RESULT = "" {
        COMMAND_PALETTE_SETTINGS_CLOSE_ESCAPE_FAILED := true
        COMMAND_PALETTE_RESULT := "CANCELLED"
    }
}

CommandPaletteSettingsCloseProbeFocus() {
    global COMMAND_PALETTE_GUI, COMMAND_PALETTE_SETTINGS_CLOSE_OTHER_GUI
    COMMAND_PALETTE_GUI.Control.ExecuteScript("openCustom(); document.querySelector('#set-delay').focus();")
    COMMAND_PALETTE_SETTINGS_CLOSE_OTHER_GUI := Gui("+ToolWindow", "Settings Close Probe Other")
    COMMAND_PALETTE_SETTINGS_CLOSE_OTHER_GUI.Show("x-10000 y-10000 w120 h80")
    WinActivate("ahk_id " . COMMAND_PALETTE_SETTINGS_CLOSE_OTHER_GUI.Hwnd)
}

CommandPaletteSettingsCloseProbeFocusSafety() {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_RESULT, COMMAND_PALETTE_SETTINGS_CLOSE_FOCUS_FAILED
    if COMMAND_PALETTE_ACTIVE && COMMAND_PALETTE_RESULT = "" {
        COMMAND_PALETTE_SETTINGS_CLOSE_FOCUS_FAILED := true
        COMMAND_PALETTE_RESULT := "CANCELLED"
    }
}

CommandPaletteSettingsCloseProbeAssert(condition, label) {
    if !condition
        throw Error("FAIL: " . label)
}

CommandPaletteSettingsCloseProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    try COMMAND_PALETTE_SETTINGS_CLOSE_OTHER_GUI.Destroy()
    try COMMAND_PALETTE_GUI.Destroy()
    ExitApp(1)
    return true
}
