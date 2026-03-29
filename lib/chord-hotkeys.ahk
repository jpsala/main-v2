#Include ".\WebViewToo.ahk"

; Chord Hotkeys Module
; Standalone two-step hotkeys with optional which-key style hints.
;
; Self-contained by design:
; - no dependency on repo logging, config, theme, or utility helpers
; - only depends on AutoHotkey v2 plus WebView2/WebViewToo for hint rendering
;
; Minimal API:
; - ChordRegister(prefixMap, executeFn)
; - ChordUnregisterAll()
; - ChordSetTimeout(seconds)
; - ChordSetHintDelay(seconds)
; - ChordEntry(command, label := "")
; - ChordSetHintLabelResolver(fn)
; - ChordSetDebugLogger(fn)
;
; Example:
; prefixMap := Map(
;     "!q", Map(
;         "r", ChordEntry("reload", "Reload"),
;         "s", ChordEntry("settings", "Settings")
;     )
; )
; ChordRegister(prefixMap, HandleChordCommand)

global CHORD_PREFIX_MAP := Map()
global CHORD_PREFIX_HOTKEY_MAP := Map()
global CHORD_PREFIX_SETTINGS := Map()
global CHORD_PENDING_PREFIX := ""
global CHORD_PENDING_UNTIL := 0
global CHORD_PENDING_ITEMS := 0
global CHORD_PENDING_HINT_DELAY_MS := 0
global CHORD_PENDING_PATH := []
global CHORD_TIMEOUT_SEC := 2.2
global CHORD_HINT_DELAY_SEC := 0.55
global CHORD_HINT_GUI := 0
global CHORD_HINT_READY := false
global CHORD_HINT_LABEL_RESOLVER := ""
global CHORD_ACTIVE_IH := 0
global CHORD_MOUSE_RESULT := ""
global CHORD_DEBUG_LOGGER := ""

ChordEntry(command, label := "", executeFn?) {
    entry := { command: command }
    if (label != "")
        entry.label := label
    if (IsSet(executeFn) && IsObject(executeFn))
        entry.executeFn := executeFn
    return entry
}

ChordSetDebugLogger(loggerFn) {
    global CHORD_DEBUG_LOGGER
    CHORD_DEBUG_LOGGER := loggerFn
}

ChordDebug(message) {
    global CHORD_DEBUG_LOGGER
    if IsObject(CHORD_DEBUG_LOGGER)
        CHORD_DEBUG_LOGGER.Call(message)
}

ChordJoin(parts, separator := "") {
    out := ""
    for index, part in parts {
        if (index > 1)
            out .= separator
        out .= part
    }
    return out
}

ChordCloneList(parts) {
    out := []
    for _, part in parts
        out.Push(part)
    return out
}

ChordAppendChars(targetList, text, prefix := "") {
    Loop StrLen(text)
        targetList.Push(prefix . SubStr(text, A_Index, 1))
}

ChordSymbolToShiftedKey(symbol) {
    static symbolMap := Map(
        "!", "+1",
        "@", "+2",
        "#", "+3",
        "$", "+4",
        "%", "+5",
        "^", "+6",
        "&", "+7",
        "*", "+8",
        "(", "+9",
        ")", "+0",
        "_", "+-",
        "+", "+=",
        "{", "+[",
        "}", "+]",
        ":", "+;",
        Chr(34), "+'",
        "<", "+,",
        ">", "+.",
        "?", "+/"
    )

    if symbolMap.Has(symbol)
        return symbolMap[symbol]
    return ""
}

ChordShiftedKeyToSymbol(suffixKey) {
    static reverseMap := Map(
        "+1", "!",
        "+2", "@",
        "+3", "#",
        "+4", "$",
        "+5", "%",
        "+6", "^",
        "+7", "&",
        "+8", "*",
        "+9", "(",
        "+0", ")",
        "+-", "_",
        "+=", "+",
        "+[", "{",
        "+]", "}",
        "+;", ":",
        "+'", Chr(34),
        "+,", "<",
        "+.", ">",
        "+/", "?"
    )

    if reverseMap.Has(suffixKey)
        return reverseMap[suffixKey]
    return ""
}

ChordBuildCandidateSuffixKeys() {
    keys := []

    ChordAppendChars(keys, "abcdefghijklmnopqrstuvwxyz")
    ChordAppendChars(keys, "0123456789")
    ChordAppendChars(keys, "abcdefghijklmnopqrstuvwxyz", "+")
    ChordAppendChars(keys, "0123456789", "+")

    ; Esc is reserved for "back/cancel" navigation and is handled separately.
    extras := ["space", "tab", "enter", "backspace", "delete", "insert", "home", "end", "pgup", "pgdn", "up", "down", "left", "right", "-", "=", "[", "]", ";", "'", ",", ".", "/"]
    for _, keyName in extras
        keys.Push(keyName)

    shiftedExtras := ["+-", "+=", "+[", "+]", "+;", "+'", "+,", "+.", "+/"]
    for _, keyName in shiftedExtras
        keys.Push(keyName)

    return keys
}

