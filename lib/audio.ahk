;===============================================================================
; AUDIO MODULE
; Volume control, sound effects, and audio device management
;===============================================================================

;===============================================================================
; VOLUME CONTROL
;===============================================================================

global VOLUME_HUD_GUI   := false
global VOLUME_HUD_READY := false
global VOLUME_HUD_SHOWN := false
global AUDIO_DEVICE_GUI := false
global AUDIO_DEVICE_READY := false
global AUDIO_DEVICE_FAVORITES := false

VolumeHudInit() {
    global VOLUME_HUD_GUI, VOLUME_HUD_READY
    if IsObject(VOLUME_HUD_GUI)
        return
    VOLUME_HUD_READY := false
    dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
    VOLUME_HUD_GUI := WebViewGui("+AlwaysOnTop -Caption +ToolWindow", "Volume HUD",, {DllPath: dllPath})
    VOLUME_HUD_GUI.Control.wv.add_NavigationCompleted(VolumeHudNavCompleted)
    VOLUME_HUD_GUI.Navigate("ui/volume-hud.html")
}

VolumeHudNavCompleted(wv, args) {
    global VOLUME_HUD_READY
    VOLUME_HUD_READY := true
}

volChange(steps := 1) {
    vol := SoundGetVolume()
    vol -= steps
    SoundSetVolume(vol)
    showVol(vol)
}

showVol(vol) {
    global VOLUME_HUD_GUI, VOLUME_HUD_READY, VOLUME_HUD_SHOWN
    try {
        if !IsObject(VOLUME_HUD_GUI)
            VolumeHudInit()

        waitStart := A_TickCount
        while (!VOLUME_HUD_READY && (A_TickCount - waitStart) < 2000)
            Sleep(30)

        if !VOLUME_HUD_READY
            return

        hudW := 260
        hudH := 44
        if (!VOLUME_HUD_SHOWN) {
            CoordMode("Mouse", "Screen")
            MouseGetPos(&mx, &my)
            monL := 0, monT := 0, monR := A_ScreenWidth
            loop MonitorGetCount() {
                MonitorGet(A_Index, &ml, &mt, &mr, &mb)
                if (mx >= ml && mx < mr && my >= mt && my < mb) {
                    monL := ml, monT := mt, monR := mr
                    break
                }
            }
            x := monL + (monR - monL - hudW) // 2
            y := monT + 20
            VOLUME_HUD_GUI.Show("x" . x . " y" . y . " w" . hudW . " h" . hudH . " NoActivate")
            VOLUME_HUD_SHOWN := true
        }

        try VOLUME_HUD_GUI.Control.ExecuteScript("updateVolume(" . Round(vol) . ");")
        SetTimer(VolumeHudHide, -1500)
    } catch Error as e {
        msgV1('Error showing volume: ' . e.Message)
    }
}

VolumeHudHide() {
    global VOLUME_HUD_GUI, VOLUME_HUD_SHOWN
    if IsObject(VOLUME_HUD_GUI)
        VOLUME_HUD_GUI.Hide()
    VOLUME_HUD_SHOWN := false
}

SaveOrRestoreVolume(value?) {
    static storedVolume := ''
    if (storedVolume != "") {
        SoundSetVolume(storedVolume)
        storedVolume := ""
    } else if (IsSet(value) and IsNumber(value)) {
        storedVolume := SoundGetVolume()
        SoundSetVolume(value)
    }
}

/**
 * Plays a beep sound with configurable volume
 * @param {number} frequency - The frequency of the beep in Hz (default: 523)
 * @param {number} duration - Duration of the beep in milliseconds (default: 150)
 * @param {number|string} volParam - Volume level or percentage of current volume (default: currentVol())
 * @param {number} minVal - Minimum volume level (default: 0)
 * @param {number} maxVal - Maximum volume level (default: 100)
 * @param {boolean} withDebug - Whether to log debug information (default: false)
 */
