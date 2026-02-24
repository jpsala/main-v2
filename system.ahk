; ===================================================================
; SYSTEM-WIDE HOTKEYS
; ===================================================================

; Add system-wide hotkeys here


; Initialize instance tracking system
OnExit(SaveAppInstanceMap)
LoadAppInstanceMap()

#hotif monitorInfo.y < 10 or (monitorInfo.y > (monitorInfo.bottom - 10))
    WheelDown:: volChange(2)
    WheelUp:: volChange(-2)
#hotif

; ===================================================================
; CURSOR MOVEMENT
; ===================================================================

; Cursor movement hotkeys (Moved to hotkeys-global.ahk)
; Note: msg() and copyToClipboard() function definitions should remain if used elsewhere.  
; Note: #hotif for Alt cursor navigation was NOT moved as it relies on activeTradeWin and cursorKeysEnabled variables, which might be context-specific. Review if this should be global.
#hotif not WinActive(activeTradeWin) and cursorKeysEnabled
#HotIf