ChordSortRowsByKey(rows) {
    rowCount := rows.Length
    if (rowCount <= 1)
        return rows

    loop rowCount - 1 {
        i := A_Index
        minIndex := i
        j := i + 1
        while (j <= rowCount) {
            if (StrCompare(rows[j].key, rows[minIndex].key) < 0)
                minIndex := j
            j += 1
        }
        if (minIndex != i) {
            temp := rows[i]
            rows[i] := rows[minIndex]
            rows[minIndex] := temp
        }
    }

    return rows
}

ChordSetTimeout(timeoutSeconds) {
    global CHORD_TIMEOUT_SEC
    if (timeoutSeconds > 0)
        CHORD_TIMEOUT_SEC := timeoutSeconds
}

ChordSetHintDelay(delaySeconds) {
    global CHORD_HINT_DELAY_SEC
    if (delaySeconds >= 0)
        CHORD_HINT_DELAY_SEC := delaySeconds
}

ChordGetTimeoutMs(prefixHotkey := "") {
    global CHORD_TIMEOUT_SEC, CHORD_PREFIX_SETTINGS
    if (prefixHotkey != "" && CHORD_PREFIX_SETTINGS.Has(prefixHotkey)) {
        settings := CHORD_PREFIX_SETTINGS[prefixHotkey]
        if (settings.HasOwnProp("timeout"))
            return Max(0, Round(settings.timeout * 1000))
    }
    return Max(0, Round(CHORD_TIMEOUT_SEC * 1000))
}

ChordGetHintDelayMs(prefixHotkey := "") {
    global CHORD_HINT_DELAY_SEC, CHORD_PREFIX_SETTINGS
    if (prefixHotkey != "" && CHORD_PREFIX_SETTINGS.Has(prefixHotkey)) {
        settings := CHORD_PREFIX_SETTINGS[prefixHotkey]
        if (settings.HasOwnProp("hintDelay"))
            return Max(0, Round(settings.hintDelay * 1000))
    }
    return Max(0, Round(CHORD_HINT_DELAY_SEC * 1000))
}

ChordGetVisibleHintMs(prefixHotkey := "") {
    return ChordGetTimeoutMs(prefixHotkey)
}

ChordGetTotalPendingMs(prefixHotkey := "") {
    return ChordGetHintDelayMs(prefixHotkey) + ChordGetVisibleHintMs(prefixHotkey)
}

ChordSecondsToMs(seconds, fallbackMs := 0) {
    if (seconds = "")
        return fallbackMs
    return Max(0, Round(seconds * 1000))
}

ChordSetHintLabelResolver(labelResolverFn) {
    global CHORD_HINT_LABEL_RESOLVER
    CHORD_HINT_LABEL_RESOLVER := labelResolverFn
}

ChordUnregisterAll() {
    global CHORD_PREFIX_MAP, CHORD_PREFIX_HOTKEY_MAP, CHORD_PREFIX_SETTINGS

    for prefixHotkey, _ in CHORD_PREFIX_HOTKEY_MAP {
        if (prefixHotkey != "")
            try Hotkey(prefixHotkey, "Off")
    }

    CHORD_PREFIX_MAP := Map()
    CHORD_PREFIX_HOTKEY_MAP := Map()
    CHORD_PREFIX_SETTINGS := Map()
    ChordClearPending()
    ChordHideHint()
}

ChordRegister(prefixMap, executeFn, registerOptions?) {
    global CHORD_PREFIX_MAP, CHORD_PREFIX_HOTKEY_MAP, CHORD_PREFIX_SETTINGS

    ChordDebug("ChordRegister called with " . prefixMap.Count . " prefixes")
    for prefix, suffixMap in prefixMap {
        ChordDebug("  Prefix: " . prefix . " with " . suffixMap.Count . " suffixes")
        for suffix, entry in suffixMap
            ChordDebug("    " . prefix . "," . suffix . " -> " . ChordEntryGetCommand(entry))
    }

    for prefixKey, suffixMap in prefixMap {
        if !CHORD_PREFIX_MAP.Has(prefixKey)
            CHORD_PREFIX_MAP[prefixKey] := Map()

        for suffixKey, entry in suffixMap
            CHORD_PREFIX_MAP[prefixKey][suffixKey] := ChordNormalizeEntry(entry, executeFn)

        CHORD_PREFIX_SETTINGS[prefixKey] := ChordNormalizeRegisterOptions(registerOptions)

        registeredPrefix := ChordEnsureHookHotkey(prefixKey)
        if !CHORD_PREFIX_HOTKEY_MAP.Has(registeredPrefix) {
            ChordDebug("Registering prefix: " . prefixKey . " -> " . registeredPrefix)
            try {
                Hotkey(registeredPrefix, ChordHandlePrefix.Bind(prefixKey))
                CHORD_PREFIX_HOTKEY_MAP[registeredPrefix] := true
                ChordDebug("  -> SUCCESS registered prefix")
            } catch as err {
                ChordDebug("  -> ERROR registering prefix: " . err.Message)
            }
        }
    }

}

