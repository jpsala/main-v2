#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(WindowsTerminalWheelScrollProbeUnhandledError)

#Include ..\hotkeys-global.ahk

try {
    result := IsWindowsTerminalWheelScrollActive()
    if (Type(result) != "Integer")
        throw Error("IsWindowsTerminalWheelScrollActive must return a boolean-compatible Integer")
    if !IsWindowsTerminalWheelScrollProcess("WindowsTerminal.exe")
        throw Error("Windows Terminal must enable wheel navigation")
    if !IsWindowsTerminalWheelScrollProcess("wezterm-gui.exe")
        throw Error("WezTerm must enable wheel navigation")
    if IsWindowsTerminalWheelScrollProcess("explorer.exe")
        throw Error("Unrelated processes must not enable wheel navigation")

    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    WindowsTerminalWheelScrollProbeFail(e)
}

WindowsTerminalWheelScrollProbeUnhandledError(error, mode) {
    WindowsTerminalWheelScrollProbeFail(error)
    return true
}

WindowsTerminalWheelScrollProbeFail(error) {
    message := error.Message
    if (error.Stack != "")
        message .= "`n" . error.Stack
    FileAppend(message . "`n", "**")
    ExitApp(1)
}
