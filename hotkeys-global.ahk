    ; ===================================================================
    ; GLOBAL HOTKEYS - MOVED FROM system.ahk
    ; ===================================================================

    ; Disable the Copilot key.
    #+F23::Return

    ; ===================================================================
    ; SETTINGS WINDOW
    ; ===================================================================
;     #,:: {  ; Win+, opens settings (like many apps)
;       ShowSettingsWindow()
;     }

;     #^!g:: {
;       MouseGestureQuickCreateStubWizard()
;     }

;     ^!#+g:: {
;       if (MouseGestureQuickSortConditions())
;         msg("Sorted gesture conditions", {seconds: 2})
;       else
;         msg("Could not sort gesture conditions", {seconds: 2})
;     }

    #HotIf WinActive('ahk_exe code.exe')
    #HotIf

    !F1:: {
      MinimizeToTrayWithNirCmd(WinGetTitle('A'))
    }

    myHotkeyAction(hotkeyStr) {
      Send(hotkeyStr)
      KeyWait("Alt", "T0.8")
      KeyWait("Ctrl", "T0.8")
      KeyWait("LWin", "T0.8")
    }

    ; Register hotkeys #!1 to #!9 (fix closure issue)
    ; Disabled: reserve Win-key combos for menu prefixes.
    ; makeHotkeyAction(hotkeyStr) {
    ;   return (*) => myHotkeyAction(hotkeyStr)
    ; }

    ; Loop 9
    ; {
    ;   hotkeyStr := "#!" A_Index
    ;   hotkeyForLayout := "#!^" A_Index
    ;   Hotkey(hotkeyStr, makeHotkeyAction(hotkeyForLayout))
    ; }


    ; ===================================================================
    ; Figma
    ; ===================================================================
    #hotif WinActive("– Figma -")
    ^c:: send('^+\')
    #hotif

    ; Temporary OpenCode gesture debugging hotkey.
; z:: {
;     KeyWait("z")
;     SendEvent("{Ctrl down}{Alt down}{Shift down}{F12 down}")
;     Sleep(60)
;     SendEvent("{F12 up}{Shift up}{Alt up}{Ctrl up}")
; }
    ; Temporary OpenCode gesture debugging hotkey.
    ; z:: {
    ;   KeyWait('z')
    ;   msg('ok')
    ;   vimMode := SetVimMode(false)

    ; send("{Alt down}{Space}{Alt up}")
    ;   SetVimMode(vimMode)
    ; }

    ; ===================================================================
    ; remote desktop & rustdesk
    ; ===================================================================

    ^F12:: MsgBox(mousePosY())

    ; Function to handle rename operations with optional parameter
    handleRename(useSpecialBackspace := false) {
      found := ImageSearch(&x, &y, 0, 0, 1000, 1000, '.\rename.png')
      if (found == 1) {
        msg('rename')
        MouseClick('Left', x + 40, y + 40)
        sleep(200)
        MouseClick('Left', 1000, 530)
        sleep(100)
        if (useSpecialBackspace) {
          send('{BackSpace 3}-')
        }
        return
      }
      MouseClick('Left', 451, 747)
      sleep(200)
      MouseClick('Left', 1000, 530)
      sleep(100)
      if (useSpecialBackspace) {
        send('{BackSpace 3}-')
      }
    }

    handleClear() {
      mousePos := saveMouse()
      found := ImageSearch(&x, &y, 0, 0, 1000, 1000, '.\clear-all.png')
      if (found == 1) {
        msg('rename')
        MouseClick('Left', x + 40, y + 40)
        sleep(200)
        send('{Enter}')
        restoreMouse(mousePos)
        return
      }
      msg('not found')
      msg('-->', { seconds: 5, x: 40, y: 655 })

      MouseClick('Left', 319, 737)
      sleep(200)
      send('{Enter}')
      restoreMouse(mousePos)
    }
    ; ===================================================================
    ; Remote desktop o strategyquant
    ; ===================================================================

    global arrowGui := false

    #hotif WinActive('ahk_class RustdeskMultiWindow') or WinActive('ahk_exe mstsc.exe') or WinActive('ahk_exe StrategyQuantX_nocheck.exe') or WinActive('ahk_exe StrategyQuantX_ui.exe')
    !r:: handleRename()
    !c:: handleClear()
;     #!r:: handleRename(true)
    #HotIf

    SetTimer(() => checkSQArrowOverlay(), 2000)

    checkSQArrowOverlay() {
      global arrowGui
      SQActive := (WinActive('ahk_class RustdeskMultiWindow') or WinActive('ahk_exe mstsc.exe') or WinActive('ahk_exe StrategyQuantX_nocheck.exe') or WinActive('ahk_exe StrategyQuantX_ui.exe'))
      if (!arrowGui && SQActive) {
        showSQArrowOverlay()
      } else if (arrowGui && !SQActive) {
        arrowGui.Destroy()
        arrowGui := false
      }
    }
    showSQArrowOverlay(x := 21, y := 645, text := "→", duration := 10000) {
      global arrowGui
      ; Minimal arrow overlay with true transparent background
      if (arrowGui) {
        return
      }
      arrowGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +LastFound")
      arrowGui.BackColor := "FF00FF" ; transparent key color
      arrowGui.SetFont("s24", "Segoe UI")
      arrowGui.Add("Text", "c0x00BFFF BackgroundTrans Center 0x200", text)
      arrowGui.Show("x" x " y" y " AutoSize NoActivate")
      WinSetTransColor("FF00FF")
    }

    ; ===================================================================
    ; SYSTEM CONTROLS
    ; ===================================================================

    ; Toggle all hotkeys on/off
    #SuspendExempt
;     #^!s:: {
;       Suspend  ; Ctrl+Alt+S
;       if (A_IsSuspended) {
;         SoundBeep(400, 200)  ; Lower pitch when disabled
;       } else {
;         SoundBeep(1000, 200)  ; Higher pitch when enabled
;       }
;       msg(A_IsSuspended ? 'Suspended' : 'Resumed')
;     }
    #SuspendExempt False

    ; Remap Ctrl+Alt+R to prevent ® character
    ^!r:: Send('^!r')

    #HotIf IsTerminalShiftVPasteActive()
    +Insert:: PasteIntoTerminalWithShiftInsert()
    #HotIf

    IsTerminalShiftVPasteActive() {
      global terminalShiftVPasteEnabled
      return (terminalShiftVPasteEnabled = true || terminalShiftVPasteEnabled = "1") && IsTerminalPasteTarget()
    }

    IsTerminalPasteTarget() {
      try exe := WinGetProcessName("A")
      catch
        return false

      return exe = "WindowsTerminal.exe"
        || exe = "OpenCode.exe"
        || exe = "pwsh.exe"
        || exe = "powershell.exe"
        || exe = "cmd.exe"
        || exe = "conhost.exe"
      }

    PasteIntoTerminalWithShiftInsert() {
      Send("^v")
    }

    ; Reload script