ChordNormalizeRegisterOptions(registerOptions?) {
    settings := {}

    if !(IsSet(registerOptions) && IsObject(registerOptions))
        return settings

    if (registerOptions.HasOwnProp("hintDelay"))
        settings.hintDelay := registerOptions.hintDelay
    if (registerOptions.HasOwnProp("timeout"))
        settings.timeout := registerOptions.timeout
    if (registerOptions.HasOwnProp("prefixLabel"))
        settings.prefixLabel := registerOptions.prefixLabel

    return settings
}

ChordNormalizeEntry(entry, executeFn?) {
    if IsObject(entry) {
        normalized := {}
        for propName, propValue in entry.OwnProps()
            normalized.%propName% := propValue
        if (!normalized.HasOwnProp("command") && normalized.HasOwnProp("name"))
            normalized.command := normalized.name
        if (normalized.HasOwnProp("items") && IsObject(normalized.items)) {
            normalizedItems := Map()
            for suffixKey, childEntry in normalized.items
                normalizedItems[ChordNormalizeSuffixKey(suffixKey)] := ChordNormalizeEntry(childEntry, executeFn)
            normalized.items := normalizedItems
        }
        if (IsSet(executeFn) && IsObject(executeFn) && !normalized.HasOwnProp("executeFn"))
            normalized.executeFn := executeFn
        return normalized
    }

    normalized := { command: entry }
    if (IsSet(executeFn) && IsObject(executeFn))
        normalized.executeFn := executeFn
    return normalized
}

ChordCollectSuffixes(items, uniqueSuffixes) {
    for suffixKey, entry in items {
        if (suffixKey = "esc")
            continue
        uniqueSuffixes[suffixKey] := true
        childItems := ChordEntryGetItems(entry)
        if (IsObject(childItems) && childItems.Count > 0)
            ChordCollectSuffixes(childItems, uniqueSuffixes)
    }
}

ChordTryParseHotkeySpec(hotkeySpec, &prefixHotkeyOut, &suffixKeyOut) {
    prefixHotkeyOut := ""
    suffixKeyOut := ""

    spec := Trim(hotkeySpec)
    if (spec = "")
        return false

    ; Try arrow syntax first
    if RegExMatch(spec, "i)^\s*(.+?)\s*->\s*(.+?)\s*$", &mArrow) {
        prefixHotkey := ChordNormalizeDisplayHotkeyToAhk(mArrow[1])
        if (prefixHotkey = "")
            prefixHotkey := Trim(mArrow[1])
        suffixKey := ChordNormalizeSuffixKey(mArrow[2])
        if (prefixHotkey != "" && suffixKey != "") {
            prefixHotkeyOut := prefixHotkey
            suffixKeyOut := suffixKey
            return true
        }
        return false
    }

    ; Try comma syntax
    commaPos := InStr(spec, ",")
    if (commaPos <= 0)
        return false

    prefixCandidate := Trim(SubStr(spec, 1, commaPos - 1))
    prefixHotkey := ChordNormalizeDisplayHotkeyToAhk(prefixCandidate)
    if (prefixHotkey = "")
        prefixHotkey := prefixCandidate
    
    suffixKey := Trim(SubStr(spec, commaPos + 1))
    suffixKey := ChordNormalizeSuffixKey(suffixKey)

    if (prefixHotkey = "" || suffixKey = "")
        return false

    prefixHotkeyOut := prefixHotkey
    suffixKeyOut := suffixKey
    return true
}

