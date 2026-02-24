;===============================================================================
; ROA & WINDOW MANAGEMENT
;===============================================================================

/**
 * RoAWithPattern - Activates a window if it exists, minimizes if active, or launches if not found
 * @param {string} winPattern - Window title or pattern to search for
 * @param {string} launchCmd - Command to run if window is not found
 * @param {string} title - Title to set for the window (optional)
 * @param {boolean} onlyShowInDebug - If true, only shows debug message without action
 * @param {string|boolean} bookmark - Bookmark identifier to set for the window
 * @param {number} timeout - Maximum time to wait for window to appear (milliseconds)
 * @returns {object|boolean} Window handle on success, false on failure
 */
RoAWithPattern(winPattern := false, launchCmd := "", bookmark := false, timeout := 5000, logIt := false) {
    try {
        ; Use toggleOrLaunchApp for window handling with custom callback to handle the result
        resultHwnd := false

        ; Define callback functions
        onToggleFunc(hwnd, wasMinimized) {
            resultHwnd := hwnd
            if (bookmark)
                setManualBookmark(bookmark, hwnd)
            return true
        }

        onLaunchFunc(hwnd) {
            resultHwnd := hwnd
            if (bookmark)
                setManualBookmark(bookmark, hwnd)
            return true
        }

        onErrorFunc(errorMsg, errorCode) {
            msg('No se pudo abrir la app: ' . launchCmd, { seconds: 3 })
            log('RoA error: ' . errorMsg . ' (Error: ' . errorCode . ')')
            soundError()
            return false
        }

        hwnd := toggleOrLaunchApp({
            winPattern: winPattern,
            launchCmd: launchCmd,
            matchMode: 'contains',
            timeout: timeout,
            onToggle: onToggleFunc,
            onLaunch: onLaunchFunc,
            onError: onErrorFunc,
            logIt: logIt,
            bookmark: bookmark
        })

        return resultHwnd
    } catch Error as e {
        log("RoA error: " . e.Message)
        return false
    }
}

/**
 * Generic function to toggle (minimize/activate) a window or launch the app if not found
 * @param {Object} params Configuration object with the following properties:
 * - winPattern: Window pattern to match (e.g. 'ahk_exe notepad.exe', 'My Window Title', etc.)
 * - launchCmd: Command to execute if window is not found
 * - windowTitle: (Optional) Title to use when launching. Defaults to winPattern
 * - matchMode: (Optional) How to match the title: 'contains' (default), 'exact', or 'startsWith'
 * - extraCheck: (Optional) Additional function that takes (hwnd, class, title) and returns boolean
 * - timeout: (Optional) Maximum time to wait for window to appear in milliseconds (default: 5000)
 * - onToggle: (Optional) Callback function called after toggling a window - receives (hwnd, wasMinimized)
 * - onLaunch: (Optional) Callback function called after launching a new window - receives (hwnd)
 * - onError: (Optional) Callback function called on error - receives (errorMsg, errorCode)
 * @returns {boolean} True if window was found or successfully launched, false otherwise
 */
