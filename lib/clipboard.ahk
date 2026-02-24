;===============================================================================
; CLIPBOARD MODULE
; Clipboard operations
;===============================================================================

ctrlC() {
    A_Clipboard := ""
    Send "^c"
    if (!ClipWait(0.5)) {
        MsgBox('Failed to copy item')
        return
    }
    return A_Clipboard
}

copyToClipboard(text) {
    A_Clipboard := ''
    A_clipboard := String(text)
    clipWait 100
    Sleep 80
}
