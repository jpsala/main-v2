#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(CommandPaletteFrecencyProbeUnhandledError)

#Include ..\lib\json.ahk
#Include ..\command-palette-frecency.ahk

try {
    CommandPaletteFrecencyProbeRun()
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    CommandPaletteFrecencyProbeFail(e)
}

CommandPaletteFrecencyProbeRun() {
    global COMMAND_PALETTE_BY_ID, COMMAND_PALETTE_FRECENCY, COMMAND_PALETTE_FRECENCY_STATE_PATH

    stateDir := A_Temp . "\main-command-palette-frecency-probe-" . A_TickCount
    COMMAND_PALETTE_FRECENCY_STATE_PATH := stateDir . "\state.json"
    COMMAND_PALETTE_FRECENCY := Map()
    COMMAND_PALETTE_BY_ID := Map(
        "Apps:g", Map("id", "Apps:g", "parentId", ""),
        "Apps:g.a", Map("id", "Apps:g.a", "parentId", "Apps:g"),
        "Apps:sibling", Map("id", "Apps:sibling", "parentId", "")
    )

    firstUse := "20260701000000"
    halfLifeLater := "20260715000000"
    CommandPaletteFrecencyRecordUse("Apps:g.a", firstUse)
    CommandPaletteFrecencyProbeNear(COMMAND_PALETTE_FRECENCY["Apps:g.a"]["score"], 1, "first action use")
    CommandPaletteFrecencyProbeNear(COMMAND_PALETTE_FRECENCY["Apps:g"]["score"], 1, "parent propagation")
    CommandPaletteFrecencyProbeAssert(!COMMAND_PALETTE_FRECENCY.Has("Apps:sibling"), "sibling unchanged")

    CommandPaletteFrecencyRecordUse("Apps:g.a", halfLifeLater)
    CommandPaletteFrecencyProbeNear(COMMAND_PALETTE_FRECENCY["Apps:g.a"]["score"], 1.5, "decay before increment")
    CommandPaletteFrecencyProbeNear(CommandPaletteFrecencyGetSnapshot(halfLifeLater)["Apps:g"], 1.5, "snapshot score")

    COMMAND_PALETTE_FRECENCY := Map()
    CommandPaletteFrecencyLoad()
    CommandPaletteFrecencyProbeNear(COMMAND_PALETTE_FRECENCY["Apps:g.a"]["score"], 1.5, "persistence round-trip")

    FileDelete(COMMAND_PALETTE_FRECENCY_STATE_PATH)
    FileAppend("not-json", COMMAND_PALETTE_FRECENCY_STATE_PATH, "UTF-8")
    CommandPaletteFrecencyLoad()
    CommandPaletteFrecencyProbeAssert(COMMAND_PALETTE_FRECENCY.Count = 0, "corrupt state degrades to empty")

    try DirDelete(stateDir, true)
}

CommandPaletteFrecencyProbeNear(actual, expected, label) {
    if Abs(actual - expected) > 0.000001
        throw Error("FAIL: " . label . " expected=" . expected . " actual=" . actual)
}

CommandPaletteFrecencyProbeAssert(condition, label) {
    if !condition
        throw Error("FAIL: " . label)
}

CommandPaletteFrecencyProbeFail(errorValue) {
    try FileAppend(errorValue.Message . "`n" . errorValue.Stack . "`n", "**")
    ExitApp(1)
}

CommandPaletteFrecencyProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    ExitApp(1)
    return true
}
