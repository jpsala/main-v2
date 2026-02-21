; CopyQ Integration Functions for AutoHotkey v2
; Include this file in your scripts to add CopyQ functionality

; CopyQ executable path
global copyqPath := "C:\tools\copyq\copyq.exe"

; Helper function to run CopyQ commands and return output
RunCopyQ(command) {
    global copyqPath
    shell := ComObject("WScript.Shell")
    exec := shell.Exec('"' . copyqPath . '" ' . command)
    output := exec.StdOut.ReadAll()
    return Trim(output, "`r`n")
}

; Get all available CopyQ tabs
GetCopyQTabs() {
    return RunCopyQ("tab")
}

; Get current item data from CopyQ
GetCurrentCopyQItem() {
    return RunCopyQ("read 0")
}

; Get current item notes
GetCurrentCopyQNotes() {
    return RunCopyQ("read 0 application/x-copyq-item-notes")
}

; Get current item tags
GetCurrentCopyQTags() {
    return RunCopyQ("read 0 application/x-copyq-tags")
}

; Update notes for the current item
UpdateCopyQNotes(notes) {
    timestamp := A_YYYY "-" A_MM "-" A_DD " " A_Hour ":" A_Min ":" A_Sec
    fullNotes := "#" . notes . " (" . timestamp . ")"
    RunCopyQ("set 0 application/x-copyq-item-notes " . '"' . fullNotes . '"')
    return fullNotes
}

; Alias for backward compatibility
AddCopyQNotes(notes) {
    return UpdateCopyQNotes(notes)
}

; Switch to a specific tab
SwitchCopyQTab(tabName) {
    RunCopyQ("tab " . '"' . tabName . '"')
    return tabName
}

; Return to clipboard tab
ReturnToClipboardTab() {
    global copyqPath
    RunWait(copyqPath " tab &clipboard",, "Hide")
    return "&clipboard"
}

