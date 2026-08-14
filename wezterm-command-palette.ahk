global WEZTERM_COMMAND_PALETTE_CATALOG_PATH := "C:\dev\wezterm\config\command-menu.json"
global WEZTERM_COMMAND_PALETTE_PROJECTS_PATH := "C:\dev\wezterm\OMP-PROJECTS.md"
global WEZTERM_COMMAND_PALETTE_CATALOG_VERSION := 1
global WEZTERM_COMMAND_PALETTE_TARGET := 0
global WEZTERM_COMMAND_PALETTE_SNAPSHOT_FINGERPRINT := ""
global WEZTERM_COMMAND_PALETTE_TARGET_GENERATION := 0
global WEZTERM_COMMAND_PALETTE_TARGET_TOKENS := Map()
global WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK := 0
global WEZTERM_COMMAND_PALETTE_LIFECYCLE_INSTALLED := false
global WEZTERM_COMMAND_PALETTE_ACTIVATE_TIMEOUT_SECONDS := 0.75
global WEZTERM_COMMAND_PALETTE_MODIFIER_TIMEOUT_MS := 1500
global WEZTERM_COMMAND_PALETTE_BRIDGE_PATH := "C:\dev\wezterm\state\wezterm-command-bridge.txt"
global WEZTERM_COMMAND_PALETTE_BRIDGE_VERSION := 2
global WEZTERM_COMMAND_PALETTE_BRIDGE_MAX_FRAME_BYTES := 512
global WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY := ""
global WEZTERM_COMMAND_PALETTE_ACK_TIMEOUT_MS := 500
global WEZTERM_COMMAND_PALETTE_REQUEST_TTL_SECONDS := 4
global WEZTERM_COMMAND_PALETTE_POLL_INTERVAL_MS := 10
global WEZTERM_COMMAND_PALETTE_ENTRIES := []
global WEZTERM_COMMAND_PALETTE_ACTION_PATHS := Map()
global WEZTERM_COMMAND_PALETTE_OPEN_MESSAGE_INSTALLED := false

InitWezTermCommandPalette() {
    global WEZTERM_COMMAND_PALETTE_CATALOG_PATH, WEZTERM_COMMAND_PALETTE_PROJECTS_PATH
    global WEZTERM_COMMAND_PALETTE_ENTRIES, WEZTERM_COMMAND_PALETTE_ACTION_PATHS
    global WEZTERM_COMMAND_PALETTE_SNAPSHOT_FINGERPRINT
    global WEZTERM_COMMAND_PALETTE_OPEN_MESSAGE_INSTALLED

    try {
        WezTermCommandPaletteBridgeInitialize()
        WezTermCommandPaletteEnsureLifetimeHook()
        snapshot := WezTermCommandPaletteReadSnapshot(
            WEZTERM_COMMAND_PALETTE_CATALOG_PATH,
            WEZTERM_COMMAND_PALETTE_PROJECTS_PATH
        )
        catalogText := snapshot.catalogText
        catalog := JsonLoad(&catalogText)
        WezTermCommandPaletteValidateCatalog(catalog)
        projects := WezTermCommandPaletteLoadProjects(snapshot.projectsText)
        if (projects.Length > catalog["providerKeys"].Length)
            throw Error("Enabled project count exceeds provider key count")
        palette := WezTermCommandPaletteBuildPalette(catalog["items"], catalog, projects)
        WEZTERM_COMMAND_PALETTE_ENTRIES := palette.catalog
        WEZTERM_COMMAND_PALETTE_ACTION_PATHS := palette.paths
        WEZTERM_COMMAND_PALETTE_SNAPSHOT_FINGERPRINT := snapshot.fingerprint
    } catch as err {
        WezTermCommandPaletteNotifyFailure("Disabled: " . err.Message)
        return false
    }

    if !WEZTERM_COMMAND_PALETTE_OPEN_MESSAGE_INSTALLED {
        try {
            OnMessage(
                WezTermCommandPaletteOpenMessageId(),
                WezTermCommandPaletteOpenFromMessage
            )
            WEZTERM_COMMAND_PALETTE_OPEN_MESSAGE_INSTALLED := true
        } catch as err {
            WezTermCommandPaletteNotifyFailure(
                "Unable to register right-click palette bridge: " . err.Message
            )
            return false
        }
    }

    registered := false
    HotIf(WezTermCommandPaletteHotIf)
    try {
        Hotkey("^+p", WezTermCommandPaletteOpen)
        registered := true
    } catch as err {
        WezTermCommandPaletteNotifyFailure("Unable to register Ctrl+Shift+P: " . err.Message)
    } finally {
        HotIf()
    }
    return registered
}

