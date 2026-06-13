global vimMode := false
global vimCurrentMode := "off"
global vimVisualMode := false
global vimPendingOperator := ""
global vimModeGuiTopLeft := 0
global vimModeLabelTopLeft := 0
global vimModeGuiBottomRight := 0
global vimModeLabelBottomRight := 0
global vimLAltDownTick := 0
global vimTapThresholdMs := 180
global vimTextEntryMode := false
global vimTextEntryLabel := ""
global vimCharPending := ""
global vimLastCharMotion := { op: "", char: "", reverse: false }
global vimVisualLineMode := false
global vimRegisteredHotkeys := []
global vimSuppressedHotkeys := []

VimCreateModeIndicatorGui() {
    indicatorGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Disabled +E0x20")
    indicatorGui.BackColor := "9E2A2B"
    indicatorGui.MarginX := 7
    indicatorGui.MarginY := 3
    indicatorGui.SetFont("s8 bold", "Segoe UI")
    label := indicatorGui.AddText("cWhite", "VIM")
    return { gui: indicatorGui, label: label }
}

ShowVimModeIndicator() {
    global vimModeGuiTopLeft, vimModeLabelTopLeft, vimModeGuiBottomRight, vimModeLabelBottomRight

    if (!vimModeGuiTopLeft) {
        indicator := VimCreateModeIndicatorGui()
        vimModeGuiTopLeft := indicator.gui
        vimModeLabelTopLeft := indicator.label
    }

    if (!vimModeGuiBottomRight) {
        indicator := VimCreateModeIndicatorGui()
        vimModeGuiBottomRight := indicator.gui
        vimModeLabelBottomRight := indicator.label
    }

    VimRefreshIndicator()
}

HideVimModeIndicator() {
    global vimModeGuiTopLeft, vimModeGuiBottomRight

    if (vimModeGuiTopLeft) {
        vimModeGuiTopLeft.Hide()
    }

    if (vimModeGuiBottomRight) {
        vimModeGuiBottomRight.Hide()
    }
}

VimSetPrimaryMode(mode) {
    global vimCurrentMode, vimMode, vimVisualMode, vimVisualLineMode

    vimCurrentMode := mode
    vimMode := (mode != "off")
    vimVisualMode := (mode = "visual")
    vimVisualLineMode := (mode = "visual_line")
}

VimIsPrimaryMode(mode) {
    global vimCurrentMode
    return vimCurrentMode = mode
}

VimModeLabelText() {
    global vimCurrentMode

    switch vimCurrentMode {
        case "visual":
            return "VISUAL"
        case "visual_line":
            return "VISUAL-LINE"
        case "normal":
            return "VIM"
        default:
            return "VIM"
    }
}

VimRefreshIndicator() {
    global vimMode, vimModeGuiTopLeft, vimModeLabelTopLeft, vimModeGuiBottomRight, vimModeLabelBottomRight, vimPendingOperator, vimTextEntryMode, vimTextEntryLabel, vimCharPending

    if (!vimMode) {
        HideVimModeIndicator()
        return
    }

    if (!vimModeGuiTopLeft || !vimModeGuiBottomRight) {
        ShowVimModeIndicator()
        return
    }

    text := VimModeLabelText()
    if (vimPendingOperator != "") {
        text .= " " . StrUpper(vimPendingOperator)
    }
    if (vimTextEntryMode) {
        text .= " " . (vimTextEntryLabel != "" ? StrUpper(vimTextEntryLabel) : "INPUT")
    }
    if (vimCharPending != "") {
        text .= " " . StrUpper(vimCharPending)
    }

    vimModeLabelTopLeft.Text := text
    vimModeLabelBottomRight.Text := text
    monitor := getMonitorInfo()
    vimModeGuiTopLeft.Show("NoActivate x" (monitor.left_screen + 10) " y" (monitor.top_screen + 20) " AutoSize")

    WinGetPos(, , &indicatorWidth, &indicatorHeight, "ahk_id " . vimModeGuiTopLeft.Hwnd)
    bottomRightX := monitor.right_screen - indicatorWidth - 12
    bottomRightY := monitor.bottom_screen - indicatorHeight - 12
    vimModeGuiBottomRight.Show("NoActivate x" bottomRightX " y" bottomRightY " AutoSize")
}

VimClearPendingOperator() {
    global vimPendingOperator
    vimPendingOperator := ""
    VimRefreshIndicator()
}

SetVimVisualMode(enabled) {
    VimSetPrimaryMode(enabled ? "visual" : "normal")
    VimClearPendingOperator()
    VimRefreshIndicator()
}

