; Pure hierarchy adapter for the command palette. No hotkeys or WebView lifecycle.

global COMMAND_PALETTE_CATALOG := []
global COMMAND_PALETTE_ACTIONS := Map()
global COMMAND_PALETTE_BY_ID := Map()

CommandPaletteBuildCatalog() {
    global COMMAND_PALETTE_CATALOG, COMMAND_PALETTE_ACTIONS, COMMAND_PALETTE_BY_ID

    COMMAND_PALETTE_CATALOG := []
    COMMAND_PALETTE_ACTIONS := Map()
    COMMAND_PALETTE_BY_ID := Map()
    for _, root in [
        { source: "Apps", shortcut: "Win+A", options: GetMainSeqAOptions() },
        { source: "Web", shortcut: "Win+W", options: GetMainSeqWOptions() },
        { source: "Code", shortcut: "Win+C", options: GetMainSeqCOptions() }
    ] {
        CommandPaletteFlattenItems(root, root.options.items, [], [], [], "", 1)
    }
}

CommandPaletteFlattenItems(root, items, breadcrumbs, keyPath, stableKeyPath, parentId, depth) {
    global COMMAND_PALETTE_CATALOG, COMMAND_PALETTE_ACTIONS, COMMAND_PALETTE_BY_ID

    for _, item in items {
        if !IsObject(item) || !item.HasOwnProp("key")
            continue
        if (item.HasOwnProp("chordHidden") && item.chordHidden)
            continue

        itemBreadcrumbs := breadcrumbs.Clone()
        itemKeyPath := CommandPaletteGetItemKeyPath(keyPath, item)
        itemStableKeyPath := stableKeyPath.Clone()
        itemStableKeyPath.Push(item.key)
        hasChildren := item.HasOwnProp("items") && IsObject(item.items)
        kind := hasChildren ? "group" : "action"
        if (!hasChildren && (!item.HasOwnProp("action") || !IsObject(item.action)))
            continue

        id := root.source . ":" . CommandPaletteJoin(itemStableKeyPath, ".")
        if COMMAND_PALETTE_BY_ID.Has(id)
            throw Error("Duplicate command palette id: " . id)
        breadcrumb := itemBreadcrumbs.Length ? CommandPaletteJoin(itemBreadcrumbs, " › ") : ""
        detail := item.HasOwnProp("doc") ? item.doc : (item.HasOwnProp("command") ? item.command : "")
        shortcut := root.shortcut . " " . CommandPaletteJoin(itemKeyPath, " ")
        record := Map(
            "id", id,
            "kind", kind,
            "parentId", parentId,
            "depth", depth,
            "label", CommandPaletteGetItemLabel(item),
            "source", root.source,
            "breadcrumb", breadcrumb,
            "shortcut", shortcut,
            "detail", detail
        )
        COMMAND_PALETTE_CATALOG.Push(record)
        COMMAND_PALETTE_BY_ID[id] := record

        if hasChildren {
            itemBreadcrumbs.Push(CommandPaletteGetItemLabel(item))
            CommandPaletteFlattenItems(root, item.items, itemBreadcrumbs, itemKeyPath, itemStableKeyPath, id, depth + 1)
        } else {
            COMMAND_PALETTE_ACTIONS[id] := item.action
        }
    }
}

CommandPaletteGetItemKeyPath(parentPath, item) {
    path := parentPath.Clone()
    if (item.HasOwnProp("chordPath") && IsObject(item.chordPath)) {
        path := []
        for _, key in item.chordPath
            path.Push(ChordFormatSuffixForHint(ChordNormalizeSuffixKey(key)))
    } else {
        path.Push(ChordFormatSuffixForHint(ChordNormalizeSuffixKey(item.key)))
    }
    return path
}

CommandPaletteGetItemLabel(item) {
    if (item.HasOwnProp("chordLabel") && item.chordLabel != "")
        return item.chordLabel
    return item.HasOwnProp("label") ? item.label : item.key
}

CommandPaletteJoin(values, separator := "") {
    text := ""
    for index, value in values
        text .= (index > 1 ? separator : "") . value
    return text
}
