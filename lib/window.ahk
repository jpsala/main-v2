;===============================================================================
; WINDOW MANAGEMENT MODULE
; Window manipulation, activation, and browser-specific operations
;===============================================================================

;===============================================================================
; WINDOW ACTIVATION
;===============================================================================

WinActivateFast(WinTitle, WinText := '', ExcludeTitle := '', ExcludeText := '', delay := 0) {
    wd := SetWinDelay(delay)
    WinActivate(WinTitle, WinText, ExcludeTitle, ExcludeText)
    SetWinDelay(wd)
}

MinimizeToTrayWithNirCmd(winTitle) {
    nircmdExe := GetCachedConfig("desktop", "nircmd_exe", "")
    if (!nircmdExe) {
        msgV1("Error: Missing nircmd path in config.ini", 3)
        return
    }
    Run(nircmdExe . ' win min title "' . winTitle . '"')
}

;===============================================================================
; BROWSER MANAGEMENT
;===============================================================================

setBrowserTitle(title?, dontExit := false) {
    clipSaved := A_Clipboard
    global lastBrowserTitle
    if (IsSet(title)) {
        lastBrowserTitle := title
    }
    msg('setBrowserTitle')
    Send('{esc}{F10}')
    Sleep(100)
    Send('{Enter}')
    Sleep(100)
    Send('l')
    Sleep(1)
    Send('w')
    if (IsSet(title)) {
        Sleep(100)
        Send(title)
        send('{Enter}')
    } else if (IsSet(lastBrowserTitle)) {
        A_Clipboard := ''
        Send('^a')
        Sleep(50)
        Send('^c')
        Sleep(50)
        ClipWait(0.5)
        if (A_Clipboard == '') {
            soundOk()
            Send(lastBrowserTitle)
        }
    }
    A_Clipboard := clipSaved
    soundOk(1)
    msg('done setBrowserTitle')
    if (!dontExit)
        send('{esc}')
}