;     #!^r:: {
;       msg('Reloading...')
;       Sleep(200)
;       Pause(false)
;       Reload()
;     }

    ; System shutdown/reboot
;     #^!del:: {
;       val := InputBox('Options:`n`ns:`tShutdown`nr:`tReboot', 'shutdown', 'T10', 'n').value
;       if (val == 's') {
;         Shutdown(1)
;       } else if (val == 'r') { ; Corrected typo: should be 'r' for reboot
;         Shutdown(2)
;       }
;     }

    ; Process Explorer (alternative to Task Manager)
    ; ^+Esc:: Run('C:\tools\procexp.exe')

    ; Kill application (xkill)
;     #!^Backspace:: Run('C:\tools\Win-xKill.exe')

    ; Debug executable (Assumes runLogExe() is defined elsewhere, e.g., system.ahk or functions.ahk)
;     +^#!d:: runLogExe()

    ; ===================================================================
    ; WINDOW MANAGEMENT
    ; ===================================================================

    ; Toggle always on top for active window (Assumes msg() is defined elsewhere)
;     #!t:: {
;       Title_When_On_Top := "! "       ; change title "! " as required
;
;       HWND := WinGetID("A")
;       t := WinGetTitle(HWND)
;
;       ExStyle := WinGetExStyle(HWND)
;       If (ExStyle & 0x8) {                ; 0x8 is WS_EX_TOPMOST
;         WinSetAlwaysOnTop 0, HWND       ; Turn OFF always on top
;         If t != ""
;           WinSetTitle StrReplace(t, Title_When_On_Top), HWND
;         SoundBeep(400, 200)  ; Lower pitch when disabled
;         msg("Always on top: OFF")
;       }
;       Else {
;         WinSetAlwaysOnTop 1, HWND      ; Turn ON always on top
;         If t != ""
          ; add Title_When_On_Top to window title
;           WinSetTitle Title_When_On_Top t, HWND
;         SoundBeep(1000, 200)  ; Higher pitch when enabled
;         msg("Always on top: ON")
;       }
;     }

