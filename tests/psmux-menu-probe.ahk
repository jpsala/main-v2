#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(PsmuxMenuProbeUnhandledError)

#Include ..\lib\chord-hotkeys.ahk
#Include ..\menus-whichkey.ahk
#Include ..\menu-webview.ahk
#Include ..\psmux-menu.ahk

try {
    PsmuxMenuProbeRun()
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    PsmuxMenuProbeFail(e)
}

PsmuxMenuProbeRun() {
    options := PsmuxMenuGetOptions()
    PsmuxMenuProbeAssert(options.HasOwnProp("title") && options.title = "psmux commands", "menu title")
    PsmuxMenuProbeAssert(options.HasOwnProp("items") && options.items.Length >= 20, "menu item count")

    actionMap := BuildActionMap(options.items)
    for _, actionId in ["ss", "sn", "sr", "wm", "wt", "wn", "wr", "wx", "wh", "wv", "wz", "cm", "rc", "hk", "lc"]
        PsmuxMenuProbeAssert(actionMap.Has(actionId), "action " . actionId)

    labels := Map()
    for _, item in options.items {
        PsmuxMenuProbeAssert(item.HasOwnProp("key") && item.key != "", "item key")
        PsmuxMenuProbeAssert(item.HasOwnProp("label") && item.label != "", "item label")
        PsmuxMenuProbeAssert(item.HasOwnProp("action"), "item action " . item.key)
        PsmuxMenuProbeAssert(!labels.Has(item.label), "unique label " . item.label)
        labels[item.label] := true
    }

    PsmuxMenuProbeAssert(PsmuxMenuIsValidSessionName("work_1.test"), "valid session name")
    PsmuxMenuProbeAssert(!PsmuxMenuIsValidSessionName("bad name"), "reject session whitespace")
    PsmuxMenuProbeAssert(!PsmuxMenuIsValidSessionName("bad;command"), "reject command injection")
}

PsmuxMenuProbeAssert(condition, label) {
    if !condition
        throw Error("FAIL: " . label)
}

PsmuxMenuProbeFail(errorValue) {
    try FileAppend(errorValue.Message . "`n" . errorValue.Stack . "`n", "**")
    ExitApp(1)
}

PsmuxMenuProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    ExitApp(1)
    return true
}
