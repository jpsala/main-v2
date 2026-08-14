#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(CommandPaletteNativeGuardProbeUnhandledError)
#Include ..\lib\logging.ahk
#Include ..\command-palette.ahk

try {
    SetWorkingDir(A_ScriptDir . "\..")
    CommandPaletteEnsureGui()
    global COMMAND_PALETTE_GUI, COMMAND_PALETTE_ACTIVE
    COMMAND_PALETTE_GUI.Show("x-10000 y-10000 w320 h220")
    WinActivate("ahk_id " . COMMAND_PALETTE_GUI.Hwnd)
    COMMAND_PALETTE_ACTIVE := true
    CommandPaletteNativeGuardsInstall()
    CommandPaletteNativeGuardsRemove()
    COMMAND_PALETTE_ACTIVE := false
    COMMAND_PALETTE_GUI.Destroy()
    COMMAND_PALETTE_GUI := false
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    try FileAppend(e.Message . "`n" . e.Stack . "`n", "**")
    try CommandPaletteNativeGuardsRemove()
    try COMMAND_PALETTE_GUI.Destroy()
    ExitApp(1)
}

CommandPaletteNativeGuardProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    try CommandPaletteNativeGuardsRemove()
    try COMMAND_PALETTE_GUI.Destroy()
    ExitApp(1)
    return true
}
