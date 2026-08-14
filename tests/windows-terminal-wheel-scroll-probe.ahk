#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(WindowsTerminalWheelScrollProbeUnhandledError)

#Include ..\hotkeys-global.ahk

try {
    global terminalWheelPagingEnabled := true

    result := IsWindowsTerminalWheelScrollActive()
    if (Type(result) != "Integer")
        throw Error("IsWindowsTerminalWheelScrollActive must return a boolean-compatible Integer")
    if !IsWindowsTerminalWheelScrollProcess("WindowsTerminal.exe")
        throw Error("Windows Terminal must support wheel navigation")
    if !IsWindowsTerminalWheelScrollProcess("wezterm-gui.exe")
        throw Error("WezTerm must support wheel navigation")
    if IsWindowsTerminalWheelScrollProcess("explorer.exe")
        throw Error("Unrelated processes must not support wheel navigation")
    if !IsWindowsTerminalWheelScrollEnabledForProcess("WindowsTerminal.exe")
        throw Error("Enabled toggle must activate Windows Terminal wheel navigation")

    terminalWheelPagingEnabled := false
    if IsWindowsTerminalWheelScrollEnabledForProcess("WindowsTerminal.exe")
        throw Error("Disabled toggle must deactivate Windows Terminal wheel navigation")
    if !ToggleTerminalWheelPaging()
        throw Error("Toggle must enable terminal wheel navigation")
    if ToggleTerminalWheelPaging()
        throw Error("Toggle must disable terminal wheel navigation")

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
