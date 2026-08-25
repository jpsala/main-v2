#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, StdOut

OnError(OmpHotkeyProbeUnhandledError)

#HotIf WinActive("ahk_exe wezterm-gui.exe")
$^+m::Send("^!o")
#HotIf
FileAppend("PASS`n", "*")
ExitApp(0)

OmpHotkeyProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    ExitApp(1)
    return true
}
