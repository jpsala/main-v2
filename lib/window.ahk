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
    if (!nircmdExe || !FileExist(nircmdExe)) {
        MsgBox("NirCmd no está disponible.`n`nPara usar esta función, instalá NirCmd y configurá su path en config.ini.`n`nPor ahora, se minimizará la ventana normalmente.", "NirCmd no configurado", "Icon! 4096")
        WinMinimize(winTitle)
        return
    }
    try {
        Run(nircmdExe . ' win min title "' . winTitle . '"')
    } catch as err {
        MsgBox("Error ejecutando NirCmd: " . err.Message . "`n`nMinimizando normalmente...", "Error", "Icon! 4096")
        WinMinimize(winTitle)
    }
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
