; ===================================================================
; Menu action helpers — functions called by menu items in menus.ahk
; ===================================================================

; --- Tabby / terminal workspace ---

GetTabbyExe() {
    return FindFirstExistingPath([
        EnvGet("LOCALAPPDATA") . "\Programs\Tabby\Tabby.exe",
        A_ProgramFiles . "\Tabby\Tabby.exe",
        A_ProgramFiles . " (x86)\Tabby\Tabby.exe"
    ])
}

GetTabbyWorkspaceDir() {
    candidates := [
        JoinPath(GetDevRoot(), "tabby"),
        "C:\dev\Tabby",
        "C:\dev\tabby"
    ]

    for _, path in candidates {
        if (DirExist(path))
            return path
    }

    return JoinPath(GetDevRoot(), "tabby")
}

OpenTabbyApp() {
    tabbyExe := GetTabbyExe()
    if (!tabbyExe) {
        MsgBox("Tabby no encontrado en esta notebook/PC", "Tabby", "IconError")
        return false
    }

    devDir := GetDevRoot()
    if (!DirExist(devDir))
        devDir := "C:\dev"

    try {
        Run(QuoteCommandPath(tabbyExe) . ' open "' . devDir . '"', devDir)
        return true
    } catch Error as e {
        MsgBox("No pude abrir Tabby en " . devDir . "`n`n" . e.Message, "Tabby", "IconError")
        return false
    }
}

OpenTabbyWorkspaceFolder() {
    workspaceDir := GetTabbyWorkspaceDir()
    if (!DirExist(workspaceDir)) {
        MsgBox("No encontre workspace Tabby: " . workspaceDir, "Tabby", "IconError")
        return false
    }
    return OpenFolderInExplorer("tabby-workspace", [workspaceDir])
}

OpenTabbyWorkspaceInEditor() {
    return OpenRepoInEditor("tabby-workspace", "Tabby workspace", vscodeExe, "tabby")
}

OpenTabbySourceConfig() {
    workspaceDir := GetTabbyWorkspaceDir()
    return OpenFileWithCodeCli("Tabby config fuente", workspaceDir, JoinPath(workspaceDir, "configs\tabby.config.yaml"))
}

OpenTabbyLiveConfig() {
    liveDir := EnvGet("APPDATA") . "\tabby"
    return OpenFileWithCodeCli("Tabby config viva", liveDir, JoinPath(liveDir, "config.yaml"))
}

OpenTabbyLiveConfigFolder() {
    return OpenFolderInExplorer("tabby-live-config", [EnvGet("APPDATA") . "\tabby"])
}

RunTabbyWorkspaceCommand(command, label) {
    workspaceDir := GetTabbyWorkspaceDir()
    if (!DirExist(workspaceDir)) {
        MsgBox(label . ": no encontre " . workspaceDir, "Tabby", "IconError")
        return false
    }

    scriptPath := A_Temp . "\tabby-menu-" . A_Now . "-" . Random(1000, 9999) . ".ps1"
    scriptBody := '$ErrorActionPreference = "Stop"' . "`r`n"
        . 'Set-Location -LiteralPath "' . workspaceDir . '"' . "`r`n"
        . command . "`r`n"
    FileAppend(scriptBody, scriptPath, "UTF-8")

    terminalCmd := 'wt -d "' . workspaceDir . '" pwsh -NoLogo -NoProfile -NoExit -ExecutionPolicy Bypass -File "' . scriptPath . '"'
    try {
        Run(terminalCmd, workspaceDir)
        return true
    } catch Error as e {
        MsgBox("No pude ejecutar " . label . "`n`n" . e.Message, "Tabby", "IconError")
        return false
    }
}

RunTabbySyncConfig() {
    return RunTabbyWorkspaceCommand("bun run sync:config", "Tabby sync config")
}

RunTabbyVerifyConfig() {
    return RunTabbyWorkspaceCommand("bun run verify:tabby", "Tabby verify")
}

RunTabbyTerminalInWorkspace() {
    workspaceDir := GetTabbyWorkspaceDir()
    if (!DirExist(workspaceDir)) {
        MsgBox("No encontre workspace Tabby: " . workspaceDir, "Tabby", "IconError")
        return false
    }

    try {
        Run('wt -d "' . workspaceDir . '"', workspaceDir)
        return true
    } catch Error as e {
        MsgBox("No pude abrir terminal Tabby`n`n" . e.Message, "Tabby", "IconError")
        return false
    }
}

; --- Scrcpy ---

GetScrcpyLauncher() {
    global deviceSection
    launcher := IniRead("config.ini", deviceSection, "scrcpy_launcher", "")
    if (!launcher)
        launcher := IniRead("config.ini", "desktop", "scrcpy_launcher", "C:\tools\scrcpy\scrcpy-noconsole.vbs")

    if (!FileExist(launcher)) {
        msg("scrcpy launcher no encontrado: " . launcher, { seconds: 4 })
        return ""
    }
    return '"' . launcher . '"'
}