ChordNormalizeDisplayHotkeyToAhk(displayHotkey) {
    raw := Trim(displayHotkey)
    if (raw = "")
        return ""
    if RegExMatch(raw, "^\s*\+")
        return Trim(raw)

    ; Keep plain AHK notation unchanged.
    if RegExMatch(raw, "[\^\!\#]") {
        if RegExMatch(raw, "^\s*\+")
            return Trim(raw)
        if InStr(raw, " ")
            return ""
        return Trim(raw)
    }

    mods := ""
    keyName := ""
    for _, token in StrSplit(raw, "+") {
        t := StrLower(Trim(token))
        if (t = "")
            continue
        switch t {
        case "ctrl", "control":
            mods .= "^"
        case "alt":
            mods .= "!"
        case "shift":
            mods .= "+"
        case "win", "meta", "cmd", "command":
            mods .= "#"
        default:
            keyName := t
        }
    }

    if (keyName = "")
        return ""

    normalizedKey := ChordNormalizeSuffixKey(keyName)
    if (normalizedKey = "")
        return ""
    if (normalizedKey = "esc")
        normalizedKey := "Esc"
    else if (normalizedKey = "pgup")
        normalizedKey := "PgUp"
    else if (normalizedKey = "pgdn")
        normalizedKey := "PgDn"
    else if (normalizedKey = "space")
        normalizedKey := "Space"
    else if (normalizedKey = "up")
        normalizedKey := "Up"
    else if (normalizedKey = "down")
        normalizedKey := "Down"
    else if (normalizedKey = "left")
        normalizedKey := "Left"
    else if (normalizedKey = "right")
        normalizedKey := "Right"
    else if (normalizedKey = "home")
        normalizedKey := "Home"
    else if (normalizedKey = "end")
        normalizedKey := "End"
    else if (normalizedKey = "tab")
        normalizedKey := "Tab"
    else if (normalizedKey = "enter")
        normalizedKey := "Enter"
    else if (normalizedKey = "backspace")
        normalizedKey := "Backspace"
    else if (normalizedKey = "delete")
        normalizedKey := "Delete"
    else if (normalizedKey = "insert")
        normalizedKey := "Insert"
    else if RegExMatch(normalizedKey, "^f([1-9]|1[0-2])$")
        normalizedKey := StrUpper(normalizedKey)

    return mods . normalizedKey
}

ChordNormalizeSuffixKey(keySpec) {
    key := Trim(keySpec)
    if (key = "")
        return ""

    mods := ""
    while (key != "") {
        firstChar := SubStr(key, 1, 1)
        if (firstChar = "^" || firstChar = "!" || firstChar = "+" || firstChar = "#") {
            mods .= firstChar
            key := SubStr(key, 2)
            continue
        }
        break
    }

    key := Trim(key)
    if (key = "")
        return ""

    if (StrLen(key) = 1) {
        if RegExMatch(key, "^[A-Z]$")
            return mods . "+" . StrLower(key)

        shiftedKey := ChordSymbolToShiftedKey(key)
        if (shiftedKey != "")
            return mods . shiftedKey

        return mods . key
    }

    lower := StrLower(key)
    switch lower {
    case "esc", "escape":
        return mods . "esc"
    case "space", "spacebar":
        return mods . "space"
    case "pgup", "pageup":
        return mods . "pgup"
    case "pgdn", "pagedown":
        return mods . "pgdn"
    case "up", "arrowup":
        return mods . "up"
    case "down", "arrowdown":
        return mods . "down"
    case "left", "arrowleft":
        return mods . "left"
    case "right", "arrowright":
        return mods . "right"
    case "tab":
        return mods . "tab"
    case "enter", "return":
        return mods . "enter"
    case "backspace":
        return mods . "backspace"
    case "delete", "del":
        return mods . "delete"
    case "insert", "ins":
        return mods . "insert"
    case "home":
        return mods . "home"
    case "end":
        return mods . "end"
    }

    if RegExMatch(lower, "^f([1-9]|1[0-2])$")
        return mods . lower
    return ""
}

ChordBuildSuffixHotkey(suffixKey) {
    if RegExMatch(suffixKey, "^[\^\!\+\#]+.+$")
        return "$*" . suffixKey

    switch suffixKey {
    case "esc":
        return "$*Esc"
    case "space":
        return "$*Space"
    case "pgup":
        return "$*PgUp"
    case "pgdn":
        return "$*PgDn"
    case "up":
        return "$*Up"
    case "down":
        return "$*Down"
    case "left":
        return "$*Left"
    case "right":
        return "$*Right"
    case "tab":
        return "$*Tab"
    case "enter":
        return "$*Enter"
    case "backspace":
        return "$*Backspace"
    case "delete":
        return "$*Delete"
    case "insert":
        return "$*Insert"
    case "home":
        return "$*Home"
    case "end":
        return "$*End"
    default:
        if RegExMatch(suffixKey, "^f([1-9]|1[0-2])$")
            return "$*" . StrUpper(suffixKey)
        if (StrLen(suffixKey) = 1)
            return "$*" . suffixKey
    }
    return ""
}

ChordEnsureHookHotkey(hotkeySpec) {
    key := Trim(hotkeySpec)
    if (key = "")
        return ""
    if (SubStr(key, 1, 1) = "$")
        return key
    return "$" . key
}

