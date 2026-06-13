#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
#ErrorStdOut UTF-8

; Portable automation shell.
; Standalone: no #Include from this repo.
; Current modules: cursor navigation + Vim mode.
;
; Main shortcuts:
; - Win+Alt+K: toggle Alt cursor keys
; - Alt+H/J/K/L: left/down/up/right
; - Alt+Shift+H/L: home/end
; - Alt+Shift+J/K: PgDn/PgUp
; - Alt+D: delete
; - Tap left Alt: toggle Vim mode
; - Esc: leave pending Vim state / visual mode / Vim mode

CoordMode("Mouse", "Window")
InstallKeybdHook()
InstallMouseHook()
SendMode("Input")
SetTitleMatchMode(2)
SetWorkingDir(A_ScriptDir)
TraySetIcon(A_ScriptDir . "\main.ico")

global portableAutostartRegPath := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
global portableAutostartValueName := "PortableAutomation"
global portableLegacyAutostartValueName := "PortableVimCursor"
global portableLogFile := A_Temp . "\portable-automation-" . FormatTime(, "yyyyMMdd-HHmmss") . ".log"
global cursorKeysEnabled := true
global vimMode := false
global vimCurrentMode := "off"
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
global vimLastCharMotion := { op: "", char: "" }
global vimRegisteredHotkeys := []
global vimSuppressedHotkeys := []

try {
    EmptyLog(portableLogFile)
    log({ logFilePath: portableLogFile }, "portable-automation started", A_ScriptFullPath)
    OnExit(LogPortableExit)
    MigratePortableAutostartValue()
    SetupPortableTrayMenu()
} catch Error as e {
    MsgBox("Startup error:`n" . FormatException(e))
    ExitApp(1)
}

ShowStatus(text, ms := 900) {
    ToolTip(text, 12, 12)
    try SetTimer(HideStatus, 0)
    SetTimer(HideStatus, -ms)
}

HideStatus(*) {
    ToolTip()
}

LogPortableExit(exitReason, exitCode) {
    global portableLogFile
    try log({ logFilePath: portableLogFile }, "portable-automation exit", exitReason, exitCode)
}

PortableTrayIconClick(wParam, lParam, msg, hwnd) {
    if (lParam = 0x202) {
        SetTimer(() => A_TrayMenu.Show(), -1)
    }
}

SetupPortableTrayMenu() {
    global cursorKeysEnabled
    tray := A_TrayMenu
    tray.Delete()

    tray.Add("Start With Windows", TrayToggleAutostart)
    tray.SetIcon("Start With Windows", "shell32.dll", 44)
    if (IsPortableAutostartEnabled()) {
        tray.Check("Start With Windows")
    }

    tray.Add("Cursor Keys", TrayToggleCursorKeys)
    tray.SetIcon("Cursor Keys", "shell32.dll", 174)
    if (cursorKeysEnabled) {
        tray.Check("Cursor Keys")
    }

    tray.Add("Vim Mode ON", TrayEnableVimMode)
    tray.SetIcon("Vim Mode ON", "shell32.dll", 174)

    tray.Add("Vim Mode OFF", TrayDisableVimMode)
    tray.SetIcon("Vim Mode OFF", "shell32.dll", 132)

    tray.Add()

    tray.Add("Reload Script", (*) => Reload())
    tray.SetIcon("Reload Script", "shell32.dll", 239)

    tray.Add("Open Script Folder", (*) => Run(A_ScriptDir))
    tray.SetIcon("Open Script Folder", "shell32.dll", 4)

    tray.Add()

    tray.Add("Exit", (*) => ExitApp())
    tray.SetIcon("Exit", "shell32.dll", 132)
    tray.Default := "Reload Script"

    OnMessage(0x404, PortableTrayIconClick)
}

GetPortableAutostartCommand() {
    if (A_IsCompiled) {
        return '"' . A_ScriptFullPath . '"'
    }

    ahkPath := A_AhkPath
    if (ahkPath = "") {
        ahkPath := "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
    }
    return '"' . ahkPath . '" "' . A_ScriptFullPath . '"'
}

IsPortableAutostartEnabled() {
    global portableAutostartRegPath, portableAutostartValueName

    try {
        value := RegRead(portableAutostartRegPath, portableAutostartValueName, "")
        return value != ""
    } catch {
        return false
    }
}

