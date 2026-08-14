#Requires AutoHotkey v2.0

if (A_LineFile = A_ScriptFullPath)
    ExitApp(WezTermCommandPaletteRequestOpen())

WezTermCommandPaletteOpenMessageId() {
    static messageId := DllCall(
        "user32\RegisterWindowMessageW",
        "Str", "main-v2.wezterm-command-palette.open.v1",
        "UInt"
    )
    return messageId
}

WezTermCommandPaletteRequestOpen() {
    sourceHwnd := WinExist("A")
    if !sourceHwnd
        return 2

    try {
        sourceWindow := "ahk_id " . sourceHwnd
        if (StrLower(WinGetProcessName(sourceWindow)) != "wezterm-gui.exe")
            return 2
        sourcePid := WinGetPID(sourceWindow)
        if (WinExist("A") != sourceHwnd)
            return 2
    } catch {
        return 2
    }

    posted := DllCall(
        "user32\PostMessageW",
        "Ptr", 0xFFFF,
        "UInt", WezTermCommandPaletteOpenMessageId(),
        "UPtr", sourceHwnd,
        "Ptr", sourcePid,
        "Int"
    )
    return posted ? 0 : 3
}
