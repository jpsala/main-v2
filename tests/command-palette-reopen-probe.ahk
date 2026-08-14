#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(CommandPaletteReopenProbeUnhandledError)
#Include ..\lib\logging.ahk
#Include ..\command-palette.ahk

global COMMAND_PALETTE_REOPEN_STAGE := ""
global COMMAND_PALETTE_REOPEN_FAILED := false

try {
    SetWorkingDir(A_ScriptDir . "\..")
    catalog := [Map(
        "id", "Reopen:a",
        "kind", "action",
        "parentId", "",
        "depth", 1,
        "label", "Reopen action",
        "source", "Reopen",
        "breadcrumb", "",
        "shortcut", "Reopen A",
        "detail", ""
    )]
    config := {
        source: "Reopen",
        catalog: catalog,
        settings: { viewMode: "groups", chordMode: false },
        allowLevelCycle: true,
        recordUse: false
    }
    actions := Map("Reopen:a", (*) => 0)

    COMMAND_PALETTE_REOPEN_STAGE := "alt-f4"
    SetTimer(CommandPaletteReopenProbeAltF4, -250)
    SetTimer(CommandPaletteReopenProbeSafety, -1200)
    CommandPaletteOpenWith(config, actions)
    CommandPaletteReopenProbeAssert(!COMMAND_PALETTE_REOPEN_FAILED, "Alt+F4 closes first session")

    COMMAND_PALETTE_REOPEN_STAGE := "escape"
    SetTimer(CommandPaletteReopenProbeEscape, -250)
    SetTimer(CommandPaletteReopenProbeSafety, -1200)
    CommandPaletteOpenWith(config, actions)
    CommandPaletteReopenProbeAssert(!COMMAND_PALETTE_REOPEN_FAILED, "Escape closes reopened session")

    COMMAND_PALETTE_REOPEN_STAGE := "focus"
    SetTimer(CommandPaletteReopenProbeFocus, -250)
    SetTimer(CommandPaletteReopenProbeSafety, -1200)
    CommandPaletteOpenWith(config, actions)
    CommandPaletteReopenProbeAssert(!COMMAND_PALETTE_REOPEN_FAILED, "focus loss closes second reopened session")

    global COMMAND_PALETTE_GUI
    if IsObject(COMMAND_PALETTE_GUI)
        COMMAND_PALETTE_GUI.Destroy()
    COMMAND_PALETTE_GUI := false
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    try FileAppend(e.Message . "`n" . e.Stack . "`n", "**")
    try COMMAND_PALETTE_GUI.Destroy()
    ExitApp(1)
}

CommandPaletteReopenProbeAltF4() {
    Send("!{F4}")
}

CommandPaletteReopenProbeEscape() {
    Send("{Escape}")
}

CommandPaletteReopenProbeFocus() {
    otherGui := Gui("+ToolWindow", "Reopen Probe Other")
    otherGui.Show("x-10000 y-10000 w120 h80")
    WinActivate("ahk_id " . otherGui.Hwnd)
    SetTimer((*) => otherGui.Destroy(), -250)
}

CommandPaletteReopenProbeSafety() {
    global COMMAND_PALETTE_ACTIVE, COMMAND_PALETTE_RESULT
    global COMMAND_PALETTE_REOPEN_FAILED, COMMAND_PALETTE_REOPEN_STAGE
    if COMMAND_PALETTE_ACTIVE && COMMAND_PALETTE_RESULT = "" {
        COMMAND_PALETTE_REOPEN_FAILED := true
        FileAppend("TIMEOUT " . COMMAND_PALETTE_REOPEN_STAGE . "`n", "**")
        COMMAND_PALETTE_RESULT := "CANCELLED"
    }
}

CommandPaletteReopenProbeAssert(condition, label) {
    if !condition
        throw Error("FAIL: " . label)
}

CommandPaletteReopenProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    try COMMAND_PALETTE_GUI.Destroy()
    ExitApp(1)
    return true
}
