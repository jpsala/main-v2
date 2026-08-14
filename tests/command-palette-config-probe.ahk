#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(CommandPaletteConfigProbeUnhandledError)

#Include ..\lib\chord-hotkeys.ahk
#Include ..\lib\json.ahk
#Include ..\menu-actions.ahk
#Include ..\menus.ahk
#Include ..\command-palette-catalog.ahk
#Include ..\command-palette-config.ahk

try {
    CommandPaletteConfigProbeRun()
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    CommandPaletteConfigProbeFail(e)
}

CommandPaletteConfigProbeRun() {
    global COMMAND_PALETTE_ACTIONS, COMMAND_PALETTE_CONFIG, COMMAND_PALETTE_CONFIG_ITEMS
    global COMMAND_PALETTE_CONFIG_LAST_ERROR, COMMAND_PALETTE_CONFIG_PATH, COMMAND_PALETTE_CONFIG_LOADED_REVISION

    originalPath := COMMAND_PALETTE_CONFIG_PATH
    CommandPaletteConfigProbeAssert(CommandPaletteConfigLoad(), "canonical config loads: " . COMMAND_PALETTE_CONFIG_LAST_ERROR)
    CommandPaletteConfigProbeAssert(COMMAND_PALETTE_CONFIG_ITEMS.Count > 150, "canonical item inventory")
    CommandPaletteConfigProbeAssert(CommandPaletteConfigSources()[1] = "Apps", "explicit menu order")
    CommandPaletteConfigProbeAssert(CommandPaletteConfigSources()[2] = "Web", "web menu order")

    CommandPaletteBuildCatalog()
    configured := CommandPaletteConfigBuildCatalog("Global")
    configuredActions := CommandPaletteConfigResolveActions("Global", COMMAND_PALETTE_ACTIONS)
    actionCount := 0
    for _, command in configured
        if command["kind"] = "action" {
            actionCount += 1
            CommandPaletteConfigProbeAssert(configuredActions.Has(command["id"]), "configured action " . command["id"])
        }
    CommandPaletteConfigProbeAssert(actionCount = configuredActions.Count, "all configured actions resolve")

    chordItems := CommandPaletteConfigBuildChordItems("Web")
    CommandPaletteConfigProbeAssert(chordItems.Has("f"), "configured Web f chord")
    CommandPaletteConfigProbeAssert(ChordEntryGetCommand(chordItems["f"]) = "Web:f", "configured chord action id")

    stateDir := A_Temp . "\main-command-palette-config-probe-" . A_TickCount
    DirCreate(stateDir)
    COMMAND_PALETTE_CONFIG_PATH := stateDir . "\menu-config.json"
    FileCopy(originalPath, COMMAND_PALETTE_CONFIG_PATH)
    CommandPaletteConfigProbeAssert(CommandPaletteConfigLoad(), "temporary config loads")
    initialRevision := COMMAND_PALETTE_CONFIG_LOADED_REVISION

    formattedJson := FileRead(COMMAND_PALETTE_CONFIG_PATH, "UTF-8")
    CommandPaletteConfigProbeAssert(InStr(formattedJson, "`n  "), "human-readable JSON formatting")
    if (COMMAND_PALETTE_CONFIG_ITEMS.Has("Apps:n") && COMMAND_PALETTE_CONFIG_ITEMS.Has("Apps:n.c")) {
        CommandPaletteConfigProbeAssert(!CommandPaletteConfigSetItem("Apps:n", "parentId", "Apps:n.c"), "hierarchy cycle rejected")
        CommandPaletteConfigProbeAssert(CommandPaletteConfigGetItem("Apps:n")["parentId"] = "", "cycle rejection restores file state")
    }
    CommandPaletteConfigProbeAssert(CommandPaletteConfigSetMenu("Web", "viewMode", "flat"), "menu preference save")
    CommandPaletteConfigProbeAssert(COMMAND_PALETTE_CONFIG_LOADED_REVISION = initialRevision + 1, "revision increment")
    CommandPaletteConfigProbeAssert(FileExist(COMMAND_PALETTE_CONFIG_PATH . ".bak"), "atomic backup")
    CommandPaletteConfigProbeAssert(CommandPaletteConfigSetItem("Web:f", "label", "Browser preferred"), "item label save")
    CommandPaletteConfigProbeAssert(CommandPaletteConfigSetItem("Web:f", "alias", "browser"), "item alias save")
    CommandPaletteConfigProbeAssert(CommandPaletteConfigTogglePin("Web:f"), "pin save")
    CommandPaletteConfigProbeAssert(CommandPaletteConfigLoad(), "saved config reload")
    webCatalog := CommandPaletteConfigBuildCatalog("Web")
    browser := CommandPaletteConfigProbeFind(webCatalog, "Web:f")
    CommandPaletteConfigProbeAssert(browser["label"] = "Browser preferred", "label round-trip")
    CommandPaletteConfigProbeAssert(browser["alias"] = "browser", "alias round-trip")
    CommandPaletteConfigProbeAssert(browser["pinned"], "pin round-trip")
    CommandPaletteConfigProbeAssert(CommandPaletteConfigGetMenu("Web")["viewMode"] = "flat", "view round-trip")

    groupId := "Web:c"
    if COMMAND_PALETTE_CONFIG_ITEMS.Has(groupId) && COMMAND_PALETTE_CONFIG_ITEMS[groupId]["kind"] = "group" {
        CommandPaletteConfigProbeAssert(CommandPaletteConfigSetItem(groupId, "hidden", true), "group hide save")
        hiddenCatalog := CommandPaletteConfigBuildCatalog("Web")
        for _, command in hiddenCatalog
            CommandPaletteConfigProbeAssert(command["id"] != groupId && command["parentId"] != groupId, "hidden group subtree")
    }

    CommandPaletteConfigProbeAssert(CommandPaletteConfigDeleteItem("Web:f"), "single item deletion")
    CommandPaletteConfigProbeAssert(!COMMAND_PALETTE_CONFIG_ITEMS.Has("Web:f"), "deleted item leaves index")
    for _, command in CommandPaletteConfigBuildCatalog("Web")
        CommandPaletteConfigProbeAssert(command["id"] != "Web:f", "deleted item leaves catalog")

    if COMMAND_PALETTE_CONFIG_ITEMS.Has("Apps:n") {
        descendantIds := []
        for candidateId, item in COMMAND_PALETTE_CONFIG_ITEMS
            if CommandPaletteConfigProbeIsDescendant(candidateId, "Apps:n")
                descendantIds.Push(candidateId)
        CommandPaletteConfigProbeAssert(descendantIds.Length > 0, "cascade fixture has descendants")
        CommandPaletteConfigProbeAssert(CommandPaletteConfigDeleteItem("Apps:n"), "group cascade deletion")
        CommandPaletteConfigProbeAssert(!COMMAND_PALETTE_CONFIG_ITEMS.Has("Apps:n"), "deleted group leaves index")
        for _, descendantId in descendantIds
            CommandPaletteConfigProbeAssert(!COMMAND_PALETTE_CONFIG_ITEMS.Has(descendantId), "deleted descendant " . descendantId)
    }
    externalCatalog := [
        Map("id", "External:g", "kind", "group", "parentId", "", "depth", 1, "label", "External group", "source", "External", "breadcrumb", "", "shortcut", "External G", "detail", ""),
        Map("id", "External:a", "kind", "action", "parentId", "External:g", "depth", 2, "label", "External action", "source", "External", "breadcrumb", "External group", "shortcut", "External G A", "detail", "")
    ]
    CommandPaletteConfigBuildCatalog("External", externalCatalog)
    CommandPaletteConfigProbeAssert(CommandPaletteConfigTogglePin("External:a"), "external pin save")
    CommandPaletteConfigProbeAssert(CommandPaletteConfigSetMenu("External", "viewMode", "mixed"), "external menu preference save")
    CommandPaletteConfigProbeAssert(CommandPaletteConfigLoad(), "external overrides reload")
    externalResolved := CommandPaletteConfigBuildCatalog("External", externalCatalog)
    externalAction := CommandPaletteConfigProbeFind(externalResolved, "External:a")
    CommandPaletteConfigProbeAssert(externalAction["pinned"], "external pin round-trip")
    CommandPaletteConfigProbeAssert(CommandPaletteConfigGetMenu("External")["viewMode"] = "mixed", "external view round-trip")

    beforeConflict := COMMAND_PALETTE_CONFIG_LOADED_REVISION
    externalJson := FileRead(COMMAND_PALETTE_CONFIG_PATH, "UTF-8")
    external := JsonLoad(&externalJson)
    external["revision"] := beforeConflict + 1
    FileDelete(COMMAND_PALETTE_CONFIG_PATH)
    FileAppend(JsonDump(external, "  ") . "`n", COMMAND_PALETTE_CONFIG_PATH, "UTF-8")
    CommandPaletteConfigProbeAssert(!CommandPaletteConfigSetMenu("Web", "viewMode", "mixed"), "revision conflict rejected")
    CommandPaletteConfigProbeAssert(CommandPaletteConfigGetMenu("Web")["viewMode"] = "flat", "conflict reload preserves external state")

    COMMAND_PALETTE_CONFIG_PATH := originalPath
    CommandPaletteConfigLoad()
    try DirDelete(stateDir, true)
}

CommandPaletteConfigProbeIsDescendant(id, ancestorId) {
    global COMMAND_PALETTE_CONFIG_ITEMS

    if !COMMAND_PALETTE_CONFIG_ITEMS.Has(id)
        return false
    parentId := COMMAND_PALETTE_CONFIG_ITEMS[id]["parentId"]
    while parentId != "" {
        if parentId = ancestorId
            return true
        if !COMMAND_PALETTE_CONFIG_ITEMS.Has(parentId)
            return false
        parentId := COMMAND_PALETTE_CONFIG_ITEMS[parentId]["parentId"]
    }
    return false
}

CommandPaletteConfigProbeFind(catalog, id) {
    for _, command in catalog
        if command["id"] = id
            return command
    throw Error("Missing configured item " . id)
}

CommandPaletteConfigProbeAssert(condition, label) {
    if !condition
        throw Error("FAIL: " . label)
}

CommandPaletteConfigProbeFail(errorValue) {
    try FileAppend(errorValue.Message . "`n" . errorValue.Stack . "`n", "**")
    ExitApp(1)
}

CommandPaletteConfigProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    ExitApp(1)
    return true
}
