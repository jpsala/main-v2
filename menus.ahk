; ===================================================================
; Menu definitions - pure data, no helpers
; Action helpers live in menu-actions.ahk
; Engine/dispatch lives in menus-whichkey.ahk
; ===================================================================

FindFirstExistingPath(paths) {
    for _, path in paths {
        if (path && FileExist(path))
            return path
    }
    return ""
}

QuoteCommandPath(path) {
    if (!path)
        return ""
    return InStr(path, " ") ? '"' . path . '"' : path
}

OpenResolvedApp(alias, label, paths, bookmark := false, extraArgs := "") {
    exePath := FindFirstExistingPath(paths)
    if (!exePath) {
        msg(label . " no encontrado en esta notebook/PC", { seconds: 4 })
        return false
    }
    return Roa(alias, QuoteCommandPath(exePath) . extraArgs, bookmark)
}

OpenFolderInExplorer(alias, targetCandidates) {
    targetPath := ""
    for _, path in targetCandidates {
        if (path && (DirExist(path) || FileExist(path))) {
            targetPath := path
            break
        }
    }

    if (!targetPath) {
        msg("No encontre la carpeta o archivo configurado para " . alias, { seconds: 4 })
        return false
    }

    launcher := xyplorerExe && FileExist(xyplorerExe)
        ? QuoteCommandPath(xyplorerExe)
        : QuoteCommandPath(A_WinDir . "\explorer.exe")
    return Roa(alias, launcher . ' "' . targetPath . '"')
}

OpenWindowSpy() {
    SplitPath(A_AhkPath, , &ahkDir)
    return OpenResolvedApp("window-spy", "Window Spy", [ahkDir . "\UX\WindowSpy.ahk"])
}

GetConfigValueWithFallback(key, default := "") {
    global deviceSection
    value := IniRead("config.ini", deviceSection, key, "")
    if (value != "")
        return value
    return IniRead("config.ini", "desktop", key, default)
}

GetDevRoot() {
    configured := GetConfigValueWithFallback("dev_dir", "")
    candidates := []

    if (configured)
        candidates.Push(configured)

    for _, fallback in ["C:\dev", "D:\dev", EnvGet("USERPROFILE") . "\dev", A_ScriptDir . "\.."] {
        if (!fallback)
            continue
        alreadyIncluded := false
        for _, existing in candidates {
            if (existing = fallback) {
                alreadyIncluded := true
                break
            }
        }
        if (!alreadyIncluded)
            candidates.Push(fallback)
    }

    for _, path in candidates {
        if (DirExist(path))
            return path
    }

    return configured ? configured : "C:\dev"
}