ChordClearPending(*) {
    global CHORD_PENDING_PREFIX, CHORD_PENDING_UNTIL, CHORD_PENDING_ITEMS, CHORD_PENDING_HINT_DELAY_MS, CHORD_PENDING_PATH
    try SetTimer(ChordClearPending, 0)
    CHORD_PENDING_PREFIX := ""
    CHORD_PENDING_UNTIL := 0
    CHORD_PENDING_ITEMS := 0
    CHORD_PENDING_HINT_DELAY_MS := 0
    CHORD_PENDING_PATH := []
    ChordHideHint()
}

ChordHandlePrefix(prefixHotkey, *) {
    global CHORD_PREFIX_MAP
    if !CHORD_PREFIX_MAP.Has(prefixHotkey) {
        ChordDebug("prefix not registered: " . prefixHotkey)
        return
    }

    ChordDebug("prefix triggered: " . prefixHotkey)
    ChordRunPendingSession(prefixHotkey, CHORD_PREFIX_MAP[prefixHotkey])
}

ChordSetPendingState(prefixHotkey, items, path, timeoutMs, hintDelayMs := 0) {
    global CHORD_PENDING_PREFIX, CHORD_PENDING_UNTIL, CHORD_PENDING_ITEMS, CHORD_PENDING_HINT_DELAY_MS, CHORD_PENDING_PATH
    CHORD_PENDING_PREFIX := prefixHotkey
    CHORD_PENDING_ITEMS := items
    CHORD_PENDING_HINT_DELAY_MS := hintDelayMs
    CHORD_PENDING_PATH := ChordCloneList(path)
    CHORD_PENDING_UNTIL := A_TickCount + Max(0, timeoutMs)
}

ChordNormalizeCapturedInput(ih) {
    inputText := ih.Input
    endKey := StrLower(ih.EndKey)

    if (inputText = "␛" || endKey = "escape" || endKey = "esc")
        return "esc"
    if (inputText = A_Space || endKey = "space")
        return "space"
    if (inputText = "`t" || endKey = "tab")
        return "tab"
    if (inputText = "`r" || inputText = "`n" || endKey = "enter" || endKey = "return")
        return "enter"
    if (endKey = "backspace")
        return "backspace"
    if (endKey = "delete" || endKey = "del")
        return "delete"
    if (endKey = "insert" || endKey = "ins")
        return "insert"
    if (endKey = "home")
        return "home"
    if (endKey = "end")
        return "end"
    if (endKey = "pgup" || endKey = "pageup")
        return "pgup"
    if (endKey = "pgdn" || endKey = "pagedown")
        return "pgdn"
    if (endKey = "up")
        return "up"
    if (endKey = "down")
        return "down"
    if (endKey = "left")
        return "left"
    if (endKey = "right")
        return "right"
    if (inputText = "")
        return ""
    return ChordNormalizeSuffixKey(inputText)
}

ChordCaptureInput(timeoutMs) {
    global CHORD_ACTIVE_IH, CHORD_MOUSE_RESULT

    if (timeoutMs <= 0)
        return ""

    CHORD_MOUSE_RESULT := ""
    secs := timeoutMs / 1000
    ih := InputHook("L1 M T" . secs)
    CHORD_ACTIVE_IH := ih
    ChordMouseHookInstall()
    ih.Start()
    ih.Wait()
    ChordMouseHookRemove()
    CHORD_ACTIVE_IH := 0

    if (CHORD_MOUSE_RESULT != "")
        return CHORD_MOUSE_RESULT

    return ChordNormalizeCapturedInput(ih)
}

ChordWaitForStep(prefixHotkey, items, path, hintDelayMs := 0) {
    visibleHintMs := ChordGetVisibleHintMs(prefixHotkey)
    ChordDebug("waiting for step: " . prefixHotkey . " path=" . ChordJoin(path, ">") . " hintDelayMs=" . hintDelayMs . " visibleHintMs=" . visibleHintMs)

    if (hintDelayMs > 0) {
        ChordSetPendingState(prefixHotkey, items, path, hintDelayMs, hintDelayMs)
        ChordHideHint()
        earlyKey := ChordCaptureInput(hintDelayMs)
        ChordDebug("early key: " . (earlyKey != "" ? earlyKey : "<none>"))
        if (earlyKey != "")
            return earlyKey
    }

    if (visibleHintMs <= 0)
        return ""

    ChordSetPendingState(prefixHotkey, items, path, visibleHintMs, hintDelayMs)
    ChordShowHint(prefixHotkey, items, path)
    key := ChordCaptureInput(visibleHintMs)
    ChordDebug("captured key: " . (key != "" ? key : "<none>"))
    return key
}