WezTermCommandPaletteValidateCatalog(catalog) {
    global WEZTERM_COMMAND_PALETTE_CATALOG_VERSION

    WezTermCommandPaletteRequireExactFields(catalog, ["version", "providerKeys", "themes", "items"], "$")
    if (Type(catalog["version"]) != "Integer" || catalog["version"] != WEZTERM_COMMAND_PALETTE_CATALOG_VERSION)
        WezTermCommandPaletteInvalid("$.version", "expected version " . WEZTERM_COMMAND_PALETTE_CATALOG_VERSION)

    providerKeys := catalog["providerKeys"]
    WezTermCommandPaletteRequireArray(providerKeys, "$.providerKeys", true)
    providerKeySet := WezTermCommandPaletteCaseSensitiveMap()
    for index, key in providerKeys {
        path := "$.providerKeys[" . index . "]"
        WezTermCommandPaletteRequireChordKey(key, path)
        if providerKeySet.Has(key)
            WezTermCommandPaletteInvalid(path, "duplicate provider key " . key)
        providerKeySet[key] := true
    }

    themes := catalog["themes"]
    WezTermCommandPaletteRequireArray(themes, "$.themes", true)
    if (themes.Length > providerKeys.Length)
        WezTermCommandPaletteInvalid("$.themes", "theme count exceeds provider key count")
    themeIds := WezTermCommandPaletteCaseSensitiveMap()
    themeLabels := WezTermCommandPaletteCaseSensitiveMap()
    for index, theme in themes {
        path := "$.themes[" . index . "]"
        WezTermCommandPaletteRequireExactFields(theme, ["id", "label"], path)
        WezTermCommandPaletteRequireNonEmptyString(theme["id"], path . ".id")
        WezTermCommandPaletteRequireNonEmptyString(theme["label"], path . ".label")
        if themeIds.Has(theme["id"])
            WezTermCommandPaletteInvalid(path . ".id", "duplicate theme id " . theme["id"])
        if themeLabels.Has(theme["label"])
            WezTermCommandPaletteInvalid(path . ".label", "duplicate theme label " . theme["label"])
        themeIds[theme["id"]] := true
        themeLabels[theme["label"]] := true
    }

    state := {
        itemIds: WezTermCommandPaletteCaseSensitiveMap(),
        providers: WezTermCommandPaletteCaseSensitiveMap()
    }
    WezTermCommandPaletteValidateItems(catalog["items"], "$.items", state)
    if !state.providers.Has("projects") || !state.providers.Has("themes")
        WezTermCommandPaletteInvalid("$.items", "expected exactly one projects provider and one themes provider")
}

WezTermCommandPaletteValidateItems(items, path, state) {
    WezTermCommandPaletteRequireArray(items, path, true)
    siblingKeys := WezTermCommandPaletteCaseSensitiveMap()

    for index, item in items {
        itemPath := path . "[" . index . "]"
        WezTermCommandPaletteRequireExactFields(item,
            ["id", "key", "label", "items", "provider", "actionId"], itemPath,
            ["id", "key", "label"])
        WezTermCommandPaletteRequireNonEmptyString(item["id"], itemPath . ".id")
        if !RegExMatch(item["id"], "^[a-z0-9][a-z0-9-]*$")
            WezTermCommandPaletteInvalid(itemPath . ".id", "expected a lowercase kebab-case id")
        if state.itemIds.Has(item["id"])
            WezTermCommandPaletteInvalid(itemPath . ".id", "duplicate item id " . item["id"])
        state.itemIds[item["id"]] := true

        WezTermCommandPaletteRequireChordKey(item["key"], itemPath . ".key")
        if siblingKeys.Has(item["key"])
            WezTermCommandPaletteInvalid(itemPath . ".key", "duplicate sibling key " . item["key"])
        siblingKeys[item["key"]] := true
        WezTermCommandPaletteRequireNonEmptyString(item["label"], itemPath . ".label")

        hasItems := item.Has("items")
        hasProvider := item.Has("provider")
        hasAction := item.Has("actionId")
        shapeCount := (hasItems ? 1 : 0) + (hasProvider ? 1 : 0) + (hasAction ? 1 : 0)
        if (shapeCount != 1)
            WezTermCommandPaletteInvalid(itemPath, "expected exactly one of items, provider, or actionId")

        if hasItems {
            WezTermCommandPaletteValidateItems(item["items"], itemPath . ".items", state)
        } else if hasProvider {
            WezTermCommandPaletteRequireNonEmptyString(item["provider"], itemPath . ".provider")
            provider := item["provider"]
            if !(provider == "projects" || provider == "themes")
                WezTermCommandPaletteInvalid(itemPath . ".provider", "unknown provider " . provider)
            if state.providers.Has(provider)
                WezTermCommandPaletteInvalid(itemPath . ".provider", "duplicate provider " . provider)
            state.providers[provider] := true
        } else {
            WezTermCommandPaletteRequireNonEmptyString(item["actionId"], itemPath . ".actionId")
        }
    }
}

WezTermCommandPaletteRequireExactFields(value, allowedFields, path, requiredFields?) {
    if !(value is Map)
        WezTermCommandPaletteInvalid(path, "expected an object")

    for field, _ in value {
        allowed := false
        for _, allowedField in allowedFields {
            if (field == allowedField) {
                allowed := true
                break
            }
        }
        if !allowed
            WezTermCommandPaletteInvalid(path, "unknown field " . field)
    }

    fieldsToRequire := IsSet(requiredFields) ? requiredFields : allowedFields
    for _, field in fieldsToRequire {
        if !value.Has(field)
            WezTermCommandPaletteInvalid(path, "missing field " . field)
    }
}

WezTermCommandPaletteRequireArray(value, path, requireItems := false) {
    if !(value is Array)
        WezTermCommandPaletteInvalid(path, "expected an array")
    if (requireItems && value.Length = 0)
        WezTermCommandPaletteInvalid(path, "array must not be empty")
}

