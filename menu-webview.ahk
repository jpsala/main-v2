; ========================================
; Enhanced Menu System with WebView Support
; ========================================
; 
; Features:
; - Keyboard navigation with timeout (showDelaySeconds/waitSeconds option) for instant execution
; - WebView-based GUI with fuzzy filtering when no key pressed
; - Sub-menus with breadcrumb navigation
; - Key combinations returned as strings (e.g., "sx1" for s→x→1)
; - Full keyboard navigation: arrows, enter, escape, backspace to go back
;
; Usage:
; - Use customMenuWebView(options) instead of customMenu(options)
; - Same options structure as customMenu
; - If key pressed within the configured wait: executes immediately
; - If timeout: shows WebView picker with filtering
;
#Include ".\lib\WebViewToo.ahk"

global MENU_WEBVIEW_GUI := false
global MENU_WEBVIEW_READY := false
global MENU_WEBVIEW_PREV_WIN := 0
global MENU_WEBVIEW_RESULT := ""
global MENU_WEBVIEW_CURRENT_OPTIONS := {}

; ========================================
; Public API
; ========================================

/**
 * Shows a menu with keyboard-first navigation and WebView fallback
 * @param options Object with { showDelaySeconds|waitSeconds|waitml, items, title? }
 * @param parentKeys Array of parent keys for submenu tracking
 * @returns String key combination or false if cancelled
 */
customMenuWebView(options, parentKeys := []) {
    if (!options.HasProp("items") || !IsObject(options.items)) {
        return false
    }
    
    ; Check if a wait option is provided - use keyboard navigation first
    if (MenuWebViewGetWaitSeconds(options) > 0) {
        return ShowKeyboardMenuWebView(options, parentKeys)
    }
    
    ; If no wait is configured, show WebView menu directly
    return ShowWebViewMenu(options, parentKeys)
}

; ========================================
; Keyboard-first Navigation
; ========================================

ShowKeyboardMenuWebView(options, parentKeys := []) {
    ; Release any stuck modifier keys
    SetKeyDelay(10)
    if (GetKeyState("Shift", "P")) {
        Send("{Shift Up}")
        Sleep(10)
    }
    if (GetKeyState("Ctrl", "P")) {
        Send("{Ctrl Up}")
        Sleep(10)
    }
    if (GetKeyState("Alt", "P")) {
        Send("{Alt Up}")
        Sleep(10)
    }
    
    ; Wait for a key press with timeout
    timeout := MenuWebViewGetWaitSeconds(options)
    Input := InputHook("L1 T" . timeout)  ; Single key, with timeout
    Input.Start()
    Input.Wait()
    
    ; If a key was pressed within the timeout, handle it
    if ((Input.EndReason == "Max" || Input.EndReason == "EndKey") && Input.Input != "") {
        keyPressed := Input.Input
        actualKey := keyPressed
        
        ; Find the item with this key
        foundItem := false
        matchedKey := ""
        
        for index, item in options.items {
            ; Try exact match with the actual key pressed
            if (item.key == actualKey) {
                foundItem := item
                matchedKey := actualKey
                break
            }
            ; For alphabetic keys, also try case-insensitive match
            if (RegExMatch(actualKey, "^[a-zA-Z]$") && RegExMatch(item.key, "^[a-zA-Z]$")) {
                if (StrLower(item.key) == StrLower(actualKey)) {
                    foundItem := item
                    matchedKey := item.key  ; Use the original case from the menu item
                    break
                }
            }
        }
        
        if (foundItem) {
            ; If this item has subitems, show submenu
            if (foundItem.HasProp("items") && IsObject(foundItem.items)) {
                subOptions := {
                    waitSeconds: timeout,
                    items: foundItem.items
                }
                if (options.HasProp("title")) {
                    subOptions.title := options.title
                }
                newParentKeys := parentKeys.Clone()
                newParentKeys.Push(matchedKey)
                return ShowKeyboardMenuWebView(subOptions, newParentKeys)
            } else {
                ; No subitems, return the result as a string with all keys
                allKeys := parentKeys.Clone()
                allKeys.Push(matchedKey)
                keyString := ""
                for key in allKeys {
                    keyString .= key
                }
                return keyString
            }
        }
        
        ; Key not found - fall back to WebView menu
        return ShowWebViewMenu(options, parentKeys)
    } else {
        ; Timeout occurred - fall back to WebView menu
        return ShowWebViewMenu(options, parentKeys)
    }
}