;     #m::
;     #!down:: {
;       WinMinimize('A')
;     }

    ; Show desktop (Assumes SendWithLevel() is defined elsewhere)
;     ^#!d:: SendWithLevel('#d', 100)

    ; ===================================================================
    ; CLIPBOARD AND TEXT MANAGEMENT
    ; ===================================================================

    ; Paste with simulated typing (Assumes msg() is defined elsewhere)
;     #!^v:: {
      ; Get clipboard content
;       msg({ text: 'Pasting...', seconds: 1000 })
;       text := A_Clipboard
;
      ; Small delay before starting
;       Sleep 500
;
      ; Type each character with a small random delay
;       Loop Parse, text
;       {
;         Send A_LoopField
        ; Random delay between 10-50ms to simulate natural typing
;         Sleep 1
;       }
;
;       return
;     }

    ; ===================================================================
    ; SPECIAL CHARACTERS - ACCENTS AND SPANISH CHARACTERS (HOTSTRINGS)
    ; ===================================================================
    :*:~n::ñ
    :*:``a::á
    :*:``e::é
    :*:``i::í
    :*:``o::ó
    :*:``u::ú
    :*:~+n::Ñ

    ; ===================================================================
    ; LAUNCHER SHORTCUTS
    ; ===================================================================

    ; PowerToys Run (Requires PowerToys Run)
    ; Moved from #, to #!space since #, is used for Settings
;     #!space:: {
;       send('#!{space}') ; PowerToys Run shortcut
;     }

    ; File Explorer (Assumes toggleOrLaunchApp() is defined elsewhere)
;     ^#e:: {
;       toggleOrLaunchApp({
;         winPattern: 'ahk_class CabinetWClass',
;         launchCmd: 'C:\Users\jpsal\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\File Explorer.lnk',
;         windowTitle: '- File Explorer'
;       })
;     }

    ; ===================================================================
    ; MEDIA CONTROLS
    ; ===================================================================

;     #!^Left:: send('{Media_Prev}')
;     #!^Right:: send('{Media_Next}')

    ; Volume control with Alt+Wheel (Assumes volChange() is defined elsewhere)
    ; !WheelDown:: volChange(2)
    ; !WheelUp:: volChange(-2)

    ; Open volume mixer (Windows default)
;     #!+m:: {
;       Run("sndvol")
;       WinWaitActive("ahk_exe sndvol.exe", , 2) ; Wait max 2 seconds
;     }

    ; Open Mixer (Assumes openMixer() is defined elsewhere, likely a custom mixer)
