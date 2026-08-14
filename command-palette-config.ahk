; Canonical declarative menu configuration. Executable closures remain in AHK.

CommandPaletteConfigDefaultPath() {
    SplitPath(A_LineFile,, &directory)
    return directory . "\menu-config.json"
}

global COMMAND_PALETTE_CONFIG := Map("version", 1, "revision", 0, "menus", Map(), "menuOverrides", Map(), "itemOverrides", Map())
global COMMAND_PALETTE_CONFIG_ITEMS := Map()
global COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS := Map()
global COMMAND_PALETTE_CONFIG_PATH := CommandPaletteConfigDefaultPath()
global COMMAND_PALETTE_CONFIG_LOADED_REVISION := 0
global COMMAND_PALETTE_CONFIG_LAST_ERROR := ""

CommandPaletteConfigInit() {
    return CommandPaletteConfigLoad()
}

CommandPaletteConfigLoad() {
    global COMMAND_PALETTE_CONFIG, COMMAND_PALETTE_CONFIG_ITEMS, COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
    global COMMAND_PALETTE_CONFIG_LAST_ERROR, COMMAND_PALETTE_CONFIG_LOADED_REVISION, COMMAND_PALETTE_CONFIG_PATH

    COMMAND_PALETTE_CONFIG_LAST_ERROR := ""
    try {
        json := FileRead(COMMAND_PALETTE_CONFIG_PATH, "UTF-8")
        payload := JsonLoad(&json)
        if !payload.Has("menuOverrides")
            payload["menuOverrides"] := Map()
        if !payload.Has("itemOverrides")
            payload["itemOverrides"] := Map()
        CommandPaletteConfigValidate(payload)
        itemIndex := Map()
        for source, menu in payload["menus"] {
            for _, item in menu["items"] {
                id := item["id"]
                if itemIndex.Has(id)
                    throw Error("Duplicate menu item id: " . id)
                itemIndex[id] := item
            }
        }
        COMMAND_PALETTE_CONFIG := payload
        COMMAND_PALETTE_CONFIG_ITEMS := itemIndex
        COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS := Map()
        COMMAND_PALETTE_CONFIG_LOADED_REVISION := payload["revision"]
        return true
    } catch Error as e {
        COMMAND_PALETTE_CONFIG_LAST_ERROR := e.Message
        OutputDebug("command palette config load error: " . e.Message)
        return false
    }
}

CommandPaletteConfigValidate(payload) {
    if !(payload is Map)
        throw Error("menu-config.json root must be an object")
    if !payload.Has("version") || payload["version"] != 1
        throw Error("Unsupported menu-config.json version")
    if !payload.Has("revision") || !(payload["revision"] is Number) || payload["revision"] < 0
        throw Error("menu-config.json requires a non-negative revision")
    if !payload.Has("menus") || !(payload["menus"] is Map)
        throw Error("menu-config.json requires a menus object")
    if !payload.Has("menuOverrides") || !(payload["menuOverrides"] is Map)
        throw Error("menu-config.json menuOverrides must be an object")
    if !payload.Has("itemOverrides") || !(payload["itemOverrides"] is Map)
        throw Error("menu-config.json itemOverrides must be an object")
    for source, settings in payload["menuOverrides"] {
        if !(settings is Map)
            throw Error("Menu override " . source . " must be an object")
        for field, value in settings
            if !CommandPaletteConfigValidMenuValue(field, value)
                throw Error("Invalid menu override " . source . "." . field)
    }
    for id, override in payload["itemOverrides"] {
        if !(override is Map)
            throw Error("Item override " . id . " must be an object")
        for field, value in override {
            if field = "deleted" {
                if !(value = true || value = false)
                    throw Error("Invalid item override " . id . ".deleted")
            } else if !CommandPaletteConfigValidItemValue(field, value)
                throw Error("Invalid item override " . id . "." . field)
        }
    }

    seenIds := Map()
    for source, menu in payload["menus"] {
        if !(menu is Map) || !menu.Has("shortcut") || !(menu["shortcut"] is String)
            throw Error("Menu " . source . " requires shortcut")
        if !menu.Has("items") || !(menu["items"] is Array)
            throw Error("Menu " . source . " requires items")
        localIds := Map()
        for _, item in menu["items"] {
            CommandPaletteConfigValidateItem(source, item)
            id := item["id"]
            if seenIds.Has(id)
                throw Error("Duplicate menu item id: " . id)
            seenIds[id] := true
            localIds[id] := item
        }
        for id, item in localIds {
            parentId := item["parentId"]
            if parentId = ""
                continue
            if !localIds.Has(parentId) || localIds[parentId]["kind"] != "group"
                throw Error("Invalid parentId for " . id . ": " . parentId)
            if CommandPaletteConfigParentCreatesCycle(id, localIds)
                throw Error("Menu hierarchy cycle at " . id)
        }
    }
}