MenuWebViewGetWaitSeconds(options) {
    if (options.HasProp("showDelaySeconds"))
        return options.showDelaySeconds
    if (options.HasProp("waitSeconds"))
        return options.waitSeconds
    if (options.HasProp("waitml"))
        return options.waitml / 1000
    return 0
}

; ========================================
; WebView Menu
; ========================================

MenuWebViewInit() {
    global MENU_WEBVIEW_GUI, MENU_WEBVIEW_READY
    
    if IsObject(MENU_WEBVIEW_GUI)
        return
    
    MENU_WEBVIEW_READY := false
    
    dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
    MENU_WEBVIEW_GUI := WebViewGui("+AlwaysOnTop -Caption", "Menu Picker",, {DllPath: dllPath})
    MENU_WEBVIEW_GUI.OnEvent("Close", (*) => MenuWebViewHide())
    
    if (A_IsCompiled)
        MENU_WEBVIEW_GUI.Control.BrowseFolder(A_ScriptDir)
    
    MENU_WEBVIEW_GUI.Control.wv.add_WebMessageReceived(MenuWebViewMessageHandler)
    MENU_WEBVIEW_GUI.Control.wv.add_NavigationCompleted(MenuWebViewNavigationCompleted)
    
    MENU_WEBVIEW_GUI.Navigate("ui/menu.html")
}

MenuWebViewNavigationCompleted(wv, args) {
    global MENU_WEBVIEW_READY := true
}

ShowWebViewMenu(options, parentKeys := []) {
    global MENU_WEBVIEW_GUI, MENU_WEBVIEW_PREV_WIN, MENU_WEBVIEW_RESULT, MENU_WEBVIEW_CURRENT_OPTIONS
    
    if !IsObject(MENU_WEBVIEW_GUI)
        MenuWebViewInit()
    
    ; Wait for WebView to be ready
    waitStart := A_TickCount
    while (!MENU_WEBVIEW_READY && (A_TickCount - waitStart) < 5000) {
        Sleep(50)
    }
    
    if (!MENU_WEBVIEW_READY) {
        MsgBox("WebView menu failed to initialize")
        return false
    }
    
    ; Store current options for potential submenu navigation
    MENU_WEBVIEW_CURRENT_OPTIONS := options
    MENU_WEBVIEW_RESULT := ""
    
    ; Save active window to restore later
    MENU_WEBVIEW_PREV_WIN := WinExist("A")
    
    ; Calculate position
    MonitorGet(MonitorGetPrimary(), &ml, &mt, &mr, &mb)
    w := 500
    h := 450
    x := ml + (mr - ml - w) // 2
    y := mt + (mb - mt - h) // 3
    
    ; Show window
    MENU_WEBVIEW_GUI.Show("x" . x . " y" . y . " w" . w . " h" . h)
    
    ; Activate and focus window
    Sleep(100)
    hwnd := MENU_WEBVIEW_GUI.Hwnd
    if (hwnd) {
        try WinShow("ahk_id " . hwnd)
        try WinActivate("ahk_id " . hwnd)
    }
    
    try MENU_WEBVIEW_GUI.Control.MoveFocus(0)
    Sleep(150)
    
    ; Build menu data JSON
    menuJson := MenuWebViewBuildJSON(options, parentKeys)

    ; Send data via PostWebMessageAsJson and let the page handle it
    try {
        MENU_WEBVIEW_GUI.Control.PostWebMessageAsJson(menuJson)
    } catch Error as e {
        ToolTip("PostMessage error: " . e.Message, , , 1)
        SetTimer(() => ToolTip(, , , 1), -3000)
    }

    ; Focus the input field
    Sleep(100)
    try MENU_WEBVIEW_GUI.Control.ExecuteScript("focusInput();")
    
    ; Wait for result (blocking)
    waitStart := A_TickCount
    while (MENU_WEBVIEW_RESULT == "" && (A_TickCount - waitStart) < 60000) {
        Sleep(50)
    }
    
    result := MENU_WEBVIEW_RESULT
    MENU_WEBVIEW_RESULT := ""
    
    return result != "" ? result : false
}

