HandleMouseGestureQuickAction(event) {
    if (HandleOpenCodeGestures(event))
        return true

    if (HandleCodeGestures(event))
        return true

    if (HandleChromeGestures(event))
        return true

    if (HandleGlobalGestures(event))
        return true

    return false
}

HandleOpenCodeGestures(event) {
    if (event.window.exe != "OpenCode.exe")
        return false

    ; Used:
    ; event.triggerButton = "RButton" && event.gesture = "D" && event.window.exe = "OpenCode.exe" && MouseGestureEventMatchesAnyCell(event, 2, 2, "1,1") -> asdfasdf
    ; event.triggerButton = "RButton" && event.shapeName = "C" && RegExMatch(event.window.title, "OpenCode") -> OpenCode project command

    if (event.triggerButton = "RButton" && event.gesture = "D" && event.window.exe = "OpenCode.exe" && MouseGestureEventMatchesAnyCell(event, 2, 2, "1,1")) {
        ; TODO: add action
        ; MouseGestureQuickSend(event, "^w", "asdfasdf")
        ; SetTimer(() => Roa("app-alias", "app.exe"), -30)
        ; MouseGestureQuickHandled(event, "asdfasdf")
        ; return true
    }

    if (event.triggerButton = "RButton" && event.shapeName = "C" && RegExMatch(event.window.title, "OpenCode")) {
        MouseGestureQuickSend(event, "^+p", "OpenCode project command")
        return true
    }

    return false
}

HandleCodeGestures(event) {
    if (event.window.exe != "Code.exe")
        return false

    ; Used:
    ; event.triggerButton = "RButton" && event.gesture = "U_R" && RegExMatch(event.window.title, "Code") -> VS Code toggle sidebar
    ; event.triggerButton = "RButton" && event.gesture = "L" -> VS Code go to symbol
    ; event.triggerButton = "RButton" && event.shapeName = "C" -> VS Code quick open

    if (event.triggerButton = "RButton" && event.gesture = "U_R" && RegExMatch(event.window.title, "Code")) {
        MouseGestureQuickSend(event, "^b", "VS Code toggle sidebar")
        return true
    }

    if (event.triggerButton = "RButton" && event.gesture = "L") {
        MouseGestureQuickSend(event, "^+o", "VS Code go to symbol")
        return true
    }

    if (event.triggerButton = "RButton" && event.shapeName = "C") {
        MouseGestureQuickSend(event, "^p", "VS Code quick open")
        return true
    }

    return false
}

HandleChromeGestures(event) {
    if (event.window.exe != "chrome.exe")
        return false

    ; Used:
    ; event.triggerButton = "RButton" && event.shapeName = "hook" -> Browser back
    ; event.triggerButton = "MButton" && event.shapeName = "hook" -> Focus address bar

    if (event.triggerButton = "RButton" && event.shapeName = "hook") {
        MouseGestureQuickSend(event, "!{Left}", "Browser back")
        return true
    }

    if (event.triggerButton = "MButton" && event.shapeName = "hook") {
        MouseGestureQuickSend(event, "^l", "Focus address bar")
        return true
    }

    return false
}