CommandPaletteConfigValidateItem(source, item) {
    if !(item is Map)
        throw Error("Menu " . source . " contains a non-object item")
    for _, field in ["id", "kind", "parentId", "label", "chordPath"]
        if !item.Has(field)
            throw Error("Menu " . source . " item missing " . field)
    if !(item["id"] is String) || item["id"] = ""
        throw Error("Menu item id must be a non-empty string")
    if !(item["kind"] = "group" || item["kind"] = "action")
        throw Error("Invalid kind for " . item["id"])
    if !(item["parentId"] is String) || !(item["label"] is String) || !(item["chordPath"] is Array)
        throw Error("Invalid declarative fields for " . item["id"])
    if item["kind"] = "action" && (!item.Has("actionId") || !(item["actionId"] is String))
        throw Error("Action item missing actionId: " . item["id"])
}

CommandPaletteConfigParentCreatesCycle(id, items) {
    seen := Map(id, true)
    current := items[id]["parentId"]
    while current != "" {
        if seen.Has(current)
            return true
        seen[current] := true
        current := items[current]["parentId"]
    }
    return false
}

CommandPaletteConfigSave() {
    global COMMAND_PALETTE_CONFIG, COMMAND_PALETTE_CONFIG_LAST_ERROR
    global COMMAND_PALETTE_CONFIG_LOADED_REVISION, COMMAND_PALETTE_CONFIG_PATH

    COMMAND_PALETTE_CONFIG_LAST_ERROR := ""
    try {
        if FileExist(COMMAND_PALETTE_CONFIG_PATH) {
            currentJson := FileRead(COMMAND_PALETTE_CONFIG_PATH, "UTF-8")
            current := JsonLoad(&currentJson)
            if !current.Has("revision") || current["revision"] != COMMAND_PALETTE_CONFIG_LOADED_REVISION
                throw Error("menu-config.json changed outside the menu; reload before saving")
        }
        CommandPaletteConfigValidate(COMMAND_PALETTE_CONFIG)
        COMMAND_PALETTE_CONFIG["revision"] := COMMAND_PALETTE_CONFIG_LOADED_REVISION + 1
        rendered := JsonDump(COMMAND_PALETTE_CONFIG, "  ") . "`n"
        temporaryPath := COMMAND_PALETTE_CONFIG_PATH . ".tmp"
        backupPath := COMMAND_PALETTE_CONFIG_PATH . ".bak"
        if FileExist(temporaryPath)
            FileDelete(temporaryPath)
        FileAppend(rendered, temporaryPath, "UTF-8")
        verificationJson := FileRead(temporaryPath, "UTF-8")
        verification := JsonLoad(&verificationJson)
        CommandPaletteConfigValidate(verification)
        if FileExist(backupPath)
            FileDelete(backupPath)
        if FileExist(COMMAND_PALETTE_CONFIG_PATH)
            FileCopy(COMMAND_PALETTE_CONFIG_PATH, backupPath, true)
        FileMove(temporaryPath, COMMAND_PALETTE_CONFIG_PATH, true)
        COMMAND_PALETTE_CONFIG_LOADED_REVISION := COMMAND_PALETTE_CONFIG["revision"]
        return true
    } catch Error as e {
        errorMessage := e.Message
        COMMAND_PALETTE_CONFIG["revision"] := COMMAND_PALETTE_CONFIG_LOADED_REVISION
        CommandPaletteConfigLoad()
        COMMAND_PALETTE_CONFIG_LAST_ERROR := errorMessage
        OutputDebug("command palette config save error: " . errorMessage)
        return false
    }
}

