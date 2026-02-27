; ===================================================================
; SYSTEM-WIDE HOTKEYS
; ===================================================================

; Add system-wide hotkeys here


; Initialize instance tracking system
OnExit(SaveAppInstanceMap)
LoadAppInstanceMap()

#HotIf IsVolumeEdge()
    WheelDown:: volChange(2)
    WheelUp:: volChange(-2)
#HotIf

IsVolumeEdge() {
    static edgePx := 10
    MouseGetPos(, &y)
    return (y <= edgePx || y >= (A_ScreenHeight - edgePx))
}

; ===================================================================
; CURSOR MOVEMENT
; ===================================================================

; Cursor movement hotkeys (Moved to hotkeys-global.ahk)
; Note: msg() and copyToClipboard() function definitions should remain if used elsewhere.  
; Note: #hotif for Alt cursor navigation was NOT moved as it relies on activeTradeWin and cursorKeysEnabled variables, which might be context-specific. Review if this should be global.
#HotIf not WinActive(activeTradeWin) and cursorKeysEnabled
#HotIf

