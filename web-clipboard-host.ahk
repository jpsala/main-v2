; ===================================================================
; Web Clipboard host sender
; Ctrl+Shift+F1 sends currently selected text to the configured room and deletes it.
; Ctrl+F1 selects all first, then sends/deletes the selected text.
; ===================================================================

global WebClipboardHostBaseUrl := "https://web-clipboard.jpsala.workers.dev"
global WebClipboardHostLogFile := A_Temp . "\web-clipboard-host.log"
global WebClipboardComposerGui := false
global WebClipboardComposerReady := false

^+F1:: SendSelectedToWebClipboardAndDelete()

^+F2:: OpenWebClipboardSender()

OpenWebClipboardSender() {
    return ShowWebClipboardComposer()
}

^F1:: {
    Send("^a")
    Sleep(150)
    SendSelectedToWebClipboardAndDelete()
}

SendSelectedToWebClipboard() {
    text := GetSelectedTextForWebClipboard()
    return SendTextToWebClipboard(text, "", "No hay texto seleccionado para enviar")
}

SendTextToWebClipboard(text, roomOverride := "", emptyMessage := "No hay texto para enviar") {
    global WebClipboardHostLogFile

    room := roomOverride ? SetWebClipboardHostRoom(roomOverride) : GetWebClipboardHostRoom()
    if (!room)
        return false

    if (!text) {
        msg(emptyMessage, { seconds: 2 })
        return false
    }

    if (StrPut(text, "UTF-8") > 64 * 1024) {
        msg("Texto demasiado grande para web-clipboard (64 KB max)", { seconds: 4 })
        return false
    }

    nodePath := GetWebClipboardNodePath()
    if (!nodePath) {
        msg("No encontre node.exe para enviar web-clipboard", { seconds: 4 })
        return false
    }

    senderPath := A_ScriptDir . "\tools\web-clipboard-send.mjs"
    if (!FileExist(senderPath)) {
        msg("No encontre " . senderPath, { seconds: 4 })
        return false
    }

    textPath := A_Temp . "\web-clipboard-host-send-" . A_TickCount . ".txt"
    FileAppend(text, textPath, "UTF-8")

    baseUrl := GetWebClipboardHostBaseUrl()
    command := '"' . nodePath . '" "' . senderPath . '" --room "' . room . '" --textPath "' . textPath . '" --baseUrl "' . baseUrl . '" --logPath "' . WebClipboardHostLogFile . '"'

    try {
        Run(command, A_ScriptDir, "Hide")
        msg("Enviado a sala " . room, { seconds: 1 })
        SetTimer(() => DeleteWebClipboardTempFile(textPath), -10000)
        return true
    } catch Error as e {
        msg("No pude enviar web-clipboard: " . e.Message, { seconds: 5 })
        DeleteWebClipboardTempFile(textPath)
        return false
    }
}

SendSelectedToWebClipboardAndDelete() {
    if (SendSelectedToWebClipboard())
        SendEvent("{Delete}")
}

GetWebClipboardHostRoom() {
    global WebClipboardHostBaseUrl

    room := IniRead(A_ScriptDir . "\config.ini", "web-clipboard", "room", "")
    room := NormalizeWebClipboardHostRoom(room)

    if (room)
        return room

    result := InputBox("Sala alfanumerica", "Web Clipboard Host", "w360 h130")
    if (result.Result != "OK")
        return ""

    room := NormalizeWebClipboardHostRoom(result.Value)
    if (!room) {
        msg("Sala invalida. Usa solo letras y numeros.", { seconds: 4 })
        return ""
    }

    IniWrite(room, A_ScriptDir . "\config.ini", "web-clipboard", "room")
    IniWrite(GetWebClipboardHostBaseUrl(), A_ScriptDir . "\config.ini", "web-clipboard", "base_url")
    return room
}

SetWebClipboardHostRoom(room) {
    room := NormalizeWebClipboardHostRoom(room)
    if (!room) {
        msg("Sala invalida. Usa solo letras y numeros.", { seconds: 4 })
        return ""
    }

    IniWrite(room, A_ScriptDir . "\config.ini", "web-clipboard", "room")
    IniWrite(GetWebClipboardHostBaseUrl(), A_ScriptDir . "\config.ini", "web-clipboard", "base_url")
    return room
}

GetWebClipboardHostBaseUrl() {
    global WebClipboardHostBaseUrl
    return IniRead(A_ScriptDir . "\config.ini", "web-clipboard", "base_url", WebClipboardHostBaseUrl)
}

GetSelectedTextForWebClipboard() {
    savedClipboard := ClipboardAll()
    A_Clipboard := ""

    try {
        Send("^c")
        if (!ClipWait(0.8))
            return ""
        return A_Clipboard
    } finally {
        Sleep(50)
        A_Clipboard := savedClipboard
    }
}

NormalizeWebClipboardHostRoom(room) {
    room := Trim(String(room))
    return StrLower(RegExReplace(SubStr(room, 1, 64), "[^a-zA-Z0-9]", ""))
}

DeleteWebClipboardTempFile(path) {
    try {
        if FileExist(path)
            FileDelete(path)
    }
}

GetWebClipboardNodePath() {
    for _, path in [
        "C:\Program Files\nodejs\node.exe",
        EnvGet("LOCALAPPDATA") . "\Programs\nodejs\node.exe"
    ] {
        if (path && FileExist(path))
            return path
    }

    try {
        shell := ComObject("WScript.Shell")
        exec := shell.Exec(A_ComSpec . " /c where node.exe")
        while (exec.Status = 0)
            Sleep(20)
        firstLine := Trim(exec.StdOut.ReadLine())
        if (firstLine && FileExist(firstLine))
            return firstLine
    }

    return ""
}