CommandPaletteConfigMenuDefaults(codeDefaults?) {
    defaults := Map(
        "viewMode", "groups",
        "groupsFirst", true,
        "chordMode", false,
        "chordDelayMs", 1000,
        "maxPinned", 3,
        "maxSuggested", 3
    )
    if IsSet(codeDefaults) && IsObject(codeDefaults) {
        for field, value in codeDefaults.OwnProps()
            if CommandPaletteConfigValidMenuValue(field, value)
                defaults[field] := value
    }
    return defaults
}

CommandPaletteConfigGetMenu(source, codeDefaults?) {
    global COMMAND_PALETTE_CONFIG

    resolved := IsSet(codeDefaults)
        ? CommandPaletteConfigMenuDefaults(codeDefaults)
        : CommandPaletteConfigMenuDefaults()
    if COMMAND_PALETTE_CONFIG["menus"].Has(source) {
        menu := COMMAND_PALETTE_CONFIG["menus"][source]
        for field, value in menu
            if CommandPaletteConfigValidMenuValue(field, value)
                resolved[field] := value
    }
    if COMMAND_PALETTE_CONFIG["menuOverrides"].Has(source)
        for field, value in COMMAND_PALETTE_CONFIG["menuOverrides"][source]
            if CommandPaletteConfigValidMenuValue(field, value)
                resolved[field] := value
    return resolved
}

CommandPaletteConfigValidMenuValue(field, value) {
    switch field {
        case "viewMode":
            return value = "flat" || value = "groups" || value = "mixed"
        case "groupsFirst", "chordMode":
            return value = true || value = false
        case "chordDelayMs":
            return value is Number && value >= 100 && value <= 2000
        case "maxPinned", "maxSuggested":
            return value is Number && value >= 0 && value <= 10
    }
    return false
}

CommandPaletteConfigSetMenu(source, field, value) {
    global COMMAND_PALETTE_CONFIG

    if !CommandPaletteConfigValidMenuValue(field, value)
        return false
    if COMMAND_PALETTE_CONFIG["menus"].Has(source)
        COMMAND_PALETTE_CONFIG["menus"][source][field] := value
    else {
        if !COMMAND_PALETTE_CONFIG["menuOverrides"].Has(source)
            COMMAND_PALETTE_CONFIG["menuOverrides"][source] := Map()
        COMMAND_PALETTE_CONFIG["menuOverrides"][source][field] := value
    }
    return CommandPaletteConfigSave()
}

CommandPaletteConfigGetItem(id) {
    global COMMAND_PALETTE_CONFIG_ITEMS, COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
    if COMMAND_PALETTE_CONFIG_ITEMS.Has(id)
        return COMMAND_PALETTE_CONFIG_ITEMS[id]
    return COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS.Has(id)
        ? COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS[id]
        : Map()
}

CommandPaletteConfigItemSource(id) {
    global COMMAND_PALETTE_CONFIG, COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
    if COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS.Has(id)
        return COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS[id]["source"]
    for source, menu in COMMAND_PALETTE_CONFIG["menus"]
        for _, item in menu["items"]
            if item["id"] = id
                return source
    return ""
}

CommandPaletteConfigValidItemValue(field, value) {
    switch field {
        case "hidden", "pinned":
            return value = true || value = false
        case "label", "alias", "parentId":
            return value is String && StrLen(value) <= 200
        case "order", "pinOrder":
            return value is Number && value >= -100000 && value <= 100000
    }
    return false
}

CommandPaletteConfigExternalParentValid(id, parentId) {
    global COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
    if parentId = ""
        return true
    if !COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS.Has(id)
        || !COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS.Has(parentId)
        || COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS[parentId]["kind"] != "group"
        || COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS[id]["source"] != COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS[parentId]["source"]
        return false
    seen := Map(id, true)
    current := parentId
    while current != "" {
        if seen.Has(current)
            return false
        seen[current] := true
        current := COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS[current]["parentId"]
    }
    return true
}