toggleOrLaunchApp(params) {
    winPattern := params.winPattern
    matchMode := params.HasProp('matchMode') ? params.matchMode : 'contains'
    extraCheck := params.HasProp('extraCheck') ? params.extraCheck : false
    timeout := params.HasProp('timeout') ? params.timeout : 5000
    logIt := params.HasProp('logIt') ? params.logIt : false
    bookmark := params.HasProp('bookmark') ? params.bookmark : false

    ; Log for debugging purposes
    if (logIt) {
        log("toggleOrLaunchApp looking for: " . winPattern)
    }

    ; Set title match mode for the search
    savedMatchMode := A_TitleMatchMode
    switch matchMode {
        case 'exact': SetTitleMatchMode(3)
        case 'startsWith': SetTitleMatchMode(1)
        default: SetTitleMatchMode(2)  ; 'contains'
    }

    ; Try to find the window first
    found := false
    hwnd := false

    ; If bookmark is provided, try to find by stored hwnd first
    msg('Looking for window by bookmark: ')
    if (bookmark) {
        storedHwnd := GetBookmarkHwnd(bookmark)
        if (storedHwnd) {
            hwnd := storedHwnd
            msg('Found window by bookmark: ' . bookmark . ' -> ' . hwnd)
            if (logIt) {
                log('Found window by bookmark: ' . bookmark . ' -> ' . hwnd)
            }
        }
    }

    ; If not found by bookmark, try pattern search
    if (!hwnd) {
        hwnd := WinExist(winPattern)
    }

    ; If window exists, toggle it
    if (hwnd) {
        msg('Found existing window: ' . hwnd)
        if (logIt) {
            log('Found existing window: ' . hwnd)
        }
        wasMinimized := false

        ; Get window info for extra check if needed
        class := WinGetClass(hwnd)
        title := WinGetTitle(hwnd)

        ; Run extra validation if provided
        if (extraCheck && Type(extraCheck) == "Func" && !extraCheck.Call(hwnd, class, title)) {
            msg('Window failed extra check')
            if (logIt) {
                log('Window failed extra check')
            }
        } else {
            ; Window found - toggle its state
            if (WinActive(hwnd)) {
                msg('Window is active, minimizing')
                if (logIt) {
                    log('Window is active, minimizing')
                }
                WinMinimize(hwnd)
                wasMinimized := true
            } else {
                msg('Window exists but not active, activating')
                if (logIt) {
                    log('Window exists but not active, activating')
                }
                WinShow(hwnd)
                WinActivate(hwnd)
            }

            found := true

            ; Call onToggle callback if provided
            if (params.HasProp('onToggle') && Type(params.onToggle) == "Func") {
                params.onToggle.Call(hwnd, wasMinimized)
            }
        }
    } else {
        msg('No existing window found with pattern: ' . winPattern)
        if (logIt) {
            log('No existing window found with pattern: ' . winPattern)
        }
    }

    ; Restore original match mode
    SetTitleMatchMode(savedMatchMode)

    ; Launch the app if no matching window found
    if (!found) {
        ; Check if launchCmd is provided and valid
        if (!params.HasProp('launchCmd') || !params.launchCmd || params.launchCmd = "") {
            msg('No se puede lanzar: path no configurado', { seconds: 3 })
            if (logIt) {
                log('Launch error: launchCmd not provided or empty')
            }
            if (params.HasProp('onError') && Type(params.onError) == "Func") {
                return params.onError.Call('Launch command not provided', 0)
            }
            return false
        }
        
        ; Extract executable path from command (handle quotes and arguments)
        exePath := params.launchCmd
        if (InStr(exePath, '"')) {
            ; Command has quotes, extract path between first pair of quotes
            RegExMatch(exePath, '"([^"]+)"', &match)
            if (match)
                exePath := match[1]
        } else {
            ; No quotes, get first part before space (if any)
            spacePos := InStr(exePath, ' ')
            if (spacePos > 0)
                exePath := SubStr(exePath, 1, spacePos - 1)
        }
        
        ; Validate executable exists
        if (!FileExist(exePath)) {
            msg('Aplicación no encontrada: ' . exePath, { seconds: 3 })
            if (logIt) {
                log('Launch error: executable not found: ' . exePath)
            }
            if (params.HasProp('onError') && Type(params.onError) == "Func") {
                return params.onError.Call('Executable not found: ' . exePath, 2)
            }
            return false
        }
        
        try {
            windowTitle := params.HasProp('windowTitle') ? params.windowTitle : winPattern
            msg('Launching: ' . params.launchCmd)
            if (logIt) {
                log('Launching: ' . params.launchCmd . ' - title: ' . windowTitle)
            }

            initialList := WinGetList(,,'Waiting for ', 'Waiting for ')
            Run(params.launchCmd)
            if (A_LastError) {
                msg('Launch error: ' . A_LastError)
                if (logIt) {
                    log('Launch error: ' . A_LastError)
                }
                if (params.HasProp('onError') && Type(params.onError) == "Func") {
                    return params.onError.Call('Failed to launch application', A_LastError)
                }
                return false
            }

            ToolTip('Waiting for ' windowTitle, 10, 120, 14)
            
            maxWaitTime := timeout
            startTime := A_TickCount
            hwnd := false
            newList := WinGetList(,,'Waiting for ', 'Waiting for ')


            try {
                while (A_TickCount - startTime < maxWaitTime) {
                    newList := WinGetList(,,'Waiting for ', 'Waiting for ')
                    if (newList.Length > initialList.Length) {
                        if (logIt) {
                            log('newList.Length > initialList.Length -> CompareWindowLists')
                        }
                        hwnd := CompareWindowLists(initialList, newList, logIt)
                        if (hwnd) {
                            if (logIt) {
                                log('Found new window by list: ' . hwnd . ' - title: ' . WinGetTitle(hwnd))
                            }
                            break
                        }
                    }
                    ; Fallback: try WinExist with pattern
                    if (!hwnd) {
                        hwnd := WinExist(windowTitle)
                        if (hwnd) {
                            title := WinGetTitle(hwnd)
                            if (InStr(title, "Waiting for")) {
                                hwnd := false
                            }
                        }
                        if (!hwnd) {
                            hwnd := WinExist(winPattern)
                            if (hwnd) {
                                title := WinGetTitle(hwnd)
                                if (InStr(title, "Waiting for")) {
                                    hwnd := false
                                }
                            }
                        }
                        if (hwnd) {
                            if (logIt) {
                                winTitle := WinGetTitle(hwnd)
                                processName := WinGetProcessName(hwnd)
                                log('Found new window by pattern -> hwnd:' . hwnd . ' - title:' . winTitle . ' - processName:' . processName)
                            }
                            break
                        }
                    }
                }
                if (hwnd and WinExist(hwnd)) {
                    winTitle := WinGetTitle(hwnd) . ' - ' . hwnd
                    if (logIt) {
                        log("hwnd and WinExist(hwnd) -> Activating new window " . hwnd . ' - ' . winTitle)
                    }
                    WinActivateFast(hwnd)

                    ; Call onLaunch callback if provided
                    if (params.HasProp('onLaunch') && Type(params.onLaunch) == "Func") {
                        params.onLaunch.Call(hwnd)
                    }
                    if (bookmark) {
                        if (logIt) {
                            winTitle := WinGetTitle(hwnd)
                            log('Setting manual bookmark: ' . bookmark . ' -> ' . winTitle)
                        }
                        setManualBookmark(bookmark, hwnd)
                    }
                    return hwnd
                } else {
                    msg('New window not found after launch')
                    if (logIt) {
                        log("New window not found after launch")
                    }
                    if (params.HasProp('onError') && Type(params.onError) == "Func") {
                        params.onError.Call('Failed to find window after launch', 0)
                    }
                    return false
                }
            } finally {
                ToolTip(, , , 14)  ; Always clear the tooltip
            }
        } catch Error as e {
            msg('toggleOrLaunchApp error: ' . e.Message)
            if (logIt) {
                log("toggleOrLaunchApp error: " . e.Message)
            }
            if (params.HasProp('onError') && Type(params.onError) == "Func") {
                params.onError.Call(e.Message, 0)
            }
            return false
        }
    }

    return hwnd
}