ChordRunPendingSession(prefixHotkey, rootItems) {
    currentItems := rootItems
    currentPath := []
    currentHintDelayMs := ChordGetHintDelayMs(prefixHotkey)
    ChordDebug("session start: " . prefixHotkey)

    while true {
        key := ChordWaitForStep(prefixHotkey, currentItems, currentPath, currentHintDelayMs)
        if (key = "") {
            ChordDebug("session timeout/empty: " . prefixHotkey)
            ChordClearPending()
            return
        }

        if (key = "esc") {
            if (currentPath.Length = 0) {
                ChordDebug("session cancelled at root: " . prefixHotkey)
                ChordClearPending()
                return
            }

            currentPath.Pop()
            currentItems := ChordGetItemsForPath(prefixHotkey, currentPath)
            if !IsObject(currentItems) {
                ChordDebug("session invalid path after esc: " . prefixHotkey)
                ChordClearPending()
                return
            }
            currentHintDelayMs := ChordGetHintDelayForPath(prefixHotkey, currentPath)
            ChordDebug("session backtrack: " . prefixHotkey . " path=" . ChordJoin(currentPath, ">"))
            continue
        }

        if !currentItems.Has(key) {
            ChordDebug("session invalid key: " . prefixHotkey . " key=" . key)
            ChordClearPending()
            return
        }

        entry := currentItems[key]
        childItems := ChordEntryGetItems(entry)
        if (IsObject(childItems) && childItems.Count > 0) {
            currentPath.Push(key)
            currentItems := childItems
            currentHintDelayMs := ChordEntryGetHintDelayMs(entry, 0)
            ChordDebug("session enter submenu: " . prefixHotkey . " path=" . ChordJoin(currentPath, ">"))
            continue
        }

        ChordClearPending()
        commandName := ChordEntryGetCommand(entry)
        ChordDebug("session execute: " . prefixHotkey . " command=" . commandName)
        executeFn := ""
        if IsObject(entry) && entry.HasOwnProp("executeFn")
            executeFn := entry.executeFn
        if IsObject(executeFn)
            SetTimer(executeFn.Bind(commandName), -1)
        return
    }
}

ChordEntryGetCommand(entry) {
    if IsObject(entry) {
        if entry.HasOwnProp("command")
            return entry.command
        if entry.HasOwnProp("name")
            return entry.name
        if entry.HasOwnProp("items")
            return "<submenu>"
    }
    return entry
}

ChordEntryGetLabel(entry, suffixKey := "") {
    global CHORD_HINT_LABEL_RESOLVER

    if IsObject(entry) {
        if entry.HasOwnProp("label")
            return "" . entry.label
        if entry.HasOwnProp("title")
            return "" . entry.title
    }

    commandName := ChordEntryGetCommand(entry)
    if IsObject(CHORD_HINT_LABEL_RESOLVER)
        return CHORD_HINT_LABEL_RESOLVER.Call(commandName, suffixKey, entry)
    return "" . commandName
}

ChordEntryGetItems(entry) {
    if IsObject(entry) && entry.HasOwnProp("items") && IsObject(entry.items)
        return entry.items
    return 0
}

ChordEntryGetHintDelayMs(entry, defaultMs := 0) {
    if IsObject(entry) && entry.HasOwnProp("hintDelay")
        return ChordSecondsToMs(entry.hintDelay, defaultMs)
    return defaultMs
}

ChordHintInit() {
    global CHORD_HINT_GUI, CHORD_HINT_READY

    if IsObject(CHORD_HINT_GUI)
        return

    CHORD_HINT_READY := false
    dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
    CHORD_HINT_GUI := WebViewGui("+AlwaysOnTop -Caption +ToolWindow -DPIScale", "Chord Hint",, {DllPath: dllPath, DefaultWidth: 240, DefaultHeight: 160})
    CHORD_HINT_GUI.OnEvent("Close", (*) => ChordHideHint())

    if (A_IsCompiled)
        CHORD_HINT_GUI.Control.BrowseFolder(A_ScriptDir)

    CHORD_HINT_GUI.Control.DefaultBackgroundColor := "11111d"
    CHORD_HINT_GUI.Control.wv.add_NavigationCompleted(ChordHintNavigationCompleted)
    CHORD_HINT_GUI.Control.wv.add_WebMessageReceived(ChordHintHandleMessage)
    CHORD_HINT_GUI.Navigate("ui/chord-hint.html")
}

ChordHintNavigationCompleted(wv, args) {
    global CHORD_HINT_READY := true
}

ChordHintWaitUntilReady(timeoutMs := 1200) {
    global CHORD_HINT_READY

    waitStart := A_TickCount
    while (!CHORD_HINT_READY && (A_TickCount - waitStart) < timeoutMs)
        Sleep(15)

    return CHORD_HINT_READY
}

