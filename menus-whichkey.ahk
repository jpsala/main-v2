; Bridge menu definitions from menus.ahk into the chord-hotkeys engine.
; Each menu item carries its own action closure — no separate handler needed.

; ===================================================================
; Generic menu action dispatch
; ===================================================================
BuildActionMap(items, prefix := "") {
    actionMap := Map()
    for _, item in items {
        if !IsObject(item) || !item.HasOwnProp("key")
            continue
        fullKey := prefix . item.key
        if (item.HasOwnProp("action"))
            actionMap[fullKey] := item.action
        if (item.HasOwnProp("items") && IsObject(item.items))
            for k, v in BuildActionMap(item.items, fullKey)
                actionMap[k] := v
    }
    return actionMap
}

RunMenuAction(actionMap, key) {
    if actionMap.Has(key)
        actionMap[key].Call()
}

InitMenusWhichKey(defaultTimeout := 10) {
    MenuWhichKeyRegisterWithActions("#a", GetMainSeqAOptions(), defaultTimeout)
    MenuWhichKeyRegisterWithActions("#w", GetMainSeqWOptions(), defaultTimeout)
    MenuWhichKeyRegisterWithActions("#c", GetMainSeqCOptions(), defaultTimeout)
    ; Pre-initialize the hint WebView so it's ready on first use
    SetTimer(() => ChordHintInit(), -500)
}

MenuWhichKeyRegisterWithActions(prefixHotkey, options, defaultTimeout := 0) {
    actionMap := BuildActionMap(options.items)
    MenuWhichKeyRegister(prefixHotkey, options, RunMenuAction.Bind(actionMap), defaultTimeout)
}

MenuWhichKeyRegister(prefixHotkey, options, executeFn, defaultTimeout := 0) {
    if !IsObject(options) || !options.HasOwnProp("items") || !IsObject(options.items)
        return

    prefixMap := Map()
    prefixMap[prefixHotkey] := MenuWhichKeyBuildItems(options.items)
    ChordRegister(prefixMap, executeFn, MenuWhichKeyGetRegisterOptions(options, defaultTimeout))
}

MenuWhichKeyGetRegisterOptions(options, defaultTimeout := 0) {
    registerOptions := {}

    if (options.HasOwnProp("chordHintDelay"))
        registerOptions.hintDelay := options.chordHintDelay
    if (options.HasOwnProp("chordTimeout"))
        registerOptions.timeout := options.chordTimeout
    else if (defaultTimeout > 0)
        registerOptions.timeout := defaultTimeout

    return registerOptions
}

MenuWhichKeyBuildItems(menuItems, legacyPrefix := "") {
    chordItems := Map()

    for _, item in menuItems {
        if !IsObject(item) || !item.HasOwnProp("key")
            continue
        if (item.HasOwnProp("chordHidden") && item.chordHidden)
            continue

        legacyKey := item.key
        fullLegacyKey := legacyPrefix . legacyKey
        chordPath := MenuWhichKeyGetPath(item)
        if (chordPath.Length = 0)
            continue

        entryLabel := MenuWhichKeyGetLabel(item)
        if (item.HasOwnProp("items") && IsObject(item.items)) {
            entry := {
                label: entryLabel,
                items: MenuWhichKeyBuildItems(item.items, fullLegacyKey)
            }
        } else {
            entry := ChordEntry(fullLegacyKey, entryLabel)
        }

        MenuWhichKeyInsertEntry(chordItems, chordPath, entry, item)
    }

    return chordItems
}

MenuWhichKeyGetLabel(item) {
    if (item.HasOwnProp("chordLabel") && item.chordLabel != "")
        return item.chordLabel
    if (item.HasOwnProp("label"))
        return item.label
    return item.key
}

MenuWhichKeyGetPath(item) {
    path := []

    if (item.HasOwnProp("chordPath") && IsObject(item.chordPath)) {
        for _, pathKey in item.chordPath {
            normalizedKey := ChordNormalizeSuffixKey(pathKey)
            if (normalizedKey = "")
                return []
            path.Push(normalizedKey)
        }
        return path
    }

    keySpec := item.HasOwnProp("chordKey") ? item.chordKey : item.key
    normalizedKey := ChordNormalizeSuffixKey(keySpec)
    if (normalizedKey = "")
        return []

    path.Push(normalizedKey)
    return path
}

MenuWhichKeyInsertEntry(targetItems, chordPath, entry, sourceItem) {
    pathLength := chordPath.Length
    if (pathLength = 0)
        return

    currentKey := chordPath[1]
    if (pathLength = 1) {
        targetItems[currentKey] := entry
        return
    }

    if !targetItems.Has(currentKey) {
        groupLabel := MenuWhichKeyGetPathLabel(sourceItem, currentKey)
        targetItems[currentKey] := { label: groupLabel, items: Map() }
    }

    currentEntry := targetItems[currentKey]
    if !(IsObject(currentEntry) && currentEntry.HasOwnProp("items") && IsObject(currentEntry.items))
        return

    if (sourceItem.HasOwnProp("chordPathLabel") && sourceItem.chordPathLabel != "")
        currentEntry.label := sourceItem.chordPathLabel

    remainingPath := []
    Loop pathLength - 1
        remainingPath.Push(chordPath[A_Index + 1])

    MenuWhichKeyInsertEntry(currentEntry.items, remainingPath, entry, sourceItem)
}

MenuWhichKeyGetPathLabel(sourceItem, fallbackKey) {
    if (sourceItem.HasOwnProp("chordPathLabel") && sourceItem.chordPathLabel != "")
        return sourceItem.chordPathLabel
    return ChordFormatSuffixForHint(fallbackKey)
}

InitMenusWhichKey()
