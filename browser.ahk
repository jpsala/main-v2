; ===================================================================
; BROWSER HOTKEYS
; Chrome and Zen browser specific hotkeys
; ===================================================================

; Zen Browser profiles


; ===================================================================
; ZEN BROWSER SPECIFIC HOTKEYS
; ===================================================================

; #HotIf WinActive('ahk_exe zen.exe')
;   !c:: {
;     ; Wait a moment to ensure all key processing is complete
;     KeyWait("Alt")
;     Sleep(50)

;     ; Get the keyboard layout information using our function
;     keyboardLayoutType := getKeyboardLayoutUsOrIntl()

;     ; Perform action based on layout
;     if (keyboardLayoutType == "INTL") {
;       msg('INTL detected - switching layout', { seconds: 2 })

;       ; Explicitly send Alt+Shift to change keyboard layout
;       ; Using SendLevel to override system handling
;       SendLevel(100)

;       ; Method 1: Using explicit key down/up
;       Send("{Alt Down}{Shift Down}")
;       Sleep(50)
;       Send("{Shift Up}{Alt Up}")

;       ; Wait for layout change to take effect
;       Sleep(100)
;     }
;     Send("^!c")
;   }
;   +WheelDown:: Send('!e')
;   +WheelUp:: Send('!w')
;   +RButton:: {
;     keyWait('Shift')
;     Sleep(100)
;     MouseClick('Left', , , 1, 0)
;     Sleep(100)
;     Send("^{End}") ; Scroll to the bottom on right-click
;   }

;   ^+e:: {
;     send('^#!x')
;   }

;   !a:: {
;     send('{esc}')
;     Sleep(100)
;     send('!a')
;   }
; #HotIf

; ===================================================================
; CHROME BROWSER SPECIFIC HOTKEYS
; ===================================================================

#HotIf WinActive("ahk_exe chrome.exe",) and not WinActive(tvWin) and not WinActive(fxWin)
allIds := '2CMJ58, M2M1T2, W8N2N3, Z6H0V0, Q4R1T4, R2G7W6, F5P3K0, Q0Z1J8, Q3F8N7, D4MP49, F0CH51, C3RV35, W8F1Q0, V0K3Q0, J4Q4Q6, K9NQ29, L5J6C4, X7B0P3, N4N0R0, F6D1B8, N1W9S0, W6B9M1, S5T3R0, Q67SC0, Z6S4T8, T0R1C3, T28HQ0, C9J6W9, X5G9K2, W7K1S0, W0M9B7, P0R2L5, W5S3R0, K6M7Q1, Q4R3K9, R7B9G0, Z8W7G3, Z5P6N7, X9C4L0, X9J0W3, V5Z8W5, Q3WF54, Q3B5D1, G2XX82, K9NQ28, L0SF11, L8Q8S0, W3W3W5, T5L0V0, K9XL04, L1RL53, L1RL54, L1RL55, L8Q8S1, P0R2L6, P0R2L7, P0R2L8, X7B0P4, X7B0P5, N1W9S1, Q4R1T5, Q4R1T6, Q4R1T7, Q0Z1J9, Q3B5D2'


  !1:: paste('J4Q4Q6')
  !2:: paste('2CMJ58,M2M1T2')
  !3:: paste('W8N2N3,Z6H0V0,Q4R1T4')
  !4:: paste('R2G7W6,F5P3K0,Q0Z1J8,J4Q4Q6')
  !5:: paste('K9NQ29,L5J6C4,X7B0P3,N4N0R0,F6D1B8')
  !6:: paste('N1W9S0,W6B9M1,S5T3R0,Q67SC0,Z6S4T8,T0R1C3')
  !7:: paste('T28HQ0,C9J6W9,Q3F8N7,D4MP49,F0CH51,C3RV35,W8F1Q0')
  !8:: paste('V0K3Q0,Q3WF54,Q3B5D1,G2XX82,K9NQ28,L0SF11,L8Q8S0')
  !9:: paste('W3W3W5,T5L0V0,K9XL04,L1RL53,L1RL54,L1RL55,L8Q8S1,P0R2L6,P0R2L7')
  !0:: paste('P0R2L8,X7B0P4,X7B0P5,N1W9S1,Q4R1T5,Q4R1T6,Q4R1T7,Q0Z1J9,Q3B5D2,W7K1S0')
  !b:: {
    randomId := getRandomId()
    if (randomId != '') {
      paste(randomId)
    } else {
      msg('No more IDs available!', { type: 'error' })
    }
  }

  !e:: send('{F8}')
  !a:: {
    Send('!{Left}')
  }
  ; !s:: {
  ;   Send('!{Right}')
  ; }
  F8:: {
    setBrowserTitle(lastBrowserTitle, true)
  }
#HotIf

; Paste function: saves clipboard, pastes text, restores clipboard
paste(text) {
  msg('Pasting: ' . text, { seconds: 2 })
  savedClipboard := A_Clipboard
  A_Clipboard := text
  if(not ClipWait(5)) {
    msg('Clipboard not ready!', { type: 'error' })
    return
  }
  Send('^v')
  Sleep(100)
  A_Clipboard := savedClipboard
}

; Get random unused ID from allIds
getRandomId() {
  static usedIds := []
  static availableIds := []
  
  ; Initialize available IDs on first call
  if (availableIds.Length == 0) {
    allIdsArray := StrSplit(allIds, ', ')
    for id in allIdsArray {
      availableIds.Push(Trim(id))
    }
  }
  
  ; Check if all IDs have been used
  if (availableIds.Length == 0) {
    return ''  ; No more IDs available
  }
  
  ; Get random index
  randomIndex := Random(1, availableIds.Length)
  randomId := availableIds[randomIndex]
  
  ; Move ID from available to used
  availableIds.RemoveAt(randomIndex)
  usedIds.Push(randomId)
  
  return randomId
}