WezTermCommandPaletteRequireNonEmptyString(value, path) {
    if (Type(value) != "String" || value = "")
        WezTermCommandPaletteInvalid(path, "expected a non-empty string")
    if RegExMatch(value, "[\x00-\x1F]")
        WezTermCommandPaletteInvalid(path, "control characters U+0000..U+001F are not allowed")
}

WezTermCommandPaletteRequireChordKey(value, path) {
    WezTermCommandPaletteRequireNonEmptyString(value, path)
    if !RegExMatch(value, "^[0-9a-z]$")
        WezTermCommandPaletteInvalid(path, "expected one lowercase ASCII letter or digit")
}

WezTermCommandPaletteInvalid(path, message) {
    throw Error("Invalid command menu " . path . ": " . message)
}

WezTermCommandPaletteCaseSensitiveMap() {
    result := Map()
    result.CaseSense := "On"
    return result
}

WezTermCommandPaletteReadSnapshot(catalogPath, projectsPath) {
    catalogBytes := FileRead(catalogPath, "RAW")
    projectsBytes := FileRead(projectsPath, "RAW")
    return {
        catalogText: StrGet(catalogBytes, catalogBytes.Size, "UTF-8"),
        projectsText: StrGet(projectsBytes, projectsBytes.Size, "UTF-8"),
        fingerprint: WezTermCommandPaletteSnapshotFingerprint(catalogBytes, projectsBytes)
    }
}

; FNV-1a over catalog bytes, one NUL byte, then project bytes. The bridge
; protocol uses the lowercase, fixed-width eight-character hex result.
WezTermCommandPaletteSnapshotFingerprint(catalogBytes, projectsBytes) {
    hash := WezTermCommandPaletteFnv1aUpdate(2166136261, catalogBytes)
    hash := (hash * 16777619) & 0xFFFFFFFF
    hash := WezTermCommandPaletteFnv1aUpdate(hash, projectsBytes)
    return Format("{:08x}", hash)
}

WezTermCommandPaletteFnv1aUpdate(hash, bytes) {
    Loop bytes.Size
        hash := ((hash ^ NumGet(bytes, A_Index - 1, "UChar")) * 16777619) & 0xFFFFFFFF
    return hash
}

WezTermCommandPaletteLoadProjects(contents) {
    projects := []
    projectIds := WezTermCommandPaletteCaseSensitiveMap()
    pattern := "^\s*-\s+\[[xX]\]\s+\x60([^\x60]+)\x60\s*\|\s*\x60([^\x60]+)\x60(.*)$"

    for _, line in StrSplit(contents, "`n", "`r") {
        if !RegExMatch(line, pattern, &match)
            continue
        projectId := match[1]
        WezTermCommandPaletteRequireNonEmptyString(projectId, "OMP project id")
        if projectIds.Has(projectId)
            throw Error("Duplicate enabled OMP project id: " . projectId)
        projectIds[projectId] := true
        projects.Push(projectId)
    }
    return projects
}

WezTermCommandPaletteBuildPalette(items, catalog, projects) {
    result := { catalog: [], paths: Map(), ids: Map() }
    WezTermCommandPaletteFlattenPalette(items, "", [], "", 1, catalog, projects, result)
    return result
}

WezTermCommandPaletteFlattenPalette(items, prefix, breadcrumbs, parentId, depth, catalog, projects, result) {
    for _, item in items {
        path := prefix . item["key"]
        if item.Has("items") || item.Has("provider") {
            groupId := WezTermCommandPaletteAddPaletteGroup(
                result,
                path,
                item["label"],
                breadcrumbs,
                parentId,
                depth
            )
            childBreadcrumbs := breadcrumbs.Clone()
            childBreadcrumbs.Push(item["label"])
            if item.Has("items") {
                WezTermCommandPaletteFlattenPalette(
                    item["items"],
                    path,
                    childBreadcrumbs,
                    groupId,
                    depth + 1,
                    catalog,
                    projects,
                    result
                )
            } else {
                WezTermCommandPaletteFlattenProvider(
                    item["provider"],
                    path,
                    childBreadcrumbs,
                    groupId,
                    depth + 1,
                    catalog,
                    projects,
                    result
                )
            }
        } else {
            WezTermCommandPaletteAddPaletteAction(result, path, item["label"], breadcrumbs, parentId, depth)
        }
    }
}

WezTermCommandPaletteFlattenProvider(provider, prefix, breadcrumbs, parentId, depth, catalog, projects, result) {
    providerKeys := catalog["providerKeys"]
    if (provider == "projects") {
        for index, projectId in projects
            WezTermCommandPaletteAddPaletteAction(
                result,
                prefix . providerKeys[index],
                "OMP: " . projectId,
                breadcrumbs,
                parentId,
                depth
            )
        return
    }

    for index, theme in catalog["themes"]
        WezTermCommandPaletteAddPaletteAction(
            result,
            prefix . providerKeys[index],
            theme["label"],
            breadcrumbs,
            parentId,
            depth
        )
}

WezTermCommandPaletteAddPaletteGroup(result, path, label, breadcrumbs, parentId, depth) {
    WezTermCommandPaletteRequirePalettePath(path)
    id := "WezTerm:" . path
    WezTermCommandPaletteRequireUniquePaletteId(result, id)
    result.catalog.Push(Map(
        "id", id,
        "kind", "group",
        "parentId", parentId,
        "depth", depth,
        "label", label,
        "source", "WezTerm",
        "breadcrumb", WezTermCommandPaletteJoin(breadcrumbs, " › "),
        "shortcut", "Ctrl+Shift+P",
        "detail", ""
    ))
    return id
}

