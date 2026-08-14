#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(CommandPaletteFocusProbeUnhandledError)
#Include ..\command-palette.ahk

try {
    SetWorkingDir(A_ScriptDir . "\..")
    CommandPaletteEnsureGui()
    global COMMAND_PALETTE_GUI
    COMMAND_PALETTE_GUI.Show("x-10000 y-10000 w320 h220")
    WinActivate("ahk_id " . COMMAND_PALETTE_GUI.Hwnd)
    Sleep(100)
    CommandPaletteFocusProbeAssert(CommandPaletteWindowIsActive(), "palette recognizes focused WebView root")

    otherGui := Gui("+ToolWindow", "Command Palette Focus Probe Other")
    otherGui.Show("x-10000 y-10000 w120 h80")
    WinActivate("ahk_id " . otherGui.Hwnd)
    Sleep(100)
    CommandPaletteFocusProbeAssert(!CommandPaletteWindowIsActive(), "palette detects focus loss")

    otherGui.Destroy()
    COMMAND_PALETTE_GUI.Destroy()
    COMMAND_PALETTE_GUI := false
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    try FileAppend(e.Message . "`n" . e.Stack . "`n", "**")
    try COMMAND_PALETTE_GUI.Destroy()
    ExitApp(1)
}

CommandPaletteFocusProbeAssert(condition, label) {
    if !condition
        throw Error("FAIL: " . label)
}

CommandPaletteFocusProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    try COMMAND_PALETTE_GUI.Destroy()
    ExitApp(1)
    return true
}
