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