GetScrcpyTargetArg(deviceKey) {
    global deviceSection
    serial := IniRead("config.ini", deviceSection, deviceKey . "_serial", "")
    if (!serial)
        serial := IniRead("config.ini", "desktop", deviceKey . "_serial", "")
    return serial ? '--serial "' . serial . '"' : "--select-usb"
}

RunScrcpyTablet() {
    launcher := GetScrcpyLauncher()
    if (!launcher)
        return
    cmd := launcher . " " . GetScrcpyTargetArg("tablet") . " --turn-screen-off --stay-awake"
    Roa("scrcpy-tablet", cmd)
}

RunScrcpyPhone(maxSize) {
    launcher := GetScrcpyLauncher()
    if (!launcher)
        return
    quotedTitle := Chr(34) . "My phone" . Chr(34)
    cmd := launcher . " --no-power-on " . GetScrcpyTargetArg("phone") . " --turn-screen-off --stay-awake --window-title=" . quotedTitle . " --window-borderless -b 2M --max-fps=15 --max-size " . maxSize
    Roa("scrcpy-phone-" . maxSize . "px", cmd)
}

RunScrcpyWifi() {
    launcher := GetScrcpyLauncher()
    if (!launcher)
        return
    Roa("scrcpy-wifi", launcher . " -b 1M -m 1024")
}

; --- Display resolution ---

DisplayResolutionGetCurrent() {
    static ENUM_CURRENT_SETTINGS := -1
    static DM_SIZE := 156

    deviceMode := Buffer(DM_SIZE, 0)
    NumPut("UShort", DM_SIZE, deviceMode, 36)

    if !DllCall("EnumDisplaySettingsA", "Ptr", 0, "Int", ENUM_CURRENT_SETTINGS, "Ptr", deviceMode.Ptr, "Int") {
        msg("No pude leer la resolucion actual", { seconds: 4 })
        return false
    }

    return {
        width: NumGet(deviceMode, 108, "UInt"),
        height: NumGet(deviceMode, 112, "UInt"),
        bitsPerPel: NumGet(deviceMode, 104, "UInt"),
        frequency: NumGet(deviceMode, 120, "UInt")
    }
}

DisplayResolutionFormat(mode) {
    if !IsObject(mode)
        return ""
    frequencyText := mode.frequency ? " @ " . mode.frequency . "Hz" : ""
    return mode.width . "x" . mode.height . frequencyText
}

DisplayResolutionSet(width, height) {
    static ENUM_CURRENT_SETTINGS := -1
    static DM_SIZE := 156
    static DM_PELSWIDTH := 0x00080000
    static DM_PELSHEIGHT := 0x00100000
    static DISP_CHANGE_SUCCESSFUL := 0

    currentMode := DisplayResolutionGetCurrent()
    if !currentMode
        return false

    if (currentMode.width = width && currentMode.height = height) {
        msg("Resolucion actual: " . DisplayResolutionFormat(currentMode), { seconds: 2 })
        return true
    }

    deviceMode := Buffer(DM_SIZE, 0)
    NumPut("UShort", DM_SIZE, deviceMode, 36)

    if !DllCall("EnumDisplaySettingsA", "Ptr", 0, "Int", ENUM_CURRENT_SETTINGS, "Ptr", deviceMode.Ptr, "Int") {
        msg("No pude preparar el cambio de resolucion", { seconds: 4 })
        return false
    }

    NumPut("UInt", DM_PELSWIDTH | DM_PELSHEIGHT, deviceMode, 40)
    NumPut("UInt", width, deviceMode, 108)
    NumPut("UInt", height, deviceMode, 112)

    result := DllCall("ChangeDisplaySettingsA", "Ptr", deviceMode.Ptr, "UInt", 0, "Int")
    if (result = DISP_CHANGE_SUCCESSFUL) {
        msg("Resolucion: " . width . "x" . height, { seconds: 2 })
        return true
    }

    msg("No pude cambiar a " . width . "x" . height . " (" . result . ": " . DisplayResolutionResultLabel(result) . ")", { seconds: 5 })
    return false
}

DisplayResolutionResultLabel(result) {
    switch result {
        case 1:
            return "requiere reinicio"
        case -1:
            return "fallo general"
        case -2:
            return "modo no soportado"
        case -3:
            return "no se pudo escribir configuracion"
        case -4:
            return "flags invalidos"
        case -5:
            return "parametro invalido"
        case -6:
            return "DualView no soportado"
        default:
            return "codigo desconocido"
    }
}

DisplayResolutionSaveCurrentIfNeeded(targetWidth, targetHeight) {
    currentMode := DisplayResolutionGetCurrent()
    if !currentMode
        return false

    if (currentMode.width = targetWidth && currentMode.height = targetHeight)
        return true

    IniWrite(currentMode.width, "config.ini", "display-resolution-menu", "restore_width")
    IniWrite(currentMode.height, "config.ini", "display-resolution-menu", "restore_height")
    IniWrite(currentMode.frequency, "config.ini", "display-resolution-menu", "restore_frequency")
    return true
}

