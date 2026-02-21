;===============================================================================
; AUDIO MODULE
; Volume control, sound effects, and audio device management
;===============================================================================

;===============================================================================
; VOLUME CONTROL
;===============================================================================

volChange(steps := 1) {
    vol := SoundGetVolume()
    vol -= steps
    SoundSetVolume(vol)
    showVol(vol)
}

showVol(vol) {
    try {
        mouseInfo := saveMouse()
        volumeGui['MyProgress'].Value := vol
        SetTimer(hideVolumeTimer, 500)
        options := 'X' mouseInfo.x + 5 ' Y' mouseInfo.y - (mouseInfo.y < 20 ? 0 : 20)
        volumeGui.show(WinActive('volumeGui') ? '' : options)
        restoreMouse(mouseInfo)
        try WinSetTransColor('Black', 'volumeGui')
        hideVolumeTimer() {
            SetTimer(, 0)
            volumeGui.Hide
        }
    } catch Error as e {
        msgV1('Error showing volume: ' . e.Message)
    }
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
