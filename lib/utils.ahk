;===============================================================================
; UTILITIES MODULE
; Miscellaneous utility functions: Arrays, Keyboard, Notifications, Timers
;===============================================================================

;===============================================================================
; KEYBOARD INPUT & SENDING
;===============================================================================

SendWithLevel(key, level := 1, beep := false) {
    levelSaved := A_SendLevel
    SendLevel(level)
    if (beep) {
        SoundBeepWithVol(200, 30)
    }
    Send(key)
    SendLevel levelSaved
}

SendAndShow(key, label := '', level := false, withDebug := false, gestureLength := 0) {
    if (level) {
        levelSaved := A_SendLevel
        SendLevel((level))
    }
    global isShow := false, show := ''
    if (isShow) {
        MsgBox(key ' ' . show . ' - ' . label)
    } else {
        Send(key)
        msg(key . (label ? ' - ' . label : '') . ' Ges. Length: ' . gestureLength, { seconds: 1 })
        if (withDebug) {
            log(key . (label ? ' - ' . label : ''))
        }
        Sleep(900)
    }
    if (level) {
        SendLevel levelSaved
    }
}

getKeyboardLayoutUsOrIntl() {
    static lastCheckedTime := 0
    static lastResult := ""

    hwnd := WinActive("A")
    if (!hwnd)
        hwnd := WinExist("A")

    ; Get the thread ID of the active window
    threadID := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt", 0)

    ; Get the keyboard layout ID for this thread
    layoutID := DllCall("GetKeyboardLayout", "UInt", threadID, "UInt")

    ; Get the system keyboard layout name
    buf := Buffer(KL_NAMELENGTH := 16)
    DllCall("GetKeyboardLayoutName", "Ptr", buf.Ptr)
    klID := StrGet(buf)

    ; Debug info - uncomment for troubleshooting
    return layoutID == '4026598409' ? 'INTL' : 'US'
}

;===============================================================================
; NOTIFICATIONS
;===============================================================================

msgV1(text, sec := 1, id := false, x := false, y := false) {
    msg(text, { seconds: sec, id: id, x: x, y: y })
}

notify(title := 'Main.ahk', text := '', seconds := 5, icon := '', muted := False) {
    ; Info icon	1	0x1	Iconi
    ; Warning icon	2	0x2		Icon!
    ; Error icon	3	0x3	Iconx
    ; Tray icon	4	0x4	N/A
    ; Do not play the notification sound.	16	0x10	Mute
    ; Use the large version of the icon.	32	0x20	N/A
    options := icon . ' ' . (muted ? 'Mute ' : ' ')
    milli := seconds * 1000
    TrayTip(text, title, options)
    SetTimer(RemoveNotify, milli)
}

notifu(message, type := 'info', seconds := 5, title := 'main.ahk', persistent := false) {
    log(seconds)
    notifuExe := GetCachedConfig("desktop", "notifu_exe", "")
    if (!notifuExe) {
        msgV1("Error: Missing notifu path in config.ini", 3)
        return
    }

    runCommand := notifuExe
    runCommand .= ' /t ' type
    runCommand .= ' /d ' (seconds * 1000)  ; Convertir segundos a milisegundos
    runCommand .= ' /p "' title . '"'
    runCommand .= ' /m "' message . '"'
    if (persistent) {
        runCommand .= ' /c'
    }

    A_Clipboard := runCommand
    Run(runCommand)
}

;===============================================================================
; TIMERS & SCHEDULED TASKS
;===============================================================================

; checkIfMouseIsOverTaskbar automatically activates the taskbar when the mouse hovers over its vertical position (1079 pixels).
; This is useful for auto-hidden taskbars or for quick access without clicking.
; It saves the currently active window before activating the taskbar. When the mouse moves away from the taskbar area (y < 1050),
; it restores the previously active window, creating a seamless workflow.
checkIfMouseIsOverTaskbar() {
    global winSaved
    if (mousePosY() = 1079 && !winSaved) {
        try winSaved := WinGetID("A")
        try winTitleSaved := WinGetTitle(winSaved)
        class := mousePosX() > 1920 ? 'Shell_SecondaryTrayWnd' : 'Shell_TrayWnd'
        WinActivate('ahk_class ' class)
    } else if (winSaved && mousePosY() < 1050) {
        WinActivate(winSaved)
        winSaved := false
    }
}

; This Hot If directive creates a context-sensitive hotkey for the left mouse button.
; It's active only when the primary or secondary taskbar is the active window.
; When the user clicks on the taskbar (which was activated by the function above),
; this hotkey intercepts the click. It resets the `winSaved` variable to `false`,
; which prevents the `checkIfMouseIsOverTaskbar` function from immediately switching back to the original window upon clicking.
; After resetting `winSaved`, it sends a normal left-click, allowing the user to interact with taskbar items as usual.
#HotIf winActive('ahk_class Shell_SecondaryTrayWnd') or winActive('ahk_class Shell_TrayWnd')
    LButton:: {
        msg('LButton')
        global winSaved
        winSaved := false
        send('{LButton}')
        msg('LButton')
        return  ; Block drag/click when over taskbar
    }
#HotIf

preventIdle() {
    SetScrollLockState(!GetKeyState("ScrollLock", "T"))
    Sleep(50)
    SetScrollLockState(!GetKeyState("ScrollLock", "T"))
}

onceADay() {
    CurrentDate := FormatTime(A_Now, "yyyy-MM-dd")
    StoredDate := IniRead("config.ini", "general", "lastDate", "")
    if (StoredDate !== CurrentDate) {
        changeAudioDevice("Headset Earphone") ; Headset Earphone / Speakers
        SoundSetVolume(5)
        msg('Changing to Headset Earphone', { seconds: 3 })
        SoundBeepWithVol(300, 600, 5)
    }
}

;===============================================================================
; ARRAY FUNCTIONS
;===============================================================================

InArray(array, value) {
    for i in array {
        if (i == value) {
            return true
        }
    }
    return false
}

arrayRemoveElByID(arr, id) {
    for idx, _id in arr {
        if (String(_id) == String(id)) {
            arr.RemoveAt(idx)
        }
    }
}

arrayJoin(array, delimiter := "`n") {
    result := ""
    for index, value in array {
        result .= value . delimiter
    }
    return RTrim(result, delimiter)  ; Remove the trailing delimiter
}

;===============================================================================
; APP INSTANCE TRACKING
;===============================================================================

LoadAppInstanceMap() {
    global appInstanceMap

    section := IniRead("config.ini", "appInstances", , "")
    ar := StrSplit(section, '`n')
    for line in ar {
        lineAr := StrSplit(line, '=')
        if (lineAr.Length == 2) {
            uid := lineAr[1]
            win := lineAr[2]
            if (WinExist(win) == 0) {
                IniDelete("config.ini", "appInstances", uid)
            } else {
                appInstanceMap[uid] := win
            }
        }
    }
}

SaveAppInstanceMap(ExitReason := '', ExitCode := '') {
    global appInstanceMap

    for uid, handle in appInstanceMap {
        if (WinExist(handle)) {
            IniWrite(String(handle), "config.ini", "appInstances", String(uid))
        } else {
            IniDelete("config.ini", "appInstances", String(uid))
        }
    }
}
