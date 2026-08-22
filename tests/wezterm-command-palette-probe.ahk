#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(WezTermCommandPaletteProbeUnhandledError)

#Include ..\lib\json.ahk
#Include ..\open-wezterm-command-palette.ahk
#Include ..\wezterm-command-palette.ahk

global WEZTERM_COMMAND_PALETTE_PROBE_STATE_PATH := A_Temp
    . "\wezterm-command-palette-probe-" . DllCall("Kernel32\GetCurrentProcessId", "UInt") . ".txt"
global WEZTERM_COMMAND_PALETTE_PROBE_ORIGINAL_STATE_PATH := WEZTERM_COMMAND_PALETTE_BRIDGE_PATH
probeError := 0
try {
    WezTermCommandPaletteProbeRun()
} catch as e {
    probeError := e
}

try {
    WezTermCommandPaletteProbeCleanup()
} catch as e {
    if !IsObject(probeError)
        probeError := e
}

if IsObject(probeError)
    WezTermCommandPaletteProbeFail(probeError)

FileAppend("PASS`n", "*")
ExitApp(0)

WezTermCommandPaletteProbeRun() {
    global WEZTERM_COMMAND_PALETTE_CATALOG_PATH, WEZTERM_COMMAND_PALETTE_PROJECTS_PATH
    global WEZTERM_COMMAND_PALETTE_SNAPSHOT_FINGERPRINT
    global WEZTERM_COMMAND_PALETTE_BRIDGE_PATH, WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY
    global WEZTERM_COMMAND_PALETTE_PROBE_STATE_PATH
    global WEZTERM_COMMAND_PALETTE_ENTRIES, WEZTERM_COMMAND_PALETTE_ACTION_PATHS

    WezTermCommandPaletteProbeAssert(
        WEZTERM_COMMAND_PALETTE_CATALOG_PATH = "C:\dev\wezterm\config\command-menu.json",
        "catalog path"
    )
    WezTermCommandPaletteProbeAssert(
        WEZTERM_COMMAND_PALETTE_PROJECTS_PATH = "C:\dev\wezterm\OMP-PROJECTS.md",
        "projects path"
    )
    openMessageId := WezTermCommandPaletteOpenMessageId()
    WezTermCommandPaletteProbeAssert(
        openMessageId > 0 && openMessageId = WezTermCommandPaletteOpenMessageId(),
        "registered open message"
    )
    WezTermCommandPaletteProbeAssert(
        WezTermCommandPaletteOpenFromMessage(0, 0) = 0,
        "invalid open request rejected"
    )
    WezTermCommandPaletteProbeProtocol(WEZTERM_COMMAND_PALETTE_PROBE_STATE_PATH)
    WEZTERM_COMMAND_PALETTE_BRIDGE_PATH := WEZTERM_COMMAND_PALETTE_PROBE_STATE_PATH


    snapshot := WezTermCommandPaletteReadSnapshot(
        WEZTERM_COMMAND_PALETTE_CATALOG_PATH,
        WEZTERM_COMMAND_PALETTE_PROJECTS_PATH
    )
    WezTermCommandPaletteProbeAssert(
        snapshot.fingerprint = "6c108c5a",
        "snapshot fingerprint"
    )
    WezTermCommandPaletteProbeAssert(
        RegExMatch(snapshot.fingerprint, "^[0-9a-f]{8}$"),
        "wire fingerprint shape"
    )

    catalogText := snapshot.catalogText
    catalog := JsonLoad(&catalogText)
    WezTermCommandPaletteValidateCatalog(catalog)
    WezTermCommandPaletteProbeAssert(catalog["providerKeys"].Length = 36, "provider key count")
    WezTermCommandPaletteProbeAssert(catalog["themes"].Length = 33, "theme count")

    projects := WezTermCommandPaletteLoadProjects(snapshot.projectsText)
    expectedProjects := [
        "os",
        "dictation-tauri",
        "copicu",
        "constelaciones",
        "omp",
        "fixvox",
        "infra",
        "wezterm"
    ]
    WezTermCommandPaletteProbeAssert(projects.Length = expectedProjects.Length, "enabled project count")
    for index, expectedProject in expectedProjects
        WezTermCommandPaletteProbeAssert(projects[index] = expectedProject, "project " . index)

    palette := WezTermCommandPaletteBuildPalette(catalog["items"], catalog, projects)
    WezTermCommandPaletteProbeAssert(palette.catalog.Length = 85, "palette record count")
    WezTermCommandPaletteProbeAssert(palette.paths.Count = 77, "palette dispatch count")
    records := Map()
    for _, record in palette.catalog
        records[record["id"]] := record

    WezTermCommandPaletteProbeAssert(
        records["WezTerm:p"]["kind"] = "group"
            && records["WezTerm:p"]["parentId"] = ""
            && records["WezTerm:p"]["depth"] = 1,
        "projects root group"
    )
    WezTermCommandPaletteProbeAssert(
        records["WezTerm:p1"]["parentId"] = "WezTerm:p"
            && records["WezTerm:p1"]["depth"] = 2,
        "project hierarchy"
    )
    WezTermCommandPaletteProbeAssert(
        records["WezTerm:at"]["kind"] = "group"
            && records["WezTerm:at"]["parentId"] = "WezTerm:a"
            && records["WezTerm:at"]["depth"] = 2,
        "theme selector hierarchy"
    )
    WezTermCommandPaletteProbeAssert(
        records["WezTerm:at1"]["parentId"] = "WezTerm:at"
            && records["WezTerm:at1"]["depth"] = 3,
        "theme action hierarchy"
    )
    WezTermCommandPaletteProbeAssert(palette.paths["WezTerm:p1"] = "p1", "first project path")
    WezTermCommandPaletteProbeAssert(records["WezTerm:p1"]["label"] = "OMP: os", "first project label")
    WezTermCommandPaletteProbeAssert(
        records["WezTerm:p1"]["breadcrumb"] = "Projects",
        "project breadcrumb"
    )
    WezTermCommandPaletteProbeAssert(palette.paths["WezTerm:p8"] = "p8", "last project path")
    WezTermCommandPaletteProbeAssert(
        records["WezTerm:p8"]["label"] = "OMP: wezterm",
        "last project label"
    )
    WezTermCommandPaletteProbeAssert(palette.paths["WezTerm:at1"] = "at1", "first theme path")
    WezTermCommandPaletteProbeAssert(
        records["WezTerm:at1"]["label"] = "Tango Dark",
        "first theme label"
    )
    WezTermCommandPaletteProbeAssert(
        records["WezTerm:at1"]["breadcrumb"] = "Appearance › Choose theme",
        "theme breadcrumb"
    )
    WezTermCommandPaletteProbeAssert(palette.paths["WezTerm:atw"] = "atw", "last theme path")
    WezTermCommandPaletteProbeAssert(
        records["WezTerm:atw"]["label"] = "Rose Pine Moon",
        "last theme label"
    )
    WezTermCommandPaletteProbeAssert(palette.paths["WezTerm:nr"] = "nr", "pane action path")
    WezTermCommandPaletteProbeAssert(palette.paths["WezTerm:zr"] = "zr", "reload action path")
    WezTermCommandPaletteProbeAssert(palette.paths["WezTerm:nm"] = "nm", "move pane path")
    groupCount := 0
    actionCount := 0
    for _, record in palette.catalog {
        if (record["kind"] = "group")
            groupCount += 1
        else if (record["kind"] = "action")
            actionCount += 1
        else
            WezTermCommandPaletteProbeAssert(false, "known palette record kind")
        WezTermCommandPaletteProbeAssert(
            record["shortcut"] = "Ctrl+Shift+P",
            "palette shortcut"
        )
    }
    WezTermCommandPaletteProbeAssert(groupCount = 8, "palette group count")
    WezTermCommandPaletteProbeAssert(actionCount = 77, "palette action count")

    WezTermCommandPaletteProbeAssert(InitWezTermCommandPalette(), "InitWezTermCommandPalette registration")
    WezTermCommandPaletteProbeAssert(
        WEZTERM_COMMAND_PALETTE_ENTRIES.Length = palette.catalog.Length,
        "registered palette size"
    )
    WezTermCommandPaletteProbeAssert(
        WEZTERM_COMMAND_PALETTE_ACTION_PATHS["WezTerm:p8"] = "p8",
        "registered project dispatch path"
    )
    WezTermCommandPaletteProbeAssert(
        WEZTERM_COMMAND_PALETTE_ACTION_PATHS["WezTerm:atw"] = "atw",
        "registered theme dispatch path"
    )
    WezTermCommandPaletteProbeAssert(
        WEZTERM_COMMAND_PALETTE_SNAPSHOT_FINGERPRINT = snapshot.fingerprint,
        "registered snapshot fingerprint"
    )
    WezTermCommandPaletteProbeAssert(
        !FileExist(WEZTERM_COMMAND_PALETTE_PROBE_STATE_PATH),
        "Init leaves no bridge request"
    )
    WezTermCommandPaletteProbeAssert(
        !WezTermCommandPaletteProbeAnyFile(WEZTERM_COMMAND_PALETTE_PROBE_STATE_PATH . ".*"),
        "Init leaves no bridge residue"
    )
    WezTermCommandPaletteProbeAssert(
        WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY = "",
        "Init leaves bridge idle"
    )
}

