#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(ChordPersistentProbeUnhandledError)
#Include ..\lib\chord-hotkeys.ahk

try {
    ChordPersistentProbeRun()
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    ChordPersistentProbeFail(e)
}

ChordPersistentProbeRun() {
    global CHORD_PREFIX_SETTINGS

    persistentSettings := ChordNormalizeRegisterOptions({ persistent: true })
    if !(persistentSettings.HasOwnProp("persistent") && persistentSettings.persistent)
        throw Error("Persistent option was not normalized")

    CHORD_PREFIX_SETTINGS["#a"] := persistentSettings
    if !ChordIsPersistent("#a")
        throw Error("Persistent menu was not detected")

    CHORD_PREFIX_SETTINGS["#w"] := ChordNormalizeRegisterOptions({ timeout: 10 })
    if ChordIsPersistent("#w")
        throw Error("Timed menu was detected as persistent")

    if (ChordNormalizeCapturedInput({ Input: Chr(27), EndKey: "" }) != "esc")
        throw Error("ASCII Esc was not normalized")
}

ChordPersistentProbeFail(errorValue) {
    try FileAppend(errorValue.Message . "`n" . errorValue.Stack . "`n", "**")
    ExitApp(1)
}

ChordPersistentProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    ExitApp(1)
    return true
}
