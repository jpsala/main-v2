; ===================================================================
; SYSTEM-WIDE HOTKEYS
; ===================================================================

; Add system-wide hotkeys here


; Initialize instance tracking system
OnExit(SaveAppInstanceMap)
LoadAppInstanceMap()

#HotIf IsMouseAtMonitorTopOrBottomEdge()
    WheelDown:: volChange(2)
    WheelUp:: volChange(-2)
    ^WheelDown:: brightness("down")
    ^WheelUp:: brightness("up")
#HotIf

IsMouseAtMonitorTopOrBottomEdge() {
    static edgePx := 10
    mouseCoordMode := CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    CoordMode("Mouse", mouseCoordMode)

    loop MonitorGetCount() {
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        if IsPointAtMonitorTopOrBottomEdge(
            mouseX,
            mouseY,
            left,
            top,
            right,
            bottom,
            edgePx
        )
            return true
    }

    return false
}

IsPointAtMonitorTopOrBottomEdge(x, y, left, top, right, bottom, edgePx := 10) {
    return (
        x >= left
        && x < right
        && y >= top
        && y < bottom
        && (y < top + edgePx || y >= bottom - edgePx)
    )
}

; ===================================================================
; CURSOR MOVEMENT
; ===================================================================

; Cursor movement hotkeys (Moved to hotkeys-global.ahk)
; Note: msg() and copyToClipboard() function definitions should remain if used elsewhere.  
; Note: #hotif for Alt cursor navigation was NOT moved as it relies on activeTradeWin and cursorKeysEnabled variables, which might be context-specific. Review if this should be global.
#HotIf not WinActive(activeTradeWin) and cursorKeysEnabled
#HotIf