ChordHintEscapeString(value) {
    text := "" . value
    text := StrReplace(text, "\", "\\")
    text := StrReplace(text, '"', '\"')
    text := StrReplace(text, "`r", "\r")
    text := StrReplace(text, "`n", "\n")
    text := StrReplace(text, "`t", "\t")
    return '"' . text . '"'
}

ChordHintBuildJSON(prefixText, rows, columns := 1, rowsHeight := 0) {
    json := '{"prefix":' . ChordHintEscapeString(prefixText)
    json .= ',"columns":' . columns
    json .= ',"rowsHeight":' . rowsHeight
    json .= ',"entries":['
    for index, row in rows {
        if (index > 1)
            json .= ","
        json .= '{"key":' . ChordHintEscapeString(row.key)
        json .= ',"rawKey":' . ChordHintEscapeString(row.rawKey)
        json .= ',"label":' . ChordHintEscapeString(row.label)
        json .= ',"submenu":' . (row.submenu ? "true" : "false")
        json .= "}"
    }
    json .= "]}"
    return json
}

ChordFormatPrefixForHint(prefixHotkey) {
    global CHORD_PREFIX_SETTINGS

    if (prefixHotkey != "" && CHORD_PREFIX_SETTINGS.Has(prefixHotkey)) {
        settings := CHORD_PREFIX_SETTINGS[prefixHotkey]
        if (settings.HasOwnProp("prefixLabel") && settings.prefixLabel != "")
            return settings.prefixLabel
    }

    hotkey := prefixHotkey
    if (SubStr(hotkey, 1, 1) = "$")
        hotkey := SubStr(hotkey, 2)

    mods := []
    while (hotkey != "") {
        ch := SubStr(hotkey, 1, 1)
        switch ch {
        case "^":
            mods.Push("Ctrl")
            hotkey := SubStr(hotkey, 2)
        case "!":
            mods.Push("Alt")
            hotkey := SubStr(hotkey, 2)
        case "+":
            mods.Push("Shift")
            hotkey := SubStr(hotkey, 2)
        case "#":
            mods.Push("Win")
            hotkey := SubStr(hotkey, 2)
        default:
            break
        }
    }

    keyName := hotkey
    if (StrLen(keyName) = 1)
        keyName := StrUpper(keyName)
    display := mods.Length ? ChordJoin(mods, "+") . "+" . keyName : keyName
    return StrUpper(display)
}

ChordBuildHintPrefixText(prefixHotkey, path) {
    prefixText := ChordFormatPrefixForHint(prefixHotkey)
    for _, stepKey in path
        prefixText .= " > " . ChordFormatSuffixForHint(stepKey)
    return prefixText
}

ChordGetItemsForPath(prefixHotkey, path) {
    global CHORD_PREFIX_MAP

    if !CHORD_PREFIX_MAP.Has(prefixHotkey)
        return 0

    items := CHORD_PREFIX_MAP[prefixHotkey]
    for _, stepKey in path {
        if !items.Has(stepKey)
            return 0
        items := ChordEntryGetItems(items[stepKey])
        if !IsObject(items)
            return 0
    }
    return items
}

ChordGetHintDelayForPath(prefixHotkey, path) {
    global CHORD_PREFIX_MAP

    if (path.Length = 0)
        return ChordGetHintDelayMs(prefixHotkey)
    if !CHORD_PREFIX_MAP.Has(prefixHotkey)
        return 0

    items := CHORD_PREFIX_MAP[prefixHotkey]
    lastEntry := 0
    for _, stepKey in path {
        if !items.Has(stepKey)
            return 0
        lastEntry := items[stepKey]
        items := ChordEntryGetItems(lastEntry)
        if !IsObject(items)
            break
    }

    if IsObject(lastEntry)
        return ChordEntryGetHintDelayMs(lastEntry, 0)
    return 0
}

ChordFormatSuffixForHint(suffixKey) {
    if RegExMatch(suffixKey, "^([\^\!\+\#]*)(.+)$", &m) {
        mods := m[1]
        base := m[2]

        if (mods = "+") {
            shiftedSymbol := ChordShiftedKeyToSymbol(suffixKey)
            if (shiftedSymbol != "")
                return shiftedSymbol
            if RegExMatch(base, "^[a-z]$")
                return StrUpper(base)
        }

        if (mods != "") {
            modParts := []
            Loop StrLen(mods) {
                modChar := SubStr(mods, A_Index, 1)
                switch modChar {
                case "^":
                    modParts.Push("Ctrl")
                case "!":
                    modParts.Push("Alt")
                case "+":
                    modParts.Push("Shift")
                case "#":
                    modParts.Push("Win")
                }
            }

            baseText := ChordFormatSuffixForHint(base)
            return ChordJoin(modParts, "+") . "+" . baseText
        }
    }

    switch suffixKey {
    case "esc":
        return "Esc"
    case "space":
        return "Space"
    case "pgup":
        return "PgUp"
    case "pgdn":
        return "PgDn"
    case "up":
        return "Up"
    case "down":
        return "Down"
    case "left":
        return "Left"
    case "right":
        return "Right"
    case "tab":
        return "Tab"
    case "enter":
        return "Enter"
    case "backspace":
        return "Backspace"
    case "delete":
        return "Delete"
    case "insert":
        return "Insert"
    case "home":
        return "Home"
    case "end":
        return "End"
    default:
        if RegExMatch(suffixKey, "^f([1-9]|1[0-2])$")
            return StrUpper(suffixKey)
        if (StrLen(suffixKey) = 1)
            return suffixKey
    }
    return suffixKey
}

ChordShowHint(prefixHotkey, items, path) {
    global CHORD_HINT_GUI

    if !IsObject(items)
        return

    if (items.Count = 0)
        return

    rows := []
    for suffixKey, entry in items {
        keyText := ChordFormatSuffixForHint(suffixKey)
        labelText := ChordEntryGetLabel(entry, suffixKey)
        rows.Push({
            key: keyText,
            rawKey: suffixKey,
            label: labelText,
            submenu: IsObject(ChordEntryGetItems(entry))
        })
    }

    ChordSortRowsByKey(rows)

    baseWidth := 240
    columnGap := 14
    rowHeight := 30
    headerHeight := 22
    paddingY := 26
    bottomMargin := 60
    topMargin := 32
    availableHeight := Max(160, A_ScreenHeight - bottomMargin - topMargin)
    rowsPerColumn := Max(1, Floor((availableHeight - paddingY - headerHeight) / rowHeight))
    columns := Max(1, Ceil(rows.Length / rowsPerColumn))
    usedRows := Min(rows.Length, rowsPerColumn)
    rowsHeight := usedRows * rowHeight
    width := (baseWidth * columns) + (columnGap * Max(0, columns - 1))
    height := paddingY + headerHeight + rowsHeight
    prefixText := ChordBuildHintPrefixText(prefixHotkey, path)
    hintJson := ChordHintBuildJSON(prefixText, rows, columns, rowsHeight)

    cm := CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    CoordMode("Mouse", cm)

    monLeft := 0, monTop := 0, monRight := A_ScreenWidth, monBottom := A_ScreenHeight
    loop MonitorGetCount() {
        MonitorGet(A_Index, &mL, &mT, &mR, &mB)
        if (mouseX >= mL && mouseX <= mR && mouseY >= mT && mouseY <= mB) {
            monLeft := mL, monTop := mT, monRight := mR, monBottom := mB
            break
        }
    }
    screenW := monRight - monLeft
    screenH := monBottom - monTop

    x := monLeft + Max(0, Min(mouseX - monLeft - Round(width / 2), screenW - width))
    yAbove := mouseY - height - 12
    yBelow := mouseY + 12
    y := (yAbove >= monTop + topMargin) ? yAbove : Min(yBelow, monBottom - height - bottomMargin)

    ChordHintInit()
    if !ChordHintWaitUntilReady()
        return

    CHORD_HINT_GUI.Show("NoActivate x" x " y" y " w" width " h" height)
    try WinSetRegion("0-0 W" width " H" height " R12-12", "ahk_id " . CHORD_HINT_GUI.Hwnd)
    try CHORD_HINT_GUI.Control.ExecuteScript("window.renderChordHint(" . hintJson . ");")
}

ChordMouseHookInstall() {
    Hotkey("~LButton", ChordMouseClickHandler, "On")
}

ChordMouseHookRemove() {
    try Hotkey("~LButton", ChordMouseClickHandler, "Off")
}

ChordMouseClickHandler(*) {
    global CHORD_HINT_GUI, CHORD_ACTIVE_IH

    if !IsObject(CHORD_ACTIVE_IH)
        return

    if IsObject(CHORD_HINT_GUI) {
        try {
            hwnd := CHORD_HINT_GUI.Hwnd
            CoordMode("Mouse", "Screen")
            MouseGetPos(&mx, &my)
            WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " . hwnd)
            if (mx >= wx && mx <= wx + ww && my >= wy && my <= wy + wh)
                return
        }
    }

    CHORD_ACTIVE_IH.Stop()
}

ChordHintHandleMessage(wv, args) {
    global CHORD_ACTIVE_IH, CHORD_MOUSE_RESULT

    try {
        msg := args.TryGetWebMessageAsString()
        CHORD_MOUSE_RESULT := ChordNormalizeSuffixKey(msg)
        if (IsObject(CHORD_ACTIVE_IH))
            CHORD_ACTIVE_IH.Stop()
    }
}

ChordHideHint() {
    global CHORD_HINT_GUI

    if (CHORD_HINT_GUI) {
        try CHORD_HINT_GUI.Hide()
    }
}
