;===============================================================================
; SETTINGS WINDOW MODULE
; WebView-based configuration interface
;===============================================================================

#Include ".\lib\WebViewToo.ahk"

global SETTINGS_GUI := false
global SETTINGS_READY := false
global SETTINGS_PATHS_DATA := []
global SETTINGS_DEBUG_FILE := A_ScriptDir . "\settings-debug.txt"

; Debug logging function (always writes, independent of logVisibility)
SettingsDebugLog(msg) {
    global SETTINGS_DEBUG_FILE
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend(timestamp . " - " . msg . "`n", SETTINGS_DEBUG_FILE)
}

;-------------------------------------------------------------------------------
; PUBLIC API
;-------------------------------------------------------------------------------

/**
 * Opens the settings window
 * @param {String} initialTab - Optional: tab to open ("paths", "general", "about")
 */
ShowSettingsWindow(initialTab := "paths") {
    global SETTINGS_GUI, SETTINGS_READY
    
    ; If window already exists, just show and focus it
    if (SETTINGS_GUI) {
        try {
            SETTINGS_GUI.Show()
            WinActivate(SETTINGS_GUI.hwnd)
            return
        } catch {
            SETTINGS_GUI := false
        }
    }
    
    ; Create new settings window
    CreateSettingsWindow(initialTab)
}

/**
 * Shows missing paths summary in WebView instead of MsgBox
 * @param {Integer} criticalCount - Number of critical missing paths
 * @param {Integer} optionalCount - Number of optional missing paths
 */
ShowMissingPathsWebView(criticalCount, optionalCount) {
    global SETTINGS_GUI
    
    ; Only show if not hidden by user setting
    hidePathsSummary := IniRead("config.ini", "general", "hidePathsSummary", "0")
    if (hidePathsSummary = "1") {
        return
    }
    
    ; Show settings window directly
    ShowSettingsWindow("paths")
    
    ; Could add a visual indicator or alert in the WebView here
}

;-------------------------------------------------------------------------------
; WINDOW CREATION
;-------------------------------------------------------------------------------

CreateSettingsWindow(initialTab := "paths") {
    global SETTINGS_GUI, SETTINGS_READY
    
    SettingsDebugLog("CreateSettingsWindow called, initialTab: " . initialTab)
    SETTINGS_READY := false
    
    ; Create WebView GUI
    try {
        dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
        
        SETTINGS_GUI := WebViewGui("+Resize", "Configuración - Main Automation",, {DllPath: dllPath})
        SETTINGS_GUI.BackColor := "1E1E1E"
        
        ; Set up window events
        SETTINGS_GUI.OnEvent("Close", (*) => CloseSettingsWindow())
        SETTINGS_GUI.OnEvent("Escape", (*) => CloseSettingsWindow())
        
        ; Set up message handler
        SETTINGS_GUI.Control.wv.add_WebMessageReceived(HandleSettingsMessage)
        SETTINGS_GUI.Control.wv.add_NavigationCompleted(SettingsNavigationCompleted)
        
        ; Browse folder if compiled
        if (A_IsCompiled)
            SETTINGS_GUI.Control.BrowseFolder(A_ScriptDir)
        
        ; Navigate to settings.html
        SETTINGS_GUI.Navigate("ui/settings.html")
        
        ; Set size and position
        SETTINGS_GUI.Show("w900 h700 Hide")
        
        ; Center on screen
        MonitorGetWorkArea(, &Left, &Top, &Right, &Bottom)
        screenWidth := Right - Left
        screenHeight := Bottom - Top
        winWidth := 900
        winHeight := 700
        x := Left + (screenWidth - winWidth) // 2
        y := Top + (screenHeight - winHeight) // 2
        SETTINGS_GUI.Move(x, y, winWidth, winHeight)
        
        ; Show window
        SETTINGS_GUI.Show()
        
    } catch as err {
        MsgBox("Error creando ventana de configuración: " . err.Message, "Error", "Icon!")
        SETTINGS_GUI := false
    }
}

SettingsNavigationCompleted(wv, args) {
    SettingsDebugLog("WebView navigation completed (HTML loaded)")
}

