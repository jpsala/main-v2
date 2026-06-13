;===============================================================================
; WEBVIEW WINDOW STATE
; Persists WebViewGui size and/or position in config.ini.
;===============================================================================

global WEBVIEW_WINDOW_STATE := Map()
global WEBVIEW_WINDOW_STATE_MESSAGE_REGISTERED := false

WebViewWindowStateAttach(gui, stateKey, options := false) {
    global WEBVIEW_WINDOW_STATE, WEBVIEW_WINDOW_STATE_MESSAGE_REGISTERED

    if (!gui || !stateKey)
        return false

    if (!IsObject(options))
        options := {}

    state := {
        key: stateKey,
        saveSize: !options.HasOwnProp("saveSize") || options.saveSize,
        savePosition: !options.HasOwnProp("savePosition") || options.savePosition,
        defaultWidth: options.HasOwnProp("defaultWidth") ? options.defaultWidth : 640,
        defaultHeight: options.HasOwnProp("defaultHeight") ? options.defaultHeight : 480,
        minWidth: options.HasOwnProp("minWidth") ? options.minWidth : 320,
        minHeight: options.HasOwnProp("minHeight") ? options.minHeight : 240,
        pending: false
    }

    WEBVIEW_WINDOW_STATE[gui.Hwnd] := state

    if (!WEBVIEW_WINDOW_STATE_MESSAGE_REGISTERED) {
        OnMessage(0x0047, WebViewWindowStateWindowPosChanged) ; WM_WINDOWPOSCHANGED
        WEBVIEW_WINDOW_STATE_MESSAGE_REGISTERED := true
    }

    gui.OnEvent("Close", (*) => WebViewWindowStateSave(gui.Hwnd))
    return true
}

WebViewWindowStateRestoreOrCenter(gui, stateKey, defaultWidth := 640, defaultHeight := 480, saveSize := true, savePosition := true) {
    section := WebViewWindowStateSection(stateKey)
    width := defaultWidth
    height := defaultHeight
    x := ""
    y := ""

    if (saveSize) {
        savedWidth := Number(IniRead("config.ini", section, "w", defaultWidth))
        savedHeight := Number(IniRead("config.ini", section, "h", defaultHeight))
        width := Max(savedWidth, 320)
        height := Max(savedHeight, 240)
    }

    if (savePosition) {
        savedX := IniRead("config.ini", section, "x", "")
        savedY := IniRead("config.ini", section, "y", "")
        if (savedX != "" && savedY != "") {
            x := Number(savedX)
            y := Number(savedY)
        }
    }

    if (x = "" || y = "" || !WebViewWindowStateIsVisibleOnMonitor(x, y, width, height)) {
        WebViewWindowStateCenteredPosition(width, height, &x, &y)
    }

    gui.Move(x, y, width, height)
    WebViewWindowStateAttach(gui, stateKey, {
        saveSize: saveSize,
        savePosition: savePosition,
        defaultWidth: defaultWidth,
        defaultHeight: defaultHeight
    })
    return true
}

WebViewWindowStateWindowPosChanged(wParam, lParam, msg, hwnd) {
    global WEBVIEW_WINDOW_STATE
    if (!WEBVIEW_WINDOW_STATE.Has(hwnd))
        return

    state := WEBVIEW_WINDOW_STATE[hwnd]
    if (state.pending)
        return

    state.pending := true
    WEBVIEW_WINDOW_STATE[hwnd] := state
    SetTimer(WebViewWindowStateFlush.Bind(hwnd), -350)
}

WebViewWindowStateFlush(hwnd) {
    global WEBVIEW_WINDOW_STATE
    if (!WEBVIEW_WINDOW_STATE.Has(hwnd))
        return

    state := WEBVIEW_WINDOW_STATE[hwnd]
    state.pending := false
    WEBVIEW_WINDOW_STATE[hwnd] := state
    WebViewWindowStateSave(hwnd)
}

WebViewWindowStateSave(hwnd) {
    global WEBVIEW_WINDOW_STATE
    if (!WEBVIEW_WINDOW_STATE.Has(hwnd) || !WinExist("ahk_id " . hwnd))
        return false

    if (WinGetMinMax("ahk_id " . hwnd) != 0)
        return false

    state := WEBVIEW_WINDOW_STATE[hwnd]
    try WinGetPos(&x, &y, &w, &h, "ahk_id " . hwnd)
    catch
        return false

    if (w < state.minWidth || h < state.minHeight)
        return false

    section := WebViewWindowStateSection(state.key)
    if (state.savePosition) {
        IniWrite(x, "config.ini", section, "x")
        IniWrite(y, "config.ini", section, "y")
    }
    if (state.saveSize) {
        IniWrite(w, "config.ini", section, "w")
        IniWrite(h, "config.ini", section, "h")
    }
    return true
}

WebViewWindowStateForget(hwnd) {
    global WEBVIEW_WINDOW_STATE
    if (WEBVIEW_WINDOW_STATE.Has(hwnd))
        WEBVIEW_WINDOW_STATE.Delete(hwnd)
}

WebViewWindowStateSection(stateKey) {
    return "webviewWindowState." . stateKey
}

WebViewWindowStateCenteredPosition(width, height, &x, &y) {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    monL := 0, monT := 0, monR := A_ScreenWidth, monB := A_ScreenHeight

    loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &left, &top, &right, &bottom)
        if (mx >= left && mx < right && my >= top && my < bottom) {
            monL := left, monT := top, monR := right, monB := bottom
            break
        }
    }

    x := monL + (monR - monL - width) // 2
    y := monT + (monB - monT - height) // 2
}

WebViewWindowStateIsVisibleOnMonitor(x, y, width, height) {
    centerX := x + width // 2
    centerY := y + height // 2

    loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &left, &top, &right, &bottom)
        if (centerX >= left && centerX < right && centerY >= top && centerY < bottom)
            return true
    }

    return false
}