MigratePortableAutostartValue() {
    global portableAutostartRegPath, portableAutostartValueName, portableLegacyAutostartValueName, portableLogFile

    try {
        currentValue := RegRead(portableAutostartRegPath, portableAutostartValueName, "")
        legacyValue := RegRead(portableAutostartRegPath, portableLegacyAutostartValueName, "")

        if (currentValue = "" && legacyValue != "") {
            RegWrite(GetPortableAutostartCommand(), "REG_SZ", portableAutostartRegPath, portableAutostartValueName)
            RegDelete(portableAutostartRegPath, portableLegacyAutostartValueName)
            log({ logFilePath: portableLogFile }, "migrated autostart value", portableLegacyAutostartValueName, portableAutostartValueName)
            return
        }

        if (legacyValue != "") {
            RegDelete(portableAutostartRegPath, portableLegacyAutostartValueName)
            log({ logFilePath: portableLogFile }, "removed legacy autostart value", portableLegacyAutostartValueName)
        }
    } catch Error as err {
        log({ logFilePath: portableLogFile, isError: true }, "autostart migration failed", err)
    }
}

EnablePortableAutostart() {
    global portableAutostartRegPath, portableAutostartValueName, portableLogFile
    command := GetPortableAutostartCommand()
    RegWrite(command, "REG_SZ", portableAutostartRegPath, portableAutostartValueName)
    try log({ logFilePath: portableLogFile }, "autostart enabled", command)
}

DisablePortableAutostart() {
    global portableAutostartRegPath, portableAutostartValueName, portableLogFile
    try RegDelete(portableAutostartRegPath, portableAutostartValueName)
    try log({ logFilePath: portableLogFile }, "autostart disabled")
}

TrayToggleAutostart(itemName, itemPos, menu) {
    if (IsPortableAutostartEnabled()) {
        DisablePortableAutostart()
        menu.Uncheck("Start With Windows")
        ShowStatus("Start with Windows disabled", 1200)
        return
    }

    EnablePortableAutostart()
    menu.Check("Start With Windows")
    ShowStatus("Start with Windows enabled", 1200)
}

TrayToggleCursorKeys(itemName, itemPos, menu) {
    global cursorKeysEnabled := !cursorKeysEnabled
    if (cursorKeysEnabled) {
        menu.Check("Cursor Keys")
    } else {
        menu.Uncheck("Cursor Keys")
    }
    ShowStatus("Cursor keys " . (cursorKeysEnabled ? "enabled" : "disabled"), 1100)
}

TrayEnableVimMode(itemName, itemPos, menu) {
    SetVimMode(true)
}

TrayDisableVimMode(itemName, itemPos, menu) {
    SetVimMode(false)
}

GetCurrentMonitorBounds() {
    mouseCoordMode := CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    CoordMode("Mouse", mouseCoordMode)

    monitorCount := MonitorGetCount()
    loop monitorCount {
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        if (mouseX >= left && mouseX <= right && mouseY >= top && mouseY <= bottom) {
            return {
                left: left,
                top: top,
                right: right,
                bottom: bottom
            }
        }
    }

    MonitorGet(1, &left, &top, &right, &bottom)
    return {
        left: left,
        top: top,
        right: right,
        bottom: bottom
    }
}

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
    global vimCurrentMode, vimMode
    vimCurrentMode := mode
    vimMode := (mode != "off")
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
    global vimMode
    global vimModeGuiTopLeft, vimModeLabelTopLeft, vimModeGuiBottomRight, vimModeLabelBottomRight
    global vimPendingOperator, vimTextEntryMode, vimTextEntryLabel, vimCharPending

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

    monitor := GetCurrentMonitorBounds()
    vimModeGuiTopLeft.Show("NoActivate x" (monitor.left + 10) " y" (monitor.top + 20) " AutoSize")

    WinGetPos(, , &indicatorWidth, &indicatorHeight, "ahk_id " . vimModeGuiTopLeft.Hwnd)
    bottomRightX := monitor.right - indicatorWidth - 12
    bottomRightY := monitor.bottom - indicatorHeight - 12
    vimModeGuiBottomRight.Show("NoActivate x" bottomRightX " y" bottomRightY " AutoSize")
}