CommandPaletteConfigStoreItemField(id, field, value) {
    global COMMAND_PALETTE_CONFIG, COMMAND_PALETTE_CONFIG_ITEMS, COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
    if COMMAND_PALETTE_CONFIG_ITEMS.Has(id) {
        if field = "hidden"
            COMMAND_PALETTE_CONFIG_ITEMS[id]["visible"] := !value
        else
            COMMAND_PALETTE_CONFIG_ITEMS[id][field] := value
        return true
    }
    if !COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS.Has(id)
        return false
    if !COMMAND_PALETTE_CONFIG["itemOverrides"].Has(id)
        COMMAND_PALETTE_CONFIG["itemOverrides"][id] := Map()
    COMMAND_PALETTE_CONFIG["itemOverrides"][id][field] := value
    COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS[id][field] := value
    return true
}

CommandPaletteConfigSetItem(id, field, value) {
    global COMMAND_PALETTE_CONFIG_ITEMS
    item := CommandPaletteConfigGetItem(id)
    if item.Count = 0 || !CommandPaletteConfigValidItemValue(field, value)
        return false
    if field = "parentId" && !COMMAND_PALETTE_CONFIG_ITEMS.Has(id)
        && !CommandPaletteConfigExternalParentValid(id, value)
        return false
    if !CommandPaletteConfigStoreItemField(id, field, value)
        return false
    return CommandPaletteConfigSave()
}

CommandPaletteConfigDeleteItem(id) {
    global COMMAND_PALETTE_CONFIG, COMMAND_PALETTE_CONFIG_ITEMS, COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
    item := CommandPaletteConfigGetItem(id)
    if item.Count = 0
        return false

    deleteIds := Map(id, true)
    itemIndex := COMMAND_PALETTE_CONFIG_ITEMS.Has(id)
        ? COMMAND_PALETTE_CONFIG_ITEMS
        : COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
    added := true
    while added {
        added := false
        for candidateId, candidate in itemIndex
            if !deleteIds.Has(candidateId) && deleteIds.Has(candidate["parentId"]) {
                deleteIds[candidateId] := true
                added := true
            }
    }

    if !COMMAND_PALETTE_CONFIG_ITEMS.Has(id) {
        for deleteId, _ in deleteIds {
            if !COMMAND_PALETTE_CONFIG["itemOverrides"].Has(deleteId)
                COMMAND_PALETTE_CONFIG["itemOverrides"][deleteId] := Map()
            COMMAND_PALETTE_CONFIG["itemOverrides"][deleteId]["deleted"] := true
        }
        return CommandPaletteConfigSave()
    }

    source := CommandPaletteConfigItemSource(id)
    items := COMMAND_PALETTE_CONFIG["menus"][source]["items"]
    index := items.Length
    while index >= 1 {
        if deleteIds.Has(items[index]["id"])
            items.RemoveAt(index)
        index -= 1
    }
    saved := CommandPaletteConfigSave()
    if saved
        CommandPaletteConfigLoad()
    return saved
}

CommandPaletteConfigTogglePin(id) {
    item := CommandPaletteConfigGetItem(id)
    if item.Count = 0
        return false
    isPinned := item.Has("pinned") && item["pinned"] = true
    if !isPinned && (!item.Has("pinOrder") || item["pinOrder"] = 0)
        CommandPaletteConfigStoreItemField(id, "pinOrder", CommandPaletteConfigNextPinOrder(CommandPaletteConfigItemSource(id)))
    CommandPaletteConfigStoreItemField(id, "pinned", !isPinned)
    return CommandPaletteConfigSave()
}

CommandPaletteConfigNextPinOrder(source) {
    global COMMAND_PALETTE_CONFIG_ITEMS, COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
    nextOrder := 1
    for itemId, item in COMMAND_PALETTE_CONFIG_ITEMS
        if CommandPaletteConfigItemSource(itemId) = source && item.Has("pinOrder") && item["pinOrder"] is Number
            nextOrder := Max(nextOrder, item["pinOrder"] + 1)
    for itemId, item in COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
        if item["source"] = source && item.Has("pinOrder") && item["pinOrder"] is Number
            nextOrder := Max(nextOrder, item["pinOrder"] + 1)
    return nextOrder
}