DisplayResolutionGetSaved() {
    width := Number(IniRead("config.ini", "display-resolution-menu", "restore_width", "0"))
    height := Number(IniRead("config.ini", "display-resolution-menu", "restore_height", "0"))
    frequency := Number(IniRead("config.ini", "display-resolution-menu", "restore_frequency", "0"))

    if (width <= 0 || height <= 0)
        return false

    return { width: width, height: height, frequency: frequency }
}

DisplayResolutionSet720() {
    if !DisplayResolutionSaveCurrentIfNeeded(1280, 720)
        return false
    return DisplayResolutionSet(1280, 720)
}

DisplayResolutionRestoreSaved() {
    savedMode := DisplayResolutionGetSaved()
    if !savedMode {
        msg("No hay resolucion guardada todavia", { seconds: 4 })
        return false
    }

    return DisplayResolutionSet(savedMode.width, savedMode.height)
}

DisplayResolutionToggle720() {
    currentMode := DisplayResolutionGetCurrent()
    if !currentMode
        return false

    if (currentMode.width = 1280 && currentMode.height = 720)
        return DisplayResolutionRestoreSaved()

    return DisplayResolutionSet720()
}

DisplayResolutionShowCurrent() {
    currentMode := DisplayResolutionGetCurrent()
    if !currentMode
        return false

    savedMode := DisplayResolutionGetSaved()
    savedText := savedMode ? " | guardada: " . DisplayResolutionFormat(savedMode) : ""
    msg("Actual: " . DisplayResolutionFormat(currentMode) . savedText, { seconds: 4 })
    return true
}

; --- Display topology ---

DisplayTopologyRun(displaySwitchArg, label) {
    displaySwitchExe := A_WinDir . "\System32\DisplaySwitch.exe"

    try {
        Run(QuoteCommandPath(displaySwitchExe) . " " . displaySwitchArg)
        msg("Pantallas: " . label, { seconds: 3 })
        return true
    } catch as err {
        msg("No pude cambiar pantallas: " . err.Message, { seconds: 5 })
        return false
    }
}

DisplayTopologyUseExternalOnly() {
    return DisplayTopologyRun("/external", "solo monitor 2")
}

DisplayTopologyExtend() {
    return DisplayTopologyRun("/extend", "dos monitores")
}

DisplayTopologyToggleExternalOnlyOrExtend() {
    try {
        activeMonitorCount := MonitorGetCount()
    } catch as err {
        msg("No pude leer monitores activos: " . err.Message, { seconds: 5 })
        return false
    }

    if (activeMonitorCount > 1)
        return DisplayTopologyUseExternalOnly()

    return DisplayTopologyExtend()
}

; --- Wispr Flow ---

RestartWisprFlow() {
    global wisprFlowExe
    processName := "Wispr Flow.exe"
    existingWisprHwnds := Map()

    for hwnd in WinGetList("ahk_exe " processName) {
        existingWisprHwnds[String(hwnd)] := true
    }

    if (ProcessExist(processName)) {
        Loop 5 {
            pid := ProcessExist(processName)
            if (!pid)
                break
            try ProcessClose(pid)
            Sleep(200)
        }
    }

    if (!FileExist(wisprFlowExe)) {
        msg("Wispr Flow no encontrado: " . wisprFlowExe, { seconds: 4 })
        return
    }

    try {
        Run('"' . wisprFlowExe . '"')
        CloseWisprStartupPopup()
        msg("Wispr Flow reiniciado", { seconds: 1 })
    } catch Error as e {
        msg("Error reiniciando Wispr Flow: " . e.Message, { seconds: 4 })
    }
}

CloseWisprStartupPopup() {
    deadline := A_TickCount + 3000
    while (A_TickCount < deadline) {
        hwnd := WinExist("Hub ahk_class Chrome_WidgetWin_1 ahk_exe Wispr Flow.exe")
        if hwnd {
            WinClose("ahk_id " hwnd)
            return true
        }
        Sleep(100)
    }
    return false
}

; --- Browser ---

QuoteBrowserExe(path) {
    if (!path)
        return ""
    return InStr(path, " ") ? '"' . path . '"' : path
}

GetMainBrowserLauncher() {
    global vivaldiWithMainProfile
    global browserWithChromeMainProfile
    global vivaldiExe
    global chromeExe

    if (vivaldiWithMainProfile)
        return vivaldiWithMainProfile
    if (browserWithChromeMainProfile)
        return browserWithChromeMainProfile
    if (vivaldiExe)
        return QuoteBrowserExe(vivaldiExe) . " "
    if (chromeExe)
        return QuoteBrowserExe(chromeExe) . " "
    return ""
}

GetBrowserLauncher(preferredLauncher := "") {
    return preferredLauncher ? preferredLauncher : GetMainBrowserLauncher()
}

