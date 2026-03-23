#usehook
#SingleInstance Force
CoordMode('Mouse', 'Window')
InstallKeybdHook()
InstallMouseHook()
SendMode("Input")
SetTitleMatchMode(2)
SetWorkingDir(A_ScriptDir)
TraySetIcon(A_ScriptDir . '\main.ico')

if(A_IsAdmin){
  MsgBox('Better not to run this as Administrator!!')
}

; Load modular library components
#Include 'lib\globals.ahk'
#Include 'lib\path-validator.ahk'
#Include 'lib\chord-hotkeys.ahk'
#Include 'lib\audio.ahk'
#Include 'lib\window.ahk'
#Include 'lib\screen.ahk'
#Include 'lib\clipboard.ahk'
#Include 'lib\logging.ahk'
#Include 'lib\utils.ahk'

; Load core modules
#Include '.\msg.ahk'
#Include '.\functions.ahk'
#Include '.\roa.ahk'
#include '.\init.ahk'
#Include ".\bookmarks.ahk"
#Include ".\menus.ahk"
#Include ".\menus-whichkey.ahk"
#Include ".\code.ahk"
#Include ".\settings-window.ahk"
#Include ".\tray-menu.ahk"

#Include ".\hotstrings.ahk"
#Include ".\system.ahk"
#Include ".\chrome.ahk"
#Include ".\hotkeys-global.ahk"
#Include ".\vim-mode.ahk"
#Include ".\vim-keymap.ahk"
#Include ".\vim-keymap-code.ahk"
#Include ".\chord-examples.ahk"
#Include ".\menu.ahk"
#Include ".\menu-webview.ahk"

InitMenusWhichKey()
