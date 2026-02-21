#usehook
#SingleInstance Force
CoordMode('Mouse', 'Window')
InstallKeybdHook()
InstallMouseHook()
SendMode("Input")
SetTitleMatchMode(2)
SetWorkingDir(A_ScriptDir)
TraySetIcon(A_ScriptDir . '\icon.ico')

if(A_IsAdmin){
  MsgBox('Better not to run this as Administrator!!')
}

#Include '.\msg.ahk'
#Include '.\functions.ahk'
#Include '.\roa.ahk'
#include '.\init.ahk'
#Include ".\bookmarks.ahk"
#Include ".\menus.ahk"
#Include ".\code.ahk"

#Include ".\hotstrings.ahk"
#Include ".\system.ahk"
#Include ".\chrome.ahk"
#Include ".\ai.ahk"
#Include ".\ai-picker.ahk"
#Include ".\ai-webui.ahk"
#Include ".\hotkeys-global.ahk"
#Include ".\menu.ahk"
#Include ".\menu-webview.ahk"

; Configurar doble click en tray icon para abrir ventana principal
A_TrayMenu.Add("AI Main Window", (*) => AIShowMainWindow())
A_TrayMenu.Default := "AI Main Window"