WezTermCommandPaletteAddPaletteAction(result, path, label, breadcrumbs, parentId, depth) {
    WezTermCommandPaletteRequirePalettePath(path)
    id := "WezTerm:" . path
    WezTermCommandPaletteRequireUniquePaletteId(result, id)
    result.catalog.Push(Map(
        "id", id,
        "kind", "action",
        "parentId", parentId,
        "depth", depth,
        "label", label,
        "source", "WezTerm",
        "breadcrumb", WezTermCommandPaletteJoin(breadcrumbs, " › "),
        "shortcut", "Ctrl+Shift+P",
        "detail", ""
    ))
    result.paths[id] := path
}

WezTermCommandPaletteRequirePalettePath(path) {
    if !RegExMatch(path, "^[0-9a-z]+$")
        throw Error("Invalid WezTerm dispatcher path: " . path)
}

WezTermCommandPaletteRequireUniquePaletteId(result, id) {
    if result.ids.Has(id)
        throw Error("Duplicate WezTerm command palette id: " . id)
    result.ids[id] := true
}

WezTermCommandPaletteJoin(values, separator) {
    text := ""
    for index, value in values
        text .= (index > 1 ? separator : "") . value
    return text
}

WezTermCommandPaletteEnsureLifetimeHook() {
    global WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK, WEZTERM_COMMAND_PALETTE_LIFECYCLE_INSTALLED

    if WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK
        return true

    WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK := CallbackCreate(
        WezTermCommandPaletteWinEventProc, , 7
    )
    if !WEZTERM_COMMAND_PALETTE_LIFECYCLE_INSTALLED {
        OnExit(WezTermCommandPaletteShutdown)
        WEZTERM_COMMAND_PALETTE_LIFECYCLE_INSTALLED := true
    }
    return true
}

WezTermCommandPaletteWinEventProc(hook, event, hwnd, objectId, childId, eventThread, eventTime) {
    global WEZTERM_COMMAND_PALETTE_TARGET_TOKENS

    if (event != 0x8001 || !hwnd || objectId != 0 || childId != 0)
        return
    for _, target in WEZTERM_COMMAND_PALETTE_TARGET_TOKENS {
        if (target.hook == hook && target.hwnd == hwnd)
            target.destroyed := true
    }
}

WezTermCommandPaletteShutdown(*) {
    global WEZTERM_COMMAND_PALETTE_TARGET, WEZTERM_COMMAND_PALETTE_TARGET_TOKENS
    global WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK

    for _, target in WEZTERM_COMMAND_PALETTE_TARGET_TOKENS {
        target.destroyed := true
        if target.hook {
            DllCall("user32\UnhookWinEvent", "Ptr", target.hook)
            target.hook := 0
        }
    }
    WEZTERM_COMMAND_PALETTE_TARGET := 0
    WEZTERM_COMMAND_PALETTE_TARGET_TOKENS := Map()

    if WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK {
        CallbackFree(WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK)
        WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK := 0
    }
}

WezTermCommandPaletteCaptureTarget(hwnd, pid) {
    global WEZTERM_COMMAND_PALETTE_TARGET_GENERATION, WEZTERM_COMMAND_PALETTE_TARGET_TOKENS
    global WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK

    WEZTERM_COMMAND_PALETTE_TARGET_GENERATION += 1
    target := {
        hwnd: hwnd,
        pid: pid,
        generation: WEZTERM_COMMAND_PALETTE_TARGET_GENERATION,
        destroyed: false,
        hook: 0
    }
    target.hook := DllCall(
        "user32\SetWinEventHook",
        "UInt", 0x8001,
        "UInt", 0x8001,
        "Ptr", 0,
        "Ptr", WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK,
        "UInt", pid,
        "UInt", 0,
        "UInt", 0,
        "Ptr"
    )
    if !target.hook
        throw Error("Unable to install owner-local EVENT_OBJECT_DESTROY hook")
    WEZTERM_COMMAND_PALETTE_TARGET_TOKENS[target.generation] := target
    return target
}

WezTermCommandPaletteRetireTarget(target) {
    global WEZTERM_COMMAND_PALETTE_TARGET_TOKENS

    if !IsObject(target)
        return
    target.destroyed := true
    if target.HasOwnProp("hook") && target.hook {
        DllCall("user32\UnhookWinEvent", "Ptr", target.hook)
        target.hook := 0
    }
    if target.HasOwnProp("generation")
        && WEZTERM_COMMAND_PALETTE_TARGET_TOKENS.Has(target.generation)
        WEZTERM_COMMAND_PALETTE_TARGET_TOKENS.Delete(target.generation)
}

WezTermCommandPaletteHotIf(*) {
    global WEZTERM_COMMAND_PALETTE_TARGET

    WezTermCommandPaletteRetireTarget(WEZTERM_COMMAND_PALETTE_TARGET)
    WEZTERM_COMMAND_PALETTE_TARGET := 0
    hwnd := WinExist("A")
    if !hwnd
        return false

    try {
        processName := WinGetProcessName("ahk_id " . hwnd)
        pid := WinGetPID("ahk_id " . hwnd)
    } catch {
        return false
    }

    if (StrLower(processName) != "wezterm-gui.exe" || WinExist("A") != hwnd)
        return false

    try {
        WEZTERM_COMMAND_PALETTE_TARGET := WezTermCommandPaletteCaptureTarget(hwnd, pid)
        return true
    } catch {
        WEZTERM_COMMAND_PALETTE_TARGET := 0
        return false
    }
}