CommandPaletteConfigMovePin(id, direction) {
    global COMMAND_PALETTE_CONFIG_ITEMS, COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
    source := CommandPaletteConfigItemSource(id)
    pins := []
    allItems := Map()
    for candidateId, item in COMMAND_PALETTE_CONFIG_ITEMS
        if CommandPaletteConfigItemSource(candidateId) = source
            allItems[candidateId] := item
    for candidateId, item in COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
        if item["source"] = source
            allItems[candidateId] := item
    for candidateId, item in allItems {
        if !item.Has("pinned") || item["pinned"] != true
            continue
        order := item.Has("pinOrder") && item["pinOrder"] is Number ? item["pinOrder"] : 100000
        insertAt := pins.Length + 1
        for index, existing in pins
            if order < existing["order"] {
                insertAt := index
                break
            }
        pins.InsertAt(insertAt, Map("id", candidateId, "order", order))
    }
    currentIndex := 0
    for index, pin in pins
        if pin["id"] = id
            currentIndex := index
    targetIndex := currentIndex + direction
    if currentIndex = 0 || targetIndex < 1 || targetIndex > pins.Length
        return false
    otherId := pins[targetIndex]["id"]
    CommandPaletteConfigStoreItemField(id, "pinOrder", pins[targetIndex]["order"])
    CommandPaletteConfigStoreItemField(otherId, "pinOrder", pins[currentIndex]["order"])
    return CommandPaletteConfigSave()
}

CommandPaletteConfigViewModeToLevel(viewMode) {
    switch viewMode {
        case "flat":
            return 0
        case "mixed":
            return 2
        default:
            return 1
    }
}

CommandPaletteConfigLevelToViewMode(level) {
    switch Integer(level) {
        case 0:
            return "flat"
        case 2:
            return "mixed"
        default:
            return "groups"
    }
}

CommandPaletteConfigBuildCatalog(source := "Global", fallbackCatalog?) {
    global COMMAND_PALETTE_CONFIG

    if ((source = "Global" && COMMAND_PALETTE_CONFIG["menus"].Count = 0)
        || (source != "Global" && !COMMAND_PALETTE_CONFIG["menus"].Has(source)))
        return IsSet(fallbackCatalog) ? CommandPaletteConfigAnnotateFallback(fallbackCatalog) : []

    result := []
    sources := source = "Global" ? CommandPaletteConfigSources() : [source]
    for _, menuSource in sources {
        menu := COMMAND_PALETTE_CONFIG["menus"][menuSource]
        itemIndex := Map()
        for _, item in menu["items"]
            itemIndex[item["id"]] := item
        for _, item in menu["items"] {
            if !CommandPaletteConfigItemVisible(item, itemIndex)
                continue
            id := item["id"]
            result.Push(Map(
                "id", id,
                "kind", item["kind"],
                "parentId", item["parentId"],
                "depth", CommandPaletteConfigItemDepth(item, itemIndex),
                "label", item["label"],
                "alias", item.Has("alias") ? item["alias"] : "",
                "source", menuSource,
                "breadcrumb", CommandPaletteConfigItemBreadcrumb(item, itemIndex),
                "shortcut", menu["shortcut"] . " " . CommandPaletteConfigItemShortcut(item, itemIndex),
                "detail", item.Has("detail") ? item["detail"] : "",
                "userOrder", item.Has("order") ? item["order"] : 0,
                "pinned", item.Has("pinned") && item["pinned"] = true,
                "pinOrder", item.Has("pinOrder") ? item["pinOrder"] : 0
            ))
        }
    }
    return result
}