;     #!m:: {
;       openMixer()
;     }


    ^!WheelUp:: brightness('up')
    ^!WheelDown:: brightness('down')

    brightness(direction) {
      /*
          Change brightness using ctrl+alt+wheel, direction is up or down

          Adapter Name: "AMD Radeon(TM) Graphics"
          Short Monitor ID: "SAM707F"
          ---------------------------
          Adapter Name: "NVIDIA GeForce 210 "
          Short Monitor ID: "SAM0D20"
      */
      static waitTime := 400
      if (A_TimeIdle > waitTime) {
        return
      }
      waitTime := 400
      monitor := getMonitorInfo().monitor == 1 ? 'SAM707F' : 'SAM0D20'
      msg('🔆 ' direction, { seconds: waitTime / 1000 })
      cmd := 'C:\tools\ControlMyMonitor.exe /ChangeValue ' . monitor . ' ' . 10 . ' ' . (direction = 'up' ? '10' : '-10')
      run(cmd)
    }
    ; ===================================================================
    ; CURSOR MOVEMENT
    ; ===================================================================

    ; Toggle cursor keys (Assumes msg() is defined elsewhere)
;     #!k:: {
;       global cursorKeysEnabled := !cursorKeysEnabled
;       msg('cursor keys ' . (cursorKeysEnabled ? 'Enabled' : 'Disabled'))
;     }

    ; CapsLock cursor navigation
    CapsLock & k:: Send("{up}")
    CapsLock & j:: Send("{down}")
    CapsLock & h:: Send("{left}")
    CapsLock & l:: Send("{right}")
    CapsLock & `;:: Send("{end}")
    CapsLock & g:: Send("{home}")
    CapsLock & d:: Send("{delete}")
    !d:: Send("{delete}") ; Alt+d also deletes

    ; Alt cursor navigation (when enabled)
    ; Note: activeTradeWin and cursorKeysEnabled need to be defined globally
    #hotif (cursorKeysEnabled ?? false) and ((activeTradeWin ?? "") = "" or not WinActive(activeTradeWin ?? ""))
    !j:: Send("{down}")
    !+j:: Send("{PgDn}")
    !k:: Send("{up}")
    !+k:: Send("{PgUp}")
    !h:: Send("{left}")
    !l:: Send("{right}")
    !+l:: Send("{end}")
    !+h:: Send("{home}")
    #HotIf

    ; Show mouse coordinates and save to clipboard (Assumes msg() and copyToClipboard() are defined elsewhere)
;     #^!LButton:: {
;       MouseGetPos(&X, &Y)
;       msg(X ':' Y, { seconds: 2, X: X + 4, Y: Y + 4 })
;       copyToClipboard(X ', ' Y)
;     }

    ; ===================================================================
    ; KEYBOARD LAYOUT INFO
    ; ===================================================================

    ; Show Keyboard Layout (Assumes getKeyboardLayoutUsOrIntl() and msg() are defined elsewhere)
;     #!^k:: {
      ; Get keyboard layout info from the function
;       layoutType := getKeyboardLayoutUsOrIntl()
;
      ; Create a more detailed message
      ; Get active window handle
;       hwnd := WinActive("A")
;       if (!hwnd)
;         hwnd := WinExist("A")
;
      ; Get the thread ID of the active window
;       threadID := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt", 0)
;
      ; Get the keyboard layout ID for this thread
;       layoutID := DllCall("GetKeyboardLayout", "UInt", threadID, "UInt")
;
      ; Get the system keyboard layout name
;       buf := Buffer(KL_NAMELENGTH := 16)
;       DllCall("GetKeyboardLayoutName", "Ptr", buf.Ptr)
;       klID := StrGet(buf)
;
;       layoutMsg := "Keyboard Layout:`n"
;       layoutMsg .= "- Type: " . layoutType . "`n"
;       layoutMsg .= "- ID: " . Format("0x{:x}", layoutID) . "`n"
;       layoutMsg .= "- Code: " . klID
;
      ; Display layout info
;       msg(layoutMsg, { seconds: 5 })
;     }