JoinPath(basePath, relativePath) {
    if (!basePath)
        return relativePath
    if (SubStr(basePath, -1) = "\" || SubStr(basePath, -1) = "/")
        return basePath . relativePath
    return basePath . "\" . relativePath
}

OpenRepoInEditor(alias, label, editorExe, relativePath, bookmark := false) {
    if (!editorExe) {
        msg(label . ": editor no configurado", { seconds: 4 })
        return false
    }

    targetPath := JoinPath(GetDevRoot(), relativePath)
    if (!DirExist(targetPath) && !FileExist(targetPath)) {
        msg(label . ": no encontre " . targetPath, { seconds: 4 })
        return false
    }

    return Roa(alias, editorExe . ' "' . targetPath . '"', bookmark)
}

; ===================================================================
; Menu A - Apps
; ===================================================================
GetMainSeqAOptions() {
    return {
        waitml: 1000,
        items: [
            { key: "#b", label: "Show Bookmarks", chordKey: "b", action: () => showBookmarks() },
            { key: "c", label: "SpeedCrunch", action: () => OpenResolvedApp("SpeedCrunch", "SpeedCrunch", ["C:\tools\speedcrunch\speedcrunch.exe", A_ProgramFiles . "\SpeedCrunch\speedcrunch.exe", A_ProgramFiles . " (x86)\SpeedCrunch\speedcrunch.exe"]) },
            { key: "C", label: "LibreOffice Calc", action: () => OpenResolvedApp("libreoffice-calc", "LibreOffice Calc", [A_ProgramFiles . "\LibreOffice\program\scalc.exe", A_ProgramFiles . " (x86)\LibreOffice\program\scalc.exe"]) },
            { key: "f", label: "File Explorer", action: () => Roa("file-explorer", QuoteCommandPath(A_WinDir . "\explorer.exe")) },
            { key: "M", label: "Mixer", action: () => openMixer() },
            { key: "s", label: "Spotify", action: () => Roa("spotify", "spotify.exe") },
            { key: "S", label: "ShareX screenshots", action: () => OpenFolderInExplorer("sharex-folder", [EnvGet("USERPROFILE") . "\Pictures\ShareX", EnvGet("USERPROFILE") . "\Pictures\sharex", EnvGet("USERPROFILE") . "\Pictures"]) },
            { key: "w", label: "Restart Wispr Flow", action: () => RestartWisprFlow() },
            { key: "t", label: "tablet/telegram/terminal", items: [
                { key: "t", label: "Windows Terminal", action: () => OpenResolvedApp("windows-terminal", "Windows Terminal", [EnvGet("LOCALAPPDATA") . "\Microsoft\WindowsApps\wt.exe", A_ProgramFiles . "\WindowsApps\Microsoft.WindowsTerminal_1.23.20211.0_x64__8wekyb3d8bbwe\wt.exe"]) },
                { key: "T", label: "Telegram", action: () => OpenResolvedApp("telegram", "Telegram", ["C:\tools\Telegram\Telegram.exe", A_AppData . "\Telegram Desktop\Telegram.exe", EnvGet("LOCALAPPDATA") . "\Programs\Telegram Desktop\Telegram.exe"]) },
                { key: "a", label: "Tablet", action: () => RunScrcpyTablet() },
                { key: "p3", label: "Phone 700px", chordPath: ["p", "3"], chordPathLabel: "Phone", action: () => RunScrcpyPhone(700) },
                { key: "p4", label: "Phone 900px", chordPath: ["p", "4"], chordPathLabel: "Phone", action: () => RunScrcpyPhone(900) },
            ] },
            { key: "x", label: "XYplorer", action: () => Roa("xyplorer", xyplorerExe) },
            { key: "y", label: "Window Spy", action: () => OpenWindowSpy() },
        ]
    }
}

; ===================================================================
; Menu W - Browser & Web
; ===================================================================
GetMainSeqWOptions() {
    return {
        waitml: 1000,
        items: [
            ; { key: "$", label: "USD" },
            { key: "a", label: "AI", action: () => OpenRepoInEditor("ai-project", "AI", cursorExe, "ai") },
            ; { key: "A", label: "Amaia", action: () => OpenRepoInEditor("amaia-project", "Amaia", cursorExe, "amaia") },
            ; { key: "b", label: "Browser Books", action: () => Roa("vivaldi-books", vivaldiWithBooksProfile, "#b") },
            { key: "c", label: "Browser Carnival", action: () => OpenBrowserProfile("chrome-carnival", vivaldiWithCarnivalProfile) },
            { key: "#c", label: "chrome-main", chordKey: "m", action: () => Roa("chrome-main", browserWithChromeMainProfile) },
            { key: "d", label: "Debug with chrome", chordHidden: true },
            ; { key: "#d", label: "Chrome Debug", chordKey: "x", action: () => OpenChromeDebugCopy() },
            { key: "D", label: "Debug with vivaldi", action: () => Run(vivaldiWithDebugProfile) },
            { key: "f", label: "Browser Main", action: () => OpenMainBrowser() },
            { key: "d", label: "Vivaldi debug", action: () => Run(vivaldiWithDebugProfile) },
            { key: "s", label: "Sites", items: [
                { key: "c", label: "Google Calendar", action: () => OpenUrlWithBrowser("google-calendar", "https://calendar.google.com/calendar/u/0/r", vivaldiWithMainProfile) },
                { key: "a", label: "jpsala.ai", action: () => OpenUrlWithBrowser("jpsala-ai", "https://claude.ai/settings/billing", vivaldiWithJpsalaAiProfile) },
                { key: "A", label: "jpsala.alt", action: () => OpenUrlWithBrowser("jpsala-alt", "https://claude.ai/settings/billing", vivaldiWithJpsalaAltProfile) },
                ; { key: "g", label: "Gemini", action: () => Roa("vivaldi-gemini", vivaldiWithGeminProfile . " https://gemini.google.com/ --new-window", "#i") },
                ; { key: "j", label: "Jitsi", action: () => Roa("jitsi-meet", vivaldiWithMainProfile . " https://meet.jit.si/JP_ALFRE_REDACTED_SECRET") },
                { key: "k", label: "Google Keep", action: () => OpenUrlWithBrowser("google-keep", "https://keep.google.com/", vivaldiWithMainProfile) },
                ; { key: "m", label: "Google Mail", action: () => Roa("google-mail", vivaldiWithMainProfile . " https://mail.google.com") },
                ; { key: "cu", label: "Cursor Dashboard", chordKey: "u", action: () => Roa("cursor-dashboard", vivaldiWithMainProfile . " https://cursor.com/dashboard?tab=billing") },
                { key: "d", label: "Google Drive", action: () => OpenUrlWithBrowser("google-drive", "https://drive.google.com/drive/my-drive?ths=true", vivaldiWithMainProfile) },
                ; { key: "t", label: "TradingView", action: () => Roa("tradingview", vivaldiWithMainProfile . " https://www.tradingview.com/chart") },
            ] },
            ; { key: "F", label: "Chrome Debug", action: () => Run(chromeWithDebugProfile) },
            ; { key: "g", label: "Browser AI", action: () => Roa("vivaldi-ai", vivaldiWithAIProfile, "#g") },
            ; { key: "G", label: "Browser Gordos", action: () => Run(vivaldiWithGordosProfile) },
            ; { key: "r", label: "Debug", chordHidden: true },
            ; { key: "w", label: "Work", action: () => Roa("browser-work", chromeWithWorkProfile) },
            ; { key: "#w", label: "Work (Alt)", chordHidden: true },
            ; { key: "#d", label: "chrome-debug (Alt)", chordHidden: true },
            { key: "v", label: "Youtube", action: () => OpenBrowserProfile("vivaldi-youtube", vivaldiWithYoutubeProfile, "#v") },
            ; { key: "yv", label: "YouTube Video Downloader", chordPath: ["y", "v"], chordPathLabel: "YouTube DL", action: () => DownloadYouTubeVideoFromClipboard() },
            ; { key: "ya", label: "YouTube Audio Downloader", chordPath: ["y", "a"], chordPathLabel: "YouTube DL", action: () => DownloadYouTubeAudioFromClipboard() },
            ; { key: "V", label: "Vivaldi (App)", action: () => Roa("vivaldi", vivaldiExe) },
        ]
    }
}

; ===================================================================
; Menu C - Code
; ===================================================================
GetMainSeqCOptions() {
    return {
        waitml: 1000,
        items: [
            { key: "M", label: "Main script with cursor", action: () => OpenRepoInEditor("main-scripts", "Main script with cursor", cursorExe, "scripts\main", "!m") },
            { key: "m", label: "Main script with vscode", action: () => OpenRepoInEditor("main-scripts", "Main script with vscode", vscodeExe, "scripts\main", "!m") },
            { key: "s", label: "Scripts folder", action: () => OpenRepoInEditor("scripts-folder", "Scripts folder", cursorExe, "scripts", "!s") },
            { key: "t", label: "Chat", action: () => OpenRepoInEditor("chat", "Chat", cursorExe, "chat", "#t") },
            { key: "C", label: "Code", action: () => RoAWithPattern("ahk_exe Code.exe", vscodeExe, "^!c") },
            { key: "c", label: "Cursor", action: () => Roa("cursor", cursorExe) },
            { key: "l", label: "Claude Code", action: () => Roa("claude-code", 'wt --size 90,35 -p "Claude" -- claude --dangerously-skip-permissions --chrome --ide ') },
            { key: "q", label: "copyQ data", action: () => OpenFolderInExplorer("copyq-backup", ["D:\user-home-in-d\Documents\copyq-backup", EnvGet("USERPROFILE") . "\Documents\copyq-backup"]) },
            { key: "p", label: "Passwords", action: () => OpenFolderInExplorer("passwords-backup", ["D:\user-home-in-d\Documents\Chrome Passwords Backup.csv", EnvGet("USERPROFILE") . "\Documents\Chrome Passwords Backup.csv"]) },
        ]
    }
}
