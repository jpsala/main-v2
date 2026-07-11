#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(MenuWebViewProbeUnhandledError)
#Include ..\lib\chord-hotkeys.ahk
#Include ..\menus-whichkey.ahk
#Include ..\menu-webview.ahk

try {
    MenuWebViewProbeRun()
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    MenuWebViewProbeFail(e)
}

MenuWebViewProbeRun() {
    items := [
        { key: "a", label: "Visible", action: (*) => 0 },
        { key: "x", label: "Hidden", chordHidden: true, action: (*) => 0 },
        { key: "s", label: "Group", items: [
            { key: "b", label: "Nested", action: (*) => 0 },
            { key: "x", label: "Nested hidden", chordHidden: true, action: (*) => 0 }
        ] }
    ]

    actions := BuildActionMap(items)
    if !(actions.Has("a") && actions.Has("sb") && actions.Has("x"))
        throw Error("Action map lost a declared action")

    menuJson := MenuWebViewBuildJSON({ items: items }, [])
    if (InStr(menuJson, "Hidden"))
        throw Error("WebView menu exposed a chordHidden item")
    if !(InStr(menuJson, "Visible") && InStr(menuJson, "Nested"))
        throw Error("WebView menu omitted a visible item")
}

MenuWebViewProbeFail(errorValue) {
    try FileAppend(errorValue.Message . "`n" . errorValue.Stack . "`n", "**")
    ExitApp(1)
}

MenuWebViewProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    ExitApp(1)
    return true
}