HandleGlobalGestures(event) {
    ; Used:
    ; event.triggerButton = "RButton" && event.gesture = "U" && MouseGestureEventMatchesAnyCell(event, 8, 8, "8,3", "8,4", "8,5") -> Web Clipboard Sender
    ; event.triggerButton = "RButton" && event.gesture = "U" && MouseGestureEventMatchesAnyCell(event, 8, 8, "8,8") -> Send selected to web clipboard
    ; event.triggerButton = "RButton" && event.gesture = "D" && MouseGestureEventMatchesAnyCell(event, 4, 4, "4,1", "4,2", "4,3", "4,4") -> GoBottom
    ; event.triggerButton = "RButton" && event.gesture = "U" && MouseGestureEventMatchesAnyCell(event, 4, 4, "1,1", "1,2", "1,3", "1,4") -> GoTop
    ; event.triggerButton = "MButton" && event.gesture = "U" && event.sizeBucket = "medium" -> Open main browser
    ; event.triggerButton = "MButton" && event.gesture = "D" && (event.sizeBucket = "medium" || event.sizeBucket = "large") -> Minimize window
    ; event.shapeName = "C" && event.sizeBucket = "large" -> Open Spotify
    ; event.triggerButton = "RButton" && event.gesture = "D_R" -> Close tab/window
    ; event.triggerButton = "MButton" && event.gesture = "D_R" -> Close app/window
    ; event.triggerButton = "RButton" && event.gesture = "D" -> Open Code End Voice
    ; event.triggerButton = "RButton" && event.gesture = "U" -> Open Code Start Voice

    if (event.triggerButton = "RButton" && event.gesture = "D") {
        MouseGestureQuickSend(event, "^{End}", "GoBottom")
        return true
    }

    if (event.triggerButton = "RButton" && event.gesture = "U" && MouseGestureEventMatchesAnyCell(event, 8, 8, "8,8")) {
        SetTimer(() => SendSelectedToWebClipboardAndDelete(), -30)
        MouseGestureQuickHandled(event, "Send selected to web clipboard and delete")
        return true
    }

    if (event.triggerButton = "RButton" && event.gesture = "U" && MouseGestureEventMatchesAnyCell(event, 8, 8, "8,3", "8,4", "8,5")) {
        SetTimer(() => OpenWebClipboardSender(), -30)
        MouseGestureQuickHandled(event, "Web Clipboard Sender")
        return true
    }

    if (event.triggerButton = "RButton" && event.gesture = "U") {
        MouseGestureQuickSend(event, "^{Home}", "GoTop")
        return true
    }

    if (event.triggerButton = "MButton" && event.gesture = "U" && event.sizeBucket = "medium") {
        SetTimer(() => OpenMainBrowser(), -30)
        MouseGestureQuickHandled(event, "Open main browser")
        return true
    }

    if (event.triggerButton = "MButton" && event.gesture = "D") {
        SetTimer(() => WinMinimize("A"), -30)
        MouseGestureQuickHandled(event, "Minimize window")
        return true
    }

    if (event.shapeName = "C" && event.sizeBucket = "large") {
        if (event.triggerButton = "MButton") {
            SetTimer(() => Roa("spotify", "spotify.exe"), -30)
            MouseGestureQuickHandled(event, "Open Spotify")
            return true
        }

        if (event.triggerButton = "RButton") {
            MouseGestureQuickSend(event, "^p", "Open file palette")
            return true
        }
    }

    if (event.triggerButton = "RButton" && event.gesture = "D_R") {
        MouseGestureQuickSend(event, "^w", "Close tab/window")
        return true
    }

    if (event.triggerButton = "MButton" && event.gesture = "D_R") {
        MouseGestureQuickSend(event, "!{F4}", "Close app/window")
        return true
    }

    ; if (event.triggerButton = "RButton" && event.gesture = "D") {
    ;     SetTimer(() => MouseGestureQuickOpenCodeEndVoice(), -30)
    ;     MouseGestureQuickHandled(event, "Open Code End Voice")
    ;     return true
    ; }

    ; if (event.triggerButton = "RButton" && event.gesture = "U") {
    ;     SetTimer(() => MouseGestureQuickOpenCodeStartVoice(), -30)
    ;     MouseGestureQuickHandled(event, "Open Code Start Voice")
    ;     return true
    ; }


}

; *********************************************************
; Helpers
; *********************************************************

MouseGestureQuickSend(event, keys, label) {
    MouseGestureSendDeferred(keys)
    MouseGestureQuickHandled(event, label)
}

MouseGestureQuickHandled(event, label) {
    MouseGestureLog(
        "dispatch"
        . " | scope=quick-handler"
        . " | button=" . event.triggerButton
        . " | gesture=" . event.gesture
        . " | shape=" . event.shapeName
        . " | label=" . label
    )
    MouseGestureShowRuleFeedback(event, label)
}

MouseGestureQuickOpenCodeEndVoice() {
    msg('D')
    SendEvent("{Ctrl down}{Alt down}{Shift down}{F12 down}")
    Sleep(60)
    SendEvent("{F12 up}{Shift up}{Alt up}{Ctrl up}")
    Sleep(3000)
    Send("{Enter}")
}

MouseGestureQuickOpenCodeStartVoice() {
    msg('U')
    SendEvent("{Ctrl down}{Alt down}{Shift down}{F12 down}")
    Sleep(60)
    SendEvent("{F12 up}{Shift up}{Alt up}{Ctrl up}")
}
