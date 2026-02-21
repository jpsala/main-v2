; ===================================================================
; DATABASE TOOLS HOTKEYS
; ===================================================================

#HotIf WinActive('ahk_exe dbeaver.exe')
:*:.like:: {
  send('like `'%%`'{space}')
  Sleep(100)
  send('`'')
  Sleep(300)
  send('{left 2}')
}

#b:: {
  send('+{F10}')
  Sleep(100)
  send('v')
  Sleep(100)
  send('r')
}
#HotIf