; ===================================================================
; CHROME HOTKEYS
; ===================================================================

#HotIf WinActive("ahk_exe chrome.exe") and not WinActive(tvWin) and not WinActive(fxWin)
  !b:: {
    Send('^l')
    Sleep(100)
    Send('* ')
  }
  !e:: send('{F8}')
  !a:: {
    Send('!{Left}')
  }
  !s:: {
    Send('!{Right}')
  }
  F8:: {
    setBrowserTitle(lastBrowserTitle, true)
  }
#HotIf