WezTermCommandPaletteProbeProtocol(statePath) {
    global WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY

    nonce := "0123456789abcdef"
    instance := "0011223344556677"
    fingerprint := "89abcdef"
    expires := WezTermCommandPaletteEpochSeconds() + 30
    writerToken := "1111111111111111"
    secondToken := "2222222222222222"

    WezTermCommandPaletteBridgeInitialize(statePath)
    WezTermCommandPaletteProbeAssert(
        WezTermCommandPaletteTryAcquireBridge(writerToken),
        "first dispatcher acquires busy token"
    )
    WezTermCommandPaletteProbeAssert(
        !WezTermCommandPaletteTryAcquireBridge(secondToken),
        "concurrent dispatcher fails closed"
    )
    WezTermCommandPaletteProbeAssert(
        !WezTermCommandPaletteReleaseBridge(secondToken),
        "non-owner cannot release busy token"
    )

    try {
        request := {
            nonce: nonce,
            phase: "claim",
            fingerprint: fingerprint,
            path: "p8",
            expires: expires
        }
        WezTermCommandPaletteWriteRequest(request, writerToken, statePath)
        actualRequest := WezTermCommandPaletteReadState(statePath)
        WezTermCommandPaletteProbeAssert(actualRequest.phase = "claim", "claim request round-trip")
        WezTermCommandPaletteProbeAssert(!actualRequest.HasOwnProp("instance"),
            "claim has no selected instance")

        claimed := {
            nonce: nonce,
            phase: "claimed",
            fingerprint: fingerprint,
            path: "p8",
            instance: instance,
            window: "42",
            expires: expires
        }
        claimPath := WezTermCommandPaletteProbePublishResponse(claimed, statePath)
        expectedClaimPath := statePath . ".response." . nonce . "." . instance
            . ".42.claimed.txt"
        WezTermCommandPaletteProbeAssert(
            StrLower(claimPath) = StrLower(expectedClaimPath),
            "immutable response filename"
        )
        duplicateRejected := false
        try WezTermCommandPaletteProbePublishResponse(claimed, statePath)
        catch
            duplicateRejected := true
        WezTermCommandPaletteProbeAssert(duplicateRejected, "immutable response is not replaced")
        discovered := WezTermCommandPaletteFindClaimedResponse(request, statePath)
        WezTermCommandPaletteProbeAssert(IsObject(discovered), "claim response discovery")
        WezTermCommandPaletteProbeAssert(discovered.instance = instance, "selected instance")
        WezTermCommandPaletteProbeAssert(discovered.window = "42", "selected window")

        request.instance := discovered.instance
        request.window := discovered.window
        for _, transition in [
            ["verify", "verified"],
            ["commit", "executing"],
            ["commit", "done"]
        ] {
            request.phase := transition[1]
            WezTermCommandPaletteWriteRequest(request, writerToken, statePath)
            response := {
                nonce: nonce,
                phase: transition[2],
                fingerprint: fingerprint,
                path: "p8",
                instance: instance,
                window: "42",
                expires: expires
            }
            responsePath := WezTermCommandPaletteProbePublishResponse(response, statePath)
            actualResponse := WezTermCommandPaletteReadState(responsePath)
            WezTermCommandPaletteValidateResponse(actualResponse, request)
            WezTermCommandPaletteProbeAssert(
                actualResponse.phase = transition[2],
                transition[2] . " response round-trip"
            )
        }

        validClaim := "version=2`nnonce=0123456789abcdef`nphase=claim`n"
            . "fingerprint=89abcdef`npath=p8`nexpires=" . expires . "`n"
        validVerified := StrReplace(validClaim, "phase=claim", "phase=verified")
        validVerified := StrReplace(
            validVerified,
            "expires=",
            "instance=" . instance . "`nwindow=42`nexpires="
        )
        invalidFrames := [
            SubStr(validClaim, 1, -2),
            StrReplace(validClaim, "`n", "`r`n"),
            StrReplace(validClaim, "version=2", "version=1"),
            StrReplace(validClaim, "0123456789abcdef", "0123456789abcdeF"),
            StrReplace(validClaim, "phase=claim", "phase=bogus"),
            StrReplace(validClaim, "fingerprint=89abcdef", "fingerprint=89abcdeg"),
            StrReplace(validClaim, "path=p8", "path=P8"),
            StrReplace(validClaim, "expires=" . expires, "expires=0" . expires),
            StrReplace(validClaim, "expires=", "instance=" . instance . "`nwindow=42`nexpires="),
            StrReplace(validVerified, "instance=" . instance, "instance=xyz"),
            StrReplace(validVerified, "window=42", "window=042"),
            StrReplace(validClaim, "path=p8", "extra=x`npath=p8"),
            StrReplace(validClaim, "nonce=", "nonce=" . Chr(1))
        ]
        for index, invalidFrame in invalidFrames
            WezTermCommandPaletteProbeAssertRejects(invalidFrame, "strict frame " . index)

        WezTermCommandPaletteCleanupNonce(nonce, writerToken, statePath)
        WezTermCommandPaletteProbeAssert(!FileExist(statePath), "request cleanup by nonce")
        WezTermCommandPaletteProbeAssert(
            !WezTermCommandPaletteProbeAnyFile(statePath . ".response." . nonce . ".*"),
            "response cleanup by nonce"
        )

        WezTermCommandPaletteProbeWriteText(statePath, WezTermCommandPaletteProbeRepeat("a", 512))
        boundaryAdmitted := false
        try WezTermCommandPaletteReadState(statePath)
        catch as err {
            boundaryAdmitted := err.Message != "invalid bridge frame size"
        }
        WezTermCommandPaletteProbeAssert(boundaryAdmitted, "512-byte frame reaches parser")
        FileDelete(statePath)

        WezTermCommandPaletteProbeWriteText(statePath, WezTermCommandPaletteProbeRepeat("a", 513))
        oversizedRejected := false
        try WezTermCommandPaletteReadState(statePath)
        catch as err {
            oversizedRejected := err.Message = "invalid bridge frame size"
        }
        WezTermCommandPaletteProbeAssert(oversizedRejected, "513-byte frame rejected at read bound")
        FileDelete(statePath)
    } finally {
        WezTermCommandPaletteCleanupNonce(nonce, writerToken, statePath)
        WezTermCommandPaletteReleaseBridge(writerToken)
        WezTermCommandPaletteBridgeInitialize(statePath)
    }

    WezTermCommandPaletteProbeAssert(
        WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY = "",
        "busy token released after handshake"
    )
    WezTermCommandPaletteProbeAssert(
        !WezTermCommandPaletteProbeAnyFile(statePath . "*"),
        "protocol round-trip cleanup"
    )
}