VimClearPendingOperator(*) {
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
        ShowStatus("Vim mode on")
    } else {
        HideVimModeIndicator()
        ShowStatus("Vim mode off")
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

VimAction(kind, value?) {
    action := { kind: kind }
    if (IsSet(value)) {
        action.value := value
    }
    return action
}

VimHotIf(*) {
    global vimMode, vimTextEntryMode, vimCharPending
    try {
        return vimMode
            && (VimIsPrimaryMode("normal") || VimIsPrimaryMode("visual") || VimIsPrimaryMode("visual_line"))
            && !vimTextEntryMode
            && vimCharPending = ""
    } catch {
        return false
    }
}

VimHotIfEnabled(*) {
    global vimMode
    try {
        return vimMode
    } catch {
        return false
    }
}

VimHotIfNotCode(*) {
    try {
        return VimHotIf() && !WinActive("ahk_exe Code.exe") && !WinActive("ahk_exe Cursor.exe")
    } catch {
        return false
    }
}

VimHotIfCode(*) {
    try {
        return VimHotIf() && (WinActive("ahk_exe Code.exe") || WinActive("ahk_exe Cursor.exe"))
    } catch {
        return false
    }
}

VimHotIfCharPending(*) {
    global vimMode, vimTextEntryMode, vimCharPending
    try {
        return vimMode && !vimTextEntryMode && vimCharPending != ""
    } catch {
        return false
    }
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
    actionType := Type(actionSpec)
    if (actionType = "Func" || actionType = "BoundFunc") {
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
        case "escape":
            VimEscape()
        default:
            ShowStatus("Unknown Vim action: " . actionSpec.kind, 1400)
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

VimCaptureCharMotionChar(char) {
    global vimCharPending, vimLastCharMotion

    kind := vimCharPending
    vimCharPending := ""
    VimRefreshIndicator()

    if (char = "") {
        return
    }

    vimLastCharMotion := { op: kind, char: char }
    VimExecuteCharMotion(kind, char)
}

VimExecuteCharMotion(kind, char) {
    if (kind = "f" || kind = "t") {
        Send("{Right}")
        Send("^f")
        Sleep(20)
        SendText(char)
        Sleep(20)
        Send("{Esc}")
    } else if (kind = "F" || kind = "T") {
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
            case "f":
                op := "F"
            case "F":
                op := "f"
            case "t":
                op := "T"
            case "T":
                op := "t"
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

VimConfirmSearch(*) {
    Send("{Enter}{Esc}")
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

global vimKeymap := Map(
    "h", VimAction("motion", "left"),
    "j", VimAction("motion", "down"),
    "k", VimAction("motion", "up"),
    "l", VimAction("motion", "right"),
    "b", VimAction("motion", "word_back"),
    "w", VimAction("motion", "word_forward"),
    "+w", VimAction("motion", "word_back"),
    "e", VimAction("motion", "word_end"),
    "0", VimAction("motion", "line_start"),
    "+4", VimAction("motion", "line_end"),
    "g", VimAction("motion", "doc_start"),
    "+g", VimAction("motion", "doc_end"),
    "+h", VimAction("history_nav", "back"),
    "+l", VimAction("history_nav", "forward"),
    "f", VimAction("char_motion", "f"),
    "+f", VimAction("char_motion", "F"),
    "t", VimAction("char_motion", "t"),
    "+t", VimAction("char_motion", "T"),
    "n", VimAction("repeat_char_motion", false),
    "+n", VimAction("repeat_char_motion", true),
    ";", VimAction("repeat_char_motion", false),
    ",", VimAction("repeat_char_motion", true),
    "v", VimAction("toggle_visual"),
    "+v", VimAction("toggle_visual_line"),
    "x", VimAction("delete_char", false),
    "+x", VimAction("delete_char", true),
    "d", VimAction("operator", "d"),
    "+d", VimAction("operator_motion", { operator: "d", motion: "line_end" }),
    "c", VimAction("operator", "c"),
    "+c", VimAction("operator_motion", { operator: "c", motion: "line_end" }),
    "y", VimAction("operator", "y"),
    "+y", VimAction("line_operator", "y"),
    "p", VimAction("paste"),
    "+p", VimAction("paste_before"),
    "u", VimAction("send", "^z"),
    "i", VimAction("insert_here"),
    "+i", VimAction("insert_here", "{Home}"),
    "a", VimAction("insert_after", "{Right}"),
    "+a", VimAction("insert_after", "{End}"),
    "o", VimAction("insert_after", "{End}{Enter}"),
    "+o", VimAction("insert_after", "{Home}{Enter}{Up}")
)

global vimCodeKeymap := Map(
    "/", VimAction("search"),
    "+7", VimAction("search")
)

VimRegisterKeymap(vimKeymap)
VimRegisterSuppressedPrintables(vimKeymap)
VimRegisterKeymap(vimCodeKeymap, VimHotIfCode)
VimRegisterSuppressedPrintables(vimCodeKeymap, VimHotIfCode)

#!k:: TrayToggleCursorKeys("Cursor Keys", 0, A_TrayMenu)

CapsLock & k:: Send("{Up}")
CapsLock & j:: Send("{Down}")
CapsLock & h:: Send("{Left}")
CapsLock & l:: Send("{Right}")
CapsLock & `;:: Send("{End}")
CapsLock & g:: Send("{Home}")
CapsLock & d:: Send("{Delete}")
!d:: Send("{Delete}")

#HotIf cursorKeysEnabled
!j:: Send("{Down}")
!+j:: Send("{PgDn}")
!k:: Send("{Up}")
!+k:: Send("{PgUp}")
!h:: Send("{Left}")
!l:: Send("{Right}")
!+l:: Send("{End}")
!+h:: Send("{Home}")
#HotIf

~LAlt:: {
    global vimLAltDownTick
    vimLAltDownTick := A_TickCount
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

#HotIf VimHotIfCode()
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

log(params*) {
    logOptions := {}
    if (params.Length > 0 && IsObject(params[1]) && Type(params[1]) = "Object") {
        logOptions := params[1]
        params.RemoveAt(1)
    }

    logFilePath := GetOption(logOptions, "logFilePath", A_ScriptDir . "\log.txt")
    isError := GetOption(logOptions, "isError", false)
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    renderedParams := []

    for value in params {
        renderedParams.Push(FormatLogValue(value))
    }

    line := timestamp
    if (isError) {
        line .= " | [ERROR]"
    }
    if (renderedParams.Length > 0) {
        line .= " | " . JoinStrings(renderedParams, " | ")
    }

    EnsureParentDir(logFilePath)
    FileAppend(line . "`n", logFilePath, "UTF-8")
}

EmptyLog(logFilePath) {
    EnsureParentDir(logFilePath)
    if (FileExist(logFilePath)) {
        FileDelete(logFilePath)
    }
    FileAppend("Emptied`n", logFilePath, "UTF-8")
}

GetOption(options, key, defaultValue := "") {
    if (IsObject(options) && Type(options) = "Object" && options.HasOwnProp(key)) {
        return options.%key%
    }
    return defaultValue
}

EnsureParentDir(filePath) {
    SplitPath(filePath, , &dirPath)
    if (dirPath != "" && !DirExist(dirPath)) {
        DirCreate(dirPath)
    }
}

FormatLogValue(value) {
    valueType := Type(value)

    if (value is Error) {
        return FormatException(value)
    }

    if (valueType = "Array") {
        parts := []
        for item in value {
            parts.Push(FormatLogValue(item))
        }
        return "[" . JoinStrings(parts, ", ") . "]"
    }

    if (valueType = "Map") {
        parts := []
        for key, item in value {
            parts.Push(String(key) . ": " . FormatLogValue(item))
        }
        return "Map{" . JoinStrings(parts, ", ") . "}"
    }

    if (IsObject(value)) {
        return "<" . valueType . ">"
    }

    return String(value)
}

FormatException(err) {
    filePart := ""
    linePart := ""

    if (err.File != "") {
        filePart := " | file=" . err.File
    }
    if (err.Line != "") {
        linePart := " | line=" . err.Line
    }

    return err.Message . filePart . linePart
}

JoinStrings(values, separator := ", ") {
    result := ""
    for index, value in values {
        if (index > 1) {
            result .= separator
        }
        result .= value
    }
    return result
}
