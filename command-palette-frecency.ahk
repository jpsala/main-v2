; Local exponentially-decayed usage ranking for the command palette.

global COMMAND_PALETTE_FRECENCY := Map()
global COMMAND_PALETTE_FRECENCY_HALF_LIFE_SECONDS := 14 * 24 * 60 * 60
global COMMAND_PALETTE_FRECENCY_STATE_PATH := EnvGet("LOCALAPPDATA") . "\main-v2\command-palette-frecency.json"

CommandPaletteFrecencyInit() {
    CommandPaletteFrecencyLoad()
}

CommandPaletteFrecencyLoad() {
    global COMMAND_PALETTE_FRECENCY, COMMAND_PALETTE_FRECENCY_STATE_PATH

    COMMAND_PALETTE_FRECENCY := Map()
    if !FileExist(COMMAND_PALETTE_FRECENCY_STATE_PATH)
        return

    try {
        json := FileRead(COMMAND_PALETTE_FRECENCY_STATE_PATH, "UTF-8")
        payload := JsonLoad(&json)
        if (!payload.Has("version") || payload["version"] != 1 || !payload.Has("entries"))
            return
        for id, entry in payload["entries"] {
            if (!IsObject(entry) || !entry.Has("score") || !entry.Has("lastUsed"))
                continue
            score := entry["score"]
            lastUsed := entry["lastUsed"]
            if !(score is Number) || score < 0
                continue
            try DateDiff(A_NowUTC, lastUsed, "Seconds")
            catch
                continue
            COMMAND_PALETTE_FRECENCY[id] := Map("score", score, "lastUsed", lastUsed)
        }
    } catch Error as e {
        OutputDebug("Command palette frecency load error: " . e.Message)
    }
}

CommandPaletteFrecencyRecordUse(actionId, now := "") {
    global COMMAND_PALETTE_BY_ID

    if !COMMAND_PALETTE_BY_ID.Has(actionId)
        return
    now := now != "" ? now : A_NowUTC
    id := actionId
    while (id != "") {
        CommandPaletteFrecencyApply(id, now)
        id := COMMAND_PALETTE_BY_ID[id]["parentId"]
    }
    CommandPaletteFrecencySave()
}

CommandPaletteFrecencyApply(id, now) {
    global COMMAND_PALETTE_FRECENCY

    score := COMMAND_PALETTE_FRECENCY.Has(id)
        ? CommandPaletteFrecencyScore(COMMAND_PALETTE_FRECENCY[id], now)
        : 0
    COMMAND_PALETTE_FRECENCY[id] := Map("score", score + 1, "lastUsed", now)
}

CommandPaletteFrecencyScore(entry, now := "") {
    global COMMAND_PALETTE_FRECENCY_HALF_LIFE_SECONDS

    now := now != "" ? now : A_NowUTC
    elapsedSeconds := Max(0, DateDiff(now, entry["lastUsed"], "Seconds"))
    return entry["score"] * (0.5 ** (elapsedSeconds / COMMAND_PALETTE_FRECENCY_HALF_LIFE_SECONDS))
}

CommandPaletteFrecencyGetSnapshot(now := "") {
    global COMMAND_PALETTE_BY_ID, COMMAND_PALETTE_FRECENCY

    now := now != "" ? now : A_NowUTC
    snapshot := Map()
    for id, entry in COMMAND_PALETTE_FRECENCY {
        if COMMAND_PALETTE_BY_ID.Has(id)
            snapshot[id] := CommandPaletteFrecencyScore(entry, now)
    }
    return snapshot
}

CommandPaletteFrecencySave() {
    global COMMAND_PALETTE_FRECENCY, COMMAND_PALETTE_FRECENCY_STATE_PATH

    try {
        SplitPath(COMMAND_PALETTE_FRECENCY_STATE_PATH,, &directory)
        DirCreate(directory)
        temporaryPath := COMMAND_PALETTE_FRECENCY_STATE_PATH . ".tmp"
        if FileExist(temporaryPath)
            FileDelete(temporaryPath)
        FileAppend(JsonDump(Map("version", 1, "entries", COMMAND_PALETTE_FRECENCY)), temporaryPath, "UTF-8")
        FileMove(temporaryPath, COMMAND_PALETTE_FRECENCY_STATE_PATH, 1)
    } catch Error as e {
        OutputDebug("Command palette frecency save error: " . e.Message)
    }
}
