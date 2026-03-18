global vimMode := false
global vimVisualMode := false
global vimPendingOperator := ""
global vimModeGui := 0
global vimModeLabel := 0
global vimLAltDownTick := 0
global vimTapThresholdMs := 180
global vimRegisteredHotkeys := []

ShowVimModeIndicator() {
    global vimModeGui, vimModeLabel

    if (!vimModeGui) {
        vimModeGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +E0x20")
        vimModeGui.BackColor := "245C3A"
        vimModeGui.MarginX := 10
        vimModeGui.MarginY := 6
        vimModeGui.SetFont("s10 bold", "Segoe UI")
        vimModeLabel := vimModeGui.AddText("cWhite", "VIM")
    }

    VimRefreshIndicator()
}

HideVimModeIndicator() {
    global vimModeGui

    if (vimModeGui) {
        vimModeGui.Hide()
    }
}

VimRefreshIndicator() {
    global vimMode, vimModeGui, vimModeLabel, vimVisualMode, vimPendingOperator

    if (!vimMode) {
        HideVimModeIndicator()
        return
    }

    if (!vimModeGui) {
        ShowVimModeIndicator()
        return
    }

    text := "VIM"
    if (vimVisualMode) {
        text .= " VISUAL"
    }
    if (vimPendingOperator != "") {
        text .= " " . StrUpper(vimPendingOperator)
    }

    vimModeLabel.Text := text
    monitor := getMonitorInfo()
    vimModeGui.Show("NoActivate x" (monitor.left_screen + 10) " y" (monitor.top_screen + 35) " AutoSize")
}

VimClearPendingOperator() {
    global vimPendingOperator
    vimPendingOperator := ""
    VimRefreshIndicator()
}

SetVimVisualMode(enabled) {
    global vimVisualMode

    vimVisualMode := enabled
    VimClearPendingOperator()
    VimRefreshIndicator()
}

ToggleVimVisualMode() {
    global vimVisualMode
    SetVimVisualMode(!vimVisualMode)
}

SetVimMode(enabled) {
    global vimMode, vimVisualMode, vimPendingOperator

    vimMode := enabled
    vimVisualMode := false
    vimPendingOperator := ""

    if (vimMode) {
        ShowVimModeIndicator()
    } else {
        HideVimModeIndicator()
    }
}

ToggleVimMode() {
    global vimMode
    SetVimMode(!vimMode)
}

VimAction(kind, value?) {
    action := { kind: kind }
    if (IsSet(value)) {
        action.value := value
    }
    return action
}

VimHotIf(*) {
    global vimMode
    return vimMode
}

VimBuildHotkeyHandler(actionSpec) {
    return (*) => VimExecuteAction(actionSpec)
}

VimRegisterKeymap(keymap) {
    global vimRegisteredHotkeys

    HotIf(VimHotIf)
    for hotkeyName, actionSpec in keymap {
        handler := VimBuildHotkeyHandler(actionSpec)
        Hotkey(hotkeyName, handler, "On")
        vimRegisteredHotkeys.Push({ key: hotkeyName, handler: handler })
    }
    HotIf()
}

VimExecuteAction(actionSpec) {
    if (Type(actionSpec) = "Func" || Type(actionSpec) = "BoundFunc") {
        actionSpec.Call()
        return
    }

    switch actionSpec.kind {
        case "motion":
            VimHandleMotion(actionSpec.value)
        case "toggle_visual":
            ToggleVimVisualMode()
        case "delete_char":
            VimDeleteChar(actionSpec.HasOwnProp("value") ? actionSpec.value : false)
        case "operator":
            VimHandleOperator(actionSpec.value)
        case "paste":
            VimPaste()
        case "send":
            Send(actionSpec.value)
        case "set_mode":
            SetVimMode(actionSpec.value)
        case "insert_after":
            VimInsertAfter(actionSpec.HasOwnProp("value") ? actionSpec.value : "")
        case "escape":
            VimEscape()
        default:
            msg("Unknown Vim action: " . actionSpec.kind, { seconds: 2 })
    }
}

