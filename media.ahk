; ===================================================================
; MEDIA APPLICATIONS
; ===================================================================

#HotIf WinActive('ahk_exe stremio.exe')
MButton:: Send('{space}')
#HotIf


; Audacity - Select All and Delete
#HotIf WinActive('ahk_exe Audacity.exe')
  !x::{
    send('^a')
    send('{Del}')
    Sleep(1)
    send('{Home}')
  }
#HotIf

; ===================================================================
; DRAWING TOOLS
; ===================================================================

#HotIf WinActive('ahk_exe ppInk.exe')
#^z:: {
  SendWithLevel('^z', 10)
  send('^z')
  send('c')
  msg('undo')
}
#HotIf