CommandPaletteConfigBuildFallbackItems(catalog) {
    global COMMAND_PALETTE_CONFIG, COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS
    result := []
    itemIndex := Map()
    originalParents := Map()
    for index, command in catalog {
        clone := Map()
        for field, value in command
            clone[field] := value
        clone["defaultLabel"] := command["label"]
        clone["defaultParentId"] := command["parentId"]
        clone["alias"] := command.Has("alias") ? command["alias"] : ""
        clone["hidden"] := false
        clone["deleted"] := false
        clone["userOrder"] := index
        clone["order"] := index
        clone["pinned"] := false
        clone["pinOrder"] := 0
        if COMMAND_PALETTE_CONFIG["itemOverrides"].Has(command["id"])
            for field, value in COMMAND_PALETTE_CONFIG["itemOverrides"][command["id"]] {
                if field = "order" {
                    clone["order"] := value
                    clone["userOrder"] := value
                } else
                    clone[field] := value
            }
        result.Push(clone)
        itemIndex[clone["id"]] := clone
        originalParents[clone["id"]] := command["parentId"]
    }
    for _, item in result {
        parentId := item["parentId"]
        if parentId != "" && (!itemIndex.Has(parentId)
            || itemIndex[parentId]["kind"] != "group"
            || itemIndex[parentId]["source"] != item["source"])
            item["parentId"] := originalParents[item["id"]]
        if CommandPaletteConfigParentCreatesCycle(item["id"], itemIndex)
            item["parentId"] := originalParents[item["id"]]
    }
    for _, item in result {
        item["depth"] := CommandPaletteConfigItemDepth(item, itemIndex)
        item["breadcrumb"] := CommandPaletteConfigItemBreadcrumb(item, itemIndex)
        COMMAND_PALETTE_CONFIG_RUNTIME_ITEMS[item["id"]] := item
    }
    return result
}

CommandPaletteConfigFallbackItemVisible(item, itemIndex) {
    current := item
    while true {
        if current["hidden"] || current["deleted"]
            return false
        parentId := current["parentId"]
        if parentId = ""
            return true
        current := itemIndex[parentId]
    }
}

CommandPaletteConfigAnnotateFallback(catalog) {
    items := CommandPaletteConfigBuildFallbackItems(catalog)
    itemIndex := Map()
    for _, item in items
        itemIndex[item["id"]] := item
    result := []
    for _, item in items
        if CommandPaletteConfigFallbackItemVisible(item, itemIndex)
            result.Push(item)
    return result
}

CommandPaletteConfigSources() {
    global COMMAND_PALETTE_CONFIG
    sources := []
    seen := Map()
    if COMMAND_PALETTE_CONFIG.Has("menuOrder") && COMMAND_PALETTE_CONFIG["menuOrder"] is Array
        for _, source in COMMAND_PALETTE_CONFIG["menuOrder"]
            if COMMAND_PALETTE_CONFIG["menus"].Has(source) && !seen.Has(source) {
                sources.Push(source)
                seen[source] := true
            }
    for source, _ in COMMAND_PALETTE_CONFIG["menus"]
        if !seen.Has(source)
            sources.Push(source)
    return sources
}


CommandPaletteConfigItemVisible(item, itemIndex) {
    current := item
    while true {
        if current.Has("visible") && current["visible"] != true
            return false
        parentId := current["parentId"]
        if parentId = ""
            return true
        current := itemIndex[parentId]
    }
}

CommandPaletteConfigItemDepth(item, itemIndex) {
    depth := 1
    parentId := item["parentId"]
    while parentId != "" {
        depth += 1
        parentId := itemIndex[parentId]["parentId"]
    }
    return depth
}

CommandPaletteConfigItemBreadcrumb(item, itemIndex) {
    labels := []
    parentId := item["parentId"]
    while parentId != "" {
        labels.InsertAt(1, itemIndex[parentId]["label"])
        parentId := itemIndex[parentId]["parentId"]
    }
    return labels.Length ? CommandPaletteJoin(labels, " › ") : ""
}

CommandPaletteConfigItemShortcut(item, itemIndex) {
    segments := []
    lineage := []
    current := item
    while true {
        lineage.InsertAt(1, current)
        parentId := current["parentId"]
        if parentId = ""
            break
        current := itemIndex[parentId]
    }
    for _, node in lineage
        for _, key in node["chordPath"]
            segments.Push(ChordFormatSuffixForHint(ChordNormalizeSuffixKey(key)))
    return CommandPaletteJoin(segments, " ")
}

