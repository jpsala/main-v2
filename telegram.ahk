; ===================================================================
; TELEGRAM HOTKEYS
; ===================================================================

#HotIf WinActive('ahk_exe Telegram.exe')
!a:: {
  try {
    msgV1('working...')
    MonitorGet(0, &Left, , &Right)
    MonitorGet(1, , , &Width)
    KeyWait('Alt')
    MouseClick('Right') ; Simulate right mouse button click
    Sleep(50)
    send('{Down 3}')
    Sleep(50)
    send('{Enter}')
    ClipWait(1)
    url := A_Clipboard
    if (!InStr(url, 'http')) {
      BlockInput(false)
      MsgBox('not valid string in clipboard: ' url)
      WinActivateFast('ahk_exe telegram.exe')
      return
    }
    RoAWithPattern('chrome-trade', browserWithTradingProfile, 'chrome-trade')
    if (WinWaitActive('chrome-trade', , 3)) {
      WinMove(Right, 0)
      WinMaximize('chrome-trade')
      Send('^t')
      Sleep(100)
      Send('^l')
      Sleep(100)
      Send(url)
      Sleep(200)
      Send('{Enter}')
      Sleep(200)
      WinActivateFast('- Discor')
      if !WinWaitActive('- Discor') {
        MsgBox('ahk_exe Discord.exe error')
      }
      msgV1('ready')
    }
    BlockInput(false)
  } catch Error as e {
    BlockInput(false)
    MsgBox('Error: ' e)
  }
}
#HotIf