VimMotionKeys(motion, select := false) {
    switch motion {
        case "left":
            return select ? "+{Left}" : "{Left}"
        case "down":
            return select ? "+{Down}" : "{Down}"
        case "up":
            return select ? "+{Up}" : "{Up}"
        case "right":
            return select ? "+{Right}" : "{Right}"
        case "word_back":
            return select ? "^+{Left}" : "^{Left}"
        case "word_forward":
            return select ? "^+{Right}" : "^{Right}"
        case "line_start":
            return select ? "+{Home}" : "{Home}"
        case "line_end":
            return select ? "+{End}" : "{End}"
        case "doc_start":
            return select ? "^+{Home}" : "^{Home}"
        case "doc_end":
            return select ? "^+{End}" : "^{End}"
        default:
            return ""
    }
}

VimSendMotion(motion, select := false) {
    keys := VimMotionKeys(motion, select)
    if (keys != "") {
        Send(keys)
    }
}

VimApplyOperator(op, motion) {
    VimSendMotion(motion, true)

    switch op {
        case "d":
            Send("{Delete}")
        case "c":
            Send("{Delete}")
            SetVimMode(false)
        case "y":
            Send("^c")
    }
}

VimApplyLineOperator(op) {
    Send("{Home}+{End}")

    switch op {
        case "d":
            Send("{Delete}")
        case "c":
            Send("{Delete}")
            SetVimMode(false)
        case "y":
            Send("^c")
    }
}

VimHandleMotion(motion) {
    global vimPendingOperator, vimVisualMode

    if (vimPendingOperator != "") {
        op := vimPendingOperator
        VimClearPendingOperator()
        VimApplyOperator(op, motion)
        return
    }

    VimSendMotion(motion, vimVisualMode)
}

VimHandleOperator(op) {
    global vimPendingOperator, vimVisualMode

    if (vimVisualMode) {
        switch op {
            case "d":
                Send("{Delete}")
            case "c":
                Send("{Delete}")
                SetVimMode(false)
            case "y":
                Send("^c")
        }
        vimVisualMode := false
        VimRefreshIndicator()
        return
    }

    if (vimPendingOperator = op) {
        VimClearPendingOperator()
        VimApplyLineOperator(op)
        return
    }

    vimPendingOperator := op
    VimRefreshIndicator()
    try SetTimer(VimClearPendingOperator, 0)
    SetTimer(VimClearPendingOperator, -1200)
}

VimDeleteChar(backward := false) {
    global vimVisualMode

    if (vimVisualMode) {
        Send("{Delete}")
        vimVisualMode := false
        VimRefreshIndicator()
        return
    }

    Send(backward ? "{Backspace}" : "{Delete}")
}

VimPaste() {
    global vimVisualMode

    Send("^v")
    if (vimVisualMode) {
        vimVisualMode := false
        VimRefreshIndicator()
    }
}

VimEscape() {
    global vimMode, vimVisualMode, vimPendingOperator

    if (vimPendingOperator != "") {
        VimClearPendingOperator()
        return
    }

    if (vimVisualMode) {
        vimVisualMode := false
        VimRefreshIndicator()
        return
    }

    if (vimMode) {
        SetVimMode(false)
    }
}

VimInsertAfter(moveKeys := "") {
    if (moveKeys != "") {
        Send(moveKeys)
    }
    SetVimMode(false)
}

~LAlt:: {
    global vimLAltDownTick
    vimLAltDownTick := A_TickCount
    ; Mask Alt immediately so the active app doesn't enter menu mode or steal focus.
    Send("{Blind}{vkE8}")
}

~LAlt Up:: {
    global vimLAltDownTick, vimTapThresholdMs

    if (A_PriorKey != "LAlt") {
        return
    }

    if ((A_TickCount - vimLAltDownTick) > vimTapThresholdMs) {
        return
    }

    ToggleVimMode()
}