OpenBrowserProfile(alias, preferredLauncher := "", bookmark := false) {
    launcher := GetBrowserLauncher(preferredLauncher)
    if (!launcher) {
        msg("No encontre un navegador configurado para " . alias, { seconds: 4 })
        return false
    }
    return Roa(alias, launcher, bookmark)
}

OpenUrlWithBrowser(alias, url, preferredLauncher := "", bookmark := false) {
    launcher := GetBrowserLauncher(preferredLauncher)
    if (!launcher) {
        try {
            Run(url)
            return true
        } catch Error as e {
            msg("No pude abrir la URL: " . e.Message, { seconds: 4 })
            return false
        }
    }
    return Roa(alias, RTrim(launcher) . " " . url, bookmark)
}

OpenChromeDebugCopy() {
    A_Clipboard := chromeWithDebugProfile
    Run(chromeWithDebugProfile)
}

OpenMainBrowser() {
    launcher := GetMainBrowserLauncher()
    if (!launcher) {
        msg("No encontre un navegador principal configurado", { seconds: 4 })
        return false
    }
    if (!Roa('vivaldi-main', launcher, '#f'))
        Run(launcher)
}

ConstelacionesRepoDir() {
    return "C:\dev\chat\constelaciones"
}

EnsureConstelacionesRepo(label := "Constelaciones") {
    repoDir := ConstelacionesRepoDir()
    packageJson := repoDir . "\package.json"
    if (!FileExist(packageJson)) {
        msg(label . ": no encontre " . packageJson, { seconds: 4 })
        return ""
    }
    return repoDir
}

RunConstelacionesCommand(command, label) {
    repoDir := EnsureConstelacionesRepo(label)
    if (!repoDir)
        return false

    scriptPath := A_Temp . "\constelaciones-menu-" . A_Now . "-" . Random(1000, 9999) . ".ps1"
    scriptBody := '$ErrorActionPreference = "Stop"' . "`r`n"
        . 'Set-Location -LiteralPath "' . repoDir . '"' . "`r`n"
        . command . "`r`n"
    FileAppend(scriptBody, scriptPath, "UTF-8")

    terminalCmd := 'wt -d "' . repoDir . '" pwsh -NoLogo -NoProfile -NoExit -ExecutionPolicy Bypass -File "' . scriptPath . '"'
    try {
        Run(terminalCmd, repoDir)
        return true
    } catch Error as e {
        MsgBox('No pude ejecutar ' . label . '`n`n' . e.Message, 'Constelaciones', 'IconError')
        return false
    }
}

RunConstelacionesPackageScript(scriptName) {
    return RunConstelacionesCommand("bun run " . scriptName, "bun run " . scriptName)
}

RunConstelacionesWebDev() {
    return RunConstelacionesPackageScript("dev")
}

RunConstelacionesPublicTunnel() {
    return RunConstelacionesCommand("cloudflared tunnel run paperclip-jpsala-dev", "Cloudflare tunnel turnos.jpsala.dev")
}

RunConstelacionesPublishControlled() {
    command := "$repo = 'C:\dev\chat\constelaciones'" . "`r`n"
        . "Start-Process -FilePath 'wt' -ArgumentList @('-d', $repo, 'pwsh', '-NoExit', '-NoProfile', '-Command', 'bun run dev')" . "`r`n"
        . "Start-Process -FilePath 'wt' -ArgumentList @('-d', $repo, 'pwsh', '-NoExit', '-NoProfile', '-Command', 'cloudflared tunnel run paperclip-jpsala-dev')" . "`r`n"
        . "Write-Host 'Constelaciones dev server and Cloudflare tunnel launched.'"
    return RunConstelacionesCommand(command, "Constelaciones publicar")
}

OpenConstelacionesLocal() {
    return OpenUrlWithBrowser("constelaciones-local", "http://localhost:3000")
}

OpenConstelacionesPublic() {
    return OpenUrlWithBrowser("constelaciones-public", "https://turnos.jpsala.dev")
}

OpenConstelacionesTerminal() {
    repoDir := EnsureConstelacionesRepo("Constelaciones terminal")
    if (!repoDir)
        return false
    try {
        Run('wt -d "' . repoDir . '"', repoDir)
        return true
    } catch Error as e {
        MsgBox('No pude abrir terminal de Constelaciones`n`n' . e.Message, 'Constelaciones', 'IconError')
        return false
    }
}

OpenConstelacionesRepoFolder() {
    repoDir := EnsureConstelacionesRepo("Constelaciones repo folder")
    if (!repoDir)
        return false
    try {
        Run('explorer.exe "' . repoDir . '"')
        return true
    } catch Error as e {
        MsgBox('No pude abrir carpeta de Constelaciones`n`n' . e.Message, 'Constelaciones', 'IconError')
        return false
    }
}

; --- Copicu / CopyQ-inspired clipboard app ---

CopicuRepoDir() {
    return "C:\dev\chat\copyq-tauri"
}

