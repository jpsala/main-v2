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