WezTermCommandPaletteOpenFromMessage(sourceHwnd, sourcePid, *) {
    global WEZTERM_COMMAND_PALETTE_TARGET

    WezTermCommandPaletteRetireTarget(WEZTERM_COMMAND_PALETTE_TARGET)
    WEZTERM_COMMAND_PALETTE_TARGET := 0
    if !sourceHwnd || !sourcePid
        return 0

    sourceWindow := "ahk_id " . sourceHwnd
    try {
        if !WinExist(sourceWindow)
            || WinGetPID(sourceWindow) != sourcePid
            || StrLower(WinGetProcessName(sourceWindow)) != "wezterm-gui.exe"
            || WinActive(sourceWindow) != sourceHwnd
            return 0

        WEZTERM_COMMAND_PALETTE_TARGET := WezTermCommandPaletteCaptureTarget(
            sourceHwnd,
            sourcePid
        )
    } catch {
        WEZTERM_COMMAND_PALETTE_TARGET := 0
        return 0
    }

    WezTermCommandPaletteOpen()
    return 1
}

WezTermCommandPaletteOpen(*) {
    global WEZTERM_COMMAND_PALETTE_ENTRIES, WEZTERM_COMMAND_PALETTE_ACTION_PATHS
    global WEZTERM_COMMAND_PALETTE_TARGET

    target := WEZTERM_COMMAND_PALETTE_TARGET
    WEZTERM_COMMAND_PALETTE_TARGET := 0
    if !WezTermCommandPaletteTargetIsValid(target, true) {
        WezTermCommandPaletteRetireTarget(target)
        return
    }

    actions := Map()
    for id, path in WEZTERM_COMMAND_PALETTE_ACTION_PATHS
        actions[id] := WezTermCommandPaletteDispatch.Bind(path, target)

    selected := CommandPaletteOpenWith(
        {
            source: "WezTerm",
            catalog: WEZTERM_COMMAND_PALETTE_ENTRIES,
            settings: {
                viewMode: "groups",
                groupsFirst: true,
                chordMode: false
            },
            allowLevelCycle: true,
            recordUse: true
        },
        actions
    )
    if !selected
        WezTermCommandPaletteRetireTarget(target)
}

WezTermCommandPaletteDispatch(path, target, *) {
    global WEZTERM_COMMAND_PALETTE_ACTIVATE_TIMEOUT_SECONDS
    global WEZTERM_COMMAND_PALETTE_MODIFIER_TIMEOUT_MS, WEZTERM_COMMAND_PALETTE_ACK_TIMEOUT_MS
    global WEZTERM_COMMAND_PALETTE_REQUEST_TTL_SECONDS
    global WEZTERM_COMMAND_PALETTE_SNAPSHOT_FINGERPRINT

    busyToken := WezTermCommandPaletteRandomNonce()
    if !WezTermCommandPaletteTryAcquireBridge(busyToken) {
        WezTermCommandPaletteNotifyFailure("Cancelled: dispatcher is busy")
        return
    }

    if !IsObject(target) {
        WezTermCommandPaletteReleaseBridge(busyToken)
        return
    }
    request := 0
    executionObserved := false

    try {
        if !RegExMatch(path, "^[0-9a-z]+$")
            throw Error("invalid dispatcher path")
        if !RegExMatch(WEZTERM_COMMAND_PALETTE_SNAPSHOT_FINGERPRINT, "^[0-9a-f]{8}$")
            throw Error("invalid dispatcher snapshot fingerprint")
        if !WezTermCommandPaletteTargetIsValid(target)
            throw Error("the source WezTerm window no longer exists")
        if !WezTermCommandPaletteWaitForModifierRelease(WEZTERM_COMMAND_PALETTE_MODIFIER_TIMEOUT_MS)
            throw Error("modifier keys were not released in time")

        windowTitle := "ahk_id " . target.hwnd
        if (WinActive(windowTitle) != target.hwnd)
            WinActivateFast(windowTitle)
        if !WinWaitActive(windowTitle, , WEZTERM_COMMAND_PALETTE_ACTIVATE_TIMEOUT_SECONDS)
            throw Error("the source WezTerm window could not be activated")
        if WezTermCommandPaletteModifiersAreDown()
            throw Error("a modifier key was pressed before dispatch")
        WezTermCommandPaletteRequirePhaseTarget(target, busyToken, "claim")

        request := {
            nonce: WezTermCommandPaletteRandomNonce(),
            phase: "claim",
            fingerprint: WEZTERM_COMMAND_PALETTE_SNAPSHOT_FINGERPRINT,
            path: path,
            expires: WezTermCommandPaletteEpochSeconds() + WEZTERM_COMMAND_PALETTE_REQUEST_TTL_SECONDS
        }
        WezTermCommandPaletteWriteRequest(request, busyToken)

        claimed := WezTermCommandPaletteWaitForResponse(
            request,
            ["claimed"],
            WEZTERM_COMMAND_PALETTE_ACK_TIMEOUT_MS,
            target,
            busyToken
        )
        request.instance := claimed.instance
        request.window := claimed.window

        WezTermCommandPaletteRequirePhaseTarget(target, busyToken, "verify")
        request.phase := "verify"
        WezTermCommandPaletteWriteRequest(request, busyToken)
        WezTermCommandPaletteWaitForResponse(
            request,
            ["verified"],
            WEZTERM_COMMAND_PALETTE_ACK_TIMEOUT_MS,
            target,
            busyToken
        )

        WezTermCommandPaletteRequirePhaseTarget(target, busyToken, "commit")
        request.phase := "commit"
        WezTermCommandPaletteWriteRequest(request, busyToken)

        result := WezTermCommandPaletteWaitForResponse(
            request,
            ["executing", "done"],
            WEZTERM_COMMAND_PALETTE_ACK_TIMEOUT_MS,
            target,
            busyToken
        )
        executionObserved := true
        if (result.phase == "executing") {
            result := WezTermCommandPaletteWaitForResponse(
                request,
                ["done"],
                WEZTERM_COMMAND_PALETTE_ACK_TIMEOUT_MS,
                target,
                busyToken
            )
        }
    } catch as err {
        if !executionObserved
            WezTermCommandPaletteNotifyFailure("Cancelled: " . err.Message)
    } finally {
        if IsObject(request)
            try WezTermCommandPaletteCleanupNonce(request.nonce, busyToken)
        WezTermCommandPaletteRetireTarget(target)
        WezTermCommandPaletteReleaseBridge(busyToken)
    }
}