;-------------------------------------------------------------------------------
; MESSAGE HANDLING
;-------------------------------------------------------------------------------

HandleSettingsMessage(wv, args) {
    global SETTINGS_GUI, SETTINGS_READY
    
    try {
        json := args.WebMessageAsJson
        SettingsDebugLog("Received message from WebView: " . json)
        data := Jxon_Load(&json)
        
        action := data.Has("action") ? data["action"] : ""
        SettingsDebugLog("Message action: " . action)
        
        switch action {
            case "ready":
                ; WebView is ready, send initial data
                SettingsDebugLog("WebView sent ready signal")
                SETTINGS_READY := true
                SendInitialData()
                
            case "updatePath":
                ; User updated a path
                HandlePathUpdate(data)
                
            case "browsePath":
                ; User clicked browse button
                HandleBrowsePath(data)
                
            case "detectPath":
                ; User clicked detect button
                HandleDetectPath(data)
                
            case "autoDetectAll":
                ; User clicked auto-detect all
                HandleAutoDetectAll()
                
            case "updateSetting":
                ; User toggled a setting
                HandleSettingUpdate(data)
                
            case "openConfigFile":
                ; Open config.ini in editor
                Run('"' . A_ScriptDir . '\config.ini"')
                
            case "reloadConfig":
                ; Reload configuration
                loadConfig()
                SendInitialData()  ; Refresh UI with new data
                SendMessage("Config recargado exitosamente", "success")
                
            case "openDoc":
                ; Open documentation file
                if (data.Has("filename")) {
                    docPath := A_ScriptDir . "\\" . data["filename"]
                    if (FileExist(docPath)) {
                        Run('"' . docPath . '"')
                    }
                }
                
            case "close":
                CloseSettingsWindow()
        }
    } catch as err {
        SettingsDebugLog("Settings window error: " . err.Message)
    }
}

;-------------------------------------------------------------------------------
; DATA MANAGEMENT
;-------------------------------------------------------------------------------

CreatePathItem(key, name, description, type, section) {
    return Map(
        "key", key,
        "name", name,
        "description", description,
        "type", type,
        "path", IniRead("config.ini", section, key, ""),
        "found", CheckPathExists(key, section)
    )
}

SendInitialData() {
    global SETTINGS_GUI, SETTINGS_READY, deviceSection
    
    SettingsDebugLog("SendInitialData called - SETTINGS_GUI: " . (SETTINGS_GUI ? "exists" : "null") . ", SETTINGS_READY: " . SETTINGS_READY . ", deviceSection: " . deviceSection)
    
    if (!SETTINGS_GUI || !SETTINGS_READY) {
        SettingsDebugLog("SendInitialData aborted - GUI or READY check failed")
        return
    }
    
    ; Gather paths data
    paths := []
    
    ; Applications
    paths.Push(CreatePathItem("cursor_path", "Cursor", "Editor de código con IA", "app", deviceSection))
    paths.Push(CreatePathItem("vscode_path", "VS Code", "Visual Studio Code", "app", deviceSection))
    paths.Push(CreatePathItem("chrome_path", "Chrome", "Google Chrome browser", "app", deviceSection))
    paths.Push(CreatePathItem("vivaldi_path", "Vivaldi", "Vivaldi browser", "app", deviceSection))
    paths.Push(CreatePathItem("zen_path", "Zen Browser", "Zen browser", "app", deviceSection))
    paths.Push(CreatePathItem("xyplorer_path", "XYplorer", "File manager avanzado", "app", deviceSection))
    
    ; Tools
    paths.Push(CreatePathItem("nircmd_exe", "NirCmd", "Utilidad de línea de comandos para Windows", "tool", "desktop"))
    paths.Push(CreatePathItem("notifu_exe", "Notifu", "Sistema de notificaciones", "tool", "desktop"))
    
    ; General settings
    ; Read raw values first
    hidePathsSummary := IniRead("config.ini", "general", "hidePathsSummary", "0")
    logVisibility := IniRead("config.ini", "variables", "logVisibility", "0")
    cursorKeys := IniRead("config.ini", "variables", "cursorKeysEnabled", "1")
    
    ; Convert to explicit true/false strings for JSON
    general := Map(
        "showPathsSummary", (hidePathsSummary = "0" ? "true" : "false"),
        "loggingEnabled", (logVisibility = "1" ? "true" : "false"),
        "cursorKeysEnabled", (cursorKeys = "1" ? "true" : "false")
    )
    
    ; Debug logging
    SettingsDebugLog("Settings values - hidePathsSummary: '" . hidePathsSummary . "', logVisibility: '" . logVisibility . "', cursorKeys: '" . cursorKeys . "'")
    SettingsDebugLog("Settings bool - showPathsSummary: " . general["showPathsSummary"] . ", loggingEnabled: " . general["loggingEnabled"] . ", cursorKeysEnabled: " . general["cursorKeysEnabled"])
    
    ; Info
    info := Map(
        "version", "1.0.0",
        "scriptDir", A_ScriptDir,
        "configPath", A_ScriptDir . "\config.ini"
    )
    
    ; Send data to WebView
    settings := Map(
        "paths", paths,
        "general", general,
        "info", info
    )
    
    data := Map(
        "action", "init",
        "settings", settings
    )
    
    SendToWebView(data)
}

