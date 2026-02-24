;===============================================================================
; SETTINGS WINDOW MODULE
; WebView-based configuration interface
;===============================================================================

#Include ".\lib\WebViewToo.ahk"

global SETTINGS_GUI := false
global SETTINGS_READY := false
global SETTINGS_PATHS_DATA := []

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
    global SETTINGS_READY := true
}

;-------------------------------------------------------------------------------
; MESSAGE HANDLING
;-------------------------------------------------------------------------------

HandleSettingsMessage(wv, args) {
    global SETTINGS_GUI, SETTINGS_READY
    
    try {
        json := args.WebMessageAsJson
        data := Jxon_Load(&json)
        
        action := data.HasProp("action") ? data.action : ""
        
        switch action {
            case "ready":
                ; WebView is ready, send initial data
                SendInitialData()
                SETTINGS_READY := true
                
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
                SendMessage("Config recargado exitosamente", "success")
                
            case "openDoc":
                ; Open documentation file
                if (data.HasProp("filename")) {
                    docPath := A_ScriptDir . "\" . data.filename
                    if (FileExist(docPath)) {
                        Run('"' . docPath . '"')
                    }
                }
                
            case "close":
                CloseSettingsWindow()
        }
    } catch as err {
        log("Settings window error: " . err.Message)
    }
}

;-------------------------------------------------------------------------------
; DATA MANAGEMENT
;-------------------------------------------------------------------------------

SendInitialData() {
    global SETTINGS_GUI, SETTINGS_READY, deviceSection
    
    if (!SETTINGS_GUI || !SETTINGS_READY) {
        return
    }
    
    ; Gather paths data
    paths := []
    
    ; Applications
    paths.Push({
        key: "cursor_path",
        name: "Cursor",
        description: "Editor de código con IA",
        type: "app",
        path: IniRead("config.ini", deviceSection, "cursor_path", ""),
        found: CheckPathExists("cursor_path", deviceSection)
    })
    
    paths.Push({
        key: "vscode_path",
        name: "VS Code",
        description: "Visual Studio Code",
        type: "app",
        path: IniRead("config.ini", deviceSection, "vscode_path", ""),
        found: CheckPathExists("vscode_path", deviceSection)
    })
    
    paths.Push({
        key: "chrome_path",
        name: "Chrome",
        description: "Google Chrome browser",
        type: "app",
        path: IniRead("config.ini", deviceSection, "chrome_path", ""),
        found: CheckPathExists("chrome_path", deviceSection)
    })
    
    paths.Push({
        key: "vivaldi_path",
        name: "Vivaldi",
        description: "Vivaldi browser",
        type: "app",
        path: IniRead("config.ini", deviceSection, "vivaldi_path", ""),
        found: CheckPathExists("vivaldi_path", deviceSection)
    })
    
    paths.Push({
        key: "zen_path",
        name: "Zen Browser",
        description: "Zen browser",
        type: "app",
        path: IniRead("config.ini", deviceSection, "zen_path", ""),
        found: CheckPathExists("zen_path", deviceSection)
    })
    
    paths.Push({
        key: "xyplorer_path",
        name: "XYplorer",
        description: "File manager avanzado",
        type: "app",
        path: IniRead("config.ini", deviceSection, "xyplorer_path", ""),
        found: CheckPathExists("xyplorer_path", deviceSection)
    })
    
    ; Tools
    paths.Push({
        key: "nircmd_exe",
        name: "NirCmd",
        description: "Utilidad de línea de comandos para Windows",
        type: "tool",
        path: IniRead("config.ini", "desktop", "nircmd_exe", ""),
        found: CheckPathExists("nircmd_exe", "desktop")
    })
    
    paths.Push({
        key: "notifu_exe",
        name: "Notifu",
        description: "Sistema de notificaciones",
        type: "tool",
        path: IniRead("config.ini", "desktop", "notifu_exe", ""),
        found: CheckPathExists("notifu_exe", "desktop")
    })
    
    ; General settings
    general := {
        showPathsSummary: IniRead("config.ini", "general", "hidePathsSummary", "0") = "0",
        loggingEnabled: IniRead("config.ini", "variables", "logVisibility", "0") = "1",
        cursorKeysEnabled: IniRead("config.ini", "variables", "cursorKeysEnabled", "1") = "1"
    }
    
    ; Info
    info := {
        version: "1.0.0",
        scriptDir: A_ScriptDir,
        configPath: A_ScriptDir . "\config.ini"
    }
    
    ; Send data to WebView
    data := {
        action: "init",
        settings: {
            paths: paths,
            general: general,
            info: info
        }
    }
    
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
    
    if (!data.HasProp("key") || !data.HasProp("path")) {
        return
    }
    
    key := data.key
    path := data.path
    
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
    SendToWebView({
        action: "pathUpdated",
        key: key,
        path: path,
        found: found
    })
}

HandleBrowsePath(data) {
    if (!data.HasProp("key") || !data.HasProp("name")) {
        return
    }
    
    key := data.key
    name := data.name
    
    ; Show file picker
    isFolder := InStr(key, "_dir")
    
    if (isFolder) {
        selectedPath := DirSelect("*", 2, "Seleccioná la carpeta de " . name)
    } else {
        selectedPath := FileSelect(1, "", "Seleccioná el ejecutable de " . name, "Ejecutables (*.exe)")
    }
    
    if (selectedPath) {
        ; Update path
        HandlePathUpdate({ key: key, path: selectedPath })
    }
}

HandleDetectPath(data) {
    if (!data.HasProp("key") || !data.HasProp("name")) {
        return
    }
    
    key := data.key
    name := data.name
    
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
            HandlePathUpdate({ key: key, path: detectedPath })
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
            HandlePathUpdate({ key: key, path: detectedPath })
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
    if (!data.HasProp("key") || !data.HasProp("value")) {
        return
    }
    
    key := data.key
    value := data.value
    
    switch key {
        case "showPathsSummary":
            ; Invert logic: showPathsSummary true = hidePathsSummary false
            IniWrite(value ? "0" : "1", "config.ini", "general", "hidePathsSummary")
            
        case "loggingEnabled":
            IniWrite(value ? "1" : "0", "config.ini", "variables", "logVisibility")
            
        case "cursorKeysEnabled":
            IniWrite(value ? "1" : "0", "config.ini", "variables", "cursorKeysEnabled")
    }
    
    ; Reload config
    loadConfig()
    
    ; Confirm to WebView
    SendToWebView({
        action: "settingUpdated",
        key: key,
        value: value
    })
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
        SETTINGS_GUI.Control.wv.PostWebMessageAsJson(json)
    } catch as err {
        log("Error sending to WebView: " . err.Message)
    }
}

SendMessage(message, type := "info") {
    ; Could implement a toast/notification system in the WebView
    ; For now, just log it
    log("Settings: " . message)
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