EnsureCopicuRepo(label := "Copicu") {
    repoDir := CopicuRepoDir()
    packageJson := repoDir . "\package.json"
    if (!FileExist(packageJson)) {
        msg(label . ": no encontre " . packageJson, { seconds: 4 })
        return ""
    }
    return repoDir
}

CopicuStopDevCommand() {
    repoDir := CopicuRepoDir()
    return "$repo = '" . repoDir . "'" . "`r`n"
        . "$exe = Join-Path $repo 'src-tauri\target\debug\copicu.exe'" . "`r`n"
        . "$targets = New-Object System.Collections.Generic.HashSet[int]" . "`r`n"
        . "Get-CimInstance Win32_Process | Where-Object {" . "`r`n"
        . "  ($_.Name -eq 'copicu.exe') -or" . "`r`n"
        . "  ($_.ExecutablePath -eq $exe) -or" . "`r`n"
        . "  (($_.Name -in @('node.exe','npm.exe','npm.cmd','tauri.exe','cargo.exe')) -and $_.CommandLine -and $_.CommandLine.Contains($repo))" . "`r`n"
        . "} | ForEach-Object { [void]$targets.Add([int]$_.ProcessId) }" . "`r`n"
        . "$viteOwner = (Get-NetTCPConnection -LocalPort 1420 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty OwningProcess)" . "`r`n"
        . "if ($viteOwner) { [void]$targets.Add([int]$viteOwner) }" . "`r`n"
        . "foreach ($id in $targets) {" . "`r`n"
        . "  if ($id -eq $PID) { continue }" . "`r`n"
        . "  try { Stop-Process -Id $id -Force -ErrorAction Stop } catch { Write-Warning $_.Exception.Message }" . "`r`n"
        . "}" . "`r`n"
        . "Start-Sleep -Milliseconds 500"
}

CopicuStartDevCommand() {
    return "npm run dev:restart"
}

RunCopicuCommand(command, label) {
    repoDir := EnsureCopicuRepo(label)
    if (!repoDir)
        return false

    scriptPath := A_Temp . "\copicu-menu-" . A_Now . "-" . Random(1000, 9999) . ".ps1"
    scriptBody := '$ErrorActionPreference = "Stop"' . "`r`n"
        . 'Set-Location -LiteralPath "' . repoDir . '"' . "`r`n"
        . command . "`r`n"
    FileAppend(scriptBody, scriptPath, "UTF-8")

    terminalCmd := 'wt -d "' . repoDir . '" pwsh -NoLogo -NoProfile -NoExit -ExecutionPolicy Bypass -File "' . scriptPath . '"'
    try {
        Run(terminalCmd, repoDir)
        msg(label . " enviado", { seconds: 2 })
        return true
    } catch Error as e {
        MsgBox('No pude ejecutar ' . label . '`n`n' . e.Message, 'Copicu', 'IconError')
        return false
    }
}

RunCopicuRestartDev() {
    return RunCopicuCommand("npm run dev:restart", "Copicu restart dev")
}

RunCopicuKillDev() {
    return RunCopicuCommand(CopicuStopDevCommand(), "Copicu kill dev")
}

OpenCopicuRepoFolder() {
    repoDir := EnsureCopicuRepo("Copicu repo folder")
    if (!repoDir)
        return false
    try {
        Run('explorer.exe "' . repoDir . '"')
        return true
    } catch Error as e {
        MsgBox('No pude abrir carpeta de Copicu`n`n' . e.Message, 'Copicu', 'IconError')
        return false
    }
}

OpenCopicuTerminal() {
    repoDir := EnsureCopicuRepo("Copicu terminal")
    if (!repoDir)
        return false
    try {
        Run('wt -d "' . repoDir . '"')
        return true
    } catch Error as e {
        MsgBox('No pude abrir terminal de Copicu`n`n' . e.Message, 'Copicu', 'IconError')
        return false
    }
}

RunCopicuBuild() {
    return RunCopicuCommand("npm run build", "Copicu build")
}

RunCopicuBuildAndRunInstaller() {
    command := "npm run tauri:build" . "`r`n"
        . "if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }" . "`r`n"
        . "$bundleDir = Join-Path (Get-Location) 'src-tauri\target\release\bundle\nsis'" . "`r`n"
        . "$installer = Get-ChildItem -LiteralPath $bundleDir -Filter '*-setup.exe' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1" . "`r`n"
        . "if (!$installer) { throw ('No encontre instalador en ' + $bundleDir) }" . "`r`n"
        . "Write-Host ('Running installer: ' + $installer.FullName)" . "`r`n"
        . "Start-Process -FilePath $installer.FullName"
    return RunCopicuCommand(command, "Copicu build installer and run")
}

RunCopicuCargoCheck() {
    command := "$env:CARGO_TARGET_DIR = Join-Path (Get-Location) 'target-codex-check'" . "`r`n"
        . "Set-Location -LiteralPath 'src-tauri'" . "`r`n"
        . "cargo check"
    return RunCopicuCommand(command, "Copicu cargo check")
}