WezTermCommandPaletteProbePublishResponse(state, statePath) {
    destination := WezTermCommandPaletteResponsePath(state, state.phase, statePath)
    tempPath := destination . ".probe.tmp"
    WezTermCommandPaletteProbeAssert(!FileExist(destination), "response destination is new")
    try {
        WezTermCommandPaletteProbeWriteText(tempPath, WezTermCommandPaletteSerializeState(state))
        FileMove(tempPath, destination, false)
    } catch {
        try FileDelete(tempPath)
        throw
    }
    return destination
}

WezTermCommandPaletteProbeRepeat(text, count) {
    repeated := ""
    Loop count
        repeated .= text
    return repeated
}

WezTermCommandPaletteProbeWriteText(path, contents) {
    file := FileOpen(path, "w", "UTF-8-RAW")
    if !IsObject(file)
        throw Error("probe cannot open " . path)
    try file.Write(contents)
    finally file.Close()
}

WezTermCommandPaletteProbeAnyFile(pattern) {
    Loop Files pattern, "F"
        return true
    return false
}

WezTermCommandPaletteProbeAssertRejects(contents, label) {
    rejected := false
    try WezTermCommandPaletteParseState(contents)
    catch
        rejected := true
    WezTermCommandPaletteProbeAssert(rejected, label)
}

