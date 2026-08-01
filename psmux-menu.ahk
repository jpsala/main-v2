; ===================================================================
; psmux contextual command menu
; Alt+P is active in Windows Terminal; actions expect the focused tab to run psmux.
; ===================================================================

global PSMUX_MENU_TARGET_HWND := 0

PsmuxMenuIsActive(*) {
    try {
        return WinActive("ahk_exe WindowsTerminal.exe") > 0
    } catch {
        return false
    }
}

PsmuxMenuGetOptions() {
    return {
        title: "psmux commands",
        items: [
            { key: "ss", label: "Sesiones: elegir con preview — Ctrl+A s", action: () => PsmuxMenuSendPrefixText("s") },
            { key: "sn", label: "Sesiones: crear nueva — Ctrl+A : new-session", action: () => PsmuxMenuCreateSession() },
            { key: "sr", label: "Sesiones: renombrar actual — Ctrl+A $", action: () => PsmuxMenuSendPrefixText("$") },
            { key: "sp", label: "Sesiones: anterior — Ctrl+A (", action: () => PsmuxMenuSendPrefixText("(") },
            { key: "sx", label: "Sesiones: siguiente — Ctrl+A )", action: () => PsmuxMenuSendPrefixText(")") },
            { key: "sd", label: "Sesiones: desconectar cliente — Ctrl+A d", action: () => PsmuxMenuSendPrefixText("d") },
            { key: "wm", label: "Tabs: selector MRU — Ctrl+A Tab", action: () => PsmuxMenuSendPrefixKey("{Tab}") },
            { key: "wt", label: "Tabs: arbol de sesiones, tabs y paneles — Ctrl+A w", action: () => PsmuxMenuSendPrefixText("w") },
            { key: "wn", label: "Tabs: crear nueva — Ctrl+A c", action: () => PsmuxMenuSendPrefixText("c") },
            { key: "wr", label: "Tabs: renombrar actual — Ctrl+A ,", action: () => PsmuxMenuSendPrefixText(",") },
            { key: "wx", label: "Tabs: cerrar actual — Ctrl+A &", action: () => PsmuxMenuSendPrefixText("&") },
            { key: "wp", label: "Tabs: anterior por indice — Ctrl+A p", action: () => PsmuxMenuSendPrefixText("p") },
            { key: "wN", label: "Tabs: siguiente por indice — Ctrl+A n", action: () => PsmuxMenuSendPrefixText("n") },
            { key: "wh", label: "Paneles: dividir horizontal — Ctrl+A h", action: () => PsmuxMenuSendPrefixText("h") },
            { key: "wv", label: "Paneles: dividir vertical — Ctrl+A v", action: () => PsmuxMenuSendPrefixText("v") },
            { key: "wz", label: "Paneles: maximizar o restaurar — Ctrl+A z", action: () => PsmuxMenuSendPrefixText("z") },
            { key: "wq", label: "Paneles: mostrar numeros — Ctrl+A q", action: () => PsmuxMenuSendPrefixText("q") },
            { key: "wX", label: "Paneles: cerrar actual — Ctrl+A x", action: () => PsmuxMenuSendPrefixText("x") },
            { key: "cm", label: "Copy mode: abrir historial — Ctrl+A [", action: () => PsmuxMenuSendPrefixText("[") },
            { key: "rc", label: "Config: recargar .psmux.conf — Ctrl+A : source-file", action: () => PsmuxMenuRunCommand("source-file ~/.psmux.conf") },
            { key: "hk", label: "Ayuda: mostrar bindings — Ctrl+A ?", action: () => PsmuxMenuSendPrefixText("?") },
            { key: "lc", label: "Ayuda: listar comandos — Ctrl+A : list-commands", action: () => PsmuxMenuRunCommand("list-commands") },
        ]
    }
}

PsmuxMenuShow() {
    global PSMUX_MENU_TARGET_HWND

    PSMUX_MENU_TARGET_HWND := WinExist("A")
    KeyWait("Alt")
    MenuWebViewRunWithActions(PsmuxMenuGetOptions())
}

PsmuxMenuActivateTarget() {
    global PSMUX_MENU_TARGET_HWND

    if (!PSMUX_MENU_TARGET_HWND || !WinExist("ahk_id " . PSMUX_MENU_TARGET_HWND))
        return false

    try {
        WinActivate("ahk_id " . PSMUX_MENU_TARGET_HWND)
        WinWaitActive("ahk_id " . PSMUX_MENU_TARGET_HWND, , 1)
        Sleep(80)
        return true
    } catch {
        return false
    }
}

PsmuxMenuSendPrefixKey(keySpec) {
    if !PsmuxMenuActivateTarget()
        return false

    Send("^a")
    Sleep(80)
    Send(keySpec)
    return true
}

PsmuxMenuSendPrefixText(text) {
    if !PsmuxMenuActivateTarget()
        return false

    Send("^a")
    Sleep(80)
    SendText(text)
    return true
}

PsmuxMenuRunCommand(command) {
    if !PsmuxMenuActivateTarget()
        return false

    Send("^a")
    Sleep(80)
    SendText(":")
    Sleep(80)
    SendText(command)
    Send("{Enter}")
    return true
}

PsmuxMenuIsValidSessionName(sessionName) {
    return RegExMatch(sessionName, "^[A-Za-z0-9._-]+$")
}

PsmuxMenuCreateSession() {
    result := InputBox("Nombre: letras, numeros, punto, guion o guion bajo.", "Nueva sesion psmux", "w430 h130")
    if (result.Result != "OK")
        return false

    sessionName := Trim(result.Value)
    if !PsmuxMenuIsValidSessionName(sessionName) {
        MsgBox("Nombre invalido. Usa solo letras, numeros, punto, guion o guion bajo.", "psmux", "IconError")
        return false
    }

    if !PsmuxMenuRunCommand("new-session -d -s " . sessionName)
        return false

    Sleep(350)
    return PsmuxMenuSendPrefixText("s")
}

#HotIf PsmuxMenuIsActive()
!p::PsmuxMenuShow()
#HotIf
