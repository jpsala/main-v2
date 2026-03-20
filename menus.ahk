; ===================================================================
; Apps
; ===================================================================
global vivaldiExe := "C:\Program Files\Vivaldi\Application\vivaldi.exe"
global cursorExe := "C:\Users\jpsal\AppData\Local\Programs\cursor\cursor.exe"
global xyplorerExe := "C:\tools\xyplorer-portable\XYplorer.exe"
global vscodeExe := "C:\Program Files\Microsoft VS Code\Code.exe"
global wisprFlowExe := "C:\Users\jpsal\AppData\Local\WisprFlow\Wispr Flow.exe"

; ===================================================================
; Generic menu action dispatch
; ===================================================================
BuildActionMap(items, prefix := "") {
    actionMap := Map()
    for _, item in items {
        if !IsObject(item) || !item.HasOwnProp("key")
            continue
        fullKey := prefix . item.key
        if (item.HasOwnProp("action"))
            actionMap[fullKey] := item.action
        if (item.HasOwnProp("items") && IsObject(item.items))
            for k, v in BuildActionMap(item.items, fullKey)
                actionMap[k] := v
    }
    return actionMap
}

RunMenuAction(actionMap, key) {
    if actionMap.Has(key)
        actionMap[key].Call()
}

; ===================================================================
; Menu A — Apps
; ===================================================================
GetMainSeqAOptions() {
    return {
        waitml: 1000,
        items: [
            { key: '#b', label: 'Show Bookmarks', chordKey: 'b', action: () => showBookmarks() },
            { key: 'c', label: 'SpeedCrunch', action: () => Roa('SpeedCrunch', 'C:\tools\speedcrunch\speedcrunch.exe') },
            { key: 'C', label: 'LibreOffice Calc', action: () => Roa('libreoffice-calc', 'C:\Program Files\LibreOffice\program\scalc.exe') },
            { key: 'f', label: 'File Explorer', action: () => Roa('file-explorer', 'C:\Windows\explorer.exe') },
            { key: 'M', label: 'Mixer', action: () => openMixer() },
            { key: 's', label: 'Spotify', action: () => Roa('spotify', 'spotify.exe') },
            { key: 'S', label: 'ShareX screenshots', action: () => Roa('sharex-folder', xyplorerExe . ' C:/Users/jpsal/Pictures/sharex') },
            { key: 'w', label: 'Restart Wispr Flow', action: () => RestartWisprFlow() },
            { key: 't', label: 'tablet/telegram/terminal', items: [
                { key: 't', label: 'Windows Terminal', action: () => Roa('windows-terminal', "C:\Program Files\WindowsApps\Microsoft.WindowsTerminal_1.23.20211.0_x64__8wekyb3d8bbwe\wt.exe") },
                { key: 'T', label: 'Telegram', action: () => Roa('telegram', '"C:\tools\Telegram\Telegram.exe"') },
                { key: 'a', label: 'Tablet', action: () => RunScrcpyTablet() },
                { key: 'p3', label: 'Phone 700px', chordPath: ['p', '3'], chordPathLabel: 'Phone', action: () => RunScrcpyPhone(700) },
                { key: 'p4', label: 'Phone 900px', chordPath: ['p', '4'], chordPathLabel: 'Phone', action: () => RunScrcpyPhone(900) },
            ] },
            { key: 'x', label: 'XYplorer', action: () => Roa('xyplorer', xyplorerExe) },
            { key: 'y', label: 'Window Spy', action: () => Roa('window-spy', 'C:\Program Files\AutoHotkey\UX\WindowSpy.ahk') },
        ]
    }
}

; --- Scrcpy helpers ---

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
        ; precise match: only the Hub popup window
        hwnd := WinExist("Hub ahk_class Chrome_WidgetWin_1 ahk_exe Wispr Flow.exe")
        if hwnd {
            WinClose("ahk_id " hwnd)   ; closes window only, not process
            return true
        }
        Sleep(100)
    }
    return false
}

; ===================================================================
; Menu W — Browser & Web
; ===================================================================
OpenChromeDebugCopy() {
    A_Clipboard := chromeWithDebugProfile
    Run(chromeWithDebugProfile)
}

OpenMainBrowser() {
    if (!Roa('vivaldi-main', vivaldiWithMainProfile, '#f'))
        Run(vivaldiWithMainProfile)
}