SoundBeepWithVol(frequency := 523, duration := 150, volParam := currentVol(), minVal := 0, maxVal := 100, withDebug := false) {
    currentVol := SoundGetVolume()

    ; Calculate volume based on volParam type
    if (!IsSet(volParam) || volParam == "") {
        vol := currentVol
    } else if (Type(volParam) == "String" && InStr(volParam, "%")) {
        volStr := StrReplace(volParam, "%", "")
        vol := currentVol * (Number(volStr) / 100)
    } else if (Type(volParam) == "Integer" || Type(volParam) == "Float") {
        vol := volParam
    } else {
        vol := currentVol
    }

    if (minVal and not IsSet(maxVal)) {
        msg('minVal is set but maxVal is not set in SoundBeepWithVol')
    }

    ; Clamp volume between min and max values if both are set
    if (IsSet(minVal) && minVal != "" && IsSet(maxVal) && maxVal != "") {
        vol := Min(Max(vol, minVal), maxVal)
    }

    ; Log debug info if requested
    if (withDebug) {
        log('volParam:' (IsSet(volParam) ? volParam : "unset") ' - Vol: ' vol ' - Min: ' (IsSet(minVal) ? minVal : "unset") ' - Max: ' (IsSet(maxVal) ? maxVal : "unset") ' - CurrentVol: ' currentVol)
    }

    ; Temporarily change volume, play beep, then restore original volume
    SaveOrRestoreVolume(vol)
    SoundBeep(frequency, duration)
    SaveOrRestoreVolume()
}

;===============================================================================
; SOUND EFFECTS
;===============================================================================

soundError(volParam := SoundGetVolume(), minVal := 0, maxVal := 100, withDebug := false) {
    ; Simply call SoundBeepWithVol twice, all parameter checking happens there
    SoundBeepWithVol(140, 100, volParam, minVal, maxVal, withDebug)
    SoundBeepWithVol(140, 100, volParam, minVal, maxVal, withDebug)
}

soundOk(volParam := SoundGetVolume(), minVal := 0, maxVal := 100, withDebug := false) {
    ; Simply call SoundBeepWithVol, all parameter checking happens there
    SoundBeepWithVol(3000, 15, volParam, minVal, maxVal, withDebug)
}

soundHigh(volParam := SoundGetVolume(), minVal := 0, maxVal := 100, withDebug := false, frequency := 5000, duration := 100) {
    ; Simply call SoundBeepWithVol, all parameter checking happens there
    msg('soundHigh')
    SoundBeepWithVol(frequency, duration, volParam, minVal, maxVal, withDebug)
}

;===============================================================================
; AUDIO DEVICE MANAGEMENT
;===============================================================================

changeAudioDevice(device) {
    try {
        nircmdExe := GetCachedConfig("desktop", "nircmd_exe", "")
        if (!nircmdExe) {
            msgV1("Error: Missing nircmd path in config.ini", 3)
            return
        }
        Run(nircmdExe . " setdefaultsounddevice " '"' device '"')  ; change device using nircmd
    } catch Error as e {
        log('Error changing audio device', device, e.Message)
        MsgBox('Error changing audio device: ' device ' /  ' e.Message)
        try {
            run(nircmdExe . ' showsounddevices')
        } catch Error as e {
            log('Error showing audio devices', e.Message)
        }
    }
}

showNirCmdAudioDevices() {
    nircmdExe := GetCachedConfig("desktop", "nircmd_exe", "")
    if (!nircmdExe) {
        msgV1("Error: Missing nircmd path in config.ini", 3)
        return
    }
    run(nircmdExe . ' showsounddevices')
}

;===============================================================================
; AUDIO DEVICE SWITCHER
;===============================================================================

ShowAudioDeviceSwitcher() {
    global AUDIO_DEVICE_GUI, AUDIO_DEVICE_READY

    if (AUDIO_DEVICE_GUI) {
        try {
            AUDIO_DEVICE_GUI.Show()
            WinActivate(AUDIO_DEVICE_GUI.hwnd)
            AudioDeviceSwitcherSendState()
            return
        } catch {
            AUDIO_DEVICE_GUI := false
        }
    }

    AUDIO_DEVICE_READY := false
    try {
        dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
        AUDIO_DEVICE_GUI := WebViewGui("+Resize -Caption +AlwaysOnTop", "Audio Devices",, {DllPath: dllPath, DefaultWidth: 760, DefaultHeight: 560})
        AUDIO_DEVICE_GUI.BackColor := "15151D"
        AUDIO_DEVICE_GUI.OnEvent("Close", (*) => CloseAudioDeviceSwitcher())
        AUDIO_DEVICE_GUI.OnEvent("Escape", (*) => CloseAudioDeviceSwitcher())
        AUDIO_DEVICE_GUI.Control.wv.add_WebMessageReceived(AudioDeviceSwitcherHandleMessage)
        AUDIO_DEVICE_GUI.Control.wv.add_NavigationCompleted(AudioDeviceSwitcherNavigationCompleted)
        AUDIO_DEVICE_GUI.Navigate("ui/audio-devices.html")
        AUDIO_DEVICE_GUI.Show("w760 h560 Hide")
        WebViewWindowStateRestoreOrCenter(AUDIO_DEVICE_GUI, "audioDevices", 760, 560, true, true)
        AUDIO_DEVICE_GUI.Show()
    } catch Error as e {
        AUDIO_DEVICE_GUI := false
        MsgBox("Error creando selector de audio: " . e.Message, "Audio Devices", "Icon!")
    }
}

