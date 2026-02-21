#usehook
#SingleInstance Force
CoordMode('Mouse', 'Window')
InstallKeybdHook()
InstallMouseHook()
SendMode("Input")
SetTitleMatchMode(2)
SetWorkingDir(A_ScriptDir)

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
#Include ".\browser.ahk"
#Include ".\keyboardSwitch.ahk"  ; New keyboard layout auto-switching functionality
#Include ".\hotstrings.ahk"
#Include ".\system.ahk"
#Include ".\chrome.ahk"
#Include ".\obsidian.ahk"
#Include ".\discord.ahk"
#Include ".\terminal.ahk"
#Include ".\media.ahk"
#Include ".\ai.ahk"
#Include ".\ai-picker.ahk"
#Include ".\ai-webui.ahk"
#Include ".\hotkeys-global.ahk"
#Include ".\menu.ahk"