/**
 * Toggle or launch an app using STRICT UID-based instance tracking.
 * This function is specifically designed for multi-profile applications 
 * where distinguishing between instances is critical.
 * 
 * Unlike toggleOrLaunchApp and toggleOrLaunchAppWithId, this function:
 * 1. ONLY looks for windows by uid in the appInstanceMap
 * 2. Does NOT attempt to match by window pattern if uid not found
 * 3. Immediately launches a new instance if uid not found
 * 
 * @param {Object} params Configuration object with the following properties:
 * - launchCmd: Command to execute if window is not found
 * - uid: Unique identifier for this specific instance (REQUIRED)
 * - onToggle: (Optional) Callback function called after toggling a window
 * - onLaunch: (Optional) Callback function called after launching a new window
 * - onError: (Optional) Callback function called on error
 * - timeout: (Optional) Maximum time to wait for window to appear (default: 5000)
 * @returns {any} Window handle on success, false on failure
 */
toggleOrLaunchAppByUid(params, withDebug := false) {
    global appInstanceMap

    ; Required parameters
    launchCmd := params.launchCmd
    uid := params.HasProp('uid') ? params.uid : false
    timeout := params.HasProp('timeout') ? params.timeout : 5000

    if (withDebug) {
        log("Looking for instance by uid: " . uid)
    }

    ; Check if we have this instance in our map
    if (appInstanceMap.Has(uid)) {
        storedHwnd := appInstanceMap[uid]
        if (withDebug) {
            log("Found stored instance: " . storedHwnd)
        }

        ; Verify window still exists
        if (WinExist(storedHwnd)) {
            ; Toggle the window (minimize if active, activate if not)
            if (WinActive(storedHwnd)) {
                if (withDebug) {
                    log("Window active, minimizing")
                }
                WinMinimize(storedHwnd)
            } else {
                if (withDebug) {
                    log("Window exists but not active, activating")
                }
                WinShow(storedHwnd)
                WinActivate(storedHwnd)
            }
            return storedHwnd
        } else {
            ; Window doesn't exist anymore, remove from map
            if (withDebug) {
                log("Stored instance no longer exists, removing")
            }
            appInstanceMap.Delete(uid)
        }
    }

    ; If we get here, either uid wasn't found in map or the window no longer exists
    ; SKIP fallback pattern matching and go straight to launching

    if (withDebug) {
        log("No instance found by uid, launching new instance: " . launchCmd)
    }

    ; Launch a new instance
    try {
        initialList := WinGetList()
        Run(launchCmd)
        if (A_LastError) {
            if (withDebug) {
                log("Launch error: " . A_LastError)
            }
            if (params.HasProp('onError') && Type(params.onError) == "Func") {
                return params.onError.Call("Failed to launch application", A_LastError)
            }
            return false
        }

        ; Wait for new window to appear
        ToolTip("Waiting for new window", 10, 120, 14)
        maxWaitTime := timeout
        startTime := A_TickCount
        hwnd := false

        try {
            while (true) {
                newList := WinGetList(,,'Waiting for new window')
                if (newList.Length > initialList.Length) {
                    hwnd := CompareWindowLists(initialList, newList)
                    if (hwnd) {
                        if (withDebug) {
                            log("Found new window: " . hwnd)
                        }
                        break
                    }
                }
                if (A_TickCount - startTime >= maxWaitTime) {
                    if (withDebug) {
                        log("Timeout waiting for new window")
                    }
                    break
                }
                Sleep(100)
                newList := WinGetList()
            }

            if (WinExist("ahk_id " . hwnd)) {
                if (withDebug) {
                    log("Activating new window")
                }
                WinActivateFast("ahk_id " . hwnd)

                ; Store this window handle with the uid
                hwndStr := "ahk_id " . hwnd
                appInstanceMap[uid] := hwndStr
                SaveAppInstanceMap()
                if (withDebug) {
                    log("Stored new instance mapping: " . uid . " = " . hwndStr)
                }

                ; Call onLaunch callback if provided
                if (params.HasProp('onLaunch') && Type(params.onLaunch) == "Func") {
                    params.onLaunch.Call(hwnd)
                }

                return hwnd
            } else {
                if (withDebug) {
                    log("New window not found after launch")
                }
                if (params.HasProp('onError') && Type(params.onError) == "Func") {
                    params.onError.Call("Failed to find window after launch", 0)
                }
                return false
            }
        } finally {
            ToolTip(, , , 14)  ; Always clear the tooltip
        }
    } catch Error as e {
        if (withDebug) {
            log("toggleOrLaunchAppByUid error: " . e.Message)
        }
        if (params.HasProp('onError') && Type(params.onError) == "Func") {
            params.onError.Call(e.Message, 0)
        }
        return false
    }
}