RunCopicuVisualCheck() {
    return RunCopicuCommand("npm run visual:check", "Copicu visual checks")
}

; --- YouTube download ---

DownloadYouTubeVideoFromClipboard() {
    url := A_Clipboard
    if (!InStr(url, 'https://www.youtube.com/watch?') and !InStr(url, 'https://youtu.be') and !InStr(url, 'https://www.youtube.com/shorts/')) {
        MsgBox('Clipboard does not contain a valid YouTube video or shorts URL.`n`n' url, 'Invalid URL', 'IconWarning')
        return
    }
    command := 'c:\tools\ytd.bat "' . url . '"'
    try {
        Run(command)
    } catch Error as e {
        MsgBox('Failed to run YouTube video download command:`n' command '`n`nError: ' e.Message, 'Execution Error', 'IconError')
    }
}

DownloadYouTubeAudioFromClipboard() {
    url := A_Clipboard
    if (!InStr(url, 'https://www.youtube.com/watch?') and !InStr(url, 'https://youtu.be')) {
        MsgBox('Clipboard does not contain a valid YouTube URL for audio download.`n`n' url, 'Invalid URL', 'IconWarning')
        return
    }
    command := 'c:\tools\ytd-audio.bat "' . url . '"'
    try {
        Run(command)
    } catch Error as e {
        MsgBox('Failed to run YouTube audio download command:`n' command '`n`nError: ' e.Message, 'Execution Error', 'IconError')
    }
}

RunFixvoxDev() {
    repoDir := "C:\dev\fixvox"
    pwshScript := "$env:FIXVOX_SUPPRESS_STARTUP_DOCK='1'; $env:FIXVOX_SUPPRESS_STARTUP_ONBOARDING='1'; $env:FIXVOX_DISABLE_STARTUP_PICKER_PRELOAD='1'; $env:FIXVOX_DISABLE_STARTUP_SETTINGS_PRELOAD='1'; & bun scripts/dev-runtime-check.ts restart"
    launchCmd := "pwsh -NoProfile -WindowStyle Hidden -Command " . Chr(34) . pwshScript . Chr(34)
    if (Roa("fixvox", launchCmd, false, false, {
        launchMode: "background",
        workingDir: repoDir,
        runOptions: "Hide"
    })) {
        msg("Fixvox restart enviado", { seconds: 2 })
        return true
    }
    return false
}

RunFixvoxPackageScript(scriptName, runInstaller := false) {
    command := "bun run " . scriptName
    if (runInstaller)
        command .= "; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; " . FixvoxRunLatestInstallerCommand()
    return RunFixvoxDeployCommand(command, "bun run " . scriptName)
}

RunFixvoxPublishProdArtifacts() {
    command := "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/publish-windows-release.ps1 -DeployProduction -SkipProductionSecret; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; " . FixvoxRestartDevCommand()
    return RunFixvoxDeployCommand(command, "Publish installer and update artifacts")
}

RunFixvoxOtherPcReadyRelease() {
    command := "bun test src/app/backend/control-plane.test.ts proxy/src/control-plane-store.test.ts"
        . "; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }"
        . "; powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-proxy-admin.ps1"
        . "; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }"
        . "; bun run package:win"
        . "; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }"
        . "; $update = Get-Content -Raw -LiteralPath 'artifacts\stable-win-x64-update.json' | ConvertFrom-Json"
        . "; $tag = 'v' + $update.version"
        . "; gh release view $tag --repo jpsala/fixvox-releases --json url,assets"
        . "; Write-Host ('Installer URL: https://github.com/jpsala/fixvox-releases/releases/download/' + $tag + '/Fixvox-Installer.exe')"
    return RunFixvoxDeployCommand(command, "Other PC ready release")
}

RunFixvoxInstallerOnly() {
    command := "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-windows-installer.ps1 -SkipPublish; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; powershell -NoProfile -ExecutionPolicy Bypass -File scripts/open-windows-installer-location.ps1; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; " . FixvoxRestartDevCommand()
    return RunFixvoxDeployCommand(command, "Build installer locally only")
}

FixvoxRestartDevCommand() {
    return "Write-Host 'Restarting dev runtime after installer/release...'; bun scripts/restart-dev.ts"
}

RunFixvoxInstallerAndOpen() {
    command := "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-windows-installer-and-open.ps1; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; " . FixvoxRunLatestInstallerCommand()
    return RunFixvoxDeployCommand(command, "Build installer locally and open artifact folder")
}

RunFixvoxOpenInstallerFolder() {
    command := "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/open-windows-installer-location.ps1"
    return RunFixvoxDeployCommand(command, "Open latest Windows installer artifact")
}

RunFixvoxLatestInstaller() {
    return RunFixvoxDeployCommand(FixvoxRunLatestInstallerCommand(), "Run latest Windows installer")
}

