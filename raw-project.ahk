;===============================================================================
; RAW WhatsApp project tools
; Tray actions and WebView status window for C:\dev\WhatsApp.
;===============================================================================

#Include ".\lib\WebViewToo.ahk"

global RAW_PROJECT_GUI := false
global RAW_PROJECT_READY := false
global RAW_CLIENT_GUI := false
global RAW_CLIENT_READY := false
global RAW_PROJECT_ROOT := "C:\dev\WhatsApp"
global RAW_PROJECT_PORT := 5173
global RAW_PROJECT_LOG := A_ScriptDir . "\raw-project.log"

RawProjectGetAccount() {
    try {
        return IniRead("config.ini", "whatsapp", "account", "ro")
    } catch {
        return "ro"
    }
}

RawProjectSetAccount(account) {
    try {
        IniWrite(account, "config.ini", "whatsapp", "account")
    }
    return account
}

RawProjectGetTask() {
    account := RawProjectGetAccount()
    return "WhatsAppAssistant-" . (account = "jp" ? "JP" : "Ro") . "-Watch"
}

RawProjectGetLabel() {
    account := RawProjectGetAccount()
    return account = "jp" ? "JP" : "Ro"
}

RawProjectIcon(name) {
    return A_ScriptDir . "\ui\icons\" . name . ".png"
}

RawProjectClientUrl() {
    global RAW_PROJECT_PORT
    return "http://127.0.0.1:" . RAW_PROJECT_PORT . "/?account=" . RawProjectGetAccount()
}

ShowRawClientWindow() {
    global RAW_CLIENT_GUI, RAW_CLIENT_READY
    RawProjectLog("ShowRawClientWindow called")

    if (RAW_CLIENT_GUI) {
        try {
            RAW_CLIENT_GUI.Show()
            WinActivate(RAW_CLIENT_GUI.Hwnd)
            RawClientSendState()
            RawProjectLog("ShowRawClientWindow reused existing window")
            return true
        } catch {
            RAW_CLIENT_GUI := false
            RawProjectLog("ShowRawClientWindow existing window invalid")
        }
    }

    RAW_CLIENT_READY := false
    try {
        dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
        RawProjectLog("Creating WebViewGui for client")
        RAW_CLIENT_GUI := WebViewGui("+Resize -Caption", "WhatsApp " . RawProjectGetLabel() . " Client",, {DllPath: dllPath, DefaultWidth: 1180, DefaultHeight: 760})
        RAW_CLIENT_GUI.BackColor := "0B141A"
        RAW_CLIENT_GUI.OnEvent("Close", (*) => CloseRawClientWindow())
        RAW_CLIENT_GUI.OnEvent("Escape", (*) => CloseRawClientWindow())
        RAW_CLIENT_GUI.Control.wv.add_WebMessageReceived(RawClientHandleMessage)
        RAW_CLIENT_GUI.Control.wv.add_NavigationCompleted(RawClientNavigationCompleted)
        RAW_CLIENT_GUI.Navigate("ui/whatsapp-ro-client.html")
        RAW_CLIENT_GUI.Show("w1180 h760 Hide")
        WebViewWindowStateRestoreOrCenter(RAW_CLIENT_GUI, "whatsappRoClient", 1180, 760, true, true)
        RAW_CLIENT_GUI.Show()
        WinActivate(RAW_CLIENT_GUI.Hwnd)
        SetTimer(RawProjectEnsureAppServer, -100)
        RawProjectLog("Client window shown")
        return true
    } catch Error as e {
        RAW_CLIENT_GUI := false
        RawProjectLog("ShowRawClientWindow error: " . e.Message)
        MsgBox("Error creando WhatsApp " . RawProjectGetLabel() . " Client: " . e.Message, "WhatsApp " . RawProjectGetLabel(), "Icon!")
        return false
    }
}

