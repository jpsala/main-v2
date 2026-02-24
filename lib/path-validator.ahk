;===============================================================================
; PATH VALIDATOR MODULE
; Validates configured paths, auto-detects common locations, and handles
; missing paths gracefully with user-friendly dialogs
;===============================================================================

;-------------------------------------------------------------------------------
; GLOBALS
;-------------------------------------------------------------------------------
global MISSING_PATHS := Map()  ; Tracks missing optional paths
global CRITICAL_PATHS := Map() ; Tracks missing critical paths

;-------------------------------------------------------------------------------
; PATH VALIDATION
;-------------------------------------------------------------------------------

/**
 * Validates a path from config.ini and attempts to find it if missing
 * @param {String} section - Config section (e.g., "desktop", "work")
 * @param {String} key - Config key (e.g., "nircmd_exe")
 * @param {String} displayName - User-friendly name for dialogs
 * @param {Boolean} isCritical - If true, will prompt user interactively
 * @param {Array} searchPaths - Optional array of common locations to check
 * @returns {String} Valid path or empty string if not found
 */
ValidatePath(section, key, displayName, isCritical := false, searchPaths := []) {
    ; Read from config
    configPath := IniRead("config.ini", section, key, "")
    
    ; If empty in config, try to auto-detect
    if (!configPath || configPath = "") {
        if (searchPaths.Length > 0) {
            configPath := AutoDetectPath(searchPaths)
            if (configPath) {
                ; Save auto-detected path to config
                IniWrite(configPath, "config.ini", section, key)
                LogMessage("Auto-detected " . displayName . ": " . configPath)
                return configPath
            }
        }
        
        ; Not found - handle based on criticality
        if (isCritical) {
            return PromptForPath(section, key, displayName)
        } else {
            TrackMissingPath(key, displayName, false)
            return ""
        }
    }
    
    ; Validate that the file/folder actually exists
    if (!FileExist(configPath)) {
        ; Try auto-detection first
        if (searchPaths.Length > 0) {
            detectedPath := AutoDetectPath(searchPaths)
            if (detectedPath) {
                IniWrite(detectedPath, "config.ini", section, key)
                LogMessage("Updated " . displayName . " path: " . detectedPath)
                return detectedPath
            }
        }
        
        ; Path doesn't exist - handle based on criticality
        if (isCritical) {
            MsgBox("El path configurado para " . displayName . " no existe:`n`n" 
                . configPath . "`n`nPor favor, seleccioná la ubicación correcta.", 
                "Path no encontrado", "Icon!")
            return PromptForPath(section, key, displayName, configPath)
        } else {
            TrackMissingPath(key, displayName, false)
            LogMessage("Warning: " . displayName . " not found at: " . configPath)
            return ""
        }
    }
    
    return configPath
}

/**
 * Attempts to auto-detect a file/folder from common locations
 * @param {Array} searchPaths - Array of paths to check
 * @returns {String} First valid path found, or empty string
 */
AutoDetectPath(searchPaths) {
    for path in searchPaths {
        ; Expand environment variables
        expandedPath := ExpandEnvVars(path)
        if (FileExist(expandedPath)) {
            return expandedPath
        }
    }
    return ""
}

/**
 * Prompts user with a file/folder picker dialog
 * @param {String} section - Config section to save to
 * @param {String} key - Config key to save to
 * @param {String} displayName - User-friendly name
 * @param {String} defaultPath - Default path to show in dialog
 * @returns {String} Selected path or empty string if cancelled
 */
PromptForPath(section, key, displayName, defaultPath := "") {
    ; Determine if we're looking for a file or folder based on the key name
    isFolder := InStr(key, "_dir") || InStr(key, "_folder")
    
    if (isFolder) {
        selectedPath := DirSelect("*" . (defaultPath ? defaultPath : ""), 2, 
            "Seleccioná la carpeta de " . displayName)
    } else {
        selectedPath := FileSelect(1, defaultPath, 
            "Seleccioná el ejecutable de " . displayName, 
            "Ejecutables (*.exe)")
    }
    
    if (selectedPath) {
        ; Save to config
        IniWrite(selectedPath, "config.ini", section, key)
        LogMessage("User selected " . displayName . ": " . selectedPath)
        return selectedPath
    } else {
        ; User cancelled - track as missing
        TrackMissingPath(key, displayName, true)
        return ""
    }
}

/**
 * Tracks a missing path for later reporting
 */
TrackMissingPath(key, displayName, isCritical) {
    pathInfo := Map()
    pathInfo["name"] := displayName
    pathInfo["key"] := key
    
    if (isCritical) {
        CRITICAL_PATHS[key] := pathInfo
    } else {
        MISSING_PATHS[key] := pathInfo
    }
}

