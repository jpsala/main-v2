#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(CommandPaletteLoadProbeUnhandledError)
#Include ..\command-palette.ahk

CommandPaletteGetWorkArea(&left, &top, &right, &bottom)
if (right <= left || bottom <= top)
    throw Error("Invalid command palette work area")
CommandPaletteMouseClickHandler()

FileAppend("PASS`n", "*")
ExitApp(0)

CommandPaletteLoadProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    ExitApp(1)
    return true
}