WezTermCommandPaletteTryAcquireBridge(token) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY

    if !RegExMatch(token, "^[0-9a-f]{16}$") || WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY != ""
        return false
    WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY := token
    return true
}

WezTermCommandPaletteReleaseBridge(token) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY

    if (WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY != token)
        return false
    WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY := ""
    return true
}

WezTermCommandPaletteRequirePhaseTarget(target, busyToken, phase) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY

    if (WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY != busyToken)
        throw Error("bridge ownership changed before " . phase)
    if !WezTermCommandPaletteTargetIsValid(target, true)
        throw Error("the source window changed before " . phase)
}

WezTermCommandPaletteParseState(contents) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_VERSION

    if (Type(contents) != "String" || contents = "" || SubStr(contents, -1) != "`n")
        throw Error("invalid bridge frame termination")
    for _, character in StrSplit(contents) {
        code := Ord(character)
        if (code != 10 && (code < 32 || code > 126))
            throw Error("bridge frame must be printable ASCII with LF separators")
    }

    lines := StrSplit(SubStr(contents, 1, StrLen(contents) - 1), "`n")
    if (lines.Length != 6 && lines.Length != 8)
        throw Error("invalid bridge field count")
    expected := lines.Length = 8
        ? ["version", "nonce", "phase", "fingerprint", "path", "instance", "window", "expires"]
        : ["version", "nonce", "phase", "fingerprint", "path", "expires"]
    values := WezTermCommandPaletteCaseSensitiveMap()
    for index, line in lines {
        separator := InStr(line, "=")
        if (separator < 2 || separator = StrLen(line))
            throw Error("invalid bridge field")
        key := SubStr(line, 1, separator - 1)
        value := SubStr(line, separator + 1)
        if (key != expected[index] || values.Has(key))
            throw Error("invalid bridge field order")
        if !RegExMatch(key, "^[a-z]+$") || !RegExMatch(value, "^[!-~]+$")
            throw Error("invalid bridge field encoding")
        values[key] := value
    }

    if (values["version"] != String(WEZTERM_COMMAND_PALETTE_BRIDGE_VERSION))
        throw Error("unsupported bridge version")
    if !RegExMatch(values["nonce"], "^[0-9a-f]{16}$")
        throw Error("invalid bridge nonce")
    if !RegExMatch(
        values["phase"],
        "^(claim|claimed|verify|verified|commit|executing|done|error)$"
    )
        throw Error("invalid bridge phase")
    if !RegExMatch(values["fingerprint"], "^[0-9a-f]{8}$")
        throw Error("invalid bridge fingerprint")
    if !RegExMatch(values["path"], "^[0-9a-z]+$")
        throw Error("invalid bridge path")
    if !WezTermCommandPaletteIsCanonicalDecimal(values["expires"])
        throw Error("invalid bridge expiry")
    if (Integer(values["expires"]) > 9007199254740991)
        throw Error("bridge expiry exceeds exact integer range")

    selected := values.Has("instance")
    if (values["phase"] == "claim" && selected)
        throw Error("claim must not select an instance")
    if (values["phase"] != "claim" && !selected)
        throw Error("bridge phase requires instance and window")
    if selected {
        if !RegExMatch(values["instance"], "^[0-9a-f]{16,32}$")
            throw Error("invalid bridge instance")
        if !WezTermCommandPaletteIsCanonicalDecimal(values["window"])
            throw Error("invalid bridge window")
    }

    state := {
        nonce: values["nonce"],
        phase: values["phase"],
        fingerprint: values["fingerprint"],
        path: values["path"],
        expires: Integer(values["expires"])
    }
    if selected {
        state.instance := values["instance"]
        state.window := values["window"]
    }
    return state
}

