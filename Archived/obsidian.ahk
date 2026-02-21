; ===================================================================
; OBSIDIAN FUNCTIONALITY
; ===================================================================

; Global variables for Obsidian
global toggleObsidanDebug := false

; ===================================================================
; OBSIDIAN HOTKEYS
; ===================================================================
#HotIf WinActive("ahk_exe Obsidian.exe") and WinActive('draw')
!f::7
!a::a
#HotIf

#HotIf WinActive("ahk_exe Obsidian.exe")
::.cbt:: {
  send('`` `` `` ')
  Sleep(100)
  send(' typescript{Enter}')
}

::.cbj:: {
  send('`` `` `` ')
  Sleep(100)
  send(' javascript{Enter}')
}

::.cbb:: {
  send('`` `` `` ')
  Sleep(100)
  send(' Python{Enter}')
}

::.cb:: {
  send('`` `` `` ')
  Sleep(100)
  send('{Enter}')
}


F1::
toggleDebugForObsidan(hk)
{
  global toggleObsidanDebug
  toggleObsidanDebug := !toggleObsidanDebug
  if (toggleObsidanDebug) {
    msgV1('Deb', 100000, 20, 1, 1)
  } else {
    ToolTip(, , , 20)
  }
}

^+e:: {
  send('+^#e')
}
#HotIf

; Obsidian debug mode hotkeys
#HotIf (toggleObsidanDebug) and WinActive("ahk_exe Obsidian.exe")
s:: Send('p')
f:: Send('^z')
e:: Send('o')
q:: Send('1')
z:: Send('^z')
d:: Send('{Delete}')
F1:: toggleDebugForObsidan(1)
#HotIf

; ===================================================================
; OBSIDIAN FUNCTIONS
; ===================================================================

; Add any Obsidian-specific functions here
