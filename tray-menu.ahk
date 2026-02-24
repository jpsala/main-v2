;===============================================================================
; TRAY MENU
; Custom system tray menu with icons and left-click support
;===============================================================================

SetupTrayMenu() {
    tray := A_TrayMenu
    tray.Delete()  ; Remove default items

    ; --- Main actions ---
    tray.Add("Settings", (*) => ShowSettingsWindow())
    tray.SetIcon("Settings", "shell32.dll", 274)       ; gear/settings

    tray.Add("Reload Script", (*) => Reload())
    tray.SetIcon("Reload Script", "shell32.dll", 239)   ; refresh arrows

    tray.Add("Pause Script", TrayTogglePause)
    tray.SetIcon("Pause Script", "shell32.dll", 145)    ; warning/pause

    tray.Add()  ; ─────────────

    ; --- Toggles ---
    tray.Add("Log Visibility", TrayToggleLog)
    tray.SetIcon("Log Visibility", "shell32.dll", 152)  ; text file
    if (logVisibility)
        tray.Check("Log Visibility")

    tray.Add("Cursor Keys", TrayToggleCursorKeys)
    tray.SetIcon("Cursor Keys", "shell32.dll", 174)     ; keyboard
    if (cursorKeysEnabled)
        tray.Check("Cursor Keys")

    tray.Add()  ; ─────────────

    ; --- Info & tools ---
    tray.Add("Open Log File", (*) => Run(A_ScriptDir . "\log.txt"))
    tray.SetIcon("Open Log File", "shell32.dll", 71)    ; document

    tray.Add("Open Config", (*) => Run("notepad.exe " . A_ScriptDir . "\config.ini"))
    tray.SetIcon("Open Config", "shell32.dll", 70)      ; notepad

    tray.Add("Open Script Folder", (*) => Run(A_ScriptDir))
    tray.SetIcon("Open Script Folder", "shell32.dll", 4) ; folder

    tray.Add()  ; ─────────────

    tray.Add("Exit", (*) => ExitApp())
    tray.SetIcon("Exit", "shell32.dll", 132)            ; red X / close

    ; Default item (bold) on double-click = Settings
    tray.Default := "Settings"

    ; Show menu on left click via message interception
    OnMessage(0x404, TrayIconClick)
}

;-------------------------------------------------------------------------------
; Left-click handler — show tray menu
;-------------------------------------------------------------------------------

TrayIconClick(wParam, lParam, uMsg, hwnd) {
    if (lParam = 0x202) {  ; WM_LBUTTONUP
        SetTimer(() => A_TrayMenu.Show(), -1)
    }
}

;-------------------------------------------------------------------------------
; Tray menu callbacks
;-------------------------------------------------------------------------------

TrayTogglePause(itemName, itemPos, menu) {
    Pause(-1)  ; Toggle pause
    if (A_IsPaused) {
        menu.Check("Pause Script")
    } else {
        menu.Uncheck("Pause Script")
    }
}

TrayToggleLog(itemName, itemPos, menu) {
    global logVisibility := !logVisibility
    if (logVisibility) {
        menu.Check("Log Visibility")
    } else {
        menu.Uncheck("Log Visibility")
    }
    msg("Log visibility: " . (logVisibility ? "ON" : "OFF"))
}

TrayToggleCursorKeys(itemName, itemPos, menu) {
    global cursorKeysEnabled := !cursorKeysEnabled
    if (cursorKeysEnabled) {
        menu.Check("Cursor Keys")
    } else {
        menu.Uncheck("Cursor Keys")
    }
    msg("Cursor keys " . (cursorKeysEnabled ? "Enabled" : "Disabled"))
}

; Initialize tray menu
SetupTrayMenu()