WezTermCommandPaletteSerializeState(state) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_VERSION, WEZTERM_COMMAND_PALETTE_BRIDGE_MAX_FRAME_BYTES

    lines := [
        "version=" . WEZTERM_COMMAND_PALETTE_BRIDGE_VERSION,
        "nonce=" . state.nonce,
        "phase=" . state.phase,
        "fingerprint=" . state.fingerprint,
        "path=" . state.path
    ]
    if state.HasOwnProp("instance") {
        lines.Push("instance=" . state.instance)
        lines.Push("window=" . state.window)
    }
    lines.Push("expires=" . state.expires)
    contents := ""
    for _, line in lines
        contents .= line . "`n"
    if (StrPut(contents, "UTF-8") - 1 > WEZTERM_COMMAND_PALETTE_BRIDGE_MAX_FRAME_BYTES)
        throw Error("bridge frame exceeds byte limit")
    WezTermCommandPaletteParseState(contents)
    return contents
}

WezTermCommandPaletteReadState(path?) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_PATH, WEZTERM_COMMAND_PALETTE_BRIDGE_MAX_FRAME_BYTES

    statePath := IsSet(path) ? path : WEZTERM_COMMAND_PALETTE_BRIDGE_PATH
    if !FileExist(statePath)
        return 0
    file := FileOpen(statePath, "r")
    if !IsObject(file)
        return 0
    frameBuffer := Buffer(WEZTERM_COMMAND_PALETTE_BRIDGE_MAX_FRAME_BYTES + 1, 0)
    try bytesRead := file.RawRead(frameBuffer, frameBuffer.Size)
    finally file.Close()
    if (bytesRead = 0 || bytesRead > WEZTERM_COMMAND_PALETTE_BRIDGE_MAX_FRAME_BYTES)
        throw Error("invalid bridge frame size")
    Loop bytesRead {
        byte := NumGet(frameBuffer, A_Index - 1, "UChar")
        if (byte != 10 && (byte < 32 || byte > 126))
            throw Error("bridge frame is not ASCII")
    }
    return WezTermCommandPaletteParseState(StrGet(frameBuffer, bytesRead, "UTF-8"))
}

WezTermCommandPaletteWriteRequest(state, writerToken, path?) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_PATH, WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY

    if (WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY != writerToken)
        throw Error("bridge request writer does not own the busy token")
    if !RegExMatch(state.phase, "^(claim|verify|commit)$")
        throw Error("AHK may write request phases only")
    statePath := IsSet(path) ? path : WEZTERM_COMMAND_PALETTE_BRIDGE_PATH
    tempPath := statePath . ".ahk." . writerToken . ".tmp"
    contents := WezTermCommandPaletteSerializeState(state)
    try {
        try FileDelete(tempPath)
        file := FileOpen(tempPath, "w", "UTF-8-RAW")
        if !IsObject(file)
            throw Error("unable to open bridge request temp file")
        try {
            if (file.Write(contents) != StrLen(contents))
                throw Error("unable to write complete bridge request")
        } finally {
            file.Close()
        }
        if (WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY != writerToken)
            throw Error("bridge ownership changed while writing request")
        FileMove(tempPath, statePath, true)
    } catch {
        try FileDelete(tempPath)
        throw
    }
    return true
}

WezTermCommandPaletteResponsePath(state, phase?, path?) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_PATH

    statePath := IsSet(path) ? path : WEZTERM_COMMAND_PALETTE_BRIDGE_PATH
    responsePhase := IsSet(phase) ? phase : state.phase
    if !RegExMatch(state.nonce, "^[0-9a-f]{16}$")
        || !RegExMatch(state.instance, "^[0-9a-f]{16,32}$")
        || !WezTermCommandPaletteIsCanonicalDecimal(state.window)
        || !RegExMatch(responsePhase, "^(claimed|verified|executing|done|error)$")
        throw Error("invalid bridge response name")
    return statePath . ".response." . state.nonce . "." . state.instance
        . "." . state.window . "." . responsePhase . ".txt"
}

WezTermCommandPaletteValidateResponse(state, request) {
    if (state.nonce != request.nonce
        || state.fingerprint != request.fingerprint
        || state.path != request.path
        || state.expires != request.expires)
        throw Error("bridge response does not match request")
    if (state.expires <= WezTermCommandPaletteEpochSeconds())
        throw Error("bridge request expired")
    if request.HasOwnProp("instance") {
        if (state.instance != request.instance || state.window != request.window)
            throw Error("bridge response selection changed")
    }
}

WezTermCommandPaletteFindClaimedResponse(request, path?) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_PATH

    statePath := IsSet(path) ? path : WEZTERM_COMMAND_PALETTE_BRIDGE_PATH
    candidate := 0
    Loop Files statePath . ".response." . request.nonce . ".*.txt", "F" {
        try {
            state := WezTermCommandPaletteReadState(A_LoopFileFullPath)
            if !IsObject(state) || state.phase != "claimed"
                continue
            WezTermCommandPaletteValidateResponse(state, request)
            if (StrLower(A_LoopFileFullPath) != StrLower(
                WezTermCommandPaletteResponsePath(state, state.phase, statePath)
            ))
                continue
            if IsObject(candidate)
                throw Error("ambiguous WezTerm bridge claim")
            candidate := state
        } catch as err {
            if (err.Message == "ambiguous WezTerm bridge claim")
                throw
            ; Invalid, stale, or unrelated immutable responses are ignored.
        }
    }
    return candidate
}