RawClientNavigationCompleted(wv, args) {
    global RAW_CLIENT_READY
    RAW_CLIENT_READY := true
    RawProjectLog("Client shell navigation completed")
    RawClientSendState()
}

RawClientHandleMessage(wv, args) {
    global RAW_CLIENT_GUI
    try {
        json := args.WebMessageAsJson
        data := JsonLoad(&json)
        action := data.Has("action") ? data["action"] : ""

        switch action {
            case "ready":
                RawClientSendState()
            case "reloadClient":
                RawProjectEnsureAppServer()
                RawClientSendState()
            case "openBrowser":
                RawProjectOpenDashboard()
            case "status":
                ShowRawProjectWindow()
            case "minimize":
                if (RAW_CLIENT_GUI)
                    RAW_CLIENT_GUI.Minimize()
            case "close":
                CloseRawClientWindow()
        }
    } catch Error as e {
        msg("WhatsApp " . RawProjectGetLabel() . " Client error: " . e.Message, { seconds: 4 })
    }
}

RawClientSendState() {
    global RAW_CLIENT_GUI, RAW_CLIENT_READY
    if (!RAW_CLIENT_GUI || !RAW_CLIENT_READY)
        return false

    serverRunning := RawProjectIsAppServerRunning()
    payload := Map(
        "action", "state",
        "url", RawProjectClientUrl(),
        "serverRunning", serverRunning
    )
    try RAW_CLIENT_GUI.Control.wv.PostWebMessageAsJson(JsonDump(payload))
    RawProjectLog("Client state sent serverRunning=" . (serverRunning ? "1" : "0"))
    return true
}

CloseRawClientWindow() {
    global RAW_CLIENT_GUI, RAW_CLIENT_READY
    if (RAW_CLIENT_GUI) {
        try WebViewWindowStateSave(RAW_CLIENT_GUI.Hwnd)
        try WebViewWindowStateForget(RAW_CLIENT_GUI.Hwnd)
        try RAW_CLIENT_GUI.Destroy()
    }
    RAW_CLIENT_GUI := false
    RAW_CLIENT_READY := false
}

ShowRawProjectWindow() {
    global RAW_PROJECT_GUI, RAW_PROJECT_READY

    if (RAW_PROJECT_GUI) {
        try {
            RAW_PROJECT_GUI.Show()
            WinActivate(RAW_PROJECT_GUI.Hwnd)
            RawProjectSendState()
            return true
        } catch {
            RAW_PROJECT_GUI := false
        }
    }

    RAW_PROJECT_READY := false
    try {
        dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
        RAW_PROJECT_GUI := WebViewGui("+Resize -Caption", "RAW WhatsApp Project",, {DllPath: dllPath, DefaultWidth: 860, DefaultHeight: 620})
        RAW_PROJECT_GUI.BackColor := "101820"
        RAW_PROJECT_GUI.OnEvent("Close", (*) => CloseRawProjectWindow())
        RAW_PROJECT_GUI.OnEvent("Escape", (*) => CloseRawProjectWindow())
        RAW_PROJECT_GUI.Control.wv.add_WebMessageReceived(RawProjectHandleMessage)
        RAW_PROJECT_GUI.Control.wv.add_NavigationCompleted(RawProjectNavigationCompleted)
        RAW_PROJECT_GUI.Navigate("ui/raw-project.html")
        RAW_PROJECT_GUI.Show("w860 h620 Hide")
        WebViewWindowStateRestoreOrCenter(RAW_PROJECT_GUI, "rawProject", 860, 620, true, true)
        RAW_PROJECT_GUI.Show()
        WinActivate(RAW_PROJECT_GUI.Hwnd)
        return true
    } catch Error as e {
        RAW_PROJECT_GUI := false
        MsgBox("Error creando RAW Project: " . e.Message, "RAW Project", "Icon!")
        return false
    }
}

RawProjectNavigationCompleted(wv, args) {
    global RAW_PROJECT_READY
    RAW_PROJECT_READY := true
    RawProjectSendState()
}

