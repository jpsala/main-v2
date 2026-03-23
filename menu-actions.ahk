; ===================================================================
; Menu action helpers — functions called by menu items in menus.ahk
; ===================================================================

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