GetMainSeqWOptions() {
    return {
        waitml: 1000,
        items: [
            ; { key: '$', label: 'USD' },
            { key: 'a', label: 'AI', action: () => Roa('ai-project', cursorExe . ' c:\dev\ai') },
            ; { key: 'A', label: 'Amaia', action: () => Roa('amaia-project', cursorExe . ' c:\dev\amaia') },
            ; { key: 'b', label: 'Browser Books', action: () => Roa('vivaldi-books', vivaldiWithBooksProfile, '#b') },
            { key: 'c', label: 'Browser Carnival', action: () => Roa('chrome-carnival', vivaldiWithCarnivalProfile) },
            { key: '#c', label: 'chrome-main', chordKey: 'm', action: () => Roa('chrome-main', browserWithChromeMainProfile) },
            { key: 'd', label: 'Debug with chrome', chordHidden: true },
            ; { key: '#d', label: 'Chrome Debug', chordKey: 'x', action: () => OpenChromeDebugCopy() },
            { key: 'D', label: 'Debug with vivaldi', action: () => Run(vivaldiWithDebugProfile) },
            { key: 'f', label: 'Browser Main', action: () => OpenMainBrowser() },
            { key: 'd', label: 'Vivaldi debug', action: () => Run(vivaldiWithDebugProfile) },
            { key: 's', label: 'Sites', items: [
                { key: 'c', label: 'Google Calendar', action: () => Roa('google-calendar', vivaldiWithMainProfile . ' https://calendar.google.com/calendar/u/0/r') },
                ; { key: 'g', label: 'Gemini', action: () => Roa('vivaldi-gemini', vivaldiWithGeminProfile . ' https://gemini.google.com/ --new-window', '#i') },
                ; { key: 'j', label: 'Jitsi', action: () => Roa('jitsi-meet', vivaldiWithMainProfile . ' https://meet.jit.si/JP_ALFRE_REDACTED_SECRET') },
                { key: 'k', label: 'Google Keep', action: () => Roa('google-keep', vivaldiWithMainProfile . ' https://keep.google.com/') },
                ; { key: 'm', label: 'Google Mail', action: () => Roa('google-mail', vivaldiWithMainProfile . ' https://mail.google.com') },
                ; { key: 'cu', label: 'Cursor Dashboard', chordKey: 'u', action: () => Roa('cursor-dashboard', vivaldiWithMainProfile . ' https://cursor.com/dashboard?tab=billing') },
                { key: 'd', label: 'Google Drive', action: () => Roa('google-drive', vivaldiWithMainProfile . ' https://drive.google.com/drive/my-drive?ths=true') },
                ; { key: 't', label: 'TradingView', action: () => Roa('tradingview', vivaldiWithMainProfile . ' https://www.tradingview.com/chart') },
            ] },
            ; { key: 'F', label: 'Chrome Debug', action: () => Run(chromeWithDebugProfile) },
            ; { key: 'g', label: 'Browser AI', action: () => Roa('vivaldi-ai', vivaldiWithAIProfile, '#g') },
            ; { key: 'G', label: 'Browser Gordos', action: () => Run(vivaldiWithGordosProfile) },
            ; { key: 'r', label: 'Debug', chordHidden: true },
            ; { key: 'w', label: 'Work', action: () => Roa('browser-work', chromeWithWorkProfile) },
            ; { key: '#w', label: 'Work (Alt)', chordHidden: true },
            ; { key: '#d', label: 'chrome-debug (Alt)', chordHidden: true },
            { key: 'v', label: 'Youtube', action: () => Roa('vivaldi-youtube', vivaldiWithYoutubeProfile, '#v') },
            ; { key: 'yv', label: 'YouTube Video Downloader', chordPath: ['y', 'v'], chordPathLabel: 'YouTube DL', action: () => DownloadYouTubeVideoFromClipboard() },
            ; { key: 'ya', label: 'YouTube Audio Downloader', chordPath: ['y', 'a'], chordPathLabel: 'YouTube DL', action: () => DownloadYouTubeAudioFromClipboard() },
            ; { key: 'V', label: 'Vivaldi (App)', action: () => Roa('vivaldi', vivaldiExe) },
        ]
    }
}

; --- YouTube download helpers ---

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

; ===================================================================
; Menu C — Code
; ===================================================================
GetMainSeqCOptions() {
    return {
        waitml: 1000,
        items: [
            { key: 'M', label: 'Main script with cursor', action: () => Roa('main-scripts', cursorExe . ' c:\dev\scripts\main', '!m') },
            { key: 'm', label: 'Main script with vscode', action: () => Roa('main-scripts', vscodeExe . ' c:\dev\scripts\main', '!m') },
            { key: 's', label: 'Scripts folder', action: () => Roa('scripts-folder', cursorExe . ' c:\dev\scripts', '!s') },
            { key: 't', label: 'Chat', action: () => Roa('chat', cursorExe . ' c:\dev\chat', '#t') },
            { key: 'C', label: 'Code', action: () => RoAWithPattern('ahk_exe Code.exe', vscodeExe, '^!c') },
            { key: 'c', label: 'Cursor', action: () => Roa('cursor', cursorExe) },
            { key: 'l', label: 'Claude Code', action: () => Roa('claude-code', 'wt --size 90,35 -p "Claude" -- claude --dangerously-skip-permissions --chrome --ide ') },
            { key: 'q', label: 'copyQ data', action: () => Roa('copyq-backup', cursorExe . ' "D:\user-home-in-d\Documents\copyq-backup"') },
            { key: 'p', label: 'Passwords', action: () => Roa('passwords-backup', cursorExe . ' "D:\user-home-in-d\Documents\Chrome Passwords Backup.csv"') },
        ]
    }
}