RawProjectHandleMessage(wv, args) {
    global RAW_PROJECT_GUI
    try {
        json := args.WebMessageAsJson
        data := JsonLoad(&json)
        action := data.Has("action") ? data["action"] : ""

        switch action {
            case "ready":
                RawProjectSendState()
            case "refresh":
                RawProjectSendState()
            case "startWatcher":
                RawProjectStartWatcher()
                RawProjectSendState("Watcher start requested")
            case "stopWatcher":
                RawProjectStopWatcher()
                RawProjectSendState("Watcher stopped")
            case "restartWatcher":
                RawProjectRestartWatcher()
                RawProjectSendState("Watcher restarted")
            case "openDashboard":
                RawProjectOpenDashboard()
            case "openProject":
                RawProjectOpenProjectFolder()
            case "openLogs":
                RawProjectOpenLogsFolder()
            case "runConfigCheck":
                RawProjectRunVisibleCommand("npm --prefix `"assistant`" run check", "RAW config check")
            case "openStatusTerminal":
                RawProjectOpenStatusTerminal()
            case "minimize":
                if (RAW_PROJECT_GUI)
                    RAW_PROJECT_GUI.Minimize()
            case "close":
                CloseRawProjectWindow()
        }
    } catch Error as e {
        RawProjectSendState("Error: " . e.Message)
    }
}

RawProjectSendState(message := "") {
    global RAW_PROJECT_GUI, RAW_PROJECT_READY
    if (!RAW_PROJECT_GUI || !RAW_PROJECT_READY)
        return false

    statusJson := RawProjectGetStatusJson(message)
    try RAW_PROJECT_GUI.Control.wv.PostWebMessageAsJson(statusJson)
    return true
}

CloseRawProjectWindow() {
    global RAW_PROJECT_GUI, RAW_PROJECT_READY
    if (RAW_PROJECT_GUI) {
        try WebViewWindowStateSave(RAW_PROJECT_GUI.Hwnd)
        try WebViewWindowStateForget(RAW_PROJECT_GUI.Hwnd)
        try RAW_PROJECT_GUI.Destroy()
    }
    RAW_PROJECT_GUI := false
    RAW_PROJECT_READY := false
}

RawProjectStartWatcher() {
    script := '$ErrorActionPreference = "Stop"' . "`r`n"
        . 'Start-ScheduledTask -TaskName "' . RawProjectGetTask() . '"' . "`r`n"
    RawProjectRunPowerShellHidden(script)
}

RawProjectStopWatcher() {
    account := RawProjectGetAccount()
    taskName := RawProjectGetTask()
    storeDir := account = "jp" ? "Juan" : "Ro"
    wacliPattern := account = "jp" ? "|wacli.exe.*stores\\\\wacli\\\\" . storeDir . " sync" : ""
    script := '$ErrorActionPreference = "SilentlyContinue"' . "`r`n"
        . 'Stop-ScheduledTask -TaskName "' . taskName . '"' . "`r`n"
        . "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'watch-account.ps1.*" . account . "|watch-sync.js " . account . "|stores\\\\" . storeDir . " sync" . wacliPattern . "' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }" . "`r`n"
    RawProjectRunPowerShellHidden(script)
}

RawProjectRestartWatcher() {
    RawProjectStopWatcher()
    Sleep(1200)
    RawProjectStartWatcher()
    Sleep(1200)
}

RawProjectOpenDashboard() {
    RawProjectEnsureAppServer()
    Run(RawProjectClientUrl())
}

RawProjectEnsureAppServer() {
    global RAW_PROJECT_ROOT
    RawProjectLog("Ensure app server")
    if (RawProjectIsAppServerRunning())
        return true

    script := '$ErrorActionPreference = "Stop"' . "`r`n"
        . '& "' . RAW_PROJECT_ROOT . '\assistant-app\scripts\start-app.ps1"' . "`r`n"
    RawProjectRunPowerShellHidden(script)
    loop 15 {
        if (RawProjectIsAppServerRunning()) {
            RawClientSendState()
            return true
        }
        Sleep(500)
    }
    RawClientSendState()
    return false
}

RawProjectLog(message) {
    global RAW_PROJECT_LOG
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") . " | " . message . "`n", RAW_PROJECT_LOG, "UTF-8")
}

RawProjectIsAppServerRunning() {
    global RAW_PROJECT_PORT
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", "http://127.0.0.1:" . RAW_PROJECT_PORT . "/", false)
        req.SetTimeouts(500, 500, 500, 1000)
        req.Send()
        return req.Status >= 200 && req.Status < 500
    } catch {
        return false
    }
}

RawProjectOpenProjectFolder() {
    global RAW_PROJECT_ROOT
    Run('"' . RAW_PROJECT_ROOT . '"')
}

RawProjectOpenLogsFolder() {
    global RAW_PROJECT_ROOT
    account := RawProjectGetAccount()
    logsDir := RAW_PROJECT_ROOT . "\assistant\accounts\" . account . "\logs"
    if (DirExist(logsDir))
        Run('"' . logsDir . '"')
    else
        msg("No encontre logs RAW/" . RawProjectGetLabel(), { seconds: 3 })
}

RawProjectOpenStatusTerminal() {
    global RAW_PROJECT_ROOT
    RawProjectRunVisibleCommand('& "assistant-app\scripts\status.ps1"', "RAW status")
}

RawProjectRunVisibleCommand(command, title := "RAW command") {
    global RAW_PROJECT_ROOT
    scriptPath := A_Temp . "\raw-project-terminal-" . A_Now . "-" . Random(1000, 9999) . ".ps1"
    scriptBody := '$ErrorActionPreference = "Stop"' . "`r`n"
        . 'Set-Location -LiteralPath "' . RAW_PROJECT_ROOT . '"' . "`r`n"
        . command . "`r`n"
    FileAppend(scriptBody, scriptPath, "UTF-8")

    try {
        Run('wt -d "' . RAW_PROJECT_ROOT . '" pwsh -NoExit -NoProfile -ExecutionPolicy Bypass -File "' . scriptPath . '"')
        return true
    } catch Error as e {
        MsgBox("No pude ejecutar " . title . "`n`n" . e.Message, "RAW Project", "IconError")
        return false
    }
}

RawProjectRunPowerShellHidden(script) {
    path := A_Temp . "\raw-project-" . A_Now . "-" . Random(1000, 9999) . ".ps1"
    FileAppend(script, path, "UTF-8")
    try {
        RunWait('pwsh -NoProfile -ExecutionPolicy Bypass -File "' . path . '"',, "Hide")
    } finally {
        try FileDelete(path)
    }
}

RawProjectGetStatusJson(message := "") {
    global RAW_PROJECT_ROOT, RAW_PROJECT_PORT
    account := RawProjectGetAccount()
    taskName := RawProjectGetTask()
    storeDir := account = "jp" ? "Juan" : "Ro"
    wacliPattern := account = "jp" ? "|wacli.exe.*stores\\\\wacli\\\\" . storeDir . " sync" : ""
    logDir := "assistant\accounts\" . account . "\logs"
    script := '$ErrorActionPreference = "SilentlyContinue"' . "`r`n"
        . '$port = ' . RAW_PROJECT_PORT . "`r`n"
        . '$taskName = "' . taskName . '"' . "`r`n"
        . '$root = "' . RAW_PROJECT_ROOT . '"' . "`r`n"
        . '$conn = Get-NetTCPConnection -LocalPort $port -State Listen | Select-Object -First 1' . "`r`n"
        . '$app = if ($conn) { Get-Process -Id $conn.OwningProcess } else { $null }' . "`r`n"
        . '$task = Get-ScheduledTask -TaskName $taskName' . "`r`n"
        . "$procs = @(Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'watch-account.ps1.*" . account . "|watch-sync.js " . account . "|stores\\\\" . storeDir . " sync" . wacliPattern . "' } | Select-Object ProcessId,Name,CommandLine)" . "`r`n"
        . "$launcherLog = Join-Path $root '" . logDir . "\launcher.log'" . "`r`n"
        . "$stdoutLog = Join-Path $root '" . logDir . "\watcher.stdout.log'" . "`r`n"
        . "$syncLog = Join-Path $root '" . logDir . "\sync.log'" . "`r`n"
        . '$payload = [ordered]@{' . "`r`n"
        . '  action = "state"' . "`r`n"
        . '  message = "' . RawProjectPsSingleLine(message) . '"' . "`r`n"
        . '  generatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")' . "`r`n"
        . '  root = $root' . "`r`n"
        . '  dashboardUrl = "http://127.0.0.1:$port"' . "`r`n"
        . '  app = [ordered]@{ running = [bool]$conn; pid = if ($app) { $app.Id } else { $null }; started = if ($app) { $app.StartTime.ToString("yyyy-MM-dd HH:mm:ss") } else { $null } }' . "`r`n"
        . '  watcher = [ordered]@{ taskName = $taskName; state = if ($task) { [string]$task.State } else { "NOT INSTALLED" }; processCount = $procs.Count }' . "`r`n"
        . '  processes = $procs' . "`r`n"
        . '  logs = [ordered]@{' . "`r`n"
        . '    launcher = if (Test-Path $launcherLog) { @(Get-Content $launcherLog -Tail 12) } else { @() }' . "`r`n"
        . '    stdout = if (Test-Path $stdoutLog) { @(Get-Content $stdoutLog -Tail 10) } else { @() }' . "`r`n"
        . '    sync = if (Test-Path $syncLog) { @(Get-Content $syncLog -Tail 10) } else { @() }' . "`r`n"
        . '  }' . "`r`n"
        . '}' . "`r`n"
        . '$payload | ConvertTo-Json -Depth 6 -Compress' . "`r`n"

    json := RawProjectRunPowerShellCapture(script, 6000)
    if (json = "")
        return '{"action":"state","message":"No pude leer status","generatedAt":"","app":{"running":false},"watcher":{"state":"UNKNOWN","processCount":0},"processes":[],"logs":{"launcher":[],"stdout":[],"sync":[]}}'
    return json
}

RawProjectRunPowerShellCapture(script, timeoutMs := 5000) {
    path := A_Temp . "\raw-project-status-" . A_Now . "-" . Random(1000, 9999) . ".ps1"
    outPath := A_Temp . "\raw-project-status-" . A_Now . "-" . Random(1000, 9999) . ".json"
    runnerPath := A_Temp . "\raw-project-status-runner-" . A_Now . "-" . Random(1000, 9999) . ".ps1"
    FileAppend(script, path, "UTF-8")
    runner := '$ErrorActionPreference = "SilentlyContinue"' . "`r`n"
        . '& "' . path . '" | Set-Content -LiteralPath "' . outPath . '" -Encoding UTF8' . "`r`n"
    FileAppend(runner, runnerPath, "UTF-8")
    try {
        RunWait('pwsh -NoProfile -ExecutionPolicy Bypass -File "' . runnerPath . '"',, "Hide")
        if (!FileExist(outPath))
            return ""
        return Trim(FileRead(outPath, "UTF-8"))
    } catch {
        return ""
    } finally {
        try FileDelete(path)
        try FileDelete(runnerPath)
        try FileDelete(outPath)
    }
}

RawProjectPsSingleLine(value) {
    text := String(value)
    text := StrReplace(text, "`r", " ")
    text := StrReplace(text, "`n", " ")
    text := StrReplace(text, "'", "''")
    text := StrReplace(text, '"', '`"')
    return text
}