ToggleVimVisualMode() {
    SetVimVisualMode(!VimIsPrimaryMode("visual"))
}

SetVimMode(enabled) {
    global vimPendingOperator, vimTextEntryMode, vimTextEntryLabel, vimCharPending

    VimSetPrimaryMode(enabled ? "normal" : "off")
    vimPendingOperator := ""
    vimTextEntryMode := false
    vimTextEntryLabel := ""
    vimCharPending := ""

    if (vimMode) {
        ShowVimModeIndicator()
    } else {
        HideVimModeIndicator()
    }

    return vimMode
}

ToggleVimMode() {
    global vimMode
    SetVimMode(!vimMode)
}

VimExitOnMouse(*) {
    global vimMode
    if (vimMode) {
        SetVimMode(false)
    }
}

VimNotifyMouseInteraction(button := "") {
    VimExitOnMouse()
}

VimAction(kind, value?) {
    action := { kind: kind }
    if (IsSet(value)) {
        action.value := value
    }
    return action
}

VimHotIf(*) {
    global vimMode, vimTextEntryMode, vimCharPending
    try
        return vimMode && (VimIsPrimaryMode("normal") || VimIsPrimaryMode("visual") || VimIsPrimaryMode("visual_line")) && !vimTextEntryMode && vimCharPending = ""
    catch
        return false
}

VimHotIfEnabled(*) {
    global vimMode
    try
        return vimMode
    catch
        return false
}

VimHotIfNotCode(*) {
    try
        return VimHotIf() && !WinActive("ahk_exe Code.exe") && !WinActive("ahk_exe Cursor.exe")
    catch
        return false
}

VimBuildHotkeyHandler(actionSpec, hotkeyName := "") {
    return (*) => VimExecuteActionWithModifiers(actionSpec, hotkeyName)
}

VimNoOp(*) {
}

VimRegisterKeymap(keymap, hotIfFunc?) {
    global vimRegisteredHotkeys

    if (!IsSet(hotIfFunc)) {
        hotIfFunc := VimHotIf
    }

    HotIf(hotIfFunc)
    for hotkeyName, actionSpec in keymap {
        handler := VimBuildHotkeyHandler(actionSpec, hotkeyName)
        Hotkey(hotkeyName, handler, "On")
        vimRegisteredHotkeys.Push({ key: hotkeyName, handler: handler, hotIf: hotIfFunc })
    }
    HotIf()
}

VimActionNeedsShiftRelease(actionSpec) {
    switch actionSpec.kind {
        case "motion":
            return true
        case "delete_char":
            return true
        case "search":
            return true
        case "history_nav":
            return true
        case "operator_motion":
            return true
        case "line_operator":
            return true
        case "insert_after":
            return true
        case "insert_here":
            return true
        default:
            return false
    }
}

VimExecuteActionWithModifiers(actionSpec, hotkeyName := "") {
    leftShiftDown := GetKeyState("LShift", "P")
    rightShiftDown := GetKeyState("RShift", "P")
    needsShiftRelease := (hotkeyName != ""
        && SubStr(hotkeyName, 1, 1) = "+"
        && (leftShiftDown || rightShiftDown)
        && VimActionNeedsShiftRelease(actionSpec))

    if (needsShiftRelease) {
        if (leftShiftDown) {
            Send("{LShift Up}")
        }
        if (rightShiftDown) {
            Send("{RShift Up}")
        }
    }

    VimExecuteAction(actionSpec)

    if (needsShiftRelease) {
        if (leftShiftDown && GetKeyState("LShift", "P")) {
            Send("{LShift Down}")
        }
        if (rightShiftDown && GetKeyState("RShift", "P")) {
            Send("{RShift Down}")
        }
    }
}