CommandPaletteConfigBuildEditorCatalog(source := "Global", fallbackCatalog?) {
    global COMMAND_PALETTE_CONFIG

    if ((source = "Global" && COMMAND_PALETTE_CONFIG["menus"].Count = 0)
        || (source != "Global" && !COMMAND_PALETTE_CONFIG["menus"].Has(source))) {
        fallback := IsSet(fallbackCatalog) ? fallbackCatalog : []
        result := []
        for _, item in CommandPaletteConfigBuildFallbackItems(fallback)
            if !item["deleted"]
                result.Push(Map(
                    "id", item["id"],
                    "kind", item["kind"],
                    "source", item["source"],
                    "defaultLabel", item["defaultLabel"],
                    "label", item["label"],
                    "alias", item["alias"],
                    "defaultParentId", item["defaultParentId"],
                    "parentId", item["parentId"],
                    "hidden", item["hidden"],
                    "pinned", item["pinned"],
                    "order", item["order"]
                ))
        return result
    }
    result := []
    sources := source = "Global" ? CommandPaletteConfigSources() : [source]
    for _, menuSource in sources
        for _, item in COMMAND_PALETTE_CONFIG["menus"][menuSource]["items"]
            result.Push(Map(
                "id", item["id"],
                "kind", item["kind"],
                "source", menuSource,
                "defaultLabel", item["label"],
                "label", item["label"],
                "alias", item.Has("alias") ? item["alias"] : "",
                "defaultParentId", item["parentId"],
                "parentId", item["parentId"],
                "hidden", item.Has("visible") && item["visible"] != true,
                "pinned", item.Has("pinned") && item["pinned"] = true,
                "order", item.Has("order") ? item["order"] : 0
            ))
    return result
}

CommandPaletteConfigResolveActions(source, baseActions) {
    global COMMAND_PALETTE_CONFIG

    if ((source = "Global" && COMMAND_PALETTE_CONFIG["menus"].Count = 0)
        || (source != "Global" && !COMMAND_PALETTE_CONFIG["menus"].Has(source)))
        return baseActions
    resolved := Map()
    sources := source = "Global" ? CommandPaletteConfigSources() : [source]
    for _, menuSource in sources
        for _, item in COMMAND_PALETTE_CONFIG["menus"][menuSource]["items"] {
            if item["kind"] != "action"
                continue
            actionId := item["actionId"]
            if baseActions.Has(actionId)
                resolved[item["id"]] := baseActions[actionId]
        }
    return resolved
}

CommandPaletteConfigBuildChordItems(source) {
    global COMMAND_PALETTE_CONFIG

    if !COMMAND_PALETTE_CONFIG["menus"].Has(source)
        return Map()
    menu := COMMAND_PALETTE_CONFIG["menus"][source]
    byParent := Map()
    for _, item in menu["items"] {
        parentId := item["parentId"]
        if !byParent.Has(parentId)
            byParent[parentId] := []
        byParent[parentId].Push(item)
    }
    return CommandPaletteConfigBuildChordChildren("", byParent)
}

CommandPaletteConfigBuildChordChildren(parentId, byParent) {
    result := Map()
    if !byParent.Has(parentId)
        return result
    for _, item in byParent[parentId] {
        if item.Has("visible") && item["visible"] != true
            continue
        entry := item["kind"] = "group"
            ? { label: item["label"], items: CommandPaletteConfigBuildChordChildren(item["id"], byParent) }
            : ChordEntry(item["actionId"], item["label"])
        CommandPaletteConfigInsertChordEntry(result, item["chordPath"], entry)
    }
    return result
}

CommandPaletteConfigInsertChordEntry(target, chordPath, entry) {
    current := target
    for index, rawKey in chordPath {
        key := ChordNormalizeSuffixKey(rawKey)
        if key = ""
            return false
        if index = chordPath.Length {
            if current.Has(key)
                throw Error("Duplicate chord path at " . key)
            current[key] := entry
            return true
        }
        if !current.Has(key)
            current[key] := { label: key, items: Map() }
        current := current[key].items
    }
    return false
}