MenuWebViewHide() {
    global MENU_WEBVIEW_GUI, MENU_WEBVIEW_PREV_WIN, MENU_WEBVIEW_RESULT
    
    if IsObject(MENU_WEBVIEW_GUI) {
        MENU_WEBVIEW_GUI.Hide()
    }
    
    ; If cancelled, set result to false
    if (MENU_WEBVIEW_RESULT == "") {
        MENU_WEBVIEW_RESULT := "CANCELLED"
    }
    
    ; Restore previous window focus
    if (MENU_WEBVIEW_PREV_WIN != 0) {
        try {
            WinActivate("ahk_id " . MENU_WEBVIEW_PREV_WIN)
        }
        MENU_WEBVIEW_PREV_WIN := 0
    }
}

MenuWebViewMessageHandler(wv, args) {
    global MENU_WEBVIEW_RESULT
    
    try {
        msgJson := args.WebMessageAsJson
        msg := JSON.parse(msgJson)
        
        if (msg.action == "select") {
            MENU_WEBVIEW_RESULT := msg.data
            MenuWebViewHide()
        } else if (msg.action == "cancel") {
            MENU_WEBVIEW_RESULT := "CANCELLED"
            MenuWebViewHide()
        }
    } catch Error as e {
        ; Ignore parsing errors
    }
}

; ========================================
; JSON Helper Functions
; ========================================

MenuWebViewBuildJSON(options, parentKeys) {
    ; Build JSON manually to avoid issues with complex stringify
    json := "{"
    
    ; Add title if present
    if (options.HasProp("title")) {
        json .= '"title":' . MenuWebViewEscapeString(options.title) . ','
    }
    
    ; Add items
    json .= '"items":['
    itemCount := 0
    for _, item in options.items {
        if (item.HasProp("chordHidden") && item.chordHidden)
            continue
        if (itemCount > 0)
            json .= ','
        json .= MenuWebViewBuildItemJSON(item)
        itemCount += 1
    }
    json .= '],'
    
    ; Add parentKeys
    json .= '"parentKeys":['
    for index, key in parentKeys {
        if (index > 1)
            json .= ','
        json .= MenuWebViewEscapeString(key)
    }
    json .= ']'
    
    json .= "}"
    return json
}

MenuWebViewBuildItemJSON(item) {
    json := "{"
    
    ; Ensure key and label exist
    keyStr := item.HasProp("key") ? item.key : ""
    labelStr := item.HasProp("label") ? item.label : ""
    
    json .= '"key":' . MenuWebViewEscapeString(keyStr) . ','
    json .= '"label":' . MenuWebViewEscapeString(labelStr)
    
    ; Add subitems if present
    if (item.HasProp("items") && IsObject(item.items) && item.items.Length > 0) {
        json .= ',"items":['
        itemCount := 0
        for _, subitem in item.items {
            if (subitem.HasProp("chordHidden") && subitem.chordHidden)
                continue
            if (itemCount > 0)
                json .= ','
            json .= MenuWebViewBuildItemJSON(subitem)
            itemCount += 1
        }
        json .= ']'
    }
    
    json .= "}"
    return json
}

