; Bridge menu definitions from menus.ahk into the chord-hotkeys engine.
; Each menu item carries its own action closure — no separate handler needed.

global MENU_WHICHKEY_DEFAULT_IDLE_TIMEOUT_SECONDS := 10
global MENU_WHICHKEY_DEFAULT_HOLD_OPEN_KEYS := ["space"]

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

MenuWebViewRunWithActions(options, *) {
    actionMap := BuildActionMap(options.items)
    result := ShowWebViewMenu(options)
    if (result && result != "CANCELLED")
        RunMenuAction(actionMap, result)
}

MenuWebViewRegisterWithActions(prefixHotkey, options) {
    Hotkey(ChordEnsureHookHotkey(prefixHotkey), MenuWebViewRunWithActions.Bind(options))
}

InitMenusWhichKey() {
    MenuWhichKeyRefreshMainMenus()
    ; Pre-initialize the hint WebView so it's ready on first use
    SetTimer(() => ChordHintInit(), -500)
}

MenuWhichKeyRefreshMainMenus() {
    MenuWhichKeyRegisterWithActions("#a", GetMainSeqAOptions())
    MenuWhichKeyRegisterWithActions("#w", GetMainSeqWOptions())
    MenuWhichKeyRegisterWithActions("#c", GetMainSeqCOptions())
}

MenuWhichKeyRegisterWithActions(prefixHotkey, options) {
    actionMap := BuildActionMap(options.items)
    MenuWhichKeyRegister(prefixHotkey, options, RunMenuAction.Bind(actionMap))
}

MenuWhichKeyRegister(prefixHotkey, options, executeFn) {
    if !IsObject(options) || !options.HasOwnProp("items") || !IsObject(options.items)
        return

    prefixMap := Map()
    prefixMap[prefixHotkey] := MenuWhichKeyBuildItems(options.items)
    ChordRegister(prefixMap, executeFn, MenuWhichKeyGetRegisterOptions(prefixHotkey, options))
}

MenuWhichKeyGetRegisterOptions(prefixHotkey, options) {
    global MENU_WHICHKEY_DEFAULT_IDLE_TIMEOUT_SECONDS, MENU_WHICHKEY_DEFAULT_HOLD_OPEN_KEYS
    registerOptions := {}

    showDelaySeconds := MenuWhichKeyGetShowDelaySeconds(options)
    if (showDelaySeconds != "")
        registerOptions.hintDelay := showDelaySeconds

    idleTimeoutSeconds := MenuWhichKeyGetIdleTimeoutSeconds(options)
    registerOptions.timeout := idleTimeoutSeconds != "" ? idleTimeoutSeconds : MENU_WHICHKEY_DEFAULT_IDLE_TIMEOUT_SECONDS

    if (MenuWhichKeyPersistentMenusEnabled() && (prefixHotkey = "#a" || prefixHotkey = "#w" || prefixHotkey = "#c"))
        registerOptions.persistent := true

    if (options.HasOwnProp("chordPrefixLabel"))
        registerOptions.prefixLabel := options.chordPrefixLabel

    if (options.HasOwnProp("holdOpenKeys"))
        registerOptions.holdOpenKeys := options.holdOpenKeys
    else if (options.HasOwnProp("holdOpenKey"))
        registerOptions.holdOpenKey := options.holdOpenKey
    else
        registerOptions.holdOpenKeys := MENU_WHICHKEY_DEFAULT_HOLD_OPEN_KEYS

    return registerOptions
}

MenuWhichKeyPersistentMenusEnabled() {
    return IniRead("config.ini", "variables", "persistentMenusEnabled", "0") = "1"
}

MenuWhichKeyGetShowDelaySeconds(options) {
    if (options.HasOwnProp("showDelaySeconds"))
        return options.showDelaySeconds
    if (options.HasOwnProp("waitSeconds"))
        return options.waitSeconds
    if (options.HasOwnProp("waitml"))
        return options.waitml / 1000
    return ""
}

MenuWhichKeyGetIdleTimeoutSeconds(options) {
    if (options.HasOwnProp("idleTimeoutSeconds"))
        return options.idleTimeoutSeconds
    return ""
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
            MenuWhichKeyApplyEntryTiming(entry, item)
        } else {
            entry := ChordEntry(fullLegacyKey, entryLabel)
        }

        MenuWhichKeyInsertEntry(chordItems, chordPath, entry, item)
    }

    return chordItems
}

MenuWhichKeyApplyEntryTiming(entry, item) {
    showDelaySeconds := MenuWhichKeyGetShowDelaySeconds(item)
    if (showDelaySeconds != "")
        entry.hintDelay := showDelaySeconds

    idleTimeoutSeconds := MenuWhichKeyGetIdleTimeoutSeconds(item)
    if (idleTimeoutSeconds != "")
        entry.timeout := idleTimeoutSeconds
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

    keySpec := item.key
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

