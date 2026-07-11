;===============================================================================
; SETTINGS WINDOW MODULE
; WebView-based configuration interface
;===============================================================================

#Include ".\lib\WebViewToo.ahk"

global SETTINGS_GUI := false
global SETTINGS_READY := false
global SETTINGS_PATHS_DATA := []
global SETTINGS_DEBUG_FILE := A_ScriptDir . "\settings-debug.txt"

;-------------------------------------------------------------------------------
; RESIZE SUPPORT — WM_NCHITTEST override for borderless (+Resize -Caption) window
; Expands the invisible resize grab zone to 6px on all edges/corners.
;-------------------------------------------------------------------------------
OnMessage(0x0084, _Settings_WM_NCHITTEST)

_Settings_WM_NCHITTEST(wParam, lParam, msg, hwnd) {
    global SETTINGS_GUI
    if (!SETTINGS_GUI || hwnd != SETTINGS_GUI.Hwnd)
        return  ; Not our window — let default handling proceed

    static BORDER     := 6
    static HTLEFT     := 10, HTRIGHT      := 11
    static HTTOP      := 12, HTBOTTOM     := 15
    static HTTOPLEFT  := 13, HTTOPRIGHT   := 14
    static HTBOTTOMLEFT := 16, HTBOTTOMRIGHT := 17

    ; Extract signed 16-bit screen coordinates from lParam
    x := lParam << 48 >> 48
    y := lParam << 32 >> 48

    WinGetPos(&wx, &wy, &ww, &wh, hwnd)

    onLeft   := x < wx + BORDER
    onRight  := x >= wx + ww - BORDER
    onTop    := y < wy + BORDER
    onBottom := y >= wy + wh - BORDER

    if (onTop && onLeft)
        return HTTOPLEFT
    if (onTop && onRight)
        return HTTOPRIGHT
    if (onBottom && onLeft)
        return HTBOTTOMLEFT
    if (onBottom && onRight)
        return HTBOTTOMRIGHT
    if (onLeft)
        return HTLEFT
    if (onRight)
        return HTRIGHT
    if (onTop)
        return HTTOP
    if (onBottom)
        return HTBOTTOM
    ; Interior — let default handling return HTCLIENT
}

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
        
        SETTINGS_GUI := WebViewGui("+Resize -Caption", "Configuración - Main Automation",, {DllPath: dllPath})
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
        data := JsonLoad(&json)
        
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
                
            case "addMachine":
                HandleAddMachine(data)

            case "removeMachine":
                HandleRemoveMachine(data)

            case "updateProfile":
                HandleUpdateProfile(data)

            case "removeProfile":
                HandleRemoveProfile(data)

            case "addProfile":
                HandleAddProfile(data)

            case "detectProfiles":
                HandleDetectProfiles(data)

            case "addBookmarkHotkey":
                HandleAddBookmarkHotkey(data)

            case "removeBookmarkHotkey":
                HandleRemoveBookmarkHotkey(data)

            case "toggleBookmarkHotkey":
                HandleToggleBookmarkHotkey(data)

            case "minimize":
                SETTINGS_GUI.Minimize()

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
    terminalShiftVPaste := IniRead("config.ini", "variables", "terminalShiftVPasteEnabled", "0")
    persistentMenus := IniRead("config.ini", "variables", "persistentMenusEnabled", "0")
    
    ; Convert to explicit true/false strings for JSON
    general := Map(
        "showPathsSummary", (hidePathsSummary = "0" ? "true" : "false"),
        "loggingEnabled", (logVisibility = "1" ? "true" : "false"),
        "cursorKeysEnabled", (cursorKeys = "1" ? "true" : "false"),
        "terminalShiftVPasteEnabled", (terminalShiftVPaste = "1" ? "true" : "false"),
        "persistentMenusEnabled", (persistentMenus = "1" ? "true" : "false"),
        "autostart", (IsAutostartEnabled() ? "true" : "false")
    )
    
    ; Debug logging
    SettingsDebugLog("Settings values - hidePathsSummary: '" . hidePathsSummary . "', logVisibility: '" . logVisibility . "', cursorKeys: '" . cursorKeys . "', terminalShiftVPaste: '" . terminalShiftVPaste . "'")
    SettingsDebugLog("Settings bool - showPathsSummary: " . general["showPathsSummary"] . ", loggingEnabled: " . general["loggingEnabled"] . ", cursorKeysEnabled: " . general["cursorKeysEnabled"] . ", terminalShiftVPasteEnabled: " . general["terminalShiftVPasteEnabled"])
    
    ; Info
    info := Map(
        "version", "1.0.0",
        "scriptDir", A_ScriptDir,
        "configPath", A_ScriptDir . "\config.ini"
    )
    
    ; Bookmark hotkeys
    bookmarkHotkeys := GetAllBookmarkHotkeys()

    ; Machine detection
    machines := GetAllMachines()
    machineInfo := Map(
        "currentName", A_ComputerName,
        "currentSection", deviceSection,
        "machines", machines
    )

    ; Browser profiles
    browserProfiles := Map(
        "vivaldi", GetAllProfiles("vivaldi-profiles"),
        "chrome", GetAllProfiles("chrome-profiles"),
        "vivaldiLocal", GetAllProfiles("vivaldi-local-profiles")
    )

    ; Send data to WebView
    settings := Map(
        "paths", paths,
        "general", general,
        "info", info,
        "bookmarkHotkeys", bookmarkHotkeys,
        "machineInfo", machineInfo,
        "browserProfiles", browserProfiles
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
    global cursorKeysEnabled, logVisibility, terminalShiftVPasteEnabled
    
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
            logVisibility := iniValue  ; Update global variable
            SettingsDebugLog("Wrote logVisibility=" . iniValue . ", updated global variable")
            
        case "cursorKeysEnabled":
            iniValue := value ? "1" : "0"
            IniWrite(iniValue, "config.ini", "variables", "cursorKeysEnabled")
            cursorKeysEnabled := iniValue  ; Update global variable
            SettingsDebugLog("Wrote cursorKeysEnabled=" . iniValue . ", updated global variable")

        case "terminalShiftVPasteEnabled":
            iniValue := value ? "1" : "0"
            IniWrite(iniValue, "config.ini", "variables", "terminalShiftVPasteEnabled")
            terminalShiftVPasteEnabled := iniValue
            SettingsDebugLog("Wrote terminalShiftVPasteEnabled=" . iniValue . ", updated global variable")

        case "persistentMenusEnabled":
            iniValue := value ? "1" : "0"
            IniWrite(iniValue, "config.ini", "variables", "persistentMenusEnabled")
            MenuWhichKeyRefreshMainMenus()
            SettingsDebugLog("Wrote persistentMenusEnabled=" . iniValue . ", refreshed main menus")

        case "autostart":
            if (value) {
                EnableAutostart()
            } else {
                DisableAutostart()
            }
            SettingsDebugLog("Autostart toggled to: " . (value ? "enabled" : "disabled"))
    }
    
    ; Reload config
    loadConfig()
    
    ; Confirm to WebView - send back as "true"/"false" strings for consistent JS parsing
    valueToSend := value ? "true" : "false"
    SettingsDebugLog("Sending confirmation to WebView: key=" . key . ", value=" . valueToSend)
    SendToWebView(Map(
        "action", "settingUpdated",
        "key", key,
        "value", valueToSend
    ))
}