MenuWebViewEscapeString(str) {
    ; Escape special characters for JSON
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`t", "\t")
    return '"' . str . '"'
}

class JSON {
    static stringify(obj, indent := "") {
        if IsObject(obj) {
            if (obj is Array) {
                return JSON.stringifyArray(obj, indent)
            } else {
                return JSON.stringifyObject(obj, indent)
            }
        } else if (obj is String) {
            return JSON.stringifyString(obj)
        } else if (obj is Number) {
            return String(obj)
        } else if (obj == true) {
            return "true"
        } else if (obj == false) {
            return "false"
        } else if (obj == "") {
            return '""'
        } else {
            return "null"
        }
    }
    
    static stringifyObject(obj, indent := "") {
        result := "{"
        first := true
        
        for key, value in obj.OwnProps() {
            if (!first)
                result .= ","
            first := false
            result .= JSON.stringifyString(key) . ":" . JSON.stringify(value, indent)
        }
        
        result .= "}"
        return result
    }
    
    static stringifyArray(arr, indent := "") {
        result := "["
        first := true
        
        for index, value in arr {
            if (!first)
                result .= ","
            first := false
            result .= JSON.stringify(value, indent)
        }
        
        result .= "]"
        return result
    }
    
    static stringifyString(str) {
        ; Escape special characters
        str := StrReplace(str, "\", "\\")
        str := StrReplace(str, '"', '\"')
        str := StrReplace(str, "`n", "\n")
        str := StrReplace(str, "`r", "\r")
        str := StrReplace(str, "`t", "\t")
        return '"' . str . '"'
    }
    
    static parse(jsonStr) {
        ; Simple JSON parser - handles objects and arrays
        jsonStr := Trim(jsonStr)
        
        if (SubStr(jsonStr, 1, 1) == "{") {
            return JSON.parseObject(jsonStr)
        } else if (SubStr(jsonStr, 1, 1) == "[") {
            return JSON.parseArray(jsonStr)
        }
        
        return {}
    }
    
    static parseObject(jsonStr) {
        obj := {}
        jsonStr := Trim(SubStr(jsonStr, 2, StrLen(jsonStr) - 2))  ; Remove { }
        
        ; Simple key-value extraction
        pos := 1
        while (pos <= StrLen(jsonStr)) {
            ; Find key
            keyStart := InStr(jsonStr, '"', , pos)
            if (!keyStart)
                break
            keyEnd := InStr(jsonStr, '"', , keyStart + 1)
            key := SubStr(jsonStr, keyStart + 1, keyEnd - keyStart - 1)
            
            ; Find colon
            colonPos := InStr(jsonStr, ":", , keyEnd)
            
            ; Find value
            valueStart := colonPos + 1
            while (SubStr(jsonStr, valueStart, 1) == " ")
                valueStart++
            
            ; Determine value type and extract
            char := SubStr(jsonStr, valueStart, 1)
            if (char == '"') {
                valueEnd := InStr(jsonStr, '"', , valueStart + 1)
                value := SubStr(jsonStr, valueStart + 1, valueEnd - valueStart - 1)
                pos := valueEnd + 1
            } else if (char == "t" || char == "f") {
                if (SubStr(jsonStr, valueStart, 4) == "true") {
                    value := true
                    pos := valueStart + 4
                } else {
                    value := false
                    pos := valueStart + 5
                }
            } else {
                ; Number or other
                valueEnd := InStr(jsonStr, ",", , valueStart)
                if (!valueEnd)
                    valueEnd := StrLen(jsonStr) + 1
                value := SubStr(jsonStr, valueStart, valueEnd - valueStart)
                pos := valueEnd
            }
            
            obj.%key% := value
            
            ; Skip to next key
            pos := InStr(jsonStr, ",", , pos)
            if (!pos)
                break
            pos++
        }
        
        return obj
    }
    
    static parseArray(jsonStr) {
        arr := []
        ; Simple array parsing implementation
        return arr
    }
}