WezTermCommandPaletteProbeCleanup() {
    global WEZTERM_COMMAND_PALETTE_TARGET, WEZTERM_COMMAND_PALETTE_TARGET_TOKENS
    global WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK
    global WEZTERM_COMMAND_PALETTE_BRIDGE_PATH, WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY
    global WEZTERM_COMMAND_PALETTE_PROBE_STATE_PATH
    global WEZTERM_COMMAND_PALETTE_PROBE_ORIGINAL_STATE_PATH

    try {
        HotIf(WezTermCommandPaletteHotIf)
        try Hotkey("^+p", "Off")
        finally HotIf()
    } finally {
        WezTermCommandPaletteShutdown()
    }

    WezTermCommandPaletteProbeAssert(!WEZTERM_COMMAND_PALETTE_TARGET, "target cleanup")
    WezTermCommandPaletteProbeAssert(WEZTERM_COMMAND_PALETTE_TARGET_TOKENS.Count = 0, "target hook cleanup")
    WezTermCommandPaletteProbeAssert(!WEZTERM_COMMAND_PALETTE_WINEVENT_CALLBACK, "callback cleanup")
    if (WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY != "")
        WezTermCommandPaletteReleaseBridge(WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY)
    WezTermCommandPaletteBridgeInitialize(WEZTERM_COMMAND_PALETTE_PROBE_STATE_PATH)
    WEZTERM_COMMAND_PALETTE_BRIDGE_PATH := WEZTERM_COMMAND_PALETTE_PROBE_ORIGINAL_STATE_PATH
    WezTermCommandPaletteProbeAssert(
        !WezTermCommandPaletteProbeAnyFile(WEZTERM_COMMAND_PALETTE_PROBE_STATE_PATH . "*"),
        "bridge file-set cleanup"
    )
    WezTermCommandPaletteProbeAssert(
        WEZTERM_COMMAND_PALETTE_BRIDGE_BUSY = "",
        "bridge busy cleanup"
    )
}

WezTermCommandPaletteProbeAssert(condition, label) {
    if !condition
        throw Error("FAIL: " . label)
}

WezTermCommandPaletteProbeFail(errorValue) {
    try FileAppend(errorValue.Message . "`n" . errorValue.Stack . "`n", "**")
    ExitApp(1)
}

WezTermCommandPaletteProbeUnhandledError(thrown, mode) {
    try WezTermCommandPaletteProbeCleanup()
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    ExitApp(1)
    return true
}