;-------------------------------------------------------------------------------
; MACHINE DETECTION OPERATIONS
;-------------------------------------------------------------------------------
; AUTOSTART OPERATIONS
;-------------------------------------------------------------------------------

/**
 * Checks if the app is enabled in Windows autostart registry
 * @return {Boolean} true if app is set to autostart, false otherwise
 */
IsAutostartEnabled() {
    try {
        regPath := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
        value := RegRead(regPath, "MainAutomation", "")
        return (value != "") ? true : false
    } catch {
        return false
    }
}

/**
 * Adds the app to Windows autostart
 */
EnableAutostart() {
    try {
        exePath := A_ScriptFullPath
        regPath := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
        RegWrite(exePath, "REG_SZ", regPath, "MainAutomation")
        SettingsDebugLog("Autostart enabled - registered: " . exePath)
    } catch as err {
        SettingsDebugLog("Error enabling autostart: " . err.Message)
    }
}

/**
 * Removes the app from Windows autostart
 */
DisableAutostart() {
    try {
        regPath := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
        RegDelete(regPath, "MainAutomation")
        SettingsDebugLog("Autostart disabled - registry entry removed")
    } catch as err {
        SettingsDebugLog("Error disabling autostart: " . err.Message)
    }
}

;-------------------------------------------------------------------------------
; MACHINE DETECTION OPERATIONS
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

HandleAddMachine(data) {
    if (!data.Has("name") || !data.Has("section")) {
        return
    }
    AddMachine(data["name"], data["section"])
    SendMachineUpdate()
}

HandleRemoveMachine(data) {
    if (!data.Has("name")) {
        return
    }
    RemoveMachine(data["name"])
    SendMachineUpdate()
}

