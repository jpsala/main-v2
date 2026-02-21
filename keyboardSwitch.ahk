; ===================================================================
; KEYBOARD LAYOUT AUTO-SWITCHING
; ===================================================================

; Configuration - adjust these values as needed
global keyboardLayoutTracking := {
    intlStartTime: 0,       ; When INTL layout was first detected
    isTracking: false,      ; Whether we're tracking an INTL session
    checkInterval: 1000,    ; How often to check for INTL layout every 10 seconds
    timeToSwitch: 6 * 10000,     ; Switch to US after 60 seconds
    enabled: true,          ; Whether auto-switching is enabled
    showNotification: true  ; Show notification when switching layouts
}

; Timer function to monitor and auto-switch keyboard layouts
monitorKeyboardLayout() {
    if (!keyboardLayoutTracking.Enabled)
        return

    currentLayout := getKeyboardLayoutUsOrIntl()

    ; If INTL layout is active
    if (currentLayout == "INTL") {
        ; Start tracking if we're not already
        if (!keyboardLayoutTracking.isTracking) {
            keyboardLayoutTracking.intlStartTime := A_TickCount
            keyboardLayoutTracking.isTracking := true
            soundHigh('30%')

        } else {
            ; Check if we've been in INTL layout for too long
            timeInIntl := A_TickCount - keyboardLayoutTracking.intlStartTime

            if (timeInIntl >= keyboardLayoutTracking.timeToSwitch) {
                ; Switch to US layout
                soundHigh('30%')
                BlockInput(true)
                try {
                    Send("{Alt Down}{Shift Down}")
                    Sleep(50)
                    Send("{Shift Up}{Alt Up}")
                } finally {
                    BlockInput(false)
                }
                SendLevel(0)

                ; Reset tracking
                keyboardLayoutTracking.isTracking := false

                ; Verify the switch happened
                Sleep(200)
                if (getKeyboardLayoutUsOrIntl() == "INTL") {
                    ; Try again with low-level API calls
                    BlockInput(true)
                    try {
                        DllCall("keybd_event", "int", 0x12, "int", 0, "int", 0, "int", 0)  ; ALT down
                        DllCall("keybd_event", "int", 0x10, "int", 0, "int", 0, "int", 0)  ; SHIFT down
                        Sleep(50)
                        DllCall("keybd_event", "int", 0x10, "int", 0, "int", 2, "int", 0)  ; SHIFT up
                        DllCall("keybd_event", "int", 0x12, "int", 0, "int", 2, "int", 0)  ; ALT up
                    } finally {
                        BlockInput(false)
                    }
                }
            }
        }
    } else {
        ; Reset tracking if we're in US layout
        if (keyboardLayoutTracking.isTracking) {
            keyboardLayoutTracking.isTracking := false
            msg("Stopped tracking INTL - layout changed to US", { seconds: 2 })
        }
    }
}

; Set up timer to check keyboard layout
;SetTimer(monitorKeyboardLayout, keyboardLayoutTracking.checkInterval)

; Hotkey to toggle auto-switching
#!^+k:: {
    keyboardLayoutTracking.Enabled := !keyboardLayoutTracking.Enabled
    msg("Keyboard auto-switching " . (keyboardLayoutTracking.Enabled ? "enabled" : "disabled"), { seconds: 2 })
    log("Keyboard auto-switching " . (keyboardLayoutTracking.Enabled ? "enabled" : "disabled"))
}