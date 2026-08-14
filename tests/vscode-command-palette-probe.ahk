#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(VSCodeCommandPaletteProbeUnhandledError)

#Include ..\lib\logging.ahk
#Include ..\lib\chord-hotkeys.ahk
#Include ..\command-palette-catalog.ahk
#Include ..\code.ahk

try {
    VSCodeCommandPaletteProbeRun()
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    VSCodeCommandPaletteProbeFail(e)
}

VSCodeCommandPaletteProbeRun() {
    specs := [
        ["VS Code · Go", "Alt+G", GetVSCodeGoChordOptions()],
        ["VS Code · Bookmarks", "Alt+B", GetVSCodeBookmarksChordOptions()],
        ["VS Code · References", "Ctrl+Alt+C", GetVSCodeReferencesChordOptions()],
        ["VS Code · Toggle", "Alt+T", GetVSCodeToggleChordOptions()],
        ["VS Code · File", "Alt+F", GetVSCodeFileChordOptions()],
        ["VS Code · Folding", "Alt+Z", GetVSCodeFoldingChordOptions()],
        ["VS Code · Settings", "Alt+S", GetVSCodeSettingsChordOptions()]
    ]

    for _, spec in specs {
        menu := CommandPaletteBuildMenuCatalog(spec[1], spec[2], spec[3])
        VSCodeCommandPaletteProbeAssert(menu.catalog.Length > 0, spec[1] . " catalog")
        VSCodeCommandPaletteProbeAssert(menu.actions.Count > 0, spec[1] . " actions")
        VSCodeCommandPaletteProbeAssert(menu.byId.Count = menu.catalog.Length, spec[1] . " ids")
        for _, command in menu.catalog {
            VSCodeCommandPaletteProbeAssert(command["source"] = spec[1], spec[1] . " source")
            if (command["kind"] = "action")
                VSCodeCommandPaletteProbeAssert(menu.actions.Has(command["id"]), spec[1] . " action mapping")
        }
    }
}

VSCodeCommandPaletteProbeAssert(condition, label) {
    if !condition
        throw Error("FAIL: " . label)
}

VSCodeCommandPaletteProbeFail(errorValue) {
    try FileAppend(errorValue.Message . "`n" . errorValue.Stack . "`n", "**")
    ExitApp(1)
}

VSCodeCommandPaletteProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    ExitApp(1)
    return true
}