SendMachineUpdate() {
    global deviceSection
    SendToWebView(Map(
        "action", "machinesUpdated",
        "machineInfo", Map(
            "currentName", A_ComputerName,
            "currentSection", deviceSection,
            "machines", GetAllMachines()
        )
    ))
}

;-------------------------------------------------------------------------------
; BROWSER PROFILE OPERATIONS
;-------------------------------------------------------------------------------

HandleUpdateProfile(data) {
    if (!data.Has("browser") || !data.Has("key") || !data.Has("profileDir")) {
        return
    }
    section := GetProfileSection(data["browser"])
    if (!section) {
        return
    }

    userDataDir := data.Has("userDataDir") ? data["userDataDir"] : ""
    extraFlags := data.Has("extraFlags") ? data["extraFlags"] : ""
    UpdateProfile(section, data["key"], data["profileDir"], userDataDir, extraFlags)
    SendProfileUpdate()
}

HandleAddProfile(data) {
    if (!data.Has("browser") || !data.Has("key") || !data.Has("profileDir")) {
        return
    }
    section := GetProfileSection(data["browser"])
    if (!section) {
        return
    }

    userDataDir := data.Has("userDataDir") ? data["userDataDir"] : ""
    extraFlags := data.Has("extraFlags") ? data["extraFlags"] : ""
    UpdateProfile(section, data["key"], data["profileDir"], userDataDir, extraFlags)
    SendProfileUpdate()
}

HandleRemoveProfile(data) {
    if (!data.Has("browser") || !data.Has("key")) {
        return
    }
    section := GetProfileSection(data["browser"])
    if (!section) {
        return
    }

    RemoveProfile(section, data["key"])
    SendProfileUpdate()
}

HandleDetectProfiles(data) {
    if (!data.Has("browser")) {
        return
    }
    detected := DetectBrowserProfiles(data["browser"])
    SendToWebView(Map(
        "action", "detectedProfiles",
        "browser", data["browser"],
        "profiles", detected
    ))
}

GetProfileSection(browser) {
    switch browser {
        case "vivaldi": return "vivaldi-profiles"
        case "chrome": return "chrome-profiles"
        case "vivaldiLocal": return "vivaldi-local-profiles"
        default: return ""
    }
}

SendProfileUpdate() {
    SendToWebView(Map(
        "action", "profilesUpdated",
        "browserProfiles", Map(
            "vivaldi", GetAllProfiles("vivaldi-profiles"),
            "chrome", GetAllProfiles("chrome-profiles"),
            "vivaldiLocal", GetAllProfiles("vivaldi-local-profiles")
        )
    ))
}

;-------------------------------------------------------------------------------
; BOOKMARK HOTKEY OPERATIONS
;-------------------------------------------------------------------------------

HandleAddBookmarkHotkey(data) {
    if (!data.Has("hotkey")) {
        return
    }

    hotkeyStr := data["hotkey"]

    ; Validate
    if (!ValidateHotkeyString(hotkeyStr)) {
        SendToWebView(Map(
            "action", "bookmarkHotkeyError",
            "message", "Hotkey inválido: " . hotkeyStr
        ))
        return
    }

    ; Check for duplicates
    existing := GetAllBookmarkHotkeys()
    for item in existing {
        if (item["hotkey"] = hotkeyStr) {
            SendToWebView(Map(
                "action", "bookmarkHotkeyError",
                "message", "Hotkey ya existe: " . hotkeyStr
            ))
            return
        }
    }

    ; Add and register live
    AddBookmarkHotkey(hotkeyStr)
    try SetHotkeysForBookmark(hotkeyStr)

    SendToWebView(Map(
        "action", "bookmarkHotkeysUpdated",
        "bookmarkHotkeys", GetAllBookmarkHotkeys()
    ))
}

HandleRemoveBookmarkHotkey(data) {
    if (!data.Has("index")) {
        return
    }

    RemoveBookmarkHotkey(data["index"])

    SendToWebView(Map(
        "action", "bookmarkHotkeysUpdated",
        "bookmarkHotkeys", GetAllBookmarkHotkeys()
    ))
}

HandleToggleBookmarkHotkey(data) {
    if (!data.Has("index") || !data.Has("enabled")) {
        return
    }

    ToggleBookmarkHotkey(data["index"], data["enabled"])

    SendToWebView(Map(
        "action", "bookmarkHotkeysUpdated",
        "bookmarkHotkeys", GetAllBookmarkHotkeys()
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
        json := JsonDump(data)
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

