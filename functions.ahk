;*************************************
/*
 * FUNCTIONS.AHK
 * Utility functions for AutoHotkey scripts
 * Repository: gitlab.com/jpsala/scripts
*/
#Warn All, Off
global appInstanceMap := Map()  ; For tracking application instances
global aliasMap := Map()        ; For alias-based window management (NEW)


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
; SOUND EFFECTS & AUDIO DEVICE MANAGEMENT
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

changeAudioDevice(device) {
    try {
        nircmdExe := IniRead("config.ini", "desktop", "nircmd_exe", "")
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
    nircmdExe := IniRead("config.ini", "desktop", "nircmd_exe", "")
    if (!nircmdExe) {
        msgV1("Error: Missing nircmd path in config.ini2", 3)
        return
    }
    run(nircmdExe . ' showsounddevices')
}

MinimizeToTrayWithNirCmd(winTitle) {
    nircmdExe := IniRead("config.ini", "desktop", "nircmd_exe", "")
    if (!nircmdExe) {
        msgV1("Error: Missing nircmd path in config.ini", 3)
        return
    }
    Run(nircmdExe . ' win min title "' . winTitle . '"')
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

;===============================================================================
; WINDOW MANAGEMENT
;===============================================================================

WinActivateFast(WinTitle, WinText := '', ExcludeTitle := '', ExcludeText := '', delay := 0) {
    wd := SetWinDelay(delay)
    WinActivate(WinTitle, WinText, ExcludeTitle, ExcludeText)
    SetWinDelay(wd)
}

;===============================================================================
; BROWSER MANAGEMENT
;===============================================================================

setBrowserTitle(title?, dontExit := false) {
    clipSaved := A_Clipboard
    global lastBrowserTitle
    if (IsSet(title)) {
        lastBrowserTitle := title
    }
    msg('setBrowserTitle')
    Send('{esc}{F10}')
    Sleep(100)
    Send('{Enter}')
    Sleep(100)
    Send('l')
    Sleep(1)
    Send('w')
    if (IsSet(title)) {
        Sleep(100)
        Send(title)
        send('{Enter}')
    } else if (IsSet(lastBrowserTitle)) {
        A_Clipboard := ''
        Send('^a')
        Sleep(50)
        Send('^c')
        Sleep(50)
        ClipWait(0.5)
        if (A_Clipboard == '') {
            soundOk()
            Send(lastBrowserTitle)
        }
    }
    A_Clipboard := clipSaved
    soundOk(1)
    msg('done setBrowserTitle')
    if (!dontExit)
        send('{esc}')
}

;===============================================================================
; MOUSE & CURSOR MANAGEMENT
;===============================================================================

mouseClickAndSave(x, y) {
    mousePos := saveMouse()
    mouseClick('L', x, y,,0)
    return mousePos
}

saveMouse() {
    MouseGetPosWithCoordMode(&x, &y, 'Screen')
    mouseSaved := { x: x, y: y }
    return mouseSaved
}

restoreMouse(mouseInfo) {
    coorMode := CoordMode('Mouse', 'Screen')
    MouseMove(mouseInfo.x, mouseInfo.y, 0)
    CoordMode('Mouse', coorMode)
}

clickOnCurrenPos() {
    MouseGetPosWithCoordMode(&xpos, &ypos, 'Screen')
    MouseClick('Left', xpos, ypos, 1, 0, 'Down',)
    sleep(200)
}

MouseGetPosWithCoordMode(&X, &Y, _coordMode := 'Screen') {
    cm := CoordMode('Mouse', _coordMode)
    MouseGetPos(&X, &Y)
    CoordMode('Mouse', cm)
}

mousePosX(_coordMode := 'Screen') {
    cm := CoordMode('Mouse', _coordMode)
    MouseGetPos(&X, &Y)
    CoordMode('Mouse', cm)
    return X
}

mousePosY(_coordMode := 'Screen') {
    cm := CoordMode('Mouse', _coordMode)
    MouseGetPos(&X, &Y)
    CoordMode('Mouse', cm)
    return Y
}

;===============================================================================
; MONITOR & SCREEN MANAGEMENT
;===============================================================================

getMonitorInfo() {
    ; Set mouse coordinate mode to screen
    _coorMode := CoordMode('Mouse', 'Screen')
    monitor := 0
    ; Get current mouse position
    MouseGetPos(&X, &Y)
    found := false
    ; Loop through all monitors to find which one the mouse is in
    loop MonitorGetCount() {
        MonitorGet(A_Index, &MonLeft, &MonTop, &MonRight, &MonBottom)
        ; Check if mouse is within the current monitor's bounds
        found := (X >= MonLeft && X <= MonRight && Y >= MonTop && Y <= MonBottom)
        coords := getMouseCoords('Screen')
        if (found) {
            monitor := {
                monitor: A_Index,
                top: 0,
                left: 0,
                right: MonRight - MonLeft,
                bottom: MonBottom - MonTop,
                top_screen: 0,
                left_screen: MonLeft,
                right_screen: MonRight,
                bottom_screen: MonBottom,
                x: X - MonLeft,
                y: Y - MonTop,
                x_screen: X,
                y_screen: Y
            }
            break
        }
    }
    if (!found) {
        {
            monitor := {
                monitor: A_Index,
                top: MonTop,
                left: MonLeft,
                right: MonRight,
                bottom: MonBottom,
                top_screen: MonTop,
                left_screen: MonLeft,
                right_screen: MonRight,
                bottom_screen: MonBottom,
                x: 10,
                y: 10,
                x_screen: 10,
                y_screen: 10
            }
        }
        log(monitor.monitor, monitor.top, monitor.left, monitor.right, monitor.bottom, monitor.x, monitor.y)
    }
    ; Restore previous mouse coordinate mode
    CoordMode('Mouse', _coorMode)
    return monitor
}

getMouseCoords(_coordMode := 'Screen') {
    __coorMode := CoordMode('Mouse', _coordMode)
    MouseGetPos(&X, &Y)
    CoordMode('Mouse', __coorMode)
    return { x: X, y: Y, coordMode: __coorMode }
}

getMonitor() {
    cm := CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)
    monitorCount := MonitorGetCount()

    if (monitorCount == 1) {
        CoordMode("Mouse", cm)
        return 1
    }

    loop monitorCount {
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        if (x >= left && x <= right && y >= top && y <= bottom) {
            CoordMode("Mouse", cm)
            return A_Index
        }
    }

    CoordMode("Mouse", cm)
    return 1 ; Default to the first monitor if the mouse is not found on any monitor
}

;===============================================================================
; SCREEN AREAS & GRID MANAGEMENT
;===============================================================================

getAreaYX(y := 4, x := 4, areas := "", withMonitor := false, showLog := false, showTickCount := false, labelForDebug := false) {

    tc := A_TickCount
    winUnderMouse := GetWindowUnderMouse()
    WinActivateFast(winUnderMouse.id)
    tit := WinGetTitle('A')
    monitor := getMonitor()
    cm := CoordMode("Mouse", "Window")
    MouseGetPos(&xpos, &ypos)
    CoordMode('Mouse', 'Screen')
    MonitorGet(0, &Mon0L, &Mon0T, &Mon0R, &Mon0B)
    MonitorGet(1, &Mon1L, &Mon1T, &Mon1R, &Mon1B)
    ; monitor := (xpos <= Mon0R) ? 1 : 2

    ; Passing the monitor number only if withMonitor is true
    ret := calculateGridArea(xpos, ypos, (monitor == 1) ? Mon0L : Mon1L, (monitor == 1) ? Mon0R : Mon1R, (monitor == 1) ? Mon0B : Mon1B, y, x, areas, withMonitor ? monitor : "", showLog, labelForDebug)
    CoordMode("Mouse", cm)
    ticks := A_TickCount - tc
    if (showTickCount or (ticks > 5))
        msg('getAreaYX ticks', ticks, { seconds: 5 })
    return ret
}

calculateGridArea(x, y, l, r, b, rows, cols, areas, monitor := "", showLog := false, labelForDebug := false) {
    ; Adjust the x-coordinate relative to the left boundary of the active monitor
    x := x - l
    ctrl := GetKeyState("Ctrl", "P")
    currentX := Floor(x / ((r - l) / cols)) + 1
    currentY := Floor(y / (b / rows)) + 1
    currentArea := currentY . ":" . currentX
    if (monitor != "") {
        currentArea := currentArea
    }
    if (areas) {
        areaArray := StrSplit(areas, ",")
        found := 0
        foundArea := 'not found'
        for each, area in areaArray {
            if (showLog) {
                log(area . " " . currentArea)
            }
            if (area = currentArea || (monitor != "" && area = currentArea . "." . monitor) and !found) {
                found := 1
                foundArea := currentArea
            }
            if (showLog and found) {
                log(currentArea)
            }
        }
        if (showLog) {
            label := labelForDebug ? ' Label:' . labelForDebug : ''
            log('getAreaYX ' areas, 'Found: ' foundArea, label)
        }
        return found
    }

    if (monitor != "")  ; If a monitor number is provided, append it to the area
        return currentArea . "." . monitor
    if (showLog or ctrl) {
        label := labelForDebug ? ' Label:' . labelForDebug : ''
        log('getAreaYX ' areas, 'Found: ' currentArea, label)
    }
    return currentArea
}

showArea(area) {
    if (Type(area) == 'String' and (InStr(area, ',') > 1)) {
        area := StrSplit(area, ',')
    } else if (Type(area) != 'Array') {
        MsgBox('Area has to be a string sepparated by comma or an array')
        return
    }
    area := getAreaYX(area[1], area[2])
    msgV1(area, 1)
    notifu(area, , 1, 'sp.ahk', true)

    return
}

inArea(area, areas, inMonitor := 0) {
    if (!area) {
        throw "Area is null"
    }
    monitor := getMonitor()
    if (inMonitor !== 0 && inMonitor != monitor) {
        return false
    }
    currentArea := area ?? getAreaYX()
    for each, area in areas {
        if (currentArea = area) {
            return true
        }
    }
    return false
}

inSec(sec) {
    curSec := getAreaYX()
    sec := sec
    ret := (sec == curSec)
    return ret
}

;===============================================================================
; CLIPBOARD OPERATIONS
;===============================================================================

ctrlC() {
    A_Clipboard := ""
    Send "^c"
    if (!ClipWait(0.5)) {
        MsgBox('Failed to copy item')
        return
    }
    return A_Clipboard
}

copyToClipboard(text) {
    A_Clipboard := ''
    A_clipboard := String(text)
    clipWait 100
    Sleep 80
}

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

;===============================================================================
; NOTIFICATIONS & MESSAGING
;===============================================================================

msgV1(text, sec := 1, id := false, x := false, y := false) {
    msg(text, { seconds: sec, id: id, x: x, y: y })
}

notify(title := 'Main.ahk', text := '', seconds := 5, icon := '', muted := False) {
    ; Info icon	1	0x1	Iconi
    ; Warning icon	2	0x2	Icon!
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
    notifuExe := IniRead("config.ini", "desktop", "notifu_exe", "")
    if (!notifuExe) {
        msgV1("Error: Missing notifu path in config.ini3", 3)
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
; DEBUGGING & LOGGING
;===============================================================================
log(params*) {
    if (!IsSet(logVisibility)) {
        logVisibility := false
    }
    
    ; Check if first parameter is an object with log options
    logOptions := {}
    if (params.Length > 0 && Type(params[1]) == "Object") {
        logOptions := params[1]
        params.RemoveAt(1) ; Remove the options object from params
    }
    
    ; Set default options
    showLog := false
    isError := false
    
    ; Check if logOptions has the properties
    if (logOptions) {
        if (logOptions.HasOwnProp("showLog")) {
            showLog := logOptions.showLog
        }
        if (logOptions.HasOwnProp("isError")) {
            isError := logOptions["isError"]
        }
    }
    
    result := ''

    tryAgain := false
    try {
        ; Add error prefix if this is an error log
        if (isError) {
            result := "[ERROR] "
        }
        
        for idx, param in params {
            separator := (idx < params.Length) ? ' | ' : ''
            if (Type(param) == 'Array') {
                arr := 'Arr-> '
                for a, b in param {
                    arr .= '[' String(a) ']' ':' String(b)
                    if (a < param.Length) {
                        arr .= ' | '
                    }
                }
                result .= arr . separator
            } else {
                result .= String(param) . separator
            }
        }
        ; Use error.txt for error logs, log.txt for normal logs
        logFile := A_ScriptDir . '\' . (isError ? 'error.txt' : 'log.txt')
        if (!logFile) {
            msgV1("Error: Missing log file path", 3)
            return
        }
        try {
            FileAppend(result . '`n', logFile)
        } catch Error as e {
            tryAgain := true
        }
        if (tryAgain) {
            Sleep 100
            try {
                FileAppend(result . '`n', logFile)
            } catch Error as e2 {
                msg("Error appending to log file", e2.Message, e2.File, e2.Line, { Seconds: 3 })
                return
            }
        }
        if (showLog or logVisibility) {
            runLogExe()
            Sleep 100
        }
    } catch Error as e {
        msg("Error appending to log file", e.Message, e.File, e.Line, { Seconds: 3 })
    }
}

runLogExe() {
    if (!WinExist("ahk_exe Tail.exe")) {
        tailExe := IniRead("config.ini", "desktop", "tail_exe", "")
        logFile := A_ScriptDir . '\log.txt'

        if (!tailExe) {
            msgV1("Error: Missing nircmd path in config.ini", 3)
            return
        }

        win := WinGetID('A')
        Run(tailExe . ' ' . logFile)
        WinWaitActive("ahk_exe Tail.exe")
        WinActivateFast("ahk_exe Tail.exe")
        WinSetAlwaysontop(-1, "A")
        WinActivateFast(win)
        WinMoveTop("ahk_exe Tail.exe")
    }
}

emptylog(logFile := '') {
    logFile := logFile ? logFile : A_ScriptDir . '\log.txt'
    
    if (!logFile) {
        msgV1("Error: Missing log file path", 3)
        return
    }
    if (FileExist(logFile)) {
        try {
            FileDelete(logFile)
        } catch Error as e {
            MsgBox('Error deleting log file: ' . e.Message)
            msgV1("Error deleting log file", 3, 19)
        }
    }
    Sleep 100
    FileAppend("Emptied" . '`n', logFile)
}

;===============================================================================
; TIMERS & SCHEDULED TASKS
;===============================================================================

global winSaved := false

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


; This HotIf directive creates a context-sensitive hotkey for the left mouse button.
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
; KEYBOARD UTILITIES
;===============================================================================

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



;===============================================================================
; CONFIG MANAGEMENT
;===============================================================================

/**
 * Read a value from config.ini with path expansion
 * @param {string} section - The section name in config.ini
 * @param {string} key - The key to read
 * @param {string} defaultValue - Default value if key not found
 * @returns {string} The expanded value from config.ini
 */
IniReadWithExpansion(section, key, defaultValue := "") {
    value := IniRead("config.ini", section, key, defaultValue)

    ; Replace %variable% with actual values
    if (InStr(value, "%")) {
        ; Replace user paths
        value := StrReplace(value, "%user_home%", IniRead("config.ini", "paths", "user_home"))
        value := StrReplace(value, "%user_documents%", IniRead("config.ini", "paths", "user_documents"))
        value := StrReplace(value, "%user_appdata%", IniRead("config.ini", "paths", "user_appdata"))
        value := StrReplace(value, "%user_localappdata%", IniRead("config.ini", "paths", "user_localappdata"))

        ; Replace program files paths
        value := StrReplace(value, "%program_files%", IniRead("config.ini", "paths", "program_files"))
        value := StrReplace(value, "%program_files_x86%", IniRead("config.ini", "paths", "program_files_x86"))

        ; Replace dev paths
        value := StrReplace(value, "%dev_dir%", IniRead("config.ini", "paths", "dev_dir"))
        value := StrReplace(value, "%scripts_dir%", IniRead("config.ini", "paths", "scripts_dir"))
    }

    return value
}

;===============================================================================
; WINDOW DETECTION & INTERACTION
;===============================================================================

GetWindowUnderMouse() {
    WinGetPos(, , &w, &h, 'A')
    MouseGetPos(&x, &y, &winId, &control, 2)
    return {
        id: winId,
        control: control,
        width: w,
        height: h,
    }
}

; =====================
; SEQUENCE & GUI MANAGEMENT (migrated from functions.ahk)
; =====================
global seqGuiActive := false

; Seq - Waits for user input with configurable timeout and feedback
; Parameters:
;   time - Time to wait for input in milliseconds (default: 500)
;   chars - Maximum number of characters to accept (default: 2)
;   key - Not used (default: False)
;   feedback - Show pressed key feedback if 1 (default: 0)
;   beepOnNoKeyPressed - Play error sound if no key pressed (default: true)
;   text - Custom message to display while waiting (default: false)
; Returns: The key(s) pressed by user or empty if timeout

Seq(time := 500, chars := 2, key := False, feedback := 0, beepOnNoKeyPressed := true, text := false) {
    msgId := 13
    if (text) {
        msg(text . ' | ' . time / 1000 . ' seconds', { seconds: time / 1000, id: msgId })
    } else {
        msg("Seq: waiting for a key " . time / 1000 . ' seconds', { seconds: time / 1000, id: msgId })
    }
    secs := (time / 1000)
    ihcommand := InputHook("L" chars "  M T" secs)
    ihcommand.Start()
    ihcommand.Wait()
    command := ihcommand.Input
    if (feedback == 1) {
        msg("key: " command)
    }
    if (!command and beepOnNoKeyPressed) {
        msg("no key pressed")
    }
    ToolTip(, , , msgId)
    if (command == '␛') {
        msg("backspace pressed")
        command := ''
    }
    return command
}

;===============================================================================
; CONFIG CACHING & AUTO-REFRESH (PORTABILITY)
;===============================================================================
global Config := Map()
global ConfigLastModified := ""

loadConfig() {
    global Config, ConfigLastModified
    Config := Map()  ; Clear previous cache

    ; Cache device-specific paths
    deviceKeys := [
        "whatsapp_path", "cursor_path", "vscode_path", "vivaldi_path", "vivaldi_local_path", "chrome_path", "zen_path", "xyplorer_path", "strokesplus_exe", "strokesplus_dir"
    ]
    Config[deviceSection] := Map()
    log('config', deviceSection, deviceKeys)
    for key in deviceKeys {
        Config[deviceSection][key] := IniRead("config.ini", deviceSection, key, "")
        log('config', key, Config[deviceSection][key])
    }

    ; Cache desktop tools
    desktopKeys := [
        "nircmd_exe", "notifu_exe", "tail_exe", "kenv_scripts_dir", "kit_dir", "fsTouch_exe"
    ]
    Config["desktop"] := Map()
    for key in desktopKeys {
        Config["desktop"][key] := IniRead("config.ini", "desktop", key, "")
    }

    ; Cache Programs section
    programKeys := ["ChromePath"]
    Config["Programs"] := Map()
    for key in programKeys {
        Config["Programs"][key] := IniRead("config.ini", "Programs", key, "")
    }

    ; Cache paths section
    pathKeys := ["user_home", "user_documents", "user_appdata", "user_localappdata", "program_files", "program_files_x86", "dev_dir", "scripts_dir"]
    Config["paths"] := Map()
    for key in pathKeys {
        Config["paths"][key] := IniRead("config.ini", "paths", key, "")
    }

    ; Cache general section
    Config["general"] := Map()
    Config["general"]["lastDate"] := IniRead("config.ini", "general", "lastDate", "")

    ConfigLastModified := FileGetTime("config.ini", "M")
}

refreshConfigIfChanged() {
    global ConfigLastModified
    newTime := FileGetTime("config.ini", "M")
    if (newTime != ConfigLastModified) {
        loadConfig()
        msg("Config reloaded!", { seconds: 2 })
    }
}

;===============================================================================
; CONFIG VARIABLES & SERIAL NUMBERS
;===============================================================================

getNextSerialNumber() {
    serial := IniRead("config.ini", "variables", "serialNumber", "")
    if (serial == "" || !IsNumber(serial)) {
        serial := 1
    } else {
        serial := Number(serial) + 1
    }
    IniWrite(serial, "config.ini", "variables", "serialNumber")
    return serial
}

;===============================================================================
; CONFIG PATH VALIDATION
;===============================================================================

CheckConfigPaths(deviceSection := "") {
    if (!FileExist("config.ini")) {
        msg("config.ini not found!", 3)
        return
    }

    ; If no device section specified, try to detect from general section
    if (deviceSection = "") {
        deviceSection := IniRead("config.ini", "general", "deviceSection", "desktop")
    }

    missing := []
    ; Only check paths section and current device section
    sections := ["paths", deviceSection]
    
    ; Check each section
    for _, section in sections {
        sectionContent := IniRead("config.ini", section, "", "")
        if (sectionContent = "")
            continue
            
        ; Parse section content
        loop parse sectionContent, "`n", "`r" {
            if (A_LoopField = "")
                continue
            if (!InStr(A_LoopField, "="))
                continue
                
            parts := StrSplit(A_LoopField, "=", , 2)
            if (parts.Length < 2)
                continue
                
            key := Trim(parts[1])
            value := Trim(parts[2])
            
            ; Remove quotes from value
            value := StrReplace(value, '"', '')
            value := StrReplace(value, "'", '')
            
            ; Skip empty values or comments
            if (value = "" || SubStr(key, 1, 1) = ";")
                continue
            
            ; Check if this is a path-related key
            isPathKey := (InStr(key, "_path") || InStr(key, "_exe") || InStr(key, "_dir") 
                         || section = "paths")
            
            if (!isPathKey)
                continue
            
            ; Expand variables in path using IniReadWithExpansion logic
            expandedPath := value
            if (InStr(expandedPath, "%")) {
                expandedPath := StrReplace(expandedPath, "%user_home%", IniRead("config.ini", "paths", "user_home", ""))
                expandedPath := StrReplace(expandedPath, "%user_documents%", IniRead("config.ini", "paths", "user_documents", ""))
                expandedPath := StrReplace(expandedPath, "%user_appdata%", IniRead("config.ini", "paths", "user_appdata", ""))
                expandedPath := StrReplace(expandedPath, "%program_files%", IniRead("config.ini", "paths", "program_files", ""))
                expandedPath := StrReplace(expandedPath, "%dev_dir%", IniRead("config.ini", "paths", "dev_dir", ""))
                expandedPath := StrReplace(expandedPath, "%scripts_dir%", IniRead("config.ini", "paths", "scripts_dir", ""))
            }
            
            ; Check if path exists (file or directory)
            if (!FileExist(expandedPath) && !DirExist(expandedPath)) {
                missing.Push("[" . section . "] " . key . " = " . expandedPath)
            }
        }
    }
    
    ; Show results
    logFile := A_ScriptDir . '\missing-paths.log'
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    
    if (missing.Length > 0) {
        msgText := "Missing paths in config.ini:`n`n"
        for _, item in missing {
            msgText .= "✗ " . item . "`n"
        }
        msgText .= "`nTotal: " . missing.Length . " missing path(s)"
        
        ToolTip(msgText, 100, 100)
        SetTimer(() => ToolTip(), -10000)  ; Hide after 10 seconds
        
        ; Log to file
        try {
            FileAppend(timestamp . "`n" . msgText . "`n`n", logFile, "UTF-8")
        }
    } else {
        ; All paths OK - silent success but log it
        try {
            FileAppend(timestamp . "`nAll paths OK - checked sections: paths, " . deviceSection . "`n`n", logFile, "UTF-8")
        }
    }
}