AudioDeviceSwitcherNavigationCompleted(wv, args) {
    global AUDIO_DEVICE_READY
    AUDIO_DEVICE_READY := true
    AudioDeviceSwitcherSendState()
}

AudioDeviceSwitcherHandleMessage(wv, args) {
    global AUDIO_DEVICE_GUI
    try {
        json := args.WebMessageAsJson
        data := JsonLoad(&json)
        action := data.Has("action") ? data["action"] : ""

        switch action {
            case "ready":
                AudioDeviceSwitcherSendState()
            case "refresh":
                AudioDeviceSwitcherSendState()
            case "activate":
                if (data.Has("name")) {
                    changeAudioDevice(data["name"])
                    AudioDeviceSwitcherRefreshSoon()
                }
            case "toggleFavorite":
                if (data.Has("kind") && data.Has("name")) {
                    AudioDeviceSwitcherToggleFavorite(data["kind"], data["name"])
                    AudioDeviceSwitcherSendState()
                }
            case "minimize":
                if (AUDIO_DEVICE_GUI)
                    AUDIO_DEVICE_GUI.Minimize()
            case "close":
                CloseAudioDeviceSwitcher()
        }
    } catch Error as e {
        log("Audio device switcher message error", e.Message)
    }
}

AudioDeviceSwitcherRefreshSoon() {
    ; NirCmd/Windows can report the old default for a short moment after switching.
    SetTimer(() => AudioDeviceSwitcherSendState(), -250)
    SetTimer(() => AudioDeviceSwitcherSendState(), -900)
    SetTimer(() => AudioDeviceSwitcherSendState(), -1800)
}

AudioDeviceSwitcherSendState() {
    global AUDIO_DEVICE_GUI, AUDIO_DEVICE_READY
    if (!AUDIO_DEVICE_GUI || !AUDIO_DEVICE_READY)
        return

    try {
        hasNirCmd := GetCachedConfig("desktop", "nircmd_exe", "") ? true : false
        state := Map(
            "action", "state",
            "devices", AudioDeviceSwitcherGetDevices(),
            "hasNirCmd", hasNirCmd,
            "hotkey", "Win+A, A"
        )
        AUDIO_DEVICE_GUI.Control.wv.PostWebMessageAsJson(JsonDump(state))
    } catch Error as e {
        log("Audio device switcher send state error", e.Message)
    }
}

AudioDeviceSwitcherGetDevices() {
    favorites := AudioDeviceSwitcherLoadFavorites()
    playbackDefault := AudioDeviceSwitcherGetDefaultInfo("playback")
    captureDefault := AudioDeviceSwitcherGetDefaultInfo("capture")

    return Map(
        "playback", AudioDeviceSwitcherEnumKind("playback", playbackDefault, favorites),
        "capture", AudioDeviceSwitcherEnumKind("capture", captureDefault, favorites)
    )
}

