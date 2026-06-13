;===============================================================================
; TRAY MENU
; Custom system tray menu with icons and left-click support
;===============================================================================

SetupTrayMenu() {
    tray := A_TrayMenu
    tray.Delete()  ; Remove default items

    ; --- Main actions ---
    tray.Add("Settings", (*) => ShowSettingsWindow())
    tray.SetIcon("Settings", RawProjectIcon("settings"),, 0)

    tray.Add("Calendar", (*) => ShowCalendarWindow())
    tray.SetIcon("Calendar", RawProjectIcon("dashboard"),, 0)

    tray.Add("Reload Script", (*) => Reload())
    tray.SetIcon("Reload Script", RawProjectIcon("restart"),, 0)

    tray.Add("Pause Script", TrayTogglePause)
    tray.SetIcon("Pause Script", RawProjectIcon("pause"),, 0)

    tray.Add()  ; ─────────────

    ; --- Toggles ---
    tray.Add("Log Visibility", TrayToggleLog)
    tray.SetIcon("Log Visibility", RawProjectIcon("logs"),, 0)
    if (logVisibility)
        tray.Check("Log Visibility")

    tray.Add("Cursor Keys", TrayToggleCursorKeys)
    tray.SetIcon("Cursor Keys", RawProjectIcon("keyboard"),, 0)
    if (cursorKeysEnabled)
        tray.Check("Cursor Keys")

    tray.Add("Vim Mode ON", TrayEnableVimMode)
    tray.SetIcon("Vim Mode ON", RawProjectIcon("vim-on"),, 0)

    tray.Add("Vim Mode OFF", TrayDisableVimMode)
    tray.SetIcon("Vim Mode OFF", RawProjectIcon("vim-off"),, 0)

    tray.Add()  ; ─────────────

    ; --- Info & tools ---
    tray.Add("Open Log File", (*) => Run(A_ScriptDir . "\log.txt"))
    tray.SetIcon("Open Log File", RawProjectIcon("logs"),, 0)

    tray.Add("Open Config", (*) => Run("notepad.exe " . A_ScriptDir . "\config.ini"))
    tray.SetIcon("Open Config", RawProjectIcon("config"),, 0)

    tray.Add("Open Script Folder", (*) => Run(A_ScriptDir))
    tray.SetIcon("Open Script Folder", RawProjectIcon("folder"),, 0)

    tray.Add("Open in VS Code", (*) => TrayOpenRepoInVSCode())
    tray.SetIcon("Open in VS Code", RawProjectIcon("code"),, 0)

    tray.Add()  ; ─────────────

    ; --- WhatsApp project ---
    rawMenu := Menu()
    rawMenu.Add("Open Client", (*) => ShowRawClientWindow())
    rawMenu.SetIcon("Open Client", RawProjectIcon("whatsapp-" . RawProjectGetAccount()),, 0)
    rawMenu.Add("Status Dashboard", (*) => ShowRawProjectWindow())
    rawMenu.SetIcon("Status Dashboard", RawProjectIcon("dashboard"),, 0)
    rawMenu.Add("Start Watcher", (*) => (RawProjectStartWatcher(), msg("RAW/" . RawProjectGetLabel() . " watcher start enviado", { seconds: 2 })))
    rawMenu.SetIcon("Start Watcher", RawProjectIcon("start"),, 0)
    rawMenu.Add("Stop Watcher", (*) => (RawProjectStopWatcher(), msg("RAW/" . RawProjectGetLabel() . " watcher detenido", { seconds: 2 })))
    rawMenu.SetIcon("Stop Watcher", RawProjectIcon("stop"),, 0)
    rawMenu.Add("Restart Watcher", (*) => (RawProjectRestartWatcher(), msg("RAW/" . RawProjectGetLabel() . " watcher reiniciado", { seconds: 2 })))
    rawMenu.SetIcon("Restart Watcher", RawProjectIcon("restart"),, 0)
    rawMenu.Add()
    rawMenu.Add("Cuenta JP", (*) => (RawProjectSetAccount("jp"), SetupTrayMenu(), msg("Cuenta JP activada", { seconds: 2 })))
    rawMenu.SetIcon("Cuenta JP", RawProjectIcon("whatsapp-jp"),, 0)
    if (RawProjectGetAccount() = "jp")
        rawMenu.Check("Cuenta JP")
    rawMenu.Add("Cuenta Ro", (*) => (RawProjectSetAccount("ro"), SetupTrayMenu(), msg("Cuenta Ro activada", { seconds: 2 })))
    rawMenu.SetIcon("Cuenta Ro", RawProjectIcon("whatsapp-ro"),, 0)
    if (RawProjectGetAccount() = "ro")
        rawMenu.Check("Cuenta Ro")
    rawMenu.Add()
    rawMenu.Add("Open Assistant App", (*) => RawProjectOpenDashboard())
    rawMenu.SetIcon("Open Assistant App", RawProjectIcon("app"),, 0)
    rawMenu.Add("Open Logs Folder", (*) => RawProjectOpenLogsFolder())
    rawMenu.SetIcon("Open Logs Folder", RawProjectIcon("logs"),, 0)
    rawMenu.Add("Open Project Folder", (*) => RawProjectOpenProjectFolder())
    rawMenu.SetIcon("Open Project Folder", RawProjectIcon("folder"),, 0)
    rawMenu.Add()
    rawMenu.Add("Status in Terminal", (*) => RawProjectOpenStatusTerminal())
    rawMenu.SetIcon("Status in Terminal", RawProjectIcon("terminal"),, 0)
    rawMenu.Add("Run Config Check", (*) => RawProjectRunVisibleCommand("npm --prefix `"assistant`" run check", "RAW config check"))
    rawMenu.SetIcon("Run Config Check", RawProjectIcon("check"),, 0)

    tray.Add("WhatsApp", rawMenu)
    tray.SetIcon("WhatsApp", RawProjectIcon("whatsapp-" . RawProjectGetAccount()),, 0)

    tray.Add()  ; ─────────────

    tray.Add("Exit", (*) => ExitApp())
    tray.SetIcon("Exit", RawProjectIcon("exit"),, 0)

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

TrayEnableVimMode(itemName, itemPos, menu) {
    SetVimMode(true)
    msg("Vim Mode ON")
}

TrayDisableVimMode(itemName, itemPos, menu) {
    SetVimMode(false)
    msg("Vim Mode OFF")
}

TrayOpenRepoInVSCode() {
    global vscodeExe

    if (!vscodeExe) {
        msg("VS Code no esta configurado", { seconds: 4 })
        return
    }

    Run(QuoteCommandPath(vscodeExe) . ' "' . A_ScriptDir . '"')
}

; Initialize tray menu
SetupTrayMenu()
