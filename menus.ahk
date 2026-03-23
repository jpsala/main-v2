; ===================================================================
; Menu definitions — pure data, no helpers
; Action helpers live in menu-actions.ahk
; Engine/dispatch lives in menus-whichkey.ahk
; ===================================================================

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

; ===================================================================
; Menu W — Browser & Web
; ===================================================================
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
                { key: 'a', label: 'jpsala.ai', action: () => Roa('jpsala-ai', vivaldiWithJpsalaAiProfile . ' https://claude.ai/settings/billing') },
                { key: 'A', label: 'jpsala.alt', action: () => Roa('jpsala-alt', vivaldiWithJpsalaAltProfile . ' https://claude.ai/settings/billing') },
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