CompareWindowLists(oldList, newList, logIt := false) {
    added := []
    for hwnd in newList {
        if (!InArray(oldList, hwnd)) {
            t := ''
            try t := WinGetClass(hwnd)
            title := ''
            try title := WinGetTitle(hwnd)
            ; Exclude tooltips, SysShadow, and windows with titles containing 'Waiting for'
            if (t !== 'tooltips_class32' and t !== 'SysShadow' and !(InStr(title, "Waiting for"))) {
                if (logIt) {
                    log('Found new window: ' . hwnd . ' - ' . title)
                }
                added.Push(hwnd)
            }
        }
    }
    return added.Length > 0 ? added[1] : false
}

/**
 * Roa - Alias-based window management
 * @param {string} alias - Unique identifier for the window
 * @param {string} launchCmd - Command to launch if window not found
 * @param {string|boolean} bookmark - Bookmark identifier to set for the window
 * @returns {object|boolean} Window handle on success, false on failure
 */
Roa(alias, launchCmd := "", bookmark := false, logIt := false) {
        ; Try to find window by alias first
        winHandle := getAliasHandle(alias, false)

        if (winHandle) {
            ; Window found by alias - toggle it
            if (WinActive(winHandle)) {
                WinMinimize(winHandle)
            } else {
                WinShow(winHandle)
                WinActivateFast(winHandle)
            }
            return winHandle
        } else {
            ; No window found by alias - need to launch
            return RoaLaunch(alias, launchCmd, bookmark, logIt)
        }

}