AudioDeviceSwitcherEnumKind(kind, defaultInfo, favorites) {
    devices := []
    seen := Map()

    baseKey := "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\" . (kind = "capture" ? "Capture" : "Render")
    nameValue := "{a45c254e-df1c-4efd-8020-67d146a850e0},2"
    descriptionValue := "{b3f8fa53-0004-438e-9003-51a46e139bfc},6"
    busValue := "{a45c254e-df1c-4efd-8020-67d146a850e0},24"

    try {
        Loop Reg, baseKey, "K" {
            endpointKey := baseKey . "\" . A_LoopRegName
            try deviceState := RegRead(endpointKey, "DeviceState")
            catch
                continue

            if (deviceState != 1)
                continue

            try name := RegRead(endpointKey . "\Properties", nameValue)
            catch
                continue

            description := AudioDeviceSwitcherReadReg(endpointKey . "\Properties", descriptionValue)
            bus := AudioDeviceSwitcherReadReg(endpointKey . "\Properties", busValue)
            AudioDeviceSwitcherPushDevice(devices, seen, kind, name, defaultInfo, favorites, description, bus, A_LoopRegName)
        }
    }

    if (devices.Length)
        return devices

    ; Fallback for machines where MMDevices registry access is restricted.
    prefix := kind = "capture" ? "Capture:" : "Playback:"

    Loop 40 {
        deviceSpec := prefix . A_Index
        try name := SoundGetName(, deviceSpec)
        catch
            break

        AudioDeviceSwitcherPushDevice(devices, seen, kind, name, defaultInfo, favorites)
    }

    return devices
}

AudioDeviceSwitcherReadReg(keyName, valueName, default := "") {
    try return RegRead(keyName, valueName)
    catch
        return default
}

AudioDeviceSwitcherPushDevice(devices, seen, kind, name, defaultInfo, favorites, description := "", bus := "", id := "") {
    if (!name)
        return

    seenKey := name . "|" . description . "|" . bus
    if (seen.Has(seenKey))
        return

    seen[seenKey] := true
    devices.Push(Map(
        "kind", kind,
        "id", id,
        "name", name,
        "description", description,
        "bus", bus,
        "active", AudioDeviceSwitcherMatchesDefault(defaultInfo, id, name, description, bus),
        "favorite", AudioDeviceSwitcherIsFavorite(favorites, kind, name)
    ))
}

AudioDeviceSwitcherGetDefaultInfo(kind) {
    return Map(
        "id", AudioDeviceSwitcherGetDefaultId(kind),
        "names", AudioDeviceSwitcherGetDefaultNames(kind)
    )
}

AudioDeviceSwitcherGetDefaultId(kind) {
    try {
        enumerator := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
        flow := kind = "capture" ? 1 : 0
        role := 1 ; eMultimedia, the default shown by normal Windows sound settings.
        pDevice := 0
        hr := ComCall(4, enumerator, "int", flow, "int", role, "ptr*", &pDevice)
        if (hr != 0 || !pDevice)
            return ""

        pId := 0
        hr := ComCall(5, pDevice, "ptr*", &pId)
        ObjRelease(pDevice)
        if (hr != 0 || !pId)
            return ""

        id := StrGet(pId, "UTF-16")
        DllCall("Ole32.dll\CoTaskMemFree", "ptr", pId)
        return id
    } catch Error as e {
        log("Audio default endpoint lookup failed", kind, e.Message)
        return ""
    }
}

AudioDeviceSwitcherGetDefaultNames(kind) {
    names := []

    if (kind = "playback") {
        AudioDeviceSwitcherPushDefaultName(names, AudioDeviceSwitcherTrySoundGetName())
        AudioDeviceSwitcherPushDefaultName(names, AudioDeviceSwitcherTrySoundGetName(, "Playback"))
        AudioDeviceSwitcherPushDefaultName(names, AudioDeviceSwitcherReadSoundMapper("Playback"))
    } else {
        AudioDeviceSwitcherPushDefaultName(names, AudioDeviceSwitcherTrySoundGetName(, "Capture"))
        AudioDeviceSwitcherPushDefaultName(names, AudioDeviceSwitcherTrySoundGetName(, "Recording"))
        AudioDeviceSwitcherPushDefaultName(names, AudioDeviceSwitcherReadSoundMapper("Record"))
    }

    return names
}

AudioDeviceSwitcherTrySoundGetName(component?, device?) {
    try {
        if (IsSet(component) && IsSet(device))
            return SoundGetName(component, device)
        if (IsSet(device))
            return SoundGetName(, device)
        return SoundGetName()
    } catch {
        return ""
    }
}

AudioDeviceSwitcherReadSoundMapper(valueName) {
    try return RegRead("HKCU\Software\Microsoft\Multimedia\Sound Mapper", valueName)
    catch
        return ""
}