/**
 * Expands environment variables in a path string
 * Supports %VARNAME% and handles common substitutions
 */
ExpandEnvVars(path) {
    ; Replace common environment variables
    path := StrReplace(path, "%ProgramFiles%", A_ProgramFiles)
    path := StrReplace(path, "%ProgramFiles(x86)%", A_ProgramFiles . " (x86)")
    path := StrReplace(path, "%AppData%", A_AppData)
    path := StrReplace(path, "%LocalAppData%", EnvGet("LOCALAPPDATA"))
    path := StrReplace(path, "%UserProfile%", A_MyDocuments . "\..")
    path := StrReplace(path, "%Username%", A_UserName)
    path := StrReplace(path, "%ComputerName%", A_ComputerName)
    
    ; Handle any remaining %VAR% patterns
    while (RegExMatch(path, "%([^%]+)%", &match)) {
        envValue := EnvGet(match[1])
        if (envValue)
            path := StrReplace(path, match[0], envValue)
        else
            break  ; Avoid infinite loop if env var doesn't exist
    }
    
    return path
}

/**
 * Shows a summary of missing paths at startup if any were not found
 * Can display as WebView window or simple MsgBox
 */
ShowMissingPathsSummary() {
    criticalCount := CRITICAL_PATHS.Count
    optionalCount := MISSING_PATHS.Count
    
    if (criticalCount = 0 && optionalCount = 0)
        return  ; All paths are valid
    
    ; Check if user wants to hide this message
    hidePathsSummary := IniRead("config.ini", "general", "hidePathsSummary", "0")
    if (hidePathsSummary = "1") {
        return
    }
    
    ; Try to show in WebView settings window (preferred)
    try {
        ShowSettingsWindow("paths")
        return
    } catch {
        ; Fallback to MsgBox if WebView fails
    }
    
    ; Fallback: Show traditional MsgBox
    message := "Algunas aplicaciones no fueron encontradas:`n`n"
    
    if (criticalCount > 0) {
        message .= "❌ CRÍTICAS (funcionalidad limitada):`n"
        for key, info in CRITICAL_PATHS {
            message .= "  • " . info["name"] . "`n"
        }
        message .= "`n"
    }
    
    if (optionalCount > 0) {
        message .= "⚠ OPCIONALES (features deshabilitadas):`n"
        for key, info in MISSING_PATHS {
            message .= "  • " . info["name"] . "`n"
        }
        message .= "`n"
    }
    
    message .= "Podés configurarlas más tarde editando:`n" . A_ScriptDir . "\config.ini`n`n"
    message .= "El script funcionará con las aplicaciones disponibles."
    
    MsgBox(message, "Configuración de Paths", "Icon! 4096")
}

/**
 * Logs a message (uses logging.ahk if available)
 */
LogMessage(message) {
    try {
        ; Try to use the logging module if available
        log(message)
    } catch {
        ; Fallback to OutputDebug
        OutputDebug(message)
    }
}

;-------------------------------------------------------------------------------
; COMMON PATH DETECTION PROFILES
;-------------------------------------------------------------------------------

/**
 * Returns common search paths for well-known applications
 * @param {String} appName - Name of the application
 * @returns {Array} Array of paths to check
 */
GetCommonPaths(appName) {
    switch appName {
        case "nircmd":
            return [
                "C:\tools\nircmd.exe",
                A_ProgramFiles . "\NirCmd\nircmd.exe",
                A_ScriptDir . "\tools\nircmd.exe"
            ]
        
        case "vscode":
            return [
                EnvGet("LOCALAPPDATA") . "\\Programs\\Microsoft VS Code\\Code.exe",
                A_ProgramFiles . "\Microsoft VS Code\Code.exe"
            ]
        
        case "cursor":
            return [
                A_ProgramFiles . "\Cursor\Cursor.exe",
                EnvGet("LOCALAPPDATA") . "\\Programs\\Cursor\\Cursor.exe"
            ]
        
        case "chrome":
            return [
                A_ProgramFiles . "\Google\Chrome\Application\chrome.exe",
                A_ProgramFiles . " (x86)\Google\Chrome\Application\chrome.exe",
                EnvGet("LOCALAPPDATA") . "\\Google\\Chrome\\Application\\chrome.exe"
            ]
        
        case "vivaldi":
            return [
                "C:\tools\vivaldi\Application\vivaldi.exe",
                A_ProgramFiles . "\Vivaldi\Application\vivaldi.exe",
                EnvGet("LOCALAPPDATA") . "\\Vivaldi\\Application\\vivaldi.exe"
            ]
        
        case "xyplorer":
            return [
                "C:\tools\XYplorer-portable\XYplorer.exe",
                A_ProgramFiles . "\XYplorer\XYplorer.exe"
            ]
        
        default:
            return []
    }
}
