; ===================================================================
; DISCORD HOTKEYS
; ===================================================================
#HotIf WinExist('ahk_exe Discord.exe')
!`:: {
    ; Save the current active window
    winId := WinGetID("A")
    ; Activate Discord
    WinActivate("ahk_exe Discord.exe")
    ; Wait for Discord to be active
    WinWaitActive("ahk_exe Discord.exe", , 2)
    ; Send the key (change 'm' to whatever you want)
    Send("^+m")
    Sleep(100)
    ; Restore the previous window
    if winId
        WinActivate("ahk_id " winId)
}
#HotIf


#HotIf WinActive('ahk_exe Discord.exe')
#^e:: {
  msgV1(1)
  KeyWait('Ctrl')
  MouseClick('Right')
}

!t:: RoAWithPattern('chrome-trade', browserWithTradingProfile, 'chrome-trade')

!e:: {
  KeyWait('Alt')
  MouseClick('right')
  Sleep(100)
  send('{up}')
  Sleep(100)
  send('{up}')
  send('{Enter}')
}
!a:: {
  Send('!{Left}')
}
!f:: {
  Send('!{Right}')
}
; !a::
; followLInk(a) {
;   try {
;     msg('working...')
;     KeyWait('Alt')
;     Click('Right')
;     Sleep(50)
;     BlockInput(true)
;     Send('{Up}')
;     Sleep(200)
;     Send('{Up}')
;     Send('{Enter}')
;     Sleep(100)
;     url := A_Clipboard
;     Sleep(100)
;     BlockInput(false)
;     if (!InStr(url, 'http')) {
;       MsgBox('not valid string in clipboard: ' url)
;       WinActivateFast('ahk_exe Discord.exe')
;       return
;     }
;     openInBrowser(url, , , , , , '!0')
;     WinActivateFast('- Discor')
;     if !WinWaitActive('- Discor') {
; ;       MsgBox('ahk_exe Discord.exe error')
;     } catch Error as e {
;     BlockInput(false)
;     MsgBox('Error: ' e)
;   }
; }

^!d:: {
    ; Save the current active window
    winId := WinGetID("A")
    ; Activate Discord
    WinActivate("ahk_exe Discord.exe")
    ; Wait for Discord to be active
    WinWaitActive("ahk_exe Discord.exe", , 2)
    ; Send the key (change 'm' to whatever you want)
    Send("m")
    ; Restore the previous window
    if winId
        WinActivate("ahk_id " winId)
}
#HotIf