VimRegisterSuppressedPrintables(keymap, hotIfFunc?) {
    global vimSuppressedHotkeys

    allowedKeys := Map()
    for hotkeyName, _ in keymap {
        allowedKeys[hotkeyName] := true
    }

    if (!IsSet(hotIfFunc)) {
        hotIfFunc := VimHotIf
    }

    suppressList := [
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "+a", "+b", "+c", "+d", "+e", "+f", "+g", "+h", "+i", "+j", "+k", "+l", "+m",
        "+n", "+o", "+p", "+q", "+r", "+s", "+t", "+u", "+v", "+w", "+x", "+y", "+z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "+0", "+1", "+2", "+3", "+4", "+5", "+6", "+7", "+8", "+9",
        "Space",
        "-", "=", "[", "]", ";", "'", ",", ".", "/",
        "+-", "+=", "+[", "+]", "+;", "+'", "+,", "+.", "+/",
        "Tab", "Enter", "Backspace", "Delete"
    ]

    HotIf(hotIfFunc)
    for _, hotkeyName in suppressList {
        if (allowedKeys.Has(hotkeyName)) {
            continue
        }
        suppressHotIf := hotIfFunc
        if ((hotkeyName = "/" || hotkeyName = "+7") && hotIfFunc == VimHotIf) {
            suppressHotIf := VimHotIfNotCode
        }

        HotIf(suppressHotIf)
        Hotkey(hotkeyName, VimNoOp, "On")
        vimSuppressedHotkeys.Push({ key: hotkeyName, hotIf: suppressHotIf })
        HotIf(hotIfFunc)
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
        case "toggle_visual_line":
            ToggleVimVisualLineMode()
        case "delete_char":
            VimDeleteChar(actionSpec.HasOwnProp("value") ? actionSpec.value : false)
        case "operator":
            VimHandleOperator(actionSpec.value)
        case "paste":
            VimPaste()
        case "paste_before":
            VimPasteBefore()
        case "line_operator":
            VimApplyLineOperator(actionSpec.value)
        case "search":
            VimStartSearch()
        case "char_motion":
            VimStartCharMotion(actionSpec.value)
        case "repeat_char_motion":
            VimRepeatCharMotion(actionSpec.value)
        case "history_nav":
            VimSendHistoryNav(actionSpec.value)
        case "operator_motion":
            VimApplyOperator(actionSpec.value.operator, actionSpec.value.motion)
        case "send":
            Send(actionSpec.value)
        case "set_mode":
            SetVimMode(actionSpec.value)
        case "insert_after":
            VimInsertAfter(actionSpec.HasOwnProp("value") ? actionSpec.value : "")
        case "insert_here":
            VimInsertHere(actionSpec.HasOwnProp("value") ? actionSpec.value : "")
        case "line_motion":
            VimSendMotion(actionSpec.value, false)
        case "escape":
            VimEscape()
        default:
            msg("Unknown Vim action: " . actionSpec.kind, { seconds: 2 })
    }
}

VimStartTextEntry(label := "input") {
    global vimTextEntryMode, vimTextEntryLabel
    vimTextEntryMode := true
    vimTextEntryLabel := label
    VimRefreshIndicator()
}

VimStopTextEntry() {
    global vimTextEntryMode, vimTextEntryLabel
    vimTextEntryMode := false
    vimTextEntryLabel := ""
    VimRefreshIndicator()
}

VimStartSearch() {
    Send("^f")
    VimStartTextEntry("find")
}

VimStartCharMotion(kind) {
    global vimCharPending
    vimCharPending := kind
    VimRefreshIndicator()
}

VimCancelCharMotion() {
    global vimCharPending
    vimCharPending := ""
    VimRefreshIndicator()
}

VimHotIfCharPending(*) {
    global vimMode, vimTextEntryMode, vimCharPending
    try
        return vimMode && !vimTextEntryMode && vimCharPending != ""
    catch
        return false
}

VimCaptureCharMotionChar(char) {
    global vimCharPending, vimLastCharMotion

    kind := vimCharPending
    vimCharPending := ""
    VimRefreshIndicator()

    if (char = "") {
        return
    }

    reverse := (kind = "F" || kind = "T")
    vimLastCharMotion := { op: kind, char: char, reverse: reverse }
    VimExecuteCharMotion(kind, char)
}

VimExecuteCharMotion(kind, char) {
    ; Portable approximation: use editor/app find-next behavior rather than
    ; inspecting rendered text. This is closest to "jump to char" without app-specific APIs.
    if (kind = "f" || kind = "t") {
        ; Skip the current character so f/t search forward from "after cursor".
        Send("{Right}")
        Send("^f")
        Sleep(20)
        SendText(char)
        Sleep(20)
        Send("{Esc}")
    } else if (kind = "F" || kind = "T") {
        ; Skip the current character so F/T search backward from "before cursor".
        Send("{Left}")
        Send("^f")
        Sleep(20)
        SendText(char)
        Sleep(20)
        Send("+{Enter}")
        Send("{Esc}")
    }

    if (kind = "f" || kind = "F") {
        Send("{Left}")
    } else if (kind = "t") {
        Send("{Left 2}")
    } else if (kind = "T") {
        ; Backward "to" should end just after the found character.
        Send("{Right}")
    }
}

VimRepeatCharMotion(reverse := false) {
    global vimLastCharMotion

    if (vimLastCharMotion.op = "" || vimLastCharMotion.char = "") {
        return
    }

    op := vimLastCharMotion.op
    if (reverse) {
        switch op {
            case "f": op := "F"
            case "F": op := "f"
            case "t": op := "T"
            case "T": op := "t"
        }
    }

    VimExecuteCharMotion(op, vimLastCharMotion.char)
}

