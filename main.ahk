#usehook
#SingleInstance Force
CoordMode('Mouse', 'Window')
InstallKeybdHook()
InstallMouseHook()
SendMode("Input")
SetTitleMatchMode(2)
SetWorkingDir(A_ScriptDir)
TraySetIcon(A_ScriptDir . '\ui\icons\main-tray.png')

if(A_IsAdmin){
  MsgBox('Better not to run this as Administrator!!')
}

; Load modular library components
#Include 'lib\globals.ahk'
#Include 'lib\path-validator.ahk'
#Include 'lib\chord-hotkeys.ahk'
#Include 'lib\webview-window-state.ahk'
#Include 'lib\audio.ahk'
#Include 'lib\window.ahk'
#Include 'lib\screen.ahk'
#Include 'lib\clipboard.ahk'
#Include 'lib\logging.ahk'
#Include 'lib\utils.ahk'
#Include 'lib\json.ahk'

; Load core modules
#Include '.\msg.ahk'
#Include '.\functions.ahk'
#Include '.\roa.ahk'
#include '.\init.ahk'
#Include ".\bookmarks.ahk"
#Include ".\menu-actions.ahk"
onceADay()
#Include ".\copy-q.ahk"
#Include ".\menus.ahk"
#Include ".\menus-whichkey.ahk"
#Include ".\code.ahk"
#Include ".\settings-window.ahk"
#Include ".\web-clipboard-host.ahk"
#Include ".\raw-project.ahk"
#Include ".\calendar-window.ahk"
#Include ".\tray-menu.ahk"

#Include ".\hotstrings.ahk"
#Include ".\system.ahk"
#Include ".\chrome.ahk"
#Include ".\mouse-gestures.ahk"
#Include ".\mouse-gestures-wizard.ahk"
#Include ".\mouse-gestures-conditions.ahk"
#Include ".\hotkeys-global.ahk"
#Include ".\chord-examples.ahk"
#Include ".\menu.ahk"
#Include ".\menu-webview.ahk"

InitMenusWhichKey()
InitVSCodeControllerChords()
InitMouseGestures()
CalendarStartReminderTimer()