FixvoxRunLatestInstallerCommand() {
    return "$installer = Get-ChildItem -Path 'artifacts\windows-installer','build\stable-win-x64' -Filter '*.exe' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if (!$installer) { throw 'No Windows installer .exe found' }; Write-Host ('Running installer: ' + $installer.FullName); Start-Process -FilePath $installer.FullName -Wait"
}

RunFixvoxProxyDeploy() {
    command := "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-proxy-admin.ps1"
    return RunFixvoxDeployCommand(command, "Deploy proxy admin")
}

RunFixvoxProxyDryRun() {
    command := "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-proxy-admin.ps1 -DryRun"
    return RunFixvoxDeployCommand(command, "Dry run proxy admin deploy")
}

RunFixvoxProxySecretOnly() {
    command := "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-proxy-admin.ps1 -SkipDeploy"
    return RunFixvoxDeployCommand(command, "Update proxy admin secret only")
}

RunFixvoxProdDryRun() {
    command := "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/publish-windows-release.ps1 -DeployProduction -DryRun"
    return RunFixvoxDeployCommand(command, "Dry run production release")
}

RunFixvoxFullLocalVerify() {
    command := "bun install; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; bun test; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-windows-installer.ps1 -SkipPublish; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; " . FixvoxRunLatestInstallerCommand()
    return RunFixvoxDeployCommand(command, "Install + test + local installer")
}