VimCharPendingHandlePrintable(keyName) {
    if (StrLen(keyName) = 1) {
        VimCaptureCharMotionChar(keyName)
        return
    }

    if (SubStr(keyName, 1, 1) = "+" && StrLen(keyName) = 2) {
        VimCaptureCharMotionChar(StrUpper(SubStr(keyName, 2)))
    }
}

VimHotIfTextEntryCode(*) {
    global vimMode, vimTextEntryMode
    try
        return vimMode && vimTextEntryMode && (WinActive("ahk_exe Code.exe") || WinActive("ahk_exe Cursor.exe"))
    catch
        return false
}

VimConfirmSearch(*) {
    Send("{Enter}{Esc}")
    VimStopTextEntry()
}

VimCancelSearch(*) {
    Send("{Esc}")
    VimStopTextEntry()
}

VimSendHistoryNav(direction) {
    leftShiftDown := GetKeyState("LShift", "P")
    rightShiftDown := GetKeyState("RShift", "P")

    if (leftShiftDown) {
        Send("{LShift Up}")
    }
    if (rightShiftDown) {
        Send("{RShift Up}")
    }

    Send(direction = "back" ? "!{Left}" : "!{Right}")

    if (leftShiftDown && GetKeyState("LShift", "P")) {
        Send("{LShift Down}")
    }
    if (rightShiftDown && GetKeyState("RShift", "P")) {
        Send("{RShift Down}")
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

VimSendWordEnd(select := false) {
    ; Approximate Vim's "e" using a word jump and then backing up one char.
    ; This is still generic Send-based behavior, but it no longer aliases "w".
    if (select) {
        Send("^+{Right}")
        Send("+{Left}")
    } else {
        Send("^{Right}{Left}")
    }
}

VimSendMotion(motion, select := false) {
    if (motion = "word_end") {
        if (VimIsPrimaryMode("visual_line")) {
            VimSetPrimaryMode("visual")
            select := true
        }
        VimSendWordEnd(select)
        return
    }

    if (VimIsPrimaryMode("visual_line")) {
        VimSetPrimaryMode("visual")
        select := true
    }

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
    global vimPendingOperator

    if (vimPendingOperator != "") {
        op := vimPendingOperator
        VimClearPendingOperator()
        VimApplyOperator(op, motion)
        return
    }

    VimSendMotion(motion, VimIsPrimaryMode("visual"))
}

VimHandleOperator(op) {
    global vimPendingOperator

    if (VimIsPrimaryMode("visual") || VimIsPrimaryMode("visual_line")) {
        switch op {
            case "d":
                Send("{Delete}")
            case "c":
                Send("{Delete}")
                SetVimMode(false)
                return
            case "y":
                Send("^c")
        }
        VimSetPrimaryMode("normal")
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
    if (VimIsPrimaryMode("visual") || VimIsPrimaryMode("visual_line")) {
        Send("{Delete}")
        VimSetPrimaryMode("normal")
        VimRefreshIndicator()
        return
    }

    Send(backward ? "{Backspace}" : "{Delete}")
}

VimPaste() {
    Send("^v")
    if (VimIsPrimaryMode("visual") || VimIsPrimaryMode("visual_line")) {
        VimSetPrimaryMode("normal")
        VimRefreshIndicator()
        return
    }
}

VimPasteBefore() {
    if (VimIsPrimaryMode("visual") || VimIsPrimaryMode("visual_line")) {
        Send("^v")
        VimSetPrimaryMode("normal")
        VimRefreshIndicator()
        return
    }
    Send("{Left}^v")
}

VimEscape() {
    global vimMode, vimPendingOperator, vimTextEntryMode, vimCharPending

    if (vimTextEntryMode) {
        Send("{Esc}")
        VimStopTextEntry()
        return
    }

    if (vimCharPending != "") {
        VimCancelCharMotion()
        return
    }

    if (vimPendingOperator != "") {
        VimClearPendingOperator()
        return
    }

    if (VimIsPrimaryMode("visual") || VimIsPrimaryMode("visual_line")) {
        VimSetPrimaryMode("normal")
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

VimInsertHere(moveKeys := "") {
    if (moveKeys != "") {
        Send(moveKeys)
    }
    SetVimMode(false)
}

ToggleVimVisualLineMode() {
    if (VimIsPrimaryMode("visual_line")) {
        VimSetPrimaryMode("normal")
        VimRefreshIndicator()
        return
    }

    VimSetPrimaryMode("visual_line")
    Send("{Home}+{End}")
    VimClearPendingOperator()
    VimRefreshIndicator()
}

~LAlt:: {
    global vimLAltDownTick
    vimLAltDownTick := A_TickCount
    ; Mask Alt immediately so the active app doesn't enter menu mode or steal focus.
    Send("{Blind}{vkE8}")
}

~LAlt Up:: {
    global vimLAltDownTick, vimTapThresholdMs, vimMode

    if (A_PriorKey != "LAlt") {
        return
    }

    if ((A_TickCount - vimLAltDownTick) > vimTapThresholdMs) {
        return
    }

    if (vimMode) {
        VimEscape()
        return
    }

    SetVimMode(true)
}

#HotIf VimHotIfTextEntryCode()
Enter:: VimConfirmSearch()
#HotIf

#HotIf VimHotIfEnabled()
Esc:: VimEscape()
~LButton:: VimExitOnMouse()
~XButton1:: VimExitOnMouse()
~XButton2:: VimExitOnMouse()
#HotIf

#HotIf VimHotIfCharPending()
a:: VimCharPendingHandlePrintable("a")
b:: VimCharPendingHandlePrintable("b")
c:: VimCharPendingHandlePrintable("c")
d:: VimCharPendingHandlePrintable("d")
e:: VimCharPendingHandlePrintable("e")
f:: VimCharPendingHandlePrintable("f")
g:: VimCharPendingHandlePrintable("g")
h:: VimCharPendingHandlePrintable("h")
i:: VimCharPendingHandlePrintable("i")
j:: VimCharPendingHandlePrintable("j")
k:: VimCharPendingHandlePrintable("k")
l:: VimCharPendingHandlePrintable("l")
m:: VimCharPendingHandlePrintable("m")
n:: VimCharPendingHandlePrintable("n")
o:: VimCharPendingHandlePrintable("o")
p:: VimCharPendingHandlePrintable("p")
q:: VimCharPendingHandlePrintable("q")
r:: VimCharPendingHandlePrintable("r")
s:: VimCharPendingHandlePrintable("s")
t:: VimCharPendingHandlePrintable("t")
u:: VimCharPendingHandlePrintable("u")
v:: VimCharPendingHandlePrintable("v")
w:: VimCharPendingHandlePrintable("w")
x:: VimCharPendingHandlePrintable("x")
y:: VimCharPendingHandlePrintable("y")
z:: VimCharPendingHandlePrintable("z")
+a:: VimCharPendingHandlePrintable("+a")
+b:: VimCharPendingHandlePrintable("+b")
+c:: VimCharPendingHandlePrintable("+c")
+d:: VimCharPendingHandlePrintable("+d")
+e:: VimCharPendingHandlePrintable("+e")
+f:: VimCharPendingHandlePrintable("+f")
+g:: VimCharPendingHandlePrintable("+g")
+h:: VimCharPendingHandlePrintable("+h")
+i:: VimCharPendingHandlePrintable("+i")
+j:: VimCharPendingHandlePrintable("+j")
+k:: VimCharPendingHandlePrintable("+k")
+l:: VimCharPendingHandlePrintable("+l")
+m:: VimCharPendingHandlePrintable("+m")
+n:: VimCharPendingHandlePrintable("+n")
+o:: VimCharPendingHandlePrintable("+o")
+p:: VimCharPendingHandlePrintable("+p")
+q:: VimCharPendingHandlePrintable("+q")
+r:: VimCharPendingHandlePrintable("+r")
+s:: VimCharPendingHandlePrintable("+s")
+t:: VimCharPendingHandlePrintable("+t")
+u:: VimCharPendingHandlePrintable("+u")
+v:: VimCharPendingHandlePrintable("+v")
+w:: VimCharPendingHandlePrintable("+w")
+x:: VimCharPendingHandlePrintable("+x")
+y:: VimCharPendingHandlePrintable("+y")
+z:: VimCharPendingHandlePrintable("+z")
0:: VimCharPendingHandlePrintable("0")
1:: VimCharPendingHandlePrintable("1")
2:: VimCharPendingHandlePrintable("2")
3:: VimCharPendingHandlePrintable("3")
4:: VimCharPendingHandlePrintable("4")
5:: VimCharPendingHandlePrintable("5")
6:: VimCharPendingHandlePrintable("6")
7:: VimCharPendingHandlePrintable("7")
8:: VimCharPendingHandlePrintable("8")
9:: VimCharPendingHandlePrintable("9")
Space:: VimCaptureCharMotionChar(" ")
#HotIf