ShowWebClipboardComposer(prefill := "") {
    global WebClipboardComposerGui, WebClipboardComposerReady

    if (WebClipboardComposerGui) {
        try {
            WebClipboardComposerGui.Show()
            WinActivate(WebClipboardComposerGui.hwnd)
            WebClipboardComposerSendState(prefill)
            WebClipboardComposerFocusSoon()
            return true
        } catch {
            WebClipboardComposerGui := false
        }
    }

    WebClipboardComposerReady := false
    try {
        dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
        WebClipboardComposerGui := WebViewGui("+Resize -Caption +AlwaysOnTop", "Web Clipboard Sender",, {DllPath: dllPath, DefaultWidth: 640, DefaultHeight: 420})
        WebClipboardComposerGui.BackColor := "101622"
        WebClipboardComposerGui.OnEvent("Close", (*) => CloseWebClipboardComposer())
        WebClipboardComposerGui.OnEvent("Escape", (*) => CloseWebClipboardComposer())
        WebClipboardComposerGui.Control.wv.add_WebMessageReceived(WebClipboardComposerHandleMessage)
        WebClipboardComposerGui.Control.wv.add_NavigationCompleted(WebClipboardComposerNavigationCompleted)
        WebClipboardComposerGui.Navigate("ui/web-clipboard-compose.html")
        WebClipboardComposerGui.Show("w640 h420 Hide")
        WebViewWindowStateRestoreOrCenter(WebClipboardComposerGui, "webClipboardComposer", 640, 420, true, true)
        WebClipboardComposerGui.Show()
        WinActivate(WebClipboardComposerGui.hwnd)
        WebClipboardComposerSendState(prefill)
        WebClipboardComposerFocusSoon()
        return true
    } catch Error as e {
        WebClipboardComposerGui := false
        MsgBox("Error creando Web Clipboard Sender: " . e.Message, "Web Clipboard", "Icon!")
        return false
    }
}

WebClipboardComposerNavigationCompleted(wv, args) {
    global WebClipboardComposerReady
    WebClipboardComposerReady := true
    WebClipboardComposerSendState()
    WebClipboardComposerFocusSoon()
}

WebClipboardComposerFocusSoon() {
    SetTimer(WebClipboardComposerFocus, -80)
    SetTimer(WebClipboardComposerFocus, -250)
    SetTimer(WebClipboardComposerFocus, -600)
}

WebClipboardComposerFocus() {
    global WebClipboardComposerGui
    if (!WebClipboardComposerGui || !WinExist("ahk_id " . WebClipboardComposerGui.Hwnd))
        return

    try {
        WinActivate(WebClipboardComposerGui.Hwnd)
        WebClipboardComposerGui.Control.Focus()
        WebClipboardComposerGui.Control.ExecuteScriptAsync("window.focus(); const text = document.querySelector('#text'); if (text) text.focus();")
    }

    try {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&oldX, &oldY)
        WinGetPos(&x, &y, &w, &h, "ahk_id " . WebClipboardComposerGui.Hwnd)
        MouseClick("Left", x + (w // 2), y + (h // 2), 1, 0)
        MouseMove(oldX, oldY, 0)
        CoordMode("Mouse", "Window")
    }
}

WebClipboardComposerHandleMessage(wv, args) {
    global WebClipboardComposerGui
    try {
        json := args.WebMessageAsJson
        data := JsonLoad(&json)
        action := data.Has("action") ? data["action"] : ""

        switch action {
            case "ready":
                WebClipboardComposerSendState()
            case "send":
                text := data.Has("text") ? data["text"] : ""
                room := data.Has("room") ? data["room"] : ""
                ok := SendTextToWebClipboard(text, room)
                WebClipboardComposerSendResult(ok, ok ? "Enviado" : "No se pudo enviar")
            case "minimize":
                if (WebClipboardComposerGui)
                    WebClipboardComposerGui.Minimize()
            case "close":
                CloseWebClipboardComposer()
        }
    } catch Error as e {
        log("Web clipboard composer message error", e.Message)
        WebClipboardComposerSendResult(false, e.Message)
    }
}

WebClipboardComposerSendState(prefill := "") {
    global WebClipboardComposerGui, WebClipboardComposerReady
    if (!WebClipboardComposerGui || !WebClipboardComposerReady)
        return

    state := Map(
        "action", "state",
        "room", IniRead(A_ScriptDir . "\config.ini", "web-clipboard", "room", ""),
        "baseUrl", GetWebClipboardHostBaseUrl(),
        "hotkey", "Ctrl+Shift+F2",
        "prefill", prefill
    )
    try WebClipboardComposerGui.Control.wv.PostWebMessageAsJson(JsonDump(state))
    try WebClipboardComposerGui.Control.ExecuteScriptAsync("window.focus(); const text = document.querySelector('#text'); if (text) text.focus();")
}

WebClipboardComposerSendResult(ok, message) {
    global WebClipboardComposerGui, WebClipboardComposerReady
    if (!WebClipboardComposerGui || !WebClipboardComposerReady)
        return

    payload := Map("action", "sendResult", "ok", ok ? true : false, "message", message)
    try WebClipboardComposerGui.Control.wv.PostWebMessageAsJson(JsonDump(payload))
}

CloseWebClipboardComposer() {
    global WebClipboardComposerGui, WebClipboardComposerReady
    if (WebClipboardComposerGui) {
        try WebViewWindowStateSave(WebClipboardComposerGui.Hwnd)
        try WebViewWindowStateForget(WebClipboardComposerGui.Hwnd)
        try WebClipboardComposerGui.Destroy()
    }
    WebClipboardComposerGui := false
    WebClipboardComposerReady := false
}