CheckPathExists(key, section) {
    path := IniRead("config.ini", section, key, "")
    if (!path || path = "") {
        return false
    }
    return FileExist(path) ? true : false
}

;-------------------------------------------------------------------------------
; PATH OPERATIONS
;-------------------------------------------------------------------------------

HandlePathUpdate(data) {
    global deviceSection
    
    if (!data.Has("key") || !data.Has("path")) {
        return
    }
    
    key := data["key"]
    path := data["path"]
    
    ; Determine section (desktop for tools, deviceSection for apps)
    section := InStr(key, "_exe") ? "desktop" : deviceSection
    
    ; Save to config
    if (path = "") {
        IniDelete("config.ini", section, key)
    } else {
        IniWrite(path, "config.ini", section, key)
    }
    
    ; Reload config cache
    loadConfig()
    
    ; Notify WebView
    found := path = "" ? false : FileExist(path) ? true : false
    SendToWebView(Map(
        "action", "pathUpdated",
        "key", key,
        "path", path,
        "found", found
    ))
}

HandleBrowsePath(data) {
    if (!data.Has("key") || !data.Has("name")) {
        SettingsDebugLog("HandleBrowsePath: missing key or name")
        return
    }
    
    key := data["key"]
    name := data["name"]
    
    SettingsDebugLog("HandleBrowsePath: key=" . key . ", name=" . name)
    
    ; Show file picker
    isFolder := InStr(key, "_dir")
    
    if (isFolder) {
        selectedPath := DirSelect("*", 2, "Seleccioná la carpeta de " . name)
    } else {
        selectedPath := FileSelect(1, "", "Seleccioná el ejecutable de " . name, "Ejecutables (*.exe)")
    }
    
    if (selectedPath) {
        ; Update path
        HandlePathUpdate(Map("key", key, "path", selectedPath))
    }
}

HandleDetectPath(data) {
    if (!data.Has("key") || !data.Has("name")) {
        SettingsDebugLog("HandleDetectPath: missing key or name")
        return
    }
    
    key := data["key"]
    name := data["name"]
    
    SettingsDebugLog("HandleDetectPath: key=" . key . ", name=" . name)
    
    ; Map key to app name for GetCommonPaths
    appMap := Map(
        "cursor_path", "cursor",
        "vscode_path", "vscode",
        "chrome_path", "chrome",
        "vivaldi_path", "vivaldi",
        "xyplorer_path", "xyplorer",
        "nircmd_exe", "nircmd"
    )
    
    appName := appMap.Has(key) ? appMap[key] : ""
    
    if (appName) {
        searchPaths := GetCommonPaths(appName)
        detectedPath := AutoDetectPath(searchPaths)
        
        if (detectedPath) {
            HandlePathUpdate(Map("key", key, "path", detectedPath))
            SendMessage(name . " detectado: " . detectedPath, "success")
        } else {
            SendMessage(name . " no pudo ser detectado automáticamente", "warning")
        }
    }
}

