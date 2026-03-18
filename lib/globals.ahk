;===============================================================================
; GLOBAL VARIABLES
; Centralized global variable declarations for the application
;===============================================================================

;-------------------------------------------------------------------------------
; Application State
;-------------------------------------------------------------------------------
global storedVolume := ""
global mouseX := 0
global mouseY := 0
global mode := 0
global monitorInfo := {x: 0, y: 0, width: 0, height: 0}

;-------------------------------------------------------------------------------
; Window References
;-------------------------------------------------------------------------------
global activeTradeWin := 'xxxx'
global tvWin := ''
global fxWin := ''
global lastBrowserTitle := ""
global winSaved := false  ; Used by taskbar hover functionality

;-------------------------------------------------------------------------------
; Timer & Time Tracking
;-------------------------------------------------------------------------------
global time := ''
global TimeGui1 := 0
global TimeGui2 := 0

;-------------------------------------------------------------------------------
; Device Detection Flags (loaded from [machines] in config.ini)
;-------------------------------------------------------------------------------
global deviceSection := LoadDeviceSection()
global isNotebook := deviceSection == "notebook"
global isRemote := deviceSection == "remote"
global isGordos := deviceSection == "gordos"
global isWork := deviceSection == "work"
global isCarnival := deviceSection == "carnival"

;-------------------------------------------------------------------------------
; Feature Flags & Toggle States
;-------------------------------------------------------------------------------
global logVisibility := false
global toggleCodeDebug := false
global toggleChromeDebug := false
global toggleObsidanDebug := false
global cursorKeysEnabled := false

;-------------------------------------------------------------------------------
; Mouse & Window Tracking
;-------------------------------------------------------------------------------
global windowUnderMouseID := 0
global winProcessNameUnderMouse := ''
global winTitleUnderMouse := ''

;-------------------------------------------------------------------------------
; Miscellaneous State
;-------------------------------------------------------------------------------
global activeGroup := ""
global altProfile := ""
global initStarted := true
global savedID := ""
global saveVol := ""

;-------------------------------------------------------------------------------
; Machine Detection Functions
;-------------------------------------------------------------------------------

LoadDeviceSection() {
  section := IniRead("config.ini", "machines",, "")
  if (section = "") {
    SeedDefaultMachines()
    section := IniRead("config.ini", "machines",, "")
  }
  lines := StrSplit(section, "`n")
  for line in lines {
    parts := StrSplit(line, "=")
    if (parts.Length >= 2 && parts[1] = A_ComputerName)
      return parts[2]
  }
  return "desktop"
}

SeedDefaultMachines() {
  defaults := Map("ZENBOOK", "notebook", "CIDEV06", "remote", "gordos", "gordos", "AR-IT31927", "work", "avdp-1310", "carnival")
  for name, sect in defaults
    IniWrite(sect, "config.ini", "machines", name)
}

GetAllMachines() {
  section := IniRead("config.ini", "machines",, "")
  if (section = "") {
    SeedDefaultMachines()
    section := IniRead("config.ini", "machines",, "")
  }
  result := []
  lines := StrSplit(section, "`n")
  for line in lines {
    parts := StrSplit(line, "=")
    if (parts.Length >= 2)
      result.Push(Map("name", parts[1], "section", parts[2], "current", parts[1] = A_ComputerName))
  }
  return result
}

AddMachine(name, sect) {
  IniWrite(sect, "config.ini", "machines", name)
}

RemoveMachine(name) {
  IniDelete("config.ini", "machines", name)
}
