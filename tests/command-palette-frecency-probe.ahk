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
    global COMMAND_PALETTE_FRECENCY, COMMAND_PALETTE_FRECENCY_STATE_PATH

    stateDir := A_Temp . "\main-command-palette-frecency-probe-" . A_TickCount
    COMMAND_PALETTE_FRECENCY_STATE_PATH := stateDir . "\state.json"
    COMMAND_PALETTE_FRECENCY := Map()
    catalogById := Map(
        "WezTerm:g", Map("id", "WezTerm:g", "parentId", ""),
        "WezTerm:g.a", Map("id", "WezTerm:g.a", "parentId", "WezTerm:g"),
        "WezTerm:sibling", Map("id", "WezTerm:sibling", "parentId", "")
    )

    firstUse := "20260701000000"
    halfLifeLater := "20260715000000"
    CommandPaletteFrecencyRecordUse("WezTerm:g.a", catalogById, firstUse)
    CommandPaletteFrecencyProbeNear(COMMAND_PALETTE_FRECENCY["WezTerm:g.a"]["score"], 1, "custom action first use")
    CommandPaletteFrecencyProbeNear(COMMAND_PALETTE_FRECENCY["WezTerm:g"]["score"], 1, "custom parent propagation")
    CommandPaletteFrecencyProbeAssert(!COMMAND_PALETTE_FRECENCY.Has("WezTerm:sibling"), "custom sibling unchanged")

    CommandPaletteFrecencyRecordUse("WezTerm:g.a", catalogById, halfLifeLater)
    CommandPaletteFrecencyProbeNear(COMMAND_PALETTE_FRECENCY["WezTerm:g.a"]["score"], 1.5, "custom decay before increment")
    snapshot := CommandPaletteFrecencyGetSnapshot(catalogById, halfLifeLater)
    CommandPaletteFrecencyProbeNear(snapshot["WezTerm:g"], 1.5, "custom snapshot score")

    COMMAND_PALETTE_FRECENCY := Map()
    CommandPaletteFrecencyLoad()
    CommandPaletteFrecencyProbeNear(COMMAND_PALETTE_FRECENCY["WezTerm:g.a"]["score"], 1.5, "persistence round-trip")
    CommandPaletteFrecencyProbeAssert(CommandPaletteFrecencyReset("WezTerm:g.a"), "individual ranking reset")
    CommandPaletteFrecencyProbeAssert(!COMMAND_PALETTE_FRECENCY.Has("WezTerm:g.a"), "reset removes action score")
    CommandPaletteFrecencyProbeAssert(COMMAND_PALETTE_FRECENCY.Has("WezTerm:g"), "reset preserves parent score")
    COMMAND_PALETTE_FRECENCY := Map()
    CommandPaletteFrecencyLoad()
    CommandPaletteFrecencyProbeAssert(!COMMAND_PALETTE_FRECENCY.Has("WezTerm:g.a"), "reset persistence")

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