HandleAutoDetectAll() {
    ; Auto-detect all applications
    apps := ["cursor", "vscode", "chrome", "vivaldi", "xyplorer", "nircmd"]
    detected := 0
    
    for appName in apps {
        searchPaths := GetCommonPaths(appName)
        detectedPath := AutoDetectPath(searchPaths)
        
        if (detectedPath) {
            ; Determine the key name
            key := appName = "nircmd" ? "nircmd_exe" : appName . "_path"
            HandlePathUpdate(Map("key", key, "path", detectedPath))
            detected++
        }
    }
    
    if (detected > 0) {
        SendMessage("✓ " . detected . " aplicaciones detectadas", "success")
        SendInitialData()  ; Refresh all data
    } else {
        SendMessage("No se detectaron aplicaciones nuevas", "info")
    }
}

;-------------------------------------------------------------------------------
; SETTINGS OPERATIONS
;-------------------------------------------------------------------------------

HandleSettingUpdate(data) {
    if (!data.Has("key") || !data.Has("value")) {
        SettingsDebugLog("HandleSettingUpdate: missing key or value")
        return
    }
    
    key := data["key"]
    value := data["value"]
    
    SettingsDebugLog("HandleSettingUpdate: key=" . key . ", value=" . value . " (type: " . Type(value) . ")")
    
    switch key {
        case "showPathsSummary":
            ; Invert logic: showPathsSummary true = hidePathsSummary false
            iniValue := value ? "0" : "1"
            IniWrite(iniValue, "config.ini", "general", "hidePathsSummary")
            SettingsDebugLog("Wrote hidePathsSummary=" . iniValue)
            
        case "loggingEnabled":
            iniValue := value ? "1" : "0"
            IniWrite(iniValue, "config.ini", "variables", "logVisibility")
            SettingsDebugLog("Wrote logVisibility=" . iniValue)
            
        case "cursorKeysEnabled":
            iniValue := value ? "1" : "0"
            IniWrite(iniValue, "config.ini", "variables", "cursorKeysEnabled")
            SettingsDebugLog("Wrote cursorKeysEnabled=" . iniValue)
    }
    
    ; Reload config
    loadConfig()
    
    ; Confirm to WebView
    SendToWebView(Map(
        "action", "settingUpdated",
        "key", key,
        "value", value
    ))
}

;-------------------------------------------------------------------------------
; WEBVIEW COMMUNICATION
;-------------------------------------------------------------------------------

SendToWebView(data) {
    global SETTINGS_GUI, SETTINGS_READY
    
    if (!SETTINGS_GUI || !SETTINGS_READY) {
        return
    }
    
    try {
        json := Jxon_Dump(data)
        SettingsDebugLog("Sending to WebView: " . json)
        SETTINGS_GUI.Control.wv.PostWebMessageAsJson(json)
    } catch as err {
        SettingsDebugLog("Error sending to WebView: " . err.Message)
    }
}

SendMessage(message, type := "info") {
    ; Could implement a toast/notification system in the WebView
    ; For now, just log it
    SettingsDebugLog("Settings: " . message)
}

;-------------------------------------------------------------------------------
; WINDOW MANAGEMENT
;-------------------------------------------------------------------------------

CloseSettingsWindow(*) {
    global SETTINGS_GUI, SETTINGS_READY
    
    if (SETTINGS_GUI) {
        try {
            SETTINGS_GUI.Destroy()
        } catch {
            ; Ignore errors
        }
        SETTINGS_GUI := false
        SETTINGS_READY := false
    }
}

;===============================================================================
; JXON - JSON parser/serializer
; Source: https://github.com/TheArkive/JXON_ahk2
;===============================================================================

