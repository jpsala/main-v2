#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(CommandPaletteProbeUnhandledError)

#Include ..\lib\chord-hotkeys.ahk
#Include ..\lib\json.ahk
#Include ..\menus.ahk
#Include ..\command-palette-catalog.ahk

try {
    CommandPaletteProbeRun()
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    CommandPaletteProbeFail(e)
}

CommandPaletteProbeRun() {
    global COMMAND_PALETTE_ACTIONS, COMMAND_PALETTE_BY_ID, COMMAND_PALETTE_CATALOG, COMMAND_PALETTE_PROBE_ACTION

    COMMAND_PALETTE_PROBE_ACTION := ""
    items := [
        { key: "a", label: "Visible", action: CommandPaletteProbeAction.Bind("visible") },
        { key: "x", label: "Hidden", chordHidden: true, action: CommandPaletteProbeAction.Bind("hidden") },
        { key: "h", label: "Hidden group", chordHidden: true, items: [
            { key: "a", label: "Hidden child", action: CommandPaletteProbeAction.Bind("hidden-child") }
        ] },
        { key: "g", label: "Group", items: [
            { key: "p3", chordPath: ["p", "3"], label: "Nested", action: CommandPaletteProbeAction.Bind("nested") }
        ] }
    ]

    COMMAND_PALETTE_CATALOG := []
    COMMAND_PALETTE_ACTIONS := Map()
    COMMAND_PALETTE_BY_ID := Map()
    CommandPaletteFlattenItems({ source: "Apps", shortcut: "Win+A" }, items, [], [], [], "", 1)

    CommandPaletteProbeAssert(COMMAND_PALETTE_CATALOG.Length = 3, "hidden subtree exclusion")
    directAction := COMMAND_PALETTE_CATALOG[1]
    group := COMMAND_PALETTE_CATALOG[2]
    nestedAction := COMMAND_PALETTE_CATALOG[3]
    CommandPaletteProbeAssert(directAction["kind"] = "action" && directAction["depth"] = 1 && directAction["parentId"] = "", "direct action hierarchy")
    CommandPaletteProbeAssert(directAction["id"] = "Apps:a" && group["id"] = "Apps:g" && nestedAction["id"] = "Apps:g.p3", "stable structural ids")
    CommandPaletteProbeAssert(group["kind"] = "group" && group["depth"] = 1 && group["parentId"] = "", "group hierarchy")
    CommandPaletteProbeAssert(nestedAction["kind"] = "action" && nestedAction["depth"] = 2 && nestedAction["parentId"] = group["id"], "nested action hierarchy")
    CommandPaletteProbeAssert(InStr(nestedAction["shortcut"], "P 3"), "chordPath shortcut")
    CommandPaletteProbeAssert(!COMMAND_PALETTE_ACTIONS.Has(group["id"]), "group excluded from action map")
    CommandPaletteProbeAssert(COMMAND_PALETTE_ACTIONS.Count = 2 && COMMAND_PALETTE_ACTIONS.Has(nestedAction["id"]), "action-only closure map")

    COMMAND_PALETTE_ACTIONS[nestedAction["id"]].Call()
    CommandPaletteProbeAssert(COMMAND_PALETTE_PROBE_ACTION = "nested", "closure dispatch")

    COMMAND_PALETTE_CATALOG := []
    COMMAND_PALETTE_ACTIONS := Map()
    COMMAND_PALETTE_BY_ID := Map()
    changedItems := [
        { key: "before", label: "Inserted", action: CommandPaletteProbeAction.Bind("inserted") },
        { key: "a", label: "Renamed", action: CommandPaletteProbeAction.Bind("visible") },
        { key: "g", label: "Renamed group", items: [
            { key: "p3", chordPath: ["different"], label: "Renamed nested", action: CommandPaletteProbeAction.Bind("nested") }
        ] }
    ]
    CommandPaletteFlattenItems({ source: "Apps", shortcut: "Win+A" }, changedItems, [], [], [], "", 1)
    CommandPaletteProbeAssert(COMMAND_PALETTE_BY_ID.Has("Apps:a") && COMMAND_PALETTE_BY_ID.Has("Apps:g.p3"), "ids survive insertion and metadata changes")

    CommandPaletteBuildCatalog()
    CommandPaletteProbeAssert(COMMAND_PALETTE_CATALOG.Length > 0, "real menu catalog")
    sources := Map()
    ids := Map()
    records := Map()
    actionCount := 0
    for _, command in COMMAND_PALETTE_CATALOG {
        source := command["source"]
        id := command["id"]
        sources[source] := true
        CommandPaletteProbeAssert(!ids.Has(id), "unique real id " . id)
        ids[id] := true
        records[id] := command
        if (command["kind"] = "action") {
            actionCount += 1
            CommandPaletteProbeAssert(COMMAND_PALETTE_ACTIONS.Has(id), "real action " . id)
        } else {
            CommandPaletteProbeAssert(!COMMAND_PALETTE_ACTIONS.Has(id), "real group excluded from action map " . id)
        }
    }
    CommandPaletteProbeAssert(actionCount = COMMAND_PALETTE_ACTIONS.Count, "real action map count")
    for _, source in ["Apps", "Web", "Code"]
        CommandPaletteProbeAssert(sources.Has(source), "source " . source)
    for _, command in COMMAND_PALETTE_CATALOG {
        if (command["parentId"] != "") {
            CommandPaletteProbeAssert(records.Has(command["parentId"]), "existing parent " . command["id"])
            CommandPaletteProbeAssert(records[command["parentId"]]["kind"] = "group", "parent is group " . command["id"])
            CommandPaletteProbeAssert(command["depth"] = records[command["parentId"]]["depth"] + 1, "declarative depth " . command["id"])
        }
    }

    catalogJson := JsonDump(COMMAND_PALETTE_CATALOG)
    catalogCopy := JsonLoad(&catalogJson)
    CommandPaletteProbeAssert(catalogCopy.Length = COMMAND_PALETTE_CATALOG.Length, "catalog JSON round-trip")

    executeJson := '{"action":"execute","id":"Apps:b"}'
    executePayload := JsonLoad(&executeJson)
    CommandPaletteProbeAssert(executePayload["action"] = "execute" && executePayload["id"] = "Apps:b", "execute payload")
    cancelJson := '{"action":"cancel"}'
    cancelPayload := JsonLoad(&cancelJson)
    CommandPaletteProbeAssert(cancelPayload["action"] = "cancel", "cancel payload")
}

CommandPaletteProbeAssert(condition, label) {
    if !condition
        throw Error("FAIL: " . label)
}

CommandPaletteProbeAction(name, *) {
    global COMMAND_PALETTE_PROBE_ACTION
    COMMAND_PALETTE_PROBE_ACTION := name
}

CommandPaletteProbeFail(errorValue) {
    try FileAppend(errorValue.Message . "`n" . errorValue.Stack . "`n", "**")
    ExitApp(1)
}

CommandPaletteProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    ExitApp(1)
    return true
}