/**
 * Helper function for RoAAlias to handle launching and alias assignment
 */
RoaLaunch(alias, launchCmd, bookmark := false, logIt := false) {
    
        hwnd := RunAndWaitForNewWindow(launchCmd, alias, logIt)
        
        if (hwnd && WinExist(hwnd)) {
            ; Successfully found new window - activate it
            WinActivateFast(hwnd)

            ; Set the alias for this new window
            if (setAlias(alias, hwnd)) {
                if (logIt) {
                    winTitle := WinGetTitle(hwnd)
                    log('RoAAliasLaunch: Set alias "' . alias . '" -> ' . winTitle . ' (' . hwnd . ')')
                }
            } else {
                if (logIt) {
                    log('RoAAliasLaunch: Failed to set alias "' . alias . '"')
                }
                MsgBox('Failed to set alias "' . alias . '"')
                return false
            }

            ; Set bookmark if provided
            if (bookmark) {
                setManualBookmark(bookmark, hwnd)
                if (logIt) {
                    log('RoAAliasLaunch: Set bookmark "' . bookmark . '" -> ' . hwnd)
                }
            }

            if (logIt) {
                log('RoAAliasLaunch: New window activated: ' . hwnd)
            }
            msg('Window for new instance ' . alias . ' found', { seconds: 3 })
            return hwnd
        } else {
            msg('Window for new instance ' . alias . ' not found', { seconds: 3 })
            if (logIt) {
                log("RoAAliasLaunch: Failed to find new window after launch")
            }
            return false
        }

}

/**
 * Wait for a new window to appear after launching an application
 * @param {string} launchCmd - Command to launch
 * @param {number} timeout - Timeout in milliseconds
 * @param {boolean} logIt - Whether to log operations
 * @param {string} alias - Alias name for logging purposes
 * @returns {number|false} Window handle of new window, or false if not found
 */
RunAndWaitForNewWindow(launchCmd, alias, logIt := false) {
    timeout := 5000
    if (logIt) {
        msgId := msg('Waiting for ' alias, { seconds: timeout / 1000 })
    }

    startTime := A_TickCount
    hwnd := false

    initialList := WinGetList()

    Run(launchCmd)

    if (A_LastError) {
        msg('Launch error: ' . A_LastError, { seconds: 3 })
        if (logIt) {
            log('RunAndWaitForNewWindow: Failed to launch ' . launchCmd)
        }
        return false
    }

    while (A_TickCount - startTime < timeout) {
        newList := WinGetList()

        if (newList.Length > initialList.Length) {
            hwnd := CompareWindowLists(initialList, newList, logIt)
            if (hwnd) {
                if (logIt) {
                    log('WaitForNewWindow: Found new window by list: ' . hwnd)
                }
                break
            }
        }

        Sleep(100)
    }

    return hwnd
}

