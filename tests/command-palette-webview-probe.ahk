#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(CommandPaletteWebViewProbeUnhandledError)

#Include ..\lib\chord-hotkeys.ahk
#Include ..\lib\json.ahk
#Include ..\menus.ahk
#Include ..\command-palette-catalog.ahk
#Include ..\lib\WebViewToo.ahk

global COMMAND_PALETTE_WEBVIEW_READY := false
global COMMAND_PALETTE_WEBVIEW_ACTION := ""

try {
    CommandPaletteWebViewProbeRun()
    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    CommandPaletteWebViewProbeFail(e)
}

CommandPaletteWebViewProbeRun() {
    global COMMAND_PALETTE_ACTIONS, COMMAND_PALETTE_CATALOG, COMMAND_PALETTE_WEBVIEW_ACTION, COMMAND_PALETTE_WEBVIEW_READY

    SetWorkingDir(A_ScriptDir . "\..")
    CommandPaletteBuildCatalog()
    defaultStateJson := JsonDump(Map("catalog", COMMAND_PALETTE_CATALOG, "levelsPerPage", 0, "groupsFirst", false))
    drilldownStateJson := JsonDump(Map("catalog", COMMAND_PALETTE_CATALOG, "levelsPerPage", 1, "groupsFirst", false))
    dllPath := A_WorkingDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
    paletteGui := WebViewGui("-Caption +ToolWindow", "Command Palette Probe",, {DllPath: dllPath, DefaultWidth: 760, DefaultHeight: 540})
    try {
        paletteGui.Control.wv.add_NavigationCompleted(CommandPaletteWebViewProbeNavigationCompleted)
        paletteGui.Control.wv.add_WebMessageReceived(CommandPaletteWebViewProbeMessageReceived)
        paletteGui.Show("NoActivate x-10000 y-10000 w760 h540")
        paletteGui.Navigate("ui/command-palette.html")
        start := A_TickCount
        while (!COMMAND_PALETTE_WEBVIEW_READY && A_TickCount - start < 3000)
            Sleep(20)
        CommandPaletteWebViewProbeAssert(COMMAND_PALETTE_WEBVIEW_READY, "WebView navigation")

        pageState := paletteGui.Control.ExecuteScript("document.title + '|' + typeof window.setPaletteState + '|' + location.href")
        paletteGui.Control.ExecuteScript("window.setPaletteState(" . defaultStateJson . ");")
        resultCount := "0"
        start := A_TickCount
        while (resultCount = "0" && A_TickCount - start < 2000) {
            Sleep(25)
            resultCount := paletteGui.Control.ExecuteScript("document.querySelectorAll('.result').length")
        }
        CommandPaletteWebViewProbeAssert(resultCount = COMMAND_PALETTE_ACTIONS.Count, "rendered action count, got " . resultCount . "; page=" . pageState)

        sourceText := paletteGui.Control.ExecuteScript("document.querySelector('#source-count').textContent")
        CommandPaletteWebViewProbeAssert(InStr(sourceText, "commands"), "catalog count footer")

        paletteGui.Control.ExecuteScript("window.setPaletteState(" . drilldownStateJson . ");")
        groupCount := paletteGui.Control.ExecuteScript("document.querySelectorAll('.group-chevron').length")
        CommandPaletteWebViewProbeAssert(groupCount != "0", "drill-down group rows")

        paletteGui.Control.ExecuteScript("postToAHK({ action: 'cancel' });")
        start := A_TickCount
        while (COMMAND_PALETTE_WEBVIEW_ACTION = "" && A_TickCount - start < 1000)
            Sleep(20)
        CommandPaletteWebViewProbeAssert(COMMAND_PALETTE_WEBVIEW_ACTION = "cancel", "WebView to AHK bridge")
    } finally {
        paletteGui.Destroy()
    }
}

CommandPaletteWebViewProbeNavigationCompleted(wv, args) {
    global COMMAND_PALETTE_WEBVIEW_READY
    COMMAND_PALETTE_WEBVIEW_READY := true
}

CommandPaletteWebViewProbeMessageReceived(wv, args) {
    global COMMAND_PALETTE_WEBVIEW_ACTION
    message := args.WebMessageAsJson
    payload := JsonLoad(&message)
    if payload.Has("action")
        COMMAND_PALETTE_WEBVIEW_ACTION := payload["action"]
}

CommandPaletteWebViewProbeAssert(condition, label) {
    if !condition
        throw Error("FAIL: " . label)
}

CommandPaletteWebViewProbeFail(errorValue) {
    try FileAppend(errorValue.Message . "`n" . errorValue.Stack . "`n", "**")
    ExitApp(1)
}

CommandPaletteWebViewProbeUnhandledError(thrown, mode) {
    try FileAppend("UNHANDLED " . mode . ": " . thrown.Message . "`n" . thrown.Stack . "`n", "**")
    ExitApp(1)
    return true
}