WezTermCommandPaletteWaitForResponse(request, expectedPhases, timeoutMs, target, busyToken) {
    global WEZTERM_COMMAND_PALETTE_POLL_INTERVAL_MS

    deadline := WezTermCommandPaletteMonotonicMilliseconds() + timeoutMs
    while (WezTermCommandPaletteMonotonicMilliseconds() < deadline) {
        WezTermCommandPaletteRequirePhaseTarget(target, busyToken, request.phase)
        if request.HasOwnProp("instance") {
            phases := expectedPhases.Clone()
            phases.Push("error")
            for _, phase in phases {
                responsePath := WezTermCommandPaletteResponsePath(request, phase)
                try state := WezTermCommandPaletteReadState(responsePath)
                catch
                    continue
                if !IsObject(state)
                    continue
                try WezTermCommandPaletteValidateResponse(state, request)
                catch
                    continue
                if (state.phase != phase)
                    continue
                if (state.phase == "error")
                    throw Error("WezTerm rejected the bridge request")
                return state
            }
        } else {
            state := WezTermCommandPaletteFindClaimedResponse(request)
            if IsObject(state)
                return state
        }
        Sleep(WEZTERM_COMMAND_PALETTE_POLL_INTERVAL_MS)
    }
    throw Error("timed out waiting for WezTerm bridge acknowledgement")
}

WezTermCommandPaletteCleanupNonce(nonce, writerToken := "", path?) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_PATH

    if !RegExMatch(nonce, "^[0-9a-f]{16}$")
        return false
    if (writerToken != "" && !RegExMatch(writerToken, "^[0-9a-f]{16}$"))
        return false
    statePath := IsSet(path) ? path : WEZTERM_COMMAND_PALETTE_BRIDGE_PATH
    try {
        request := WezTermCommandPaletteReadState(statePath)
        if IsObject(request) && request.nonce == nonce
            FileDelete(statePath)
    }
    Loop Files statePath . ".response." . nonce . ".*", "F"
        try FileDelete(A_LoopFileFullPath)
    if (writerToken != "")
        try FileDelete(statePath . ".ahk." . writerToken . ".tmp")
    return true
}

WezTermCommandPaletteBridgeInitialize(path?) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_PATH, WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY

    if (WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY != "")
        throw Error("cannot initialize a busy bridge")
    statePath := IsSet(path) ? path : WEZTERM_COMMAND_PALETTE_BRIDGE_PATH
    try FileDelete(statePath)
    try FileDelete(statePath . ".ahk.tmp")
    try FileDelete(statePath . ".lua.tmp")
    Loop Files statePath . ".ahk.*.tmp", "F"
        try FileDelete(A_LoopFileFullPath)
    Loop Files statePath . ".response.*", "F"
        try FileDelete(A_LoopFileFullPath)
    return true
}

WezTermCommandPaletteIsCanonicalDecimal(value) {
    return RegExMatch(value, "^(0|[1-9][0-9]*)$")
}

WezTermCommandPaletteRandomNonce() {
    bytes := Buffer(8, 0)
    status := DllCall(
        "bcrypt\BCryptGenRandom",
        "Ptr", 0,
        "Ptr", bytes.Ptr,
        "UInt", bytes.Size,
        "UInt", 0x2,
        "UInt"
    )
    if status
        throw Error("BCryptGenRandom failed with status " . status)
    nonce := ""
    Loop bytes.Size
        nonce .= Format("{:02x}", NumGet(bytes, A_Index - 1, "UChar"))
    return nonce
}

WezTermCommandPaletteEpochSeconds() {
    return DateDiff(A_NowUTC, "19700101000000", "Seconds")
}

WezTermCommandPaletteMonotonicMilliseconds() {
    return DllCall("Kernel32\GetTickCount64", "UInt64")
}

WezTermCommandPaletteTargetIsValid(target, requireActive := false) {
    global WEZTERM_COMMAND_PALETTE_TARGET_TOKENS

    if !IsObject(target)
        || !target.HasOwnProp("hwnd")
        || !target.HasOwnProp("pid")
        || !target.HasOwnProp("generation")
        || !target.HasOwnProp("destroyed")
        || target.destroyed
        return false
    if !WEZTERM_COMMAND_PALETTE_TARGET_TOKENS.Has(target.generation)
        || ObjPtr(WEZTERM_COMMAND_PALETTE_TARGET_TOKENS[target.generation]) != ObjPtr(target)
        return false


    windowTitle := "ahk_id " . target.hwnd
    if !WinExist(windowTitle)
        return false
    try {
        if (StrLower(WinGetProcessName(windowTitle)) != "wezterm-gui.exe")
            return false
        if (WinGetPID(windowTitle) != target.pid)
            return false
    } catch {
        return false
    }
    if (requireActive && WinActive(windowTitle) != target.hwnd)
        return false
    return !target.destroyed
}


WezTermCommandPaletteWaitForModifierRelease(timeoutMs) {
    startedAt := A_TickCount
    while WezTermCommandPaletteModifiersAreDown() {
        if (A_TickCount - startedAt >= timeoutMs)
            return false
        Sleep(10)
    }
    return true
}

WezTermCommandPaletteModifiersAreDown() {
    return GetKeyState("Ctrl", "P")
        || GetKeyState("Shift", "P")
        || GetKeyState("Alt", "P")
        || GetKeyState("LWin", "P")
        || GetKeyState("RWin", "P")
}

WezTermCommandPaletteNotifyFailure(message) {
    try TrayTip(message, "WezTerm Command Palette")
}