HasValue(arr, value) {
    for item in arr {
        if (item = value)
            return true
    }
    return false
} 


;===============================================================================
; ALIAS-BASED WINDOW MANAGEMENT (NEW)
;===============================================================================

/**
 * Load alias-to-handle mapping from config.ini on startup
 * Mirrors LoadAppInstanceMap() pattern exactly
 */
LoadAliasMap() {
    global aliasMap

    section := IniRead("config.ini", "windowAliases", , "")
    ar := StrSplit(section, '`n')
    for line in ar {
        lineAr := StrSplit(line, '=')
        if (lineAr.Length == 2) {
            alias := lineAr[1]
            winHandle := lineAr[2]
            if (WinExist(winHandle) == 0) {
                ; Clean up stale alias from config
                IniDelete("config.ini", "windowAliases", alias)
                log("Cleaned up stale alias: " . alias . " -> " . winHandle)
            } else {
                aliasMap[alias] := winHandle
                log("Loaded alias: " . alias . " -> " . winHandle)
            }
        }
    }
}

/**
 * Save alias-to-handle mapping to config.ini on shutdown
 * Mirrors SaveAppInstanceMap() pattern exactly
 */
SaveAliasMap(ExitReason := '', ExitCode := '') {
    global aliasMap

    for alias, handle in aliasMap {
        if (WinExist(handle)) {
            IniWrite(String(handle), "config.ini", "windowAliases", String(alias))
        } else {
            ; Clean up stale aliases
            IniDelete("config.ini", "windowAliases", String(alias))
            log("Removed invalid alias during save: " . alias . " -> " . handle)
        }
    }
}
/**
 * Associate an alias with a window handle
 * @param {string} alias - Human-readable alias for the window
 * @param {string|number} winHandle - Window handle (HWND) or active window if omitted
 */
setAlias(alias, winHandle := false, logIt := false) {
    global aliasMap

    if (!winHandle) {
        winHandle := WinGetID("A")
    }

    if (!WinExist(winHandle)) {
        log("setAlias failed: Window does not exist - " . alias . " -> " . String(winHandle))
        return false
    }

    winHandleStr := "ahk_id " . winHandle
    aliasMap[alias] := winHandleStr

    if (logIt) {
        log("Alias set: " . alias . " -> " . String(winHandle))
    }
    SaveAliasMap()  ; Persist immediately
    return true
}

/**
 * Get window handle for a given alias
 * @param {string} alias - Alias to look up
 * @returns {string|false} Window handle string or false if not found/invalid
 */
getAliasHandle(alias, logIt := false) {
    global aliasMap

    if (!aliasMap.Has(alias)) {
        return false
    }

    storedHandle := aliasMap[alias]
    if (!WinExist(storedHandle)) {
        ; Clean up stale handle
        aliasMap.Delete(alias)
        IniDelete("config.ini", "windowAliases", alias)
        if (logIt) {
            log("Cleaned up invalid alias: " . alias . " -> " . storedHandle)
        }
        return false
    }
    if (logIt) {
        log("Alias resolved: " . alias . " -> " . storedHandle)
    }
    return storedHandle
}

/**
 * Remove an alias association
 * @param {string} alias - Alias to remove
 */
clearAlias(alias, logIt := false) {
    global aliasMap

    if (aliasMap.Has(alias)) {
        oldHandle := aliasMap[alias]
        aliasMap.Delete(alias)
        IniDelete("config.ini", "windowAliases", alias)
        if (logIt) {
            log("Alias cleared: " . alias . " was -> " . oldHandle)
        }
        return true
    }

    if (logIt) {
        log("clearAlias: alias not found - " . alias)
    }
    return false
}

/**
 * Check if an alias is valid (exists and window is alive)
 * @param {string} alias - Alias to check
 * @returns {boolean} True if alias exists and window is valid
 */
isValidAlias(alias) {
    global aliasMap

    if (!aliasMap.Has(alias)) {
        return false
    }

    storedHandle := aliasMap[alias]
    return WinExist(storedHandle)
}