Jxon_Load(&src, args*) {
    key := "", is_key := false
    stack := [ tree := [] ]
    next := '"{[01234567890-tfn'
    pos := 0
    
    while ( (ch := SubStr(src, ++pos, 1)) != "" ) {
        if InStr(" `t`n`r", ch)
            continue
        if !InStr(next, ch, true) {
            testArr := StrSplit(SubStr(src, 1, pos), "`n")
            
            ln := testArr.Length
            col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

            msg := Format("{}: line {} col {} (char {})"
                ,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
                  : (next == "'")     ? "Unterminated string starting at"
                  : (next == "\")     ? "Invalid \escape"
                  : (next == ":")     ? "Expecting ':' delimiter"
                  : (next == '"')     ? "Expecting object key enclosed in double quotes"
                  : (next == '"}')    ? "Expecting object key enclosed in double quotes or object closing '}'"
                  : (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
                  : (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
                  : ["Expecting JSON value(string, number, [true, false, null], object or array)"
                     , ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1)][1]
                , ln, col, pos)

            throw Error(msg, -1, ch)
        }
        
        obj := stack[1]
        is_array := (obj is Array)
        
        if i := InStr("{[", ch) { ; start new object / map?
            val := (i = 1) ? Map() : Array()	; Map() or Array()
            
            is_array ? obj.Push(val) : obj[key] := val
            stack.InsertAt(1,val)
            
            next := '"' ((is_key := (ch == "{")) ? "}" : "{[]0123456789-tfn")
        } else if InStr("}]", ch) {
            stack.RemoveAt(1)
            next := (stack[1]==tree) ? "" : (stack[1] is Array) ? ",]" : ",}"
        } else if InStr(",:", ch) {
            is_key := (!is_array && ch == ",")
            next := is_key ? '"' : '"{[0123456789-tfn'
        } else { ; string | number | true | false | null
            if (ch == '"') { ; string
                i := pos
                while (i := InStr(src, '"',, i+1)) {
                    val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
                    if (SubStr(val, -1) != "\")
                        break
                }
                if !i ? (pos--, next := "'") : 0
                    continue

                pos := i ; update pos

                val := StrReplace(val, "\/", "/")
                val := StrReplace(val, '\"', '"')
                val := StrReplace(val, "\b", "`b")
                val := StrReplace(val, "\f", "`f")
                val := StrReplace(val, "\n", "`n")
                val := StrReplace(val, "\r", "`r")
                val := StrReplace(val, "\t", "`t")

                i := 0
                while (i := InStr(val, "\",, i+1)) {
                    if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
                        continue 2

                    xxxx := Abs("0x" . SubStr(val, i+2, 4)) ; \uXXXX - JSON unicode escape sequence
                    if (xxxx < 0x100)
                        val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
                }
                
                if is_key {
                    key := val, next := ":"
                    continue
                }
            
            } else { ; number | true | false | null
                val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
            
                if IsInteger(val)
                    val += 0
                else if IsFloat(val)
                    val += 0
                else if (val == "true" || val == "false")
                    val := (val == "true")
                else if (val == "null")
                    val := ""
                else if is_key {
                    pos--, next := "#"
                    continue
                }
                
                pos += i-1
            }
            
            is_array ? obj.Push(val) : obj[key] := val
            next := obj == tree ? "" : is_array ? ",]" : ",}"
        }
    }
    
    return tree[1]
}

Jxon_Dump(obj, indent := "", lvl := 1) {
    if IsObject(obj) {
        if (obj is Array) {
            if (obj.Length == 0)
                return "[]"
            
            out := "["
            for i, v in obj {
                out .= "`n" . indent . Jxon_Dump(v, indent . "  ", lvl+1) . ","
            }
            out := RTrim(out, ",") . "`n" . SubStr(indent, 3) . "]"
            return out
            
        } else if (obj is Map) {
            if (obj.Count == 0)
                return "{}"
            
            out := "{"
            for k, v in obj {
                out .= "`n" . indent . '"' . k . '": ' . Jxon_Dump(v, indent . "  ", lvl+1) . ","
            }
            out := RTrim(out, ",") . "`n" . SubStr(indent, 3) . "}"
            return out
        }
    }
    
    ; Primitive value
    if IsNumber(obj)
        return obj
    if (obj == "true" || obj == "false")
        return obj
    if (obj == "")
        return "null"
    
    ; String - escape special characters
    obj := StrReplace(obj, "\", "\\")
    obj := StrReplace(obj, '"', '\"')
    obj := StrReplace(obj, "`b", "\b")
    obj := StrReplace(obj, "`f", "\f")
    obj := StrReplace(obj, "`n", "\n")
    obj := StrReplace(obj, "`r", "\r")
    obj := StrReplace(obj, "`t", "\t")
    
    return '"' . obj . '"'
}