ShowFixvoxMenuDocs() {
    static docsGui := false
    htmlPath := BuildFixvoxMenuDocsHtml()
    dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"

    if !IsObject(docsGui) {
        docsGui := WebViewGui("+Resize", "Fixvox menu docs",, {DllPath: dllPath, DefaultWidth: 980, DefaultHeight: 720})
        docsGui.OnEvent("Close", (*) => docsGui.Hide())
    }

    docsGui.Navigate("file:///" . StrReplace(htmlPath, "\", "/"))
    docsGui.Show("w980 h720")
    try WinActivate("ahk_id " . docsGui.Hwnd)
    return true
}

BuildFixvoxMenuDocsHtml() {
    htmlPath := A_Temp . "\fixvox-menu-docs.html"
    docsHtml := ""
    docsHtml .= "<!doctype html><html><head><meta charset='utf-8'><title>Fixvox menu docs</title>"
    docsHtml .= "<style>"
    docsHtml .= "body{margin:0;background:#0d1117;color:#c9d1d9;font:14px/1.5 Segoe UI,system-ui,sans-serif;}"
    docsHtml .= "header{position:sticky;top:0;background:#010409;border-bottom:1px solid #30363d;padding:16px 22px;z-index:1;}"
    docsHtml .= "h1{font-size:18px;margin:0 0 4px;} h2{font-size:15px;margin:24px 0 10px;color:#58a6ff;}"
    docsHtml .= "main{padding:18px 22px 32px;} .hint{color:#8b949e;font-size:12px;}"
    docsHtml .= ".summary{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:10px;margin:0 0 18px;} .card{background:#161b22;border:1px solid #30363d;border-radius:10px;padding:10px 12px;} .card b{display:block;color:#f0f6fc;margin-bottom:4px;}"
    docsHtml .= "table{width:100%;border-collapse:collapse;background:#161b22;border:1px solid #30363d;border-radius:10px;overflow:hidden;margin-bottom:18px;}"
    docsHtml .= "th,td{border-bottom:1px solid #30363d;padding:9px 10px;text-align:left;vertical-align:top;} th{background:#21262d;color:#8b949e;font-size:11px;text-transform:uppercase;letter-spacing:.06em;} tr:last-child td{border-bottom:0;}"
    docsHtml .= "code{font-family:Cascadia Code,Consolas,monospace;font-size:12px;background:#0d1117;border:1px solid #30363d;border-radius:5px;padding:2px 5px;color:#79c0ff;}"
    docsHtml .= ".key{white-space:nowrap;color:#f0f6fc;} .label{font-weight:600;color:#f0f6fc;} .doc{color:#c9d1d9;} .command{color:#8b949e;}"
    fixvoxMenu := GetFixvoxMenuItem()
    timeoutText := GetMenuTimeoutText(fixvoxMenu)

    docsHtml .= "</style></head><body><header><h1>Fixvox Deploy / Release menu docs</h1><div class='hint'>Route: <code>Win+A</code> then <code>E</code>. This window is generated from the live menu data and does not run commands.</div></header><main>"
    docsHtml .= "<div class='summary'><div class='card'><b>Submenu timeout</b>" . HtmlEscape(timeoutText) . "</div><div class='card'><b>Installer auto-run</b>Installer-producing actions now run the newest generated <code>.exe</code> after a successful build/release.</div><div class='card'><b>Installer search paths</b><code>artifacts\\windows-installer</code><br><code>build\\stable-win-x64</code></div></div>"
    docsHtml .= "<h2>Fixvox actions</h2>"
    docsHtml .= BuildMenuDocsTable(GetFixvoxDocsItems(), "Win+A > e")
    docsHtml .= "<h2>Current full menu tree</h2>"
    docsHtml .= BuildMenuDocsTable(BuildAllMenuDocsItems(), "")
    docsHtml .= "</main></body></html>"

    if FileExist(htmlPath)
        FileDelete(htmlPath)
    FileAppend(docsHtml, htmlPath, "UTF-8")
    return htmlPath
}

GetMenuTimeoutText(menuItem) {
    if !IsObject(menuItem)
        return "default menu timeout"
    if (menuItem.HasOwnProp("idleTimeoutSeconds"))
        return menuItem.idleTimeoutSeconds . " seconds"
    if (menuItem.HasOwnProp("timeout"))
        return menuItem.timeout . " seconds"
    return "default menu timeout"
}

GetFixvoxMenuItem() {
    for _, item in GetMainSeqAOptions().items {
        if (item.HasOwnProp("key") && item.key = "e" && item.HasOwnProp("items"))
            return item
    }
    return false
}

GetFixvoxDocsItems() {
    fixvoxMenu := GetFixvoxMenuItem()
    if IsObject(fixvoxMenu)
        return BuildMenuDocsItems(fixvoxMenu.items, "Win+A > e")
    return []
}

BuildAllMenuDocsItems() {
    entries := []
    for _, root in [
        { prefix: "Win+A", options: GetMainSeqAOptions() },
        { prefix: "Win+W", options: GetMainSeqWOptions() },
        { prefix: "Win+C", options: GetMainSeqCOptions() },
        { prefix: "Win+``,", options: GetCopyQOptions() },
    ] {
        for _, entry in BuildMenuDocsItems(root.options.items, root.prefix)
            entries.Push(entry)
    }
    return entries
}

BuildMenuDocsItems(items, prefix) {
    entries := []
    for _, item in items {
        if (!IsObject(item) || !item.HasOwnProp("key"))
            continue
        keyPath := prefix . " > " . item.key
        label := item.HasOwnProp("label") ? item.label : item.key
        hasChildren := item.HasOwnProp("items") && IsObject(item.items)
        doc := item.HasOwnProp("doc") ? item.doc : (hasChildren ? "Submenu. Opens the listed child actions; it does not execute a command by itself." : "Runs the AutoHotkey action configured for this menu item.")
        command := item.HasOwnProp("command") ? item.command : (hasChildren ? "submenu" : "AHK closure/action")
        entries.Push({ keyPath: keyPath, label: label, doc: doc, command: command })
        if (hasChildren) {
            for _, child in BuildMenuDocsItems(item.items, keyPath)
                entries.Push(child)
        }
    }
    return entries
}

BuildMenuDocsTable(entries, fallbackPrefix) {
    if (!entries.Length)
        return "<p class='hint'>No menu entries found for " . HtmlEscape(fallbackPrefix) . ".</p>"
    html := "<table><thead><tr><th>Key path</th><th>Label</th><th>Does</th><th>Command/action</th></tr></thead><tbody>"
    for _, entry in entries {
        html .= "<tr>"
        html .= "<td class='key'><code>" . HtmlEscape(entry.keyPath) . "</code></td>"
        html .= "<td class='label'>" . HtmlEscape(entry.label) . "</td>"
        html .= "<td class='doc'>" . HtmlEscape(entry.doc) . "</td>"
        html .= "<td class='command'><code>" . HtmlEscape(entry.command) . "</code></td>"
        html .= "</tr>"
    }
    html .= "</tbody></table>"
    return html
}

HtmlEscape(value) {
    text := String(value)
    text := StrReplace(text, "&", "&amp;")
    text := StrReplace(text, "<", "&lt;")
    text := StrReplace(text, ">", "&gt;")
    text := StrReplace(text, '"', "&quot;")
    text := StrReplace(text, "'", "&#39;")
    return text
}

RunFixvoxDeployCommand(command, label) {
    repoDir := "C:\dev\fixvox"
    packageJson := repoDir . "\package.json"
    if (!FileExist(packageJson)) {
        msg("No encontre " . packageJson, { seconds: 4 })
        return false
    }

    scriptPath := A_Temp . "\fixvox-menu-" . A_Now . "-" . Random(1000, 9999) . ".ps1"
    scriptBody := '$ErrorActionPreference = "Stop"' . "`r`n"
        . 'Set-Location -LiteralPath "' . repoDir . '"' . "`r`n"
        . command . "`r`n"
    FileAppend(scriptBody, scriptPath, "UTF-8")

    terminalCmd := 'wt -d "' . repoDir . '" pwsh -NoExit -NoProfile -ExecutionPolicy Bypass -File "' . scriptPath . '"'
    try {
        Run(terminalCmd)
        return true
    } catch Error as e {
        MsgBox('No pude ejecutar ' . label . '`n`n' . e.Message, 'Deploy Fixvox', 'IconError')
        return false
    }
}
