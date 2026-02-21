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
; Device Detection Flags
;-------------------------------------------------------------------------------
global isNotebook := A_ComputerName == 'ZENBOOK'
global isRemote := A_ComputerName == 'CIDEV06'
global isGordos := A_ComputerName == 'gordos'
global isWork := A_ComputerName == 'AR-IT31927'
global isCarnival := A_ComputerName == 'avdp-1310'

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
; Device Section Configuration
;-------------------------------------------------------------------------------
global deviceSection := isGordos ? "gordos" : (isNotebook ? "notebook" : (!isWork ? "desktop" : "work"))
global deviceSection := isCarnival ? "carnival" : deviceSection
