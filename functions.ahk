;*************************************
/*
 * FUNCTIONS.AHK
 * Core utility functions and configuration management
 * Note: Audio, Window, Screen, Clipboard, Logging, and Utility functions
 * have been moved to lib/ modules for better organization
 * Repository: gitlab.com/jpsala/scripts
*/
#Warn All, Off
global appInstanceMap := Map()  ; For tracking application instances
global aliasMap := Map()        ; For alias-based window management
global configCache := Map()     ; Cache for frequently accessed config values
global NOTIFICATION_GUI := false
global NOTIFICATION_READY := false
global NOTIFICATION_PAYLOAD := false
global NOTIFICATION_CALLBACK := false

;===============================================================================
; CONFIG CACHE HELPERS
;===============================================================================

/**
 * Get a config value with caching to reduce disk I/O
 * @param {string} section - The INI section name
 * @param {string} key - The config key
 * @param {string} default - Default value if not found
 * @returns {string} The config value
 */
GetCachedConfig(section, key, default := "") {
    global configCache
    cacheKey := section . "." . key
    
    if (configCache.Has(cacheKey)) {
        return configCache[cacheKey]
    }
    
    value := IniRead("config.ini", section, key, default)
    configCache[cacheKey] := value
    return value
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
    desktopKeys := ["nircmd_exe", "notifu_exe"]
    Config["desktop"] := Map()
    for key in desktopKeys {
        Config["desktop"][key] := IniRead("config.ini", "desktop", key, "")
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
    } else{
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

;===============================================================================
; SEQUENCE & GUI MANAGEMENT
;===============================================================================
global seqGuiActive := false

/**
 * Seq - Waits for user input with configurable timeout and feedback
 * @param {number} time - Time to wait for input in milliseconds (default: 500)
 * @param {number} chars - Maximum number of characters to accept (default: 2)
 * @param {*} key - Not used (default: False)
 * @param {number} feedback - Show pressed key feedback if 1 (default: 0)
 * @param {boolean} beepOnNoKeyPressed - Play error sound if no key pressed (default: true)
 * @param {string|boolean} text - Custom message to display while waiting (default: false)
 * @returns {string} The key(s) pressed by user or empty if timeout
 */
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
; NOTIFICATIONS
;===============================================================================

ShowNotification(payload, callback := false, persistent := false) {
    if (!persistent) {
        NotificationFallback(payload)
        return true
    }

    return ShowPersistentNotification(payload, callback)
}

ShowPersistentNotification(payload, callback := false) {
    global NOTIFICATION_GUI, NOTIFICATION_READY, NOTIFICATION_PAYLOAD, NOTIFICATION_CALLBACK
    NOTIFICATION_PAYLOAD := payload
    NOTIFICATION_CALLBACK := callback

    if (NOTIFICATION_GUI) {
        try {
            NOTIFICATION_GUI.Show()
            WinActivate(NOTIFICATION_GUI.Hwnd)
            NotificationSendState()
            return true
        } catch {
            NOTIFICATION_GUI := false
        }
    }

    NOTIFICATION_READY := false
    try {
        dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
        NOTIFICATION_GUI := WebViewGui("+Resize -Caption +AlwaysOnTop", NotificationMapGet(payload, "windowTitle", "Notification"),, {DllPath: dllPath, DefaultWidth: 560, DefaultHeight: 360})
        NOTIFICATION_GUI.BackColor := NotificationMapGet(payload, "backColor", "111827")
        NOTIFICATION_GUI.OnEvent("Close", (*) => CloseNotification())
        NOTIFICATION_GUI.OnEvent("Escape", (*) => CloseNotification())
        NOTIFICATION_GUI.Control.wv.add_WebMessageReceived(NotificationHandleMessage)
        NOTIFICATION_GUI.Control.wv.add_NavigationCompleted(NotificationNavigationCompleted)
        NOTIFICATION_GUI.Navigate("ui/notification.html")
        NOTIFICATION_GUI.Show("w560 h360 Hide")
        WebViewWindowStateRestoreOrCenter(NOTIFICATION_GUI, "notification", 560, 360, true, true)
        NOTIFICATION_GUI.Show()
        WinActivate(NOTIFICATION_GUI.Hwnd)
        try SoundBeep(900, 250)
        try SoundBeep(700, 250)
        return true
    } catch Error as e {
        NotificationFallback(payload)
        return false
    }
}

NotificationNavigationCompleted(wv, args) {
    global NOTIFICATION_READY
    NOTIFICATION_READY := true
    NotificationSendState()
}

NotificationHandleMessage(wv, args) {
    global NOTIFICATION_CALLBACK
    try {
        json := args.WebMessageAsJson
        data := JsonLoad(&json)
        action := data.Has("action") ? data["action"] : ""

        switch action {
            case "ready":
                NotificationSendState()
            case "minimize":
                global NOTIFICATION_GUI
                if (NOTIFICATION_GUI)
                    NOTIFICATION_GUI.Minimize()
            case "close", "dismiss":
                CloseNotification()
            case "button":
                buttonAction := data.Has("buttonAction") ? data["buttonAction"] : ""
                closeAfter := data.Has("close") ? data["close"] : true
                if (NOTIFICATION_CALLBACK)
                    NOTIFICATION_CALLBACK.Call(buttonAction, data)
                if (closeAfter)
                    CloseNotification()
        }
    } catch Error as e {
        log("Notification error", e.Message)
    }
}

NotificationSendState() {
    global NOTIFICATION_GUI, NOTIFICATION_READY, NOTIFICATION_PAYLOAD
    if (!NOTIFICATION_GUI || !NOTIFICATION_READY || !NOTIFICATION_PAYLOAD)
        return false

    payload := Map("action", "notification", "notification", NOTIFICATION_PAYLOAD)
    try NOTIFICATION_GUI.Control.wv.PostWebMessageAsJson(JsonDump(payload))
    return true
}

CloseNotification() {
    global NOTIFICATION_GUI, NOTIFICATION_READY, NOTIFICATION_PAYLOAD, NOTIFICATION_CALLBACK
    if (NOTIFICATION_GUI) {
        try WebViewWindowStateSave(NOTIFICATION_GUI.Hwnd)
        try WebViewWindowStateForget(NOTIFICATION_GUI.Hwnd)
        try NOTIFICATION_GUI.Destroy()
    }
    NOTIFICATION_GUI := false
    NOTIFICATION_READY := false
    NOTIFICATION_PAYLOAD := false
    NOTIFICATION_CALLBACK := false
}

NotificationFallback(payload) {
    title := NotificationMapGet(payload, "title", "Notification")
    message := NotificationMapGet(payload, "message", "")
    detail := NotificationMapGet(payload, "detail", "")
    body := message . (detail != "" ? "`n" . detail : "")
    try TrayTip(body, title)
    try msg(body, { seconds: 20, topLeft: true })
}

NotificationMapGet(valueMap, key, defaultValue := "") {
    return (valueMap is Map && valueMap.Has(key)) ? valueMap[key] : defaultValue
}