AudioDeviceSwitcherPushDefaultName(names, name) {
    if (!name)
        return
    for existing in names {
        if (existing = name)
            return
    }
    names.Push(name)
}

AudioDeviceSwitcherMatchesDefault(defaultInfo, endpointGuid, name, description := "", bus := "") {
    if (IsObject(defaultInfo) && defaultInfo.Has("id") && endpointGuid) {
        if (InStr(StrLower(defaultInfo["id"]), StrLower(endpointGuid)))
            return true
    }

    defaultNames := IsObject(defaultInfo) && defaultInfo.Has("names") ? defaultInfo["names"] : defaultInfo
    candidates := [name, description, bus]
    for defaultName in defaultNames {
        normalizedDefault := AudioDeviceSwitcherNormalizeName(defaultName)
        if (!normalizedDefault)
            continue
        for candidate in candidates {
            normalizedCandidate := AudioDeviceSwitcherNormalizeName(candidate)
            if (!normalizedCandidate)
                continue
            if (normalizedCandidate = normalizedDefault)
                return true
            if (InStr(normalizedCandidate, normalizedDefault) || InStr(normalizedDefault, normalizedCandidate))
                return true
        }
    }
    return false
}

AudioDeviceSwitcherNormalizeName(value) {
    value := StrLower(Trim(value))
    value := RegExReplace(value, "\s+", " ")
    value := RegExReplace(value, "\s*\([^)]*\)\s*", " ")
    return Trim(value)
}

AudioDeviceSwitcherLoadFavorites() {
    global AUDIO_DEVICE_FAVORITES
    favorites := Map("playback", [], "capture", [])

    try section := IniRead("config.ini", "audioDeviceFavorites")
    catch {
        AUDIO_DEVICE_FAVORITES := favorites
        return favorites
    }

    for line in StrSplit(section, "`n", "`r") {
        if (!line || !InStr(line, "="))
            continue
        parts := StrSplit(line, "=",, 2)
        key := parts[1]
        name := parts.Length >= 2 ? parts[2] : ""
        if (!name)
            continue
        if (RegExMatch(key, "i)^playback\d+$"))
            favorites["playback"].Push(name)
        else if (RegExMatch(key, "i)^capture\d+$"))
            favorites["capture"].Push(name)
    }

    AUDIO_DEVICE_FAVORITES := favorites
    return favorites
}

AudioDeviceSwitcherSaveFavorites(favorites) {
    try IniDelete("config.ini", "audioDeviceFavorites")
    catch {
    }

    for kind in ["playback", "capture"] {
        index := 1
        for name in favorites[kind] {
            IniWrite(name, "config.ini", "audioDeviceFavorites", kind . index)
            index += 1
        }
    }
}

AudioDeviceSwitcherIsFavorite(favorites, kind, name) {
    for favoriteName in favorites[kind] {
        if (favoriteName = name)
            return true
    }
    return false
}

AudioDeviceSwitcherToggleFavorite(kind, name) {
    favorites := AudioDeviceSwitcherLoadFavorites()
    if (!favorites.Has(kind))
        return

    next := []
    removed := false
    for favoriteName in favorites[kind] {
        if (favoriteName = name) {
            removed := true
            continue
        }
        next.Push(favoriteName)
    }

    if (!removed)
        next.Push(name)

    favorites[kind] := next
    AudioDeviceSwitcherSaveFavorites(favorites)
}

CloseAudioDeviceSwitcher(*) {
    global AUDIO_DEVICE_GUI, AUDIO_DEVICE_READY
    if (AUDIO_DEVICE_GUI) {
        hwnd := AUDIO_DEVICE_GUI.Hwnd
        WebViewWindowStateSave(hwnd)
        try AUDIO_DEVICE_GUI.Destroy()
        WebViewWindowStateForget(hwnd)
        AUDIO_DEVICE_GUI := false
        AUDIO_DEVICE_READY := false
    }
}

openMixer() {
    if (WinExist("Settings")) {
        if (WinActive("Settings")) {
            WinMinimize("Settings")
            return
        }
        msgV1('exists')
        WinActivateFast("Settings")
        return
    }
    KeyWait("LWin")
    KeyWait('Alt')
    BlockInput(true)
    send('{LWin}')
    Sleep(300)
    send('mixer')
    Sleep(300)
    send('{Enter}')
    BlockInput(false)
}
